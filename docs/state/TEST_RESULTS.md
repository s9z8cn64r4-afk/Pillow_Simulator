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

| 2026-10-27 | 994fbf8 | Studio-Runner inkl. M3 (Daily 7, Codes 5, Telemetry 5, Leaderboard 2; Runner schaltet Auto-Swing je Spec ab) | **86/86 PASS** | `[TEST] SUMMARY 86/86 passed` |
| 2026-10-27 | 994fbf8 | Daily per echtem Klick, Phone-Menü zweispaltig, Musik, Leaderboard-Tafeln mit echten DataStore-Einträgen | bestanden | Screenshots, Konsole |
| 2026-10-27 | e9e2d2e | Studio-Runner inkl. Social.spec (3) + Feedback.spec (4) | **93/93 PASS** | `[TEST] SUMMARY 93/93 passed` |
| 2026-10-27 | e9e2d2e | Feedback per echtem Klick (Settings → Feedback → Idee → Text → Senden) mit echtem TextService-Filter + DataStore | bestanden: Toast „Thanks for your feedback!“, Log `Feedback {category=idea, saved=true}` | Screenshots, Konsole |
| 2026-10-27 | e9e2d2e | Freunde-Badge im HUD (Attribut gesetzt) | bestanden: „👥 +20%“ unter den Federn | Screenshot; echter Freunde-Fall braucht Mehrspielertest |
| 2026-10-27 | e9e2d2e | Repo ↔ Studio Drift (78 Skripte) | 78/78 Pfade vorhanden, alle geänderten Hashes identisch | `studio_hash.luau` / `source_hash.py` |

| 2026-10-27 | bf510ba | Studio-Runner inkl. Monetization.spec (7: Pass-Wirkung, Kaufsperre ohne ID, idempotente Quittung, NotProcessedYet ohne Speicherbestätigung, Boost ohne Deckel, fremde Produkte/Spieler) | **100/100 PASS** | `[TEST] SUMMARY 100/100 passed` |
| 2026-10-27 | 76fce79 | **Persistenz-Stresstest** (Persistence.spec, echter DataStore DEV, Test-Schlüssel): 8 schnelle Sitzungswechsel, Doppel-Laden im selben Server, 1000 Quittungen, `saveAndWait` | **bestanden**: 0 Datenverlust (6,6 s für 8 Wechsel), Doppel-Laden verweigert, 1000/1000 geladen, Speicherbestätigung 0,6 s; Gesamt **104/104 PASS** | Konsole `[PERSIST]`, `SUMMARY 104/104` |
| 2026-10-27 | 76fce79 | Shop-Reiter „Extras“ (Desktop + Phone 844×390): 4 Artikel „SOON“, nicht kaufbar; Ziel-Leiste „ready!“ | bestanden | Screenshots |
| 2026-10-27 | aaf7b16 | Phone 844×390 mit Touch-Skalierung (0,8): Settings war höher als der Bildschirm (Titel/Schließen abgeschnitten) → Fenster passen sich an, Settings scrollt; Feedback-Fenster passt; Feedback-Knopf vergrößert | bestanden nach Korrektur (Scrollen bis „Code“ geprüft) | Screenshots |
| 2026-10-27 | aaf7b16 | Repo ↔ Studio Drift (81 Skripte) | **0 Abweichungen** | `source_hash.py` |

| 2026-10-27 | 44c5610 | Phone 844×390 + Touch-Skalierung: Rebirth, Zonen, Index, Daily | bestanden (Rebirth-Schrift vergrößert, Zonen/Index auf 400 px Höhe → passen ungeschrumpft) | Screenshots |
| 2026-10-27 | 5ae09f6 | Studio-Runner inkl. SessionReport.spec (3) | **107/107 PASS** | `[TEST] SUMMARY 107/107 passed` |
| 2026-10-27 | 5ae09f6 | Sitzungsbericht E2E: Play-Sitzung beenden → `Sessions_DEV` → `beta_report.luau` | bestanden: 1 Sitzung (3,2 Min., 0 Serverfehler), Feedback-Eintrag gelistet | Bericht-Ausgabe |

| 2026-10-27 | 3533e71 | Studio-Runner inkl. Griff-Rotationen (Config.spec) | **108/108 PASS** | `[TEST] SUMMARY 108/108 passed` |
| 2026-10-27 | fc8a49a | Arm-Schwung (AnimationConstraint-Rig): Messung Oberarm relativ zum Rumpf während Auto-Schlägen | **bestanden**: 8 Auto-Schläge/3 s, Winkel 69°–162° (vorher 0° – Arm bewegte sich nie) | Konsole Play-Test |
| 2026-10-27 | 3533e71 | Mehrspieler-Check (automatisch, `RunMultiplayerCheck`) | `[IMPLEMENTIERT, UNGETESTET]` – braucht Studio-Test mit 2 Spielern (Owner #3) | – |

| 2026-10-27 | e3a01a4 | Relay-Worker (node --test, CI-Job `relay`): Validierung, Datenschutzfilter, Deduplizierung, Discord-Grenzen, Token, 429-Retry | **12/12 PASS** | CI-Run 40578150820 |
| 2026-10-27 | e3a01a4 | Studio-Runner inkl. Relay.spec (7) | **115/115 PASS** | `[TEST] SUMMARY 115/115 passed` |
| 2026-10-27 | e3a01a4 | Schnittstelle Spiel ↔ Relay: echter Batch aus `RelayService` (Studio) durch den Worker (lokal, simuliertes Discord) | **bestanden**: 5 Kanäle, keine UserId im Batch, `@everyone` entschärft, Rollen-Ping nur in `#alerts-critical` | Konsolen-Ausgabe |
| 2026-10-27 | e3a01a4 | Repo ↔ Studio Drift (87 Skripte) | **0 Abweichungen** (Studio-Stand war gespeichert) | `source_hash.py` |

| 2026-10-27 | 5312931 | Relay-Einzeldatei fürs Dashboard (`dist/worker.js`): gleiches Verhalten wie Quelle + CI-Aktualitätsprüfung | **13/13 PASS** (Relay gesamt) | CI-Job `relay` |
| 2026-10-27 | 5312931 | Discord-Setup gegen simulierten Discord: Erstlauf, Idempotenz, Dry-Run, Berechtigungen Tester/Staff/Info, Community-Fallback, keine Pings, AutoMod-Formate, Rate-Limit | **9/9 PASS** | CI-Job `relay`, `node --test tools/discord-setup/` |

| 2026-10-27 | 37965ab | **Exploit-Suite v2** über die echten Remotes (Client, `tools/studio/exploit_suite.luau`): 37 Angriffe auf alle 13 Client-Remotes (falsche Typen, NaN/∞, 100-KB-Strings, 50-fach verschachtelte Tabellen, Zusatzargumente, Pfad-/SQL-Muster, gesperrte/fremde IDs) + 60× Schlag-Spam | **bestanden**: 0 geschützte Änderungen, 33/33 Validierungsangriffe als Verstoß gezählt (4 formal gültige von der Logik abgelehnt), Spam 45/60 gedrosselt, Server danach normal, Einstellungen im Bereich, 0 Handler-/Skriptfehler | Suite-Ausgabe, Server-Log |
| 2026-10-27 | 37965ab | Kick-Schwelle: weitere 140 Müll-Anfragen | **bestanden**: Server kickt bei genau 200 Verstößen (Log `Kick wegen Netz-Spam`, 0 Spieler danach) | Server-Log |
| 2026-10-30 | 1fb0c08 | **Persistenz-Stress 100 Zyklen** (`tools/studio/persistence_stress.luau`, echter DataStore `PlayerData_DEV`, Test-Schlüssel Test_Stress_1..4): Join → Prüfsumme → ändern → Leave; jeder 5. Zyklus Schnell-Rejoin, jeder 10. Shutdown-Pfad (Save + sofort EndSession) | **bestanden**: 100 Join/Leave, 20 Rejoins, 10 Shutdowns, 0 Prüfsummen-Abweichungen, 0 Ladefehler, Schlussprüfung 4/4, 59 s | Werkzeug-Ausgabe; echte Server-Abstürze/Übernahme zwischen Servern nur live prüfbar |
| 2026-10-30 | b4ef018 | **Server-Last** (`tests/perf/ServerBench.luau` über `ServerStorage.DevBench`, Studio): Schlagkosten + Dauerlast über den echten Server-Pfad | aktiver Schlag 0,033 ms, Auto-Schlag 0,011 ms · Ruhe 59,9 FPS · **40 Schläge/s (= 12 Spieler im Maximaltempo) 20 s: Heartbeat 59,9 FPS**, Schlag-CPU 0,05 ms/Frame · 120 Schläge/s (3-fache Reserve): 59,7 FPS, einzelner Ausreißer-Frame 101 ms · Client bei 40 Schlag-Effekten/s in der Nähe: 60 FPS, 0 Frames < 30 FPS | Hochrechnung mit 1 echtem Spieler (12 echte Clients nicht per Werkzeug startbar); Messung auf PC, nicht Phone |
| 2026-10-30 | f5a2e79 | Nach Art-Pass Zonen v2 (+723 Teile, 1201 Teile im Workspace): Studio-Runner + Client-FPS | **115/115 PASS** · Client 60 FPS (min 49) | Konsole `[TEST] SUMMARY 115/115 passed` |
| 2026-10-30 | 041a649 | Art-Pass Teil 2+3: Plüsch-Puppen (geschweißt), Props, `AmbientController`, Portale | **115/115 PASS**, 0 Fehler im Log · Puppe folgt Wackeln (0,2 Studs Versatz, zurück 0) · Discokugel dreht, max. 6 Lampen gedimmt, bei Reduced Motion steht beides · Lauf durch den Lounge-Durchgang: Zone wechselt auf `livingroom` · Client 60 FPS | Konsole, Client-Messung |
| 2026-10-30 | 1af7ecf | UI-Politur: Daily-Fenster, Puppen-Schilder, 3D-Kissen-Vorschau in Shop + Index (28 ViewportFrames) | **115/115 PASS**, 0 Fehler · Shop/Index per Klick geöffnet, Vorschauen + Silhouetten sichtbar | Screenshots Play-Test |
| 2026-10-30 | 2896306 | UI-Politur Zonen- und Rebirth-Fenster | **115/115 PASS**, 0 Fehler · per Klick geöffnet: Zonen-Kacheln + Markierung aktuelle Zone, Rebirth-Fortschritt 5,82M / 80M | Screenshots Play-Test |
| 2026-10-30 | 480f12b | Phone-Simulation 844 × 390 + Touch (Daily, Zonen, Rebirth, Shop, Index) + Ziel-Leiste mit Kissen-Vorschau | alle Fenster vollständig sichtbar, Schließen-Knopf erreichbar · **115/115 PASS**, 0 Fehler | Screenshots Play-Test |
| 2026-10-30 | a9c7824 | **Tutorial-Durchlauf als Neuspieler** (frischer Spielstand, Klicks auf echte Knöpfe) | alle 6 Schritte in ~3 Min., Abschluss-Banner + 2×-Boost · 2 UX-Funde behoben und erneut geprüft (Shop-Reiter passend, Puppe leuchtet + Marker, Marker verschwindet nach Treffer) · **115/115 PASS**, 0 Fehler, DataStore wieder `PlayerData_DEV` | Screenshots Play-Test |
| 2026-10-30 | a1da7c8 | Neuspieler bis Rank 2 (frischer Spielstand): AUTO-Hinweis + Daily-Zeitpunkt | Ring am AUTO-Knopf sichtbar, nach Klick weg · Daily öffnet ~25 s nach Tutorial-Ende (nicht mehr über der Feier) · **115/115 PASS**, 0 Fehler | Screenshot + Client-Prüfung |
| 2026-10-30 | 2bed301 | Studio-Fotomodus (5 Szenen) + Umbau Kissen-Tool in Shared-Modul | alle 5 Szenen per Screenshot geprüft (HUD aus, Kamera fest, Kissen in der Hand, Federn) · Beenden stellt Kamera, HUD, Laufen wieder her · **115/115 PASS**, 0 Fehler | Screenshots Play-Test |
| 2026-10-30 | 0fce8ce | Schlag-Effekte nach Seltenheit | Treffer auf Puppe mit Satin (Rare): 14 aktive Federn (10 × 1,4) + Funken-Emitter · **115/115 PASS**, 0 Fehler · Zonen-Banner noch ungetestet | Client-Messung |

## Offen / ungetestet
- Echtes Mobilgerät (Touch-Eingabe, Performance) – Closed Beta
- Relay live (Cloudflare + Discord + Roblox-Secrets, Owner #6)
- Discord-Setup gegen echten Server (Owner #7)
- Echte Robux-Käufe (brauchen Owner-IDs/Preise, OWNER_REQUESTS #4) und Sitzungsübernahme zwischen zwei Servern (nur live nachstellbar)
- Mehrspieler (2+ Clients: RankTag/Notify für andere, fireNear, **Freunde-Bonus mit echten Freunden**)
- ProximityPrompt-Einblendung im echten Spielfenster (im automatisierten Studio-Fenster wird sie nicht angezeigt, Auslösen per API funktioniert)
- Hörprobe der Sounds durch Owner
- Server-Skriptzeit je Frame (Budget < 2 ms) – Mikroprofiler nicht automatisierbar, Owner-/Beta-Messung
- Client-Speicher auf Referenz-Smartphone
