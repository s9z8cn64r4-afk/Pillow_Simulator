--!strict
-- Gibt jedem Spieler sein ausgerüstetes Kissen als Tool in die Hand (generiertes Modell, sonst Platzhalter).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PillowTool = require(Shared.Util.PillowTool)

local TOOL_NAME = PillowTool.TOOL_NAME

local PillowToolService = {}
local PlayerData, Shop

function PillowToolService:Init(registry)
	PlayerData = registry.PlayerDataService
	Shop = registry.ShopService
end

-- Bau des Tools: Shared/Util/PillowTool (auch vom Studio-Fotomodus genutzt)
PillowToolService.buildTool = PillowTool.build
PillowToolService.addRarityFx = PillowTool.addRarityFx

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
