const crypto = require("crypto");
const EMAIL_SUPPRESSION = require("../model/email_suppression.model");

const SEQUENCE_COLLECTION = require("../model/sequence.model");

const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");

const { sendSequenceEmail } = require("./email.service");

// ============================================================
// SEND ONE SEQUENCE TO ONE LEAD
// ============================================================

async function sendSequenceToLead({ sequence, lead, baseUrl }) {
  console.log("==============================================");
  console.log("SEQUENCE DELIVERY STARTED");
  console.log("LEAD:", lead?.email);
  console.log("SEQUENCE:", sequence?._id);
  console.log("STEP:", sequence?.step);
  console.log("VARIANT:", sequence?.variant);
  console.log("==============================================");

  const suppression = lead.tracking === false ? null : await EMAIL_SUPPRESSION.findOne({
    userId: sequence.userId, email: String(lead.email || "").trim().toLowerCase(),
  }).select("reason").lean();
  let skipReason = lead.tracking === false ? "lead_unsubscribed"
    : suppression ? `lead_${suppression.reason}` : null;
  if (!skipReason && await SEQUENCE_DELIVERY.exists({
    userId: sequence.userId, leadId: lead._id, repliedAt: { $ne: null },
  })) {
    skipReason = "lead_already_replied";
  }
  if (skipReason) {
    console.log("SEQUENCE EMAIL SKIPPED:", skipReason);
    return { sent: false, skipped: true, reason: skipReason };
  }
  const deliveryChannel = sequence.channel || "Email";

  if (deliveryChannel !== "Email" || lead.type !== deliveryChannel) {
    return {
      sent: false,
      failed: false,
      skipped: true,
      reason: "unsupported_delivery_channel",
    };
  }

  // ==========================================================
  // CHECK EMAIL
  // ==========================================================

  const leadEmail = typeof lead?.email === "string" ? lead.email.trim() : "";

  // ==========================================================
  // BASIC EMAIL VALIDATION
  // ==========================================================

  const emailRegex =
    /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

  if (!leadEmail || !emailRegex.test(leadEmail)) {
    console.error("==============================================");
    console.error("INVALID LEAD EMAIL");
    console.error("EMAIL:", leadEmail || "EMPTY");
    console.error("==============================================");

    // --------------------------------------------------------
    // CHECK WHETHER A DELIVERY ALREADY EXISTS
    // --------------------------------------------------------

    let delivery = await SEQUENCE_DELIVERY.findOne({
      leadId: lead._id,
      sequenceId: sequence._id,
    });

    // --------------------------------------------------------
    // CREATE FAILED DELIVERY
    // --------------------------------------------------------

    if (!delivery) {
      const trackingId = crypto.randomUUID();

      delivery = await SEQUENCE_DELIVERY.create({
        userId: sequence.userId,

        leadId: lead._id,

        sequenceId: sequence._id,

        step: sequence.step,

        variant: sequence.variant,

        sequenceType: deliveryChannel,

        leadType: lead.type,

        email: leadEmail,

        status: "failed",

        trackingId,

        scheduledAt: new Date(),

        errorMessage: `Invalid email address: ${leadEmail || "empty"}`,

        failureType: "invalid_recipient",

        failureReason: `Invalid email address: ${leadEmail || "empty"}`,

        failedAt: new Date(),
      });
    } else if (delivery.status !== "sent") {
      delivery.status = "failed";

      delivery.errorMessage = `Invalid email address: ${leadEmail || "empty"}`;

      delivery.failureType = "invalid_recipient";

      delivery.failureReason = `Invalid email address: ${leadEmail || "empty"}`;

      delivery.failedAt = new Date();

      await delivery.save();
    }

    // --------------------------------------------------------
    // UPDATE FAILED STATISTICS
    // --------------------------------------------------------

    await SEQUENCE_COLLECTION.updateOne(
      {
        _id: sequence._id,
      },
      {
        $inc: {
          "statistics.failed": 1,
        },
      },
    );

    return {
      sent: false,

      failed: true,

      skipped: false,

      deliveryId: delivery._id,

      failureType: "invalid_recipient",

      failureReason: `Invalid email address: ${leadEmail || "empty"}`,
    };
  }

  // ==========================================================
  // CHECK ALREADY SUCCESSFULLY SENT
  // ==========================================================

  const alreadySent = await SEQUENCE_DELIVERY.findOne({
    leadId: lead._id,
    sequenceId: sequence._id,
    status: "sent",
  });

  if (alreadySent) {
    console.log(`Already sent: ${leadEmail}`);

    return {
      sent: false,

      failed: false,

      skipped: true,

      reason: "already_sent",
    };
  }

  // ==========================================================
  // CHECK EXISTING PENDING DELIVERY
  // ==========================================================

  const trackingId = crypto.randomUUID();

  let delivery = null;

  const existingPending = await SEQUENCE_DELIVERY.findOne({
    leadId: lead._id,
    sequenceId: sequence._id,
    status: "pending",
  });

  if (existingPending) {
    const pendingAge =
      Date.now() - new Date(existingPending.updatedAt).getTime();

    const fiveMinutes = 5 * 60 * 1000;

    if (pendingAge < fiveMinutes) {
      console.log(`Delivery is currently processing: ${leadEmail}`);

      return {
        sent: false,

        failed: false,

        skipped: true,

        reason: "delivery_in_progress",

        deliveryId: existingPending._id,
      };
    }

    console.warn(`Recovering stale pending delivery: ${leadEmail}`);

    existingPending.status = "pending";

    existingPending.failureType = null;

    existingPending.failureReason = null;

    existingPending.errorMessage = null;

    existingPending.failedAt = null;

    existingPending.scheduledAt = new Date();

    existingPending.trackingId = trackingId;

    await existingPending.save();

    delivery = existingPending;
  }

  const cleanBaseUrl = String(baseUrl || "")
    .trim()
    .replace(/\/+$/, "");

  let parsedBaseUrl = null;

  try {
    parsedBaseUrl = new URL(cleanBaseUrl);
  } catch (_) {
    parsedBaseUrl = null;
  }

  if (
    !parsedBaseUrl ||
    (parsedBaseUrl.protocol !== "http:" &&
      parsedBaseUrl.protocol !== "https:")
  ) {
    console.error(
      "Sequence email was not sent because the public tracking base URL is invalid.",
    );

    return {
      sent: false,
      failed: true,
      skipped: false,
      failureType: "configuration_error",
      failureReason:
        "APP_BASE_URL must be the public backend origin, for example https://high-custom-app.onrender.com",
    };
  }

  // A failed delivery already occupies the unique lead/sequence pair. Reuse
  // it for the retry instead of attempting to insert a duplicate document.
  if (!delivery && !existingPending) {
    const existingFailed = await SEQUENCE_DELIVERY.findOne({
      leadId: lead._id,
      sequenceId: sequence._id,
      status: "failed",
    });

    if (existingFailed) {
      console.log(`Retrying failed delivery: ${leadEmail}`);

      existingFailed.status = "pending";
      existingFailed.failureType = null;
      existingFailed.failureReason = null;
      existingFailed.errorMessage = null;
      existingFailed.failedAt = null;
      existingFailed.scheduledAt = new Date();
      existingFailed.trackingId = trackingId;

      await existingFailed.save();

      delivery = existingFailed;
    }
  }

  // ==========================================================
  // CREATE TRACKING URL
  // ==========================================================

  const trackingUrl = `${parsedBaseUrl.origin}/api/email-tracking/open/${encodeURIComponent(
    trackingId,
  )}?v=${Date.now()}`;

  const interestedUrl = `${parsedBaseUrl.origin}/api/email-tracking/response/${encodeURIComponent(
    trackingId,
  )}/interested`;

  const notInterestedUrl = `${parsedBaseUrl.origin}/api/email-tracking/response/${encodeURIComponent(
    trackingId,
  )}/notInterested`;

  console.log("==============================================");
  console.log("TRACKING URL GENERATED");
  console.log("BASE URL:", parsedBaseUrl.origin);
  console.log("TRACKING URL:", trackingUrl);
  console.log("==============================================");

  // ==========================================================
  // CREATE DELIVERY
  // ==========================================================

  try {
    if (!delivery) {
      delivery = await SEQUENCE_DELIVERY.create({
        userId: sequence.userId,

        leadId: lead._id,

        sequenceId: sequence._id,

        step: sequence.step,

        variant: sequence.variant,

        sequenceType: deliveryChannel,

        leadType: lead.type,

        email: leadEmail,

        status: "pending",

        trackingId,

        scheduledAt: new Date(),
      });
    }
  } catch (createError) {
    console.error("Failed to create delivery:", createError);

    return {
      sent: false,

      failed: true,

      skipped: false,

      reason: "delivery_creation_failed",

      failureType: "database_error",

      failureReason: createError.message || "Unable to create delivery record.",
    };
  }

  // ==========================================================
  // SEND EMAIL
  // ==========================================================

  let acceptedRecorded = false;
  try {
    const result = await sendSequenceEmail({
      userId: sequence.userId,

      sequence,

      lead: {
        ...lead,
        email: leadEmail,
      },

      trackingUrl,

      interestedUrl,

      notInterestedUrl,

      baseUrl,

      onAccepted: async ({ messageId, threadId }) => {
        delivery.status = "sent";
        delivery.sentAt = new Date();
        delivery.messageId = messageId || null;
        delivery.threadId = threadId || null;
        delivery.errorMessage = null;
        delivery.failureType = null;
        delivery.failureReason = null;
        delivery.failedAt = null;

        await delivery.save();
        acceptedRecorded = true;

        await SEQUENCE_COLLECTION.updateOne(
          {
            _id: sequence._id,
          },
          {
            $inc: {
              "statistics.sent": 1,
            },
          },
        );
      },
    });

    // ========================================================
    // MAKE SURE GMAIL CONFIRMED MESSAGE
    // ========================================================

    if (!result || !result.messageId) {
      throw Object.assign(
        new Error("Gmail did not confirm the email with a message ID."),
        {
          failureType: "unknown",

          failureReason: "Gmail did not confirm the email with a message ID.",
        },
      );
    }

    // ========================================================
    // GMAIL ACCEPTED EMAIL
    // ========================================================

    // Older/custom email providers may not use the callback. Keep this
    // fallback so a confirmed message can never remain pending.
    if (delivery.status !== "sent") {
      delivery.status = "sent";
      delivery.sentAt = new Date();
      delivery.messageId = result.messageId || null;
      delivery.threadId = result.threadId || null;
      delivery.errorMessage = null;
      delivery.failureType = null;
      delivery.failureReason = null;
      delivery.failedAt = null;

      await delivery.save();
      acceptedRecorded = true;

      await SEQUENCE_COLLECTION.updateOne(
        {
          _id: sequence._id,
        },
        {
          $inc: {
            "statistics.sent": 1,
          },
        },
      );
    }

    // ========================================================
    // SUCCESS LOG
    // ========================================================

    console.log("==============================================");

    console.log("SEQUENCE DELIVERY SUCCESS");

    console.log("Lead:", leadEmail);

    console.log("Sequence:", sequence._id);

    console.log("Step:", sequence.step);

    console.log("Variant:", sequence.variant);

    console.log("Delivery:", delivery._id);

    console.log("Message ID:", result.messageId);

    console.log("==============================================");

    // ========================================================
    // RETURN SUCCESS
    // ========================================================

    return {
      sent: true,

      failed: false,

      skipped: false,

      deliveryId: delivery._id,

      messageId: result.messageId,

      threadId: result.threadId,
    };
  } catch (error) {
    // ========================================================
    // EMAIL FAILED
    // ========================================================

    const failureType = error?.failureType || "unknown";

    const failureReason =
      error?.failureReason || error?.message || "Unknown email error";

    // ========================================================
    // MARK DELIVERY FAILED
    // ========================================================

    // Provider acceptance is final even if a later local statistics write fails.
    if (acceptedRecorded) {
      console.error("Email sent, but local statistics update failed:", failureReason);
      return { sent: true, failed: false, messageId: delivery.messageId };
    }
    delivery.status = "failed";
    delivery.retryable = error?.retryable === true;

    delivery.errorMessage = failureReason;

    delivery.failureType = failureType;

    delivery.failureReason = failureReason;

    delivery.failedAt = new Date();

    await delivery.save();

    // ========================================================
    // UPDATE FAILED STATISTICS
    // ========================================================

    await SEQUENCE_COLLECTION.updateOne(
      {
        _id: sequence._id,
      },
      {
        $inc: {
          "statistics.failed": 1,
        },
      },
    );

    // ========================================================
    // LOG FAILURE
    // ========================================================

    console.error("==============================================");

    console.error("SEQUENCE DELIVERY FAILED");

    console.error("Lead:", leadEmail);

    console.error("Sequence:", sequence._id);

    console.error("Step:", sequence.step);

    console.error("Variant:", sequence.variant);

    console.error("Delivery:", delivery._id);

    console.error("Failure Type:", failureType);

    console.error("Failure Reason:", failureReason);

    console.error("==============================================");

    // BullMQ only applies attempts/backoff when the processor throws. Preserve
    // the delivery diagnostics above, then rethrow transient provider/network
    // failures so the configured queue retry policy actually runs.
    if (error?.retryable === true) {
      throw error;
    }

    // ========================================================
    // RETURN FAILED
    // ========================================================

    return {
      sent: false,

      failed: true,

      skipped: false,

      deliveryId: delivery._id,

      failureType,

      failureReason,
    };
  }
}

// ============================================================
// EXPORT
// ============================================================

module.exports = {
  sendSequenceToLead,
};
