# TEST_RESULTS

| Datum | Version/Commit | Suite | Ergebnis | Beleg |
|---|---|---|---|---|
| 2026-10-27 | Phase 0 | Economy-Simulation `sim.py --check` | alle Zielkurven OK | Konsolenausgabe, `docs/design/economy.md` |
| 2026-10-27 | 0.1.0-dev | Studio-Runner Unit (24) + Integration (6 mit echtem Spieler, ProfileStore-Roundtrip) | **30/30 PASS** (2 Läufe) | Studio-Konsole: `[TEST] SUMMARY 30/30 passed` |
| 2026-10-27 | 0.1.0-dev | Exploit-Basis (Client feuert NaN, 100-KB-String, Tabelle, gesperrtes Kissen, Zusatzargumente, falscher Typ, 60× Swing-Spam, 30× Upgrade-Spam) | **bestanden**: keine Käufe/Federn gutgeschrieben, ≥75 Verstöße gezählt, kein Absturz | Konsole `Netz-Verstoß count=25/50/75`; Federstand danach 1 (max. ein regulärer Schlag durch Cooldown), Werkzeug/Kissen unverändert |
| 2026-10-27 | 0.1.0-dev | Persistenz E2E: spielen → Play stoppen → neu starten | **bestanden**: 72 Federn vor und nach Rejoin | Konsole `Profil geladen {feathers=72}` |
| 2026-10-27 | 0.1.0-dev | Repo ↔ Studio Drift (37 Skripte) | **0 Abweichungen** | `tools/scripts/source_hash.py` |
| 2026-10-27 | 0.1.0-dev | Manueller Spieltest Desktop 1610×985: Halten = Dauerschlag, Puppen-Bonus, HUD, Shop-Layout | bestanden (Shop-Klick per Automatisierung nicht auslösbar → manuell prüfen) | Screenshots in Sitzung 1 |

## Offen / ungetestet
- Auto-Swing ab Rank 2 im Play-Modus
- Shop-Kauf per echtem Klick (Automatisierung konnte GUI-Buttons nicht anklicken)
- Phone-/Tablet-Layout (Geräteemulator)
- Schwebende „+X“-Zahlen visuell bestätigt (Screenshot-Timing verfehlt)
