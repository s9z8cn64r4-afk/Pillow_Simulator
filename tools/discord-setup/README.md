# Discord-Setup (Community-Server A)

Legt Rollen, Kategorien, Kanäle (inkl. Foren), Begrüßungs-/Regel-/FAQ-/Tester-Texte und AutoMod-Regeln nach `server-a.json` an. Idempotent: mehrfach ausführbar, ergänzt nur Fehlendes. Moderationsregeln: `docs/community/moderation.md`.

## Einmalige Einrichtung (Owner, ~10 Min., nur Browser)
1. Discord: neuen Server anlegen („Pillow Legends“). *Servereinstellungen → Community aktivieren* (nötig für Ankündigungs- und Forum-Kanäle).
2. [Discord Developer Portal](https://discord.com/developers/applications) → **New Application** → **Bot** → **Reset Token** → Token kopieren (geheim!).
3. **OAuth2 → URL Generator**: Scope `bot`, Rechte *Manage Roles, Manage Channels, Manage Server, View Channels, Send Messages, Read Message History* → Link öffnen → Bot in deinen Server einladen.
4. GitHub: Repository → *Settings → Secrets and variables → Actions → New repository secret*: Name `DISCORD_BOT_TOKEN`, Wert = Token.
5. Discord: *Einstellungen → Erweitert → Entwicklermodus* an; Rechtsklick auf den Server → **Server-ID kopieren**.
6. GitHub: *Actions → Discord Setup → Run workflow*, Server-ID einfügen, zuerst mit **dry_run** ansehen, dann ohne dry_run starten.
7. Danach den Bot behalten (für spätere Ergänzungen) oder aus dem Server entfernen.

## Lokal (optional)
`DISCORD_BOT_TOKEN=… node setup.mjs --guild <Server-ID> [--dry-run]` · Tests: `node --test setup.test.mjs`
