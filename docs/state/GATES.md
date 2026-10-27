# GATES – Gate-Protokolle

Format: Kriterium · Status · Beleg · Ausnahme

## Gate M0 – Phase 0 Research & Planning (2026-10-27)
| Kriterium | Status | Beleg | Ausnahme |
|---|---|---|---|
| Konkurrenzanalyse mit Quellen | erfüllt | `docs/research/competitor-analysis.md` | Blade Simulator ohne belastbare Zahlen (Backlog) |
| GDD v1 | erfüllt | `docs/design/GDD.md` | – |
| Economy-Modell + Simulation erfüllt Zielkurven | erfüllt `[VERIFIZIERT]` | `python3 tools/economy-sim/sim.py --check` → exit 0 | – |
| Config v1 generiert | erfüllt | `src/shared/Config/*.luau` | – |
| TDD, Architektur, ADR-0001–0005 | erfüllt | `docs/tech/`, `docs/decisions/` | ADR-0003 weicht vom Masterprompt ab (begründet) |
| MVP_SCOPE, ROADMAP, RISKS | erfüllt | `docs/` | – |
| Backlog mit Task Briefs | erfüllt | `docs/state/BACKLOG.md` | Trello am Board-Limit → Markdown-Fallback |
| Testplan, UI-Design-System, Art Bible | erfüllt | `docs/qa/`, `docs/design/`, `docs/art/` | – |
| Capability-Matrix | erfüllt | `docs/state/CAPABILITIES.md` | – |
| MVP-Scope freigegeben | **vorläufig (Orchestrator)** | MVP_SCOPE.md | Owner-Freigabe spätestens vor Closed Beta |

**Ergebnis:** Gate M0 bestanden (vorläufige Scope-Freigabe). Phase 1 beginnt.

## Gate M1 – Prototype (2026-10-27)
| Kriterium | Status | Beleg | Ausnahme |
|---|---|---|---|
| 10 Min. spielen inkl. Käufe | erfüllt `[VERIFIZIERT]` | Dauertest 2: ~10 Min. Halten + Auto-Swing, 0 Verstöße/Kicks/Fehler, 59,9 FPS; UI-Käufe per echtem Klick | – |
| Rejoin behält Stand | erfüllt `[VERIFIZIERT]` | `Profil geladen` nach Play-Neustart: 72 → 72; 26,5 K → 27.141; 4,82 M → 4.858.081 (Auto-Swing läuft bis zum Stopp weiter) | – |
| Automatisierte Tests grün | erfüllt `[VERIFIZIERT]` | Studio-Runner `SUMMARY 49/49` (Unit + Integration mit echtem Spieler, ProfileStore-Roundtrip, Restore-Wächter) | – |
| Exploit-Basistests | erfüllt `[VERIFIZIERT]` | NaN/Strings/Tabellen/Spam: keine Gutschrift, Verstöße gezählt, kein Absturz; BUG-001 (Fehl-Kick) behoben + 6 Regressionstests | – |
| Unit-Abdeckung Formeln/Validierung ≥ 80 % | erfüllt (Schätzung) | jede öffentliche Funktion von Formulas/NumberFormat/Validate/RateLimiter/SwingGate hat Tests | nicht werkzeuggemessen (kein Coverage-Tool in Studio) |
| CI grün | erfüllt `[VERIFIZIERT]` | GitHub Actions: StyLua (Auto-Fix auf main), Selene 0 Fehler, Economy-Sim | – |
| Repo ↔ Studio ohne Drift | erfüllt `[VERIFIZIERT]` | `source_hash.py` → „OK – keine Abweichung“ (53 Skripte) | Place muss vom Owner gespeichert werden (Owner-Anfrage #2) |
| Phone-Layout | erfüllt `[VERIFIZIERT]` | Debug-Viewport 844×390 + Touch-Mindestskalierung 0,8 | echtes Gerät steht aus (Closed Beta) |

**Ergebnis:** Gate M1 bestanden. Phase 2 (M2 Vertical Slice) läuft.

## Gate M2 – Alpha / Vertical Slice (2026-10-27) – **vorläufig bestanden**
| Kriterium | Status | Beleg | Ausnahme |
|---|---|---|---|
| Alle Kissen/Zonen, Puppen, Rebirth, Ranks | erfüllt `[VERIFIZIERT]` | 14 Modelle, 4 Zonen, Integrationstests Progression/Rank/BotRun | – |
| Map final-nah, Animationen/VFX | erfüllt `[VERIFIZIERT]` | Dekor aller Zonen, Vorhänge, Licht-Profile, Federburst, Aura/Trail, Feier-Banner (Screenshots) | Arm-Animation teils vom Standard-Animator überdeckt (P3) |
| UI-Design-System, Tutorial, Settings, Musik, Ladebildschirm, Tooltips | erfüllt `[VERIFIZIERT]` | Klick-/Hover-Tests, Screenshots Desktop + Phone 844×390, Musik spielt | – |
| Gamepad-Grundbedienung | erfüllt `[VERIFIZIERT]` | R2 = Schlag (5 Schläge/2 s), Y = Shop, B = Schließen, X = Auto (simulierte Eingaben) | echtes Gamepad nicht getestet |
| Pfad Start → Rebirth 3 per Bot | erfüllt `[VERIFIZIERT]` | BotRun.spec (echte Services): keine Sackgasse, Rebirth 3 nach 214 Sim-Min. | – |
| Pfad Start → Rebirth 3 manuell | **offen** | Zone 2 manuell freigeschaltet (Play-Test) | voller manueller Durchlauf (≈ 2–3 h) → Closed Beta |
| Keine offenen P0/P1 | erfüllt | KNOWN_BUGS: BUG-001/003 behoben, nur P2/P3 offen | – |
| Performance-Budgets (G.6) | erfüllt (1 Spieler) `[VERIFIZIERT]` | 59,9 FPS, Heartbeat 59,9, 9/60 Partikel, 0,08 KB/s, StreamingEnabled | Server-Skriptzeit + Gerätespeicher nicht automatisiert messbar; Last mit 12 Spielern → M3 |
| Tests/CI/Drift | erfüllt `[VERIFIZIERT]` | Studio-Runner grün, CI grün, Drift 0 (60 Skripte) | – |
| Mehrspieler-Sichtbarkeit (Titel, Effekte anderer) | **offen** | – | Owner-Test mit 2 Clients (Owner-Aktion, ~5 Min.) |

**Ergebnis:** Gate M2 vorläufig bestanden – zwei Restpunkte (manueller Volldurchlauf, Mehrspielertest) werden in M3 / Closed Beta nachgeholt. Phase 3 (M3 Beta: Retention, Monetarisierung, Analytics/Relay) kann beginnen; Owner-Freigabe des MVP-Scopes wird vor Closed Beta benötigt.

## Gate M3 – Closed Beta (Vorbereitung, Stand 2026-10-27) – **noch nicht bewertbar**
Ergebnisse (Masterprompt F.2, Phase 3):
| Ergebnis | Status | Beleg |
|---|---|---|
| Daily, Codes, Leaderboards | `[VERIFIZIERT]` | Daily/Codes/Leaderboard-Specs, Klick-Tests; Codes-Liste `[ENTWURF]` bis Owner-Freigabe |
| Group Reward / Freunde-Bonus | Freunde `[VERIFIZIERT]` (Logik, HUD); Gruppe `[BLOCKIERT]` | Social.spec; Gruppen-ID fehlt (Owner) |
| Monetarisierung im Testmodus | `[VERIFIZIERT]` (Testgerüst) | Monetization.spec; echte IDs/Preise → Owner #4 |
| Analytics live | `[IMPLEMENTIERT]` – Events verifiziert in Studio | Telemetry.spec; Dashboard-Daten erst mit echten Spielern |
| Feedback/Bug-Report | `[VERIFIZIERT]` | Feedback.spec + echter Klick mit Filter |
| Logging-Relay + Discord Logs | **offen** (PS-36) | braucht Owner: Discord-Server/Webhook bzw. Relay-Hosting-Entscheidung |
| Mobile-Optimierung | `[VERIFIZIERT]` (Phone 844×390 mit Touch-Skalierung, alle Fenster) | Screenshots; echtes Gerät in Beta |
| Tester-Rolle im Community-Discord | **offen** (PS-38) | Owner-Aktion |
| 10–30 Tester | **offen** | Beta-Place + Einladung (Owner #5), `docs/qa/beta-plan.md`, `docs/community/tester-guide.md` |
| Persistenz-Stresstest | `[VERIFIZIERT]` | Persistence.spec (echter DataStore) |

Exit-Kriterien:
| Kriterium | Status | Messung |
|---|---|---|
| ≥ 20 Tester-Sitzungen ausgewertet | offen | `tools/studio/beta_report.luau` (Sitzungsberichte, `Sessions_<ENV>`) – Werkzeug `[VERIFIZIERT]` mit echter Studio-Sitzung |
| Tutorial-Abschluss ≥ 80 % | offen | Bericht (Erstsitzungen) + Roblox Onboarding-Funnel |
| Fehlerrate unter Grenzwert (≤ 1 % Sitzungen mit Serverfehlern) | offen | Bericht + Roblox-Fehlerberichte |
| Economy mit realen Daten abgeglichen | offen | Median Federn/Min., Zeit bis Zone 2/Rebirth 1 vs. `economy.md` |
| Owner bestätigt MVP-Scope endgültig | offen | Owner |
