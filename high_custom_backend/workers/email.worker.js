const dotenv = require("dotenv");
dotenv.config();

const { Worker, DelayedError } = require("bullmq");
const connectDB = require("../config/db");
const { createRedisConnection } = require("../config/redis");
const { EMAIL_QUEUE_NAME } = require("../queues/email.queue");
const SEQUENCE_COLLECTION = require("../model/sequence.model");
const LEADS_COLLECTION = require("../model/leads.model");
const { sendSequenceToLead } = require("../services/sequence.service");
const {
  acquireUserSendPermit,
  EMAILS_PER_USER_WINDOW,
  EMAIL_USER_WINDOW_MS,
} = require("../services/sender_rate_limit.service");

const EMAIL_WORKER_CONCURRENCY = Math.max(
  1,
  Number(process.env.EMAIL_WORKER_CONCURRENCY || 50),
);

const EMAIL_GLOBAL_MAX_PER_SECOND = Math.max(
  1,
  Number(process.env.EMAIL_GLOBAL_MAX_PER_SECOND || 150),
);

const workerRedisConnection = createRedisConnection();

async function processEmailJob(job, token) {
  const { userId, sequenceId, leadId, baseUrl } = job.data;

  const permit = await acquireUserSendPermit(userId);

  if (!permit.allowed) {
    await job.moveToDelayed(Date.now() + permit.waitMs, token);
    throw new DelayedError();
  }

  const sequence = await SEQUENCE_COLLECTION.findOne({
    _id: sequenceId,
    userId,
  }).lean();

  if (!sequence) {
    return {
      sent: false,
      skipped: true,
      reason: "sequence_not_found",
    };
  }

  if (sequence.status !== "active") {
    return {
      sent: false,
      skipped: true,
      reason: "sequence_not_active",
    };
  }

  const lead = await LEADS_COLLECTION.findOne({
    _id: leadId,
    userId,
  }).lean();

  if (!lead) {
    return {
      sent: false,
      skipped: true,
      reason: "lead_not_found",
    };
  }

  if (lead.tracking === false) {
    return {
      sent: false,
      skipped: true,
      reason: "lead_unsubscribed",
    };
  }

  return sendSequenceToLead({
    sequence,
    lead,
    baseUrl,
  });
}

async function startEmailWorker() {
  await connectDB();

  const worker = new Worker(EMAIL_QUEUE_NAME, processEmailJob, {
    connection: workerRedisConnection,
    concurrency: EMAIL_WORKER_CONCURRENCY,
    limiter: {
      max: EMAIL_GLOBAL_MAX_PER_SECOND,
      duration: 1000,
    },
  });

  worker.on("completed", (job, result) => {
    if (result) {
      console.log(`Email job completed: ${job.id}`);
    }
  });

  worker.on("failed", (job, error) => {
    console.error(`Email job failed: ${job?.id || "unknown"}`, error.message);
  });

  worker.on("error", (error) => {
    console.error("Email worker error:", error);
  });

  console.log("==============================================");
  console.log("HIGH CUSTOM EMAIL WORKER STARTED");
  console.log(`Concurrency: ${EMAIL_WORKER_CONCURRENCY}`);
  console.log(`Global maximum: ${EMAIL_GLOBAL_MAX_PER_SECOND}/second`);
  console.log(
    `Per user: ${EMAILS_PER_USER_WINDOW} emails / ${EMAIL_USER_WINDOW_MS / 1000} seconds`,
  );
  console.log("==============================================");

  return worker;
}

startEmailWorker().catch((error) => {
  console.error("Unable to start email worker:", error);
  process.exit(1);
});
