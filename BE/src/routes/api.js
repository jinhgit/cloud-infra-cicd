"use strict";

const express = require("express");
const config = require("../config");

const router = express.Router();

router.get("/", (_req, res) => {
  res.json({
    name: config.serviceName,
    version: "0.1.0",
    endpoints: ["/health", "/api", "/api/hello", "/api/info"],
  });
});

router.get("/hello", (_req, res) => {
  res.json({
    message: "Hello from BE",
    service: config.serviceName,
    timestamp: new Date().toISOString(),
  });
});

/** 배포 환경 메타 (디버그용, 민감정보 없음) */
router.get("/info", (_req, res) => {
  res.json({
    service: config.serviceName,
    env: config.nodeEnv,
    node: process.version,
    uptime_sec: Math.floor(process.uptime()),
  });
});

module.exports = router;
