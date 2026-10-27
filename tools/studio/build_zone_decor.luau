-- PS-16: Dekor für alle 4 Zonen nach Art Bible (prozedural + generierte Kissenmodelle als Requisiten).
-- In Studio (Edit) ausführen (DevTools.RunToolScript), NACH build_graybox_bedroom/zones.luau. Idempotent: ersetzt
-- Map.Zones.<Zone>.Decor und färbt Boden/Wände um. Mittelgang (|x| < 30) bleibt frei für Puppen und Laufwege.
local map = workspace:WaitForChild("Map")
local zones = map:WaitForChild("Zones")
local pillowAssets = game.ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pillows")
local C = Color3.fromRGB
local rng = Random.new(1612)

local function part(props, parent, shape)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	if shape then
		p.Shape = shape
	end
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function ball(pos, size, color, parent, material)
	return part({
		Size = Vector3.one * size,
		Position = pos,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, parent, Enum.PartType.Ball)
end

-- Zylinder stehend (Roblox-Zylinder liegen entlang X → um Z drehen)
local function column(pos, height, diameter, color, parent, material)
	return part({
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}, parent, Enum.PartType.Cylinder)
end

local function light(parent: BasePart, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
end

-- Kissen-Requisite aus den generierten Modellen
local function pillowProp(id, cf, scale, parent)
	local tpl = pillowAssets:FindFirstChild(id)
	if not tpl then
		return
	end
	local p = tpl:Clone()
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Size *= scale
	p.CFrame = cf
	for _, d in p:GetChildren() do
		d:Destroy()
	end
	p.Parent = parent
end

local function recolor(room, floorColor, wallColor, floorMaterial)
	for _, d in room:GetChildren() do
		if d:IsA("BasePart") then
			if d.Name == "Floor" then
				d.Color = floorColor
				d.Material = floorMaterial or d.Material
			elseif d.Name:sub(1, 4) == "Wall" then
				d.Color = wallColor
				d.Material = Enum.Material.SmoothPlastic
			end
		end
	end
end

-- Lichterkette an beiden Seitenwänden
local function stringLights(cz, colors, parent)
	for _, x in { -68.4, 68.4 } do
		part({
			Name = "Wire",
			Size = Vector3.new(0.2, 0.2, 136),
			Position = Vector3.new(x, 19, cz),
			Color = C(80, 70, 70),
			CanCollide = false,
		}, parent)
		local i = 0
		for z = cz - 66, cz + 66, 6 do
			i += 1
			local sag = math.sin((z - cz) / 6 * math.pi) * 0.6
			local b = ball(Vector3.new(x, 18.3 - math.abs(sag), z), 0.9, colors[(i % #colors) + 1], parent, Enum.Material.Neon)
			b.CanCollide = false
			if i % 4 == 0 then
				light(b, colors[1], 14, 0.7)
			end
		end
	end
end

local function makeDecor(roomName)
	local room = zones:FindFirstChild(roomName)
	assert(room, "Zone fehlt: " .. roomName .. " (erst build_graybox_zones.luau ausführen)")
	local old = room:FindFirstChild("Decor")
	if old then
		old:Destroy()
	end
	local decor = Instance.new("Model")
	decor.Name = "Decor"
	decor.Parent = room
	return room, decor
end

-- ---------- Cozy Bedroom (Pastellblau, Holz, Sternchen) – Startzone, erster Eindruck ----------
do
	local room, decor = makeDecor("Bedroom")
	recolor(room, C(214, 180, 140), C(170, 196, 232), Enum.Material.WoodPlanks)
	local wood = C(214, 170, 120)
	-- Nachtfenster an der Rückwand mit Mond und Sternen
	local win = Instance.new("Model")
	win.Name = "NightWindow"
	win.Parent = decor
	part({ Size = Vector3.new(26, 16, 0.8), Position = Vector3.new(25, 12, -68.7), Color = wood, Material = Enum.Material.Wood }, win)
	part({ Size = Vector3.new(23, 13, 0.3), Position = Vector3.new(25, 12, -68.2), Color = C(40, 50, 110), Material = Enum.Material.SmoothPlastic }, win)
	part({ Size = Vector3.new(0.6, 13, 0.4), Position = Vector3.new(25, 12, -68), Color = wood, Material = Enum.Material.Wood }, win)
	part({ Size = Vector3.new(23, 0.6, 0.4), Position = Vector3.new(25, 12, -68), Color = wood, Material = Enum.Material.Wood }, win)
	local moon = ball(Vector3.new(30, 15.5, -68), 3, C(255, 245, 210), win, Enum.Material.Neon)
	moon.Size = Vector3.new(3, 3, 0.4)
	for _ = 1, 9 do
		local st = ball(Vector3.new(rng:NextNumber(14.5, 35.5), rng:NextNumber(6.5, 17.5), -68), 0.5, C(255, 236, 160), win, Enum.Material.Neon)
		st.Size = Vector3.new(0.5, 0.5, 0.3)
	end
	-- Leucht-Sternchen an den Seitenwänden
	for _ = 1, 22 do
		local x = if rng:NextNumber() < 0.5 then -68.7 else 68.7
		local st = ball(Vector3.new(x, rng:NextNumber(11, 21), rng:NextNumber(-62, 62)), rng:NextNumber(0.6, 1.1), C(255, 236, 160), decor, Enum.Material.Neon)
		st.CanCollide = false
	end
	-- Bücherregal an der rechten Wand
	local shelf = Instance.new("Model")
	shelf.Name = "Bookshelf"
	shelf.Parent = decor
	part({ Size = Vector3.new(4, 14, 18), Position = Vector3.new(66, 7, 22), Color = wood, Material = Enum.Material.Wood }, shelf)
	local bookColors = { C(255, 143, 177), C(127, 216, 255), C(126, 224, 138), C(255, 226, 122), C(196, 140, 255) }
	for row = 0, 2 do
		local z = 14
		local i = 0
		while z < 30 do
			i += 1
			local w = rng:NextNumber(0.9, 1.6)
			local h = rng:NextNumber(2.6, 3.6)
			part({ Size = Vector3.new(3, h, w), Position = Vector3.new(63.4, 1.2 + row * 4.4 + h / 2, z + w / 2), Color = bookColors[(i + row) % #bookColors + 1] }, shelf)
			z += w + 0.15
		end
	end
	-- Kissenhaufen neben dem Bett (Hinweis aufs Spielthema)
	for i = 1, 7 do
		local id = if i % 2 == 0 then "worn" else "cotton"
		local pos = Vector3.new(rng:NextNumber(-62, -48), 1.2 + (i // 4) * 1.8, rng:NextNumber(-28, -18))
		pillowProp(id, CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3)), 2.2, decor)
	end
	-- Spielteppich-Wege (Rennbahn) vor dem Spawn, flach
	part({ Size = Vector3.new(0.25, 18, 18), CFrame = CFrame.new(-40, 0.12, 30) * CFrame.Angles(0, 0, math.rad(90)), Color = C(126, 224, 138), Material = Enum.Material.Fabric, CanCollide = false }, decor, Enum.PartType.Cylinder)
	part({ Size = Vector3.new(0.25, 14, 14), CFrame = CFrame.new(45, 0.12, 40) * CFrame.Angles(0, 0, math.rad(90)), Color = C(255, 226, 122), Material = Enum.Material.Fabric, CanCollide = false }, decor, Enum.PartType.Cylinder)
end

-- ---------- Lounge (Pfirsich, Lichterketten-Gelb) ----------
do
	local room, decor = makeDecor("Lounge")
	local cz = 140
	recolor(room, C(222, 168, 128), C(255, 196, 170), Enum.Material.WoodPlanks)
	part({
		Name = "Rug",
		Size = Vector3.new(0.3, 46, 46),
		CFrame = CFrame.new(0, 0.1, cz + 8) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C(255, 236, 160),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}, decor, Enum.PartType.Cylinder)
	stringLights(cz, { C(255, 226, 122), C(255, 160, 190), C(255, 200, 120) }, decor)
	-- Sofas an der linken Wand
	for _, z in { cz - 32, cz + 30 } do
		local sofa = Instance.new("Model")
		sofa.Name = "Sofa"
		sofa.Parent = decor
		local coral = C(255, 140, 130)
		part({ Size = Vector3.new(9, 3, 22), Position = Vector3.new(-62, 1.5, z), Color = coral, Material = Enum.Material.Fabric }, sofa)
		part({ Size = Vector3.new(3, 7, 22), Position = Vector3.new(-66, 3.5, z), Color = coral, Material = Enum.Material.Fabric }, sofa)
		for _, dz in { -11, 11 } do
			part({ Size = Vector3.new(9, 5, 2.5), Position = Vector3.new(-62, 2.5, z + dz), Color = C(240, 120, 115), Material = Enum.Material.Fabric }, sofa)
		end
		for k, id in { "fluffy", "heart", "sleepover" } do
			pillowProp(id, CFrame.new(-63, 4.8, z - 7 + (k - 1) * 7) * CFrame.Angles(0, math.rad(90), math.rad(-15)), 1.7, sofa)
		end
	end
	-- Sitzsäcke rechts
	local beanColors = { C(255, 170, 120), C(140, 210, 255), C(200, 160, 255), C(255, 226, 122) }
	for i = 1, 5 do
		local pos = Vector3.new(rng:NextNumber(42, 62), 2.2, cz - 55 + (i - 1) * 26 + rng:NextNumber(-3, 3))
		local b = ball(pos, 6, beanColors[(i % #beanColors) + 1], decor, Enum.Material.Fabric)
		b.Size = Vector3.new(7, 4.6, 7)
	end
	-- Kissenberg (Pillow Fight!) in der hinteren rechten Ecke
	local ids = { "cotton", "striped", "fluffy", "heart", "sleepover", "worn" }
	for i = 1, 16 do
		local pos = Vector3.new(rng:NextNumber(46, 64), 1.2 + (i // 5) * 1.8, rng:NextNumber(cz + 44, cz + 62))
		local cf = CFrame.new(pos) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4))
		pillowProp(ids[(i % #ids) + 1], cf, 2.2, decor)
	end
	-- Deckenburg (Zelt aus zwei Keilen) mit Kissen davor
	local fort = Instance.new("Model")
	fort.Name = "BlanketFort"
	fort.Parent = decor
	local blanket = C(130, 190, 255)
	for _, side in { -1, 1 } do
		local w = Instance.new("WedgePart")
		w.Anchored = true
		w.Size = Vector3.new(16, 10, 7)
		w.Color = blanket
		w.Material = Enum.Material.Fabric
		w.CFrame = CFrame.new(52, 5, cz - 4 + side * 3.5) * CFrame.Angles(0, if side == 1 then math.rad(180) else 0, 0)
		w.Parent = fort
	end
	for k, id in { "striped", "cotton", "fluffy" } do
		pillowProp(id, CFrame.new(42.5, 1.3, cz - 9 + (k - 1) * 5) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), 2, fort)
	end
	-- verstreute Bodenkissen
	for i = 1, 8 do
		local side = if i % 2 == 0 then 1 else -1
		local pos = Vector3.new(side * rng:NextNumber(32, 44), 0.9, rng:NextNumber(cz - 60, cz + 60))
		pillowProp(ids[(i % #ids) + 1], CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), 1.8, decor)
	end
	-- Pizza-Karton + Snack-Tisch links vorne
	part({ Size = Vector3.new(8, 2.5, 8), Position = Vector3.new(-48, 1.25, cz - 58), Color = C(205, 160, 120), Material = Enum.Material.Wood }, decor)
	part({ Size = Vector3.new(4, 0.5, 4), Position = Vector3.new(-48, 2.75, cz - 58), Color = C(250, 240, 225) }, decor)
end

-- ---------- Grand Hotel Suite (Bordeaux, Gold, Creme) ----------
do
	local room, decor = makeDecor("HotelSuite")
	local cz = 280
	local gold = C(255, 196, 60)
	local bordeaux = C(120, 30, 50)
	local cream = C(255, 240, 220)
	recolor(room, bordeaux, cream, Enum.Material.Fabric)
	-- roter Läufer im Mittelgang
	part({ Name = "Runner", Size = Vector3.new(10, 0.2, 130), Position = Vector3.new(0, 0.1, cz), Color = C(170, 30, 45), Material = Enum.Material.Fabric, CanCollide = false }, decor)
	for _, x in { -5.3, 5.3 } do
		part({ Size = Vector3.new(0.6, 0.25, 130), Position = Vector3.new(x, 0.12, cz), Color = gold, Material = Enum.Material.Metal, CanCollide = false }, decor)
	end
	-- Goldsäulen
	for _, x in { -60, 60 } do
		for _, dz in { -45, 0, 45 } do
			local pos = Vector3.new(x, 11, cz + dz)
			column(pos, 22, 3, gold, decor, Enum.Material.Metal)
			part({ Size = Vector3.new(5, 1.2, 5), Position = Vector3.new(x, 0.6, cz + dz), Color = cream }, decor)
			part({ Size = Vector3.new(5, 1.2, 5), Position = Vector3.new(x, 21.4, cz + dz), Color = cream }, decor)
		end
	end
	-- Kronleuchter
	local center = Vector3.new(0, 19, cz + 5)
	local hub = ball(center, 2.2, gold, decor, Enum.Material.Neon)
	hub.CanCollide = false
	light(hub, C(255, 220, 160), 40, 1.2)
	for i = 1, 10 do
		local a = i / 10 * math.pi * 2
		local b = ball(center + Vector3.new(math.cos(a) * 5, -1.5, math.sin(a) * 5), 0.9, C(255, 240, 200), decor, Enum.Material.Neon)
		b.CanCollide = false
	end
	part({ Size = Vector3.new(0.3, 4, 0.3), Position = center + Vector3.new(0, 2.5, 0), Color = gold, Material = Enum.Material.Metal, CanCollide = false }, decor)
	-- Himmelbett rechts
	local bed = Instance.new("Model")
	bed.Name = "GrandBed"
	bed.Parent = decor
	part({ Size = Vector3.new(22, 3.5, 26), Position = Vector3.new(52, 1.75, cz - 20), Color = cream, Material = Enum.Material.Fabric }, bed)
	part({ Size = Vector3.new(22, 1.2, 26), Position = Vector3.new(52, 4.1, cz - 20), Color = C(255, 250, 240), Material = Enum.Material.Fabric }, bed)
	part({ Size = Vector3.new(2, 12, 28), Position = Vector3.new(64, 6, cz - 20), Color = bordeaux, Material = Enum.Material.Fabric }, bed)
	part({ Size = Vector3.new(2.4, 1, 28.4), Position = Vector3.new(64, 12.3, cz - 20), Color = gold, Material = Enum.Material.Metal }, bed)
	for k, id in { "hotel", "royal", "satin", "hotel" } do
		pillowProp(id, CFrame.new(60.5, 5.6, cz - 29 + (k - 1) * 6) * CFrame.Angles(0, math.rad(90), math.rad(-20)), 1.3, bed)
	end
	-- Gepäckwagen links
	local cart = Instance.new("Model")
	cart.Name = "LuggageCart"
	cart.Parent = decor
	part({ Size = Vector3.new(6, 0.6, 10), Position = Vector3.new(-50, 1.2, cz + 30), Color = gold, Material = Enum.Material.Metal }, cart)
	for _, dz in { -4.6, 4.6 } do
		part({ Size = Vector3.new(0.5, 9, 0.5), Position = Vector3.new(-50, 5.5, cz + 30 + dz), Color = gold, Material = Enum.Material.Metal }, cart)
	end
	part({ Size = Vector3.new(0.5, 0.5, 9.7), Position = Vector3.new(-50, 10, cz + 30), Color = gold, Material = Enum.Material.Metal }, cart)
	local suitcases = { { C(70, 110, 160), 4 }, { C(150, 90, 60), 3.2 }, { C(200, 70, 90), 2.6 } }
	local y = 1.5
	for _, s in suitcases do
		part({ Size = Vector3.new(4.5, s[2], 7), Position = Vector3.new(-50, y + s[2] / 2, cz + 30), Color = s[1], Material = Enum.Material.Leather }, cart)
		y += s[2]
	end
	-- Sessel + Beistelltisch links hinten
	for _, dz in { -6, 6 } do
		part({ Size = Vector3.new(6, 3, 6), Position = Vector3.new(-58, 1.5, cz - 35 + dz), Color = bordeaux, Material = Enum.Material.Fabric }, decor)
		part({ Size = Vector3.new(2, 6, 6), Position = Vector3.new(-62, 3, cz - 35 + dz), Color = bordeaux, Material = Enum.Material.Fabric }, decor)
	end
	column(Vector3.new(-56, 1.5, cz - 35), 3, 4, gold, decor, Enum.Material.Metal)
end

-- ---------- Cloud Kingdom (Weiß, Lavendel, Mondsilber) ----------
do
	local room, decor = makeDecor("CloudKingdom")
	local cz = 420
	recolor(room, C(248, 248, 255), C(205, 195, 255), Enum.Material.SmoothPlastic)
	-- Wolkenhaufen an den Seiten
	local cloudSpots = {
		Vector3.new(-56, 0, cz - 50), Vector3.new(-58, 0, cz - 10), Vector3.new(-55, 0, cz + 35),
		Vector3.new(56, 0, cz - 45), Vector3.new(58, 0, cz + 5), Vector3.new(55, 0, cz + 50),
	}
	for _, base in cloudSpots do
		local cloud = Instance.new("Model")
		cloud.Name = "Cloud"
		cloud.Parent = decor
		for _ = 1, 6 do
			local s = rng:NextNumber(5, 10)
			ball(base + Vector3.new(rng:NextNumber(-6, 6), s * 0.35 + rng:NextNumber(0, 2), rng:NextNumber(-7, 7)), s, C(255, 255, 255), cloud)
		end
	end
	-- Schwebende Wolken (hoch, ohne Kollision)
	for i = 1, 6 do
		local pos = Vector3.new(rng:NextNumber(-55, 55), rng:NextNumber(14, 19), cz - 60 + i * 18)
		for _ = 1, 3 do
			local b = ball(pos + Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-0.5, 0.5), rng:NextNumber(-2, 2)), rng:NextNumber(3, 5), C(240, 236, 255), decor)
			b.CanCollide = false
			b.Transparency = 0.1
		end
	end
	-- Mond an der Rückwand
	local moon = ball(Vector3.new(36, 17, cz + 64), 16, C(235, 235, 250), decor, Enum.Material.Neon)
	moon.CanCollide = false
	light(moon, C(210, 200, 255), 50, 1.4)
	local bite = ball(Vector3.new(31, 19, cz + 61), 15, C(205, 195, 255), decor)
	bite.CanCollide = false
	-- Sterne
	for _ = 1, 32 do
		local side = if rng:NextNumber() < 0.5 then -68.6 else 68.6
		local pos = if rng:NextNumber() < 0.7
			then Vector3.new(side, rng:NextNumber(10, 22), rng:NextNumber(cz - 66, cz + 66))
			else Vector3.new(rng:NextNumber(-60, 60), rng:NextNumber(12, 22), cz + 68.6)
		local s = ball(pos, rng:NextNumber(0.5, 1.1), C(255, 236, 160), decor, Enum.Material.Neon)
		s.CanCollide = false
	end
	-- Thron aus Kissen (Ziel des Endgames) an der Rückwand links
	local throne = Instance.new("Model")
	throne.Name = "PillowThrone"
	throne.Parent = decor
	part({ Size = Vector3.new(14, 4, 10), Position = Vector3.new(-36, 2, cz + 58), Color = C(205, 195, 255), Material = Enum.Material.Fabric }, throne)
	part({ Size = Vector3.new(14, 14, 3), Position = Vector3.new(-36, 9, cz + 63), Color = C(180, 165, 250), Material = Enum.Material.Fabric }, throne)
	for k, id in { "starlight", "dream", "cloud" } do
		pillowProp(id, CFrame.new(-41 + (k - 1) * 5, 6.2, cz + 59) * CFrame.Angles(math.rad(-15), 0, 0), 2.2, throne)
	end
end

-- ---------- Durchgänge: Vorhang statt Kraftfeld (Farbe der Zielzone) ----------
-- Die Barriere selbst wird zum Vorhang (lokal unsichtbar, sobald freigeschaltet – ZoneController);
-- Stange und Seitenschals bleiben als Türrahmen stehen.
do
	local CS = game:GetService("CollectionService")
	local curtainColors = {
		livingroom = C(255, 150, 130),
		hotelsuite = C(150, 35, 60),
		cloudrealm = C(180, 165, 250),
	}
	for _, b in CS:GetTagged("ZoneBarrier") do
		local target = b:GetAttribute("ZoneId")
		local color = curtainColors[target]
		local decor = b.Parent and b.Parent:FindFirstChild("Decor")
		if b:IsA("BasePart") and color and decor then
			b.Material = Enum.Material.Fabric
			b.Color = color
			b.Transparency = 0
			b:SetAttribute("LockedTransparency", 0)
			-- Preisschild zur Seite, von der Spieler kommen (−Z = Front; BUG-003: war Back)
			local sg = b:FindFirstChildOfClass("SurfaceGui")
			if sg then
				sg.Face = Enum.NormalId.Front
			end
			local frame = Instance.new("Model")
			frame.Name = "Doorway_" .. target
			frame.Parent = decor
			local z = b.Position.Z - 1.4
			local rod = part({
				Size = Vector3.new(38, 0.8, 0.8),
				CFrame = CFrame.new(0, 16.6, z),
				Color = C(255, 196, 60),
				Material = Enum.Material.Metal,
				CanCollide = false,
			}, frame, Enum.PartType.Cylinder)
			rod.Name = "Rod"
			for _, side in { -1, 1 } do
				-- Seitenschal: drei leicht versetzte Bahnen für Faltenwurf
				for k = 0, 2 do
					part({
						Name = "Drape",
						Size = Vector3.new(1.4, 16.2, 0.8),
						Position = Vector3.new(side * (15.6 + k * 1.2), 8.1, z - k * 0.15),
						Color = color:Lerp(Color3.new(0, 0, 0), 0.12 + k * 0.06),
						Material = Enum.Material.Fabric,
						CanCollide = false,
					}, frame)
				end
				ball(Vector3.new(side * 19.5, 16.6, z), 1.4, C(255, 196, 60), frame, Enum.Material.Metal).CanCollide = false
			end
			-- Raffhalter (Schleifenband) auf Hüfthöhe
			for _, side in { -1, 1 } do
				part({
					Name = "Tieback",
					Size = Vector3.new(4, 0.5, 1),
					Position = Vector3.new(side * 16.8, 6, z - 0.5),
					Color = C(255, 226, 122),
					Material = Enum.Material.Fabric,
					CanCollide = false,
				}, frame)
			end
		end
	end
end

local n = 0
for _, z in zones:GetChildren() do
	local d = z:FindFirstChild("Decor")
	if d then
		for _, p in d:GetDescendants() do
			if p:IsA("BasePart") then
				n += 1
			end
		end
	end
end
return ("Dekor gebaut: %d Teile"):format(n)
