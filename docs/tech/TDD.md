# Technical Design Document v1

> Stand 2026-10-27 · Rolle: Tech Lead · Status: `[ENTWURF]` → Phase-1-Umsetzung läuft.
> Architekturentscheidungen: `docs/decisions/ADR-*.md`. Struktur/Abhängigkeiten: `docs/tech/architecture.md`.

## 1. Grundsätze
Server-authoritativ · alle Werte aus `Shared.Config` · reine Logik in `Shared.Util` (testbar ohne Instanzen) · `--!strict` · Services mit `Init()`/`Start()` · jedes Remote im `Net/Schema` · Speichern nur über `PlayerDataService`.

## 2. Laufzeit-Aufbau
**Server** (`ServerScriptService.Server`): `init.server.luau` lädt alle Module unter `Services/` in fester Reihenfolge, ruft `Init()` dann `Start()`.

| Service | Aufgabe (Phase) |
|---|---|
| `LogService` | Log-Level, Fehler-Fingerprints, Puffer für Relay (P1: Konsole; P3: Relay) |
| `NetService` | erzeugt Remotes aus Schema, Validierung, Token-Bucket-Rate-Limit, Verstoß-Zähler |
| `PlayerDataService` | ProfileStore-Sessions, Template, Migration, Zugriff `get/update`, Replikation `StateDelta` |
| `StatsService` | berechnet Multiplikator-Stack und Cooldown je Spieler (Cache, invalidiert bei Änderungen) |
| `SwingService` | Schlag-Anfragen, Cooldown, Puppen-Treffer, Auto-Swing-Loop, Federn gutschreiben |
| `ShopService` | Kissen/Upgrades kaufen, ausrüsten |
| `ZoneService` | Zonen-Volumen (Tag `ZoneVolume`), aktuelle Zone je Spieler (alle 0,25 s), Freischaltung per ProximityPrompt an der Barriere (Tag `ZoneBarrier`), Teleport zu `ZoneSpawn` |
| `RebirthService` | Rebirth synchron ohne Yield (keine Doppel-Ausführung), Reset + Teleport in Startzone |
| `RankService` | Titel über dem Kopf, Trail ab Rank 5, Rank-Up-Hinweis an Mitspieler |
| `SettingsService` | Einstellungen validieren/runden/speichern (`SetSetting`) |
| `TutorialService` | 6 Onboarding-Aufgaben, ausgewertet über Signale (`SwingService.Swung`, `ShopService.Purchased`, `RankChanged`); `data.tutorial.step` = erledigte Aufgaben; Funnel über `AnalyticsService:LogOnboardingFunnelStepEvent`; Skip (`TutorialSkip`); Profile ab Rank 3 still beendet; Belohnung 2×-Boost 120 s über `StatsService:addBoost` (nicht gespeichert, Attribute `BoostMult`/`BoostEndsAt`) |
| `DailyRewardService` | 7-Tage-Kette (UTC-Tage, Lücke pausiert; Logik in `Util/Daily`), Federn = Minuten Produktion, Boost-Tage über `StatsService:addBoost`; Remote `ClaimDaily` |
| `TelemetryService` | AnalyticsService: Economy-Quellen und Upgrade-Ausgaben je Minute gebündelt, seltene Senken (Kissen/Zone/Rebirth) sofort, Progression (Zonen, Rebirth), Custom (RankUp); Signale `PlayerDataService.FeathersAdded/FeathersSpent` |
| `CodeService` | Codes aus `Config/Codes` (einmal je Spieler, Ablauf), Remote `RedeemCode(codeText)` (alnum ≤ 20, 0,2/s) |
| `SocialService` | Freunde im Server (`IsFriendsWith`, gecacht, pcall) + Gruppe (`Config/Social.groupId`, 0 = aus) → Multiplikator in `StatsService:extraMultiplier`, Attribute `FriendsInServer`/`GroupMember` |
| `MonetizationService` | Gamepässe (`UserOwnsGamePassAsync`, Attribute `Pass_<id>`) → `passMultiplier`, `autoSwingEfficiency`; `ProcessReceipt` idempotent (ReceiptId in `purchaseHistory`, `PurchaseGranted` erst nach `PlayerDataService:saveAndWait`); Artikel ohne Owner-ID/Preis nicht kaufbar; Remote `PromptPurchase(kind, id)` |
| `SessionReportService` | Beim Verlassen ein Sitzungsbericht (Pseudonym statt UserId, Länge, Tutorial, Fortschritt, Serverfehler) in DataStore `Sessions_<ENV>`; Auswertung `tools/studio/beta_report.luau` |
| `FeedbackService` | Remote `SendFeedback(category, text)` (3–300 Zeichen, 1 je 20 s), TextService-Filter, nur gefilterter Text in DataStore `Feedback_<ENV>`, max. 5 je Sitzung |
| `LeaderboardService` | OrderedDataStore `LB_<board>_<ENV>` (lifetimeFeathers, rebirths), alle 60 s schreiben/lesen, Tafeln zur Laufzeit im Kinderzimmer |
| `SocialService`, `PurchaseService`, `AntiCheatService` | M3 |

**Client** (`StarterPlayerScripts.Client`): `init.client.luau` lädt `Controllers/`.
`PlayerStateController` (hält replizierten Zustand, Signal `Changed`), `SwingController` (Eingabe → Remote, lokales Sofort-Feedback), `FxController` (Partikel, Zahlen, Sounds), `UI/` (HUD, Menüs).

## 3. Datenmodell
`Shared/Types/PlayerData.luau` (Schema-Version 1) – Felder wie Masterprompt E.9, plus `feathers` als Kommazahl. Migrationen `Migrations.luau`: Liste von Funktionen `[n] = (data) -> data` für n → n+1; Test pro Migration.
DataStore-Name: `PlayerData_<ENV>`, ENV aus Attribut `Environment` am `ServerScriptService` (DEV/STG/PROD; Studio = DEV).

**Boosts:** `data.activeBoosts[boostId] = Ablaufzeit (Unix)` – laufen in Echtzeit ab, überstehen Rejoins, stapeln bis `Rewards.boosts[id].maxStackMinutes`; `StatsService:extraMultiplier` multipliziert aktive Boosts und räumt abgelaufene auf; HUD liest Attribute `BoostMult`/`BoostEndsAt`.

## 4. Netzwerk
Schema-Einträge: `name`, `kind` (`event`/`unreliable`), `dir` (`c2s`/`s2c`), `args` (Validierer-Liste), `rate` (Tokens/s, Burst).
Client → Server: `SwingRequest()`, `BuyPillow(id)`, `EquipPillow(id)`, `BuyUpgrade(kind)`, `SetAutoSwing(on)`, `TeleportZone(id)`, `Rebirth()`, `SetSetting(key, value)`, `TutorialSkip()`, `ClaimDaily()`, `RedeemCode(text)`, `SendFeedback(category, text)`, `PromptPurchase(kind, id)`.
Server → Client: `StateInit(snapshot)`, `StateDelta(changes)`, `SwingFx(userId, amount, hitDummy)` (unreliable), `Notify(kind, payload)`.
Keine RemoteFunctions. Anfragen werden über `Notify("purchaseResult", …)` beantwortet.

## 5. Schlag-Ablauf
1. Client: Eingabe → sofortiges lokales Animations-Feedback → `SwingRequest`.
2. Server: Rate-Limit → Zustand geladen? → `SwingGate.active` (Cooldown mit Toleranz; Verstoß erst bei anhaltendem Spam, BUG-001) → Puppe in Reichweite (Position Server-seitig) → Ertrag = `Formulas.feathersPerSwing(...)` → `PlayerData.addFeathers` → `SwingFx` an Spieler in der Nähe.
3. Auto-Swing: Server-Heartbeat-Schleife pro Spieler (`SwingGate.auto`), pausiert während aktiver Schläge, 80 % Effizienz, nur wenn Rank ≥ 2 und aktiviert. AFK-Grenze: Robloxs Standard-Idle-Kick (20 Min.); eigene AFK-Logik erst bei Bedarf (Leaderboard-Fairness, M3).

## 6. Persistenz
ProfileStore (Vendor, `ServerStorage.Vendor.ProfileStore`, ADR-0002). Join → `StartSessionAsync` (Abbruch bei Leave) → `Reconcile` → Migration → `StateInit`. Leave → `EndSession`. `BindToClose` wartet auf Abschluss. Käufe: `ProcessReceipt` schreibt ReceiptId in `purchaseHistory` und gibt `PurchaseGranted` erst nach Speicherbestätigung zurück (`saveAndWait`, umgesetzt in PS-34).

## 7. Tests
`ServerStorage.Tests` (nur Dev): `RunTests` lädt alle `*.spec`-Module; Mini-Framework `describe/it/expect` (`TestLib`). Ausführung per `execute_luau` (Edit-Modus für reine Logik) und im Play-Modus für Integrationstests (Server-DataModel). Ausgabe `[TEST] PASS/FAIL name`, Zusammenfassung `[TEST] SUMMARY x/y`.
Paritätstest: Testvektoren aus `sim.py` müssen in `Formulas.spec` identische Ergebnisse liefern.

## 8. Sicherheit (Kurz)
Validierung aller Argumente gegen Config-IDs, NaN/Inf-Prüfung, String-Längen. Rate-Limits: Swing 12/s Burst 15 (Cooldown-Prüfung zusätzlich), Käufe 5/s. Verstöße → `AntiCheatService` (loggen → ignorieren → bei Massen-Spam kicken; keine automatischen Bans).

## 9. Performance
StreamingEnabled an; Federpartikel clientseitig mit Pooling; `SwingFx` unreliable und nur an Spieler im Umkreis 80 Studs; Zustand nur als Delta.
