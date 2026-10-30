# PROJECT_STATE – Pillow Legends (Repo: pillow-simulator)

> Einstiegspunkt für jede KI-Sitzung (Masterprompt K.3/K.4). Wird am Ende jeder Sitzung aktualisiert – nicht duplizieren.
> Spiegel: gleiche Datei im Claude-Projekt (`claude/PROJECT_STATE.md`).

| Feld | Wert |
|---|---|
| Aktuelle Phase | **Phase 3 – Closed Beta (M3) in Arbeit**; Gate M0 + M1 bestanden, **Gate M2 vorläufig bestanden** (2 Restpunkte) |
| Version | 0.3.0-dev (M3 in Arbeit) |
| Sprint-Ziel | Closed Beta starten (wartet auf Owner #5: Beta-Place, Tester, MVP-Scope); danach Auswertung bis Gate M3 |
| Letzte Sitzung | 2026-10-30 (Sitzung 5): Persistenz-Stress 100 Zyklen, Server-Lastmessung (12 Spieler hochgerechnet), Art-Pass Zonen v2 für alle 4 Zonen inkl. generierter Props + Plüsch-Puppen + lebendiger Deko, Spielseiten-Entwurf – 115/115 Tests |
| Repository | github.com/s9z8cn64r4-afk/Pillow_Simulator (`main`, **öffentlich**) – Push funktioniert, CI grün |
| Task-Tracker | Trello „Pillow Simulator \| Studio“ – https://trello.com/b/fAGsLKn7/pillow-simulator-studio |
| Dev-Place | „dev place“, PlaceId 123160785919248, DataStore `PlayerData_DEV` |
| MVP-Scope | `docs/MVP_SCOPE.md` – vorläufig freigegeben (Orchestrator), Owner-Freigabe bis M3 |

## Stand
| Bereich | Status |
|---|---|
| M1 (PS-01–10) | **Done** – Gate M1 `[VERIFIZIERT]`, Protokoll `GATES.md` |
| Tests | **115/115** grün in Studio inkl. Bot-Durchlauf `[VERIFIZIERT]`; CI (StyLua/Selene/Economy-Sim) grün `[VERIFIZIERT]` |
| Repo ↔ Studio | 0 Abweichungen (87 Skripte, Commit e3a01a4) `[VERIFIZIERT]`; danach 3 Skripte per Sync eingespielt (1942a0a: Ladebildschirm „PILLOW LEGENDS“, Preise, Social) – **Studio-Stand nicht gespeichert** |
| PS-30 Daily / PS-35 Analytics / PS-31 Codes / PS-32 Leaderboards | `[VERIFIZIERT]` (Tests + Klick/Screenshots); Codes-Liste `[ENTWURF]` bis Owner-Freigabe |
| PS-33 Freunde-/Gruppen-Bonus | Logik + HUD `[VERIFIZIERT]` (Tests, Badge-Screenshot); echte Freunde `[IMPLEMENTIERT, UNGETESTET]` (Mehrspielertest); Gruppen-Bonus aus (Owner: keine Gruppe) |
| PS-34 Monetarisierung | Testgerüst `[VERIFIZIERT]` (7 Tests, Shop „Extras“ zeigt SOON); Preise festgelegt (149/99/79/25 R$, Config); echte Käufe `[BLOCKIERT]` (Owner: Pässe/Produkte anlegen + IDs, #4) |
| PS-39 Persistenz | Stresstest `[VERIFIZIERT]` (4 Tests + 100 Zyklen mit Prüfsummen, echter DataStore); Übernahme zwischen zwei Servern nur live prüfbar |
| PS-40 Mobile | alle Fenster auf Phone mit Touch-Skalierung `[VERIFIZIERT]` (Fehler gefunden + behoben); echtes Gerät in Beta |
| PS-41 Tester-Programm | Sitzungsberichte + `beta_report.luau` `[VERIFIZIERT]`; Tester-Anleitung + Beta-Plan `[ENTWURF]`; Start `[BLOCKIERT]` (Owner #5) |
| PS-36 Logging-Relay | Worker + RelayService `[VERIFIZIERT]` (Tests + Schnittstellentest); live `[BLOCKIERT]` (Owner #6) |
| Server-Last | 12 Spieler hochgerechnet (40 Schläge/s): Heartbeat 59,9 FPS `[VERIFIZIERT]` (Studio, `DevBench`); echte 12-Spieler-Messung in der Beta |
| Sicherheit | Exploit-Suite v2 über echte Remotes `[VERIFIZIERT]` (37 Angriffe, 13 Remotes, Kick bei 200) |
| Pre-Launch-Marketing | Plan, Posts, Short-Skripte, Spielseite (`store-page.md`) `[ENTWURF]` (`docs/marketing/`, Posten durch Owner; Name Pillow Legends eingesetzt) |
| PS-38 Community-Discord | Setup-Skript + Action + Texte + Moderationsleitfaden `[VERIFIZIERT]` (simuliert); Discord-Vorlage (Doc, manueller Weg) `[ENTWURF]` https://claude.ai/artifact/Pwr6S9dsnFVXB9QyKmZfB5; live `[BLOCKIERT]` (Owner #7) |
| PS-42 Gate M3 | Vorbereitung in `GATES.md`; Exit-Kriterien brauchen Beta-Daten |
| PS-37 Feedback | `[VERIFIZIERT]` (4 Tests + echter Klick mit TextService-Filter, Ablage DataStore `Feedback_DEV`); Relay → PS-36 |
| PS-12 Zonen 2–4 | Logik + Graybox `[VERIFIZIERT]` (Tests); Map-Ausbau → PS-16 |
| PS-14 Rebirth | `[VERIFIZIERT]` (Test + Menü) |
| PS-15 Ranks | Titel, Banner + Konfetti, Trail ab Rank 5 `[VERIFIZIERT]` (Tests + Screenshot); Mehrspieler-Sichtbarkeit `[IMPLEMENTIERT, UNGETESTET]` |
| PS-19/20 Settings + Index | `[VERIFIZIERT]` per Klick + Server-Roundtrip |
| PS-11 Kissenmodelle | 14/14 Modelle + Aura/Trail `[VERIFIZIERT]` (Lineup + gehalten); Griff-Feinjustierung P3 |
| PS-18 Tutorial | 6 Schritte + Skip + Boost `[VERIFIZIERT]` (8 Integrationstests, Desktop/Phone-Screenshots); echter Erstspieler-Durchlauf steht aus |
| PS-43 Art-Pass Zonen v2 | alle 4 Zonen: Wände 44 hoch, Tapete je Zone, Leisten, Lichterketten/Wandleuchten, bekletterbarer Riesen-Kissenberg, Extras (Schrank + Bilder, Wimpel, Kronleuchter, Mond + Sterne) – `tools/studio/build_zones_v2.luau` `[VERIFIZIERT]` (Screenshots vorher/nachher, 115/115, Client 60 FPS); **nur im Place → Studio speichern** |
| PS-16 Map | alle 4 Zonen dekoriert (`tools/studio/build_zone_decor.luau`, 362 Dekor-Teile), Vorhang-Durchgänge mit lesbarem Preisschild (BUG-003 behoben), Licht-Profile je Zone (`LightingController`) `[VERIFIZIERT]` (Freischalten + Zonenwechsel im Play-Test) |
| PS-22/23 | Bot bis Rebirth 3 + Performance `[VERIFIZIERT]`; PS-21 Mehrspielertest: automatischer Check `[IMPLEMENTIERT, UNGETESTET]` – Owner startet Test mit 2 Spielern (#3) |
| Musik, Ladebildschirm, Tooltips, Gamepad | `[VERIFIZIERT]` (Musik spielt, Screenshots, simulierte Gamepad-Eingaben) |

## Nächste konkrete Aktion
Siehe `NEXT_ACTIONS.md`.

## Wichtige Hinweise für die nächste Sitzung
- **Code nach Studio:** nach Push `python3 tools/scripts/studio_sync.py OUT drift.txt --github <SHA>` → `OUT/sync_helper.luau` per `execute_luau` (Edit) ausführen (nutzt `ServerStorage.DevTools.SyncFromGitHub`; fehlt der Helfer, `sync_github.luau` nehmen); Studio lädt per HttpService von raw.githubusercontent.com (geht nur, solange das Repo öffentlich ist). Danach Drift-Check (`studio_hash.luau` + `source_hash.py`).
- **Studio-DevTools** (`ServerStorage.DevTools`, nicht im Repo-Mapping, nur im Place): `SyncFromGitHub(sha, list)`, `RunToolScript(sha, "tools/…")` (führt Builder vom Commit aus), `ImportPillows`.
- **CI formatiert selbst:** Push auf `main` → StyLua-Auto-Fix-Commit möglich → vor dem nächsten Push `git pull --rebase`, vor dem Studio-Sync den neuesten SHA nehmen. Generierte Config ist per `.styluaignore` ausgenommen.
- Actions-Logs nicht abrufbar → Fehler über Check-Run-Annotations (`gh api repos/.../check-runs/<id>/annotations`).
- Studio-Änderungen (Map, Modelle, Vendor) existieren nur im Place → Owner muss speichern (Owner-Anfrage #2).
- Skripte mit Punkt im Namen nicht über `multi_edit` ansprechen; `require` aus `execute_luau` = eigene Modulinstanz; Studio-Aufrufe nie > 50 s blockieren.
- GUI-Klicks: `user_mouse_input` mit Mittelpunkt aus `AbsolutePosition + AbsoluteSize/2`.

## Offene Owner-Entscheidungen / -Aktionen
Anleitung für alle Schritte: https://claude.ai/artifact/2CQ96veHiQ7L7u1KnSxyoF

Mehrspielertest (#3) · **Studio speichern (Art-Pass v2!)** · Owner richtet Discord/Relay/Pässe mit mir im Browser ein (angemeldet sein: Discord, GitHub, Roblox, Cloudflare) · Hörprobe Sounds + Musik · Codes freigeben · Pässe/Produkt anlegen + IDs (#4) · Beta-Place + Tester (#5) · Log-Discord + Relay-Deploy (#6) · Community-Discord per Action (#7, Owner hat GitHub-Weg gewählt) · MVP-Freigabe (Owner prüft) · Werbebudget (Standard 0 €) · Repo öffentlich lassen? (Hinweis: ursprünglich „privat“ angefragt; enthält keine Geheimnisse)

## Aktive Blocker
Keine.
