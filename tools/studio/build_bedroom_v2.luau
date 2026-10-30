-- Art-Pass Bedroom v2 (PS-43). In Studio (Edit) ausführen, z. B. DevTools.RunToolScript(sha, "tools/studio/build_bedroom_v2.luau").
-- Idempotent: entfernt Workspace.Map.Zones.Bedroom.DecorV2 und baut neu; Wände werden auf WALL_H gesetzt.
-- Ziel (Art Bible): gemütliches Riesen-Kinderzimmer – höhere Wände mit Streifentapete, Fußleiste + Zierleiste,
-- Sternen-Lichterketten, Riesen-Kissenberg (bekletterbar), Riesen-Kleiderschrank, Bilderrahmen.
-- Spielrelevantes bleibt unverändert: Boden, Puppen, Spawn, Durchgang/Barriere zur Lounge.
local Bedroom = workspace.Map.Zones.Bedroom
local Pillows = game.ReplicatedStorage.Assets.Pillows

local WALL_H = 44
local HALF = 70 -- Raum 140 × 140, Mitte (0, 0, 0)
local DOOR_W, DOOR_H = 30, 16

local function C(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local WALL = C(178, 205, 240)
local STRIPE = C(198, 220, 248)
local CREAM = C(255, 246, 232)
local WOOD = C(214, 170, 120)
local WOOD_DARK = C(170, 122, 82)
local STAR = C(255, 224, 120)

local old = Bedroom:FindFirstChild("DecorV2")
if old then
	old:Destroy()
end
local root = Instance.new("Model")
root.Name = "DecorV2"

local count = 0
local function part(props: { [string]: any }, parent: Instance?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent or root
	count += 1
	return p
end
local function deco(p: BasePart)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
end

-- 1. Wände erhöhen (Durchgang zur Lounge bleibt 30 × 16)
local function wall(name: string, size: Vector3, pos: Vector3)
	local w = Bedroom:FindFirstChild(name)
	if w then
		w.Size = size
		w.Position = pos
		w.Color = WALL
	end
end
wall("WallBack", Vector3.new(140, WALL_H, 2), Vector3.new(0, WALL_H / 2, -HALF))
wall("WallLeft", Vector3.new(2, WALL_H, 140), Vector3.new(-HALF, WALL_H / 2, 0))
wall("WallRight", Vector3.new(2, WALL_H, 140), Vector3.new(HALF, WALL_H / 2, 0))
wall("WallFrontL", Vector3.new(55, WALL_H, 2), Vector3.new(-42, WALL_H / 2, HALF))
wall("WallFrontR", Vector3.new(55, WALL_H, 2), Vector3.new(42, WALL_H / 2, HALF))
wall("WallFrontTop", Vector3.new(DOOR_W, WALL_H - DOOR_H, 2), Vector3.new(0, DOOR_H + (WALL_H - DOOR_H) / 2, HALF))

-- Innenflächen: Wand-Richtungen (Position der Innenfläche, Laufrichtung, Normale nach innen)
local faces = {
	{ origin = Vector3.new(0, 0, -HALF + 1), along = Vector3.xAxis, normal = Vector3.zAxis, len = 140 },
	{ origin = Vector3.new(-HALF + 1, 0, 0), along = Vector3.zAxis, normal = Vector3.xAxis, len = 140 },
	{ origin = Vector3.new(HALF - 1, 0, 0), along = Vector3.zAxis, normal = -Vector3.xAxis, len = 140 },
	{ origin = Vector3.new(0, 0, HALF - 1), along = Vector3.xAxis, normal = -Vector3.zAxis, len = 140, door = true },
}
local function onFace(f, t: number, y: number, depth: number): Vector3
	return f.origin + f.along * t + Vector3.yAxis * y + f.normal * depth
end
local function sizeOnFace(f, w: number, h: number, d: number): Vector3
	if f.along == Vector3.xAxis then
		return Vector3.new(w, h, d)
	end
	return Vector3.new(d, h, w)
end
local function inDoor(f, t: number, halfW: number): boolean
	return f.door == true and math.abs(t) < DOOR_W / 2 + halfW
end

-- 2. Streifentapete, Fußleiste, Zierleiste
local wallpaper = Instance.new("Folder")
wallpaper.Name = "Wallpaper"
wallpaper.Parent = root
for _, f in faces do
	for t = -HALF + 6, HALF - 6, 8 do
		local s = part({
			Name = "Stripe",
			Color = STRIPE,
			Size = sizeOnFace(f, 2, WALL_H - 6, 0.2),
			Position = onFace(f, t, 3 + (WALL_H - 6) / 2, 0.1),
		}, wallpaper)
		deco(s)
		if inDoor(f, t, 1) then
			-- über dem Durchgang nur den oberen Teil
			s.Size = sizeOnFace(f, 2, WALL_H - DOOR_H - 4, 0.2)
			s.Position = onFace(f, t, DOOR_H + 1 + (WALL_H - DOOR_H - 4) / 2, 0.1)
		end
	end
	-- Fußleiste (am Durchgang unterbrochen)
	local segments = if f.door then { { -HALF, -DOOR_W / 2 }, { DOOR_W / 2, HALF } } else { { -HALF, HALF } }
	for _, seg in segments do
		local mid, len = (seg[1] + seg[2]) / 2, seg[2] - seg[1]
		part({ Name = "Baseboard", Color = CREAM, Size = sizeOnFace(f, len, 2.5, 0.8), Position = onFace(f, mid, 1.25, 0.4) }, wallpaper)
	end
	local top = part({
		Name = "CrownMolding",
		Color = CREAM,
		Size = sizeOnFace(f, f.len, 1.6, 1.4),
		Position = onFace(f, 0, WALL_H - 0.8, 0.7),
	}, wallpaper)
	deco(top)
end

-- 3. Sternen-Lichterketten (durchhängend) an Rück-, Links- und Rechtswand
local lights = Instance.new("Folder")
lights.Name = "StarGarlands"
lights.Parent = root
local BULB_COLORS = { STAR, C(255, 180, 210), C(170, 220, 255), C(200, 255, 200) }
for fi = 1, 3 do
	local f = faces[fi]
	for sag = 0, 1 do
		local t0 = -HALF + 4 + sag * (f.len - 8) / 2
		local t1 = t0 + (f.len - 8) / 2
		local n = 14
		for i = 0, n do
			local a = i / n
			local t = t0 + (t1 - t0) * a
			local y = WALL_H - 6 - 5 * (1 - (2 * a - 1) ^ 2)
			local bulb = part({
				Name = "Bulb",
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = BULB_COLORS[(i % #BULB_COLORS) + 1],
				Size = Vector3.new(1.3, 1.3, 1.3),
				Position = onFace(f, t, y, 1.2),
			}, lights)
			deco(bulb)
		end
	end
end

-- 4. Riesen-Kissenberg vorne links (bekletterbar)
local pile = Instance.new("Model")
pile.Name = "GiantPillowPile"
pile.Parent = root
local PILE = {
	-- id, Skalierung, Position, Drehung (Grad)
	{ "cotton", 7, Vector3.new(-56, 4, 54), Vector3.new(0, 20, 0) },
	{ "striped", 6.5, Vector3.new(-44, 4, 58), Vector3.new(0, -15, 0) },
	{ "fluffy", 6, Vector3.new(-58, 4, 38), Vector3.new(0, 40, 0) },
	{ "heart", 5.5, Vector3.new(-52, 11, 50), Vector3.new(8, 65, -6) },
	{ "worn", 5, Vector3.new(-58, 16, 56), Vector3.new(-10, 110, 12) },
	{ "cloud", 4.5, Vector3.new(-46, 10, 46), Vector3.new(0, -30, 18) },
}
for _, e in PILE do
	local tpl = Pillows:FindFirstChild(e[1])
	if tpl and tpl:IsA("BasePart") then
		local p = tpl:Clone()
		p.Name = "Giant_" .. e[1]
		p.Anchored = true
		p.CanCollide = true
		p.Size = tpl.Size * e[2]
		local r = e[4]
		p.CFrame = CFrame.new(e[3]) * CFrame.Angles(math.rad(r.X), math.rad(r.Y), math.rad(r.Z))
		p.Parent = pile
		count += 1
	end
end

-- 5. Riesen-Kleiderschrank an der linken Wand
local wardrobe = Instance.new("Model")
wardrobe.Name = "GiantWardrobe"
wardrobe.Parent = root
local wx, wz = -HALF + 1 + 6, 12
part({ Name = "Body", Color = WOOD, Material = Enum.Material.Wood, Size = Vector3.new(12, 34, 30), Position = Vector3.new(wx, 17, wz) }, wardrobe)
part({ Name = "Top", Color = WOOD_DARK, Material = Enum.Material.Wood, Size = Vector3.new(13.5, 2, 32), Position = Vector3.new(wx, 35, wz) }, wardrobe)
for _, dz in { -7.3, 7.3 } do
	local door = part({
		Name = "Door",
		Color = C(236, 200, 160),
		Material = Enum.Material.Wood,
		Size = Vector3.new(0.6, 28, 14),
		Position = Vector3.new(wx + 6.2, 18, wz + dz),
	}, wardrobe)
	deco(door)
	local knob = part({
		Name = "Knob",
		Shape = Enum.PartType.Ball,
		Color = STAR,
		Material = Enum.Material.Metal,
		Size = Vector3.new(1.4, 1.4, 1.4),
		Position = Vector3.new(wx + 6.8, 18, wz + dz * 0.15),
	}, wardrobe)
	deco(knob)
end
for _, dz in { -11, 11 } do
	part({ Name = "Foot", Shape = Enum.PartType.Cylinder, Color = WOOD_DARK, Size = Vector3.new(2, 2.4, 2.4), CFrame = CFrame.new(wx + 3, 0.6, wz + dz) * CFrame.Angles(0, 0, math.rad(90)) }, wardrobe)
end

-- 6. Bilderrahmen an der rechten Wand (Mond, Stern, Herz als einfache Formen)
local frames = Instance.new("Folder")
frames.Name = "Frames"
frames.Parent = root
local FRAMES = {
	{ z = -30, inner = C(60, 70, 140), motif = STAR, shape = Enum.PartType.Ball, ms = 5 },
	{ z = 0, inner = C(255, 220, 230), motif = C(255, 120, 160), shape = Enum.PartType.Ball, ms = 4 },
	{ z = 30, inner = C(210, 240, 220), motif = C(255, 255, 255), shape = Enum.PartType.Cylinder, ms = 5 },
}
local fx = HALF - 1
for _, fr in FRAMES do
	local frame = part({ Name = "Frame", Color = WOOD_DARK, Material = Enum.Material.Wood, Size = Vector3.new(0.8, 14, 12), Position = Vector3.new(fx - 0.4, 26, fr.z) }, frames)
	deco(frame)
	local inner = part({ Name = "Canvas", Color = fr.inner, Size = Vector3.new(0.4, 11, 9), Position = Vector3.new(fx - 0.9, 26, fr.z) }, frames)
	deco(inner)
	local motif = part({
		Name = "Motif",
		Shape = fr.shape,
		Material = Enum.Material.Neon,
		Color = fr.motif,
		Size = if fr.shape == Enum.PartType.Cylinder then Vector3.new(0.4, fr.ms, fr.ms) else Vector3.new(fr.ms, fr.ms, 0.4 + fr.ms * 0),
		CFrame = CFrame.new(fx - 1.2, 26, fr.z),
	}, frames)
	if fr.shape == Enum.PartType.Ball then
		motif.Size = Vector3.new(fr.ms, fr.ms, fr.ms) * 0.8
		motif.Position = Vector3.new(fx - 1.1 + 0, 26, fr.z)
	end
	deco(motif)
end

root.Parent = Bedroom
return ("Bedroom v2: %d Teile, Wände %d hoch"):format(count, WALL_H)
