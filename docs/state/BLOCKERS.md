# BLOCKERS

| ID | Blockade | Seit | Ersatzweg | Benötigte Owner-Aktion |
|---|---|---|---|---|
| B-1 | DataStore-Tests in Studio unmöglich (Place unveröffentlicht, kein API-Zugriff) | 2026-10-27 | Speicher-Mock in Studio; Persistenz `[IMPLEMENTIERT, UNGETESTET]` | Freigabe #1.1: Dev-Place privat veröffentlichen + API-Zugriff aktivieren |
| B-2 | Kein GitHub-Repo (Push/CI/Backup) | 2026-10-27 | Lokales Git im Cloud-Arbeitsbereich + Kopie der Kernstände im Claude-Projekt | Freigabe #1.2: privates Repo `pillow-simulator` anlegen |
| B-3 | Keine Luau-Toolchain (Rojo serve/Lune/Selene/StyLua) in der Cloud | 2026-10-27 | Tests in Studio per eigenem Runner; Format/Lint in GitHub-CI, sobald Repo existiert | keine (optional: `rojo serve` auf dem PC) |
