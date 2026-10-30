# Game Design Document – Pillow Legends v1

> Stand 2026-10-27 · Rolle: Design & Economy · Status: `[ENTWURF]`, gilt nach MVP-Freigabe als verbindlich.
> Grundlage: Masterprompt B/E, Recherche `docs/research/competitor-analysis.md`, Werte `docs/design/economy.md`.

## 1. Vision
Weicher, humorvoller Kissenschlacht-Simulator: mit einem zerfledderten Kissen Federn herausschlagen, immer prächtigere Kissen sammeln, gemütlich-verrückte Schlafwelten freischalten und per Rebirth zur Legende werden. **USP:** Jeder Schlag fühlt sich gut an (Game Feel), faire Wirtschaft ohne Kaufdruck, aufgeräumtes Mobile-UI.

**Titel:** „Pillow Simulator“ ist nah an dem existierenden *Pillow Fighting Simulator*. Vorschläge: *Pillow Smash Simulator*, *Feather Frenzy*, *Pillow Legends* – **Entschieden (Owner, 2026-10-27): Pillow Legends.**

## 2. Zielgruppe
9–15 Jahre, überwiegend Mobile; sekundär ältere Simulator-Fans. Spielertypen: Achiever (Ranks, Rebirths), Collector (Pillow Index), Socializer (Freunde-Bonus, Leaderboards), Explorer (Zonen-Details, Codes).

## 3. Loops
- **Sekunde:** Tippen → Schwung → Federburst + „+12“ → Zähler rollt.
- **Minute:** Nächstes Upgrade/Kissen erreichen; Puppen treffen für Bonus.
- **Session (5–20 Min.):** neue Zone oder Rebirth; HUD zeigt immer das nächste Ziel.
- **Tag:** Daily Reward, Codes, Leaderboard.
- **Langzeit:** Rebirth-Stufen, Ranks, Pillow Index komplettieren; später Pets, Welten, Events.

## 4. Systeme (MVP)

### 4.1 Schlagen
- Tippen/Klicken/Halten oder Schlag-Taste (Mobile unten rechts, groß). Server prüft Cooldown und berechnet Ertrag; der Client sendet nur „Schlag“.
- **Kissenpuppen (Dummies):** stehen in jeder Zone; Schlag innerhalb der Reichweite (9 Studs, Server-Prüfung) → ×1,5 und Treffer-Feedback (Puppe wackelt, Federn fliegen von der Puppe). Zone 2+ hat wippende Puppen. *Neu durch Recherche (R3).*
- **Auto-Swing:** kostenlos ab Rank 2, serverseitig, 80 % Effizienz (Gamepass: 100 %). Schalter im HUD.
- **Feedback:** Squash & Stretch des Kissens, Federpartikel, schwebende Zahl, Sound mit Tonhöhen-Variation, alle 10 Schläge Mini-Combo-Funke. Reduced Motion: kleiner Burst, keine Kamera.

### 4.2 Federn
Einzige Währung. Kommazahl intern, Anzeige abgerundet mit Suffixen (K, M, B, T). Keine Zweitwährung im MVP.

### 4.3 Kissen (14)
| # | Kissen | Seltenheit | Power | Preis | Voraussetzung |
|---|---|---|---|---|---|
| 0 | Worn-Out Pillow | Common | 1 | Start | – |
| 1 | Cotton Pillow | Common | 3 | 75 | – |
| 2 | Striped Pillow | Common | 7 | 600 | – |
| 3 | Fluffy Pillow | Uncommon | 16 | 4,5 K | – |
| 4 | Sleepover Pillow | Uncommon | 38 | 35 K | Zone 2 |
| 5 | Heart Pillow | Uncommon | 90 | 250 K | Zone 2 |
| 6 | Satin Pillow | Rare | 210 | 1,8 M | Zone 2 |
| 7 | Hotel Deluxe Pillow | Rare | 480 | 13 M | Zone 3 |
| 8 | Royal Velvet Pillow | Rare | 1,1 K | 90 M | Zone 3 |
| 9 | Memory Foam Pillow | Epic | 2,6 K | 650 M | Zone 3, Rebirth 1 |
| 10 | Cloud Puff Pillow | Epic | 6,2 K | 4,5 B | Zone 4, Rebirth 1 |
| 11 | Thunder Pillow | Epic | 15 K | 32 B | Zone 4, Rebirth 2 |
| 12 | Starlight Pillow | Legendary | 36 K | 230 B | Zone 4, Rebirth 3 |
| 13 | Dreamweaver Pillow | Legendary | 90 K | 1,6 T | Zone 4, Rebirth 5 |

Kauf im Shop gegen Federn (deterministisch), Kissen bleiben beim Rebirth. Ab Rare leicht schnellerer Schwung (Tempo-Faktor 0,97–0,88). Seltenheit farbig **und** mit Symbol (● ◆ ★ ❖ 👑 – ✦ und ♛ werden von der Roblox-Schrift nicht dargestellt, getestet 30.10.). Ab Epic Aura, ab Legendary eigener Trail. **Pillow Index:** Raster aller Kissen (gesehen/besessen/gesperrt mit Bedingung).

### 4.4 Upgrades
Feather Power (+25 % je Stufe, bis 100) und Swing Speed (−0,05 s je Stufe, 6 Stufen). Werden beim Rebirth zurückgesetzt.

### 4.5 Zonen (1 Welt, 4 Zonen)
| Zone | Multiplikator | Preis | Voraussetzung | Stimmung |
|---|---|---|---|---|
| Cozy Bedroom | ×1 | Start | – | Kinderzimmer, Bettburgen, Spielzeug |
| Pajama Party Lounge | ×2 | 75 K | – | Wohnzimmer, Lichterketten, Sofa-Festung |
| Grand Hotel Suite | ×4 | 4 M | – | Gold, Samt, riesiges Hotelbett |
| Cloud Kingdom | ×8 | 250 M | Rebirth 1 | Wolkeninseln, Mondlicht |

Barriere mit Preisschild; Kauf per Halten der Interaktion (ProximityPrompt) → Barriere öffnet sich (Kamerafahrt folgt in M2/Polish). Zonen-Menü mit Teleport. Server bestimmt die Zone aus der Position (Zonen-Volumen). Teleport-Pads zu bereits offenen Zonen.

### 4.6 Rebirth
Kosten 80 M × 6^R Federn. Reset: Federn, Upgrades, Zonen 2–4. Behalten: Kissen, Rank, Daily-Fortschritt, Einstellungen. Gewinn: +50 % dauerhaft (ab R 11 +25 %), Freischaltung Zone 4 bzw. Epic/Legendary-Kissen. Menü zeigt „Du verlierst / Du behältst / Du bekommst“ mit Zahlen; Bestätigung durch zweites Tippen innerhalb von 3 s.

### 4.7 Ranks (10)
Sleepyhead → Pillow Rookie (500) → Feather Fighter (25 K) → Fluff Brawler (500 K) → Cushion Champion (8 M) → Duvet Duke (150 M) → Slumber Knight (2 B) → Dream Warden (30 B) → Night Sovereign (400 B) → Pillow Legend (5 T) lebenslange Federn. Bonus +3 % … +30 %. Rank 2: Auto-Swing; ab Rank 5 kosmetischer Schwung-Trail. Titel über dem Kopf, Rank-Up-Feier mit Toast an den Server.

### 4.8 Retention & Soziales (MVP)
- **Daily Reward** 7 Tage: Federn als „x Minuten Produktion“ (Tag 1: 3, 3: 6, 5: 10, 7: 20) und 2×-Boosts (10/15/20 Min.). Verpasster Tag pausiert die Kette (kein Reset).
- **Willkommen-zurück-Karte** mit Daily Reward und Hinweis auf aktive Codes (R6).
- **Codes** (serverseitig gehasht, einmal pro Spieler, mit Ablaufdatum).
- **Freunde-im-Server-Bonus** +10 % je Freund, max. +30 % (R4).
- **Gruppen-Bonus** +10 % für Mitglieder der Roblox-Gruppe.
- **Leaderboards:** Lebenslange Federn, Rebirths (Top 50, alle 60–120 s aktualisiert).
- **Nächstes-Ziel-Anzeige** im HUD (R5).

### 4.9 Onboarding (≤ 3 Min.)
1. „Tippe, um zu schlagen!“ (Pfeil auf Schlag-Taste) → erster Schlag ≤ 10 s.
2. „Kauf Feather Power“ → Shop öffnet sich mit Markierung (≈ 5 s Spielzeit).
3. „Triff eine Kissenpuppe!“ → Bonus erleben.
4. „Kauf dein erstes neues Kissen“ (≈ 40 s) → Enthüllungskarte.
5. „Erreiche Rank 2“ → Auto-Swing wird erklärt.
6. Ziel-Anzeige zeigt Zone 2 → Tutorial endet mit Konfetti + kleinem Boost.
Jeder Schritt = Funnel-Event.

### 4.10 Monetarisierung (MVP)
2× Feathers (Pass), VIP (Kosmetik + 10 %), Better Auto-Swing (Pass), 2×-Boost 30 Min. (Dev Product). Keine Zufallsitems, keine Fake-Countdowns, Robux-Buttons klar gekennzeichnet, höchstens ein dezenter Shop-Hinweis pro Session, nie direkt nach Misserfolg. Preise: Owner.

## 5. Ausgeschlossen bis nach Release
Pets/Eggs, Trading, weitere Welten, Events, Season Pass, Quests, Achievements (außer Pillow Index), Kissen-Level, PvP, Clans, Zweitwährung, Lokalisierung außer Englisch.

## 6. Post-Launch-Kandidaten
1.1 Pets & Eggs (gegen Federn) + tägliche Quests · 1.2 Welt 2 · 1.3 erstes Event mit kostenlosen Event-Kissen · 1.4 Achievements.

## 7. Offene Entscheidungen
Spieltitel (Owner) · Preise (Owner) · Servergröße (Empfehlung 12) · Portrait-Modus auf Phones (Empfehlung: nur Landscape im MVP).
