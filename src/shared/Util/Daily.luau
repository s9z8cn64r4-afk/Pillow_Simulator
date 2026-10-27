--!strict
-- Reine Daily-Reward-Logik (ohne Roblox-Dienste, testbar): Tage nach UTC, eine Abholung pro Kalendertag,
-- verpasste Tage pausieren die 7-Tage-Kette (kein Reset, GDD 4.8).
local Daily = {}

Daily.CYCLE = 7

function Daily.dayIndex(unix: number): number
	return math.floor(unix / 86400)
end

-- Abholbar, wenn seit der letzten Abholung ein neuer UTC-Tag begonnen hat (oder noch nie abgeholt)
function Daily.canClaim(lastClaimUnix: number, nowUnix: number): boolean
	return lastClaimUnix <= 0 or Daily.dayIndex(nowUnix) > Daily.dayIndex(lastClaimUnix)
end

-- Nächster Kettentag 1..7 (nach Tag 7 wieder Tag 1)
function Daily.nextDay(streakDay: number): number
	return (streakDay % Daily.CYCLE) + 1
end

-- Sekunden bis zum nächsten UTC-Tageswechsel (für „wieder verfügbar in …“)
function Daily.secondsUntilNext(nowUnix: number): number
	return (Daily.dayIndex(nowUnix) + 1) * 86400 - nowUnix
end

return Daily
