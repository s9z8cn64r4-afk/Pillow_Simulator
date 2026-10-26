# Architektur

```
                 ┌───────────── ReplicatedStorage.Shared ─────────────┐
                 │ Config/*  (generiert)   Types/PlayerData   Util/*  │
                 │ Net/Schema  Net/Net (Client- & Server-Wrapper)     │
                 └───────────────▲──────────────────────▲─────────────┘
                                 │ require              │ require
ServerScriptService.Server       │                      │     StarterPlayerScripts.Client
 init.server ─► Services/        │                      │      init.client ─► Controllers/
  LogService ◄─ alle             │                      │       PlayerStateController ◄─ StateInit/StateDelta
  NetService ──► Remotes (ReplicatedStorage.Remotes) ◄──┘       SwingController ─► SwingRequest
  PlayerDataService ─► ServerStorage.Vendor.ProfileStore ─► DataStore PlayerData_<ENV>
  StatsService ◄─ PlayerData, Config, Formulas                  FxController ◄─ SwingFx
  SwingService ─► PlayerData, Stats, Net                        UI/* ◄─ PlayerStateController
  ShopService  ─► PlayerData, Stats, Net
```

## Abhängigkeitsregeln
- `Shared` hängt von nichts ab außer `Shared`.
- Services greifen auf andere Services nur über den Service-Registry-Zugriff in `Init()` zu; keine Zyklen (Bootstrap prüft Ladereihenfolge).
- UI liest Spielzustand ausschließlich aus `PlayerStateController`; Aktionen gehen über `Net`.
- Nur `PlayerDataService` berührt Profile/DataStores.

## Ladereihenfolge Server
`LogService → NetService → PlayerDataService → StatsService → ShopService → SwingService → (ZoneService, RebirthService, RankService, …)`
