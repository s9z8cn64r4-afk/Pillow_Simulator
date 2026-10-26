# ADR-0005 – Task-Tracker Trello

- **Status:** angenommen (2026-10-27, aktualisiert nach Owner-Freigabe)
- **Kontext:** GitHub Issues/Projects sind aus dieser Umgebung nicht steuerbar; Trello ist verbunden (Masterprompt K.1 Fallback). Erster Versuch scheiterte am Board-Limit; Owner hat Platz geschaffen.
- **Entscheidung:** Board **„Pillow Simulator | Studio“** (https://trello.com/b/fAGsLKn7/pillow-simulator-studio) mit Listen 🔐 Owner-Aktionen · Backlog · Ready (M1) · In Progress · Review / QA · Done · Ideas. Jede Karte trägt den Task Brief (C.11), Milestone und Priorität im Titel (`[M1] PS-01 … (P0)`).
- **Spiegel:** `docs/state/BACKLOG.md` bleibt als Offline-Kopie; Trello ist führend für Status.
- **Konsequenzen:** Commits referenzieren `PS-xx`. M2/M3 liegen als Paketkarten im Backlog und werden bei Milestone-Start zerlegt.
