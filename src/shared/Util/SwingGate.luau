--!strict
-- Reine Taktlogik für Schläge (serverseitig genutzt, offline testbar).
-- Behebt BUG-001: legitime Spieler wurden durch Auto-Swing-Kollisionen und Paket-Bündelung als Spammer gekickt.
--  * Auto-Swing pausiert, solange der Spieler aktiv schlägt.
--  * Zu frühe Anfragen werden nur verworfen; als Verstoß zählt erst anhaltendes Spammen (Strikes mit Abbau).
export type State = { last: number, lastActive: number, strikes: number, strikeAt: number }

local STRIKE_DECAY_PER_SECOND = 1.0 -- Abbau der Strikes
local MAX_STRIKES = 6 -- ab hier gilt es als Spam
local TOO_FAST_FACTOR = 0.5 -- Abstand < 50 % des Cooldowns erzeugt einen Strike

local SwingGate = {}

function SwingGate.new(): State
	return { last = -math.huge, lastActive = -math.huge, strikes = 0, strikeAt = 0 }
end

-- Aktiver Schlag. Rückgabe: (angenommen, alsVerstoßMelden)
function SwingGate.active(s: State, now: number, cooldown: number, tolerance: number): (boolean, boolean)
	s.lastActive = now
	if now - s.last >= cooldown - tolerance then
		s.last = now
		return true, false
	end
	s.strikes = math.max(0, s.strikes - (now - s.strikeAt) * STRIKE_DECAY_PER_SECOND)
	s.strikeAt = now
	if now - s.last < cooldown * TOO_FAST_FACTOR then
		s.strikes += 1
	end
	return false, s.strikes > MAX_STRIKES
end

-- Auto-Swing-Takt. Pausiert, solange in den letzten 1,5 Cooldowns aktiv geschlagen wurde.
function SwingGate.auto(s: State, now: number, cooldown: number): boolean
	if now - s.lastActive < cooldown * 1.5 then
		return false
	end
	if now - s.last >= cooldown then
		s.last = now
		return true
	end
	return false
end

return SwingGate
