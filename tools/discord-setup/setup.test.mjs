// Tests für das Discord-Setup gegen einen simulierten Discord: `node --test tools/discord-setup/`
import { test } from "node:test";
import assert from "node:assert/strict";
import { setup, loadConfig, overwritesFor, automodPayload, client, PERM } from "./setup.mjs";

const GUILD = "1000";

// In-Memory-Discord mit den Endpunkten, die setup.mjs nutzt
function fakeDiscord({ communityEnabled = true } = {}) {
  let next = 2000;
  const state = { roles: [{ id: GUILD, name: "@everyone" }], channels: [], messages: {}, automod: [], calls: [] };
  const call = async (method, path, body) => {
    state.calls.push(`${method} ${path}`);
    if (method === "GET" && path === `/guilds/${GUILD}/roles`) return structuredClone(state.roles);
    if (method === "POST" && path === `/guilds/${GUILD}/roles`) {
      const r = { id: String(next++), ...body };
      state.roles.push(r);
      return r;
    }
    if (method === "GET" && path === `/guilds/${GUILD}/channels`) return structuredClone(state.channels);
    if (method === "POST" && path === `/guilds/${GUILD}/channels`) {
      if (!communityEnabled && (body.type === 5 || body.type === 15)) {
        const e = new Error("400 needs community");
        e.status = 400;
        throw e;
      }
      const c = { id: String(next++), ...body, parent_id: body.parent_id ?? null };
      state.channels.push(c);
      return c;
    }
    if (method === "GET" && path === "/users/@me") return { id: "bot" };
    let m = path.match(/^\/channels\/(\d+)\/messages/);
    if (m && method === "GET") return state.messages[m[1]] ?? [];
    if (m && method === "POST") {
      (state.messages[m[1]] ??= []).push({ author: { id: "bot" }, ...body });
      return {};
    }
    if (method === "GET" && path.endsWith("/auto-moderation/rules")) return structuredClone(state.automod);
    if (method === "POST" && path.endsWith("/auto-moderation/rules")) {
      state.automod.push({ id: String(next++), ...body });
      return {};
    }
    throw new Error(`unerwartet: ${method} ${path}`);
  };
  return { call, state };
}

const config = loadConfig();
const countChannels = () => config.categories.reduce((n, c) => n + c.channels.length, 0);

test("Erstlauf legt alles an: Rollen, Kategorien, Kanäle, Texte, AutoMod", async () => {
  const d = fakeDiscord();
  const res = await setup({ call: d.call, guildId: GUILD, config });
  assert.equal(d.state.roles.length, 1 + config.roles.length);
  assert.equal(d.state.channels.length, config.categories.length + countChannels());
  assert.equal(d.state.automod.length, config.automod.length);
  assert.equal(Object.keys(d.state.messages).length, 4); // welcome, rules, faq, tester-info
  assert.equal(res.warnings.length, 0);
  assert.ok(!d.state.channels.some((c) => c.name === "trading-talk"));
});

test("Zweiter Lauf ändert nichts (idempotent)", async () => {
  const d = fakeDiscord();
  await setup({ call: d.call, guildId: GUILD, config });
  const posts = d.state.calls.filter((c) => c.startsWith("POST")).length;
  const res = await setup({ call: d.call, guildId: GUILD, config });
  assert.equal(res.created.length, 0);
  assert.equal(d.state.calls.filter((c) => c.startsWith("POST")).length, posts);
});

test("Dry-Run schreibt nichts, plant aber alles", async () => {
  const d = fakeDiscord();
  const res = await setup({ call: d.call, guildId: GUILD, config, dryRun: true });
  assert.equal(d.state.calls.filter((c) => c.startsWith("POST")).length, 0);
  assert.ok(res.created.length >= config.roles.length + countChannels());
  // ohne Verbindung (kein Token) ebenfalls nur Plan
  const offline = await setup({ call: null, guildId: GUILD, config, dryRun: true });
  assert.equal(offline.created.length, res.created.length);
});

test("Tester- und Staff-Bereich sind für @everyone unsichtbar, Info ist nur lesbar", async () => {
  const d = fakeDiscord();
  await setup({ call: d.call, guildId: GUILD, config });
  const roleId = (n) => d.state.roles.find((r) => r.name === n).id;
  const ch = (n) => d.state.channels.find((c) => c.name === n);
  const ev = (c) => c.permission_overwrites.find((o) => o.id === GUILD);
  const has = (o, bit, key) => (BigInt(o[key]) & bit) !== 0n;
  // Tester-Kanal: @everyone sieht ihn nicht, Tester schon
  assert.ok(has(ev(ch("tester-feedback")), PERM.VIEW_CHANNEL, "deny"));
  const tester = ch("tester-feedback").permission_overwrites.find((o) => o.id === roleId("Tester"));
  assert.ok(has(tester, PERM.VIEW_CHANNEL, "allow") && has(tester, PERM.SEND_MESSAGES, "allow"));
  // tester-info: Tester lesen, schreiben nicht
  const tInfo = ch("tester-info").permission_overwrites.find((o) => o.id === roleId("Tester"));
  assert.ok(has(tInfo, PERM.SEND_MESSAGES, "deny"));
  // Staff: nur Moderator + Owner/Dev
  assert.ok(has(ev(ch("mod-chat")), PERM.VIEW_CHANNEL, "deny"));
  assert.ok(ch("mod-chat").permission_overwrites.some((o) => o.id === roleId("Moderator")));
  assert.ok(!ch("mod-chat").permission_overwrites.some((o) => o.id === roleId("Tester")));
  // Regeln: sichtbar, aber nicht beschreibbar; Moderatoren dürfen schreiben
  assert.ok(has(ev(ch("rules")), PERM.VIEW_CHANNEL, "allow") && has(ev(ch("rules")), PERM.SEND_MESSAGES, "deny"));
  // general: keine Einschränkung
  assert.deepEqual(ch("general").permission_overwrites, []);
});

test("Ohne Community-Modus: Ankündigungs-/Forum-Kanäle werden Textkanäle mit Hinweis", async () => {
  const d = fakeDiscord({ communityEnabled: false });
  const res = await setup({ call: d.call, guildId: GUILD, config });
  assert.equal(d.state.channels.find((c) => c.name === "announcements").type, 0);
  assert.equal(d.state.channels.find((c) => c.name === "bug-reports").type, 0);
  assert.ok(res.warnings.length >= 6);
});

test("Texte pingen niemanden", async () => {
  const d = fakeDiscord();
  await setup({ call: d.call, guildId: GUILD, config });
  for (const list of Object.values(d.state.messages)) {
    for (const m of list) assert.deepEqual(m.allowed_mentions, { parse: [] });
  }
});

test("AutoMod-Regeln haben gültige Discord-Formate", () => {
  const p = config.automod.map(automodPayload);
  assert.deepEqual(p[0].trigger_metadata.presets, [1, 2, 3]);
  assert.equal(p[1].trigger_type, 3);
  assert.equal(p[2].trigger_metadata.mention_total_limit, 5);
  assert.ok(p[3].trigger_metadata.regex_patterns.every((r) => r.length <= 260));
  assert.ok(new RegExp(config.automod[3].regex[0]).test("join discord.gg/abc123"));
  assert.ok(new RegExp(config.automod[3].regex[1], "i").test("FREE ROBUX here"));
});

test("Client wartet bei Rate-Limit (429) und versucht erneut", async () => {
  let n = 0;
  const waits = [];
  const fakeFetch = async () => {
    n++;
    return n === 1
      ? new Response(JSON.stringify({ retry_after: 0.25 }), { status: 429 })
      : new Response(JSON.stringify({ ok: 1 }), { status: 200 });
  };
  const call = client("t", fakeFetch, async (ms) => waits.push(ms));
  assert.deepEqual(await call("GET", "/x"), { ok: 1 });
  assert.deepEqual(waits, [250]);
});

test("overwritesFor: unbekannte Zugriffsart wirft", () => {
  assert.throws(() => overwritesFor("secret", false, GUILD, {}));
});
