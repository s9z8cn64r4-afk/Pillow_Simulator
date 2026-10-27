--!strict
-- Käufe gegen Federn: Kissen, Upgrades; Ausrüsten. Alle Prüfungen serverseitig.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pillows = require(Shared.Config.Pillows)
local Progression = require(Shared.Config.Progression)
local Formulas = require(Shared.Util.Formulas)

local ShopService = {}
local Net, PlayerData, Log
ShopService.PillowEquipped = nil :: any
ShopService.Purchased = nil :: any

function ShopService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Log = registry.LogService
	ShopService.PillowEquipped = require(Shared.Util.Signal).new() -- (player, pillowId)
	ShopService.Purchased = require(Shared.Util.Signal).new() -- (player, kind, id)
end

local function result(player: Player, ok: boolean, kind: string, id: string, reason: string?)
	Net:fire("Notify", player, "purchaseResult", { ok = ok, kind = kind, id = id, reason = reason })
end

-- Gibt (true) oder (false, Grund) zurück
function ShopService:buyPillow(player: Player, id: string): (boolean, string?)
	local data = PlayerData:get(player)
	local pillow = Pillows.byId[id]
	if not data or not pillow then
		return false, "invalid"
	end
	if data.ownedPillows[id] then
		return false, "owned"
	end
	if not data.unlockedZones[pillow.zone] then
		return false, "zoneLocked"
	end
	if data.rebirths < pillow.rebirths then
		return false, "rebirthLocked"
	end
	if not PlayerData:spendFeathers(player, pillow.cost, "pillow:" .. id) then
		return false, "notEnough"
	end
	data.ownedPillows[id] = true
	PlayerData:markChanged(player, "ownedPillows")
	self:equipPillow(player, id)
	Log:info("Kissen gekauft", { userId = player.UserId, pillow = id })
	self.Purchased:Fire(player, "pillow", id)
	return true, nil
end

function ShopService:equipPillow(player: Player, id: string): (boolean, string?)
	local data = PlayerData:get(player)
	if not data or not data.ownedPillows[id] then
		return false, "notOwned"
	end
	data.equippedPillow = id
	PlayerData:markChanged(player, "equippedPillow")
	self.PillowEquipped:Fire(player, id)
	return true, nil
end

function ShopService:buyUpgrade(player: Player, kind: string): (boolean, string?)
	local data = PlayerData:get(player)
	local def = (Progression.upgrades :: any)[kind]
	if not data or not def then
		return false, "invalid"
	end
	local level = data.upgrades[kind]
	if level >= def.maxLevel then
		return false, "maxLevel"
	end
	if not PlayerData:spendFeathers(player, Formulas.upgradeCost(kind, level), "upgrade:" .. kind) then
		return false, "notEnough"
	end
	data.upgrades[kind] = level + 1
	PlayerData:markChanged(player, "upgrades")
	self.Purchased:Fire(player, "upgrade", kind)
	return true, nil
end

function ShopService:Start()
	Net:on("BuyPillow", function(player, id: string)
		local ok, why = self:buyPillow(player, id)
		result(player, ok, "pillow", id, why)
	end)
	Net:on("EquipPillow", function(player, id: string)
		local ok, why = self:equipPillow(player, id)
		result(player, ok, "equip", id, why)
	end)
	Net:on("BuyUpgrade", function(player, kind: string)
		local ok, why = self:buyUpgrade(player, kind)
		result(player, ok, "upgrade", kind, why)
	end)
end

return ShopService
