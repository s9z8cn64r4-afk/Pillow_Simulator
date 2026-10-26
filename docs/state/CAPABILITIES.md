# CAPABILITIES – Ergebnis der Capability Probe

> Stand: 2026-10-27 (Sitzung 1). Bei jeder Sitzung kurz neu prüfen; bei Änderungen hier aktualisieren.

## Geprüfte Fähigkeiten

| Fähigkeit | Ergebnis | Beleg |
|---|---|---|
| Dateisystem & Shell (Cloud-Arbeitsbereich, Linux) | ✅ verfügbar | `git 2.43`, `python3`, `node 22`, `cargo` vorhanden |
| Paket-Registries (npm, PyPI, crates.io) | ❌ nicht erreichbar (DNS-Auflösung schlägt fehl) | `npm view`, `pip index`, `cargo search` → Fehler |
| GitHub-Downloads (Releases, raw) | ❌ Proxy 403 | `raw.githubusercontent.com` → connect_rejected |
| Luau-Toolchain in der Cloud (Rokit, Rojo, Lune, Selene, StyLua) | ❌ nicht installierbar (siehe oben) | – |
| GitHub-Repo | ⚠️ nur fremdes Repo `Gane` sichtbar; `gh`-Token ungültig. Neues Repo muss der Owner anlegen, dann per Repo-Anbindung nutzbar | `list_repos`, `gh auth status` |
| Roblox Studio (über verbundenen PC „jonas“, Windows) | ✅ verbunden: 1 Instanz „Place1“ (unveröffentlicht, PlaceId 0), Studio 0.744 | `list_roblox_studios`, `get_studio_state` |
| Studio-Werkzeuge | ✅ Luau ausführen (Edit/Server/Client), Skripte lesen/bearbeiten, Spielbaum durchsuchen, Play starten/stoppen, Konsole lesen, Screenshots, Asset-Suche/-Einfügen, Mesh/Textur/Material/prozedurale Generierung | Tool-Liste + `execute_luau` erfolgreich |
| Rojo | ⚠️ Plugin 7.7.0 in Studio installiert; `rojo serve` müsste auf dem PC des Owners laufen – aus der Cloud nicht startbar (keine Geräte-Shell) | Spielbaum: `PluginGuiService.Rojo 7.7.0` |
| DataStores in Studio | ❌ derzeit nicht nutzbar: Place unveröffentlicht, „Studio Access to API Services“ nicht aktiv | PlaceId 0 |
| HttpService | aus (`HttpEnabled=false`) – erst für Logging-Relay (Phase 3) nötig | `execute_luau` |
| Open Cloud API-Key | ❌ nicht vorhanden | – |
| Trello | ✅ verbunden (Konto „HolderACC“), Lesen/Schreiben | `trelloReadMember get_me` |
| GitHub Issues/Projects | ❌ nicht verfügbar → Fallback Trello (Masterprompt K.1) | – |
| Claude-Projekt-Dokumente | ✅ lesen/schreiben | Projektdokumente im Kontext |
| Web-Suche / Seitenabruf | ✅ verfügbar | Tool-Liste |
| Bildgenerierung | ⚠️ nur über Studio (generate_texture/store_image); kein separates Bildwerkzeug geprüft | Tool-Liste |
| Blender | ❌ in der Cloud nicht vorhanden; auf dem PC ungeprüft (keine Geräte-Shell) | – |
| Discord / Relay-Hosting | ❌ nicht eingerichtet | – |
| Sub-Agenten | ✅ Agent-Tool vorhanden → Modus P möglich, Standard bleibt Modus S (Kosten) | Tool-Liste |
| Geplante Aufgaben | ✅ Scheduling-Tools vorhanden | Tool-Liste |

## Konsequenzen (Entscheidungen dieser Sitzung)

1. **Code-Wahrheit:** lokales Git-Repo im Cloud-Arbeitsbereich (`pillow-simulator/`), Rojo-Struktur. Übertragung nach Studio über die Studio-Werkzeuge (Skript für Skript). Sobald ein GitHub-Repo angebunden ist, wird gepusht.
2. **Tests:** eigener Luau-Testrunner, der **in Studio** per `execute_luau` läuft (statt Lune im CI). Economy-Simulation in Python.
3. **Persistenz-Tests** erst nach Veröffentlichung des Dev-Place + API-Zugriff; bis dahin speichert der `PlayerDataService` in Studio in einen Speicher-Mock und ist als `[IMPLEMENTIERT, UNGETESTET]` markiert.
4. **Task-Tracker:** Trello (Board „Pillow Simulator“).

## Aufgabenklassifikation

| Aufgabe | Klasse |
|---|---|
| Code schreiben, in Studio einspielen, Play-Tests, Konsole, Screenshots | AUTO |
| Map/Graybox bauen, Assets generieren/einfügen | AUTO |
| Unit-/Integrationstests in Studio | AUTO |
| Dokumentation, Recherche, Economy-Simulation | AUTO |
| Trello-Backlog pflegen | AUTO |
| Dev-Place veröffentlichen, API-Zugriff aktivieren | TEIL (Owner, ~3 Min.) |
| GitHub-Repo anlegen + anbinden | TEIL (Owner, ~3 Min.) |
| Rojo-Live-Sync | TEIL (Owner startet `rojo serve`) – optional |
| Production-Veröffentlichung, Robux-Preise, Werbung | FREIGABE |
| Open-Cloud-Deployment aus CI | N/V (kein Key/CI) → Ersatz: Owner publiziert per Studio nach Checkliste |
| Discord-Server + Relay | N/V bis Phase 3 → später TEIL |
| Blender-Pipeline | N/V → Ersatz: Studio-Generierung + prozedurale Modelle |
