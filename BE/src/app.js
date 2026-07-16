"use strict";

const express = require("express");
const cors = require("cors");
const logger = require("./middleware/logger");
const healthRoutes = require("./routes/health");
const apiRoutes = require("./routes/api");

const app = express();

app.use(cors());
app.use(express.json());
app.use(logger);

app.use(healthRoutes);
app.use("/api", apiRoutes);

app.use((_req, res) => {
  res.status(404).json({ error: "not_found" });
});

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: "internal_error" });
});

module.exports = app;
