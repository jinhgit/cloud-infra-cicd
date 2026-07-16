"use strict";

const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const app = require("../src/app");

describe("GET /health", () => {
  it("returns 200 and status ok", async () => {
    const server = http.createServer(app);
    await new Promise((resolve) => server.listen(0, resolve));
    const { port } = server.address();

    const data = await new Promise((resolve, reject) => {
      http
        .get(`http://127.0.0.1:${port}/health`, (res) => {
          let body = "";
          res.on("data", (chunk) => (body += chunk));
          res.on("end", () => {
            resolve({ status: res.statusCode, body: JSON.parse(body) });
          });
        })
        .on("error", reject);
    });

    server.close();
    assert.equal(data.status, 200);
    assert.equal(data.body.status, "ok");
  });
});
