--!strict
-- Gibt jedem Spieler sein ausgerüstetes Kissen als Tool in die Hand (M1: Platzhalter-Modell).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pillows = require(Shared.Config.Pillows)
local Assets = require(Shared.Config.Assets)

local TOOL_NAME = "Pillow"

local PillowToolService = {}
local PlayerData, Shop

local rarityColor: { [string]: Color3 } = {}
for _, r in Pillows.rarities do
	rarityColor[r.id] = Color3.fromRGB(r.color[1], r.color[2], r.color[3])
end

function PillowToolService:Init(registry)
	PlayerData = registry.PlayerDataService
	Shop = registry.ShopService
end

-- Baut das Kissen-Tool. M2 ersetzt das Platzhalter-Ellipsoid durch generierte Modelle je Kissen.
function PillowToolService.buildTool(pillowId: string): Tool
	local pillow = Pillows.byId[pillowId] or Pillows.byId[Pillows.starter]
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = pillow.name
	tool:SetAttribute("PillowId", pillow.id)
	tool.Grip = CFrame.new(0, -0.2, -1.1) * CFrame.Angles(math.rad(90), 0, 0)

	-- Generiertes Modell, falls vorhanden (ReplicatedStorage.Assets.Pillows.<id>), sonst Platzhalter-Ellipsoid
	local folder = ReplicatedStorage:FindFirstChild("Assets")
	local model = folder and folder:FindFirstChild(Assets.models.pillowsFolder)
	local template = model and model:FindFirstChild(pillow.id)
	local handle: BasePart
	if template and template:IsA("MeshPart") then
		handle = template:Clone()
		handle.Name = "Handle"
		-- Kissen quer vor dem Körper halten: Längsachse (X) quer, Fläche nach vorn
		-- Längsachse X (Standard) wird um 90° gedreht; Modelle mit Längsachse Z (Attribut vom Import) nicht
		local longZ = handle:GetAttribute("LongAxisZ") == true
		tool.Grip = CFrame.new(0, 0, -0.9) * CFrame.Angles(0, if longZ then 0 else math.rad(90), 0)
	else
		local part = Instance.new("Part")
		part.Name = "Handle"
		part.Size = Vector3.new(2.4, 0.9, 1.7)
		part.Color = rarityColor[pillow.rarity] or Color3.new(1, 1, 1)
		part.Material = Enum.Material.Fabric
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = part
		handle = part
	end
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	handle:SetAttribute("BaseSize", handle.Size)
	handle.Parent = tool
	return tool
end

function PillowToolService:give(player: Player)
	local data = PlayerData:get(player)
	local char = player.Character
	if not data or not char then
		return
	end
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, container in { char, backpack } do
		if container then
			for _, t in container:GetChildren() do
				if t:IsA("Tool") and t.Name == TOOL_NAME then
					t:Destroy()
				end
			end
		end
	end
	local tool = self.buildTool(data.equippedPillow)
	tool.Parent = char -- direkt ausgerüstet
end

function PillowToolService:Start()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function()
			task.wait() -- Character vollständig aufbauen lassen
			self:give(player)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	PlayerData.Loaded:Connect(function(player)
		self:give(player)
	end)
	Shop.PillowEquipped:Connect(function(player)
		self:give(player)
	end)
end

return PillowToolService
