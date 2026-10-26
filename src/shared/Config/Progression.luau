--!strict
-- GENERIERT aus tools/economy-sim/content.py – nicht von Hand bearbeiten.
-- Werte ändern: content.py anpassen, gen_config.py ausführen, sim.py --check.

return table.freeze({
	swing = { baseCooldown = 0.6, minCooldown = 0.3, latencyTolerance = 0.08, autoSwingEfficiency = 0.8, autoSwingRank = 2, dummyBonus = 1.5, dummyRange = 9 },
	upgrades = {
		featherPower = { name = "Feather Power", baseCost = 5, growth = 1.28, bonusPerLevel = 0.25, maxLevel = 100 },
		swingSpeed = { name = "Swing Speed", baseCost = 100, growth = 4.0, cooldownPerLevel = 0.05, maxLevel = 6 },
	},
	rebirth = { baseCost = 80000000, costGrowth = 6.0, bonusPerRebirth = 0.5, softcapAfter = 10, bonusAfterSoftcap = 0.25 },
	ranks = {
		{ name = "Sleepyhead", lifetimeFeathers = 0, bonus = 0.0 },
		{ name = "Pillow Rookie", lifetimeFeathers = 500, bonus = 0.03 },
		{ name = "Feather Fighter", lifetimeFeathers = 25000, bonus = 0.06 },
		{ name = "Fluff Brawler", lifetimeFeathers = 500000, bonus = 0.09 },
		{ name = "Cushion Champion", lifetimeFeathers = 8000000, bonus = 0.12 },
		{ name = "Duvet Duke", lifetimeFeathers = 150000000, bonus = 0.15 },
		{ name = "Slumber Knight", lifetimeFeathers = 2000000000, bonus = 0.18 },
		{ name = "Dream Warden", lifetimeFeathers = 30000000000, bonus = 0.21 },
		{ name = "Night Sovereign", lifetimeFeathers = 400000000000, bonus = 0.25 },
		{ name = "Pillow Legend", lifetimeFeathers = 5000000000000, bonus = 0.3 },
	},
})
