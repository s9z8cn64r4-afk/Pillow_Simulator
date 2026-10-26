--!strict
-- GENERIERT aus tools/economy-sim/content.py – nicht von Hand bearbeiten.
-- Werte ändern: content.py anpassen, gen_config.py ausführen, sim.py --check.

return table.freeze({
	daily = {
		{
			day = 1,
			kind = "feathersMinutes",
			amount = 3,
		},
		{
			day = 2,
			kind = "boost",
			boost = "feathers2x",
			minutes = 10,
		},
		{
			day = 3,
			kind = "feathersMinutes",
			amount = 6,
		},
		{
			day = 4,
			kind = "boost",
			boost = "feathers2x",
			minutes = 15,
		},
		{
			day = 5,
			kind = "feathersMinutes",
			amount = 10,
		},
		{
			day = 6,
			kind = "boost",
			boost = "feathers2x",
			minutes = 20,
		},
		{
			day = 7,
			kind = "feathersMinutes",
			amount = 20,
		},
	},
	social = {
		friendBonusPerFriend = 0.1,
		friendBonusMax = 0.3,
		groupBonus = 0.1,
	},
	boosts = {
		feathers2x = {
			name = "2x Feathers",
			multiplier = 2.0,
			maxStackMinutes = 120,
		},
	},
})
