const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const SEQUENCE = require("../model/sequence.model");

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
              new: true,
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

    const statistics = await SEQUENCE_DELIVERY.aggregate([
      {
        $match: {
          userId,
        },
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

        openRate,
      },

      pagination: {
        page: pageNumber,

        limit: limitNumber,

        total,

        totalPages: Math.ceil(total / limitNumber),
      },

      deliveries,
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
