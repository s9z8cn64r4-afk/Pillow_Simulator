# PROJECT_STATE – Pillow Simulator

> Einstiegspunkt für jede KI-Sitzung (Masterprompt K.3/K.4). Wird am Ende jeder Sitzung aktualisiert – nicht duplizieren.
> Spiegel: gleiche Datei im Claude-Projekt (`claude/PROJECT_STATE.md`).

| Feld | Wert |
|---|---|
| Aktuelle Phase | **Phase 2 – Vertical Slice (M2)**, Gate M0 + **Gate M1 bestanden** (2026-10-27) |
| Version | 0.2.0-dev |
| Sprint-Ziel | M2: alle 14 Kissen als Modelle, Map final-nah, Tutorial, Rank-Up-Feedback, Bot-Durchlauf, Gate M2 |
| Letzte Sitzung | 2026-10-27 (Sitzung 3): CI repariert, Gate M1, 14 Kissenmodelle + Effekte, Rank-Up-Feier, Tutorial, Map-Dekor aller Zonen |
| Repository | github.com/s9z8cn64r4-afk/Pillow_Simulator (`main`, **öffentlich**) – Push funktioniert, CI grün |
| Task-Tracker | Trello „Pillow Simulator \| Studio“ – https://trello.com/b/fAGsLKn7/pillow-simulator-studio |
| Dev-Place | „dev place“, PlaceId 123160785919248, DataStore `PlayerData_DEV` |
| MVP-Scope | `docs/MVP_SCOPE.md` – vorläufig freigegeben (Orchestrator), Owner-Freigabe bis M3 |

## Stand
| Bereich | Status |
|---|---|
| M1 (PS-01–10) | **Done** – Gate M1 `[VERIFIZIERT]`, Protokoll `GATES.md` |
| Tests | 60/60 grün in Studio `[VERIFIZIERT]`; CI (StyLua/Selene/Economy-Sim) grün `[VERIFIZIERT]` |
| Repo ↔ Studio | per GitHub-Sync aktuell (Drift-Check zuletzt 0 bei 0aff1bf) |
| PS-12 Zonen 2–4 | Logik + Graybox `[VERIFIZIERT]` (Tests); Map-Ausbau → PS-16 |
| PS-14 Rebirth | `[VERIFIZIERT]` (Test + Menü) |
| PS-15 Ranks | Titel, Banner + Konfetti, Trail ab Rank 5 `[VERIFIZIERT]` (Tests + Screenshot); Mehrspieler-Sichtbarkeit `[IMPLEMENTIERT, UNGETESTET]` |
| PS-19/20 Settings + Index | `[VERIFIZIERT]` per Klick + Server-Roundtrip |
| PS-11 Kissenmodelle | 14/14 Modelle + Aura/Trail `[VERIFIZIERT]` (Lineup + gehalten); Griff-Feinjustierung P3 |
| PS-18 Tutorial | 6 Schritte + Skip + Boost `[VERIFIZIERT]` (8 Integrationstests, Desktop/Phone-Screenshots); echter Erstspieler-Durchlauf steht aus |
| PS-16 Map | alle 4 Zonen dekoriert (`tools/studio/build_zone_decor.luau`, 362 Dekor-Teile), Vorhang-Durchgänge mit lesbarem Preisschild (BUG-003 behoben), Licht-Profile je Zone (`LightingController`) `[VERIFIZIERT]` (Freischalten + Zonenwechsel im Play-Test) |
| PS-21–23 | offen |

## Nächste konkrete Aktion
Siehe `NEXT_ACTIONS.md`.

## Wichtige Hinweise für die nächste Sitzung
- **Code nach Studio:** nach Push `python3 tools/scripts/studio_sync.py OUT drift.txt --github <SHA>` → `OUT/sync_helper.luau` per `execute_luau` (Edit) ausführen (nutzt `ServerStorage.DevTools.SyncFromGitHub`; fehlt der Helfer, `sync_github.luau` nehmen); Studio lädt per HttpService von raw.githubusercontent.com (geht nur, solange das Repo öffentlich ist). Danach Drift-Check (`studio_hash.luau` + `source_hash.py`).
- **Studio-DevTools** (`ServerStorage.DevTools`, nicht im Repo-Mapping, nur im Place): `SyncFromGitHub(sha, list)`, `RunToolScript(sha, "tools/…")` (führt Builder vom Commit aus), `ImportPillows`.
- **CI formatiert selbst:** Push auf `main` → StyLua-Auto-Fix-Commit möglich → vor dem nächsten Push `git pull --rebase`, vor dem Studio-Sync den neuesten SHA nehmen. Generierte Config ist per `.styluaignore` ausgenommen.
- Actions-Logs nicht abrufbar → Fehler über Check-Run-Annotations (`gh api repos/.../check-runs/<id>/annotations`).
- Studio-Änderungen (Map, Modelle, Vendor) existieren nur im Place → Owner muss speichern (Owner-Anfrage #2).
- Skripte mit Punkt im Namen nicht über `multi_edit` ansprechen; `require` aus `execute_luau` = eigene Modulinstanz; Studio-Aufrufe nie > 50 s blockieren.
- GUI-Klicks: `user_mouse_input` mit Mittelpunkt aus `AbsolutePosition + AbsoluteSize/2`.

## Offene Owner-Entscheidungen / -Aktionen
Studio speichern (#2) · Hörprobe Sounds · Spielname (Vorschläge: Pillow Smash Simulator, Feather Frenzy, Pillow Legends) · MVP-Freigabe · Robux-Preise · Werbebudget (Standard 0 €) · Repo öffentlich lassen? (Hinweis: ursprünglich „privat“ angefragt; enthält keine Geheimnisse)

## Aktive Blocker
Keine.
