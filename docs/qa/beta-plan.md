# Closed-Beta-Plan (PS-41)

## Ziel
Gate M3 (Masterprompt F.2) belegen: ≥ 20 Tester-Sitzungen ausgewertet · Tutorial-Abschluss ≥ 80 % · Fehlerrate unter Grenzwert · Economy mit realen Daten abgeglichen · Owner bestätigt MVP-Scope.

## Umgebung
- **Eigener Beta-Place** (Kopie des Dev-Place) mit Workspace-Attribut `Environment = "BETA"` → getrennte DataStores (`PlayerData_BETA`, `Sessions_BETA`, `Feedback_BETA`, `LB_*_BETA`). Dev-Testdaten mischen sich so nicht mit Tester-Daten.
- Zugang nur für eingeladene Tester (Weg legt der Owner fest, z. B. Gruppe mit Tester-Rolle). 10–30 Tester.
- Testläufe (`RunTestsOnStart`) im Beta-Place **aus**.

## Ablauf
1. Owner veröffentlicht Beta-Place + lädt Tester ein (Owner-Aktion), verteilt `docs/community/tester-guide.md`.
2. Laufzeit ca. 7–10 Tage (Daily-Kette und D1/D7-Rückkehr sichtbar).
3. Täglich: Bericht erzeugen (unten), Bugs als Trello-Karten (P0/P1 sofort), Feedback-Ideen ins Backlog (`idea`).
4. Nach 20+ ausgewerteten Sitzungen: Gate-M3-Protokoll in `docs/state/GATES.md`.

## Auswertung
- **Bericht:** Im Beta-Place (Edit) `ServerStorage`-Attribut `BetaReportEnv = "BETA"` setzen, dann
  `require(game.ServerStorage.DevTools.RunToolScript)(<SHA>, "tools/studio/beta_report.luau")`.
  Liefert: Sitzungen (≥ 60 s), eindeutige Tester (Pseudonym), Tutorial-Abschluss der Erstsitzungen, Sitzungen mit Serverfehlern, Median Sitzungslänge, Median Federn/Min., Rebirth-Sitzungen, Feedback-Liste.
- **Roblox-Analytics** (Creator Hub): Onboarding-Funnel (Tutorial-Schritte), Economy (Quellen/Senken), Progression (Zonen/Rebirth), Retention D1/D7, Fehlerberichte des Clients.
- **Economy-Abgleich:** Median Federn/Min. und Zeit bis Zone 2 / Rebirth 1 gegen `docs/design/economy.md` (Bot-Faktor ≈ 1,7 zur Simulation).

## Grenzwerte (Startwerte, nach Beta kalibrieren)
| Kennzahl | Grenze |
|---|---|
| Ausgewertete Sitzungen | ≥ 20 |
| Tutorial-Abschluss (Erstsitzungen) | ≥ 80 % (Masterprompt-KPI 85 %) |
| Sitzungen mit Serverfehlern | ≤ 1 % (KPI fehlerfreie Sessions ≥ 99 %) |
| Offene P0/P1-Bugs | 0 |
| Median Sitzungslänge | ≥ 12 Min. (Hypothese) |

## Testschwerpunkte
Tutorial-Verständnis · erste 10 Minuten · Preis-/Tempo-Gefühl (Zone 2, Rebirth) · Phone/Tablet-Bedienung · Mehrspieler (Freunde-Bonus, Ranganzeige, Effekte anderer) · Daily über mehrere Tage · Codes · Feedback-Knopf.

## Jugendschutz / Datenschutz
Keine Namen oder UserIds in Berichten (Pseudonym), Feedback nur gefiltert gespeichert, Tester-Anleitung bittet um keine persönlichen Daten, keine Robux-Käufe in der Beta, kein privater Kontakt zu Testern außerhalb vom Owner festgelegter Kanäle.
