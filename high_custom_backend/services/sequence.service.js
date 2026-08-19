const crypto = require("crypto");

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

  // ==========================================================
  // TYPE MATCH
  // ==========================================================

  if (sequence.type !== lead.type) {
    return {
      sent: false,
      failed: false,
      skipped: true,
      reason: "type_mismatch",
    };
  }

  // ==========================================================
  // ONLY EMAIL
  // ==========================================================

  if (sequence.type !== "Email") {
    return {
      sent: false,
      failed: false,
      skipped: true,
      reason: "unsupported_email_type",
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

        sequenceType: sequence.type,

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

  const existingPending = await SEQUENCE_DELIVERY.findOne({
    leadId: lead._id,
    sequenceId: sequence._id,
    status: "pending",
  });

  if (existingPending) {
    console.log(`Delivery pending: ${leadEmail}`);

    return {
      sent: false,

      failed: false,

      skipped: true,

      reason: "delivery_pending",
    };
  }

  // ==========================================================
  // CREATE TRACKING ID
  // ==========================================================

  const trackingId = crypto.randomUUID();

  // ==========================================================
  // CREATE TRACKING URL
  // ==========================================================

  const trackingUrl = `${baseUrl}/api/email-tracking/open/${trackingId}`;

  console.log("==============================================");
  console.log("TRACKING URL GENERATED");
  console.log("TRACKING ID:", trackingId);
  console.log("BASE URL:", baseUrl);
  console.log("TRACKING URL:", trackingUrl);
  console.log("==============================================");

  // ==========================================================
  // CREATE DELIVERY
  // ==========================================================

  let delivery;

  try {
    delivery = await SEQUENCE_DELIVERY.create({
      userId: sequence.userId,

      leadId: lead._id,

      sequenceId: sequence._id,

      step: sequence.step,

      variant: sequence.variant,

      sequenceType: sequence.type,

      leadType: lead.type,

      email: leadEmail,

      status: "pending",

      trackingId,

      scheduledAt: new Date(),
    });
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

  try {
    const result = await sendSequenceEmail({
      userId: sequence.userId,

      sequence,

      lead: {
        ...lead,
        email: leadEmail,
      },

      trackingUrl,

      baseUrl,
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

    delivery.status = "sent";

    delivery.sentAt = new Date();

    delivery.messageId = result.messageId || null;

    delivery.threadId = result.threadId || null;

    delivery.errorMessage = null;

    delivery.failureType = null;

    delivery.failureReason = null;

    delivery.failedAt = null;

    await delivery.save();

    // ========================================================
    // UPDATE SENT STATISTICS
    // ========================================================

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

    delivery.status = "failed";

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
