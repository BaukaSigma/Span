const express = require("express");
const {
  createBooking,
  getClientBookings,
  getTrainerBookings,
  cancelBooking,
  confirmBooking,
} = require("../controllers/bookingController");
const { protect } = require("../middlewares/authMiddleware");

const router = express.Router();

router.post("/", protect, createBooking);
router.get("/client", protect, getClientBookings);
router.get("/trainer", protect, getTrainerBookings);
router.patch("/:id/cancel", protect, cancelBooking);
router.patch("/:id/confirm", protect, confirmBooking);

module.exports = router;
