# UI-Design-System v1

Code-Wahrheit: `src/client/UI/Theme.luau`. Stil: weich, verspielt, Bonbonfarben, hoher Kontrast, große Touch-Ziele.

## Farben
| Token | Wert | Verwendung |
|---|---|---|
| `bg` | #2B2350 (Nachtblau-Violett) | Panels |
| `bgSoft` | #3A3170 | Karten, Listen |
| `surface` | #FFF6EC (Kissen-Creme) | helle Flächen, Text auf Dunkel |
| `primary` | #FF8FB1 (Bonbon-Rosa) | Hauptaktionen |
| `secondary` | #7FD8FF (Himmelblau) | Nebenaktionen |
| `success` | #7EE08A | Kauf ok |
| `danger` | #FF6B6B | Abbrechen/Warnung |
| `robux` | #00B06F + Robux-Symbol | ausschließlich Echtgeld-Käufe |
| `feather` | #FFE27A | Federanzeige |
| `stroke` | #1A1433 | Text-/Rand-Kontur |
| Seltenheiten | Common #BEC4CC ● · Uncommon #78D68C ◆ · Rare #5AAAFF ★ · Epic #BE78FF ❖ · Legendary #FFC43C 👑 | immer Farbe **und** Symbol |

## Typografie
`FredokaOne` (Überschriften, Zahlen), `GothamSSm`/`BuilderSans` (Fließtext). Größen: 14 / 18 / 24 / 32 / 48 (Zähler). Text immer mit 2-px-Kontur `stroke`.

## Raster & Formen
4-px-Raster, Abstände 8/12/16/24. Eckradius 12 (Buttons), 18 (Panels). Panel-Stroke 3 px.

## Komponenten
Button (Primary/Secondary/Danger/Robux; Hover +4 % Größe, Press-Squash 0,92, Disabled 50 %), Panel (Ein-/Ausblenden 0,18 s Back-Out), Toast-Stapel (oben Mitte), ProgressBar, Counter (rollend 0,35 s), Tooltip, Modal.

## Layout
Federanzeige oben links · Rank-Fortschritt oben Mitte · Menüknöpfe links vertikal (Shop, Kissen, Rebirth, Settings) · Schlag-Taste unten rechts (Mobile, 120 px) · Auto-Swing-Schalter darüber · Nächstes-Ziel-Karte unten Mitte. `UIScale` nach kurzer Bildschirmseite (Referenz 390 px Höhe Phone Landscape).

## Bewegung
Standard 0,18–0,35 s, `Back`/`Quad` Out. Reduced Motion: Dauer ×0,3, keine Skalierungs-Pops, keine Kamera-Effekte.
