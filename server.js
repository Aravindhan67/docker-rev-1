require("dotenv").config();
const express = require("express");
const path = require("path");
const client = require("prom-client");
const mongoose = require("mongoose");

const app = express();
const PORT = process.env.PORT || 3000;

// MongoDB Connection
const MONGO_URI = process.env.MONGO_URI;
if (MONGO_URI) {
  mongoose.connect(MONGO_URI)
    .then(() => {
      console.log("Connected to MongoDB Atlas");
      syncSubmissionCount();
    })
    .catch(err => console.error("Could not connect to MongoDB Atlas", err));
} else {
  console.warn("MONGO_URI not found. Data will not be persisted to MongoDB.");
}

// Student Schema & Model
const studentSchema = new mongoose.Schema({
  name: { type: String, required: true },
  rollNumber: { type: String, required: true },
  marks: { type: Number, required: true },
  submittedAt: { type: Date, default: Date.now }
});

const Student = mongoose.model("Student", studentSchema);

const students = []; // Temporary fallback or for legacy ref

client.collectDefaultMetrics();

const studentSubmissionCounter = new client.Gauge({
  name: "student_submissions_total",
  help: "Total number of student submissions"
});

async function syncSubmissionCount() {
  try {
    const count = await Student.countDocuments();
    studentSubmissionCounter.set(count);
    console.log(`Synced total submissions from MongoDB: ${count}`);
  } catch (error) {
    console.error("Error syncing submission count:", error);
  }
}

const submissionDuration = new client.Histogram({
  name: "student_submission_duration_seconds",
  help: "Duration of student submission requests",
  buckets: [0.05, 0.1, 0.25, 0.5, 1, 2]
});

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "public")));

function simulateCpuLoad(durationMs = 300) {
  const end = Date.now() + durationMs;
  let value = 0;

  while (Date.now() < end) {
    for (let i = 0; i < 25000; i += 1) {
      value += Math.sqrt(i * Math.random());
    }
  }

  return value;
}

app.get("/", (_req, res) => {
  res.send("Server Running");
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.get("/api/students", async (_req, res) => {
  try {
    const allStudents = await Student.find().sort({ submittedAt: -1 });
    res.json(allStudents);
  } catch (error) {
    res.status(500).json({ message: "Error fetching students", error: error.message });
  }
});

app.post("/student", async (req, res) => {
  const timer = submissionDuration.startTimer();
  const { name, rollNumber, marks } = req.body;

  if (!name || !rollNumber || marks === undefined) {
    timer();
    return res.status(400).json({ message: "name, rollNumber and marks are required" });
  }

  simulateCpuLoad(350);

  try {
    const student = new Student({
      name: String(name),
      rollNumber: String(rollNumber),
      marks: Number(marks)
    });

    await student.save();
    studentSubmissionCounter.inc();
    timer();

    return res.status(201).json({
      message: "Student result stored successfully in MongoDB",
      student
    });
  } catch (error) {
    timer();
    return res.status(500).json({ message: "Error saving student result", error: error.message });
  }
});

app.get("/metrics", async (_req, res) => {
  res.set("Content-Type", client.register.contentType);
  res.end(await client.register.metrics());
});

app.listen(PORT, () => {
  console.log(`Student Result Monitoring System running on port ${PORT}`);
});
