const Booking = require("../models/Booking");
const User = require("../models/User");
const { slots } = require("../utils/reportTiming");
const { sendBookingEmail } = require("../utils/email");

const createBooking = async (req, res) => {
  try {
    const { trainerId, trainingDate, slot, comment } = req.body;

    if (!trainerId || !trainingDate || !slot) {
      return res
        .status(400)
        .json({ message: "Пожалуйста, заполните все обязательные поля." });
    }

    if (!slots.includes(slot)) {
      return res.status(400).json({ message: "Неверный слот времени." });
    }

    const dateValue = new Date(trainingDate);
    if (dateValue.getTime() < Date.now()) {
      return res
        .status(400)
        .json({ message: "Нельзя записаться на прошедшее время." });
    }
    if (Number.isNaN(dateValue.getTime())) {
      return res.status(400).json({ message: "Неверный формат даты." });
    }

    // Check if trainer exists and is indeed a trainer
    const trainer = await User.findById(trainerId);
    if (!trainer || trainer.role !== "trainer") {
      return res.status(400).json({ message: "Указанный тренер не найден." });
    }

    // Check if client already booked this exact slot on this exact date
    const clientExists = await Booking.findOne({
      clientId: req.user._id,
      trainingDate: dateValue,
      slot,
      status: { $ne: "cancelled" },
    });
    if (clientExists) {
      return res
        .status(400)
        .json({ message: "Вы уже записаны на это время." });
    }
    const trainerBusy = await Booking.findOne({
      trainerId,
      trainingDate: dateValue,
      slot,
      status: { $ne: "cancelled" },
    });
    if (trainerBusy) {
      return res
        .status(400)
        .json({ message: "Тренер уже занят в это время." });
    }

    const booking = await Booking.create({
      clientId: req.user._id,
      trainerId,
      trainingDate: dateValue,
      slot,
      comment: comment || "",
    });

    // Populate data for response & email
    const populatedBooking = await Booking.findById(booking._id)
      .populate("clientId", "fullName phoneNumber")
      .populate("trainerId", "fullName phoneNumber");

    // Send email notification (asynchronous, don't await blocking response)
    sendBookingEmail({
      clientName: populatedBooking.clientId.fullName,
      clientPhone: populatedBooking.clientId.phoneNumber,
      trainerName: populatedBooking.trainerId.fullName,
      trainingDate: populatedBooking.trainingDate,
      slot: populatedBooking.slot,
      comment: populatedBooking.comment,
    }).catch((err) => console.error("Email notification failed:", err));

    res.status(201).json(populatedBooking);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getClientBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ clientId: req.user._id })
      .populate("trainerId", "fullName phoneNumber")
      .sort({ trainingDate: -1, createdAt: -1 });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getTrainerBookings = async (req, res) => {
  try {
    if (req.user.role !== "trainer") {
      return res.status(403).json({ message: "Доступ запрещен." });
    }
    const bookings = await Booking.find({ trainerId: req.user._id })
      .populate("clientId", "fullName phoneNumber")
      .sort({ trainingDate: -1, createdAt: -1 });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({ message: "Запись не найдена." });
    }

    // Only allow client who booked, or trainer, or manager/director to cancel
    const isClient = booking.clientId.toString() === req.user._id.toString();
    const isTrainer = booking.trainerId.toString() === req.user._id.toString();
    const isStaff = ["director", "manager"].includes(req.user.role);

    if (!isClient && !isTrainer && !isStaff) {
      return res.status(403).json({ message: "Доступ запрещен." });
    }

    booking.status = "cancelled";
    await booking.save();

    res.json({ message: "Запись успешно отменена.", booking });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const confirmBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) {
      return res.status(404).json({ message: "Запись не найдена." });
    }

    const isTrainer = booking.trainerId.toString() === req.user._id.toString();
    const isStaff = ["director", "manager"].includes(req.user.role);

    if (!isTrainer && !isStaff) {
      return res.status(403).json({ message: "Доступ запрещен." });
    }

    booking.status = "confirmed";
    await booking.save();

    res.json({ message: "Запись успешно подтверждена.", booking });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createBooking,
  getClientBookings,
  getTrainerBookings,
  cancelBooking,
  confirmBooking,
};
