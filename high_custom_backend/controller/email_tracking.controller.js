const SEQUENCE_DELIVERY = require("../model/sequence_delivery.model");
const SEQUENCE_COLLECTION = require("../model/sequence.model");

// ============================================================
// TRACK EMAIL OPEN
// ============================================================

exports.trackEmailOpen = async (req, res) => {
  try {
    const { trackingId } = req.params;

    if (!trackingId) {
      return res.sendStatus(404);
    }

    const delivery = await SEQUENCE_DELIVERY.findOne({
      trackingId,
    });

    if (delivery) {
      const firstOpen = !delivery.openedAt;

      if (firstOpen) {
        delivery.openedAt = new Date();
        delivery.openedCount = (delivery.openedCount || 0) + 1;

        await delivery.save();

        await SEQUENCE_COLLECTION.updateOne(
          {
            _id: delivery.sequenceId,
          },
          {
            $inc: {
              "statistics.opened": 1,
            },
          },
        );
      }
    }

    // ========================================================
    // 1x1 TRANSPARENT GIF
    // ========================================================

    const pixel = Buffer.from(
      "R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==",
      "base64",
    );

    res.set({
      "Content-Type": "image/gif",
      "Content-Length": pixel.length,
      "Cache-Control": "no-store, no-cache, must-revalidate, proxy-revalidate",
      Pragma: "no-cache",
      Expires: "0",
    });

    return res.status(200).send(pixel);
  } catch (error) {
    console.error("Email tracking error:", error);

    return res.sendStatus(200);
  }
};
