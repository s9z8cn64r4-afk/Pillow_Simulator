# OWNER_REQUESTS

## #1 (2026-10-27) – erledigt
1. Dev-Place „Pillow Simulator [DEV]“ privat veröffentlichen + „Studio-Zugriff auf API-Dienste“ aktivieren → löst B-1 ✅
2. Privates GitHub-Repo `pillow-simulator` anlegen, Namen nennen → löst B-2 ✅ (inkl. Claude-GitHub-App)

## Offene Entscheidungen (für MVP-Freigabe gesammelt)
- Endgültiger Spielname
- Freigabe MVP-Scope (`docs/MVP_SCOPE.md`)
- Robux-Preise
- Werbebudget (Standard 0 €)

## #2 (2026-10-27) – offen
1. Studio-Stand speichern: Datei → Auf Roblox speichern (Map, ProfileStore-Vendor, Skripte)

## #3 (2026-10-27) – offen
1. **Mehrspielertest (~5 Min.)**: In Studio oben „Test“ → bei „Clients and Servers“ 2 Spieler wählen → „Start“. In einem Fenster schlagen, im anderen prüfen: Kissen in der Hand sichtbar, Federn fliegen, Rang-Titel über dem Kopf. Rückmeldung „ok“ oder was fehlt.
2. **Hörprobe** der Sounds und der 3 Musiktitel (Einstellungen → Musik/Sound) – passt die Stimmung?
3. **Studio speichern** (Datei → Auf Roblox speichern) – weiterhin wichtig (Kissenmodelle, Map, DevTools nur im Place).
4. **Codes freigeben** (Entwurf in `src/shared/Config/Codes.luau`): PILLOWFIGHT (5 Min. Produktion), FLUFFY (2× für 15 Min.), BETATESTER (10 Min., bis 01.01.2027). Funktionieren bereits im Spiel; öffentlich genannt werden sie erst nach deinem OK.
5. **Roblox-Gruppe** für den Gruppen-Bonus (+10 %): Gruppen-ID nennen oder „keine Gruppe“.

## #4 (2026-10-27) – offen, erst vor Closed Beta nötig
**Monetarisierung (PS-34)** ist technisch fertig und getestet, aber ausgeschaltet (Shop zeigt „SOON“). Zum Einschalten brauche ich von dir:
1. **Preise** (Robux) für: 2x Feathers (Pass, dauerhaft ×2), VIP (Pass, ×1,1 + später Kosmetik), Better Auto-Swing (Pass, Auto-Swing 100 % statt 80 %), 2x Feathers 30 Min. (Produkt, stapelbar). Ich mache keine Preisvorgabe; vergleichbare Simulatoren nutzen grob Pässe im Bereich einiger hundert Robux und Kurz-Boosts im zweistelligen Bereich.
2. **Anlegen** im Creator Hub (Spiel → Monetarisierung → Pässe bzw. Developer Products), danach die **IDs** nennen. Ich trage sie in `tools/economy-sim/content.py` ein, erzeuge die Config neu und teste den Kauf im Dev-Place.
Regeln bleiben: keine Zufallsitems, alle Inhalte ohne Robux erreichbar, Robux-Knöpfe grün markiert, keine Kauf-Pop-ups.

## #5 (2026-10-27) – offen, Start der Closed Beta
1. **Beta-Place** anlegen: Dev-Place kopieren (Datei → Speichern unter / „Place duplizieren“), im neuen Place am **Workspace** das Attribut `Environment` = `BETA` setzen (eigene Spielstände/Berichte, getrennt von meinen Tests) und am Skript `ServerScriptService.Server` das Attribut `RunTestsOnStart` ausschalten.
2. **Tester einladen** (10–30; Weg legst du fest, z. B. Roblox-Gruppe mit Tester-Rolle) und `docs/community/tester-guide.md` weitergeben.
3. Mir den **Beta-Place-Namen/ID** nennen – ich erstelle dann täglich den Bericht (`docs/qa/beta-plan.md`).
4. Vorher noch nötig: **MVP-Scope bestätigen** (`docs/MVP_SCOPE.md`) und **Spielname**.
