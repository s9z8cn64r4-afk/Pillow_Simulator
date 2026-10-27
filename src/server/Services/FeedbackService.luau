--!strict
-- Feedback-/Bug-Knopf (PS-37). Text wird mit TextService gefiltert; nur der gefilterte Text wird gespeichert
-- (DataStore "Feedback_<ENV>", Schlüssel <unix>_<userId>) und geloggt. Scheitert die Filterung, wird nichts
-- gespeichert. Max. MAX_PER_SESSION Meldungen je Spieler und Server-Sitzung. Ziel später: Relay (PS-36).
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local DataStoreService = game:GetService("DataStoreService")

local FeedbackService = {}
FeedbackService.MAX_PER_SESSION = 5
FeedbackService.recent = {} :: { any } -- letzte Einträge (für Tests/Diagnose), max. 20

local Net, PlayerData, Stats, Log, Relay
local store: DataStore? = nil
local sentCount: { [Player]: number } = {}

-- austauschbar für Tests: gibt gefilterten Text zurück oder wirft
FeedbackService.filter = function(text: string, userId: number): string
	local result = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
	return result:GetNonChatStringForBroadcastAsync()
end
-- austauschbar für Tests
FeedbackService.save = function(key: string, value: any)
	if store then
		store:SetAsync(key, value)
	end
end

function FeedbackService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
	Relay = registry.RelayService
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore("Feedback_" .. PlayerData.environment())
	end)
	store = if ok then s else nil
end

-- Gibt (true, key) oder (false, Grund) zurück. Gründe: invalid, limit, filterFailed, saveFailed
function FeedbackService:submit(player: Player, category: string, text: string): (boolean, string)
	local data = PlayerData:get(player)
	if not data or type(text) ~= "string" then
		return false, "invalid"
	end
	local n = sentCount[player] or 0
	if n >= self.MAX_PER_SESSION then
		return false, "limit"
	end
	local ok, filtered = pcall(self.filter, text, player.UserId)
	if not ok or type(filtered) ~= "string" then
		Log:warn("Feedback-Filter fehlgeschlagen", { userId = player.UserId, err = tostring(filtered) })
		return false, "filterFailed"
	end
	sentCount[player] = n + 1
	local t = os.time()
	local key = ("%d_%d"):format(t, player.UserId)
	local entry = {
		category = category,
		text = filtered,
		unix = t,
		placeVersion = game.PlaceVersion,
		zone = Stats:zoneOf(player),
		rank = data.rank,
		rebirths = data.rebirths,
	}
	local saved = pcall(self.save, key, entry)
	table.insert(self.recent, entry)
	if #self.recent > 20 then
		table.remove(self.recent, 1)
	end
	Log:info("Feedback", { userId = player.UserId, category = category, text = filtered, saved = saved })
	if not saved then
		return false, "saveFailed"
	end
	-- an #feedback-inbox (nur gefilterter Text, Spieler als Pseudonym)
	if Relay then
		Relay:push(
			"feedback",
			filtered,
			{ type = category, rank = data.rank, zone = entry.zone, userId = player.UserId }
		)
	end
	return true, key
end

function FeedbackService:resetCount(player: Player)
	sentCount[player] = nil
end

function FeedbackService:Start()
	Net:on("SendFeedback", function(player, category: string, text: string)
		local ok, why = self:submit(player, category, text)
		Net:fire("Notify", player, "feedbackResult", { ok = ok, reason = if ok then nil else why })
	end)
	Players.PlayerRemoving:Connect(function(p)
		sentCount[p] = nil
	end)
end

return FeedbackService
