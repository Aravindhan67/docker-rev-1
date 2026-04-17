require("dotenv").config();
const mongoose = require("mongoose");

const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("MONGO_URI not found");
  process.exit(1);
}

mongoose.connect(MONGO_URI)
  .then(() => {
    console.log("SUCCESS: Connected to MongoDB Atlas");
    process.exit(0);
  })
  .catch(err => {
    console.error("FAILURE: Could not connect to MongoDB Atlas", err);
    process.exit(1);
  });
