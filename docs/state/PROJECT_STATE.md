# PROJECT_STATE – Pillow Simulator

> Einstiegspunkt für jede KI-Sitzung (Masterprompt K.3/K.4). Wird am Ende jeder Sitzung aktualisiert – nicht duplizieren.
> Spiegel: gleiche Datei im Claude-Projekt (`claude/PROJECT_STATE.md`).

| Feld | Wert |
|---|---|
| Aktuelle Phase | **Phase 1 – Pre-Alpha / Prototyp (M1)**, Gate M0 bestanden (Scope vorläufig freigegeben) |
| Version | 0.1.0-dev |
| Sprint-Ziel | M1 abschließen: spielbare Scheibe Schlagen → Federn → Kaufen → Speichern |
| Letzte Sitzung | 2026-10-27 (Sitzung 1): Capability Probe, Phase 0 komplett, M1-Kern gebaut und getestet |
| Repository | github.com/s9z8cn64r4-afk/Pillow_Simulator (`main`) – Push funktioniert |
| Task-Tracker | Trello „Pillow Simulator \| Studio“ – https://trello.com/b/fAGsLKn7/pillow-simulator-studio |
| Dev-Place | „Pillow Simulator [DEV]“, PlaceId 123160785919248, DataStore `PlayerData_DEV` |
| MVP-Scope | `docs/MVP_SCOPE.md` – vorläufig freigegeben (Orchestrator), Owner-Freigabe bis M3 |

## Stand M1
| Task | Status |
|---|---|
| PS-01 Datenschema + PlayerDataService | `[VERIFIZIERT]` Rejoin behält 72 Federn; ProfileStore-Roundtrip-Test |
| PS-02 Netzwerkschicht | `[VERIFIZIERT]` Unit-Tests + Exploit-Basistest |
| PS-03 Formeln + Zahlformat | `[VERIFIZIERT]` Paritätstest mit sim.py |
| PS-04 Schlagen + Auto-Swing | aktiv `[VERIFIZIERT]`; Auto-Swing `[IMPLEMENTIERT, UNGETESTET]` |
| PS-05 Shop | Server `[VERIFIZIERT]`; Kauf per UI-Klick `[IMPLEMENTIERT, UNGETESTET]` |
| PS-06 Graybox Bedroom | `[VERIFIZIERT]` Screenshot; Builder-Skript `tools/studio/build_graybox_bedroom.luau` |
| PS-07 HUD v0 | Desktop `[VERIFIZIERT]`; Phone-Layout `[IMPLEMENTIERT, UNGETESTET]` |
| PS-08 Schlag-Feedback | Animation/Burst `[IMPLEMENTIERT, teilw. geprüft]`; Sound fehlt |
| PS-09 Testrunner | `[VERIFIZIERT]` 30/30 |
| PS-10 Gate M1 | offen |

## Nächste konkrete Aktion
Siehe `NEXT_ACTIONS.md` – zuerst: Auto-Swing-Test (Spieler auf Rank 2 setzen, AUTO aktivieren, Federanstieg ohne Eingabe messen).

## Wichtige Hinweise für die nächste Sitzung
- Studio-Änderungen müssen vom Owner gespeichert werden (Datei → Auf Roblox speichern), sonst gehen Map/Skripte im Place verloren. Code liegt zusätzlich im Repo, Map als Builder-Skript.
- Skripte mit Punkt im Namen (`*.spec`) über `multi_edit` NICHT direkt ansprechen (Punkt = Pfadtrenner) → per `execute_luau` und `Source` bearbeiten.
- Modul-`require` aus `execute_luau` liefert eine eigene Instanz (nicht die des laufenden Spiels) → Laufzeitzustand über Konsole/leaderstats/Attribute prüfen.
- GUI-Klicks per Automatisierung lösen `Activated` nicht aus → UI-Kaufpfad manuell oder per Testhook prüfen.

## Offene Owner-Entscheidungen
Spielname (Vorschläge: Pillow Smash Simulator, Feather Frenzy, Pillow Legends) · MVP-Freigabe · Robux-Preise · Werbebudget (Standard 0 €)

## Aktive Blocker
Keine.
