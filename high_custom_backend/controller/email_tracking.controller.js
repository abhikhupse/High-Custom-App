const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const SEQUENCE = require("../model/sequence.model");

// ============================================================
// 1. TRACK EMAIL OPEN
// ============================================================

exports.trackOpen = async (req, res) => {
  try {
    const { trackingId } = req.params;

    if (!trackingId) {
      return res.status(400).send("Missing tracking ID");
    }

    const delivery = await SEQUENCE_DELIVERY.findOne({
      trackingId,
    });

    if (!delivery) {
      return res.status(404).send("Tracking ID not found");
    }

    // --------------------------------------------------------
    // Count every pixel request
    // --------------------------------------------------------

    delivery.openedCount = (delivery.openedCount || 0) + 1;

    // --------------------------------------------------------
    // Only count the FIRST open in sequence statistics
    // --------------------------------------------------------

    const firstOpen = !delivery.openedAt;
    if (firstOpen) {
      delivery.openedAt = new Date();

      // Keep delivery status as "sent".
      // Open tracking is represented by openedAt/openedCount.

      if (delivery.sequenceId) {
        await SEQUENCE.findByIdAndUpdate(delivery.sequenceId, {
          $inc: {
            "statistics.opened": 1,
          },
        });
      }
    }

    await delivery.save();

    // --------------------------------------------------------
    // Transparent 1x1 GIF
    // --------------------------------------------------------

    const pixel = Buffer.from("R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=", "base64");

    res.set({
      "Content-Type": "image/gif",
      "Content-Length": pixel.length,
      "Cache-Control": "no-cache, no-store, must-revalidate",
      Pragma: "no-cache",
      Expires: "0",
    });

    return res.status(200).send(pixel);
  } catch (error) {
    console.error("TRACK OPEN ERROR:", error);

    const pixel = Buffer.from("R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=", "base64");

    res.set({
      "Content-Type": "image/gif",
      "Content-Length": pixel.length,
      "Cache-Control": "no-cache, no-store, must-revalidate",
    });

    return res.status(200).send(pixel);
  }
};

// ============================================================
// 2. GET TRACKING REPORT
// ============================================================

exports.getTrackingReport = async (req, res) => {
  try {
    const userId = req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "Unauthorized",
      });
    }

    const { sequenceId, page = 1, limit = 20 } = req.query;

    const pageNumber = Math.max(Number(page) || 1, 1);
    const limitNumber = Math.min(Math.max(Number(limit) || 20, 1), 100);

    // --------------------------------------------------------
    // Build query
    // --------------------------------------------------------

    const sequenceQuery = {
      userId,
    };

    if (sequenceId) {
      sequenceQuery.sequenceId = sequenceId;
    }

    // --------------------------------------------------------
    // Get deliveries
    // --------------------------------------------------------

    const deliveries = await SEQUENCE_DELIVERY.find(sequenceQuery)
      .populate("sequenceId", "step variant subject type")
      .populate("leadId", "firstName lastName name email phone")
      .sort({
        createdAt: -1,
      })
      .skip((pageNumber - 1) * limitNumber)
      .limit(limitNumber)
      .lean();

    const total = await SEQUENCE_DELIVERY.countDocuments(sequenceQuery);

    // --------------------------------------------------------
    // Statistics
    // --------------------------------------------------------

    const statistics = await SEQUENCE_DELIVERY.aggregate([
      {
        $match: {
          userId,
        },
      },
      {
        $group: {
          _id: null,

          totalSent: {
            $sum: 1,
          },

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

          totalOpens: {
            $sum: {
              $ifNull: ["$openedCount", 0],
            },
          },

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

    const stats = statistics[0] || {
      totalSent: 0,
      totalOpened: 0,
      totalOpens: 0,
      totalFailed: 0,
    };

    const totalNotOpened = stats.totalSent - stats.totalOpened;

    const openRate =
      stats.totalSent > 0
        ? Number(((stats.totalOpened / stats.totalSent) * 100).toFixed(2))
        : 0;

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
