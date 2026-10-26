# Changelog

Format: Keep a Changelog · Versionierung: SemVer (0.x bis Release).

## [Unreleased] – 0.1.0-dev (M1 Prototype)
### Added
- Serverseitige Architektur: Service-Bootstrap, LogService, NetService (Schema, Validierung, Rate-Limits), PlayerDataService (ProfileStore, Migrationen, Delta-Replikation, leaderstats), StatsService, ShopService, SwingService (Cooldown-Prüfung, Puppen-Bonus, Auto-Swing), PillowToolService.
- Client: PlayerStateController, SwingController (Halten = Dauerschlag, prozedurale Animation), FxController (Federburst, „+X“-Zahlen, Puppen-Wackeln), HUD v0 (Federn, Rank-Balken, Shop, Schlag-Taste, Auto-Schalter, Nächstes-Ziel, Toasts).
- Config aus Economy-Simulation generiert (14 Kissen, 4 Zonen, 10 Ranks, Upgrades, Rebirth).
- Graybox-Zone „Cozy Bedroom“ mit 4 Kissenpuppen und Barriere zu Zone 2.
- Studio-Testrunner mit 30 Tests; Drift-Prüfung Repo ↔ Studio.
