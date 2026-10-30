-- Art-Pass Zonen v2 (PS-43). In Studio (Edit) ausführen: DevTools.RunToolScript(sha, "tools/studio/build_zones_v2.luau").
-- Idempotent: je Zone wird <Zone>.DecorV2 neu gebaut; Wände werden auf WALL_H erhöht.
-- Ziel (Art Bible): jede Zone wirkt wie ein echter Raum statt einer Box – höhere Wände mit eigener Tapete
-- (Rückseite geteilter Wände bekommt die Farbe der jeweiligen Zone), Fuß- und Zierleiste, Lichter je Zonenstil,
-- ein bekletterbarer Riesen-Kissenberg aus den echten Kissenmodellen, Extras je Zone.
-- Unverändert: Böden, Puppen, Spawns, Zonen-Volumen, Durchgänge (30 × 16) und Barrieren.
local CollectionService = game:GetService("CollectionService")
local Zones = workspace.Map.Zones
local Pillows = game.ReplicatedStorage.Assets.Pillows

local WALL_H = 44
local HALF = 70 -- jede Zone 140 × 140
local DOOR_W, DOOR_H = 30, 16

local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Zonen in Reihenfolge entlang +Z. backDoor/frontDoor: Durchgang in der Rück-/Vorderwand.
local ZONES = {
	{
		folder = "Bedroom",
		cz = 0,
		wall = C(178, 205, 240),
		stripe = C(198, 220, 248),
		trim = C(255, 246, 232),
		lights = "garland",
		bulbs = { C(255, 224, 120), C(255, 180, 210), C(170, 220, 255), C(200, 255, 200) },
		backDoor = false,
		frontDoor = true,
		ownBack = "WallBack",
		pile = { "cotton", "striped", "fluffy", "heart", "worn", "cloud" },
		extras = "bedroom",
		dummySkin = "dummy_bedroom",
		spawnId = "bedroom",
	},
	{
		folder = "Lounge",
		cz = 140,
		wall = C(255, 204, 180),
		stripe = C(255, 222, 202),
		trim = C(255, 242, 228),
		lights = "garland",
		bulbs = { C(255, 214, 120) },
		backDoor = true,
		frontDoor = true,
		pile = { "sleepover", "heart", "striped", "fluffy", "satin", "cotton" },
		extras = "lounge",
		dummySkin = "dummy_lounge",
		spawnId = "livingroom",
	},
	{
		folder = "HotelSuite",
		cz = 280,
		wall = C(255, 241, 222),
		stripe = C(244, 222, 180),
		trim = C(225, 182, 70),
		trimMaterial = Enum.Material.Metal,
		lights = "sconce",
		bulbs = { C(255, 228, 170) },
		backDoor = true,
		frontDoor = true,
		pile = { "hotel", "royal", "satin", "memoryfoam", "royal", "hotel" },
		extras = "hotel",
		dummySkin = "dummy_hotel",
		spawnId = "hotelsuite",
	},
	{
		folder = "CloudKingdom",
		cz = 420,
		wall = C(205, 195, 255),
		stripe = C(224, 216, 255),
		trim = C(228, 232, 245),
		lights = "garland",
		bulbs = { C(255, 255, 255), C(210, 200, 255), C(255, 236, 150) },
		backDoor = true,
		frontDoor = false, -- Ende der Welt: Durchgang ist durch WallEnd verschlossen
		pile = { "cloud", "dream", "starlight", "fluffy", "cloud", "starlight" },
		extras = "cloud",
		dummySkin = "dummy_cloud",
		spawnId = "cloudrealm",
	},
}

local count = 0
local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	count += 1
	return p
end
local function deco(p: BasePart): BasePart
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end
local function folder(name: string, parent: Instance): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- Innenfläche einer Wand: origin (Mitte, Boden), along (Laufrichtung), normal (in den Raum)
local function facesFor(z: any)
	local c = Vector3.new(0, 0, z.cz)
	return {
		{ origin = c + Vector3.new(0, 0, -HALF + 1), along = Vector3.xAxis, normal = Vector3.zAxis, door = z.backDoor },
		{ origin = c + Vector3.new(-HALF + 1, 0, 0), along = Vector3.zAxis, normal = Vector3.xAxis, door = false },
		{ origin = c + Vector3.new(HALF - 1, 0, 0), along = Vector3.zAxis, normal = -Vector3.xAxis, door = false },
		{ origin = c + Vector3.new(0, 0, HALF - 1), along = Vector3.xAxis, normal = -Vector3.zAxis, door = z.frontDoor },
	}
end
local function at(f, t: number, y: number, depth: number): Vector3
	return f.origin + f.along * t + Vector3.yAxis * y + f.normal * depth
end
local function sz(f, w: number, h: number, d: number): Vector3
	return if f.along == Vector3.xAxis then Vector3.new(w, h, d) else Vector3.new(d, h, w)
end
-- Abschnitte entlang einer Fläche, Durchgang ausgespart
local function spans(f): { { number } }
	if f.door then
		return { { -HALF, -DOOR_W / 2 }, { DOOR_W / 2, HALF } }
	end
	return { { -HALF, HALF } }
end

local function raiseWalls(model: Instance, z: any)
	local function set(name: string, size: Vector3, pos: Vector3)
		local w = model:FindFirstChild(name)
		if w and w:IsA("BasePart") then
			w.Size = size
			w.Position = pos
		end
	end
	local cz = z.cz
	if z.ownBack then
		set(z.ownBack, Vector3.new(140, WALL_H, 2), Vector3.new(0, WALL_H / 2, cz - HALF))
	end
	set("WallLeft", Vector3.new(2, WALL_H, 140), Vector3.new(-HALF, WALL_H / 2, cz))
	set("WallRight", Vector3.new(2, WALL_H, 140), Vector3.new(HALF, WALL_H / 2, cz))
	set("WallFrontL", Vector3.new(55, WALL_H, 2), Vector3.new(-42, WALL_H / 2, cz + HALF))
	set("WallFrontR", Vector3.new(55, WALL_H, 2), Vector3.new(42, WALL_H / 2, cz + HALF))
	set("WallFrontTop", Vector3.new(DOOR_W, WALL_H - DOOR_H, 2), Vector3.new(0, DOOR_H + (WALL_H - DOOR_H) / 2, cz + HALF))
end

local function wallpaper(root: Instance, z: any)
	local wp = folder("Wallpaper", root)
	for _, f in facesFor(z) do
		-- Tapeten-Grund (eigene Farbe je Zone, auch auf geteilten Wänden), Durchgang ausgespart
		for _, s in spans(f) do
			local mid, len = (s[1] + s[2]) / 2, s[2] - s[1]
			deco(part({ Name = "Backing", Color = z.wall, Size = sz(f, len, WALL_H - 0.2, 0.1), Position = at(f, mid, WALL_H / 2, 0.05) }, wp))
		end
		if f.door then
			deco(part({
				Name = "BackingTop",
				Color = z.wall,
				Size = sz(f, DOOR_W, WALL_H - DOOR_H - 0.2, 0.1),
				Position = at(f, 0, DOOR_H + (WALL_H - DOOR_H) / 2, 0.05),
			}, wp))
		end
		-- Streifen
		for t = -HALF + 6, HALF - 6, 8 do
			local inDoor = f.door and math.abs(t) < DOOR_W / 2 + 1
			local y0 = if inDoor then DOOR_H + 1 else 3
			local h = WALL_H - 3 - y0
			deco(part({ Name = "Stripe", Color = z.stripe, Size = sz(f, 2, h, 0.2), Position = at(f, t, y0 + h / 2, 0.15) }, wp))
		end
		-- Fußleiste + Zierleiste
		for _, s in spans(f) do
			local mid, len = (s[1] + s[2]) / 2, s[2] - s[1]
			part({
				Name = "Baseboard",
				Color = z.trim,
				Material = z.trimMaterial or Enum.Material.SmoothPlastic,
				Size = sz(f, len, 2.5, 0.8),
				Position = at(f, mid, 1.25, 0.4),
			}, wp)
		end
		deco(part({
			Name = "CrownMolding",
			Color = z.trim,
			Material = z.trimMaterial or Enum.Material.SmoothPlastic,
			Size = sz(f, 140, 1.6, 1.4),
			Position = at(f, 0, WALL_H - 0.8, 0.7),
		}, wp))
	end
end

local function lights(root: Instance, z: any)
	local lf = folder("Lights", root)
	local faces = facesFor(z)
	if z.lights == "garland" then
		-- durchhängende Lichterketten an Links-, Rechts- und Rückwand (Rückwand nur ohne Durchgang)
		for fi, f in faces do
			if fi == 4 or (fi == 1 and f.door) then
				continue
			end
			for half = 0, 1 do
				local t0 = -HALF + 4 + half * 66
				local n = 14
				for i = 0, n do
					local a = i / n
					local y = WALL_H - 6 - 5 * (1 - (2 * a - 1) ^ 2)
					local bulb = deco(part({
						Name = "Bulb",
						Shape = Enum.PartType.Ball,
						Material = Enum.Material.Neon,
						Color = z.bulbs[(i % #z.bulbs) + 1],
						Size = Vector3.new(1.3, 1.3, 1.3),
						Position = at(f, t0 + 66 * a, y, 1.2),
					}, lf))
					CollectionService:AddTag(bulb, "AmbientTwinkle")
				end
			end
		end
	else
		-- Wandleuchten (Hotel): goldene Platte + warmes Licht, alle 20 Studs an Links- und Rechtswand
		for fi = 2, 3 do
			local f = faces[fi]
			for t = -60, 60, 20 do
				deco(part({ Name = "SconcePlate", Color = z.trim, Material = Enum.Material.Metal, Size = sz(f, 2.4, 4, 0.4), Position = at(f, t, 26, 0.3) }, lf))
				deco(part({
					Name = "SconceLight",
					Shape = Enum.PartType.Ball,
					Material = Enum.Material.Neon,
					Color = z.bulbs[1],
					Size = Vector3.new(2, 2, 2),
					Position = at(f, t, 28, 1.4),
				}, lf))
			end
		end
	end
end

local PILE_LAYOUT = {
	-- Skalierung, Versatz zur Ecke (x, y, z), Drehung (Grad)
	{ 10, Vector3.new(-54, 6, 52), Vector3.new(0, 20, 0) },
	{ 9, Vector3.new(-38, 5.5, 58), Vector3.new(0, -15, 0) },
	{ 9, Vector3.new(-57, 5.5, 32), Vector3.new(0, 40, 0) },
	{ 8, Vector3.new(-50, 16, 46), Vector3.new(8, 65, -6) },
	{ 7.5, Vector3.new(-58, 23, 56), Vector3.new(-10, 110, 12) },
	{ 7, Vector3.new(-40, 14, 44), Vector3.new(0, -30, 18) },
}
local function pile(root: Instance, z: any)
	local m = Instance.new("Model")
	m.Name = "GiantPillowPile"
	m.Parent = root
	for i, id in z.pile do
		local tpl = Pillows:FindFirstChild(id)
		local L = PILE_LAYOUT[i]
		if tpl and tpl:IsA("BasePart") and L then
			local p = tpl:Clone()
			p.Name = "Giant_" .. id
			p.Anchored = true
			p.CanCollide = true
			p.Size = tpl.Size * L[1]
			local r = L[3]
			p.CFrame = CFrame.new(L[2] + Vector3.new(0, 0, z.cz)) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
			p.Parent = m
			count += 1
		end
	end
end

-- Generierte Hero-Props aus ReplicatedStorage.Assets.Props (Studio-Mesh-Generierung, siehe docs/art/asset-list.md)
local Props = game.ReplicatedStorage.Assets:FindFirstChild("Props")
local function prop(root: Instance, name: string, scale: number, groundPos: Vector3, yawDeg: number, collide: boolean)
	local tpl = Props and Props:FindFirstChild(name)
	if not tpl or not tpl:IsA("Model") then
		return nil
	end
	local m = tpl:Clone()
	m:ScaleTo(scale)
	m:PivotTo(CFrame.Angles(0, math.rad(yawDeg), 0) * (m:GetPivot() - m:GetPivot().Position) + m:GetPivot().Position)
	local cf, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + (groundPos + Vector3.new(0, size.Y / 2, 0) - cf.Position))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = collide
			d.CanTouch = false
			if not collide then
				d.CanQuery = false
			end
		end
	end
	m.Name = "Hero_" .. name
	m.Parent = root
	count += 1
	return m
end

local EXTRAS = {}
function EXTRAS.bedroom(root: Instance, z: any)
	prop(root, "teddy", 1.4, Vector3.new(52, 0, z.cz - 28), -90, true)
	local WOOD, WOOD_DARK, STAR = C(214, 170, 120), C(170, 122, 82), C(255, 224, 120)
	local w = Instance.new("Model")
	w.Name = "GiantWardrobe"
	w.Parent = root
	local wx, wz = -HALF + 7, z.cz + 12
	part({ Name = "Body", Color = WOOD, Material = Enum.Material.Wood, Size = Vector3.new(12, 34, 30), Position = Vector3.new(wx, 17, wz) }, w)
	part({ Name = "Top", Color = WOOD_DARK, Material = Enum.Material.Wood, Size = Vector3.new(13.5, 2, 32), Position = Vector3.new(wx, 35, wz) }, w)
	for _, dz in { -7.3, 7.3 } do
		deco(part({ Name = "Door", Color = C(236, 200, 160), Material = Enum.Material.Wood, Size = Vector3.new(0.6, 28, 14), Position = Vector3.new(wx + 6.2, 18, wz + dz) }, w))
		deco(part({
			Name = "Knob",
			Shape = Enum.PartType.Ball,
			Color = STAR,
			Material = Enum.Material.Metal,
			Size = Vector3.new(1.4, 1.4, 1.4),
			Position = Vector3.new(wx + 6.8, 18, wz + dz * 0.15),
		}, w))
	end
	-- Bilderrahmen rechts (Stern, Herz, Mond)
	local fr = folder("Frames", root)
	local fx = HALF - 1
	for _, e in { { -30, C(60, 70, 140), STAR }, { 0, C(255, 220, 230), C(255, 120, 160) }, { 30, C(210, 240, 220), C(255, 255, 255) } } do
		local zz = z.cz + e[1]
		deco(part({ Name = "Frame", Color = WOOD_DARK, Material = Enum.Material.Wood, Size = Vector3.new(0.8, 14, 12), Position = Vector3.new(fx - 0.4, 26, zz) }, fr))
		deco(part({ Name = "Canvas", Color = e[2], Size = Vector3.new(0.4, 11, 9), Position = Vector3.new(fx - 0.9, 26, zz) }, fr))
		deco(part({ Name = "Motif", Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = e[3], Size = Vector3.new(4, 4, 4), Position = Vector3.new(fx - 1.1, 26, zz) }, fr))
	end
end
function EXTRAS.lounge(root: Instance, z: any)
	-- Discokugel unter der mittleren Wimpelkette
	local ball = prop(root, "disco", 1.3, Vector3.new(0, WALL_H - 22, z.cz), 0, false)
	if ball then
		CollectionService:AddTag(ball, "AmbientSpin") -- dreht sich lokal (AmbientController)
		local top = ball:GetBoundingBox().Position.Y + ball:GetExtentsSize().Y / 2
		deco(part({
			Name = "DiscoChain",
			Color = C(200, 200, 210),
			Material = Enum.Material.Metal,
			Size = Vector3.new(0.4, WALL_H + 4 - top, 0.4),
			Position = Vector3.new(0, (top + WALL_H + 4) / 2, z.cz),
		}, root))
	end
	-- Wimpelkette (Party) quer über den Raum, unter den Lichterketten
	local b = folder("Bunting", root)
	local COLORS = { C(255, 140, 160), C(255, 210, 110), C(140, 210, 255), C(170, 235, 170), C(210, 170, 255) }
	for row = 0, 2 do
		local zz = z.cz - 40 + row * 40
		for i = 0, 22 do
			local x = -66 + i * 6
			local sag = 6 * (1 - ((x / 66) ^ 2))
			local w = Instance.new("WedgePart")
			w.Anchored = true
			w.Size = Vector3.new(0.2, 3.2, 3.2)
			w.Color = COLORS[(i % #COLORS) + 1]
			w.Material = Enum.Material.Fabric
			w.CFrame = CFrame.new(x, WALL_H - 10 - sag, zz) * CFrame.Angles(0, math.rad(90), math.rad(180))
			deco(w)
			w.Parent = b
			count += 1
		end
	end
end
function EXTRAS.hotel(root: Instance, z: any)
	prop(root, "trolley", 1.3, Vector3.new(-32, 0, z.cz - 54), 20, true)
	-- Riesen-Kronleuchter in der Mitte (Goldring + Kristalle)
	local ch = Instance.new("Model")
	ch.Name = "GiantChandelier"
	ch.Parent = root
	local GOLD = C(225, 182, 70)
	local center = Vector3.new(0, WALL_H - 8, z.cz)
	deco(part({ Name = "Chain", Color = GOLD, Material = Enum.Material.Metal, Size = Vector3.new(0.6, 8, 0.6), Position = center + Vector3.new(0, 5, 0) }, ch))
	deco(part({
		Name = "Ring",
		Shape = Enum.PartType.Cylinder,
		Color = GOLD,
		Material = Enum.Material.Metal,
		Size = Vector3.new(1, 18, 18),
		CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
	}, ch))
	for i = 0, 11 do
		local a = i / 12 * math.pi * 2
		deco(part({
			Name = "Crystal",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = C(255, 240, 200),
			Size = Vector3.new(1.6, 1.6, 1.6),
			Position = center + Vector3.new(math.cos(a) * 8.5, -1.5, math.sin(a) * 8.5),
		}, ch))
	end
end
function EXTRAS.cloud(root: Instance, z: any)
	prop(root, "moon", 4.5, Vector3.new(52, 0, z.cz - 30), -90, true)
	-- Großer Mond + schwebende Sterne an der Rückwand-Höhe
	local sky = folder("Sky", root)
	deco(part({
		Name = "Moon",
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Neon,
		Color = C(255, 246, 210),
		Size = Vector3.new(16, 16, 16),
		Position = Vector3.new(40, WALL_H + 14, z.cz + 40),
	}, sky))
	local rng = Random.new(42)
	for _ = 1, 24 do
		deco(part({
			Name = "Star",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = C(255, 236, 150),
			Size = Vector3.new(1.2, 1.2, 1.2),
			Position = Vector3.new(rng:NextNumber(-60, 60), rng:NextNumber(WALL_H - 14, WALL_H + 20), z.cz + rng:NextNumber(-60, 60)),
		}, sky))
	end
end

-- Puppen-Optik: generiertes Plüsch-Modell je Zone, an den (unsichtbar gemachten) Körper geschweißt.
-- Trefferlogik (Tag PillowDummy, Pivot), Wackel-Animation (PrimaryPart) und Schild (Head) bleiben unverändert.
local DUMMY_MAX_H, DUMMY_MAX_W = 12, 8
local function skinDummies(model: Instance, z: any): number
	local folderD = model:FindFirstChild("Dummies")
	local tpl = Props and z.dummySkin and Props:FindFirstChild(z.dummySkin)
	if not folderD or not tpl then
		return 0
	end
	local src = tpl:FindFirstChildWhichIsA("MeshPart", true)
	if not src then
		return 0
	end
	local spawn = workspace.Map:FindFirstChild("ZoneSpawn_" .. tostring(z.spawnId))
	local scale = math.min(DUMMY_MAX_H / src.Size.Y, DUMMY_MAX_W / math.max(src.Size.X, src.Size.Z))
	local n = 0
	for _, d in folderD:GetChildren() do
		local body = d:IsA("Model") and (d.PrimaryPart or d:FindFirstChild("Body"))
		if not body then
			continue
		end
		local old = d:FindFirstChild("Plush")
		if old then
			old:Destroy()
		end
		for _, name in { "Stand", "Pole", "Body", "Head" } do
			local p = d:FindFirstChild(name)
			if p and p:IsA("BasePart") then
				p.Transparency = 1
			end
		end
		local plush = src:Clone()
		plush.Name = "Plush"
		plush.Size = src.Size * scale
		local pivot = d:GetPivot().Position
		local _, ext = d:GetBoundingBox()
		local groundY = pivot.Y - ext.Y / 2
		local pos = Vector3.new(pivot.X, groundY + plush.Size.Y / 2, pivot.Z)
		-- Gesicht (+Z des generierten Modells, Eigendrehung des MeshParts beibehalten) zum Zonen-Spawn drehen
		if spawn and spawn:IsA("BasePart") then
			local target = Vector3.new(spawn.Position.X, pos.Y, spawn.Position.Z)
			plush.CFrame = CFrame.lookAt(pos, target) * CFrame.Angles(0, math.pi, 0) * src.CFrame.Rotation
		else
			plush.CFrame = CFrame.new(pos) * src.CFrame.Rotation
		end
		plush.Anchored = false
		plush.Massless = true
		plush.CanCollide = false
		plush.CanQuery = false
		plush.CanTouch = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = plush
		weld.Parent = plush
		plush.Parent = d
		n += 1
	end
	return n
end

local report = {}
for _, z in ZONES do
	local model = Zones:FindFirstChild(z.folder)
	if not model then
		table.insert(report, z.folder .. ": fehlt")
		continue
	end
	local before = count
	local old = model:FindFirstChild("DecorV2")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "DecorV2"
	raiseWalls(model, z)
	wallpaper(root, z)
	lights(root, z)
	pile(root, z)
	if EXTRAS[z.extras] then
		EXTRAS[z.extras](root, z)
	end
	root.Parent = model
	local skinned = skinDummies(model, z)
	table.insert(report, ("%s %d, Puppen %d"):format(z.folder, count - before, skinned))
end
-- Durchgänge (Portal): Rahmen in den Farben der Zielzone, Leuchtschild mit Zonenname (Lampen funkeln),
-- zwei Riesen-Kissen der Zielzone daneben. Anflugseite (vorige Zone) + Rückseite (Name der vorigen Zone).
-- Vorhang, Stange und Preisschild (Barriere, ZoneController) bleiben unverändert.
local ZoneConfig = require(game.ReplicatedStorage.Shared.Config.Zones)
local function portal(root: Instance, doorZ: number, facing: number, target: any, label: string)
	-- facing = Richtung der Raumseite (−1: Raum liegt bei kleinerem Z)
	local m = Instance.new("Model")
	m.Name = "Portal_" .. label:gsub("%W", "")
	m.Parent = root
	local zf = doorZ + facing * 1.6 -- vor der Wand
	local TRIM = target.trim
	local mat = target.trimMaterial or Enum.Material.SmoothPlastic
	for _, side in { -1, 1 } do
		part({ Name = "Post", Color = TRIM, Material = mat, Size = Vector3.new(3, 21, 2), Position = Vector3.new(side * 23, 10.5, zf) }, m)
		part({ Name = "PostCap", Shape = Enum.PartType.Ball, Color = TRIM, Material = mat, Size = Vector3.new(3.6, 3.6, 3.6), Position = Vector3.new(side * 23, 22.5, zf) }, m)
	end
	part({ Name = "Lintel", Color = TRIM, Material = mat, Size = Vector3.new(49, 3, 2), Position = Vector3.new(0, 19.5, zf) }, m)
	-- Leuchtschild
	local board = part({
		Name = "Sign",
		Color = target.wall,
		Size = Vector3.new(30, 7, 0.6),
		CFrame = CFrame.lookAt(Vector3.new(0, 27, zf), Vector3.new(0, 27, zf + facing)),
	}, m)
	deco(board)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(600, 140)
	sg.LightInfluence = 0
	sg.Parent = board
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne
	tl.TextScaled = true
	tl.Text = label
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0
	tl.TextStrokeColor3 = Color3.fromRGB(60, 40, 90)
	tl.Parent = sg
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.05, 0), UDim.new(0.05, 0)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0.12, 0), UDim.new(0.12, 0)
	pad.Parent = tl
	-- Lampenrand ums Schild
	local bz = zf + facing * 0.5
	local function bulb(x: number, y: number)
		local b = deco(part({
			Name = "Bulb",
			Shape = Enum.PartType.Ball,
			Material = Enum.Material.Neon,
			Color = target.bulbs[1],
			Size = Vector3.new(0.9, 0.9, 0.9),
			Position = Vector3.new(x, y, bz),
		}, m))
		CollectionService:AddTag(b, "AmbientTwinkle")
	end
	for x = -14.5, 14.5, 2.9 do
		bulb(x, 30.3)
		bulb(x, 23.7)
	end
	for _, x in { -15.2, 15.2 } do
		for y = 25.35, 28.65, 1.65 do
			bulb(x, y)
		end
	end
	-- Riesen-Kissen der Zielzone neben dem Durchgang
	for i, side in { -1, 1 } do
		local id = target.pile[i]
		local tpl = Pillows:FindFirstChild(id)
		if tpl and tpl:IsA("BasePart") then
			local p = tpl:Clone()
			p.Name = "PortalPillow"
			p.Anchored = true
			p.CanCollide = true
			p.Size = tpl.Size * 4.5
			p.CFrame = CFrame.new(side * 32, p.Size.Z / 2 + 0.5, doorZ + facing * (p.Size.Y / 2 + 1.5))
				* CFrame.Angles(math.rad(-80 * facing), math.rad(side * 12), 0)
			p.Parent = m
			count += 1
		end
	end
end

local portals = 0
for i = 1, #ZONES - 1 do
	local a, b = ZONES[i], ZONES[i + 1]
	local doorZ = a.cz + HALF
	local aModel, bModel = Zones:FindFirstChild(a.folder), Zones:FindFirstChild(b.folder)
	local aRoot = aModel and aModel:FindFirstChild("DecorV2")
	local bRoot = bModel and bModel:FindFirstChild("DecorV2")
	local nameB = ZoneConfig.byId[b.spawnId] and ZoneConfig.byId[b.spawnId].name or b.folder
	local nameA = ZoneConfig.byId[a.spawnId] and ZoneConfig.byId[a.spawnId].name or a.folder
	if aRoot then
		portal(aRoot, doorZ, -1, b, nameB)
		portals += 1
	end
	if bRoot then
		portal(bRoot, doorZ, 1, a, nameA)
		portals += 1
	end
end
table.insert(report, ("Portale %d"):format(portals))

return ("Zonen v2: %d Teile (%s), Wände %d hoch"):format(count, table.concat(report, ", "), WALL_H)
