# KNOWN_BUGS (Spiegel offener P0/P1)

Keine offenen P0/P1.

## Behoben
- BUG-003 (P1) Preisschilder an den Zonen-Durchgängen zeigten in die nächste Zone (SurfaceGui `Face = Back`), Spieler sahen Name/Preis nie – gefunden bei Sichtprüfung der Vorhänge, behoben 2026-10-27 (Builder setzen `Front`).
- BUG-001 (P0) Fehl-Kick legitimer Spieler bei Halten + Auto-Swing – behoben 2026-10-27, siehe `docs/ops/postmortems/BUG-001-false-kick.md`.

## Offen (P2/P3)
- BUG-002 (P2, nur DEV-Daten): Nach einem Testlauf stand der DEV-Spielstand einmalig bei 4,8 M statt ~27 K Federn. In drei Folgeläufen nicht reproduzierbar. Restore-Code der Specs korrekt; Gegenmaßnahme: Restore-Wächter im Runner (Spec schlägt fehl, wenn Federn nach der Spec abweichen). Integrations-Tests laufen nur in Studio/DEV.
- P3: Schwung-Animation des Arms wird teilweise vom Standard-Animator überdeckt (Arm-Tween kaum sichtbar). Lösung in M2 mit echter Animation.
- P3: Griff je Kissenmodell nicht einzeln justiert – aufrecht generierte Modelle (dünne Z-Achse, z. B. Dream/Satin/Thunder) zeigen ihre Vorderseite seitlich. Lösung: optionales Attribut `GripRotation` je Modell.
