--!strict
-- Pseudonym für Spieler in Berichten und Logs (Datenschutz, Masterprompt I.4): stabil, 16 Hex-Zeichen,
-- ohne Wörterbuch nicht auf die UserId zurückzuführen. Reicht zum Zählen eindeutiger Spieler.
local Pseudonym = {}

function Pseudonym.of(userId: number): string
	local s = "ps-beta:" .. tostring(userId)
	local h1, h2 = 5381, 52711
	for i = 1, #s do
		local b = string.byte(s, i)
		h1 = (h1 * 33 + b) % 4294967296
		h2 = (h2 * 31 + b * 7) % 4294967296
	end
	return string.format("%08x%08x", h1, h2)
end

return Pseudonym
