# Changelog

Format: Keep a Changelog · Versionierung: SemVer (0.x bis Release).

## [Unreleased] – 0.2.0-dev (M2 Vertical Slice, in Arbeit)
### Added
- Zonen 2–4 (Graybox), Zonen-Erkennung, Freischaltung per ProximityPrompt, Teleport-Menü.
- Rebirth (Doppel-Bestätigung, dauerhafter Multiplikator), Rank-Titel über dem Kopf, Rank-Up-Hinweis an Mitspieler.
- Einstellungen (Musik/SFX in 25-%-Schritten, Reduced Motion, Low Effects, UI-Größe), serverseitig validiert und gespeichert.
- Pillow Index (Sammlung x/14 mit Sperrgrund).
- Alle 14 Kissen als generierte 3D-Modelle; Aura ab Epic, Trail bei Legendary (Low Effects schaltet ab).
- Feier-Banner mit Konfetti für Rank-Up, Rebirth und Epic/Legendary-Kissen; Feder-Trail ab Rank 5.
- Tutorial mit 6 Schritten (serverseitig ausgewertet, überspringbar, Funnel-Events), Belohnung 2×-Federn für 2 Min.; Boost-Anzeige im HUD.
- CI: StyLua-Auto-Fix auf `main`, Selene-Diagnosen als Annotations; Restore-Wächter für Integrations-Tests; `studio_sync.py` (Studio lädt gepinnten Commit).
### Fixed
- BUG-001 (P0): Fehl-Kick legitimer Spieler bei Halten + Auto-Swing (SwingGate).
- CI seit Phase 0 rot (Formatierung, Selene `if_same_then_else`).

## 0.1.0-dev (M1 Prototype) – Gate M1 bestanden 2026-10-27
### Added
- Serverseitige Architektur: Service-Bootstrap, LogService, NetService (Schema, Validierung, Rate-Limits), PlayerDataService (ProfileStore, Migrationen, Delta-Replikation, leaderstats), StatsService, ShopService, SwingService (Cooldown-Prüfung, Puppen-Bonus, Auto-Swing), PillowToolService.
- Client: PlayerStateController, SwingController (Halten = Dauerschlag, prozedurale Animation), FxController (Federburst, „+X“-Zahlen, Puppen-Wackeln), HUD v0 (Federn, Rank-Balken, Shop, Schlag-Taste, Auto-Schalter, Nächstes-Ziel, Toasts).
- Config aus Economy-Simulation generiert (14 Kissen, 4 Zonen, 10 Ranks, Upgrades, Rebirth).
- Graybox-Zone „Cozy Bedroom“ mit 4 Kissenpuppen und Barriere zu Zone 2.
- Studio-Testrunner mit 32 Tests (inkl. Auto-Swing); Drift-Prüfung Repo ↔ Studio.
- Soundeffekte (Schlag, Puppen-Treffer, Kauf, Rank-Up, UI-Klick) mit SFX-SoundGroup.
- 3D-Federburst aus generiertem Federmodell (Pool, max. 60 aktiv, Low-VFX halbiert).
- Generiertes Modell für das Startkissen „Worn-Out Pillow“.
### Changed
- UI: Touch-Geräte mit Mindestskalierung 0,8 (Tippziele ≥ 44 px), größere Tabs/Buttons, Toasts mit dunklem Hintergrund.
- Feder-Symbol 🪶 → 🕊️ (Roblox-Schrift unterstützt 🪶 nicht).
