const express = require("express");
const {
  getProfile,
  updateProfile,
  createStaff,
  listStaff,
  updateStaffStatus,
  deleteStaff,
  listTrainers,
} = require("../controllers/userController");
const { protect } = require("../middlewares/authMiddleware");
const router = express.Router();

router.get("/profile", protect, getProfile);
router.put("/profile", protect, updateProfile);
router.get("/trainers", protect, listTrainers);
router.get("/staff", protect, listStaff);
router.post("/staff", protect, createStaff);
router.patch("/staff/:id/status", protect, updateStaffStatus);
router.delete("/staff/:id", protect, deleteStaff);

module.exports = router;
