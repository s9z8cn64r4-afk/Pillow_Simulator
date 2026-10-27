// Richtet den Community-Discord (Server A) nach server-a.json ein – idempotent (Masterprompt I.5).
// Aufruf: DISCORD_BOT_TOKEN=… node setup.mjs --guild <Server-ID> [--dry-run]
//   oder über GitHub Actions „Discord Setup“ (Token als Repository-Secret DISCORD_BOT_TOKEN).
// Ohne Token und mit --dry-run: zeigt nur den Plan aus der Konfiguration.
// Der Bot braucht: Manage Roles, Manage Channels, Manage Server (AutoMod), Send Messages, View Channels.
import { readFileSync } from "node:fs";

const API = "https://discord.com/api/v10";
export const PERM = {
  ADD_REACTIONS: 1n << 6n,
  VIEW_CHANNEL: 1n << 10n,
  SEND_MESSAGES: 1n << 11n,
  CREATE_PUBLIC_THREADS: 1n << 35n,
  SEND_MESSAGES_IN_THREADS: 1n << 38n,
};
const SEND = PERM.SEND_MESSAGES | PERM.SEND_MESSAGES_IN_THREADS | PERM.CREATE_PUBLIC_THREADS;
const TYPES = { text: 0, category: 4, announcement: 5, forum: 15 };
const PRESETS = { profanity: 1, sexual_content: 2, slurs: 3 };
const STAFF = ["Owner/Dev", "Moderator"];

export function loadConfig(path = new URL("./server-a.json", import.meta.url)) {
  return JSON.parse(readFileSync(path, "utf8"));
}

export function loadText(name) {
  return readFileSync(new URL(`./texts/${name}.md`, import.meta.url), "utf8").trim();
}

const colorInt = (hex) => (hex ? parseInt(hex.slice(1), 16) : 0);
const ow = (id, allow = 0n, deny = 0n) => ({ id, type: 0, allow: allow.toString(), deny: deny.toString() });

// Berechtigungen je Zugriffsart (auf Kategorie und Kanal identisch gesetzt)
export function overwritesFor(access, channelReadonly, guildId, roleIds) {
  const staff = STAFF.map((n) => roleIds[n]).filter(Boolean);
  if (access === "public") {
    return channelReadonly ? [ow(guildId, 0n, SEND), ...staff.map((id) => ow(id, SEND))] : [];
  }
  if (access === "readonly") {
    return [ow(guildId, PERM.VIEW_CHANNEL, SEND), ...staff.map((id) => ow(id, SEND))];
  }
  if (access.startsWith("role:")) {
    const role = roleIds[access.slice(5)];
    const list = [ow(guildId, 0n, PERM.VIEW_CHANNEL)];
    if (role && !staff.includes(role)) {
      list.push(ow(role, channelReadonly ? PERM.VIEW_CHANNEL : PERM.VIEW_CHANNEL | SEND, channelReadonly ? SEND : 0n));
    }
    for (const id of staff) list.push(ow(id, PERM.VIEW_CHANNEL | SEND));
    return list;
  }
  throw new Error(`unbekannte Zugriffsart ${access}`);
}

export function automodPayload(rule) {
  const base = { name: rule.name, event_type: 1, enabled: true, actions: [{ type: 1 }] };
  switch (rule.trigger) {
    case "keyword_preset":
      return { ...base, trigger_type: 4, trigger_metadata: { presets: rule.presets.map((p) => PRESETS[p]) } };
    case "spam":
      return { ...base, trigger_type: 3 };
    case "mention_spam":
      return { ...base, trigger_type: 5, trigger_metadata: { mention_total_limit: rule.limit ?? 5 } };
    case "keyword":
      return { ...base, trigger_type: 1, trigger_metadata: { regex_patterns: rule.regex } };
    default:
      throw new Error(`unbekannter AutoMod-Trigger ${rule.trigger}`);
  }
}

// Minimaler Discord-Client mit Rate-Limit-Behandlung (429 → warten, max. 5 Versuche)
export function client(token, fetchImpl = fetch, sleep = (ms) => new Promise((r) => setTimeout(r, ms))) {
  return async function call(method, path, body) {
    for (let attempt = 0; attempt < 5; attempt++) {
      const res = await fetchImpl(API + path, {
        method,
        headers: { authorization: `Bot ${token}`, "content-type": "application/json" },
        body: body ? JSON.stringify(body) : undefined,
      });
      if (res.status === 429) {
        const data = await res.json().catch(() => ({}));
        await sleep(Math.ceil((data.retry_after ?? 1) * 1000));
        continue;
      }
      const text = await res.text();
      const data = text ? JSON.parse(text) : null;
      if (!res.ok) {
        const err = new Error(`${method} ${path} → ${res.status} ${data?.message ?? ""}`);
        err.status = res.status;
        err.code = data?.code;
        throw err;
      }
      return data;
    }
    throw new Error(`${method} ${path}: Rate-Limit, aufgegeben`);
  };
}

// Plan + Ausführung. Gibt ein Protokoll zurück: { created: [...], existing: [...], warnings: [...] }
export async function setup({ call, guildId, config, dryRun = false, log = () => {} }) {
  const out = { created: [], existing: [], warnings: [] };
  const note = (kind, what) => {
    out[kind].push(what);
    log(`${kind === "created" ? (dryRun ? "+ (geplant)" : "+") : kind === "existing" ? "=" : "!"} ${what}`);
  };
  const online = Boolean(call);

  // Rollen
  const roles = online ? await call("GET", `/guilds/${guildId}/roles`) : [];
  const roleIds = Object.fromEntries(roles.map((r) => [r.name, r.id]));
  for (const r of config.roles) {
    if (roleIds[r.name]) {
      note("existing", `Rolle ${r.name}`);
      continue;
    }
    note("created", `Rolle ${r.name}`);
    if (!dryRun) {
      const made = await call("POST", `/guilds/${guildId}/roles`, {
        name: r.name,
        color: colorInt(r.color),
        hoist: Boolean(r.hoist),
        mentionable: Boolean(r.mentionable),
        permissions: "0",
      });
      roleIds[r.name] = made.id;
    } else {
      roleIds[r.name] = `dry:${r.name}`;
    }
  }

  // Kategorien + Kanäle
  const channels = online ? await call("GET", `/guilds/${guildId}/channels`) : [];
  const find = (name, type, parent) =>
    channels.find((c) => c.name === name && (type === undefined || c.type === type) && (parent === undefined || c.parent_id === parent));
  const postQueue = [];
  for (const cat of config.categories) {
    let catCh = find(cat.name, TYPES.category);
    if (catCh) note("existing", `Kategorie ${cat.name}`);
    else {
      note("created", `Kategorie ${cat.name}`);
      catCh = dryRun
        ? { id: `dry:${cat.name}` }
        : await call("POST", `/guilds/${guildId}/channels`, {
            name: cat.name,
            type: TYPES.category,
            permission_overwrites: overwritesFor(cat.access, false, guildId, roleIds),
          });
      channels.push({ ...catCh, name: cat.name, type: TYPES.category });
    }
    for (const ch of cat.channels) {
      const existing = channels.find((c) => c.name === ch.name && c.parent_id === catCh.id);
      if (existing) {
        note("existing", `#${ch.name}`);
        if (ch.post) postQueue.push({ channel: existing, post: ch.post });
        continue;
      }
      note("created", `#${ch.name} (${ch.type})`);
      if (dryRun) {
        if (ch.post) note("created", `Text in #${ch.name}`);
        continue;
      }
      const body = {
        name: ch.name,
        type: TYPES[ch.type],
        parent_id: catCh.id,
        topic: ch.topic,
        rate_limit_per_user: ch.slowmode ?? 0,
        permission_overwrites: overwritesFor(cat.access, Boolean(ch.readonly), guildId, roleIds),
      };
      if (ch.type === "forum") body.available_tags = (ch.tags ?? []).map((name) => ({ name }));
      let made;
      try {
        made = await call("POST", `/guilds/${guildId}/channels`, body);
      } catch (e) {
        // Ankündigungs-/Forum-Kanäle brauchen den Community-Modus → als Textkanal anlegen und Hinweis geben
        if (ch.type !== "text" && e.status === 400) {
          note("warnings", `#${ch.name}: ${ch.type} nicht möglich (Community-Modus aus?) – als Textkanal angelegt`);
          delete body.available_tags;
          made = await call("POST", `/guilds/${guildId}/channels`, { ...body, type: TYPES.text });
        } else throw e;
      }
      channels.push(made);
      if (ch.post) postQueue.push({ channel: made, post: ch.post });
    }
  }

  // Begrüßungs-/Regeltexte: nur posten, wenn der Bot dort noch nichts geschrieben hat
  if (online && postQueue.length) {
    const me = await call("GET", `/users/@me`);
    for (const { channel, post } of postQueue) {
      const msgs = await call("GET", `/channels/${channel.id}/messages?limit=20`);
      if (msgs.some((m) => m.author?.id === me.id)) {
        note("existing", `Text in #${channel.name}`);
        continue;
      }
      note("created", `Text in #${channel.name}`);
      if (!dryRun) {
        await call("POST", `/channels/${channel.id}/messages`, { content: loadText(post), allowed_mentions: { parse: [] } });
      }
    }
  }

  // AutoMod
  const rules = online ? await call("GET", `/guilds/${guildId}/auto-moderation/rules`) : [];
  for (const rule of config.automod) {
    if (rules.some((r) => r.name === rule.name)) {
      note("existing", `AutoMod ${rule.name}`);
      continue;
    }
    note("created", `AutoMod ${rule.name}`);
    if (!dryRun) {
      try {
        await call("POST", `/guilds/${guildId}/auto-moderation/rules`, automodPayload(rule));
      } catch (e) {
        note("warnings", `AutoMod ${rule.name}: ${e.message}`);
      }
    }
  }
  return out;
}

// CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);
  const guildId = args[args.indexOf("--guild") + 1];
  const dryRun = args.includes("--dry-run");
  const token = process.env.DISCORD_BOT_TOKEN;
  if (!dryRun && (!token || !guildId || args.indexOf("--guild") < 0)) {
    console.error("Benötigt: DISCORD_BOT_TOKEN (Umgebung) und --guild <Server-ID>. Zum Ansehen: --dry-run");
    process.exit(2);
  }
  const call = token && guildId ? client(token) : null;
  const res = await setup({ call, guildId, config: loadConfig(), dryRun, log: console.log });
  console.log(
    `\n${dryRun ? "Plan" : "Fertig"}: ${res.created.length} neu, ${res.existing.length} vorhanden, ${res.warnings.length} Hinweise`
  );
  if (res.warnings.length) console.log(res.warnings.map((w) => "! " + w).join("\n"));
}
