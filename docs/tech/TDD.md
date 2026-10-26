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
| `ZoneService` | Zonen-Volumen, aktuelle Zone je Spieler, Freischaltung, Barrieren (P2) |
| `RebirthService`, `RankService` | P2 |
| `RewardService`, `CodeService`, `LeaderboardService`, `SocialService`, `PurchaseService`, `AnalyticsService`, `AntiCheatService` | P2–P3 |

**Client** (`StarterPlayerScripts.Client`): `init.client.luau` lädt `Controllers/`.
`PlayerStateController` (hält replizierten Zustand, Signal `Changed`), `SwingController` (Eingabe → Remote, lokales Sofort-Feedback), `FxController` (Partikel, Zahlen, Sounds), `UI/` (HUD, Menüs).

## 3. Datenmodell
`Shared/Types/PlayerData.luau` (Schema-Version 1) – Felder wie Masterprompt E.9, plus `feathers` als Kommazahl. Migrationen `Migrations.luau`: Liste von Funktionen `[n] = (data) -> data` für n → n+1; Test pro Migration.
DataStore-Name: `PlayerData_<ENV>`, ENV aus Attribut `Environment` am `ServerScriptService` (DEV/STG/PROD; Studio = DEV).

## 4. Netzwerk
Schema-Einträge: `name`, `kind` (`event`/`unreliable`), `dir` (`c2s`/`s2c`), `args` (Validierer-Liste), `rate` (Tokens/s, Burst).
Client → Server (P1): `SwingRequest()`, `BuyPillow(id)`, `EquipPillow(id)`, `BuyUpgrade(kind)`, `SetAutoSwing(on)`.
Server → Client: `StateInit(snapshot)`, `StateDelta(changes)`, `SwingFx(userId, amount, hitDummy)` (unreliable), `Notify(kind, payload)`.
Keine RemoteFunctions. Anfragen werden über `Notify("purchaseResult", …)` beantwortet.

## 5. Schlag-Ablauf
1. Client: Eingabe → sofortiges lokales Animations-Feedback → `SwingRequest`.
2. Server: Rate-Limit → Zustand geladen? → `now - lastSwing >= cooldown - tolerance` sonst verwerfen (Zähler) → Puppe in Reichweite (Position Server-seitig) → Ertrag = `Formulas.feathersPerSwing(...)` → `PlayerData.addFeathers` → `SwingFx` an Spieler in der Nähe.
3. Auto-Swing: Server-Heartbeat-Schleife pro Spieler mit gemeinsamem Cooldown (füllt Lücken zwischen aktiven Schlägen), 80 % Effizienz, nur wenn Rank ≥ 2 und aktiviert. AFK-Grenze: Robloxs Standard-Idle-Kick (20 Min.); eigene AFK-Logik erst bei Bedarf (Leaderboard-Fairness, M3).

## 6. Persistenz
ProfileStore (Vendor, `ServerStorage.Vendor.ProfileStore`, ADR-0002). Join → `StartSessionAsync` (Abbruch bei Leave) → `Reconcile` → Migration → `StateInit`. Leave → `EndSession`. `BindToClose` wartet auf Abschluss. Käufe: `ProcessReceipt` schreibt ReceiptId in `purchaseHistory` und gibt `PurchaseGranted` erst nach Speicherbestätigung zurück (P3).

## 7. Tests
`ServerStorage.Tests` (nur Dev): `RunTests` lädt alle `*.spec`-Module; Mini-Framework `describe/it/expect` (`TestLib`). Ausführung per `execute_luau` (Edit-Modus für reine Logik) und im Play-Modus für Integrationstests (Server-DataModel). Ausgabe `[TEST] PASS/FAIL name`, Zusammenfassung `[TEST] SUMMARY x/y`.
Paritätstest: Testvektoren aus `sim.py` müssen in `Formulas.spec` identische Ergebnisse liefern.

## 8. Sicherheit (Kurz)
Validierung aller Argumente gegen Config-IDs, NaN/Inf-Prüfung, String-Längen. Rate-Limits: Swing 12/s Burst 15 (Cooldown-Prüfung zusätzlich), Käufe 5/s. Verstöße → `AntiCheatService` (loggen → ignorieren → bei Massen-Spam kicken; keine automatischen Bans).

## 9. Performance
StreamingEnabled an; Federpartikel clientseitig mit Pooling; `SwingFx` unreliable und nur an Spieler im Umkreis 80 Studs; Zustand nur als Delta.
