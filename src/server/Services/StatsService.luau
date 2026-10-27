--!strict
-- Berechnet Ertrag und Cooldown je Spieler aus Daten + Config (Multiplikator-Stack an einer Stelle).
local Players = game:GetService("Players")
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

-- Zeitlich begrenzte Boosts (nicht gespeichert): Tutorial-Belohnung, ab M3 Dev Products
local boosts: { [Player]: { mult: number, endsAt: number } } = {}

-- Setzt/verlängert einen Boost; Client sieht ihn über Attribute (BoostMult, BoostEndsAt in Serverzeit)
function StatsService:addBoost(player: Player, mult: number, seconds: number)
	local endsAt = workspace:GetServerTimeNow() + seconds
	boosts[player] = { mult = mult, endsAt = endsAt }
	player:SetAttribute("BoostMult", mult)
	player:SetAttribute("BoostEndsAt", endsAt)
end

function StatsService:clearBoost(player: Player)
	boosts[player] = nil
	player:SetAttribute("BoostMult", nil)
	player:SetAttribute("BoostEndsAt", nil)
end

-- Zusätzliche Multiplikatoren (Gamepass, Boosts, Freunde, Gruppe) – Gamepass/Freunde ab M3
function StatsService:extraMultiplier(player: Player): number
	local b = boosts[player]
	if b then
		if workspace:GetServerTimeNow() < b.endsAt then
			return b.mult
		end
		self:clearBoost(player)
	end
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

function StatsService:Start()
	Players.PlayerRemoving:Connect(function(player)
		boosts[player] = nil
	end)
end

return StatsService
