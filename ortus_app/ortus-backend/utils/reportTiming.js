const slots = [
  "08:00-09:30",
  "10:00-11:30",
  "16:00-17:00",
  "18:00-20:00",
  "20:00-22:00",
];

const getSlotStart = (slot) => {
  const [start] = slot.split("-");
  const [hour, minute] = start.split(":").map((v) => parseInt(v, 10));
  return { hour, minute };
};

const getWindowTimes = (trainingDate, slot, offsetMinutes = -new Date().getTimezoneOffset()) => {
  const { hour, minute } = getSlotStart(slot);

  let year, month, day;
  if (typeof trainingDate === "string") {
    const [datePart] = trainingDate.split("T");
    const parts = datePart.split("-").map((v) => parseInt(v, 10));
    year = parts[0];
    month = parts[1] - 1; // JS Date month is 0-indexed
    day = parts[2];
  } else if (trainingDate instanceof Date) {
    year = trainingDate.getFullYear();
    month = trainingDate.getMonth();
    day = trainingDate.getDate();
  } else {
    throw new Error("Invalid trainingDate type");
  }

  // Construct training start time in client's local time (UTC representation)
  const localStartTimeMs = Date.UTC(year, month, day, hour, minute, 0, 0);
  
  // Convert to absolute UTC by subtracting the timezone offset
  const startTime = new Date(localStartTimeMs - offsetMinutes * 60 * 1000);

  const windowStart = new Date(startTime.getTime() - 60 * 60 * 1000);
  const windowEnd = new Date(startTime.getTime() - 30 * 60 * 1000);

  return { startTime, windowStart, windowEnd };
};

const isLateAt = (trainingDate, slot, now = new Date(), offsetMinutes = -new Date().getTimezoneOffset()) => {
  const { windowEnd } = getWindowTimes(trainingDate, slot, offsetMinutes);
  return now > windowEnd;
};

const canSubmitAt = (trainingDate, slot, now = new Date(), offsetMinutes = -new Date().getTimezoneOffset()) => {
  const { windowStart } = getWindowTimes(trainingDate, slot, offsetMinutes);
  return now >= windowStart;
};

module.exports = {
  slots,
  getWindowTimes,
  isLateAt,
  canSubmitAt,
};

