# Pillow Simulator

Roblox-Progression-Simulator: Mit einem zerfledderten Kissen Federn herausschlagen, bessere Kissen kaufen, Zonen freischalten, Rebirth.

Entwickelt von **Pillow Studio** (KI-Entwicklungsstudio) nach `docs/AGENTS.md` bzw. dem Masterprompt im Claude-Projekt.

## Einstieg
- Projektzustand: `docs/state/PROJECT_STATE.md`
- Nächste Schritte: `docs/state/NEXT_ACTIONS.md`
- Spieldesign: `docs/design/GDD.md` · Technik: `docs/tech/TDD.md`
- MVP-Umfang: `docs/MVP_SCOPE.md`

## Struktur (Rojo)
| Pfad | Ziel in Roblox |
|---|---|
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |
| `tests` | `ServerStorage.Tests` (nur Dev) |

## Arbeiten mit Rojo (optional, auf dem PC des Owners)
```
rokit install
rojo serve
```
Dann im Studio-Rojo-Plugin „Connect“. Ohne Rojo spielt die KI Skripte direkt über die Studio-Werkzeuge ein; das Repo bleibt die Wahrheit.

## Tests
Tests liegen in `tests/` und laufen in Studio über `tests/RunTests.server.luau` (Ausgabe in der Konsole: `[TEST] PASS/FAIL`).
Economy-Simulation: `python3 tools/economy-sim/sim.py`.
