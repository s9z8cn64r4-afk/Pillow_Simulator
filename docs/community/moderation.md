# Moderationsleitfaden – Community-Discord (Server A)

Gilt für Owner und Moderatoren. Die Spieler sind überwiegend 9–15 Jahre alt: **Schutz geht vor Reichweite.** Öffentliche Regeln: `tools/discord-setup/texts/rules.md` (Kanal `#rules`).

## Grundsätze für das Team
- **Keine privaten Nachrichten an Spieler**, besonders nicht an Minderjährige. Support nur in Kanälen, Forum-Threads oder Tickets, die andere Teammitglieder sehen.
- **Nie nach persönlichen Daten fragen** (Name, Alter, Schule, Wohnort, Social Media, Passwörter). Gepostete persönliche Daten sofort löschen und freundlich darauf hinweisen.
- **Keine Robux- oder Echtgeld-Gewinnspiele.** Giveaways nur mit Spielinhalten und Codes.
- **Keine Discord-Einladungen im Spiel.** Verlinkung nur über die offiziellen Social Links der Experience.
- Jede Moderationsaktion kurz in `#mod-log` festhalten: Datum, Kanal, Verstoß, Stufe, Pseudonym oder Discord-Name (keine weiteren Daten).

## Eskalationsstufen
| Stufe | Wann | Aktion |
|---|---|---|
| 1 Hinweis | erster leichter Verstoß (falscher Kanal, leichter Spam, Streit) | freundlicher Hinweis im Kanal, Nachricht ggf. löschen |
| 2 Timeout | Wiederholung oder Beleidigung | Timeout 1 Std. – 1 Tag |
| 3 Kick | wiederholte Timeouts, bewusstes Stören | Kick mit kurzer Begründung |
| 4 Bann | Scams, sexuelle Inhalte, Hass, Doxxing, Bedrohung, Umgehen eines Banns | sofortiger Bann (Stufen werden übersprungen) |

## Sonderfälle
- **Scam / „Free Robux“ / Fremd-Einladungen:** AutoMod blockt die bekannten Muster. Durchgerutschte Nachrichten löschen, Konto bannen, Muster in `tools/discord-setup/server-a.json` (AutoMod) ergänzen und Setup erneut laufen lassen.
- **Hinweise auf Gefährdung eines Kindes** (z. B. Grooming-Versuche, Selbstgefährdung): nicht selbst ermitteln, Inhalte nicht weiterverbreiten. Sofort dem Owner melden, Konto sperren und über die Melde-Funktion an Discord (Trust & Safety) bzw. Roblox melden. Bei akuter Gefahr gilt der Notruf.
- **Bug-Meldungen mit Account-Problemen:** Nie Passwörter oder Cookies erfragen; auf den Roblox-Support verweisen, wenn es um das Roblox-Konto selbst geht.
- **Streit um Spielfortschritt:** Daten nur der Owner bzw. die Entwicklung prüfen (Pseudonym aus Bericht), nicht im öffentlichen Kanal.
- **Löschanfragen:** an den Owner weiterleiten; Spielstände sind über die Roblox-UserId verknüpft (ProfileStore `AddUserId`), Löschung über die Roblox-Datenschutzprozesse.

## Automatischer Schutz (vom Setup-Skript angelegt)
| Regel | Wirkung |
|---|---|
| Profanity & slurs | Discord-Wortlisten (Schimpfwörter, sexuelle Inhalte, Beleidigungen) blockiert |
| Spam | von Discord erkannter Spam blockiert |
| Mention spam | mehr als 5 Erwähnungen in einer Nachricht blockiert |
| Foreign invites & scam links | Einladungen zu anderen Servern, „free robux“ & Co. blockiert |

Zusätzlich empfohlen (im Discord unter *Servereinstellungen*, einmalig): **Community-Modus** an, **Onboarding** mit Ping-Rollen (Updates, Events, Codes), **Regelprüfung** (Rules Screening) an, Verifizierungsstufe mindestens „Mittel“.

## Moderatoren auswählen
Nur volljährige, vertrauenswürdige Personen, die der Owner persönlich bestätigt. Rolle `Moderator` vergibt nur der Owner. Bei Austritt Rolle sofort entfernen.
