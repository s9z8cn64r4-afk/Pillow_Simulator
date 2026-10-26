# ADR-0004 – Logging über Relay statt Direktanbindung an Discord

- **Status:** angenommen (2026-10-27), Umsetzung Phase 3
- **Entscheidung:** Roblox-Server → (HMAC-signiert, gebündelt) → Relay (Cloudflare Worker, kostenloses Kontingent) → Discord-Webhooks im privaten Log-Server. Spieler nur als `HMAC(UserId, Salt)`. Spiel funktioniert unabhängig vom Relay (Puffer mit Obergrenze, Verwerfen nach N Versuchen).
- **Begründung:** Webhook-URLs bleiben geheim und rotierbar, Rate-Limits und Deduplizierung an einer Stelle, Datenschutzfilter zentral (Masterprompt I.4).
- **Bis Phase 3:** `LogService` schreibt in die Konsole; `warn+` werden gezählt und im Session-Bericht ausgewertet.
