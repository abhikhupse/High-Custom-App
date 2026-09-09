const cron = require("node-cron");
const { syncAllGoDaddyReplies } = require("../services/godaddy_reply.service");

const schedule = process.env.GODADDY_REPLY_SYNC_CRON || "*/1 * * * *";

function startGoDaddyReplyJob() {
  if (!cron.validate(schedule)) {
    console.error(`GoDaddy reply sync cron is invalid: ${schedule}`);
    return;
  }

  cron.schedule(schedule, async () => {
    try {
      const result = await syncAllGoDaddyReplies();
      console.log(
        `GoDaddy reply sync: ${result.processed}/${result.found}; replies: ${result.replies}`,
      );
    } catch (error) {
      console.error("GoDaddy reply scheduler failed:", error.message);
    }
  });

  console.log(`GoDaddy reply sync scheduler started: ${schedule}`);
}

module.exports = { startGoDaddyReplyJob };
