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
