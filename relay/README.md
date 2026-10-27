# Logging-Relay (Roblox → Discord)

Kleiner Cloudflare Worker (kostenloses Kontingent, keine Datenbank). Nimmt gebündelte Meldungen vom Roblox-Server
(`RelayService`) an, prüft Token/Format/Größe, fasst gleiche Fehler zusammen und postet je Kanal eine Nachricht in den
**privaten** Log-Discord (Server B). Architektur: Masterprompt I.4, `docs/decisions/ADR-0004-logging-relay.md`.

## Kanäle (je ein Webhook)
| Secret | Discord-Kanal | Inhalt |
|---|---|---|
| `WEBHOOK_ALERTS_CRITICAL` | `#alerts-critical` | kritische Fehler (optional Rollen-Ping `CRITICAL_PING`) |
| `WEBHOOK_ERRORS` | `#errors` | Skriptfehler, Warnungen (zusammengefasst mit Zähler) |
| `WEBHOOK_ANTI_EXPLOIT` | `#anti-exploit` | Netz-Verstöße, Kicks (Spieler nur als Pseudonym) |
| `WEBHOOK_FEEDBACK_INBOX` | `#feedback-inbox` | gefiltertes Spieler-Feedback |
| `WEBHOOK_PLAYERS` | `#players` | Sitzungs-Summen je 30 s (Anzahl, Spielzeit, neue Spieler, Tutorial) |

Fehlt ein Webhook, wird der Kanal einfach übersprungen.

## Einrichtung (Owner, einmalig ~15 Min.)
1. **Discord:** privaten Server „Pillow Logs“ anlegen, die Kanäle oben erstellen, je Kanal *Integrationen → Webhook erstellen → URL kopieren*.
2. **Cloudflare (ohne Terminal):** Workers & Pages → Create Worker → *Edit code* → Inhalt von `dist/worker.js` einfügen → Deploy; Secrets unter *Settings → Variables and Secrets* (Typ Secret).
   **Oder mit Terminal**, in diesem Ordner:
   ```
   cp wrangler.toml.example wrangler.toml
   npx wrangler login
   npx wrangler deploy
   npx wrangler secret put RELAY_TOKEN            # langes Zufallspasswort (z. B. 40 Zeichen)
   npx wrangler secret put WEBHOOK_ERRORS         # Webhook-URL einfügen, ebenso die anderen
   ```
   Test: `https://pillow-relay.<konto>.workers.dev/health` → `{"ok":true}`.
3. **Roblox:** Spiel → Experience Settings → Security: **Allow HTTP Requests** an; unter **Secrets** anlegen:
   - `relay_url` = `https://pillow-relay.<konto>.workers.dev` (Domain auf genau diese Adresse beschränken)
   - `relay_token` = derselbe Wert wie `RELAY_TOKEN`
4. Fertig – Live-Server senden ab dem nächsten Start. (Lokale Studio-Tests haben keine Secrets → Relay bleibt dort aus.)

Secrets nie in Chat, Code oder Repo – nur in Cloudflare bzw. Roblox eintragen.

## Entwicklung
`npm test` (Node ≥ 20, keine Abhängigkeiten), `npm run build` erzeugt `dist/worker.js` (Einzeldatei fürs Dashboard). Beides läuft im CI; CI schlägt fehl, wenn `dist/` nicht zum Quellcode passt.
