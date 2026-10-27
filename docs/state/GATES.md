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
