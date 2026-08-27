const { Queue } = require("bullmq");
const { createRedisConnection } = require("../config/redis");

const EMAIL_QUEUE_NAME = "high-custom-email";
const emailQueueConnection = createRedisConnection();

const emailQueue = new Queue(EMAIL_QUEUE_NAME, {
  connection: emailQueueConnection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: "exponential",
      delay: 15000,
    },
    removeOnComplete: {
      age: 60 * 60,
      count: 100000,
    },
    removeOnFail: {
      age: 24 * 60 * 60,
      count: 100000,
    },
  },
});

emailQueue.on("error", (error) => {
  console.error("Email queue error:", error.message);
});

module.exports = {
  EMAIL_QUEUE_NAME,
  emailQueue,
};
