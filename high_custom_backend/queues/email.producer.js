const { emailQueue } = require("./email.queue");

async function queueSequenceEmail({ sequence, lead, baseUrl }) {
  if (!sequence?._id || !sequence?.userId || !lead?._id) {
    throw new Error("sequence, sequence.userId and lead are required.");
  }

  const jobId = `sequence-${String(sequence._id)}-lead-${String(lead._id)}`;

  const job = await emailQueue.add(
    "send-sequence-email",
    {
      userId: String(sequence.userId),
      sequenceId: String(sequence._id),
      leadId: String(lead._id),
      baseUrl,
    },
    {
      jobId,
    },
  );

  return {
    queued: true,
    jobId: job.id,
  };
}

module.exports = {
  queueSequenceEmail,
};
