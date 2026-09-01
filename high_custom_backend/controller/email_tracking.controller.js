const mongoose = require("mongoose");
const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const SEQUENCE = require("../model/sequence.model");
const USER = require("../model/user.model");
const LEAD = require("../model/leads.model");
const LEAD_INTEREST_DETAILS = require("../model/lead_interest_details.model");
const { getClientIp } = require("../utils/clientIp");
const { detectEmailOpenScanner } = require("../utils/emailOpenScanner");

// ============================================================
// TRACK EMAIL OPEN
// ============================================================

exports.trackOpen = async (req, res) => {
  const requestTime = new Date();

  try {
    const { trackingId } = req.params;

    // ==========================================================
    // LOG EVERY TRACKING REQUEST
    // ==========================================================

    console.log("");
    console.log("============================================================");
    console.log("🔥 EMAIL OPEN TRACKING REQUEST RECEIVED");
    console.log("============================================================");

    console.log("Time:", requestTime.toISOString());

    console.log("Tracking ID:", trackingId);

    console.log("IP:", req.ip || req.headers["x-forwarded-for"] || "unknown");

    console.log("User-Agent:", req.headers["user-agent"] || "unknown");

    console.log(
      "Referer:",
      req.headers.referer || req.headers.referrer || "none",
    );

    console.log("============================================================");

    // ==========================================================
    // VALIDATE TRACKING ID
    // ==========================================================

    if (!trackingId) {
      console.error("❌ EMAIL OPEN ERROR: Missing tracking ID");

      return sendTrackingPixel(res);
    }

    // ==========================================================
    // FIND DELIVERY
    // ==========================================================

    console.log("🔎 Searching SequenceDelivery...");

    const delivery = await SEQUENCE_DELIVERY.findOne({
      trackingId,
    });

    // ==========================================================
    // TRACKING ID NOT FOUND
    // ==========================================================

    if (!delivery) {
      console.error("❌ TRACKING ID NOT FOUND:", trackingId);

      console.log(
        "============================================================",
      );

      return sendTrackingPixel(res);
    }

    // ==========================================================
    // DELIVERY FOUND
    // ==========================================================

    console.log("✅ DELIVERY FOUND");

    console.log("Delivery ID:", delivery._id);

    console.log("User ID:", delivery.userId);

    console.log("Sequence ID:", delivery.sequenceId);

    console.log("Lead ID:", delivery.leadId);

    console.log("Email:", delivery.email);

    console.log("Current Status:", delivery.status);

    console.log("Previous Opened At:", delivery.openedAt || "NULL");

    console.log("Previous Open Count:", delivery.openedCount || 0);

    // ==========================================================
    // IGNORE REQUESTS FROM A RECENT SENDER LOGIN IP
    // ==========================================================

    const requestIp = getClientIp(req);

    if (requestIp && delivery.userId) {
      const isSenderLoginIp = await USER.exists({
        _id: delivery.userId,
        "loginDeviceIps.ipAddress": requestIp,
      });

      if (isSenderLoginIp) {
        console.log(
          `IGNORED OPEN: ${requestIp} matches a sender login-device IP`,
        );
        console.log("============================================================");

        return sendTrackingPixel(res);
      }
    }

    // ==========================================================
    // COUNT IMMEDIATE OPENS
    // ==========================================================
    //
    // The delivery record is created before Gmail sends the message. A fast
    // recipient can therefore request the tracking pixel while the delivery
    // is still "pending", before sendSequenceToLead stores status="sent".
    // Gmail may cache that first pixel response, so ignoring it permanently
    // loses the real open. Count both pending and sent deliveries, but never
    // count a delivery that has already failed.
    // ==========================================================

    if (delivery.status === "failed") {
      console.log("IGNORED OPEN: delivery has failed");
      console.log(
        "============================================================",
      );

      return sendTrackingPixel(res);
    }

    // ==========================================================
    // IGNORE MAIL SECURITY SCANNERS AND AUTOMATED PREFETCHES
    // ==========================================================

    const scannerCheck = detectEmailOpenScanner(req, delivery, requestTime);

    if (scannerCheck.isScanner) {
      console.log(`IGNORED OPEN: ${scannerCheck.reason}`);
      console.log("============================================================");

      return sendTrackingPixel(res);
    }

    // ==========================================================
    // PRESERVE GMAIL OPEN TRACKING; IGNORE NON-GMAIL PIXEL OPENS
    // ==========================================================
    //
    // Zoho and other mail-security proxies can make multiple requests that
    // look like a normal browser. They cannot be reliably separated from a
    // person using a tracking pixel, so do not allow them to mark a delivery
    // as opened. Gmail keeps its existing GoogleImageProxy behavior.
    // ==========================================================

    const userAgent = String(req.headers["user-agent"] || "");
    const isGmailImageProxy = /googleimageproxy/i.test(userAgent);
    let recipientEmail = String(delivery.email || "").trim().toLowerCase();

    if (!recipientEmail && delivery.leadId) {
      const recipientLead = await LEAD.findById(delivery.leadId)
        .select("email")
        .lean();

      recipientEmail = String(recipientLead?.email || "").trim().toLowerCase();
    }

    const recipientDomain = recipientEmail
      .trim()
      .toLowerCase()
      .split("@")
      .pop();
    const isGmailRecipient = ["gmail.com", "googlemail.com"].includes(
      recipientDomain,
    );

    if (!isGmailRecipient || !isGmailImageProxy) {
      console.log(
        `IGNORED OPEN: recipient domain ${recipientDomain || "unknown"} is not a Gmail recipient or request is not GoogleImageProxy`,
      );
      console.log("============================================================");

      return sendTrackingPixel(res);
    }

    // ==========================================================
    // INCREMENT OPEN COUNT
    // ==========================================================

    const previousOpenCount = delivery.openedCount || 0;

    delivery.openedCount = previousOpenCount + 1;

    // ==========================================================
    // FIRST OPEN
    // ==========================================================

    const firstOpen = !delivery.openedAt;

    if (firstOpen) {
      console.log("🟢 FIRST OPEN DETECTED");

      delivery.openedAt = requestTime;

      // --------------------------------------------------------
      // IMPORTANT
      // --------------------------------------------------------
      //
      // Keep status as "sent".
      //
      // Do NOT do:
      //
      // delivery.status = "opened";
      //
      // Open tracking is represented by:
      //
      // openedAt
      // openedCount
      //
      // --------------------------------------------------------

      console.log("Opened At:", delivery.openedAt.toISOString());

      // ========================================================
      // UPDATE SEQUENCE OPEN STATISTICS
      // ========================================================

      if (delivery.sequenceId) {
        try {
          const sequenceUpdate = await SEQUENCE.findByIdAndUpdate(
            delivery.sequenceId,
            {
              $inc: {
                "statistics.opened": 1,
              },
            },
            {
              returnDocument: "after",
            },
          );

          if (sequenceUpdate) {
            console.log("✅ Sequence open statistics updated");

            console.log(
              "Sequence statistics.opened:",
              sequenceUpdate.statistics?.opened || 0,
            );
          } else {
            console.warn("⚠️ Sequence not found:", delivery.sequenceId);
          }
        } catch (sequenceError) {
          console.error(
            "❌ Failed to update sequence statistics:",
            sequenceError,
          );

          // Do not fail the open tracking request
          // because the delivery itself can still be saved.
        }
      }
    } else {
      console.log("🔵 REPEAT OPEN / IMAGE REQUEST");

      console.log("Original Opened At:", delivery.openedAt.toISOString());
    }

    // ==========================================================
    // SAVE DELIVERY
    // ==========================================================

    console.log("💾 Saving delivery...");

    await delivery.save();

    // ==========================================================
    // CONFIRM SAVE
    // ==========================================================

    console.log("✅ DELIVERY SAVED");

    console.log("Tracking ID:", delivery.trackingId);

    console.log("Opened At:", delivery.openedAt);

    console.log("Opened Count:", delivery.openedCount);

    console.log("Status:", delivery.status);

    console.log("============================================================");

    console.log("🔥 EMAIL OPEN TRACKING COMPLETED");

    console.log("============================================================");

    console.log("");

    // ==========================================================
    // RETURN TRACKING PIXEL
    // ==========================================================

    return sendTrackingPixel(res);
  } catch (error) {
    // ==========================================================
    // ERROR
    // ==========================================================

    console.error("");
    console.error(
      "============================================================",
    );

    console.error("❌ TRACK OPEN ERROR");

    console.error(error);

    console.error(
      "============================================================",
    );

    console.error("");

    // ----------------------------------------------------------
    // IMPORTANT
    // ----------------------------------------------------------
    //
    // Always return the tracking pixel.
    //
    // This prevents Gmail from receiving a broken image response.
    //
    // ----------------------------------------------------------

    return sendTrackingPixel(res);
  }
};

// ============================================================
// TRACKING PIXEL RESPONSE
// ============================================================

function sendTrackingPixel(res) {
  try {
    // ----------------------------------------------------------
    // Transparent 1x1 GIF
    // ----------------------------------------------------------

    const pixel = Buffer.from("R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=", "base64");

    res.set({
      "Content-Type": "image/gif",

      "Content-Length": pixel.length,

      "Cache-Control": "no-cache, no-store, must-revalidate, proxy-revalidate",

      Pragma: "no-cache",

      Expires: "0",

      "X-Content-Type-Options": "nosniff",
    });

    return res.status(200).send(pixel);
  } catch (error) {
    console.error("❌ TRACKING PIXEL RESPONSE ERROR:", error);

    return res.status(200).end();
  }
}

exports.trackResponse = async (req, res) => {
  try {
    const trackingId = String(req.params.trackingId || "").trim();
    const response = String(req.params.response || "").trim();

    if (!trackingId || !["interested", "notInterested"].includes(response)) {
      return sendResponsePage(res, {
        title: "Invalid Response",
        message: "This response link is not valid.",
        success: false,
      });
    }

    const delivery = await SEQUENCE_DELIVERY.findOne({ trackingId });

    if (!delivery) {
      return sendResponsePage(res, {
        title: "Link Not Found",
        message: "This response link is no longer available.",
        success: false,
      });
    }

    return sendResponseConfirmationPage(res, {
      trackingId,
      response,
    });
  } catch (error) {
    console.error("TRACK RESPONSE ERROR:", error);
    return sendResponsePage(res, {
      title: "Unable to Open Response",
      message: "Please try again later.",
      success: false,
    });
  }
};

exports.confirmResponse = async (req, res) => {
  try {
    const trackingId = String(req.params.trackingId || "").trim();
    const response = String(req.params.response || "").trim();

    if (!trackingId || !["interested", "notInterested"].includes(response)) {
      return sendResponsePage(res, {
        title: "Invalid Response",
        message: "This response link is not valid.",
        success: false,
      });
    }

    const delivery = await SEQUENCE_DELIVERY.findOne({ trackingId });

    if (!delivery) {
      return sendResponsePage(res, {
        title: "Link Not Found",
        message: "This response link is no longer available.",
        success: false,
      });
    }

    if (delivery.response !== response) {
      const increments = {};

      if (delivery.response === "interested") {
        increments["statistics.interested"] = -1;
      } else if (delivery.response === "notInterested") {
        increments["statistics.notInterested"] = -1;
      }

      increments[
        response === "interested"
          ? "statistics.interested"
          : "statistics.notInterested"
      ] = 1;

      delivery.response = response;
      delivery.respondedAt = new Date();
      delivery.clickedAt = delivery.clickedAt || delivery.respondedAt;

      await delivery.save();
      await SEQUENCE.updateOne({ _id: delivery.sequenceId }, { $inc: increments });
    }

    await LEAD.updateOne(
      { _id: delivery.leadId, userId: delivery.userId },
      {
        $set: {
          responseStatus: response,
          respondedAt: delivery.respondedAt || new Date(),
          ...(response === "notInterested" ? { tracking: false } : {}),
        },
      },
    );

    if (response === "interested") {
      const lead = await LEAD.findById(delivery.leadId).lean();
      const existingDetails = await LEAD_INTEREST_DETAILS.findOne({
        trackingId,
      }).lean();

      return sendInterestForm(res, {
        trackingId,
        values: existingDetails || {
          name: [lead?.firstName, lead?.lastName].filter(Boolean).join(" "),
          companyName: lead?.company || "",
        },
      });
    }

    return sendResponsePage(res, {
      title: "Unsubscribed Successfully",
      message: "You will no longer receive emails from us.",
    });
  } catch (error) {
    console.error("CONFIRM RESPONSE ERROR:", error);
    return sendResponsePage(res, {
      title: "Unable to Record Response",
      message: "Please try again later.",
      success: false,
    });
  }
};

function sendResponseConfirmationPage(res, { trackingId, response }) {
  const interested = response === "interested";
  const title = interested ? "Confirm Interest" : "Confirm Unsubscribe";
  const message = interested
    ? "Please confirm that you are interested and would like to share your contact details."
    : "Please confirm that you are not interested and no longer want to receive these emails.";
  const buttonLabel = interested ? "Yes, I am interested" : "Confirm unsubscribe";

  res.set({
    "Content-Type": "text/html; charset=UTF-8",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });

  return res.status(200).send(`<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8" />
<meta name="viewport" content="width=device-width,initial-scale=1.0" />
<title>${escapeHtml(title)}</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#050709;color:#fff;font-family:Arial,sans-serif}
main{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
section{width:100%;max-width:560px;text-align:center;background:#0b0e12;border:1px solid #5f4d27;border-radius:20px;padding:32px;box-shadow:0 20px 60px #0008}
h1{margin:0 0 12px;color:#f2c45f;font-size:30px}p{color:#aeb4bf;line-height:1.6;margin:0 0 24px}
button{width:100%;padding:14px;border:0;border-radius:10px;background:#f2c45f;color:#080a0c;font-weight:800;font-size:16px;cursor:pointer}
</style></head><body><main><section>
<h1>${escapeHtml(title)}</h1>
<p>${escapeHtml(message)}</p>
<form method="post" action="/api/email-tracking/response/${encodeURIComponent(trackingId)}/${encodeURIComponent(response)}/confirm">
<button type="submit">${escapeHtml(buttonLabel)}</button>
</form>
</section></main></body></html>`);
}

exports.submitInterestDetails = async (req, res) => {
  try {
    const trackingId = String(req.params.trackingId || "").trim();
    const delivery = await SEQUENCE_DELIVERY.findOne({ trackingId });

    if (!delivery) {
      return sendResponsePage(res, {
        title: "Link Not Found",
        message: "This response link is no longer available.",
        success: false,
      });
    }

    const values = {
      name: String(req.body.name || "").trim(),
      mobileNumber: String(req.body.mobileNumber || "").trim(),
      companyName: String(req.body.companyName || "").trim(),
      city: String(req.body.city || "").trim(),
      state: String(req.body.state || "").trim(),
      country: String(req.body.country || "").trim(),
    };

    const missingRequired = [
      "name",
      "mobileNumber",
      "city",
      "state",
      "country",
    ].some((field) => !values[field]);

    if (missingRequired) {
      return sendInterestForm(res, {
        trackingId,
        values,
        error: "Please complete all required fields.",
        statusCode: 400,
      });
    }

    await LEAD_INTEREST_DETAILS.findOneAndUpdate(
      { trackingId },
      {
        $set: {
          userId: delivery.userId,
          leadId: delivery.leadId,
          sequenceId: delivery.sequenceId,
          ...values,
          status: "interested",
          submittedAt: new Date(),
        },
      },
      { upsert: true, returnDocument: "after", runValidators: true },
    );

    return sendResponsePage(res, {
      title: "Thank You 🙌",
      message:
        "Your interest and contact details have been recorded. Our team will contact you shortly.",
    });
  } catch (error) {
    console.error("SUBMIT INTEREST DETAILS ERROR:", error);
    return sendResponsePage(res, {
      title: "Unable to Save Details",
      message: "Please check your details and try again.",
      success: false,
    });
  }
};

exports.getInterestDetails = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;
    const page = Math.max(Number(req.query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(req.query.limit) || 10, 1), 100);
    const query = { userId };

    const details = await LEAD_INTEREST_DETAILS.find({ userId })
      .populate("leadId", "firstName lastName email")
      .populate("sequenceId", "subject step variant")
      .sort({ submittedAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    const total = await LEAD_INTEREST_DETAILS.countDocuments(query);

    return res.status(200).json({
      success: true,
      details,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.max(Math.ceil(total / limit), 1),
      },
    });
  } catch (error) {
    console.error("GET INTEREST DETAILS ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get interested lead details.",
    });
  }
};

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function sendInterestForm(
  res,
  { trackingId, values = {}, error = "", statusCode = 200 },
) {
  const field = (name, label, { required = true, type = "text" } = {}) => `
    <label>${escapeHtml(label)}${required ? " *" : ""}
      <input type="${type}" name="${name}" value="${escapeHtml(values[name])}"
        ${required ? "required" : ""} maxlength="160" />
    </label>`;

  res.set({
    "Content-Type": "text/html; charset=UTF-8",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });

  return res.status(statusCode).send(`<!DOCTYPE html>
<html lang="en"><head><meta charset="UTF-8" />
<meta name="viewport" content="width=device-width,initial-scale=1.0" />
<title>Interested — Contact Details</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#050709;color:#fff;font-family:Arial,sans-serif}
main{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px}
section{width:100%;max-width:620px;background:#0b0e12;border:1px solid #5f4d27;border-radius:20px;padding:30px;box-shadow:0 20px 60px #0008}
h1{margin:0 0 8px;color:#f2c45f;font-size:30px}p{color:#aeb4bf;line-height:1.5;margin:0 0 22px}
.error{background:#35191c;color:#ffb4ab;padding:12px;border-radius:9px;margin-bottom:18px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}label{display:flex;flex-direction:column;gap:7px;color:#e6e8ec;font-size:14px}
label:first-child,label:nth-child(2),label:nth-child(3){grid-column:1/-1}input{width:100%;padding:13px;border-radius:10px;border:1px solid #343942;background:#11151b;color:#fff;font-size:16px;outline:none}
input:focus{border-color:#f2c45f;box-shadow:0 0 0 3px #f2c45f20}button{width:100%;margin-top:22px;padding:14px;border:0;border-radius:10px;background:#f2c45f;color:#080a0c;font-weight:800;font-size:16px;cursor:pointer}
@media(max-width:560px){section{padding:24px 18px}.grid{grid-template-columns:1fr}.grid label{grid-column:1}}
</style></head><body><main><section>
<h1>Thank You 🙌</h1><p>Your response has been recorded as Interested. Please share your contact details.</p>
${error ? `<div class="error">${escapeHtml(error)}</div>` : ""}
<form method="post" action="/api/email-tracking/response/${encodeURIComponent(trackingId)}/interested">
<div class="grid">
${field("name", "Name")}${field("mobileNumber", "Mobile Number", { type: "tel" })}
${field("companyName", "Company Name", { required: false })}${field("city", "City")}
${field("state", "State")}${field("country", "Country")}
</div><button type="submit">Submit Details</button></form>
</section></main></body></html>`);
}

function sendResponsePage(res, { title, message, success = true }) {
  res.set({
    "Content-Type": "text/html; charset=UTF-8",
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
  });

  return res.status(success ? 200 : 400).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title}</title>
</head>
<body style="margin:0;background:#f5f7fb;font-family:Arial,Helvetica,sans-serif;color:#101828;">
  <main style="min-height:100vh;display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box;">
    <section style="width:100%;max-width:560px;background:#fff;border:1px solid #e4e7ec;border-radius:16px;padding:40px 28px;text-align:center;box-shadow:0 12px 32px rgba(16,24,40,.08);">
      <h1 style="margin:0 0 16px;font-size:30px;line-height:1.25;">${title}</h1>
      <p style="margin:0;color:#475467;font-size:17px;line-height:1.6;">${message}</p>
    </section>
  </main>
</body>
</html>`);
}

// ============================================================
// GET TRACKING REPORT
// ============================================================

exports.getTrackingReport = async (req, res) => {
  try {
    // ==========================================================
    // GET LOGGED-IN USER
    // ==========================================================

    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    // ==========================================================
    // QUERY PARAMETERS
    // ==========================================================

    const { sequenceId, page = 1, limit = 20 } = req.query;

    // ==========================================================
    // PAGINATION
    // ==========================================================

    const pageNumber = Math.max(Number(page) || 1, 1);

    const limitNumber = Math.min(Math.max(Number(limit) || 20, 1), 100);

    // ==========================================================
    // BUILD QUERY
    // ==========================================================

    const deliveryQuery = {
      userId,
    };

    if (sequenceId && String(sequenceId).trim()) {
      deliveryQuery.sequenceId = sequenceId;
    }

    // ==========================================================
    // GET DELIVERIES
    // ==========================================================

    const deliveries = await SEQUENCE_DELIVERY.find(deliveryQuery)
      .populate("sequenceId", "step variant subject type")
      .populate("leadId", "firstName lastName name email phone")
      .sort({
        createdAt: -1,
      })
      .skip((pageNumber - 1) * limitNumber)
      .limit(limitNumber)
      .lean();

    // ==========================================================
    // TOTAL
    // ==========================================================

    const total = await SEQUENCE_DELIVERY.countDocuments(deliveryQuery);

    // ==========================================================
    // STATISTICS
    // ==========================================================

    // Mongoose casts values for find(), but it does not cast values inside an
    // aggregation pipeline. The JWT contains the user id as a string, while
    // sequence deliveries store it as an ObjectId.
    const statisticsMatch = {
      ...deliveryQuery,
      userId: new mongoose.Types.ObjectId(String(userId)),
    };

    if (statisticsMatch.sequenceId) {
      statisticsMatch.sequenceId = new mongoose.Types.ObjectId(
        String(statisticsMatch.sequenceId),
      );
    }

    const statistics = await SEQUENCE_DELIVERY.aggregate([
      {
        $match: statisticsMatch,
      },

      {
        $group: {
          _id: null,

          // --------------------------------------------------
          // TOTAL DELIVERY RECORDS
          // --------------------------------------------------

          totalSent: {
            $sum: {
              $cond: [
                {
                  $eq: ["$status", "sent"],
                },
                1,
                0,
              ],
            },
          },

          // --------------------------------------------------
          // UNIQUE OPENED EMAILS
          // --------------------------------------------------

          totalOpened: {
            $sum: {
              $cond: [
                {
                  $ne: ["$openedAt", null],
                },
                1,
                0,
              ],
            },
          },

          // --------------------------------------------------
          // TOTAL PIXEL REQUESTS
          // --------------------------------------------------

          totalOpens: {
            $sum: {
              $ifNull: ["$openedCount", 0],
            },
          },

          // --------------------------------------------------
          // FAILED
          // --------------------------------------------------

          totalFailed: {
            $sum: {
              $cond: [
                {
                  $eq: ["$status", "failed"],
                },
                1,
                0,
              ],
            },
          },

          totalInterested: {
            $sum: {
              $cond: [{ $eq: ["$response", "interested"] }, 1, 0],
            },
          },

          totalNotInterested: {
            $sum: {
              $cond: [{ $eq: ["$response", "notInterested"] }, 1, 0],
            },
          },

          totalReplied: {
            $sum: {
              $cond: [{ $ne: ["$repliedAt", null] }, 1, 0],
            },
          },
        },
      },
    ]);

    // ==========================================================
    // DEFAULT STATISTICS
    // ==========================================================

    const stats = statistics[0] || {
      totalSent: 0,
      totalOpened: 0,
      totalOpens: 0,
      totalFailed: 0,
      totalInterested: 0,
      totalNotInterested: 0,
      totalReplied: 0,
    };

    // ==========================================================
    // NOT OPENED
    // ==========================================================

    const totalNotOpened = Math.max(stats.totalSent - stats.totalOpened, 0);

    // ==========================================================
    // OPEN RATE
    // ==========================================================

    const openRate =
      stats.totalSent > 0
        ? Number(((stats.totalOpened / stats.totalSent) * 100).toFixed(2))
        : 0;

    // ==========================================================
    // RESPONSE
    // ==========================================================

    return res.status(200).json({
      success: true,

      statistics: {
        totalSent: stats.totalSent,

        totalOpened: stats.totalOpened,

        totalNotOpened,

        totalOpens: stats.totalOpens,

        totalFailed: stats.totalFailed,

        totalInterested: stats.totalInterested,

        totalNotInterested: stats.totalNotInterested,

        totalReplied: stats.totalReplied,

        openRate,
      },

      pagination: {
        page: pageNumber,

        limit: limitNumber,

        total,

        totalPages: Math.ceil(total / limitNumber),
      },

      deliveries: deliveries.map((delivery) => ({
        ...delivery,
        responseStatus:
          delivery.response === "interested"
            ? "Interested"
            : delivery.response === "notInterested"
              ? "Not Interested"
              : delivery.repliedAt
                ? "Replied"
                : null,
      })),
    });
  } catch (error) {
    console.error("GET TRACKING REPORT ERROR:", error);

    return res.status(500).json({
      success: false,

      message: "Failed to get tracking report",

      error: error.message,
    });
  }
};
