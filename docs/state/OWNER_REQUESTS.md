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
1. **Mehrspielertest (~3 Min., jetzt automatisch)**: In Studio oben „Test“ → bei „Clients and Servers“ **2** Spieler wählen → „Start“. Es öffnen sich 3 Fenster (Server + 2 Spieler). **Nichts eintippen** – nach ca. 20 s läuft der Check von selbst (Attribut `RunMultiplayerCheck` am Server-Skript ist gesetzt). Ergebnis: im Server-Fenster `[MP] SUMMARY …`, in den Spieler-Fenstern `[MP-CLIENT] PASS/FAIL …`. Schreib mir „läuft“ und lass die Fenster offen – ich lese die Ausgabe dann selbst, sonst schick mir die Zeilen mit `[MP`.
   Geprüft wird: getrennte Spielstände, Kissen in der Hand und Rang-Titel beim anderen Spieler sichtbar, Schlag-Effekte kommen beim Mitspieler an, Rang-Hinweis an Mitspieler, Freunde-Bonus, Leaderboard, Sitzungsberichte.
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

## #6 (2026-10-27) – offen, vor der Closed Beta empfohlen
**Fehler-/Feedback-Meldungen in einen privaten Discord (PS-36)** – Relay ist fertig und getestet, braucht nur noch dein Konto (~15 Min.). Schritt für Schritt: `relay/README.md`.
1. Privaten Discord-Server „Pillow Logs“ mit 5 Kanälen + je einem Webhook anlegen.
2. Kostenloses Cloudflare-Konto, Worker mit `npx wrangler deploy` hochladen, Token und Webhook-URLs als Secrets eintragen.
3. In Roblox „Allow HTTP Requests“ einschalten und die Secrets `relay_url` + `relay_token` anlegen.
Hinweis: Webhook-URLs und Token **nicht** an mich schicken – nur dort eintragen.
