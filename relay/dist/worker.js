// GENERIERT von relay/build.mjs – nicht von Hand bearbeiten. Quelle: relay/src/
// Komplett kopieren und im Cloudflare-Dashboard in den Worker-Editor einfügen.

// Reine Relay-Logik (ohne Netzwerk) – testbar mit `node --test relay/test`.
// Eingang: Batch vom Roblox-Server (RelayService). Ausgang: Discord-Nachrichten je Kanal.
// Datenschutz: keine Namen/UserIds (Felder werden verworfen), Erwähnungen (@everyone/@here/<@…>) entschärft.

const CATEGORIES = {
  critical: { channel: "ALERTS_CRITICAL", label: "CRITICAL", icon: "🚨" },
  error: { channel: "ERRORS", label: "ERROR", icon: "❌" },
  warn: { channel: "ERRORS", label: "WARN", icon: "⚠️" },
  exploit: { channel: "ANTI_EXPLOIT", label: "EXPLOIT", icon: "🛡️" },
  feedback: { channel: "FEEDBACK_INBOX", label: "FEEDBACK", icon: "💬" },
  session: { channel: "PLAYERS", label: "SESSIONS", icon: "👥" },
};

const LIMITS = {
  maxBodyBytes: 64 * 1024,
  maxEvents: 100,
  maxMsg: 300,
  maxCtxKeys: 10,
  maxCtxString: 200,
  maxDiscordContent: 1900, // Discord-Grenze 2000, Puffer für Präfix
  maxMessagesPerChannel: 3, // Rate-Limit-Schutz je Anfrage
};

const ENVS = new Set(["DEV", "BETA", "STG", "PROD"]);
const FORBIDDEN_KEYS = new Set(["userid", "user_id", "name", "displayname", "username", "ip", "email"]);

// Erwähnungen und Markdown-Codeblöcke entschärfen
function sanitizeText(value, max) {
  let s = String(value ?? "");
  s = s.replace(/[\u0000-\u0008\u000b-\u001f]/g, "");
  s = s.replace(/@/g, "@​").replace(/```/g, "'''");
  if (s.length > max) s = s.slice(0, max - 1) + "…";
  return s;
}

function cleanCtx(ctx) {
  const out = {};
  if (!ctx || typeof ctx !== "object" || Array.isArray(ctx)) return out;
  let n = 0;
  for (const [k, v] of Object.entries(ctx)) {
    if (n >= LIMITS.maxCtxKeys) break;
    if (FORBIDDEN_KEYS.has(k.toLowerCase())) continue;
    if (typeof v === "number" && Number.isFinite(v)) out[k] = v;
    else if (typeof v === "boolean") out[k] = v;
    else if (typeof v === "string") out[k] = sanitizeText(v, LIMITS.maxCtxString);
    else continue;
    n++;
  }
  return out;
}

// Prüft und normalisiert einen Batch. Gibt { ok, batch?, error? } zurück.
function validateBatch(body) {
  if (!body || typeof body !== "object") return { ok: false, error: "kein Objekt" };
  if (body.v !== 1) return { ok: false, error: "Version" };
  if (!ENVS.has(body.env)) return { ok: false, error: "Umgebung" };
  if (!Array.isArray(body.events) || body.events.length === 0) return { ok: false, error: "keine Events" };
  if (body.events.length > LIMITS.maxEvents) return { ok: false, error: "zu viele Events" };
  const events = [];
  let dropped = 0;
  for (const e of body.events) {
    if (!e || typeof e !== "object" || !CATEGORIES[e.cat] || typeof e.msg !== "string") {
      dropped++;
      continue;
    }
    events.push({
      cat: e.cat,
      msg: sanitizeText(e.msg, LIMITS.maxMsg),
      fp: typeof e.fp === "string" ? e.fp.slice(0, 80) : `${e.cat}:${e.msg.slice(0, 80)}`,
      count: Number.isInteger(e.count) && e.count > 0 ? Math.min(e.count, 1e6) : 1,
      ctx: cleanCtx(e.ctx),
    });
  }
  if (events.length === 0) return { ok: false, error: "keine gültigen Events" };
  return {
    ok: true,
    batch: {
      env: body.env,
      place: Number.isInteger(body.place) ? body.place : 0,
      server: typeof body.server === "string" ? body.server.replace(/[^\w-]/g, "").slice(0, 12) : "?",
      dropped: (Number.isInteger(body.dropped) ? body.dropped : 0) + dropped,
      events,
    },
  };
}

// Gleiche Fingerprints zusammenfassen (Zähler addieren)
function dedupe(events) {
  const byFp = new Map();
  for (const e of events) {
    const key = `${e.cat}|${e.fp}`;
    const prev = byFp.get(key);
    if (prev) prev.count += e.count;
    else byFp.set(key, { ...e });
  }
  return [...byFp.values()];
}

function formatCtx(ctx) {
  const parts = Object.entries(ctx).map(([k, v]) => `${k}=${v}`);
  return parts.length ? ` · ${parts.join(", ")}` : "";
}

// Baut Discord-Nachrichten: [{ channel, content }], max. maxMessagesPerChannel je Kanal
function buildMessages(batch) {
  const head = `**[${batch.env} v${batch.place} · ${batch.server}]**`;
  const groups = new Map();
  for (const e of dedupe(batch.events)) {
    const cfg = CATEGORIES[e.cat];
    let line = `${cfg.icon} \`${cfg.label}${e.count > 1 ? ` ×${e.count}` : ""}\` ${e.msg}${formatCtx(e.ctx)}`;
    // eine Zeile darf nie allein die Discord-Grenze sprengen
    const maxLine = LIMITS.maxDiscordContent - head.length - 20;
    if (line.length > maxLine) line = line.slice(0, maxLine - 1) + "…";
    if (!groups.has(cfg.channel)) groups.set(cfg.channel, []);
    groups.get(cfg.channel).push(line);
  }
  if (batch.dropped > 0) {
    if (!groups.has("ERRORS")) groups.set("ERRORS", []);
    groups.get("ERRORS").push(`⚠️ \`RELAY\` ${batch.dropped} Events verworfen (Puffer/Validierung)`);
  }
  const out = [];
  for (const [channel, lines] of groups) {
    let current = head;
    let count = 0;
    for (const line of lines) {
      if ((current + "\n" + line).length > LIMITS.maxDiscordContent) {
        out.push({ channel, content: current });
        count++;
        if (count >= LIMITS.maxMessagesPerChannel) {
          current = null;
          break;
        }
        current = head + " (Forts.)";
      }
      current += "\n" + line;
    }
    if (current !== null && count < LIMITS.maxMessagesPerChannel) out.push({ channel, content: current });
  }
  return out;
}

// Zeitkonstanter Vergleich (Token-Prüfung)
function safeEqual(a, b) {
  if (typeof a !== "string" || typeof b !== "string") return false;
  const len = Math.max(a.length, b.length);
  let diff = a.length ^ b.length;
  for (let i = 0; i < len; i++) diff |= (a.charCodeAt(i) || 0) ^ (b.charCodeAt(i) || 0);
  return diff === 0;
}

// Cloudflare Worker: nimmt Batches vom Roblox-Server an und leitet sie an Discord-Webhooks weiter.
// Secrets (wrangler secret put …): RELAY_TOKEN, WEBHOOK_ALERTS_CRITICAL, WEBHOOK_ERRORS,
// WEBHOOK_ANTI_EXPLOIT, WEBHOOK_FEEDBACK_INBOX, WEBHOOK_PLAYERS. Optional: CRITICAL_PING (z. B. "<@&ROLLEN-ID>").
// Keine Speicherung (kein KV) – Discord ist nur Benachrichtigungskanal.

const json = (status, obj) =>
  new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });

async function postDiscord(url, content, ping) {
  const body = {
    content: ping ? `${ping}\n${content}` : content,
    // Nur die konfigurierte Rolle darf pingen; nie @everyone/@here/Nutzer
    allowed_mentions: ping ? { parse: [], roles: [ping.replace(/\D/g, "")] } : { parse: [] },
  };
  for (let attempt = 0; attempt < 2; attempt++) {
    const res = await fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    if (res.status !== 429) return res.ok;
    // Rate-Limit: einmal kurz warten (max. 2 s), sonst aufgeben
    const data = await res.json().catch(() => ({}));
    const wait = Math.min(2000, Math.ceil((data.retry_after ?? 1) * 1000));
    await new Promise((r) => setTimeout(r, wait));
  }
  return false;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/health") return json(200, { ok: true });
    if (request.method !== "POST" || url.pathname !== "/ingest") return json(404, { ok: false });

    const auth = request.headers.get("authorization") ?? "";
    if (!env.RELAY_TOKEN || !safeEqual(auth, `Bearer ${env.RELAY_TOKEN}`)) return json(401, { ok: false });

    const raw = await request.text();
    if (raw.length > LIMITS.maxBodyBytes) return json(413, { ok: false, error: "zu groß" });
    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      return json(400, { ok: false, error: "JSON" });
    }
    const v = validateBatch(body);
    if (!v.ok) return json(400, { ok: false, error: v.error });

    let sent = 0;
    let skipped = 0;
    for (const m of buildMessages(v.batch)) {
      const hook = env[`WEBHOOK_${m.channel}`];
      if (!hook) {
        skipped++;
        continue;
      }
      const ping = m.channel === "ALERTS_CRITICAL" ? env.CRITICAL_PING : undefined;
      if (await postDiscord(hook, m.content, ping)) sent++;
    }
    return json(202, { ok: true, sent, skipped });
  },
};
