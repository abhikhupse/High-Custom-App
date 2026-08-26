const cron = require("node-cron");

const SEQUENCE_COLLECTION = require("../model/sequence.model");
const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");

const { sendSequenceToLead } = require("../services/sequence.service");

// ============================================================
// BASE URL
// ============================================================

function normalizeBaseUrl(value) {
  const rawValue = String(value || "").trim();

  if (!rawValue) {
    return null;
  }

  try {
    const url = new URL(rawValue);

    if (url.protocol !== "http:" && url.protocol !== "https:") {
      return null;
    }

    // Only the origin belongs here. This prevents callback paths or trailing
    // slashes from producing an invalid tracking-pixel endpoint.
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

console.log("========================================");

// ============================================================
// ACTIVATE SCHEDULED SEQUENCES THAT ARE DUE
// ============================================================

async function activateDueScheduledSequences(userId = null) {
  const filter = {
    status: "scheduled",
    scheduledAt: {
      $ne: null,
      $lte: new Date(),
    },
  };

  if (userId) {
    filter.userId = userId;
  }

  const result = await SEQUENCE_COLLECTION.updateMany(filter, {
    $set: {
      status: "active",
    },
  });

  const activated = result.modifiedCount || 0;

  if (activated > 0) {
    console.log(`Activated ${activated} scheduled sequence(s).`);
  }

  return activated;
}
console.log("EMAIL TRACKING BASE URL:", BASE_URL || "NOT CONFIGURED");

if (!BASE_URL) {
  console.error(
    "Tracking is unavailable: set APP_BASE_URL to the public backend origin, for example https://high-custom-app.onrender.com",
  );
}
console.log("========================================");

// ============================================================
// PROCESS ONE SEQUENCE
// ============================================================

async function processOneSequence(sequence) {
  let sent = 0;
  let skipped = 0;
  let failed = 0;
  let leadsProcessed = 0;

  // ==========================================================
  // GET LEADS
  // ==========================================================

  // Old records stored the business category in type. New records keep the
  // delivery channel separate. All current sequence delivery is email.
  const deliveryChannel = sequence.channel || "Email";

  const sequenceBusinessType =
    sequence.businessType ||
    (sequence.type && sequence.type !== "Email" ? sequence.type : "");

  const leadFilter = {
    userId: sequence.userId,
    type: deliveryChannel,
    ...(sequenceBusinessType ? { businessType: sequenceBusinessType } : {}),
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

  // ==========================================================
  // LOOP LEADS
  // ==========================================================

  const configuredConcurrency = Number(
    process.env.SEQUENCE_SEND_CONCURRENCY || 3,
  );

  const concurrency = Number.isInteger(configuredConcurrency)
    ? Math.min(Math.max(configuredConcurrency, 1), 5)
    : 3;

  // Resolve the previous step once per sequence. Previously this lookup ran
  // once for every lead, which became extremely expensive for bulk imports.
  let previousSequence = null;

  if (sequence.step > 1) {
    previousSequence = await SEQUENCE_COLLECTION.findOne({
      userId: sequence.userId,
      step: sequence.step - 1,
      variant: sequence.variant,
      channel: deliveryChannel,
      ...(sequenceBusinessType
        ? { businessType: sequenceBusinessType }
        : {}),
    })
      .sort({ createdAt: -1 })
      .select({ _id: 1 })
      .lean();
  }

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
      .select({ leadId: 1, status: 1 })
      .lean();

    const currentDeliveryByLead = new Map(
      currentDeliveries.map((delivery) => [
        String(delivery.leadId),
        delivery,
      ]),
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

    const eligibleLeads = [];
    const requiredGapMilliseconds =
      Number(sequence.gapDays || 0) * 24 * 60 * 60 * 1000;

    for (const lead of leads) {
      const existingDelivery = currentDeliveryByLead.get(String(lead._id));

      if (existingDelivery?.status === "sent") {
        skipped++;
        continue;
      }

      if (sequence.step > 1) {
        const previousDelivery = previousDeliveryByLead.get(String(lead._id));

        if (
          !previousSequence ||
          !previousDelivery?.sentAt ||
          Date.now() <
            new Date(previousDelivery.sentAt).getTime() + requiredGapMilliseconds
        ) {
          skipped++;
          continue;
        }
      }

      eligibleLeads.push(lead);
    }

    for (let index = 0; index < eligibleLeads.length; index += concurrency) {
      const batch = eligibleLeads.slice(index, index + concurrency);

      await Promise.all(
        batch.map(async (lead) => {
          try {
            // ==================================================
            // SEND EMAIL
            // ==================================================

            const result = await sendSequenceToLead({
              sequence,
              lead,
              baseUrl: BASE_URL,
            });

            if (result.sent) {
              sent++;

              console.log(
                `Email sent: ${lead.email} | Step ${sequence.step} | Variant ${sequence.variant}`,
              );
            } else if (result.failed) {
              failed++;

              console.error(
                `Email failed: ${lead.email} | Step ${sequence.step} | Variant ${sequence.variant}`,
              );

              console.error(
                `Reason: ${result.failureReason || result.reason || "Unknown error"}`,
              );
            } else {
              skipped++;

              console.log(
                `Email skipped: ${lead.email} | Step ${sequence.step} | ` +
                  `Variant ${sequence.variant} | Reason: ${
                    result.reason || "unknown"
                  }`,
              );
            }
          } catch (leadError) {
            failed++;

            console.error(
              `Failed sending to ${lead.email}:`,
              leadError.message,
            );
          }
        }),
      );
    }

    // Advance only after the complete page has been handled. If the process
    // stops unexpectedly, the page is safely retried and the delivery unique
    // index prevents duplicate sends.
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
    sent,
    skipped,
    failed,
  };
}

// ============================================================
// PROCESS ALL ACTIVE SEQUENCES
// ============================================================

async function processSequences() {
  console.log("================================================");
  console.log("SEQUENCE JOB STARTED");
  console.log(new Date().toISOString());
  console.log("================================================");

  try {
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

    // Reaching the end starts the next fair pass from the beginning.
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

    console.log("Active sequences:", sequences.length);

    const results = [];

    for (const sequence of sequences) {
      try {
        const result = await processOneSequence(sequence);

        results.push(result);
      } catch (sequenceError) {
        console.error(
          `Sequence ${sequence._id} failed:`,
          sequenceError.message,
        );

        results.push({
          sequenceId: sequence._id,
          error: sequenceError.message,
        });
      }
    }

    console.log("================================================");
    console.log("SEQUENCE JOB FINISHED");
    console.log("================================================");

    return {
      sequencesProcessed: sequences.length,
      results,
    };
  } catch (error) {
    console.error("Sequence job error:", error);

    throw error;
  }
}

// ============================================================
// PROCESS ONLY ONE USER
// ============================================================

async function processSequencesForUser(userId) {
  console.log("================================================");
  console.log("USER SEQUENCE JOB STARTED");
  console.log("USER:", userId);
  console.log(new Date().toISOString());
  console.log("================================================");

  try {
    await activateDueScheduledSequences(userId);

    // ========================================================
    // ACTIVE SEQUENCES FOR USER
    // ========================================================

    const sequences = await SEQUENCE_COLLECTION.find({
      userId,
      status: "active",
    }).lean();

    console.log("Active sequences for user:", sequences.length);

    const results = [];

    for (const sequence of sequences) {
      try {
        const result = await processOneSequence(sequence);

        results.push(result);
      } catch (sequenceError) {
        console.error(
          `Sequence ${sequence._id} failed:`,
          sequenceError.message,
        );

        results.push({
          sequenceId: sequence._id,
          error: sequenceError.message,
        });
      }
    }

    console.log("================================================");
    console.log("USER SEQUENCE JOB FINISHED");
    console.log("================================================");

    return {
      userId,
      sequencesProcessed: sequences.length,
      results,
    };
  } catch (error) {
    console.error("User sequence job error:", error);

    throw error;
  }
}

// ============================================================
// START CRON JOB
// ============================================================

let scheduledJobIsRunning = false;

function startSequenceJob() {
  cron.schedule(
    SEQUENCE_CRON,
    async () => {
      if (scheduledJobIsRunning) {
        console.warn(
          "Sequence scheduler skipped this run because the previous run is still active.",
        );
        return;
      }

      scheduledJobIsRunning = true;

      try {
        await processSequences();
      } catch (error) {
        console.error("Scheduled sequence job failed:", error);
      } finally {
        scheduledJobIsRunning = false;
      }
    },
    {
      timezone: process.env.TIMEZONE || "Asia/Kolkata",
    },
  );

  console.log(`Sequence scheduler started with cron: ${SEQUENCE_CRON}`);
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  startSequenceJob,
  processSequences,
  processSequencesForUser,
  activateDueScheduledSequences,
};
