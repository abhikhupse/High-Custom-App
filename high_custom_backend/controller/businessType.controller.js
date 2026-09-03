const BusinessType = require("../model/businessType.model");
const Sequence = require("../model/sequence.model");
const Leads = require("../model/leads.model");

exports.listBusinessTypes = async (req, res) => {
  try {
    const items = await BusinessType.find({ userId: req.user.id })
      .sort({ name: 1 })
      .select("name createdAt updatedAt")
      .lean();

    return res.status(200).json({ success: true, data: items });
  } catch (error) {
    console.error("LIST BUSINESS TYPES ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to load business types.",
    });
  }
};

exports.createBusinessType = async (req, res) => {
  try {
    const name = typeof req.body.name === "string" ? req.body.name.trim() : "";

    if (name.length < 2 || name.length > 100) {
      return res.status(400).json({
        success: false,
        message: "Business type must contain between 2 and 100 characters.",
      });
    }

    const item = await BusinessType.create({
      userId: req.user.id,
      name,
      normalizedName: name.toLowerCase(),
    });

    return res.status(201).json({
      success: true,
      message: "Business type added successfully.",
      data: { _id: item._id, name: item.name },
    });
  } catch (error) {
    if (error?.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "This business type already exists.",
      });
    }

    console.error("CREATE BUSINESS TYPE ERROR:", error);
    return res.status(500).json({
      success: false,
      message: "Unable to add business type.",
    });
  }
};

exports.updateBusinessType = async (req, res) => {
  try {
    const name = typeof req.body.name === "string" ? req.body.name.trim() : "";
    if (name.length < 2 || name.length > 100) {
      return res.status(400).json({
        success: false,
        message: "Business type must contain between 2 and 100 characters.",
      });
    }

    const item = await BusinessType.findOne({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!item) {
      return res
        .status(404)
        .json({ success: false, message: "Business type not found." });
    }

    const previousName = item.name;
    item.name = name;
    item.normalizedName = name.toLowerCase();
    await item.save();

    await Promise.all([
      Sequence.updateMany(
        { userId: req.user.id, businessType: previousName },
        { $set: { businessType: name } },
      ),
      Leads.updateMany(
        { userId: req.user.id, businessType: previousName },
        { $set: { businessType: name } },
      ),
    ]);

    return res.status(200).json({
      success: true,
      message: "Business type updated successfully.",
      data: { _id: item._id, name: item.name },
    });
  } catch (error) {
    if (error?.code === 11000) {
      return res
        .status(409)
        .json({
          success: false,
          message: "This business type already exists.",
        });
    }
    console.error("UPDATE BUSINESS TYPE ERROR:", error);
    return res
      .status(500)
      .json({ success: false, message: "Unable to update business type." });
  }
};

exports.deleteBusinessType = async (req, res) => {
  try {
    const item = await BusinessType.findOne({
      _id: req.params.id,
      userId: req.user.id,
    });
    if (!item) {
      return res
        .status(404)
        .json({ success: false, message: "Business type not found." });
    }

    const sequenceExists = await Sequence.exists({
      userId: req.user.id,
      businessType: item.name,
    });
    if (sequenceExists) {
      return res.status(409).json({
        success: false,
        message:
          "Can't delete the business type because a sequence already exists for this business type.",
      });
    }

    await item.deleteOne();
    return res.status(200).json({
      success: true,
      message: "Business type deleted successfully.",
    });
  } catch (error) {
    console.error("DELETE BUSINESS TYPE ERROR:", error);
    return res
      .status(500)
      .json({ success: false, message: "Unable to delete business type." });
  }
};
