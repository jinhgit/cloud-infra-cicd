"use strict";

const express = require("express");
const config = require("../config");

const router = express.Router();

router.get("/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
    service: config.serviceName,
    env: config.nodeEnv,
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;
