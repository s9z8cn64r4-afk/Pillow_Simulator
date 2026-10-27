--!strict
-- Leaderboards (PS-32): Top 10 nach lebenslangen Federn und Rebirths (OrderedDataStore, je Umgebung getrennt).
-- Alle 60 s: eigene Werte schreiben, Top-Listen lesen, Tafeln im Kinderzimmer aktualisieren.
-- Tafeln werden zur Laufzeit erzeugt (kein Place-Stand nötig). DataStore-Fehler werden geloggt, nie geworfen.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared.Util.NumberFormat)

local INTERVAL = 60
local TOP = 10
local MAX_VALUE = 2 ^ 53

local LeaderboardService = {}
LeaderboardService.BOARDS = table.freeze({
	{ id = "feathers", title = "🕊️ TOP FEATHERS", field = "lifetimeFeathers", z = 4 },
	{ id = "rebirths", title = "🔄 TOP REBIRTHS", field = "rebirths", z = 30 },
})

local PlayerData, Log
local stores: { [string]: OrderedDataStore } = {}
local nameCache: { [number]: string } = {}
local surfaces: { [string]: Frame } = {}

function LeaderboardService:Init(registry)
	PlayerData = registry.PlayerDataService
	Log = registry.LogService
	local env = PlayerData.environment()
	for _, b in self.BOARDS do
		stores[b.id] = DataStoreService:GetOrderedDataStore("LB_" .. b.id .. "_" .. env)
	end
end

local function valueOf(data: any, field: string): number
	return math.clamp(math.floor(tonumber(data[field]) or 0), 0, MAX_VALUE)
end

-- Werte eines Spielers schreiben (Rückgabe: Anzahl erfolgreicher Schreibvorgänge)
function LeaderboardService:submit(player: Player): number
	local data = PlayerData:get(player)
	if not data then
		return 0
	end
	local okCount = 0
	for _, b in self.BOARDS do
		local ok, err = pcall(function()
			stores[b.id]:SetAsync(tostring(player.UserId), valueOf(data, b.field))
		end)
		if ok then
			okCount += 1
		else
			Log:warn("Leaderboard schreiben fehlgeschlagen", { board = b.id, err = tostring(err) })
		end
	end
	return okCount
end

local function displayName(userId: number): string
	local cached = nameCache[userId]
	if cached then
		return cached
	end
	local p = Players:GetPlayerByUserId(userId)
	local name = p and p.DisplayName
	if not name then
		local ok, n = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		name = if ok then n else ("Player " .. userId)
	end
	nameCache[userId] = name :: string
	return name :: string
end

-- Top-Liste lesen: { { userId, name, value } } oder nil bei Fehler
function LeaderboardService:fetch(boardId: string): { any }?
	local ok, pages = pcall(function()
		return stores[boardId]:GetSortedAsync(false, TOP)
	end)
	if not ok then
		Log:warn("Leaderboard lesen fehlgeschlagen", { board = boardId, err = tostring(pages) })
		return nil
	end
	local out = {}
	for _, entry in (pages :: any):GetCurrentPage() do
		local userId = tonumber(entry.key) or 0
		table.insert(out, { userId = userId, name = displayName(userId), value = entry.value })
	end
	return out
end

-- Tafel an der linken Wand des Kinderzimmers (zeigt nach +X in den Raum)
local function buildBoard(b: any): Frame
	local folder = workspace:FindFirstChild("Leaderboards") or Instance.new("Folder")
	folder.Name = "Leaderboards"
	folder.Parent = workspace
	local old = folder:FindFirstChild(b.id)
	if old then
		old:Destroy()
	end
	local part = Instance.new("Part")
	part.Name = b.id
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Size = Vector3.new(0.6, 15, 22)
	part.Position = Vector3.new(-68.5, 9.5, b.z)
	part.Color = Color3.fromRGB(43, 35, 80)
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = folder
	local frame = Instance.new("Part")
	frame.Name = "Frame"
	frame.Anchored = true
	frame.CanCollide = false
	frame.CanQuery = false
	frame.Size = Vector3.new(0.4, 15.8, 22.8)
	frame.Position = part.Position - Vector3.new(0.2, 0, 0)
	frame.Color = Color3.fromRGB(214, 170, 120)
	frame.Material = Enum.Material.Wood
	frame.Parent = folder
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Right
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.LightInfluence = 0
	sg.Parent = part
	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = sg
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.13, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 226, 122)
	title.Text = b.title
	title.Parent = root
	for i = 1, TOP do
		local row = Instance.new("TextLabel")
		row.Name = "Row" .. i
		row.Position = UDim2.new(0.05, 0, 0.15 + (i - 1) * 0.084, 0)
		row.Size = UDim2.new(0.9, 0, 0.078, 0)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = if i <= 3 then Color3.fromRGB(255, 246, 236) else Color3.fromRGB(196, 186, 240)
		row.Text = ""
		row.Parent = root
	end
	return root
end

function LeaderboardService:render(boardId: string, list: { any })
	local root = surfaces[boardId]
	if not root then
		return
	end
	for i = 1, TOP do
		local row = root:FindFirstChild("Row" .. i) :: TextLabel?
		local e = list[i]
		if row then
			row.Text = if e then ("%d. %s  –  %s"):format(i, e.name, NumberFormat.short(e.value)) else ""
		end
	end
end

function LeaderboardService:refresh()
	for _, p in Players:GetPlayers() do
		self:submit(p)
	end
	for _, b in self.BOARDS do
		local list = self:fetch(b.id)
		if list then
			self:render(b.id, list)
		end
	end
end

function LeaderboardService:Start()
	for _, b in self.BOARDS do
		surfaces[b.id] = buildBoard(b)
	end
	Players.PlayerRemoving:Connect(function(player)
		self:submit(player)
	end)
	task.spawn(function()
		task.wait(5) -- erste Profile laden lassen
		while true do
			self:refresh()
			task.wait(INTERVAL)
		end
	end)
end

return LeaderboardService
