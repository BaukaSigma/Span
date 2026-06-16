const Report = require("../models/Report");
const { uploadBuffer } = require("../utils/cloudinaryUpload");
const { slots, canSubmitAt, isLateAt } = require("../utils/reportTiming");

const allowedMime = new Set([
  "image/jpeg",
  "image/png",
  "application/pdf",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
]);

const createReport = async (req, res) => {
  try {
    if (req.user.role !== "trainer") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { trainingDate, slot, comment } = req.body;

    if (!trainingDate || !slot) {
      return res
        .status(400)
        .json({ message: "Дата и слот обязательны" });
    }

    if (!slots.includes(slot)) {
      return res.status(400).json({ message: "Invalid slot" });
    }

    const dateValue = new Date(trainingDate);
    if (Number.isNaN(dateValue.getTime())) {
      return res.status(400).json({ message: "Invalid date" });
    }

    const files = req.files || [];
    if (files.length === 0) {
      return res.status(400).json({ message: "Добавьте вложения" });
    }
    if (files.length > 4) {
      return res.status(400).json({ message: "Максимум 4 вложения" });
    }

    const now = new Date();
    const offsetMinutes = parseInt(
      req.headers["x-timezone-offset"] || (-new Date().getTimezoneOffset()).toString(),
      10
    );

    if (!canSubmitAt(trainingDate, slot, now, offsetMinutes)) {
      return res.status(400).json({
        message: "Отправка доступна за 60 минут до тренировки",
      });
    }

    const attachments = [];
    for (const file of files) {
      if (!allowedMime.has(file.mimetype)) {
        return res.status(400).json({ message: "Unsupported file type" });
      }
      const resourceType = file.mimetype.startsWith("image/")
        ? "image"
        : "raw";
      const uploaded = await uploadBuffer(file.buffer, {
        folder: "ortus/reports",
        resource_type: resourceType,
        originalname: file.originalname,
      });
      attachments.push({
        url: uploaded.secure_url,
        publicId: uploaded.public_id,
        resourceType,
        fileType: file.mimetype,
        originalName: file.originalname,
      });
    }

    const report = await Report.create({
      trainerId: req.user._id,
      trainingDate: dateValue,
      slot,
      comment: comment || "",
      attachments,
      isLate: isLateAt(trainingDate, slot, now, offsetMinutes),
    });

    res.status(201).json(report);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getMyReports = async (req, res) => {
  try {
    if (req.user.role !== "trainer") {
      return res.status(403).json({ message: "Access denied" });
    }

    const reports = await Report.find({ trainerId: req.user._id }).sort({
      createdAt: -1,
    });
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteReport = async (req, res) => {
  try {
    if (req.user.role !== "trainer") {
      return res.status(403).json({ message: "Access denied" });
    }

    const report = await Report.findById(req.params.id);
    if (!report) {
      return res.status(404).json({ message: "Report not found" });
    }

    if (report.trainerId.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: "Access denied" });
    }

    await report.deleteOne();
    res.json({ message: "Report deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getReports = async (req, res) => {
  try {
    if (!["manager", "director"].includes(req.user.role)) {
      return res.status(403).json({ message: "Access denied" });
    }

    const { dateFrom, dateTo, trainerId, isLate } = req.query;
    const filter = {};

    if (trainerId) filter.trainerId = trainerId;

    if (dateFrom || dateTo) {
      filter.trainingDate = {};
      if (dateFrom) filter.trainingDate.$gte = new Date(dateFrom);
      if (dateTo) filter.trainingDate.$lte = new Date(dateTo);
    }

    if (isLate === "true" || isLate === "false") {
      filter.isLate = isLate === "true";
    }

    const reports = await Report.find(filter)
      .populate("trainerId", "fullName phoneNumber")
      .sort({ trainingDate: -1, createdAt: -1 });
    res.json(reports);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createReport,
  getMyReports,
  deleteReport,
  getReports,
  slots,
};
