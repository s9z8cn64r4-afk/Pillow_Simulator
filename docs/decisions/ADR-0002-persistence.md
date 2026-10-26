# ADR-0002 – Persistenz mit ProfileStore

- **Status:** angenommen (2026-10-27)
- **Kontext:** Datenverlust und Item-Duplikation durch gleichzeitige Sessions sind die größten Risiken eines Simulators. Eigene Session-Locking-Logik ist fehleranfällig.
- **Entscheidung:** ProfileStore von loleris (Nachfolger von ProfileService; Session-Locking, MessagingService-Übergabe, Auto-Save 300 s, `Reconcile`).
  - Quelle: Creator-Store-Asset `109379033046155`, eingefügt am 2026-10-27 nach `ServerStorage.Vendor.ProfileStore`.
  - Prüfung: Quelltext (2.242 Zeilen) auf Netzwerk-/Fremdcode-Muster durchsucht – nur `DataStoreService`, `MessagingService`, `RunService`, `HttpService:GenerateGUID` (keine HTTP-Anfragen, kein `require(id)`, kein `loadstring`). `Sandboxed` deaktiviert.
  - Herkunftsnachweis: Quelltext-Hash `1157481565` (Attribut `SourceHash`). Bei Updates neu prüfen.
  - Nicht im Repo gespiegelt (64 KB Fremdcode); Wiederherstellung = Asset erneut einfügen und Hash vergleichen.
- **Alternativen:** ProfileService (veraltet), DataStore2 (kein echtes Session-Locking), Eigenbau (Risiko).
- **Konsequenzen:** Lizenzangabe im Header nicht explizit – vor Release auf GitHub-Repo von MadStudioRoblox prüfen (Risiko R-07).
