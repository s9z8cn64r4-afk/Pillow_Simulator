// Tests für das Logging-Relay: `node --test relay/test`
import { test } from "node:test";
import assert from "node:assert/strict";
import { validateBatch, dedupe, buildMessages, sanitizeText, safeEqual, LIMITS } from "../src/core.js";
import worker from "../src/worker.js";

const batch = (events, extra = {}) => ({ v: 1, env: "DEV", place: 12, server: "abc123", events, ...extra });

test("gültiger Batch wird normalisiert, unbekannte Kategorien verworfen", () => {
  const r = validateBatch(batch([{ cat: "error", msg: "boom", count: 2 }, { cat: "nope", msg: "x" }]));
  assert.equal(r.ok, true);
  assert.equal(r.batch.events.length, 1);
  assert.equal(r.batch.events[0].count, 2);
  assert.equal(r.batch.dropped, 1);
});

test("falsche Version/Umgebung/leere Liste werden abgelehnt", () => {
  assert.equal(validateBatch({ ...batch([{ cat: "error", msg: "x" }]), v: 2 }).ok, false);
  assert.equal(validateBatch({ ...batch([{ cat: "error", msg: "x" }]), env: "LIVE" }).ok, false);
  assert.equal(validateBatch(batch([])).ok, false);
  assert.equal(validateBatch(batch(new Array(LIMITS.maxEvents + 1).fill({ cat: "error", msg: "x" }))).ok, false);
});

test("Datenschutz: Namen/UserIds in ctx werden entfernt, nur einfache Typen bleiben", () => {
  const r = validateBatch(
    batch([{ cat: "warn", msg: "m", ctx: { userId: 123, Name: "Bob", p: "a1b2", n: 3, ok: true, obj: { a: 1 } } }])
  );
  assert.deepEqual(r.batch.events[0].ctx, { p: "a1b2", n: 3, ok: true });
});

test("Erwähnungen werden entschärft, Texte gekürzt", () => {
  const s = sanitizeText("hi @everyone ```x```", 100);
  assert.ok(!s.includes("@everyone"));
  assert.ok(!s.includes("```"));
  assert.equal(sanitizeText("a".repeat(500), 300).length, 300);
});

test("Deduplizierung addiert Zähler gleicher Fingerprints", () => {
  const d = dedupe([
    { cat: "error", fp: "A", msg: "a", count: 2, ctx: {} },
    { cat: "error", fp: "A", msg: "a", count: 3, ctx: {} },
    { cat: "warn", fp: "A", msg: "a", count: 1, ctx: {} },
  ]);
  assert.equal(d.length, 2);
  assert.equal(d.find((e) => e.cat === "error").count, 5);
});

test("Nachrichten je Kanal, unter 2000 Zeichen, höchstens 3 je Kanal", () => {
  const events = [];
  for (let i = 0; i < 99; i++) events.push({ cat: "error", msg: `Fehler ${i} ` + "x".repeat(250), fp: `f${i}` });
  events.push({ cat: "feedback", msg: "More pillows" });
  const msgs = buildMessages(validateBatch(batch(events)).batch);
  const errs = msgs.filter((m) => m.channel === "ERRORS");
  assert.ok(errs.length <= LIMITS.maxMessagesPerChannel);
  assert.ok(msgs.every((m) => m.content.length <= 2000));
  assert.equal(msgs.filter((m) => m.channel === "FEEDBACK_INBOX").length, 1);
});

test("überlange Einzelzeile wird gekürzt statt die Grenze zu sprengen", () => {
  const ctx = {};
  for (let i = 0; i < 10; i++) ctx["k" + i] = "v".repeat(200);
  const msgs = buildMessages(validateBatch(batch([{ cat: "error", msg: "x".repeat(300), ctx }])).batch);
  assert.equal(msgs.length, 1);
  assert.ok(msgs[0].content.length <= 2000);
});

test("Token-Vergleich", () => {
  assert.equal(safeEqual("Bearer abc", "Bearer abc"), true);
  assert.equal(safeEqual("Bearer abc", "Bearer abd"), false);
  assert.equal(safeEqual("Bearer ab", "Bearer abc"), false);
});

// --- Worker mit simuliertem Discord ---
function withFetch(handler, fn) {
  const orig = globalThis.fetch;
  globalThis.fetch = handler;
  return fn().finally(() => {
    globalThis.fetch = orig;
  });
}
const env = { RELAY_TOKEN: "secret", WEBHOOK_ERRORS: "https://discord.test/err", WEBHOOK_FEEDBACK_INBOX: "https://discord.test/fb" };
const req = (body, token = "secret") =>
  new Request("https://relay.test/ingest", {
    method: "POST",
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: typeof body === "string" ? body : JSON.stringify(body),
  });

test("Worker: falsches Token → 401, nichts gesendet", async () => {
  let calls = 0;
  await withFetch(async () => {
    calls++;
    return new Response("{}");
  }, async () => {
    const res = await worker.fetch(req(batch([{ cat: "error", msg: "x" }]), "falsch"), env);
    assert.equal(res.status, 401);
  });
  assert.equal(calls, 0);
});

test("Worker: gültiger Batch → je Kanal ein Webhook-Aufruf, keine Massen-Erwähnungen", async () => {
  const posted = [];
  await withFetch(async (url, init) => {
    posted.push({ url, body: JSON.parse(init.body) });
    return new Response(null, { status: 204 });
  }, async () => {
    const res = await worker.fetch(
      req(batch([{ cat: "error", msg: "boom" }, { cat: "feedback", msg: "hi @everyone" }, { cat: "exploit", msg: "spam" }])),
      env
    );
    assert.equal(res.status, 202);
    const out = await res.json();
    assert.equal(out.sent, 2);
    assert.equal(out.skipped, 1); // ANTI_EXPLOIT-Webhook nicht konfiguriert
  });
  assert.deepEqual(posted.map((p) => p.url).sort(), ["https://discord.test/err", "https://discord.test/fb"]);
  for (const p of posted) assert.deepEqual(p.body.allowed_mentions, { parse: [] });
  assert.ok(!posted.find((p) => p.url.endsWith("/fb")).body.content.includes("@everyone"));
});

test("Worker: Discord-Rate-Limit (429) → ein Wiederholversuch", async () => {
  let n = 0;
  await withFetch(async () => {
    n++;
    return n === 1
      ? new Response(JSON.stringify({ retry_after: 0.01 }), { status: 429 })
      : new Response(null, { status: 204 });
  }, async () => {
    const res = await worker.fetch(req(batch([{ cat: "error", msg: "x" }])), env);
    assert.equal((await res.json()).sent, 1);
  });
  assert.equal(n, 2);
});

test("Worker: kaputtes JSON / zu groß / falscher Pfad", async () => {
  assert.equal((await worker.fetch(req("{kaputt"), env)).status, 400);
  assert.equal((await worker.fetch(req("x".repeat(LIMITS.maxBodyBytes + 1)), env)).status, 413);
  assert.equal((await worker.fetch(new Request("https://relay.test/other", { method: "POST" }), env)).status, 404);
  assert.equal((await worker.fetch(new Request("https://relay.test/health"), env)).status, 200);
});
