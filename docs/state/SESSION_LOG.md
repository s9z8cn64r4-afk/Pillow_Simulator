# SESSION_LOG (neueste oben)

## Sitzung 3 – 2026-10-27
**Ziele:** CI-Fehler (rote Commits) beheben, M2-Stand in Studio verifizieren, Gate M1, PS-11.
**Erledigt:**
- CI seit Phase 0 rot (StyLua-Format, Selene `if_same_then_else`) → StyLua-Auto-Fix auf `main`, Selene als Annotations, Lint behoben → **CI grün** `[VERIFIZIERT]`.
- Settings/Index/UIController + Settings.spec in Studio; 49/49 Tests; Settings + Index per echtem Klick inkl. Server-Roundtrip `[VERIFIZIERT]`; Rejoin `[VERIFIZIERT]`.
- `studio_sync.py --github`: Studio lädt gepinnten Commit (22 Dateien in einem Aufruf); Drift 0.
- Restore-Wächter im Testrunner (BUG-002, einmaliger Federsprung in DEV, nicht reproduzierbar).
- **Gate M1 bestanden**; Trello: PS-04/05/07/08/10, PS-19/20 → Done, PS-11 → In Progress, Owner-Karte Hörprobe.
- PS-11: 13 Kissenmodelle generiert (sequenziell; parallel scheitert), 2 nach Sichtprüfung neu; Import-/Lineup-Skripte; Aura ab Epic, Trail bei Legendary.
- PS-15: Feier-Banner + Konfetti (Rank-Up, Rebirth, Epic/Legendary), Trail ab Rank 5, Rank.spec → 52/52.
- PS-16: Dekor-Builder für alle 4 Zonen (Art-Bible-Paletten, prozedurale Möbel, generierte Kissen als Requisiten, Lichterketten/Kronleuchter/Mond), 329 Teile, Tests weiter grün.
- PS-16 Rest: Vorhang-Durchgänge, Licht-Profile je Zone (LightingController), BUG-003 (Preisschild falsche Seite) gefunden und behoben.
- PS-22/23: Bot-Durchlauf (BotRun.spec) bis Rebirth 3 ohne Sackgasse, Performance gemessen; Musik (Playlist), Ladebildschirm, Tooltips, Gamepad (R2/Y/X/B); Test-Isolation Gameplay.spec; ProfileStore-Lizenz (Apache-2.0) geklärt.
- **Gate M2 vorläufig bestanden** (Restpunkte: Mehrspielertest, manueller Volldurchlauf).
- PS-18: Tutorial (TutorialService, Hinweis-UI mit Markierung, Skip, 2×-Boost, Funnel-Events), Tutorial.spec → 60/60; Sync-Helfer `DevTools.SyncFromGitHub` in Studio.
**Probleme:** StyLua-Binary-Download in der Cloud-Umgebung nicht erlaubt (→ CI formatiert); Actions-Logs nicht abrufbar (→ Annotations).

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
