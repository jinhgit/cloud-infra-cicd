"use strict";

const express = require("express");
const config = require("../config");

const router = express.Router();

router.get("/", (_req, res) => {
  res.json({
    name: config.serviceName,
    version: "0.1.0",
    endpoints: ["/health", "/api", "/api/hello"],
  });
});

router.get("/hello", (_req, res) => {
  res.json({
    message: "Hello from BE",
    service: config.serviceName,
  });
});

module.exports = router;
