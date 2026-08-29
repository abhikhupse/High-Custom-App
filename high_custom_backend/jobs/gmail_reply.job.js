const cron = require("node-cron");

const {
  renewExpiringGmailWatches,
  retryPendingGmailNotifications,
} = require("../services/gmail_reply.service");

const GMAIL_WATCH_RENEWAL_CRON =
  process.env.GMAIL_WATCH_RENEWAL_CRON || "17 3 * * *";

let renewalIsRunning = false;
let recoveryIsRunning = false;

async function runRenewal() {
  if (renewalIsRunning) return;

  renewalIsRunning = true;

  try {
    const result = await renewExpiringGmailWatches();

    if (result.enabled) {
      console.log(`Gmail reply watches renewed: ${result.renewed}`);
    }
  } catch (error) {
    console.error("Gmail reply watch renewal failed:", error);
  } finally {
    renewalIsRunning = false;
  }
}

async function runPendingRecovery() {
  if (recoveryIsRunning) return;

  recoveryIsRunning = true;

  try {
    const result = await retryPendingGmailNotifications();

    if (result.found > 0) {
      console.log(
        `Pending Gmail reply syncs processed: ${result.processed}/${result.found}`,
      );
    }
  } catch (error) {
    console.error("Pending Gmail reply recovery failed:", error);
  } finally {
    recoveryIsRunning = false;
  }
}

function startGmailReplyJob() {
  cron.schedule(GMAIL_WATCH_RENEWAL_CRON, runRenewal, {
    timezone: process.env.TIMEZONE || "Asia/Kolkata",
  });

  cron.schedule("* * * * *", runPendingRecovery, {
    timezone: process.env.TIMEZONE || "Asia/Kolkata",
  });

  // Also repair missing or near-expiry watches after each backend restart.
  setImmediate(runRenewal);
  setImmediate(runPendingRecovery);

  console.log(
    `Gmail reply watch renewal scheduler started: ${GMAIL_WATCH_RENEWAL_CRON}`,
  );
}

module.exports = {
  startGmailReplyJob,
  runRenewal,
  runPendingRecovery,
};
