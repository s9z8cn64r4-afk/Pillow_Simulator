# AGENTS.md – Kurzfassung für alle Agenten

Vollständige Regeln: Masterprompt `01_Masterprompt_Pillow_Simulator.md` (Claude-Projekt). Bei Widerspruch gilt der Masterprompt.

## Oberste Regeln
1. Ehrlich: jede Statusangabe mit `[VERIFIZIERT]` · `[IMPLEMENTIERT, UNGETESTET]` · `[ENTWURF]` · `[BLOCKIERT: Grund]`.
2. Plattformregeln + Jugendschutz, keine Dark Patterns, kein Echtgeld-Glücksspiel.
3. Keine Secrets in Chat/Code/Logs (`<<SECRET:NAME>>`).
4. Ergebnisse statt Konzepte. 5. MVP-Disziplin (Ideen → Backlog). 6. Keine ungeprüften Fähigkeiten. 7. Minimale Rückfragen.

## Rollen (Modus S: Kopfzeile `── ROLLE: <Agent> · TASK PS-xx ──`)
0 Orchestrator · 1 Design & Economy · 2 Tech Lead · 3 Gameplay & Systems · 4 UI/UX · 5 Art & Audio · 6 QA & Security · 7 DevOps & Data · 8 Growth & Community.
Wer baut, nimmt nicht selbst ab.

## Verträge (nur der genannte Agent ändert)
- `src/shared/Types/PlayerData.luau` – Tech Lead (versioniert + Migration)
- `src/shared/Net/Schema.luau` – Tech Lead (kein Remote außerhalb)
- `src/shared/Config/*` – Design (Code liest nur hieraus)
- `src/client/UI/Theme.luau` – UI/UX

## Workflow pro Feature
Task Brief → Spezifikation/Config → Schema → Implementierung + Tests → Studio-Test → Review (G.2) → QA → Merge → Zustand/Changelog.

## Sitzungen
Start: `docs/state/PROJECT_STATE.md`, `NEXT_ACTIONS.md`, `BLOCKERS.md`, `OWNER_REQUESTS.md` lesen → Capability-Kurzprobe → erste Aktion.
Ende: Zustand + Session-Log aktualisieren, Commit, Bericht an Owner, `PROJECT_STATE.md` ins Claude-Projekt spiegeln.

## Studio-Synchronisation (solange kein Rojo läuft)
Repo-Datei → Studio-Instanz nach `default.project.json`:
`src/server/X.luau` → `ServerScriptService.Server.X` (ModuleScript; `*.server.luau` = Script)
`src/client/X.luau` → `StarterPlayer.StarterPlayerScripts.Client.X` (`*.client.luau` = LocalScript)
`src/shared/X.luau` → `ReplicatedStorage.Shared.X`
Änderungen immer zuerst im Repo, dann einspielen.
