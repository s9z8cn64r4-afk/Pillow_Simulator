--!strict
-- Berechnet Ertrag und Cooldown je Spieler aus Daten + Config (Multiplikator-Stack an einer Stelle).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared.Util.Formulas)
local Pillows = require(Shared.Config.Pillows)
local Zones = require(Shared.Config.Zones)
local Progression = require(Shared.Config.Progression)
local Rewards = require(Shared.Config.Rewards)

local StatsService = {}
local PlayerData, Social, Monetization

-- Aktuelle Zone je Spieler (ZoneService setzt sie ab M2 anhand der Position)
StatsService.currentZone = {} :: { [Player]: string }

function StatsService:Init(registry)
	PlayerData = registry.PlayerDataService
	Social = registry.SocialService
	Monetization = registry.MonetizationService
end

function StatsService:zoneOf(player: Player): string
	return self.currentZone[player] or Zones.start
end

-- Zeitlich begrenzte Boosts (Config Rewards.boosts), gespeichert als Ablaufzeit (Unix) in data.activeBoosts:
-- laufen in Echtzeit ab, überstehen Rejoins, stapeln bis maxStackMinutes. Client sieht den stärksten aktiven
-- Boost über Attribute (BoostMult, BoostEndsAt in Serverzeit = Unix).
local function now(): number
	return workspace:GetServerTimeNow()
end

function StatsService:refreshBoostAttributes(player: Player)
	local data = PlayerData:get(player)
	local bestMult, bestEnd = nil, nil
	if data then
		for id, endsAt in data.activeBoosts do
			local def = Rewards.boosts[id]
			if def and endsAt > now() and (not bestMult or def.multiplier > bestMult) then
				bestMult, bestEnd = def.multiplier, endsAt
			end
		end
	end
	player:SetAttribute("BoostMult", bestMult)
	player:SetAttribute("BoostEndsAt", bestEnd)
end

-- Fügt Sekunden zu einem Boost hinzu (verlängert einen laufenden). Gibt die neue Ablaufzeit zurück.
-- paid = true (Robux-Kauf): kein Deckel, gekaufte Zeit geht nie verloren.
function StatsService:addBoost(player: Player, boostId: string, seconds: number, paid: boolean?): number?
	local data = PlayerData:get(player)
	local def = Rewards.boosts[boostId]
	if not data or not def or seconds <= 0 then
		return nil
	end
	local t = now()
	local current = math.max(data.activeBoosts[boostId] or 0, t)
	local endsAt = if paid then current + seconds else math.min(current + seconds, t + def.maxStackMinutes * 60)
	data.activeBoosts[boostId] = endsAt
	PlayerData:markChanged(player, "activeBoosts")
	self:refreshBoostAttributes(player)
	return endsAt
end

function StatsService:clearBoost(player: Player)
	local data = PlayerData:get(player)
	if data then
		table.clear(data.activeBoosts)
		PlayerData:markChanged(player, "activeBoosts")
	end
	self:refreshBoostAttributes(player)
end

-- Zusätzliche Multiplikatoren: aktive Boosts und Freunde-/Gruppen-Bonus multiplizieren sich
function StatsService:extraMultiplier(player: Player): number
	local data = PlayerData:get(player)
	if not data then
		return 1
	end
	local m = (if Social then Social:multiplier(player) else 1)
		* (if Monetization then Monetization:passMultiplier(player) else 1)
	local expired = false
	for id, endsAt in data.activeBoosts do
		local def = Rewards.boosts[id]
		if def and endsAt > now() then
			m *= def.multiplier
		else
			expired = true
		end
	end
	if expired then
		for id, endsAt in data.activeBoosts do
			if endsAt <= now() or not Rewards.boosts[id] then
				data.activeBoosts[id] = nil
			end
		end
		PlayerData:markChanged(player, "activeBoosts")
		self:refreshBoostAttributes(player)
	end
	return m
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
	-- gespeicherte Boosts nach dem Laden für die HUD-Anzeige sichtbar machen
	PlayerData.Loaded:Connect(function(player)
		self:refreshBoostAttributes(player)
	end)
end

return StatsService
