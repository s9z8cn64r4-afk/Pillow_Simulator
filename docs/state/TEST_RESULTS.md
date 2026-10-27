# TEST_RESULTS

| Datum | Version/Commit | Suite | Ergebnis | Beleg |
|---|---|---|---|---|
| 2026-10-27 | Phase 0 | Economy-Simulation `sim.py --check` | alle Zielkurven OK | Konsolenausgabe, `docs/design/economy.md` |
| 2026-10-27 | 0.1.0-dev | Studio-Runner Unit (24) + Integration (6 mit echtem Spieler, ProfileStore-Roundtrip) | **30/30 PASS** (2 Läufe) | Studio-Konsole: `[TEST] SUMMARY 30/30 passed` |
| 2026-10-27 | 0.1.0-dev | Exploit-Basis (Client feuert NaN, 100-KB-String, Tabelle, gesperrtes Kissen, Zusatzargumente, falscher Typ, 60× Swing-Spam, 30× Upgrade-Spam) | **bestanden**: keine Käufe/Federn gutgeschrieben, ≥75 Verstöße gezählt, kein Absturz | Konsole `Netz-Verstoß count=25/50/75`; Federstand danach 1 (max. ein regulärer Schlag durch Cooldown), Werkzeug/Kissen unverändert |
| 2026-10-27 | 0.1.0-dev | Persistenz E2E: spielen → Play stoppen → neu starten | **bestanden**: 72 Federn vor und nach Rejoin | Konsole `Profil geladen {feathers=72}` |
| 2026-10-27 | 0.1.0-dev | Repo ↔ Studio Drift (37 Skripte) | **0 Abweichungen** | `tools/scripts/source_hash.py` |
| 2026-10-27 | 0.1.0-dev | Manueller Spieltest Desktop 1610×985: Halten = Dauerschlag, Puppen-Bonus, HUD, Shop-Layout | bestanden (Shop-Klick per Automatisierung nicht auslösbar → manuell prüfen) | Screenshots in Sitzung 1 |
| 2026-10-27 | 0.1.0-dev S2 | Auto-Swing (Integration), UI-Kauf per echtem Klick, Phone-Layout 844×390, Sound-Ladeprüfung (5) | bestanden | Konsole/Screenshots Sitzung 2 |
| 2026-10-27 | 0.1.0-dev S2 | Dauertest 2 (~10 Min. Halten + Auto-Swing nach BUG-001-Fix) | **bestanden**: 0 Verstöße, 0 Kicks, 0 Fehler, 59,9 FPS | Konsole, Heartbeat-Messung |
| 2026-10-27 | 0aff1bf | Studio-Runner Unit + Integration (Zonen, Rebirth, Settings, Restore-Wächter) | **49/49 PASS** (3 Läufe) | `[TEST] SUMMARY 49/49 passed` |
| 2026-10-27 | 0aff1bf | Persistenz E2E (Rejoin) | bestanden: 4,82 M → 4.858.081 | Konsole `Profil geladen` |
| 2026-10-27 | 0aff1bf | Settings + Index per echtem Klick (SFX 80→100 %, Reduced Motion an/aus, Index 4/14) | bestanden, Server-Roundtrip per StateDelta | Screenshots |
| 2026-10-27 | 0aff1bf | Repo ↔ Studio Drift (53 Skripte) | **0 Abweichungen** | `source_hash.py` |
| 2026-10-27 | f0d3c68 | GitHub Actions CI (StyLua, Selene, Economy-Sim) | **grün** (vorher rot seit Phase 0: Format + 1 Lint-Fehler) | Actions-Run 40445001694 |

| 2026-10-27 | fefe31f | Studio-Runner inkl. Rank.spec (Titel, Trail ab Rank 5) | **52/52 PASS** (2 Läufe) | `[TEST] SUMMARY 52/52 passed` |
| 2026-10-27 | fefe31f | Sichtprüfung 14 Kissenmodelle (Lineup), gehaltenes Fluffy/Dream, Aura + Trail vorhanden, Rank-Up-Banner + Konfetti | bestanden (2 Modelle neu generiert) | Screenshots Sitzung 3 |

| 2026-10-27 | de2d2d8 | Studio-Runner inkl. Tutorial.spec (8 Tests: 6 Schritte über echte Services, Boost, Skip, Reihenfolge) | **60/60 PASS** (2 Läufe) | `[TEST] SUMMARY 60/60 passed`, Funnel-Events in Konsole |
| 2026-10-27 | de2d2d8 | Tutorial-UI Desktop + Phone 844×390 (Hinweis, Markierung Swing/Shop, Boost-Anzeige) | bestanden nach Layout-Korrektur (Boost unter Federn, Karte 460 px) | Screenshots |

| 2026-10-27 | 5c52050 | Map-Dekor aller Zonen: Sichtprüfung je Zone + Testlauf | bestanden (60/60, Teile gesamt ~420, 13 Lichter) | Screenshots, Konsole |

| 2026-10-27 | 9e77dc5 | Play-Test Zone 2 freischalten (Prompt-Hold über Client-API) → Vorhang lokal offen, 75 K abgezogen, Lichtprofil Lounge aktiv (ClockTime 16,8, Atmosphäre Pfirsich) | bestanden; BUG-003 (Schild falsche Seite) gefunden + behoben | Konsole, Screenshots |

| 2026-10-27 | 2daf0a7 | **Bot-Durchlauf** (BotRun.spec, echte Services, Zeitraffer) bis Rebirth 3 | **bestanden**: keine Sackgasse; Zone 2 15,5 Min., Rebirth 1 77,7 Min., Rebirth 3 214 Min. (Faktor ≈ 1,7 zur Sim, ohne Puppen-Bonus) | Konsole `[BOT]`, `docs/design/economy.md` |
| 2026-10-27 | 2daf0a7 | Studio-Runner gesamt | **62/62 PASS** (Gameplay.spec gegen DEV-Spielstand isoliert) | `[TEST] SUMMARY 62/62 passed` |
| 2026-10-27 | 2daf0a7 | **Performance** (Play, 1 Spieler, Auto-Swing an, alle 4 Zonen dekoriert) | Client 59,9 FPS (Frame-Max 21 ms) · Server-Heartbeat 59,9 (Max 30 ms) · 483 Teile / 879 Instanzen im Workspace · aktive Federn 9 (Budget 60) · Senden 0,63 kbit/s (Budget 5 KB/s) · StreamingEnabled an | Konsole; Speicherwert (2,7 GB) = gesamter Studio-Prozess, nicht aussagekräftig → Mikroprofiler/Gerät in Beta |

## Offen / ungetestet
- Echtes Mobilgerät (Touch-Eingabe, Performance) – Closed Beta
- Mehrspieler (2+ Clients: RankTag/Notify für andere, fireNear)
- ProximityPrompt-Einblendung im echten Spielfenster (im automatisierten Studio-Fenster wird sie nicht angezeigt, Auslösen per API funktioniert)
- Hörprobe der Sounds durch Owner
- Server-Skriptzeit je Frame (Budget < 2 ms) – Mikroprofiler nicht automatisierbar, Owner-/Beta-Messung
- Client-Speicher auf Referenz-Smartphone
