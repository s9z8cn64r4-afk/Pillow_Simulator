# Postmortem BUG-001 – Legitime Spieler wurden als Spammer gekickt

- **Priorität:** P0 (Spieler verliert Session; hätte nach Release jeden aktiven Auto-Swing-Nutzer getroffen)
- **Entdeckt:** 2026-10-27, Dauertest (Soak) nach 5 Minuten Halten der Schlag-Taste mit aktivem Auto-Swing
- **Status:** behoben, Regressionstests grün (46/46)

## Ablauf
1. Spieler hält die Schlag-Taste, Auto-Swing ist an (Rank ≥ 2).
2. Der Server-Auto-Swing setzte den gemeinsamen Cooldown-Zeitstempel; aktive Anfragen kamen kurz danach an → als „zu schnell“ (< 50 % Cooldown) gewertet.
3. Zusätzlich bündelt das Netz gelegentlich zwei Pakete → ebenfalls „zu schnell“.
4. Nach 200 solchen Verstößen: Kick („Connection problem detected“) – wiederholt, weil der Kick bei jedem weiteren Verstoß erneut ausgelöst wurde.

## Ursache
Verstoßerkennung pro Einzelereignis statt für anhaltendes Verhalten; Auto-Swing und aktive Schläge konkurrierten um denselben Zeitstempel.

## Lösung
- Neues reines Modul `src/shared/Util/SwingGate.luau`:
  - Auto-Swing pausiert, solange der Spieler in den letzten 1,5 Cooldowns aktiv geschlagen hat.
  - Zu frühe Anfragen werden verworfen; ein Verstoß wird erst bei anhaltendem Spam gemeldet (Strike-Zähler mit Abbau 1/s, Grenze 6).
- `NetService`: Kick nur genau einmal beim Erreichen der Schwelle.
- 6 Regressionstests (`tests/unit/SwingGate.spec.luau`), u. a. 1.000 Schläge mit Jitter/Bündelung ohne Verstoß und Erkennung von 50 Anfragen/s.

## Lehre
- Anti-Cheat-Signale nie auf Einzelereignisse stützen, die im Normalbetrieb vorkommen.
- Dauertests (≥ 10 Min., realistische Eingaben) gehören vor jedes Gate – Unit-Tests allein hatten den Fehler nicht gefunden.
