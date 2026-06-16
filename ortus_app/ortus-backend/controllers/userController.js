const User = require("../models/User");

const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { fullName, phoneNumber, password } = req.body;
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (fullName) user.fullName = fullName;
    if (phoneNumber) user.phoneNumber = phoneNumber;
    if (password) user.password = password;

    await user.save();

    const safeUser = user.toObject();
    delete safeUser.password;

    res.json(safeUser);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createStaff = async (req, res) => {
  try {
    if (req.user.role !== "director") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { phoneNumber, fullName, password, role } = req.body;

    if (!phoneNumber || !fullName || !password || !role) {
      return res
        .status(400)
        .json({ message: "Заполните все обязательные поля" });
    }

    if (!["trainer", "manager"].includes(role)) {
      return res.status(400).json({ message: "Invalid staff role" });
    }

    const existing = await User.findOne({ phoneNumber });
    if (existing) {
      return res
        .status(400)
        .json({ message: "Пользователь с таким телефоном уже существует" });
    }

    const staff = await User.create({
      phoneNumber,
      fullName,
      password,
      role,
      status: "active",
    });

    const safeStaff = staff.toObject();
    delete safeStaff.password;

    res.status(201).json(safeStaff);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const listStaff = async (req, res) => {
  try {
    if (req.user.role !== "director") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { role, status } = req.query;
    const filter = { role: { $in: ["trainer", "manager"] } };

    if (role && ["trainer", "manager"].includes(role)) {
      filter.role = role;
    }
    if (status && ["active", "inactive"].includes(status)) {
      filter.status = status;
    }

    const staff = await User.find(filter)
      .select("-password")
      .sort({ createdAt: -1 });
    res.json(staff);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateStaffStatus = async (req, res) => {
  try {
    if (req.user.role !== "director") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { id } = req.params;
    const { status } = req.body;

    if (!["active", "inactive"].includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    const staff = await User.findById(id);
    if (!staff || !["trainer", "manager"].includes(staff.role)) {
      return res.status(404).json({ message: "Staff not found" });
    }

    staff.status = status;
    await staff.save();

    const safeStaff = staff.toObject();
    delete safeStaff.password;

    res.json(safeStaff);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteStaff = async (req, res) => {
  try {
    if (req.user.role !== "director") {
      return res.status(403).json({ message: "Access denied" });
    }

    const { id } = req.params;
    const staff = await User.findById(id);

    if (!staff || !["trainer", "manager"].includes(staff.role)) {
      return res.status(404).json({ message: "Staff not found" });
    }

    await staff.deleteOne();
    res.json({ message: "Staff deleted" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const listTrainers = async (req, res) => {
  try {
    const trainers = await User.find({ role: "trainer", status: "active" })
      .select("fullName phoneNumber")
      .sort({ fullName: 1 });
    res.json(trainers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getProfile,
  updateProfile,
  createStaff,
  listStaff,
  updateStaffStatus,
  deleteStaff,
  listTrainers,
};
