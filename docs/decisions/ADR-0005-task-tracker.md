# ADR-0005 – Task-Tracker

- **Status:** angenommen (2026-10-27)
- **Kontext:** GitHub Issues/Projects sind aus dieser Umgebung nicht steuerbar. Trello ist verbunden, aber der Arbeitsbereich ist am Board-Limit (10 Boards) – Board-Anlage scheiterte mit „board limit“.
- **Entscheidung:** Fallback laut Masterprompt K.1: `docs/state/BACKLOG.md` als Markdown-Board (Spalten Backlog · Ready · In Progress · Review · QA · Done · Ideas), Task Briefs nach C.11.
- **Wechsel später:** Sobald der Owner ein Trello-Board freigibt (eins archivieren) oder GitHub Issues nutzbar sind, wird das Backlog dorthin übertragen. Bis dahin ist BACKLOG.md die Wahrheit für Aufgaben.
