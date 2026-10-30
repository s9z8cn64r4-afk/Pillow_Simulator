# Spielseite „Pillow Legends“ (Creator Dashboard → Experience → Places/Experience-Details)

> Status `[ENTWURF]` · Eintragen macht der Owner (Experience-Name ändern + Text einfügen). Alle Aussagen entsprechen Stand 0.3.0-dev – nur zeigen, was im Spiel ist.

## Titel
**Pillow Legends** (optional mit Kurzzusatz für die Suche: „Pillow Legends 🛏️ Pillow Fight Simulator“ – Roblox erlaubt Emojis, aber keine irreführenden Zusätze wie „UPDATE“/„FREE“ ohne Grund)

## Beschreibung (Englisch, zum Kopieren)
```
Swing pillows, collect feathers and become a Pillow Legend! 🛏️

🪶 Swing at training dummies to earn feathers – every hit bursts with fluff
🛏️ 14 pillows from Worn-Out to the legendary Dreamweaver
🏰 4 cozy zones: Bedroom → Pajama Party Lounge → Grand Hotel Suite → Cloud Kingdom
🔄 Rebirth for a permanent feather boost
🏅 10 ranks with titles, daily rewards and leaderboards
👫 Play with friends: +10% feathers for every friend in your server (up to +30%)

⚖️ Fair by design: everything can be unlocked without Robux. No random paid items.

Found a bug or have an idea? Use the 💬 Feedback button in the settings!
```

## Genre / Einstellungen
- Genre: Simulation · Untergenre (Discovery-Tags): Simulator, Idle/Clicker (Owner wählt im Dashboard)
- Fragebogen Inhaltsreife (Maturity): kein Gewalt-/Blut-Inhalt außer cartoonhaftem Kissenschlagen → erwartbar „Minimal“; Fragebogen ehrlich ausfüllen (Owner)
- Geräte: Computer, Phone, Tablet (Konsole erst nach Gamepad-Test auf echter Konsole)

## Fotomodus in Studio (fertig, für die Aufnahmen)
1. Studio-Fenster maximieren (je größer, desto schärfer die Bilder), oben **Test → Play**.
2. Warten, bis das Spiel geladen ist, dann **P** drücken → Szene 1 (Icon). Die Anzeige verschwindet, die Figur schwingt das Kissen in Schleife, Federn fliegen.
3. Screenshot machen (Windows: **Win + Shift + S**, Mac: **Cmd + Shift + 4**). Fürs Icon einen quadratischen Ausschnitt um Figur + Kissen wählen.
4. **N** = nächste Szene (2 Kinderzimmer · 3 Lounge · 4 Hotel · 5 Wolkenreich), **B** = zurück, **P** = Fotomodus beenden.
Der Fotomodus gibt es nur in Studio, verändert keinen Spielstand und zeigt nur echte Spielinhalte (`src/client/Dev/PhotoMode.luau`).

## Icon (512 × 512) und Thumbnails (1920 × 1080)
Roblox-Regel: Bilder müssen das Spiel korrekt zeigen. Aufnahme im Play-Test, Studio-Fenster maximiert, UI aus (Einstellungen → UI-Größe klein oder Screenshot vor dem Öffnen von Menüs).
| Bild | Motiv | Vorbereitung |
|---|---|---|
| Icon | Nahaufnahme: Avatar mit Dreamweaver-Kissen (Aura), Federburst, Kissenberg im Hintergrund | Spielstand mit Dreamweaver im Dev-Place (kann ich setzen) |
| Thumbnail 1 | Kinderzimmer, Avatar schlägt Puppe, Federn fliegen, Lichterketten | Standard-Spielstand |
| Thumbnail 2 | Pillow Index / Lineup aller 14 Kissen | `tools/studio/pillow_lineup.luau` |
| Thumbnail 3 | Hotel-Suite mit Kronleuchter, Rang-Titel über dem Kopf | Spielstand mit Zone 3 |
| Thumbnail 4 | Wolkenreich mit Mond und Sternen | Spielstand mit Zone 4 |
Vorschau der Zonen (Studio, ohne Avatar): Vorher/Nachher-Bild aus dem Art-Pass v2 (Sitzung 5).
