--!strict
-- Analytics (PS-35): Roblox-AnalyticsService-Events für Economy, Progression und Rank.
-- Quellen (Schläge, Auto-Swing) werden je Spieler gesammelt und höchstens einmal pro Minute gesendet;
-- Senken (Käufe, Zonen, Rebirth) sofort. Alle Aufrufe in pcall: Analytics darf das Spiel nie stören.
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")

local CURRENCY = "Feathers"
local FLUSH_INTERVAL = 60

local TelemetryService = {}
TelemetryService.log = {} :: { any } -- letzte Events (für Tests/Diagnose, max. 50)

local PlayerData, Log
local pending: { [Player]: { [string]: number } } = {}

-- Quelle → Roblox-Transaktionstyp
-- (Namen von Enum.AnalyticsEconomyTransactionType als String, damit unbekannte Werte nie das Laden brechen)
local SOURCE_TYPE = {
	swing = "Gameplay",
	auto_swing = "Gameplay",
	daily = "TimedReward",
	code = "Gameplay",
}

local function record(e: any)
	table.insert(TelemetryService.log, e)
	if #TelemetryService.log > 50 then
		table.remove(TelemetryService.log, 1)
	end
end

local function balance(player: Player): number
	local data = PlayerData:get(player)
	return if data then math.floor(data.feathers) else 0
end

function TelemetryService:Init(registry)
	PlayerData = registry.PlayerDataService
	Log = registry.LogService
end

-- gesammelte Quellen eines Spielers senden
function TelemetryService:flush(player: Player)
	local p = pending[player]
	if not p then
		return
	end
	pending[player] = nil
	for source, amount in p do
		local amt = math.floor(amount)
		if amt > 0 then
			local tType = SOURCE_TYPE[source] or "Gameplay"
			record({ kind = "economy", flow = "Source", amount = amt, source = source })
			pcall(function()
				AnalyticsService:LogEconomyEvent(
					player,
					Enum.AnalyticsEconomyFlowType.Source,
					CURRENCY,
					amt,
					balance(player),
					tType,
					source
				)
			end)
		end
	end
end

function TelemetryService:onSpent(player: Player, amount: number, sink: string)
	local amt = math.floor(amount)
	if amt <= 0 then
		return
	end
	local category = string.match(sink, "^(%w+)") or sink
	local tType = if category == "rebirth" then "Gameplay" else "Shop"
	record({ kind = "economy", flow = "Sink", amount = amt, sink = sink })
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Sink,
			CURRENCY,
			amt,
			balance(player),
			tType,
			sink
		)
	end)
	-- Progression: Zonen-Freischaltung und Rebirth
	local data = PlayerData:get(player)
	local zoneId = string.match(sink, "^zone:(.+)$")
	if zoneId then
		record({ kind = "progression", path = "Zones", name = zoneId })
		pcall(function()
			AnalyticsService:LogProgressionCompleteEvent(player, "Zones", 1, zoneId)
		end)
	elseif sink == "rebirth" and data then
		local level = data.rebirths + 1 -- Signal kommt vor dem Hochzählen
		record({ kind = "progression", path = "Rebirth", level = level })
		pcall(function()
			AnalyticsService:LogProgressionCompleteEvent(player, "Rebirth", level, "Rebirth " .. level)
		end)
	end
end

function TelemetryService:Start()
	PlayerData.FeathersAdded:Connect(function(player, amount: number, source: string)
		if source == "bot" then
			return -- Testläufe nicht senden
		end
		local p = pending[player]
		if not p then
			p = {}
			pending[player] = p
		end
		p[source] = (p[source] or 0) + amount
	end)
	PlayerData.FeathersSpent:Connect(function(player, amount: number, sink: string)
		self:onSpent(player, amount, sink)
	end)
	PlayerData.RankChanged:Connect(function(player, newRank: number, oldRank: number)
		if newRank > oldRank then
			record({ kind = "custom", name = "RankUp", value = newRank })
			pcall(function()
				AnalyticsService:LogCustomEvent(player, "RankUp", newRank)
			end)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:flush(player)
	end)
	task.spawn(function()
		while true do
			task.wait(FLUSH_INTERVAL)
			for player in pending do
				self:flush(player)
			end
		end
	end)
	Log:debug("TelemetryService bereit")
end

return TelemetryService
