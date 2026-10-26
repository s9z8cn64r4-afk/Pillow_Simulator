# ADR-0001 – Toolchain und Code-Synchronisation

- **Status:** angenommen (2026-10-27)
- **Kontext:** Masterprompt D.2 sieht Rojo/Rokit/Wally/Lune im CI vor. Capability Probe: Paket-Registries und GitHub-Releases sind aus der Cloud-Umgebung nicht erreichbar; `rojo serve` kann nur auf dem PC des Owners laufen. Roblox-Studio-Werkzeuge (Skripte bearbeiten, Luau ausführen, Play-Tests) sind verfügbar.
- **Entscheidung:**
  1. Git-Repo mit Rojo-Struktur (`default.project.json`) bleibt die einzige Code-Wahrheit.
  2. Übertragung nach Studio durch die KI über die Studio-Werkzeuge nach der Abbildung in `docs/AGENTS.md`. Optional kann der Owner `rojo serve` starten – Ergebnis identisch.
  3. Tests laufen in Studio (eigener Mini-Runner, ADR in TDD §7), nicht in Lune.
  4. Format/Lint (StyLua/Selene) laufen in GitHub Actions, sobald Push möglich ist.
  5. Wally wird im MVP nicht benötigt; externe Module werden als geprüfte Vendor-Kopien geführt.
- **Konsequenzen:** Doppelter Schritt Repo → Studio; Risiko von Abweichungen. Gegenmaßnahme: Abgleich-Prüfung (Studio-Quelltext-Hash je Modul gegen Repo) vor jedem Meilenstein.
