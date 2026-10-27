--!strict
-- Codes (PS-31): einmal je Spieler, Ablaufdatum, Belohnung wie Daily Reward. Liste in Config/Codes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Codes = require(Shared.Config.Codes)

local CodeService = {}
local Net, PlayerData, Stats, Log, Daily

function CodeService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
	Daily = registry.DailyRewardService
end

-- Gibt (true, Info) oder (false, Grund) zurück. Gründe: invalid, unknown, expired, used
function CodeService:redeem(player: Player, text: string, nowUnix: number?): (boolean, any)
	local data = PlayerData:get(player)
	if not data or type(text) ~= "string" then
		return false, "invalid"
	end
	local key = string.upper((string.gsub(text, "%s", "")))
	local def = Codes[key]
	if not def then
		return false, "unknown"
	end
	if def.expiresUnix and (nowUnix or os.time()) >= def.expiresUnix then
		return false, "expired"
	end
	if data.redeemedCodes[key] then
		return false, "used"
	end
	data.redeemedCodes[key] = true -- zuerst markieren (kein Doppel-Einlösen bei Fehlern danach)
	local r = def.reward
	local info: any = { code = key, kind = r.kind }
	if r.kind == "feathersMinutes" then
		local amount = Daily:productionFeathers(player, r.amount or 0)
		PlayerData:addFeathers(player, amount, "code")
		info.amount = amount
	elseif r.kind == "boost" then
		Stats:addBoost(player, r.boost or "", (r.minutes or 0) * 60)
		info.minutes = r.minutes
	end
	Log:info("Code eingelöst", { userId = player.UserId, code = key })
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "CodeRedeemed", 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = key })
	end)
	return true, info
end

function CodeService:Start()
	Net:on("RedeemCode", function(player, text: string)
		local ok, info = self:redeem(player, text)
		Net:fire(
			"Notify",
			player,
			"codeResult",
			{ ok = ok, info = if ok then info else nil, reason = if ok then nil else info }
		)
	end)
end

return CodeService
