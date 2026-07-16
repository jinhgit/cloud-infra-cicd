"use strict";

const { describe, it } = require("node:test");
const assert = require("node:assert/strict");
const http = require("node:http");
const app = require("../src/app");

function request(server, path) {
  const { port } = server.address();
  return new Promise((resolve, reject) => {
    http
      .get(`http://127.0.0.1:${port}${path}`, (res) => {
        let body = "";
        res.on("data", (chunk) => (body += chunk));
        res.on("end", () => {
          resolve({
            status: res.statusCode,
            body: body ? JSON.parse(body) : {},
          });
        });
      })
      .on("error", reject);
  });
}

describe("API routes", () => {
  it("GET /api/hello returns message", async () => {
    const server = http.createServer(app);
    await new Promise((resolve) => server.listen(0, resolve));
    try {
      const data = await request(server, "/api/hello");
      assert.equal(data.status, 200);
      assert.equal(data.body.message, "Hello from BE");
      assert.ok(data.body.gitSha);
    } finally {
      server.close();
    }
  });

  it("GET /api/info returns service meta and version", async () => {
    const server = http.createServer(app);
    await new Promise((resolve) => server.listen(0, resolve));
    try {
      const data = await request(server, "/api/info");
      assert.equal(data.status, 200);
      assert.ok(data.body.service);
      assert.ok(data.body.version);
      assert.ok(data.body.gitSha);
      assert.ok(typeof data.body.uptime_sec === "number");
    } finally {
      server.close();
    }
  });
});
