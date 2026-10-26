--!strict
-- Rebirth: Federn, Upgrades und Zonen 2–4 zurücksetzen, Kissen und Rank behalten, dauerhafter Multiplikator.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared.Util.Formulas)
local Zones = require(Shared.Config.Zones)

local RebirthService = {}
local Net, PlayerData, ZoneSvc, Log
local busy: { [Player]: boolean } = {}

function RebirthService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	ZoneSvc = registry.ZoneService
	Log = registry.LogService
end

-- Gibt (true) oder (false, Grund) zurück. Läuft vollständig synchron (kein Yield zwischen Prüfung und Reset).
function RebirthService:rebirth(player: Player): (boolean, string?)
	if busy[player] then
		return false, "busy"
	end
	local data = PlayerData:get(player)
	if not data then
		return false, "invalid"
	end
	local cost = Formulas.rebirthCost(data.rebirths)
	if data.feathers < cost then
		return false, "notEnough"
	end
	busy[player] = true
	data.feathers = 0
	data.upgrades = { featherPower = 0, swingSpeed = 0 }
	data.unlockedZones = { [Zones.start] = true }
	data.rebirths += 1
	PlayerData:markChanged(player, "feathers", "upgrades", "unlockedZones", "rebirths")
	busy[player] = nil
	Log:info("Rebirth", { userId = player.UserId, rebirths = data.rebirths })
	Net:fire("Notify", player, "rebirth", {
		rebirths = data.rebirths,
		multiplier = Formulas.rebirthMultiplier(data.rebirths),
	})
	-- zurück in die Startzone
	task.defer(function()
		ZoneSvc:teleport(player, Zones.start)
	end)
	return true, nil
end

function RebirthService:Start()
	Net:on("Rebirth", function(player)
		local ok, why = self:rebirth(player)
		if not ok then
			Net:fire("Notify", player, "purchaseResult", { ok = false, kind = "rebirth", id = "rebirth", reason = why })
		end
	end)
end

return RebirthService
