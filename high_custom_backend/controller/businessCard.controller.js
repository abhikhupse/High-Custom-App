const B_CARD_COLLECTION = require("../model/businessCard.model");
const QRCode = require("qrcode");
const normalizeWhatsapp = (value) => {
  let digits = String(value || "").replace(/\D/g, "");
  // Accept both a local 10-digit mobile number and an Indian +91 number.
  if (digits.length === 12 && digits.startsWith("91")) digits = digits.slice(2);
  return digits;
};
const isValidUrl = (value) => /^https?:\/\//i.test(String(value || "").trim());
exports.createBusinessCard = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User Authentication required",
      });
    }

    const { fullName, role, companyName, email, qrLink, address } =
      req.body;
    const whatsapp = normalizeWhatsapp(req.body.whatsapp);

    if (
      !fullName ||
      !role ||
      !companyName ||
      !whatsapp ||
      !email ||
      !qrLink ||
      !address
    ) {
      return res.status(400).json({
        success: false,
        message: "Please enter all the fields to generate business card",
      });
    }
    if (whatsapp.length !== 10) {
      return res.status(400).json({ success: false, message: "Enter a valid 10-digit WhatsApp number." });
    }
    if (!isValidUrl(qrLink)) {
      return res.status(400).json({ success: false, message: "Enter a complete QR link starting with http:// or https://." });
    }
    const businessCardExist = await B_CARD_COLLECTION.findOne({
      userId,
    });

    if (businessCardExist) {
      return res.status(400).json({
        success: false,
        message: "Business Card is only created once",
      });
    }
    const qrCode = await QRCode.toDataURL(qrLink);

    const businessCard = await B_CARD_COLLECTION.create({
      userId,
      fullName,
      role,
      companyName,
      whatsapp,
      email,
      qrLink,
      qrCode,
      address,
    });

    return res.status(201).json({
      success: true,
      message: "Business card created successfully",
      businessCard,
    });
  } catch (error) {
    console.error("Create Business Card Error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

exports.updateBusinessCard = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User Authentication required",
      });
    }

    const { fullName, role, companyName, email, address, qrLink } =
      req.body;
    const whatsapp = req.body.whatsapp === undefined ? undefined : normalizeWhatsapp(req.body.whatsapp);
    if (whatsapp !== undefined && whatsapp.length !== 10) {
      return res.status(400).json({ success: false, message: "Enter a valid 10-digit WhatsApp number." });
    }
    if (qrLink !== undefined && !isValidUrl(qrLink)) {
      return res.status(400).json({ success: false, message: "Enter a complete QR link starting with http:// or https://." });
    }

    // ============================================================
    // QR CODE
    // ============================================================

    let qrCode;

    if (qrLink !== undefined) {
      qrCode = await QRCode.toDataURL(qrLink);
    }

    // ============================================================
    // UPDATE BUSINESS CARD
    // ============================================================

    const updatedBusinessCard = await B_CARD_COLLECTION.findOneAndUpdate(
      {
        userId,
      },
      {
        $set: {
          ...(fullName !== undefined && { fullName }),
          ...(role !== undefined && { role }),
          ...(companyName !== undefined && { companyName }),
          ...(whatsapp !== undefined && { whatsapp }),
          ...(email !== undefined && { email }),
          ...(address !== undefined && { address }),

          ...(qrLink !== undefined && {
            qrLink,
            qrCode,
          }),
        },
      },
      {
        returnDocument: "after",
        runValidators: true,
      },
    );

    // ============================================================
    // NOT FOUND
    // ============================================================

    if (!updatedBusinessCard) {
      return res.status(404).json({
        success: false,
        message: "Business Card not found",
      });
    }

    // ============================================================
    // RESPONSE
    // ============================================================

    return res.status(200).json({
      success: true,
      message: "Business card updated successfully",
      businessCard: updatedBusinessCard,
    });
  } catch (error) {
    console.error("Update Business Card Error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
    });
  }
};

exports.deleteBusinessCard = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "User authentication required",
      });
    }

    const businessCard = await B_CARD_COLLECTION.findOne({
      userId,
    });

    if (!businessCard) {
      return res.status(400).json({
        success: false,
        message: "Business Card not found",
      });
    }

    await B_CARD_COLLECTION.deleteOne({
      userId,
    });

    return res.status(201).json({
      success: true,
      message: "Business card delete successfully",
    });
  } catch (error) {
    console.error("Update Business Card Error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal Server error",
    });
  }
};
exports.fetchBusinessCard = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({
        success: false,
        message: "User authentication required",
      });
    }

    const businessCard = await B_CARD_COLLECTION.findOne({ userId });

    if (!businessCard) {
      return res.status(404).json({
        success: false,
        message: "Business card not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Business card fetched successfully",
      businessCard,
    });
  } catch (error) {
    console.error("Fetch Business Card Error:", error);

    return res.status(500).json({
      success: false,
      message: "Internal server error",
      error: error.message,
    });
  }
};
