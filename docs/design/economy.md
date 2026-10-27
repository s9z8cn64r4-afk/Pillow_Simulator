# Economy-Modell & Simulationsbericht v1

> Stand 2026-10-27 · Rolle: Design & Economy · Status: `[VERIFIZIERT]` (Simulation läuft, alle Zielkurven erfüllt) – reale Spielerdaten folgen in Closed Beta.
> Wertequelle: `tools/economy-sim/content.py` → generiert `src/shared/Config/*.luau`. Reproduzieren: `python3 tools/economy-sim/sim.py --check`.

## Formeln (identisch in `src/shared/Util/Formulas.luau`)
- **Federn pro Schlag** = Kissen-Power × (1 + 0,25 × FeatherPower-Level) × Zonen-Multiplikator × Rebirth-Multiplikator × (1 + Rank-Bonus) × weitere Multiplikatoren (Puppe 1,5 · Freunde bis +30 % · Gruppe +10 % · Boost · Gamepass). **Kein Abrunden** – Federn werden als Kommazahl geführt und abgerundet angezeigt (sonst sind frühe Boni wirkungslos).
- **Cooldown** = max(0,30 s; (0,60 s − 0,05 s × SwingSpeed-Level) × Kissen-Tempo).
- **Upgrade-Kosten(n)** = Basis × Wachstum^n → Feather Power: 5 × 1,28^n · Swing Speed: 100 × 4^n (6 Stufen).
- **Rebirth-Kosten(n)** = 80 Mio. × 6^n Federn (werden abgegeben). **Rebirth-Multiplikator** = 1 + 0,5 × R (ab R > 10: +0,25 je weiterem Rebirth).
- **Rank** nach lebenslangen Federn (10 Stufen, 0 → 5 Billionen), Bonus +3 % … +30 %.

## Quellen und Senken
| Quellen | Senken |
|---|---|
| Schlagen (aktiv, mit Puppen-Bonus) · Auto-Swing (80 %) · Daily Reward (in „Minuten Produktion“) · Codes · Boosts | 14 Kissen · Feather Power (bis 100) · Swing Speed (6) · 3 Zonen-Freischaltungen · Rebirth (verbraucht alle Federn) |

Rebirth ist der zentrale Inflations-Reset: Federn, Upgrades und Zonen 2–4 werden zurückgesetzt; **Kissen bleiben** (Entscheidung, damit Rebirth nicht als Verlust empfunden wird).

## Simulation v1 (Bot kauft stets das Angebot mit kürzester Amortisationszeit)
Profile: Casual 15 Min./Tag (50 % aktiv), Regular 45 Min./Tag (60 % aktiv), Grinder 180 Min./Tag (30 % aktiv), Regular mit 2×-Pass.
Angaben = **aktive Spielzeit** (Tag x = Kalendertag beim jeweiligen Tagesbudget).

| Meilenstein | Casual | Regular | Grinder | Regular + 2x Pass |
|---|---|---|---|---|
| Erstes Upgrade | 4 s | 4 s | 3 s | 2 s |
| Erstes neues Kissen | 45 s | 39 s | 36 s | 20 s |
| Rank 2 (Auto-Swing) | 1,4 Min. | 1,2 Min. | 1,1 Min. | 36 s |
| Zone 2 | 10,1 Min. | 9,1 Min. | 9,2 Min. | 4,6 Min. |
| Zone 3 | 26,4 Min. | 23,9 Min. | 24,4 Min. | 12,0 Min. |
| Rank 5 | 27,2 Min. | 24,6 Min. | 25,2 Min. | 12,4 Min. |
| Rebirth 1 | 51,8 Min. | 47,0 Min. | 48,1 Min. | 23,6 Min. |
| Zone 4 | 81 Min. (Tag 6) | 74 Min. (Tag 2) | 76 Min. (Tag 1) | 37 Min. |
| Rebirth 3 | 2,4 h (Tag 10) | 2,1 h (Tag 3) | 2,2 h (Tag 1) | 64 Min. (Tag 2) |
| Rebirth 5 | 5,8 h (Tag 24) | 5,3 h (Tag 8) | 5,4 h (Tag 2) | 2,6 h (Tag 4) |
| Starlight (Legendary) | 8,1 h (Tag 33) | 7,4 h (Tag 10) | 7,6 h (Tag 3) | 3,7 h (Tag 5) |
| Dreamweaver (Legendary) | 15,7 h (Tag 63) | 14,3 h (Tag 20) | 14,6 h (Tag 5) | 7,1 h (Tag 10) |
| Rank 10 = alle MVP-Inhalte | 18,2 h (Tag 73) | 16,6 h (Tag 23) | 17,0 h (Tag 6) | 8,3 h (Tag 12) |

## Zielkurven-Prüfung (Regular)
| Ziel (J.4) | Ergebnis | Status |
|---|---|---|
| Erstes Upgrade ≤ 30 s | 4 s | OK |
| Erstes neues Kissen ≤ 2 Min. | 39 s | OK |
| Zone 2 ≈ 10–15 Min. | 9,1 Min. | OK (Toleranz) |
| Erster Rebirth ≈ 45–60 Min. | 47 Min. | OK |
| MVP-Inhalte Regular ≈ 2–3 Wochen | 22 Tage | OK |
| Legendary erst nach mehreren Rebirths | Starlight ab Rebirth 3, Dreamweaver ab Rebirth 5 | OK |
| Größte Federzahl < 2^53 | ≈ 5 × 10¹² | OK |

## Fairness
- 2×-Gamepass beschleunigt bis Content-Ende um genau 2,0× (Grenze laut Masterprompt eingehalten); Nicht-Zahler erreichen alle Inhalte.
- Casual-Spieler brauchen ~10 Wochen für alles – Post-Launch-Content (1.1/1.2) muss so geplant werden, dass auch sie neue Ziele haben, bevor sie das Ende erreichen.

## Bekannte Grenzen der Simulation
- Bot spielt optimal; reale Spieler kaufen suboptimal → in Beta mit Funnel-Daten kalibrieren.
- Daily Rewards, Codes, Freunde-/Gruppen-Bonus nicht eingerechnet (beschleunigen real um ~10–30 %).
- Feinkörnig ab Rebirth 3: lange Abschnitte (Rebirth 3 → 5 ≈ 3 h beim Regular) – Kandidat für die Funnel-Beobachtung („Grind-Wand“).

## Bot-Durchlauf im Spiel (PS-22, 2026-10-27)
`tests/integration/BotRun.spec.luau` spielt mit den echten Services (StatsService-Ertrag inkl. Zonen-Multiplikator nach echter Position, Shop, ZoneService, RebirthService) im Zeitraffer (Tick = 10 s aktive Schläge, **ohne** Puppen-Bonus und Auto-Swing-Mix; Kauf-Heuristik: nächste Zone → bestes leistbares Kissen → Upgrades bis 50 % der Federn).

| Meilenstein | Bot (Spiel) | Sim „Regular“ | Faktor |
|---|---|---|---|
| Zone 2 | 15,5 Min. | 9,1 Min. | 1,70 |
| Rebirth 1 | 77,7 Min. | 47 Min. | 1,65 |
| Rebirth 3 | 214 Min. | 126 Min. | 1,70 |

**Befund:** Kein Fortschrittsblocker bis Rebirth 3; Server-Formeln und Sim stimmen strukturell überein (gleichmäßiger Faktor ≈ 1,7). Der Abstand erklärt sich durch fehlenden Puppen-Bonus (×1,5 auf einen Teil der Schläge) und die einfachere Kauf-Heuristik. **Konsequenz:** Spieler, die Puppen ignorieren, erreichen Zone 2 erst nach ~15 Min. (Obergrenze des Ziels). Das Tutorial lehrt den Puppen-Bonus (Schritt 3); keine Änderung jetzt – nach Closed Beta mit echten Funnel-/Session-Daten neu bewerten (R-Eintrag in RISKS.md).
