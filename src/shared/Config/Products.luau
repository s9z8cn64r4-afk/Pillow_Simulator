--!strict
-- GENERIERT aus tools/economy-sim/content.py – nicht von Hand bearbeiten.
-- Werte ändern: content.py anpassen, gen_config.py ausführen, sim.py --check.

-- robux = nil: Preis noch nicht vom Owner freigegeben; assetId/productId = 0: noch nicht angelegt.
return {
	gamepasses = {
		{ id = "doubleFeathers", name = "2x Feathers", multiplier = 2.0, robux = 149, assetId = 0 },
		{ id = "vip", name = "VIP", multiplier = 1.1, robux = 99, assetId = 0 },
		{ id = "fasterAutoSwing", name = "Better Auto-Swing", autoSwingEfficiency = 1.0, robux = 79, assetId = 0 },
	},
	devProducts = {
		{ id = "boost2x30", name = "2x Feathers (30 min)", boost = "feathers2x", minutes = 30, robux = 25, productId = 0 },
	},
}
