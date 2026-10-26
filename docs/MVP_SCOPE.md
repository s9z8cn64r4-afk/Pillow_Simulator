# MVP-Umfang – Version 1.0

> Status: **vorläufig freigegeben durch Orchestrator (2026-10-27)** – endgültige Owner-Freigabe spätestens vor Closed Beta (Masterprompt F.2).
> Änderungen nur per Change Request (`docs/decisions/CR-*.md`).

## Enthalten
| # | Feature | Prio | Milestone |
|---|---|---|---|
| 1 | Schlagen (aktiv + serverseitiger Auto-Swing ab Rank 2) mit Game-Feel-Feedback | P0 | M1/M2 |
| 2 | Federn als einzige Währung, Suffix-Anzeige | P0 | M1 |
| 3 | Sichere Speicherung (ProfileStore), Migrationen, BindToClose | P0 | M1 |
| 4 | Netzwerkschicht mit Schema, Validierung, Rate-Limits | P0 | M1 |
| 5 | 14 Kissen, 5 Seltenheiten, Shop, Ausrüsten, Pillow Index | P1 | M1 (3 Kissen) / M2 (alle) |
| 6 | Upgrades Feather Power + Swing Speed | P1 | M1 |
| 7 | **Kissenpuppen** mit Bonus (CR-001) | P1 | M2 |
| 8 | 1 Welt, 4 Zonen mit Barrieren und Teleport-Pads | P1 | M2 |
| 9 | Rebirth mit Erklär-Menü | P1 | M2 |
| 10 | 10 Ranks, Overhead-Titel, Rank-Up-Feier | P1 | M2 |
| 11 | Tutorial (6 Schritte), Nächstes-Ziel-Anzeige | P1 | M2 |
| 12 | Settings (Musik, SFX, Reduced Motion, Low VFX, UI-Größe), Toasts, Tooltips, Ladebildschirm | P2 | M2 |
| 13 | Daily Reward (7 Tage, Pause statt Reset), Willkommen-zurück-Karte | P2 | M3 |
| 14 | Codes, Gruppen-Bonus, **Freunde-Bonus** (CR-001), 2 Leaderboards | P2 | M3 |
| 15 | Monetarisierung: 2× Feathers, VIP, Better Auto-Swing, 2×-Boost-Produkt | P2 | M3 |
| 16 | Analytics-Events (Funnel, Economy, Progression), Logging-Relay → privater Discord | P2 | M3 |
| 17 | In-Game-Feedback/Bug-Report | P2 | M3 |
| 18 | Mobile/Tablet/Desktop; Gamepad-Grundbedienung | P1 | M2/M3 |

## Ausgeschlossen bis nach Release
Pets/Eggs · Trading · weitere Welten · Events · Limited Cosmetics · Season Pass · Quests · Achievements (außer Pillow Index) · Kissen-Level · PvP · Clans · Zweitwährung · Lokalisierung außer Englisch.

## Technische Mindestanforderungen
Server-Heartbeat ≥ 55 FPS bei 12 Spielern · Client ≥ 30 FPS auf Mittelklasse-Phone · kein Datenverlust in 100 Join/Leave/Shutdown-Zyklen · alle Remotes im Schema, validiert, rate-limitiert · 0 offene P0/P1.

## Definition of Done (je Aufgabe)
Akzeptanzkriterien belegt · Tests vorhanden und grün (Studio-Runner) · Review durch Prüfrolle · Analytics-Events (falls relevant) · Doku/Config/Changelog aktuell · Phone- und Desktop-Layout geprüft.

## Freigabebedingungen Release
Alle Punkte oben `[VERIFIZIERT]` · Release-Checkliste vollständig · Owner-Freigabe (Name, Preise, Veröffentlichung).

## Abhängigkeiten
Datenschema → PlayerDataService → Net → Swing → Shop/Upgrades → Zonen → Rebirth/Ranks → Tutorial → Retention → Monetarisierung → Analytics/Relay.
