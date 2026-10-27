-- In Studio (Edit) per execute_luau ausführen, nachdem generate_mesh Modelle in den Workspace gelegt hat.
-- Ordnet Modelle anhand eines Schlüsselworts im Prompt-Namen einer Kissen-ID zu, skaliert auf 2,4 Studs Länge
-- (längste horizontale Achse) und legt das MeshPart als ReplicatedStorage.Assets.Pillows.<id> ab (ersetzt vorhandene).
local KEYS = {
	{ "cotton", "cotton" },
	{ "stripes", "striped" },
	{ "mint", "fluffy" },
	{ "sleepover", "sleepover" },
	{ "heart", "heart" },
	{ "satin pillow", "satin" },
	{ "hotel", "hotel" },
	{ "velvet", "royal" },
	{ "memory foam", "memoryfoam" },
	{ "cloud with", "cloud" },
	{ "storm", "thunder" },
	{ "night-sky", "starlight" },
	{ "dreamweaver", "dream" },
}
local TARGET_LENGTH = 2.4
local folder = game.ReplicatedStorage.Assets.Pillows
local done = {}
for _, m in workspace:GetChildren() do
	if m:IsA("Model") then
		local lname = m.Name:lower()
		local id
		for _, k in KEYS do
			if lname:find(k[1], 1, true) then
				id = k[2]
				break
			end
		end
		local mp = m:FindFirstChildWhichIsA("MeshPart", true)
		if id and mp then
			local s = mp.Size
			mp:SetAttribute("RawSize", s)
			-- gleichmäßig skalieren (Größe tauschen würde das Mesh verzerren; Längsachse Z wird gemeldet)
			local scaled = s * (TARGET_LENGTH / math.max(s.X, s.Z))
			-- Höhe begrenzen, damit würfelige Generierungen als Kissen lesbar bleiben
			mp.Size = Vector3.new(scaled.X, math.clamp(scaled.Y, 0.9, 1.3), scaled.Z)
			if s.Z > s.X * 1.15 then -- nur bei deutlich längerer Z-Achse (fast quadratisch = egal)
				mp:SetAttribute("LongAxisZ", true)
			end
			mp.Name = id
			mp.Anchored = false
			mp.CanCollide = false
			mp.CanTouch = false
			mp.CanQuery = false
			mp.Massless = true
			mp:SetAttribute("Source", "generate_mesh 2026-10-27: " .. m.Name)
			local old = folder:FindFirstChild(id)
			if old then
				old:Destroy()
			end
			mp.Parent = folder
			m:Destroy()
			table.insert(done, id .. " " .. tostring(mp.Size))
		end
	end
end
return table.concat(done, "; ")
