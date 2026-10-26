# ADR-0003 – UI-Technik

- **Status:** angenommen (2026-10-27), ersetzt Masterprompt-Standard „React-Lua“
- **Kontext:** React-Lua müsste über Wally bezogen werden – Registries sind nicht erreichbar (ADR-0001). Fremdcode ohne Paketmanager zu vendoren ist groß und schwer prüfbar.
- **Entscheidung:** Eigene schlanke Komponentenbibliothek in `src/client/UI/` auf Basis von Roblox-Instanzen: `Theme.luau` (Design-Tokens), `Components/*` (Button, Panel, Toast, ProgressBar, Counter) als Funktionen, die Instanzen erzeugen und ein `update(props)` zurückgeben. Animationen über TweenService mit zentralem `Motion`-Modul (respektiert Reduced Motion).
- **Konsequenzen:** Weniger Abstraktion als React, aber keine Abhängigkeit; Komponenten bleiben klein und testbar. Neubewertung, wenn Wally verfügbar ist (Re-Entscheidung vor Phase 2 möglich).
