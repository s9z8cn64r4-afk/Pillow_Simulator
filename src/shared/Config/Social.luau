--!strict
-- Freunde-/Gruppen-Bonus (CR-001, R4). Wirkt als Multiplikator auf Federn pro Schlag.
-- groupId = 0 → Gruppen-Bonus aus (Owner nennt die Gruppe, siehe OWNER_REQUESTS).
return table.freeze({
	friendBonusPer = 0.10, -- +10 % je Freund im Server
	maxFriends = 3, -- max. +30 %
	groupId = 0, -- <<OWNER: Roblox-Gruppen-ID>>
	groupBonus = 0.10, -- +10 % für Gruppenmitglieder
})
