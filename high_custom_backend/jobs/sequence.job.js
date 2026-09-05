const cron = require("node-cron");

const SEQUENCE_COLLECTION = require("../model/sequence.model");
const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const { queueSequenceEmail } = require("../queues/email.producer");

function normalizeBaseUrl(value) {
  const rawValue = String(value || "").trim();

  if (!rawValue) return null;

  try {
    const url = new URL(rawValue);
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    return url.origin;
  } catch (_) {
    return null;
  }
}

const BASE_URL =
  normalizeBaseUrl(process.env.APP_BASE_URL) ||
  normalizeBaseUrl(process.env.RENDER_EXTERNAL_URL) ||
  (process.env.NODE_ENV !== "production"
    ? `http://localhost:${process.env.PORT || 3000}`
    : null);

const SEQUENCE_CRON = process.env.SEQUENCE_CRON || "* * * * *";
let scheduledSequenceCursor = null;
let scheduledJobIsRunning = false;

console.log("========================================");
console.log("EMAIL TRACKING BASE URL:", BASE_URL || "NOT CONFIGURED");
console.log("EMAIL DELIVERY MODE: BULLMQ QUEUE");
console.log("========================================");

async function activateDueScheduledSequences(userId = null) {
  const filter = {
    status: "scheduled",
    scheduledAt: { $ne: null, $lte: new Date() },
  };

  if (userId) filter.userId = userId;

  const result = await SEQUENCE_COLLECTION.updateMany(filter, {
    $set: { status: "active" },
  });

  return result.modifiedCount || 0;
}

async function getPreviousSequence(sequence, deliveryChannel, businessType) {
  if (sequence.step <= 1) return null;

  return SEQUENCE_COLLECTION.findOne({
    userId: sequence.userId,
    step: sequence.step - 1,
    variant: sequence.variant,
    channel: deliveryChannel,
    ...(businessType ? { businessType } : {}),
  })
    .sort({ createdAt: -1 })
    .select({ _id: 1 })
    .lean();
}

async function processOneSequence(sequence) {
  let queued = 0;
  let skipped = 0;
  let failed = 0;
  let leadsProcessed = 0;

  const deliveryChannel = sequence.channel || "Email";
  const businessType =
    sequence.businessType ||
    (sequence.type && sequence.type !== "Email" ? sequence.type : "");

  const leadFilter = {
    userId: sequence.userId,
    type: deliveryChannel,
    ...(businessType ? { businessType } : {}),
    tracking: true,
  };

  const configuredBatchSize = Number(process.env.SEQUENCE_LEAD_BATCH_SIZE || 250);
  const leadBatchSize = Number.isInteger(configuredBatchSize)
    ? Math.min(Math.max(configuredBatchSize, 25), 1000)
    : 250;

  const configuredRunLimit = Number(
    process.env.SEQUENCE_MAX_LEADS_PER_RUN || 1000,
  );
  const maxLeadsPerRun = Number.isInteger(configuredRunLimit)
    ? Math.min(Math.max(configuredRunLimit, leadBatchSize), 5000)
    : 1000;

  const previousSequence = await getPreviousSequence(
    sequence,
    deliveryChannel,
    businessType,
  );

  let lastLeadId = sequence.processingCursor || null;

  while (leadsProcessed < maxLeadsPerRun) {
    const remainingThisRun = maxLeadsPerRun - leadsProcessed;

    const leads = await LEADS_COLLECTION.find({
      ...leadFilter,
      ...(lastLeadId ? { _id: { $gt: lastLeadId } } : {}),
    })
      .sort({ _id: 1 })
      .limit(Math.min(leadBatchSize, remainingThisRun))
      .lean();

    if (leads.length === 0) {
      if (lastLeadId) {
        await SEQUENCE_COLLECTION.updateOne(
          { _id: sequence._id },
          { $set: { processingCursor: null } },
        );
      }
      break;
    }

    lastLeadId = leads[leads.length - 1]._id;
    leadsProcessed += leads.length;

    const leadIds = leads.map((lead) => lead._id);

    const currentDeliveries = await SEQUENCE_DELIVERY.find({
      sequenceId: sequence._id,
      leadId: { $in: leadIds },
    })
      .select({ leadId: 1, status: 1, retryable: 1 })
      .lean();

    const currentDeliveryByLead = new Map(
      currentDeliveries.map((delivery) => [String(delivery.leadId), delivery]),
    );

    let previousDeliveryByLead = new Map();

    if (sequence.step > 1 && previousSequence) {
      const previousDeliveries = await SEQUENCE_DELIVERY.find({
        sequenceId: previousSequence._id,
        leadId: { $in: leadIds },
        status: "sent",
      })
        .select({ leadId: 1, sentAt: 1 })
        .lean();

      previousDeliveryByLead = new Map(
        previousDeliveries.map((delivery) => [
          String(delivery.leadId),
          delivery,
        ]),
      );
    }

    const requiredGapMilliseconds =
      Number(sequence.gapDays || 0) * 24 * 60 * 60 * 1000;

    for (const lead of leads) {
      try {
        const existingDelivery = currentDeliveryByLead.get(String(lead._id));

        if (existingDelivery?.status === "sent" ||
            (existingDelivery?.status === "failed" && !existingDelivery.retryable)) {
          skipped++;
          continue;
        }

        if (sequence.step > 1) {
          const previousDelivery = previousDeliveryByLead.get(String(lead._id));

          if (
            !previousSequence ||
            !previousDelivery?.sentAt ||
            Date.now() <
              new Date(previousDelivery.sentAt).getTime() +
                requiredGapMilliseconds
          ) {
            skipped++;
            continue;
          }
        }

        const result = await queueSequenceEmail({
          sequence,
          lead,
          baseUrl: BASE_URL,
        });

        if (result.queued) queued++;
      } catch (leadError) {
        failed++;
        console.error(`Failed to queue ${lead.email}:`, leadError.message);
      }
    }

    await SEQUENCE_COLLECTION.updateOne(
      { _id: sequence._id },
      { $set: { processingCursor: lastLeadId } },
    );
  }

  return {
    sequenceId: sequence._id,
    step: sequence.step,
    variant: sequence.variant,
    leads: leadsProcessed,
    queued,
    skipped,
    failed,
  };
}

async function processSequenceList(sequences) {
  const results = [];

  for (const sequence of sequences) {
    try {
      results.push(await processOneSequence(sequence));
    } catch (error) {
      console.error(`Sequence ${sequence._id} queueing failed:`, error.message);
      results.push({ sequenceId: sequence._id, error: error.message });
    }
  }

  return results;
}

async function processSequences() {
  await activateDueScheduledSequences();

  const configuredSequenceLimit = Number(
    process.env.SEQUENCE_MAX_SEQUENCES_PER_RUN || 100,
  );
  const sequenceLimit = Number.isInteger(configuredSequenceLimit)
    ? Math.min(Math.max(configuredSequenceLimit, 1), 1000)
    : 100;

  let sequences = await SEQUENCE_COLLECTION.find({
    status: "active",
    ...(scheduledSequenceCursor
      ? { _id: { $gt: scheduledSequenceCursor } }
      : {}),
  })
    .sort({ _id: 1 })
    .limit(sequenceLimit)
    .lean();

  if (sequences.length === 0 && scheduledSequenceCursor) {
    scheduledSequenceCursor = null;
    sequences = await SEQUENCE_COLLECTION.find({ status: "active" })
      .sort({ _id: 1 })
      .limit(sequenceLimit)
      .lean();
  }

  if (sequences.length > 0) {
    scheduledSequenceCursor = sequences[sequences.length - 1]._id;
  }

  const results = await processSequenceList(sequences);

  return {
    sequencesProcessed: sequences.length,
    results,
  };
}

async function processSequencesForUser(userId) {
  await activateDueScheduledSequences(userId);

  const sequences = await SEQUENCE_COLLECTION.find({
    userId,
    status: "active",
  }).lean();

  const results = await processSequenceList(sequences);

  return {
    userId,
    sequencesProcessed: sequences.length,
    results,
  };
}

function startSequenceJob() {
  cron.schedule(
    SEQUENCE_CRON,
    async () => {
      if (scheduledJobIsRunning) {
        console.warn("Sequence scheduler skipped: previous run is active.");
        return;
      }

      scheduledJobIsRunning = true;

      try {
        const result = await processSequences();
        console.log(
          `Sequence queue pass finished. Sequences: ${result.sequencesProcessed}`,
        );
      } catch (error) {
        console.error("Scheduled sequence queue job failed:", error);
      } finally {
        scheduledJobIsRunning = false;
      }
    },
    {
      timezone: process.env.TIMEZONE || "Asia/Kolkata",
    },
  );

  console.log(`Sequence queue scheduler started with cron: ${SEQUENCE_CRON}`);
}

module.exports = {
  startSequenceJob,
  processSequences,
  processSequencesForUser,
  activateDueScheduledSequences,
};
