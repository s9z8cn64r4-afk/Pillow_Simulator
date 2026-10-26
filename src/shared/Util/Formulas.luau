--!strict
-- Reine Spielformeln. MUSS identisch zu tools/economy-sim/sim.py sein (Paritätstest Formulas.spec).
local Config = script.Parent.Parent.Config
local Progression = require(Config.Progression)

local Formulas = {}

-- Kosten der nächsten Upgrade-Stufe (level = aktuelle Stufe)
function Formulas.upgradeCost(kind: string, level: number): number
	local u = (Progression.upgrades :: any)[kind]
	assert(u, "unbekanntes Upgrade: " .. tostring(kind))
	return math.floor(u.baseCost * u.growth ^ level)
end

function Formulas.rebirthCost(rebirths: number): number
	local rb = Progression.rebirth
	return math.floor(rb.baseCost * rb.costGrowth ^ rebirths)
end

function Formulas.rebirthMultiplier(rebirths: number): number
	local rb = Progression.rebirth
	if rebirths <= rb.softcapAfter then
		return 1 + rb.bonusPerRebirth * rebirths
	end
	return 1 + rb.bonusPerRebirth * rb.softcapAfter + rb.bonusAfterSoftcap * (rebirths - rb.softcapAfter)
end

-- Rank (1-basiert) aus lebenslangen Federn
function Formulas.rankIndex(lifetimeFeathers: number): number
	local idx = 1
	for i, r in Progression.ranks do
		if lifetimeFeathers >= r.lifetimeFeathers then
			idx = i
		end
	end
	return idx
end

function Formulas.rankBonus(rank: number): number
	local r = Progression.ranks[rank]
	return if r then r.bonus else 0
end

-- Sekunden zwischen zwei Schlägen
function Formulas.cooldown(speedLevel: number, pillowSpeed: number): number
	local s = Progression.swing
	local cd = (s.baseCooldown - Progression.upgrades.swingSpeed.cooldownPerLevel * speedLevel) * pillowSpeed
	return math.max(s.minCooldown, cd)
end

-- Federn pro Schlag (bewusst ohne Abrunden, siehe docs/design/economy.md)
function Formulas.feathersPerSwing(
	pillowPower: number,
	featherPowerLevel: number,
	zoneMultiplier: number,
	rebirths: number,
	rankBonus: number,
	extraMultiplier: number
): number
	return pillowPower
		* (1 + Progression.upgrades.featherPower.bonusPerLevel * featherPowerLevel)
		* zoneMultiplier
		* Formulas.rebirthMultiplier(rebirths)
		* (1 + rankBonus)
		* extraMultiplier
end

return Formulas
