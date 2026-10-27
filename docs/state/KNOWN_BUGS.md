# KNOWN_BUGS (Spiegel offener P0/P1)

Keine offenen P0/P1.

## Behoben
- BUG-003 (P1) Preisschilder an den Zonen-Durchgängen zeigten in die nächste Zone (SurfaceGui `Face = Back`), Spieler sahen Name/Preis nie – gefunden bei Sichtprüfung der Vorhänge, behoben 2026-10-27 (Builder setzen `Front`).
- BUG-001 (P0) Fehl-Kick legitimer Spieler bei Halten + Auto-Swing – behoben 2026-10-27, siehe `docs/ops/postmortems/BUG-001-false-kick.md`.

## Offen (P2/P3)
- BUG-002 (P2, nur DEV-Daten): Einmaliger Federsprung im DEV-Spielstand nach einem Testlauf. Seit Einführung des Restore-Wächters (Runner) in allen Folgeläufen (> 15) nicht wieder aufgetreten → beobachten, schließen nach der Beta.

## Behoben (P3)
- Arm-Schwung unsichtbar (2026-10-27): Ursache war nicht der Standard-Animator, sondern der Gelenktyp – aktuelle Avatare nutzen `AnimationConstraint` statt `Motor6D`, der Code bewegte nur `Motor6D.C0` → Arm bewegte sich gar nicht. Außerdem werden Gelenkänderungen nicht repliziert (Mitspieler sahen nie einen Schwung). Lösung: Schwung jedes Frame additiv auf `Transform` (beide Gelenktypen), jeder Client animiert auch Mitspieler und eigene Auto-Schläge über `SwingFx`. Beleg: Oberarm schwingt 93° bei Auto-Schlägen (Messung im Play-Test).
- Griff je Kissenmodell (2026-10-27): Rotationen je Modell in `Config/Assets`, Unit-Test.
