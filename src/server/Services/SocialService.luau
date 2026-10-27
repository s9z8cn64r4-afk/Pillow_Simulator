--!strict
-- Freunde-/Gruppen-Bonus (PS-33). Zählt Freunde im selben Server (max. Social.maxFriends) und prüft die
-- Gruppenmitgliedschaft. Ergebnis als Attribute am Spieler (FriendsInServer, GroupMember) und als
-- Multiplikator für StatsService:extraMultiplier. Web-Aufrufe (IsFriendsWith/IsInGroup) laufen in pcall
-- und werden je Spielerpaar gecacht; Fehler zählen als „kein Freund“.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Social = require(ReplicatedStorage:WaitForChild("Shared").Config.Social)

local SocialService = {}
local Log

local friendCache: { [string]: boolean } = {}
local state: { [Player]: { friends: number, group: boolean } } = {}

-- austauschbar für Tests
SocialService.friendCheck = function(a: Player, b: Player): boolean
	return a:IsFriendsWith(b.UserId)
end
SocialService.groupCheck = function(p: Player, groupId: number): boolean
	return p:IsInGroup(groupId)
end

local function pairKey(a: number, b: number): string
	return if a < b then a .. ":" .. b else b .. ":" .. a
end

function SocialService:Init(registry)
	Log = registry.LogService
end

-- reine Berechnung (auch in Unit-Tests nutzbar)
function SocialService.multiplierFor(friends: number, inGroup: boolean): number
	local f = math.clamp(friends, 0, Social.maxFriends)
	return (1 + Social.friendBonusPer * f) * (if inGroup then 1 + Social.groupBonus else 1)
end

function SocialService:multiplier(player: Player): number
	local s = state[player]
	return if s then SocialService.multiplierFor(s.friends, s.group) else 1
end

function SocialService:apply(player: Player, friends: number, inGroup: boolean)
	local f = math.clamp(friends, 0, Social.maxFriends)
	state[player] = { friends = f, group = inGroup }
	player:SetAttribute("FriendsInServer", f)
	player:SetAttribute("GroupMember", inGroup)
end

local function isFriends(a: Player, b: Player): boolean
	local key = pairKey(a.UserId, b.UserId)
	local cached = friendCache[key]
	if cached ~= nil then
		return cached
	end
	local ok, res = pcall(SocialService.friendCheck, a, b)
	if not ok then
		Log:warn("IsFriendsWith fehlgeschlagen", { err = tostring(res) })
		return false -- nicht cachen, nächster Versuch beim nächsten Join/Leave
	end
	friendCache[key] = res == true
	return res == true
end

function SocialService:recompute(player: Player)
	if player.Parent ~= Players then
		return
	end
	local friends = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and isFriends(player, other) then
			friends += 1
		end
	end
	local inGroup = state[player] and state[player].group or false
	self:apply(player, friends, inGroup)
end

function SocialService:recomputeAll()
	for _, p in Players:GetPlayers() do
		task.spawn(self.recompute, self, p)
	end
end

local function checkGroup(player: Player): boolean
	if Social.groupId <= 0 then
		return false
	end
	local ok, res = pcall(SocialService.groupCheck, player, Social.groupId)
	if not ok then
		Log:warn("IsInGroup fehlgeschlagen", { err = tostring(res) })
		return false
	end
	return res == true
end

local function onAdded(self, player: Player)
	state[player] = { friends = 0, group = checkGroup(player) }
	self:recomputeAll()
end

function SocialService:Start()
	Players.PlayerAdded:Connect(function(p)
		onAdded(self, p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(onAdded, self, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		state[p] = nil
		task.defer(function()
			self:recomputeAll()
		end)
	end)
end

return SocialService
