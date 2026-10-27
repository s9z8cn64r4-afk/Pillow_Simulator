// Cloudflare Worker: nimmt Batches vom Roblox-Server an und leitet sie an Discord-Webhooks weiter.
// Secrets (wrangler secret put …): RELAY_TOKEN, WEBHOOK_ALERTS_CRITICAL, WEBHOOK_ERRORS,
// WEBHOOK_ANTI_EXPLOIT, WEBHOOK_FEEDBACK_INBOX, WEBHOOK_PLAYERS. Optional: CRITICAL_PING (z. B. "<@&ROLLEN-ID>").
// Keine Speicherung (kein KV) – Discord ist nur Benachrichtigungskanal.
import { validateBatch, buildMessages, safeEqual, LIMITS } from "./core.js";

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
