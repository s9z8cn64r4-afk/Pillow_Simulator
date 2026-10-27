--!strict
-- Ranks: Titel über dem Kopf (für alle sichtbar) und Rank-Up-Ankündigung an Mitspieler.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Config.Progression)

local TAG_NAME = "RankTag"
local TRAIL_NAME = "RankTrail"
local TRAIL_RANK = 5 -- GDD: Feder-Trail ab Rank 5 (für alle sichtbar)

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
	local color = Color3.fromRGB(255, 246, 236):Lerp(Color3.fromRGB(255, 196, 60), t)
	label.TextColor3 = color
	self:applyTrail(player, data.rank, color)
end

-- Trail ab TRAIL_RANK: zwei Attachments am Root, Farbe wie der Rang-Titel
function RankService:applyTrail(player: Player, rank: number, color: Color3)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local trail = root:FindFirstChild(TRAIL_NAME) :: Trail?
	if rank < TRAIL_RANK then
		for _, n in { TRAIL_NAME, TRAIL_NAME .. "A0", TRAIL_NAME .. "A1" } do
			local inst = root:FindFirstChild(n)
			if inst then
				inst:Destroy()
			end
		end
		return
	end
	if not trail then
		local a0 = Instance.new("Attachment")
		a0.Name = TRAIL_NAME .. "A0"
		a0.Position = Vector3.new(0, 0.8, 0.4)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = TRAIL_NAME .. "A1"
		a1.Position = Vector3.new(0, -0.8, 0.4)
		a1.Parent = root
		local tr = Instance.new("Trail")
		tr.Name = TRAIL_NAME
		tr.Attachment0 = a0
		tr.Attachment1 = a1
		tr.Lifetime = 0.35
		tr.MinLength = 0.2
		tr.LightEmission = 0.3
		tr.Transparency = NumberSequence.new(0.35, 1)
		tr.WidthScale = NumberSequence.new(1, 0.2)
		tr.FaceCamera = true
		tr.Parent = root
		trail = tr
	end
	(trail :: Trail).Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
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
					Net:fire(
						"Notify",
						other,
						"otherRankUp",
						{ name = player.DisplayName, rank = Progression.ranks[newRank].name }
					)
				end
			end
		end
	end)
end

return RankService
