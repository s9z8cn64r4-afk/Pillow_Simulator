--!strict
-- Daily Reward (GDD 4.8): 7-Tage-Kette, eine Abholung pro UTC-Tag, Lücke pausiert statt zurückzusetzen.
-- Federn-Belohnungen in „Minuten aktueller Produktion“ (skaliert mit dem Fortschritt), Boosts über StatsService.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Rewards = require(Shared.Config.Rewards)
local Daily = require(Shared.Util.Daily)

local DailyRewardService = {}
local Net, PlayerData, Stats, Log

function DailyRewardService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
end

-- Federn für „minutes“ Minuten aktiver Produktion beim aktuellen Stand (ohne temporäre Boosts)
function DailyRewardService:productionFeathers(player: Player, minutes: number): number
	local perSwing = Stats:feathersPerSwing(player) / math.max(Stats:extraMultiplier(player), 1)
	local swingsPerMinute = 60 / Stats:cooldown(player)
	return math.max(1, math.floor(perSwing * swingsPerMinute * minutes))
end

-- Gibt (true, Belohnungsinfo) oder (false, Grund) zurück. nowUnix nur für Tests überschreibbar.
function DailyRewardService:claim(player: Player, nowUnix: number?): (boolean, any)
	local data = PlayerData:get(player)
	if not data then
		return false, "invalid"
	end
	local now = nowUnix or os.time()
	local dr = data.dailyReward
	if not Daily.canClaim(dr.lastClaimUnix, now) then
		return false, "alreadyClaimed"
	end
	local day = Daily.nextDay(dr.streakDay)
	local def = Rewards.daily[day]
	local info: any = { day = day, kind = def.kind }
	if def.kind == "feathersMinutes" then
		local amount = self:productionFeathers(player, def.amount)
		PlayerData:addFeathers(player, amount, "daily")
		info.amount = amount
	elseif def.kind == "boost" then
		Stats:addBoost(player, def.boost, def.minutes * 60)
		info.boost = def.boost
		info.minutes = def.minutes
	end
	dr.streakDay = day
	dr.lastClaimUnix = now
	PlayerData:markChanged(player, "dailyReward")
	Log:info("Daily abgeholt", { userId = player.UserId, day = day })
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "DailyRewardClaimed", day)
	end)
	return true, info
end

function DailyRewardService:Start()
	Net:on("ClaimDaily", function(player)
		local ok, info = self:claim(player)
		Net:fire("Notify", player, "dailyResult", { ok = ok, info = if ok then info else nil, reason = if ok then nil else info })
	end)
end

return DailyRewardService
