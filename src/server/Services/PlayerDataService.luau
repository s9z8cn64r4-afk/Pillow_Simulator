--!strict
-- Einziger Zugriffspunkt auf Spielerdaten (ProfileStore, ADR-0002). Repliziert Änderungen als Delta.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlayerDataTypes = require(Shared.Types.PlayerData)
local Formulas = require(Shared.Util.Formulas)
local NumberFormat = require(Shared.Util.NumberFormat)
local Signal = require(Shared.Util.Signal)
local Progression = require(Shared.Config.Progression)
local Migrations = require(script.Parent.Parent.Migrations)
local ProfileStore = require(ServerStorage:WaitForChild("Vendor"):WaitForChild("ProfileStore") :: any)

local FLUSH_INTERVAL = 0.1

local PlayerDataService = {}
PlayerDataService.Loaded = Signal.new() -- (player, data)
PlayerDataService.RankChanged = Signal.new() -- (player, newRank, oldRank)
PlayerDataService.FeathersAdded = Signal.new() -- (player, amount, source)
PlayerDataService.FeathersSpent = Signal.new() -- (player, amount, sink)

local profiles: { [Player]: any } = {}
local dirty: { [Player]: { [string]: boolean } } = {}
local Log, Net
local store

-- Umgebung aus Attribut am Workspace (Standard DEV; Production-Place setzt "PROD")
function PlayerDataService.environment(): string
	local env = workspace:GetAttribute("Environment")
	return if type(env) == "string" and env ~= "" then env else "DEV"
end

local function snapshot(data: any): { [string]: any }
	local out = {}
	for k, v in data do
		if not PlayerDataTypes.PRIVATE_KEYS[k] then
			out[k] = v
		end
	end
	return out
end

local function setupLeaderstats(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local f = Instance.new("StringValue")
	f.Name = "Feathers"
	f.Parent = ls
	local r = Instance.new("IntValue")
	r.Name = "Rebirths"
	r.Parent = ls
	ls.Parent = player
end

local function updateLeaderstats(player: Player, data: any)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Feathers.Value = NumberFormat.short(data.feathers);
		(ls :: any).Rebirths.Value = data.rebirths
	end
end

function PlayerDataService:Init(registry)
	Log = registry.LogService
	Net = registry.NetService
	local name = "PlayerData_" .. self.environment()
	store = ProfileStore.New(name, PlayerDataTypes.TEMPLATE)
	Log:info("DataStore", { name = name })
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync("Player_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if profile == nil then
		Log:error("Profil konnte nicht geladen werden", { userId = player.UserId })
		player:Kick("Your data could not be loaded. Please rejoin in a moment.")
		return
	end
	profile:AddUserId(player.UserId) -- für Datenlöschanfragen
	profile:Reconcile()
	profile.Data = Migrations.run(profile.Data)
	if profile.Data.stats.firstJoinUnix == 0 then
		profile.Data.stats.firstJoinUnix = os.time()
	end
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		dirty[player] = nil
		player:Kick("Your session ended in another server. Please rejoin.")
	end)
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end
	profile._joinClock = os.clock()
	profiles[player] = profile
	dirty[player] = {}
	setupLeaderstats(player)
	updateLeaderstats(player, profile.Data)
	Net:fire("StateInit", player, snapshot(profile.Data))
	Log:info("Profil geladen", { userId = player.UserId, feathers = math.floor(profile.Data.feathers) })
	PlayerDataService.Loaded:Fire(player, profile.Data)
end

function PlayerDataService:Start()
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile then
			profile.Data.stats.playtimeSeconds += math.floor(os.clock() - (profile._joinClock or os.clock()))
			profiles[player] = nil
			dirty[player] = nil
			profile:EndSession()
		end
	end)
	-- Deltas gebündelt senden
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < FLUSH_INTERVAL then
			return
		end
		acc = 0
		for player, keys in dirty do
			if next(keys) then
				local profile = profiles[player]
				if profile then
					local delta = {}
					for k in keys do
						delta[k] = profile.Data[k]
					end
					table.clear(keys)
					Net:fire("StateDelta", player, delta)
					updateLeaderstats(player, profile.Data)
				end
			end
		end
	end)
	-- ProfileStore speichert beim Herunterfahren selbst; hier nur warten, bis alle Sessions enden
	game:BindToClose(function()
		local deadline = os.clock() + 25
		while next(profiles) and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

-- ---------- Öffentliche API ----------

function PlayerDataService:isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- Lebende Datentabelle (nur Services dürfen sie verwenden; nach Änderung markChanged aufrufen)
function PlayerDataService:get(player: Player): any
	local profile = profiles[player]
	return profile and profile.Data
end

function PlayerDataService:markChanged(player: Player, ...: string)
	local keys = dirty[player]
	if keys then
		for _, k in { ... } do
			keys[k] = true
		end
	end
end

function PlayerDataService:addFeathers(player: Player, amount: number, source: string?)
	local data = self:get(player)
	if not data or amount ~= amount or amount <= 0 or amount == math.huge then
		return
	end
	data.feathers += amount
	data.lifetimeFeathers += amount
	self:markChanged(player, "feathers", "lifetimeFeathers")
	self.FeathersAdded:Fire(player, amount, source or "other")
	local newRank = Formulas.rankIndex(data.lifetimeFeathers)
	if newRank ~= data.rank then
		local old = data.rank
		data.rank = newRank
		self:markChanged(player, "rank")
		Net:fire("Notify", player, "rankUp", { rank = newRank, name = Progression.ranks[newRank].name })
		self.RankChanged:Fire(player, newRank, old)
	end
end

-- Zieht Federn ab, wenn genug vorhanden. Gibt true bei Erfolg zurück.
-- sink: wofür ausgegeben wurde (Analytics), z. B. "pillow:cotton", "upgrade:featherPower", "zone:livingroom"
function PlayerDataService:spendFeathers(player: Player, amount: number, sink: string?): boolean
	local data = self:get(player)
	if not data or amount ~= amount or amount < 0 then
		return false
	end
	if data.feathers + 1e-9 < amount then
		return false
	end
	data.feathers = math.max(0, data.feathers - amount)
	self:markChanged(player, "feathers")
	self.FeathersSpent:Fire(player, amount, sink or "other")
	return true
end

-- Speichert sofort und wartet auf die Bestätigung (Käufe: PurchaseGranted erst nach Speicherung).
-- Gibt true zurück, wenn innerhalb von timeout Sekunden gespeichert wurde.
function PlayerDataService:saveAndWait(player: Player, timeout: number?): boolean
	local profile = profiles[player]
	if not profile or not profile:IsActive() then
		return false
	end
	local saved = false
	local conn = profile.OnAfterSave:Connect(function()
		saved = true
	end)
	profile:Save()
	local deadline = os.clock() + (timeout or 15)
	while not saved and os.clock() < deadline and profile:IsActive() do
		task.wait(0.1)
	end
	conn:Disconnect()
	return saved
end

-- Nur für Tests in Studio: Zugriff auf den ProfileStore (eigene Test-Schlüssel, nie Spieler-Schlüssel)
function PlayerDataService:_storeForTest(): any
	assert(RunService:IsStudio(), "nur in Studio")
	return store
end

return PlayerDataService
