# BACKLOG (Task-Tracker, ADR-0005)

Format je Task: Task Brief (Masterprompt C.11). Status-Spalten: Backlog · Ready · In Progress · Review · QA · Done · Ideas.

## In Progress
_(leer)_

## Ready – M1 Prototype

### PS-01 Datenschema + PlayerDataService
Agent: Gameplay & Systems · Prüfer: Tech Lead + QA · P0 · S/M
Ziel: Spielerdaten sicher laden/speichern mit Session-Locking.
Dateien: `src/shared/Types/PlayerData.luau`, `src/server/Services/PlayerDataService.luau`, `src/server/Migrations.luau`
Akzeptanz: (1) Profil wird bei Join geladen, bei Leave freigegeben. (2) Template-Felder via Reconcile ergänzt. (3) Migration v0→v1 getestet. (4) Rejoin zeigt identischen Stand. (5) DataStore-Name enthält Umgebung.
Test: Integrationstest Join→Änderung→EndSession→Neuladen; Unit-Test Migration.
Nicht-Ziele: Kaufbelege (PS-M3).

### PS-02 Netzwerkschicht (Schema, Validierung, Rate-Limit)
Agent: Tech Lead · Prüfer: QA & Security · P0 · M
Akzeptanz: (1) Remotes nur aus Schema. (2) Falsche Typen/NaN/zu lange Strings werden verworfen. (3) Token-Bucket je Spieler+Remote. (4) Verstöße gezählt.
Test: Unit-Tests Validatoren/RateLimiter; Exploit-Test im Play-Modus.

### PS-03 Formeln + Zahlformat
Agent: Gameplay & Systems · Prüfer: Design + QA · P0 · S
Akzeptanz: (1) Formeln identisch zu sim.py (Paritätsvektoren). (2) Suffix-Format 1.2K/3.45M/… korrekt bis 1e15.
Test: `Formulas.spec`, `NumberFormat.spec`.

### PS-04 Schlagen + Auto-Swing (serverseitig)
Agent: Gameplay & Systems · Prüfer: Tech Lead + QA · P0 · M
Akzeptanz: (1) Server prüft Cooldown mit Toleranz. (2) Ertrag nur serverseitig. (3) Auto-Swing ab Rank 2, 80 %. (4) Zu schnelle Anfragen werden verworfen und gezählt.
Test: Integrationstest Federn nach N Schlägen; Spam-Test.

### PS-05 Shop: 3 Kissen + 2 Upgrades + Ausrüsten
Agent: Gameplay & Systems · Prüfer: QA · P1 · M
Akzeptanz: (1) Kauf nur mit genug Federn und erfüllten Voraussetzungen. (2) Unbekannte IDs verworfen. (3) Ausrüsten nur besessener Kissen. (4) Kostenkurven aus Config.

### PS-06 Graybox-Zone „Cozy Bedroom“ + Kissenpuppen-Platzhalter
Agent: Art & Audio · Prüfer: Design · P1 · S
Akzeptanz: Spawn, Bodenfläche, 4 Puppen-Platzhalter, Barriere zu Zone 2 (gesperrt), Beleuchtung; Screenshot.

### PS-07 HUD v0 (Federzähler, Schlag-Taste, Shop-Panel, Auto-Swing-Schalter)
Agent: UI/UX · Prüfer: Design + QA · P1 · M
Akzeptanz: (1) Zähler rollt bei Änderungen. (2) Shop listet Kissen/Upgrades mit Preis und Kaufbarkeit. (3) Funktioniert auf Phone-Landscape und Desktop (Screenshots).

### PS-08 Kissen-Werkzeug + Schlag-Feedback v0
Agent: Art & Audio + UI/UX · Prüfer: Design · P1 · M
Akzeptanz: Kissen in der Hand, Schwung-Animation (prozedural), Federburst, „+X“-Zahl, Sound.

### PS-09 Studio-Testrunner + Exploit-Basistests
Agent: QA & Security · Prüfer: Tech Lead · P0 · S
Akzeptanz: `RunTests` gibt `[TEST] SUMMARY x/y` aus; Exploit-Basisfälle aus Testplan.

### PS-10 Gate M1
Agent: Orchestrator · P0 · S – 10-Minuten-Spieltest mit Rejoin, Belege, GATES.md.

## Backlog – M2 Alpha
PS-11 Alle 14 Kissen + Seltenheits-Visuals · PS-12 Zonen 2–4, Barrieren, Teleport-Pads, Zonen-Erkennung · PS-13 Kissenpuppen mit Bonus (CR-001) · PS-14 Rebirth + Menü · PS-15 Ranks + Overhead-Titel + Feier · PS-16 Map final-nah (4 Zonen) · PS-17 UI-Design-System-Komponenten · PS-18 Tutorial + Nächstes-Ziel · PS-19 Settings + Accessibility · PS-20 Pillow Index · PS-21 Bot-Durchlauf bis Rebirth 3 · PS-22 Performance-Messung · PS-23 Gate M2

## Backlog – M3 Closed Beta
PS-30 Daily Reward + Willkommen-zurück · PS-31 Codes · PS-32 Leaderboards · PS-33 Gruppen-/Freunde-Bonus · PS-34 Monetarisierung (Test) · PS-35 AnalyticsService-Events · PS-36 Relay + privater Discord · PS-37 Feedback/Bug-Report · PS-38 Community-Discord · PS-39 Persistenz-Stresstest · PS-40 Mobile-Feinschliff · PS-41 Tester-Programm · PS-42 Gate M3

## Ideas (P3, nach Release prüfen)
Pets & Eggs (gegen Federn) · tägliche Quests · Welt 2 · Events · Achievements · Kissen-Skins · Portrait-Modus

## Done
- PS-00 Phase 0: Recherche, GDD, Economy-Sim, TDD, ADRs, MVP-Scope (2026-10-27)
