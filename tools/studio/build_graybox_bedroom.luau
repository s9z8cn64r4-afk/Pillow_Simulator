-- Baut die Graybox-Zone „Cozy Bedroom“ (PS-06). In Studio (Edit) per execute_luau ausführen.
-- Idempotent: ersetzt workspace.Map vollständig. Stand 2026-10-27.
local CS = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local old = workspace:FindFirstChild("Map") if old then old:Destroy() end
local bp = workspace:FindFirstChild("Baseplate") if bp then bp:Destroy() end

local map = Instance.new("Folder") map.Name = "Map"
local zones = Instance.new("Folder") zones.Name = "Zones" zones.Parent = map
local bedroom = Instance.new("Model") bedroom.Name = "Bedroom" bedroom.Parent = zones

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do p[k] = v end
	p.Parent = parent
	return p
end
local C = Color3.fromRGB

-- Boden & Wände (Raum 140 x 140, Ausgang Richtung +Z)
part({Name="Floor", Size=Vector3.new(140,2,140), Position=Vector3.new(0,-1,0), Color=C(196,214,240), Material=Enum.Material.Fabric}, bedroom)
part({Name="Rug", Size=Vector3.new(60,0.2,44), Position=Vector3.new(0,0.1,-10), Color=C(255,190,210), Material=Enum.Material.Fabric}, bedroom)
local wallColor = C(170,196,232)
part({Name="WallBack", Size=Vector3.new(140,24,2), Position=Vector3.new(0,12,-70), Color=wallColor, Material=Enum.Material.SmoothPlastic}, bedroom)
part({Name="WallLeft", Size=Vector3.new(2,24,140), Position=Vector3.new(-70,12,0), Color=wallColor, Material=Enum.Material.SmoothPlastic}, bedroom)
part({Name="WallRight", Size=Vector3.new(2,24,140), Position=Vector3.new(70,12,0), Color=wallColor, Material=Enum.Material.SmoothPlastic}, bedroom)
part({Name="WallFrontL", Size=Vector3.new(55,24,2), Position=Vector3.new(-42.5,12,70), Color=wallColor, Material=Enum.Material.SmoothPlastic}, bedroom)
part({Name="WallFrontR", Size=Vector3.new(55,24,2), Position=Vector3.new(42.5,12,70), Color=wallColor, Material=Enum.Material.SmoothPlastic}, bedroom)
part({Name="WallFrontTop", Size=Vector3.new(30,8,2), Position=Vector3.new(0,20,70), Color=wallColor, Material=Enum.Material.SmoothPlastic}, bedroom)

-- Riesenbett (Deko)
local bed = Instance.new("Model") bed.Name = "GiantBed" bed.Parent = bedroom
part({Name="Frame", Size=Vector3.new(44,6,30), Position=Vector3.new(-35,3,-50), Color=C(214,170,120), Material=Enum.Material.Wood}, bed)
part({Name="Mattress", Size=Vector3.new(42,4,28), Position=Vector3.new(-35,8,-50), Color=C(250,250,255), Material=Enum.Material.Fabric}, bed)
part({Name="Blanket", Size=Vector3.new(42,1.2,18), Position=Vector3.new(-35,10.4,-45), Color=C(140,170,255), Material=Enum.Material.Fabric}, bed)
part({Name="Headboard", Size=Vector3.new(44,16,2), Position=Vector3.new(-35,8,-66), Color=C(214,170,120), Material=Enum.Material.Wood}, bed)
local bp1 = part({Name="BigPillow", Size=Vector3.new(16,4,9), Position=Vector3.new(-35,12,-60), Color=C(255,255,255), Material=Enum.Material.Fabric}, bed)
local m = Instance.new("SpecialMesh") m.MeshType = Enum.MeshType.Sphere m.Parent = bp1

-- Spielzeugblöcke & Nachttisch mit Lampe
local toys = Instance.new("Model") toys.Name = "Toys" toys.Parent = bedroom
local toyColors = {C(255,143,177), C(127,216,255), C(126,224,138), C(255,226,122)}
for i = 1, 6 do
	part({Name="Block"..i, Size=Vector3.new(4,4,4), Position=Vector3.new(40 + (i%3)*5, 2 + (i>3 and 4 or 0), -50 + (i%2)*2), Color=toyColors[(i-1)%4+1], Material=Enum.Material.SmoothPlastic, Orientation=Vector3.new(0,i*13,0)}, toys)
end
part({Name="Nightstand", Size=Vector3.new(8,7,8), Position=Vector3.new(-5,3.5,-60), Color=C(214,170,120), Material=Enum.Material.Wood}, bedroom)
local lamp = part({Name="Lamp", Shape=Enum.PartType.Ball, Size=Vector3.new(4,4,4), Position=Vector3.new(-5,9,-60), Color=C(255,236,180), Material=Enum.Material.Neon}, bedroom)
local light = Instance.new("PointLight") light.Range = 40 light.Brightness = 1.2 light.Color = C(255,226,180) light.Parent = lamp

-- Kissenpuppen (Tag PillowDummy, Bonus ×1.5 serverseitig)
local dummies = Instance.new("Folder") dummies.Name = "Dummies" dummies.Parent = bedroom
local spots = {Vector3.new(-20,0,10), Vector3.new(20,0,10), Vector3.new(-20,0,-20), Vector3.new(20,0,-20)}
for i, pos in spots do
	local d = Instance.new("Model") d.Name = "Dummy"..i
	local stand = part({Name="Stand", Shape=Enum.PartType.Cylinder, Size=Vector3.new(1,2,2), Position=pos+Vector3.new(0,0.5,0), Orientation=Vector3.new(0,0,90), Color=C(214,170,120), Material=Enum.Material.Wood}, d)
	local pole = part({Name="Pole", Size=Vector3.new(0.6,4,0.6), Position=pos+Vector3.new(0,3,0), Color=C(180,140,100), Material=Enum.Material.Wood}, d)
	local body = part({Name="Body", Size=Vector3.new(4,6,4), Position=pos+Vector3.new(0,7,0), Color=C(255,214,225), Material=Enum.Material.Fabric}, d)
	local bm = Instance.new("SpecialMesh") bm.MeshType = Enum.MeshType.Sphere bm.Parent = body
	local head = part({Name="Head", Shape=Enum.PartType.Ball, Size=Vector3.new(3,3,3), Position=pos+Vector3.new(0,11,0), Color=C(255,236,240), Material=Enum.Material.Fabric}, d)
	for _, p in {stand, pole, body, head} do p.CanCollide = (p ~= head) end
	d.PrimaryPart = body
	local bb = Instance.new("BillboardGui") bb.Size = UDim2.fromOffset(140, 36) bb.StudsOffset = Vector3.new(0, 4, 0) bb.MaxDistance = 60 bb.Parent = head
	local t = Instance.new("TextLabel") t.Size = UDim2.fromScale(1,1) t.BackgroundTransparency = 1 t.Font = Enum.Font.FredokaOne t.TextScaled = true
	t.Text = "Training Dummy ×1.5" t.TextColor3 = C(255,226,122) t.TextStrokeTransparency = 0.2 t.Parent = bb
	CS:AddTag(d, "PillowDummy")
	d.Parent = dummies
end

-- Barriere zu Zone 2
local barrier = part({Name="Barrier_livingroom", Size=Vector3.new(30,16,1), Position=Vector3.new(0,8,70), Color=C(255,143,177), Material=Enum.Material.ForceField, Transparency=0.3}, bedroom)
barrier:SetAttribute("ZoneId", "livingroom")
CS:AddTag(barrier, "ZoneBarrier")
local sg = Instance.new("SurfaceGui") sg.Face = Enum.NormalId.Front sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 20 sg.Parent = barrier
local lbl = Instance.new("TextLabel") lbl.Size = UDim2.fromScale(1,1) lbl.BackgroundTransparency = 1 lbl.Font = Enum.Font.FredokaOne lbl.TextScaled = true
lbl.Text = "🔒 Pajama Party Lounge\n🕊️ 75K" lbl.TextColor3 = C(255,246,236) lbl.TextStrokeTransparency = 0 lbl.Parent = sg

-- Zonen-Volumen (unsichtbar, für ZoneService ab M2)
local vol = part({Name="ZoneVolume_bedroom", Size=Vector3.new(138,40,138), Position=Vector3.new(0,20,0), Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false}, map)
vol:SetAttribute("ZoneId", "bedroom")
CS:AddTag(vol, "ZoneVolume")

-- Spawn
local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
if spawnLoc then
	spawnLoc.Position = Vector3.new(0, 0.5, 30) spawnLoc.Size = Vector3.new(8,1,8)
	spawnLoc.Color = C(255,214,225) spawnLoc.Material = Enum.Material.Fabric
	local dec = spawnLoc:FindFirstChildOfClass("Decal") if dec then dec:Destroy() end
	spawnLoc.Duration = 0
end
map.Parent = workspace

-- Licht
Lighting.ClockTime = 14
Lighting.Brightness = 2
Lighting.Ambient = C(120,110,140)
Lighting.OutdoorAmbient = C(150,140,170)
if not Lighting:FindFirstChildOfClass("Atmosphere") then
	local a = Instance.new("Atmosphere") a.Density = 0.25 a.Color = C(220,210,255) a.Decay = C(180,170,220) a.Parent = Lighting
end
return "Map gebaut"
