const cron = require("node-cron");
const { syncAllZohoReplies } = require("../services/zoho_reply.service");

function startZohoReplyJob() {
  const schedule = String(process.env.ZOHO_REPLY_SYNC_CRON || "*/1 * * * *").trim();
  if (!cron.validate(schedule)) {
    console.error(`Zoho reply sync cron is invalid: ${schedule}`);
    return;
  }

  let running = false;
  cron.schedule(schedule, async () => {
    if (running) return;
    running = true;
    try {
      const result = await syncAllZohoReplies();
      if (result.found || result.replies) {
        console.log(`Zoho reply sync: ${result.processed}/${result.found}; replies: ${result.replies}`);
      }
    } catch (error) {
      console.error("Zoho reply scheduler failed:", error.message);
    } finally {
      running = false;
    }
  });
  console.log(`Zoho reply sync scheduler started: ${schedule}`);
}

module.exports = { startZohoReplyJob };
