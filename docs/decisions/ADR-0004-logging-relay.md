# ADR-0004 – Logging über Relay statt Direktanbindung an Discord

- **Status:** angenommen (2026-10-27), **umgesetzt 2026-10-27** (PS-36) – Deployment wartet auf Owner
- **Entscheidung:** Roblox-Server → (gebündelt, HTTPS, Bearer-Token) → Relay (Cloudflare Worker, kostenloses Kontingent, `relay/`) → Discord-Webhooks im privaten Log-Server. Spieler nur als Pseudonym (`Server/Pseudonym`). Spiel funktioniert unabhängig vom Relay (Puffer mit Obergrenze 100, Verwerfen nach 3 Fehlversuchen, alles in `pcall`).
- **Begründung:** Webhook-URLs bleiben geheim und rotierbar, Rate-Limits und Deduplizierung an einer Stelle, Datenschutzfilter zentral (Masterprompt I.4).

## Abweichung vom Masterprompt: Bearer-Token statt HMAC-Signatur
Der Masterprompt sieht eine HMAC-Signatur mit einem Secret aus dem Roblox Secrets Store vor. Roblox gibt Secrets in Luau **nicht im Klartext** heraus; sie lassen sich nur in URL oder Header von `HttpService:RequestAsync` einsetzen (`Secret:AddPrefix/AddSuffix`, nicht im Body) – eine HMAC-Berechnung im Spiel ist damit nicht möglich ([Roblox-Doku „Secrets stores“](https://create.roblox.com/docs/cloud-services/secrets)).
Umsetzung stattdessen: Token als `Authorization: Bearer …` (Secret `relay_token`), Relay-URL ebenfalls als Secret (`relay_url`, Domain-beschränkt), Transport nur HTTPS, Token-Vergleich zeitkonstant im Worker, Größen-/Schema-Prüfung, keine Speicherung im Relay. Schutzwirkung für unseren Zweck gleichwertig (Token nie im Code/Repo, rotierbar); Replay-Schutz entfällt, ist bei reinen Benachrichtigungen unkritisch.

## Umfang M3
Kategorien: `critical`, `error` (inkl. unbehandelter Skriptfehler), `warn`, `exploit`, `feedback`, `session` (Summen). Weitere Kanäle aus I.4 (`#economy`, `#performance`, `#deployments`, `#qa-results`, `#daily-summary`) folgen bei Bedarf über dieselbe Schnittstelle.
