const cron = require("node-cron");

const SEQUENCE_COLLECTION = require("../model/sequence.model");
const LEADS_COLLECTION = require("../model/leads.model");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");

const { sendSequenceToLead } = require("../services/sequence.service");

// ============================================================
// BASE URL
// ============================================================

const BASE_URL = process.env.APP_BASE_URL || "http://localhost:3000";

// ============================================================
// CHECK PREVIOUS STEP
// ============================================================

async function getPreviousStepDelivery({ leadId, sequence }) {
  if (sequence.step <= 1) {
    return null;
  }

  const previousSequence = await SEQUENCE_COLLECTION.findOne({
    userId: sequence.userId,
    step: sequence.step - 1,
  }).sort({
    createdAt: -1,
  });

  if (!previousSequence) {
    return null;
  }

  return SEQUENCE_DELIVERY.findOne({
    leadId,
    sequenceId: previousSequence._id,
    status: "sent",
  });
}

// ============================================================
// GAP DAY CHECK
// ============================================================

async function isGapSatisfied({ leadId, sequence }) {
  // STEP 1
  if (sequence.step === 1) {
    return true;
  }

  // PREVIOUS STEP
  const previousDelivery = await getPreviousStepDelivery({
    leadId,
    sequence,
  });

  if (!previousDelivery) {
    return false;
  }

  // GAP DAYS
  const gapDays = Number(sequence.gapDays || 0);

  const previousSentAt = previousDelivery.sentAt;

  if (!previousSentAt) {
    return false;
  }

  const now = Date.now();

  const requiredTime = previousSentAt.getTime() + gapDays * 24 * 60 * 60 * 1000;

  return now >= requiredTime;
}

// ============================================================
// PROCESS ONE SEQUENCE
// ============================================================

async function processOneSequence(sequence) {
  let sent = 0;
  let skipped = 0;
  let failed = 0;

  // ==========================================================
  // ONLY EMAIL
  // ==========================================================

  if (sequence.type !== "Email") {
    return {
      sequenceId: sequence._id,
      step: sequence.step,
      variant: sequence.variant,
      sent: 0,
      skipped: 0,
      failed: 0,
      reason: "unsupported_type",
    };
  }

  // ==========================================================
  // GET LEADS
  // ==========================================================

  const leads = await LEADS_COLLECTION.find({
    userId: sequence.userId,
    type: sequence.type,
    tracking: true,
  }).lean();

  // ==========================================================
  // LOOP LEADS
  // ==========================================================

  for (const lead of leads) {
    try {
      // ======================================================
      // CHECK ALREADY SENT
      // ======================================================

      const alreadySent = await SEQUENCE_DELIVERY.findOne({
        leadId: lead._id,
        sequenceId: sequence._id,
        status: "sent",
      });

      if (alreadySent) {
        skipped++;
        continue;
      }

      // ======================================================
      // CHECK GAP
      // ======================================================

      const gapSatisfied = await isGapSatisfied({
        leadId: lead._id,
        sequence,
      });

      if (!gapSatisfied) {
        skipped++;
        continue;
      }

      // ======================================================
      // SEND EMAIL
      // ======================================================

      const result = await sendSequenceToLead({
        sequence,
        lead,
        baseUrl: BASE_URL,
      });

      // ======================================================
      // PROCESS SEND RESULT
      // ======================================================

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
      }
    } catch (leadError) {
      failed++;

      console.error(`Failed sending to ${lead.email}:`, leadError.message);
    }
  }

  return {
    sequenceId: sequence._id,
    step: sequence.step,
    variant: sequence.variant,
    leads: leads.length,
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
    const sequences = await SEQUENCE_COLLECTION.find({
      status: "active",
    }).lean();

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

function startSequenceJob() {
  cron.schedule(
    "*/15 * * * *",
    async () => {
      try {
        await processSequences();
      } catch (error) {
        console.error("Scheduled sequence job failed:", error);
      }
    },
    {
      timezone: process.env.TIMEZONE || "Asia/Kolkata",
    },
  );

  console.log("Sequence scheduler started.");
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  startSequenceJob,
  processSequences,
  processSequencesForUser,
};
