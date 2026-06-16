const test = require("node:test");
const assert = require("node:assert/strict");

const Booking = require("../models/Booking");
const User = require("../models/User");
const { createBooking } = require("../controllers/bookingController");

function responseRecorder() {
  return {
    statusCode: 200,
    body: undefined,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(payload) {
      this.body = payload;
      return this;
    },
  };
}

async function withPatchedModels(patches, run) {
  const originals = new Map();
  for (const [target, methods] of patches) {
    for (const [name, replacement] of Object.entries(methods)) {
      originals.set(`${target.modelName}.${name}`, { target, name, value: target[name] });
      target[name] = replacement;
    }
  }

  try {
    await run();
  } finally {
    for (const { target, name, value } of originals.values()) {
      target[name] = value;
    }
  }
}

test("createBooking rejects a trainer slot that is already booked by another client", async () => {
  let createCalled = false;
  const req = {
    user: { _id: "client-2", role: "client" },
    body: {
      trainerId: "trainer-1",
      trainingDate: "2030-01-01T08:00:00.000Z",
      slot: "08:00-09:30",
      comment: "",
    },
  };
  const res = responseRecorder();

  await withPatchedModels(
    [
      [User, { findById: async () => ({ _id: "trainer-1", role: "trainer" }) }],
      [Booking, {
        findOne: async (query) => {
          if (query.clientId === "client-2") return null;
          if (query.trainerId === "trainer-1") return { _id: "existing-booking" };
          return null;
        },
        create: async () => {
          createCalled = true;
          return { _id: "new-booking" };
        },
      }],
    ],
    async () => createBooking(req, res)
  );

  assert.equal(res.statusCode, 400);
  assert.match(res.body.message, /тренер|занят|время/i);
  assert.equal(createCalled, false);
});

test("createBooking rejects training dates in the past", async () => {
  let findOneCalled = false;
  const req = {
    user: { _id: "client-1", role: "client" },
    body: {
      trainerId: "trainer-1",
      trainingDate: "2000-01-01T08:00:00.000Z",
      slot: "08:00-09:30",
      comment: "",
    },
  };
  const res = responseRecorder();

  await withPatchedModels(
    [
      [User, { findById: async () => ({ _id: "trainer-1", role: "trainer" }) }],
      [Booking, {
        findOne: async () => {
          findOneCalled = true;
          return null;
        },
      }],
    ],
    async () => createBooking(req, res)
  );

  assert.equal(res.statusCode, 400);
  assert.match(res.body.message, /прошед/i);
  assert.equal(findOneCalled, false);
});
