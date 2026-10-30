--!strict
-- Kissen-Werkzeug (Tool) bauen – gemeinsam für Server (PillowToolService) und Studio-Fotomodus (Client).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pillows = require(Shared.Config.Pillows)
local Assets = require(Shared.Config.Assets)

local PillowTool = {}
PillowTool.TOOL_NAME = "Pillow"

local rarityColor: { [string]: Color3 } = {}
for _, r in Pillows.rarities do
	rarityColor[r.id] = Color3.fromRGB(r.color[1], r.color[2], r.color[3])
end

-- Baut das Kissen-Tool aus ReplicatedStorage.Assets.Pillows.<id> (Fallback: Ellipsoid in Seltenheitsfarbe).
function PillowTool.build(pillowId: string): Tool
	local pillow = Pillows.byId[pillowId] or Pillows.byId[Pillows.starter]
	local tool = Instance.new("Tool")
	tool.Name = PillowTool.TOOL_NAME
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
		-- Feinjustierung je Modell (Grad): Config Assets.models.gripRotation, sonst Attribut GripRotation am Modell
		local rot = Assets.models.gripRotation[pillow.id]
		local attr = handle:GetAttribute("GripRotation")
		local extra = if rot
			then Vector3.new(rot[1], rot[2], rot[3])
			elseif typeof(attr) == "Vector3" then attr
			else nil
		if extra then
			tool.Grip *= CFrame.Angles(math.rad(extra.X), math.rad(extra.Y), math.rad(extra.Z))
		end
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
	PillowTool.addRarityFx(handle, pillow.rarity)
	handle.Parent = tool
	return tool
end

-- Seltenheits-Visuals (GDD): Aura ab Epic, zusätzlich Trail bei Legendary. Dezent, Low Effects
-- schaltet sie clientseitig ab (FxController, Name-Präfix "RarityFx").
function PillowTool.addRarityFx(handle: BasePart, rarity: string)
	if rarity ~= "Epic" and rarity ~= "Legendary" then
		return
	end
	local color = rarityColor[rarity]
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "RarityFxAura"
	aura.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	aura.Color = ColorSequence.new(color)
	aura.LightEmission = 0.6
	aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	aura.Transparency = NumberSequence.new(0.2, 1)
	aura.Lifetime = NumberRange.new(0.6, 1)
	aura.Rate = if rarity == "Legendary" then 14 else 8
	aura.Speed = NumberRange.new(0.5, 1.2)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Parent = handle
	if rarity == "Legendary" then
		local half = handle.Size.X / 2
		local a0 = Instance.new("Attachment")
		a0.Name = "RarityFxA0"
		a0.Position = Vector3.new(-half, 0, 0)
		a0.Parent = handle
		local a1 = Instance.new("Attachment")
		a1.Name = "RarityFxA1"
		a1.Position = Vector3.new(half, 0, 0)
		a1.Parent = handle
		local trail = Instance.new("Trail")
		trail.Name = "RarityFxTrail"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(color, Color3.fromRGB(255, 255, 255))
		trail.Transparency = NumberSequence.new(0.4, 1)
		trail.Lifetime = 0.25
		trail.LightEmission = 0.5
		trail.Parent = handle
	end
end

return PillowTool
