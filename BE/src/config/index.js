"use strict";

const config = {
  port: Number(process.env.PORT) || 3000,
  nodeEnv: process.env.NODE_ENV || "development",
  serviceName: process.env.SERVICE_NAME || "cloud-infra-be",
  appVersion: process.env.APP_VERSION || "0.1.0",
  gitSha: process.env.GIT_SHA || process.env.GITHUB_SHA || "dev",
};

module.exports = config;
