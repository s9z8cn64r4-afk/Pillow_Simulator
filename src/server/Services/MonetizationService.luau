--!strict
-- Monetarisierung (PS-34, Testgerüst). Gamepässe + Developer Products aus Config/Products.
-- Regeln (GDD 4.10, R8): keine Zufallsitems, nichts Wichtiges nur gegen Robux, Preise/IDs vom Owner.
-- assetId/productId = 0 → Artikel nicht verfügbar (Shop zeigt „SOON“, Server lehnt Kauf ab).
-- ProcessReceipt ist idempotent: ReceiptId in purchaseHistory, PurchaseGranted erst nach bestätigter
-- Speicherung; sonst NotProcessedYet (Roblox wiederholt, kein doppeltes Gutschreiben).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local AnalyticsService = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Products = require(Shared.Config.Products)
local Progression = require(Shared.Config.Progression)

local MonetizationService = {}
local Net, PlayerData, Stats, Log

local passById: { [string]: any } = {}
local productById: { [string]: any } = {}
for _, p in Products.gamepasses do
	passById[p.id] = p
end
for _, p in Products.devProducts do
	productById[p.id] = p
end

-- Zuordnung Roblox-ID → Artikel (Tests können zusätzliche Einträge setzen)
MonetizationService.passByAssetId = {} :: { [number]: any }
MonetizationService.productByProductId = {} :: { [number]: any }
for _, p in Products.gamepasses do
	if p.assetId > 0 then
		MonetizationService.passByAssetId[p.assetId] = p
	end
end
for _, p in Products.devProducts do
	if p.productId > 0 then
		MonetizationService.productByProductId[p.productId] = p
	end
end

local owned: { [Player]: { [string]: boolean } } = {}

-- austauschbar für Tests
MonetizationService.ownsCheck = function(player: Player, assetId: number): boolean
	return MarketplaceService:UserOwnsGamePassAsync(player.UserId, assetId)
end
MonetizationService.saveCheck = function(player: Player): boolean
	return PlayerData:saveAndWait(player, 15)
end

function MonetizationService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
end

function MonetizationService:owns(player: Player, passId: string): boolean
	local o = owned[player]
	return o ~= nil and o[passId] == true
end

function MonetizationService:setOwned(player: Player, passId: string, value: boolean)
	owned[player] = owned[player] or {}
	owned[player][passId] = value
	player:SetAttribute("Pass_" .. passId, value)
end

-- Multiplikator aller besessenen Pässe (2x Feathers, VIP)
function MonetizationService:passMultiplier(player: Player): number
	local m = 1
	for id, has in owned[player] or {} do
		local def = passById[id]
		if has and def and def.multiplier then
			m *= def.multiplier
		end
	end
	return m
end

function MonetizationService:autoSwingEfficiency(player: Player): number
	local best = Progression.swing.autoSwingEfficiency
	for id, has in owned[player] or {} do
		local def = passById[id]
		if has and def and def.autoSwingEfficiency then
			best = math.max(best, def.autoSwingEfficiency)
		end
	end
	return best
end

local function refreshOwnership(player: Player)
	for _, p in Products.gamepasses do
		if p.assetId > 0 then
			local ok, has = pcall(MonetizationService.ownsCheck, player, p.assetId)
			if ok then
				MonetizationService:setOwned(player, p.id, has == true)
			else
				Log:warn("UserOwnsGamePassAsync fehlgeschlagen", { pass = p.id, err = tostring(has) })
			end
		end
	end
end

-- Kauf anstoßen. Gibt (true) oder (false, Grund) zurück: notAvailable, owned, boostFull
function MonetizationService:prompt(player: Player, kind: string, id: string): (boolean, string?)
	if kind == "pass" then
		local p = passById[id]
		if not p or p.assetId <= 0 or p.robux == nil then
			return false, "notAvailable"
		end
		if self:owns(player, id) then
			return false, "owned"
		end
		MarketplaceService:PromptGamePassPurchase(player, p.assetId)
		return true
	elseif kind == "product" then
		local p = productById[id]
		if not p or p.productId <= 0 or p.robux == nil then
			return false, "notAvailable"
		end
		MarketplaceService:PromptProductPurchase(player, p.productId)
		return true
	end
	return false, "notAvailable"
end

local function grantProduct(player: Player, product: any)
	if product.boost then
		Stats:addBoost(player, product.boost, (product.minutes or 0) * 60, true)
	end
end

-- Developer-Product-Quittung (auch direkt aus Tests aufrufbar)
function MonetizationService:processReceipt(info: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local product = self.productByProductId[info.ProductId]
	if not player or not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = PlayerData:get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local receiptKey = tostring(info.PurchaseId)
	if not data.purchaseHistory[receiptKey] then
		data.purchaseHistory[receiptKey] = true -- zuerst markieren: Wiederholung schreibt nie doppelt gut
		grantProduct(player, product)
		Log:info(
			"Kauf gutgeschrieben",
			{ userId = player.UserId, product = product.id, receipt = receiptKey }
		)
		pcall(function()
			AnalyticsService:LogCustomEvent(
				player,
				"RobuxPurchase",
				info.CurrencySpent or 0,
				{ [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = product.id }
			)
		end)
		Net:fire("Notify", player, "storeResult", { ok = true, kind = "product", id = product.id })
	end
	if not self.saveCheck(player) then
		Log:warn("Kauf noch nicht gespeichert – Roblox wiederholt", { receipt = receiptKey })
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:Start()
	PlayerData.Loaded:Connect(function(player)
		owned[player] = owned[player] or {}
		task.spawn(refreshOwnership, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, assetId, purchased)
		local p = self.passByAssetId[assetId]
		if purchased and p then
			self:setOwned(player, p.id, true)
			Log:info("Gamepass gekauft", { userId = player.UserId, pass = p.id })
			Net:fire("Notify", player, "storeResult", { ok = true, kind = "pass", id = p.id })
		end
	end)
	MarketplaceService.ProcessReceipt = function(info)
		local ok, decision = pcall(self.processReceipt, self, info)
		if not ok then
			Log:error("ProcessReceipt-Fehler", { err = tostring(decision) })
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return decision
	end
	Net:on("PromptPurchase", function(player, kind: string, id: string)
		local ok, why = self:prompt(player, kind, id)
		if not ok then
			Net:fire("Notify", player, "storeResult", { ok = false, reason = why })
		end
	end)
end

return MonetizationService
