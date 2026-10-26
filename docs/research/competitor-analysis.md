# Konkurrenzanalyse & Design-Empfehlung (Phase 0)

> Stand 2026-10-27 · Rolle: Design & Economy · Status: `[ENTWURF]` – Recherche-Tiefe: mittel (eine Sitzung).
> Kennzeichnung: **(B)** = belegt mit Quelle · **(H)** = Hypothese/Erfahrungswert, noch nicht belegt.

## 1. Referenzspiele

| Spiel | Kennzahlen | Kern-Hooks |
|---|---|---|
| **Ninja Legends** (Muscle Legends Studio, seit 09/2019) | 2,2 Mrd. Besuche, 4,7 Mio. Favoriten, Peak-CCU 11,2 K, aktuell ~400–600 CCU, Ø Session 12,1 Min., 92,5 % positiv; letztes Update ~08/2026 **(B)** [1] | Klick-Training → Stats, Rebirth/„Ranks“, Inseln als Höhen-Gates, Pets aus Eiern, Elemente **(H)** |
| **Bubble Gum Simulator INFINITY** (Neuauflage 2025) | >500 Mio. Besuche bis Sommer 2025 (Visits-Event in Update 12) **(B)** [2] | Eier/Pets mit extrem seltenen Secret-Pets (0,0001 %), Welten, Rifts (temporäre Buff-Zonen), Masteries, Tränke-Tiers, Truhen, Season Pass, Events im Wochenrhythmus, Codes pro Update **(B)** [2] |
| **Blade Simulator** | keine belastbaren Zahlen gefunden | Schwert-Schwung → Stärke, Rebirth, Pets – Annahme aus Genre-Muster **(H)** |
| **Pillow Fighting Simulator** (xFrozen Entertainment) | treue Fanbasis, keine Zahlen **(B)** [3] | Antippen erhöht Stärke, Kämpfe in Arenen gegen Spieler/NPCs, Pets und Tränke über Codes **(B)** [3] |

**Wichtigster Fund:** Mit *Pillow Fighting Simulator* existiert ein thematisch sehr nahes Spiel. Der Arbeitstitel „Pillow Simulator“ ist dadurch schwach unterscheidbar (Suche, Markenwahrnehmung). → Empfehlung in Abschnitt 4.

## 2. Was die Plattform 2026 belohnt (B)

Roblox hat die Empfehlungslogik im Juni 2026 umgestellt [4][5]:
- **Langfristige Bindung:** 28-Tage-Sicht statt 7 Tage; getrennte Signale für D1, D2–7, D8–28.
- **Qualified Play-Through** aufgeteilt in Play-Through-Verhalten, Session-Qualität und Ausgaben.
- **Co-Play** (Spieler bringen Freunde mit) ist ein eigenes Signal.
- **First-Play-Bounce** (<60 s und 61–180 s) ist ein negatives Signal.
- Spielzeit pro Nutzer zählt nur bis 60 Min./Tag/Spiel.
- Nur Spiele mit **eigenem Thumbnail** erhalten Home-Empfehlungen; Thumbnails müssen das Spiel korrekt zeigen.
- Kurzfristiges Engagement wurde abgewertet, weil auffällige Thumbnails Spiele mit dauerhaftem Wert verdrängt hatten.

**Folgerung:** Ein Simulator, der in Woche 2–4 nichts Neues bietet, wird kaum noch verteilt. Retention D8–28 und Co-Play sind für Pillow Simulator wichtiger als ein lauter Start.

## 3. Analyse nach den 10 Leitfragen

1. **Warum erfolgreich:** Sofort verständliche Handlung (klicken), sichtbar wachsende Zahlen, ständig ein nächstes Ziel in Reichweite, Sammel-Kompletion (Pets/Index), hoher Update-Takt mit Codes als Rückkehr-Anlass **(B für BGSI-Updates/Codes [2], sonst H)**.
2. **Gut funktionierende Loops:** Zahlen-Eskalation + Zonen-Gates; Rebirth als Neustart mit Multiplikator; Ei-/Pet-Sammeln als zweite Achse; zeitlich begrenzte Events **(H, Genre-Muster)**.
3. **Langzeitmotivation:** Sammlungen, Ranglisten, Rebirth-Stufen, saisonale Inhalte, soziale Prestige-Anzeigen (Titel, seltene Pets) **(H)**.
4. **Häufige Kritik:** Pay-to-Win-Wahrnehmung, Grind-Wände kurz nach dem Start, überladene UI mit Kaufaufforderungen, extrem niedrige Wahrscheinlichkeiten, die zum Kauf drängen **(H; Quellen nur meinungsbasiert)**.
5. **Veraltet:** Reines Klicken ohne Feedback oder Variation; endlose, nur umgefärbte Zonen; Spiele, die die Rückkehr nicht anerkennen [6].
6. **Abwanderung zwischen Session 2 und 5:** Session 2 bietet nichts Neues, Session 1 endet ohne offenes Ziel; Inhalte hinzuzufügen hilft nicht, wenn die Kernhandlung gleich bleibt [6] **(B, Fachartikel – Aussage plausibel, nicht offiziell)**.
7. **Einsteiger:** In den ersten 60 s schlagen und belohnt werden; früh Fortschritt zeigen, niedrige erste Schwellen, Startgegenstände; Onboarding mit einem Erfolgsmoment beenden [7] **(B)**.
8. **Casual vs. Langzeit:** Casual braucht kurze Ziele und Auto-Swing; Langzeit braucht Rebirth-Tiefe, Sammlung, Ranglisten **(H)**.
9. **Monetarisierung & Regeln:** Zufallsgegenstände, die direkt oder indirekt mit Robux gekauft werden (auch über Robux-Währung, Glücks-Boosts), brauchen vollständige Wahrscheinlichkeitsanzeige; `PolicyService` muss pro Spieler geprüft werden, eingeschränkte Spieler erhalten einen kostenlosen Weg oder Direktkauf **(B)** [8].
10. **Eigene Identität:** Siehe Abschnitt 4.

## 4. Design-Empfehlung (Auswirkung auf GDD/MVP)

| # | Empfehlung | Begründung | Aufwand | Wirkung auf Plan |
|---|---|---|---|---|
| R1 | **Titel ändern.** Vorschläge: *Pillow Smash Simulator*, *Feather Frenzy*, *Pillow Legends*. Bis zur Owner-Entscheidung Arbeitstitel behalten | Name zu nah an *Pillow Fighting Simulator* [3] | S | Owner-Entscheidung |
| R2 | **Erster Schlag ≤ 10 s, erster Kauf ≤ 30 s** (bestätigt Zielkurve J.4) | First-Play-Bounce <60 s ist negatives Signal [5] | S | Economy-Ziele |
| R3 | **Kissenpuppen („Dummies“) ab Zone 1 ins MVP** – Treffer auf eine Puppe gibt Bonus-Federn und Combo; Zone 2 bringt bewegliche Puppen | Kernhandlung variiert sich (Session-2-Problem [6]) | M | MVP-Feature (war optional) |
| R4 | **Freunde-im-Server-Bonus ins MVP** (+10 % pro Freund, max. +30 %) | Co-Play ist ein Empfehlungssignal [4] | S | MVP (war 1.1, Option in E.8) |
| R5 | **Offenes Ziel am Session-Ende:** HUD zeigt immer „Nächstes Ziel“ (Kissen/Zone/Rank) mit Fortschritt; Abschluss-Toast „Morgen wartet Tag 2 deiner Belohnungen“ | Session 1 muss mit offener Schleife enden [6] | S | UI |
| R6 | **Rückkehr anerkennen:** „Willkommen zurück“-Karte mit Daily Reward + Hinweis auf neue Codes | [6] | S | im Daily Reward enthalten |
| R7 | **Physisches Game Feel als USP** (Squash & Stretch, Federburst, Kamera-Mikroimpuls) | Abgrenzung zu „reinem Klicken“ [6] | M | bereits im Plan |
| R8 | **Keine bezahlten Zufallsitems im MVP**; Eggs (1.1) gegen Federn, nicht gegen Robux | Vermeidet Richtlinienaufwand und Pay-to-Win-Kritik [8] | – | bestätigt J.5 |
| R9 | **Eigenes, ehrliches Thumbnail vor jedem Test mit externen Spielern** | Pflicht für Empfehlungen [5] | S | Marketing Phase 3 |
| R10 | **Update-Takt mit Codes** ab Release (wöchentlich kleine Codes, alle 2 Wochen Update) | Muster der Marktführer [2] | – | LiveOps-Plan |

**Nicht übernommen:** Extrem seltene Secret-Drops (0,0001 %) und Tränke-Tier-Kaskaden – passen nicht zur fairen, transparenten Ausrichtung und erhöhen Komplexität.

## Quellen
1. [Rotrends – Ninja Legends](https://rotrends.com/game/1335695570)
2. [Sportskeeda – BGSI Update 12 Patch Notes](https://www.sportskeeda.com/roblox-news/bubble-gum-simulator-infinity-update-12-patch-notes)
3. [Twinfinite – Pillow Fighting Simulator](https://twinfinite.net/roblox/pillow-fighting-simulator-codes/)
4. [Roblox Newsroom – Optimizing Discovery (06/2026)](https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox)
5. [Roblox Creator Docs – Discovery](https://create.roblox.com/docs/discovery)
6. [RoWatcher – Why your Roblox game bleeds players between sessions 2 and 5](https://rowatcher.com/news/why-your-roblox-game-bleeds-players-between-sessions-2-and-5)
7. [Roblox Creator Docs – Onboarding](https://create.roblox.com/docs/production/game-design/onboarding)
8. [Roblox Creator Docs – Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)
9. [DevForum – ProfileStore](https://devforum.roblox.com/t/profilestore-save-your-player-data-easy-datastore-module/3190543/) (Technikwahl, siehe ADR-0002)

## Offene Recherche (Backlog)
- Belastbare Zahlen zu Blade Simulator und 3–5 aktuellen Top-Simulatoren (Creator-Hub-Benchmarks nach Veröffentlichung nutzen).
- Mobile-Anteil der Zielgruppe (offizielle Zahl suchen).
