-- Baut Graybox-Räume für Zone 2–4 hinter dem Kinderzimmer (PS-12 Testumgebung, PS-16 ersetzt die Optik).
-- In Studio (Edit) per execute_luau ausführen. Idempotent: ersetzt Map.Zones.<Name> und zugehörige Volumen/Spawns.
local CS = game:GetService("CollectionService")
local map = workspace:WaitForChild("Map")
local zonesFolder = map:WaitForChild("Zones")
local C = Color3.fromRGB

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do p[k] = v end
	p.Parent = parent
	return p
end

-- Spawn für das Kinderzimmer (Teleport-Ziel)
local bedSpawn = map:FindFirstChild("ZoneSpawn_bedroom") or part({Name="ZoneSpawn_bedroom", Size=Vector3.new(6,1,6), Position=Vector3.new(0,0.5,40), Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false}, map)
bedSpawn:SetAttribute("ZoneId", "bedroom")
CS:AddTag(bedSpawn, "ZoneSpawn")

local defs = {
	{ id = "livingroom", name = "Lounge", z0 = 70, floor = C(255,214,190), wall = C(255,190,160), accent = C(255,226,122), next = "hotelsuite", nextLabel = "🔒 Grand Hotel Suite\n🕊️ 4M" },
	{ id = "hotelsuite", name = "HotelSuite", z0 = 210, floor = C(120,40,60), wall = C(150,60,80), accent = C(255,196,60), next = "cloudrealm", nextLabel = "🔒 Cloud Kingdom\n🕊️ 250M · Rebirth 1" },
	{ id = "cloudrealm", name = "CloudKingdom", z0 = 350, floor = C(245,245,255), wall = C(200,190,255), accent = C(190,170,255) },
}

for _, d in defs do
	local old = zonesFolder:FindFirstChild(d.name) if old then old:Destroy() end
	for _, n in { "ZoneVolume_" .. d.id, "ZoneSpawn_" .. d.id } do
		local o = map:FindFirstChild(n) if o then o:Destroy() end
	end
	local room = Instance.new("Model") room.Name = d.name
	local cz = d.z0 + 70
	part({Name="Floor", Size=Vector3.new(140,2,140), Position=Vector3.new(0,-1,cz), Color=d.floor, Material=Enum.Material.Fabric}, room)
	part({Name="WallLeft", Size=Vector3.new(2,24,140), Position=Vector3.new(-70,12,cz), Color=d.wall}, room)
	part({Name="WallRight", Size=Vector3.new(2,24,140), Position=Vector3.new(70,12,cz), Color=d.wall}, room)
	-- Rückwand mit Durchgang zur nächsten Zone
	part({Name="WallFrontL", Size=Vector3.new(55,24,2), Position=Vector3.new(-42.5,12,d.z0+140), Color=d.wall}, room)
	part({Name="WallFrontR", Size=Vector3.new(55,24,2), Position=Vector3.new(42.5,12,d.z0+140), Color=d.wall}, room)
	part({Name="WallFrontTop", Size=Vector3.new(30,8,2), Position=Vector3.new(0,20,d.z0+140), Color=d.wall}, room)
	if not d.next then
		part({Name="WallEnd", Size=Vector3.new(30,16,2), Position=Vector3.new(0,8,d.z0+140), Color=d.wall}, room)
	end
	-- Puppen
	local dummies = Instance.new("Folder") dummies.Name = "Dummies" dummies.Parent = room
	for i, off in { Vector3.new(-20,0,-10), Vector3.new(20,0,-10), Vector3.new(-20,0,25), Vector3.new(20,0,25) } do
		local pos = Vector3.new(off.X, 0, cz + off.Z)
		local m = Instance.new("Model") m.Name = d.name .. "Dummy" .. i
		part({Name="Pole", Size=Vector3.new(0.6,4,0.6), Position=pos+Vector3.new(0,2,0), Color=C(180,140,100), Material=Enum.Material.Wood}, m)
		local body = part({Name="Body", Size=Vector3.new(4,6,4), Position=pos+Vector3.new(0,7,0), Color=d.accent, Material=Enum.Material.Fabric}, m)
		local sm = Instance.new("SpecialMesh") sm.MeshType = Enum.MeshType.Sphere sm.Parent = body
		m.PrimaryPart = body
		CS:AddTag(m, "PillowDummy")
		m.Parent = dummies
	end
	-- Barriere zur nächsten Zone
	if d.next then
		local b = part({Name="Barrier_" .. d.next, Size=Vector3.new(30,16,1), Position=Vector3.new(0,8,d.z0+140), Color=C(255,143,177), Material=Enum.Material.ForceField, Transparency=0.3}, room)
		b:SetAttribute("ZoneId", d.next)
		CS:AddTag(b, "ZoneBarrier")
		local sg = Instance.new("SurfaceGui") sg.Face = Enum.NormalId.Back sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud sg.PixelsPerStud = 20 sg.Parent = b
		local lbl = Instance.new("TextLabel") lbl.Size = UDim2.fromScale(1,1) lbl.BackgroundTransparency = 1 lbl.Font = Enum.Font.FredokaOne lbl.TextScaled = true
		lbl.Text = d.nextLabel lbl.TextColor3 = C(255,246,236) lbl.TextStrokeTransparency = 0 lbl.Parent = sg
	end
	room.Parent = zonesFolder
	local vol = part({Name="ZoneVolume_" .. d.id, Size=Vector3.new(138,40,138), Position=Vector3.new(0,20,cz), Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false}, map)
	vol:SetAttribute("ZoneId", d.id)
	CS:AddTag(vol, "ZoneVolume")
	local sp = part({Name="ZoneSpawn_" .. d.id, Size=Vector3.new(6,1,6), Position=Vector3.new(0,0.5,d.z0+12), Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false}, map)
	sp:SetAttribute("ZoneId", d.id)
	CS:AddTag(sp, "ZoneSpawn")
end
return "Zonen 2–4 gebaut"
