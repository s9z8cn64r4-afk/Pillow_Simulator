// Die Einzeldatei für das Dashboard (dist/worker.js) muss sich wie src/worker.js verhalten.
import { test } from "node:test";
import assert from "node:assert/strict";
import bundled from "../dist/worker.js";

test("dist/worker.js: Token-Prüfung und Weiterleitung wie die Quelle", async () => {
  const posted = [];
  const orig = globalThis.fetch;
  globalThis.fetch = async (url, init) => {
    posted.push({ url, body: JSON.parse(init.body) });
    return new Response(null, { status: 204 });
  };
  try {
    const env = { RELAY_TOKEN: "t", WEBHOOK_ERRORS: "https://discord.test/err" };
    const body = JSON.stringify({ v: 1, env: "BETA", place: 3, server: "x", events: [{ cat: "error", msg: "boom @here" }] });
    const bad = await bundled.fetch(new Request("https://r.test/ingest", { method: "POST", headers: { authorization: "Bearer nein" }, body }), env);
    assert.equal(bad.status, 401);
    const ok = await bundled.fetch(new Request("https://r.test/ingest", { method: "POST", headers: { authorization: "Bearer t" }, body }), env);
    assert.equal(ok.status, 202);
    assert.equal(posted.length, 1);
    assert.ok(!posted[0].body.content.includes("@here"));
  } finally {
    globalThis.fetch = orig;
  }
});
