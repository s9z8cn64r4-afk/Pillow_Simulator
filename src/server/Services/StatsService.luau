--!strict
-- Berechnet Ertrag und Cooldown je Spieler aus Daten + Config (Multiplikator-Stack an einer Stelle).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared.Util.Formulas)
local Pillows = require(Shared.Config.Pillows)
local Zones = require(Shared.Config.Zones)
local Progression = require(Shared.Config.Progression)

local StatsService = {}
local PlayerData

-- Aktuelle Zone je Spieler (ZoneService setzt sie ab M2 anhand der Position)
StatsService.currentZone = {} :: { [Player]: string }

function StatsService:Init(registry)
	PlayerData = registry.PlayerDataService
end

function StatsService:zoneOf(player: Player): string
	return self.currentZone[player] or Zones.start
end

-- Zusätzliche Multiplikatoren (Gamepass, Boosts, Freunde, Gruppe) – ab M3 befüllt
function StatsService:extraMultiplier(_player: Player): number
	return 1
end

function StatsService:feathersPerSwing(player: Player): number
	local data = PlayerData:get(player)
	if not data then
		return 0
	end
	local pillow = Pillows.byId[data.equippedPillow] or Pillows.byId[Pillows.starter]
	local zone = Zones.byId[self:zoneOf(player)] or Zones.byId[Zones.start]
	return Formulas.feathersPerSwing(
		pillow.power,
		data.upgrades.featherPower,
		zone.multiplier,
		data.rebirths,
		Formulas.rankBonus(data.rank),
		self:extraMultiplier(player)
	)
end

function StatsService:cooldown(player: Player): number
	local data = PlayerData:get(player)
	if not data then
		return math.huge
	end
	local pillow = Pillows.byId[data.equippedPillow] or Pillows.byId[Pillows.starter]
	return Formulas.cooldown(data.upgrades.swingSpeed, pillow.speed)
end

function StatsService:canAutoSwing(player: Player): boolean
	local data = PlayerData:get(player)
	return data ~= nil and data.rank >= Progression.swing.autoSwingRank
end

return StatsService
