const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
dotenv.config();
const connectDB = require("./config/db");
const root = require("./routes/index");
const path = require("path");
const { startSequenceJob } = require("./jobs/sequence.job");
const { startGmailReplyJob } = require("./jobs/gmail_reply.job");

const app = express();

app.set("trust proxy", 1);

// ==========================================
// MIDDLEWARE
// ==========================================

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  }),
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ==========================================
// TEST ROUTE
// ==========================================

app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "High Custom Jewellers API is running",
    server: "Node.js + Express",
  });
});

// ==========================================
// API ROUTES
// ==========================================

app.use("/api", root);

startSequenceJob();

// ==========================================
// ERROR HANDLER
// ==========================================

app.use((err, req, res, next) => {
  console.error("SERVER ERROR:", err);

  const statusCode =
    err.statusCode || (err.name === "MulterError" ? 400 : 500);

  res.status(statusCode).json({
    success: false,
    message: statusCode === 400 ? err.message : "Internal Server Error",
  });
});

// ==========================================
// START SERVER
// ==========================================

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await connectDB();
    startGmailReplyJob();

    app.listen(PORT, "0.0.0.0", () => {
      console.log("");
      console.log("======================================");
      console.log("HIGH CUSTOM JEWELLERS SERVER");
      console.log("======================================");
      console.log(`Local:   http://localhost:${PORT}`);
      console.log(`Network: http://192.168.1.15:${PORT}`);
      console.log(`API:     http://192.168.1.15:${PORT}/api`);
      console.log("======================================");
      console.log("Server is ready...");
      console.log("");
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
};

startServer();
