# SESSION_LOG (neueste oben)

## Sitzung 2 – 2026-10-27
**Ziele:** M1 abschließen (Auto-Swing, UI-Kauf, Phone-Layout, Sound, Gate), M2 beginnen.
**Erledigt:**
- Auto-Swing-Integrationstest; UI-Kauf per echtem Klick (Kissen + Upgrade) `[VERIFIZIERT]`; Phone-Layout 844×390 per Debug-Viewport `[VERIFIZIERT]`; Touch-Mindestskalierung.
- Sounds (5, Ladeprüfung OK), 3D-Federburst aus generiertem Federmodell, generiertes Modell „Worn-Out Pillow“.
- **BUG-001 (P0) gefunden durch Dauertest und behoben**: Fehl-Kick legitimer Spieler bei Halten + Auto-Swing → `SwingGate` + 6 Regressionstests, Postmortem.
- M2 begonnen: ZoneService (Erkennung, ProximityPrompt-Kauf, Teleport), RebirthService (+ Menü mit Doppel-Bestätigung), RankService (Titel über Kopf), Graybox-Zonen 2–4, Settings (validiert) + Pillow Index.
- Trello: M2 in Einzelkarten zerlegt.
**Probleme:** Fremde Creator-Store-Bilder laden nicht im Spiel → eigene 3D-Federn; Studio-Werkzeugaufrufe dürfen nicht > 60 s blockieren.

## Sitzung 1 – 2026-10-26/27
**Ziele:** Capability Probe, Projektgerüst, Phase 0, Beginn Phase 1.
**Erledigt:**
- Capability Probe → `CAPABILITIES.md`; Freigabe-Anfrage #1 – vom Owner erledigt (Place veröffentlicht + API-Zugriff, GitHub-Repo + App, Trello-Platz).
- Phase 0 komplett, Gate M0 bestanden: Konkurrenzanalyse (Namenskonflikt „Pillow Fighting Simulator“, Algorithmus 2026), GDD v1, Economy-Simulation (alle Zielkurven OK), Config-Generator, TDD, ADR-0001–0005, CR-001 (Puppen + Freunde-Bonus), MVP-Scope, Roadmap, Risiken, Testplan, UI-System, Art Bible.
- Trello-Board mit M1-Karten, M2/M3-Paketen, Owner-Aktionen.
- M1-Code (37 Skripte) in Repo und Studio, 0 Abweichungen; Graybox Bedroom; 30/30 Tests; Exploit-Basistest; Persistenz-Rejoin `[VERIFIZIERT]`.
**Offen:** Auto-Swing-Test, UI-Klick-Kauf, Phone-Layout, Sound, Gate M1.
**Probleme:** Emoji 🪶 und ✕ werden in Roblox-Schrift nicht dargestellt (ersetzt durch 🕊️ / X); Dotted-Namen bei `multi_edit`; Trello-Listen-API akzeptiert keine numerische Position.
