# QA-Testplan v1

## Ebenen
1. **Unit (Studio, Edit-Modus):** Formulas (inkl. Paritätsvektoren aus sim.py), BigNumberFormat, Validatoren, RateLimiter, Migrationen, Daily-Reward-Tageslogik.
2. **Integration (Studio, Play-Modus, Server-DataModel):** Join → Laden → Schlagen → Kaufen → Datenstand; Zonenwechsel; Rebirth-Reset; Speichern beim Verlassen.
3. **Exploit-Suite (Play-Modus):** falsche Typen, NaN/inf, riesige Strings/Tabellen, unbekannte IDs, Spam über Rate-Limit, Kauf ohne Federn, gesperrtes Kissen, Schlag schneller als Cooldown. Automatisiert: `tools/studio/exploit_suite.luau` im Client-DataModel ausführen (Play, ohne Testlauf); misst über das Studio-Attribut `NetViolations`. Bei jedem neuen Remote ergänzen.
4. **Bot-Durchlauf (ab M2):** Debug-Multiplikator nur im Dev-Place, Pfad bis Rebirth 3.
5. **Visuell:** Screenshots je Referenzauflösung (Phone Landscape 844×390, Tablet 1024×768, Desktop 1920×1080).
6. **Persistenz-Stress (vor M3):** 100 Join/Leave/Shutdown-Zyklen mit Prüfsummen.

## Ablage
Jeder Lauf → `docs/state/TEST_RESULTS.md` (Datum, Commit, Suite, x/y, Beleg).

## Bug-Priorität
P0 Datenverlust/Exploit/Absturz/Kauf · P1 Kernloop gestört · P2 störend · P3 kosmetisch.
