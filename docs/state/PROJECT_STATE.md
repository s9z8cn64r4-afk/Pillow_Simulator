# PROJECT_STATE – Pillow Simulator

> Einstiegspunkt für jede KI-Sitzung (Masterprompt K.3/K.4). Wird am Ende jeder Sitzung aktualisiert – nicht duplizieren.
> Spiegel: gleiche Datei im Claude-Projekt (`claude/PROJECT_STATE.md`).

| Feld | Wert |
|---|---|
| Aktuelle Phase | **Phase 2 – Vertical Slice (M2)**, Gate M0 + **Gate M1 bestanden** (2026-10-27) |
| Version | 0.2.0-dev |
| Sprint-Ziel | M2: alle 14 Kissen als Modelle, Map final-nah, Tutorial, Rank-Up-Feedback, Bot-Durchlauf, Gate M2 |
| Letzte Sitzung | 2026-10-27 (Sitzung 3): CI repariert (seit Phase 0 rot), Settings/Index in Studio verifiziert, Gate M1, PS-11 begonnen |
| Repository | github.com/s9z8cn64r4-afk/Pillow_Simulator (`main`, **öffentlich**) – Push funktioniert, CI grün |
| Task-Tracker | Trello „Pillow Simulator \| Studio“ – https://trello.com/b/fAGsLKn7/pillow-simulator-studio |
| Dev-Place | „dev place“, PlaceId 123160785919248, DataStore `PlayerData_DEV` |
| MVP-Scope | `docs/MVP_SCOPE.md` – vorläufig freigegeben (Orchestrator), Owner-Freigabe bis M3 |

## Stand
| Bereich | Status |
|---|---|
| M1 (PS-01–10) | **Done** – Gate M1 `[VERIFIZIERT]`, Protokoll `GATES.md` |
| Tests | 49/49 grün in Studio `[VERIFIZIERT]`; CI (StyLua/Selene/Economy-Sim) grün `[VERIFIZIERT]` |
| Repo ↔ Studio | 0 Abweichungen (53 Skripte) `[VERIFIZIERT]` |
| PS-12 Zonen 2–4 | Logik + Graybox `[VERIFIZIERT]` (Tests); Map-Ausbau → PS-16 |
| PS-14 Rebirth | `[VERIFIZIERT]` (Test + Menü) |
| PS-15 Ranks | Titel über Kopf `[IMPLEMENTIERT, UNGETESTET]` (Mehrspieler); Banner/Trail offen |
| PS-19/20 Settings + Index | `[VERIFIZIERT]` per Klick + Server-Roundtrip |
| PS-11 Kissenmodelle | in Arbeit: 13 Generierungen gestartet |
| PS-16 Map, PS-18 Tutorial, PS-21–23 | offen |

## Nächste konkrete Aktion
Siehe `NEXT_ACTIONS.md`.

## Wichtige Hinweise für die nächste Sitzung
- **Code nach Studio:** nach Push `python3 tools/scripts/studio_sync.py OUT drift.txt --github <SHA>` → kleinen Chunk per `execute_luau` (Edit) ausführen; Studio lädt per HttpService von raw.githubusercontent.com (geht nur, solange das Repo öffentlich ist). Danach Drift-Check (`studio_hash.luau` + `source_hash.py`).
- **CI formatiert selbst:** Push auf `main` → StyLua-Auto-Fix-Commit möglich → vor dem nächsten Push `git pull --rebase`, vor dem Studio-Sync den neuesten SHA nehmen. Generierte Config ist per `.styluaignore` ausgenommen.
- Actions-Logs nicht abrufbar → Fehler über Check-Run-Annotations (`gh api repos/.../check-runs/<id>/annotations`).
- Studio-Änderungen (Map, Modelle, Vendor) existieren nur im Place → Owner muss speichern (Owner-Anfrage #2).
- Skripte mit Punkt im Namen nicht über `multi_edit` ansprechen; `require` aus `execute_luau` = eigene Modulinstanz; Studio-Aufrufe nie > 50 s blockieren.
- GUI-Klicks: `user_mouse_input` mit Mittelpunkt aus `AbsolutePosition + AbsoluteSize/2`.

## Offene Owner-Entscheidungen / -Aktionen
Studio speichern (#2) · Hörprobe Sounds · Spielname (Vorschläge: Pillow Smash Simulator, Feather Frenzy, Pillow Legends) · MVP-Freigabe · Robux-Preise · Werbebudget (Standard 0 €) · Repo öffentlich lassen? (Hinweis: ursprünglich „privat“ angefragt; enthält keine Geheimnisse)

## Aktive Blocker
Keine.
