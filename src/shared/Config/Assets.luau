--!strict
-- Asset-IDs und Modellnamen (Art & Audio pflegt diese Datei; Herkunft/Lizenz in docs/art/asset-list.md).
-- Sounds: Roblox Creator Store, kostenlos, Ladeprüfung bestanden; Hörprobe durch Owner ausstehend.
-- Modelle liegen im Place unter ReplicatedStorage.Assets (generiert mit Studio-Mesh-Generierung).
return table.freeze({
	sounds = table.freeze({
		swing = { id = "rbxassetid://74924309961251", volume = 0.35, pitchVariation = 0.12 },
		hit = { id = "rbxassetid://74924309961251", volume = 0.6, pitchVariation = 0.08 },
		purchase = { id = "rbxassetid://4612374393", volume = 0.5, pitchVariation = 0 },
		rankUp = { id = "rbxassetid://103516326607012", volume = 0.6, pitchVariation = 0 },
		click = { id = "rbxassetid://88442833509532", volume = 0.4, pitchVariation = 0.05 },
	}),
	-- Hintergrundmusik (Roblox-Musikbibliothek „DistrokidOfficial“, für Experiences freigegeben), Playlist in Folge
	music = table.freeze({
		{ id = "rbxassetid://121736147160985", name = "Lofi Bakery R&B", volume = 0.45 },
		{ id = "rbxassetid://79718837116412", name = "Cheesecake Glow", volume = 0.45 },
		{ id = "rbxassetid://140517328454242", name = "innocent soft funny", volume = 0.4 },
	}),
	models = table.freeze({
		feather = "FeatherMesh", -- ReplicatedStorage.Assets.FeatherMesh
		pillowsFolder = "Pillows", -- ReplicatedStorage.Assets.Pillows.<pillowId> (MeshPart, X = Längsachse)
		-- Zusätzliche Griff-Drehung je Modell in Grad (X, Y, Z), geprüft per Screenshot (Frontansicht, 2026-10-27).
		-- Aufrecht generierte Modelle: Y 90 (Fläche nach vorn); flache Modelle: Fläche aufrichten.
		-- Nicht aufgeführt = Standardgriff passt (fluffy, royal, memoryfoam, striped).
		gripRotation = table.freeze({
			worn = { 0, 90, 0 },
			cotton = { 0, 90, 0 },
			sleepover = { 0, 90, 0 },
			satin = { 0, 90, 0 },
			hotel = { 0, 90, 0 },
			thunder = { 0, 90, 0 },
			dream = { 0, 90, 0 },
			cloud = { 0, 90, 0 },
			heart = { 90, 0, 90 },
			starlight = { 55, 0, 90 }, -- 90 würde den Kopf verdecken
		}),
	}),
})
