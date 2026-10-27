# Risk Register

| ID | Risiko | W | A | Gegenmaßnahme | Verantwortlich |
|---|---|---|---|---|---|
| R-01 | Datenverlust/Duplikation | M | H | ProfileStore, Shutdown-Tests, idempotente Käufe | Tech Lead / QA |
| R-02 | Economy-Exploit (Remote-Spam, Fake-Werte) | M | H | Server-Autorität, Schema-Validierung, Rate-Limits, Exploit-Suite | QA & Security |
| R-03 | Name zu nah an „Pillow Fighting Simulator“ | H | M | Alternativtitel vorgeschlagen, Owner-Entscheidung vor Store-Seite | Growth |
| R-04 | Geringe Sichtbarkeit (Algorithmus 2026 gewichtet D8–28, Co-Play) | H | H | Puppen-Variation, Freunde-Bonus, Update-Takt mit Codes, ehrliche Thumbnails | Design / Growth |
| R-05 | Repo ↔ Studio driften auseinander (kein Rojo-Live-Sync) | M | M | Hash-Abgleich vor Meilensteinen, Repo zuerst ändern (ADR-0001) | DevOps |
| R-06 | ~~Kein Push zu GitHub~~ – **erledigt** (Push + CI laufen) | – | – | – | DevOps |
| R-07 | ~~Lizenzlage ProfileStore unklar~~ – **geklärt: Apache-2.0** (kommerziell erlaubt, Lizenzhinweis mitführen → `THIRD_PARTY_NOTICES.md`) | – | – | – | Tech Lead |
| R-08 | Grind-Wand Rebirth 3→5 (Sim: ~3 h) | M | M | Funnel-Beobachtung in Beta, Feinjustierung über content.py | Design |
| R-09 | Mobile-Performance durch Partikel | M | M | Budgets G.6, Low-VFX, Pooling | Art / QA |
| R-10 | Kontextverlust zwischen Sitzungen | M | M | docs/state + Spiegelung PROJECT_STATE ins Claude-Projekt | Orchestrator |
| R-11 | Frühe Phase zu langsam für Spieler ohne Puppen-Nutzung (Bot: Zone 2 nach ~15 Min., Ziel 10–15) | M | M | Tutorial lehrt Puppen-Bonus; Beta-Funnel prüfen, ggf. Zone-2-Preis senken (content.py) | Design |

W = Wahrscheinlichkeit, A = Auswirkung (L/M/H)
