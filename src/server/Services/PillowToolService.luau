--!strict
-- Gibt jedem Spieler sein ausgerüstetes Kissen als Tool in die Hand (M1: Platzhalter-Modell).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pillows = require(Shared.Config.Pillows)

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

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(2.4, 0.9, 1.7)
	handle.Color = rarityColor[pillow.rarity] or Color3.new(1, 1, 1)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.Massless = true
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(1, 1, 1)
	mesh.Parent = handle
	if pillow.id == Pillows.starter then
		-- abgenutzt: matter, leicht gräulich
		handle.Color = Color3.fromRGB(176, 168, 150)
	end
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
