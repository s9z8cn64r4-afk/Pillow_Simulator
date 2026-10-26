--!strict
-- Ranks: Titel über dem Kopf (für alle sichtbar) und Rank-Up-Ankündigung an Mitspieler.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Config.Progression)

local TAG_NAME = "RankTag"

local RankService = {}
local Net, PlayerData

function RankService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
end

function RankService:applyTag(player: Player)
	local data = PlayerData:get(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not data or not head then
		return
	end
	local bb = head:FindFirstChild(TAG_NAME) :: BillboardGui?
	if not bb then
		local b = Instance.new("BillboardGui")
		b.Name = TAG_NAME
		b.Size = UDim2.fromOffset(200, 40)
		b.StudsOffset = Vector3.new(0, 2.6, 0)
		b.MaxDistance = 80
		b.LightInfluence = 0
		local label = Instance.new("TextLabel")
		label.Name = "Title"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextStrokeTransparency = 0.1
		label.TextStrokeColor3 = Color3.fromRGB(26, 20, 51)
		label.Parent = b
		b.Parent = head
		bb = b
	end
	local rank = Progression.ranks[data.rank]
	local label = (bb :: BillboardGui):FindFirstChild("Title") :: TextLabel
	label.Text = rank.name
	-- Farbe steigt mit dem Rang: Creme → Himmelblau → Gold
	local t = (data.rank - 1) / (#Progression.ranks - 1)
	label.TextColor3 = Color3.fromRGB(255, 246, 236):Lerp(Color3.fromRGB(255, 196, 60), t)
end

function RankService:Start()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 5)
			self:applyTag(player)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	PlayerData.Loaded:Connect(function(player)
		self:applyTag(player)
	end)
	PlayerData.RankChanged:Connect(function(player, newRank: number, oldRank: number)
		self:applyTag(player)
		if newRank > oldRank then
			for _, other in Players:GetPlayers() do
				if other ~= player then
					Net:fire("Notify", other, "otherRankUp", { name = player.DisplayName, rank = Progression.ranks[newRank].name })
				end
			end
		end
	end)
end

return RankService
