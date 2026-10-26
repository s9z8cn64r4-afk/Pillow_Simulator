--!strict
-- GENERIERT aus tools/economy-sim/content.py – nicht von Hand bearbeiten.
-- Werte ändern: content.py anpassen, gen_config.py ausführen, sim.py --check.

export type Zone = {
	id: string,
	name: string,
	multiplier: number,
	cost: number,
	rebirths: number,
	order: number,
}

local list: { Zone } = {
	{
		id = "bedroom",
		name = "Cozy Bedroom",
		multiplier = 1.0,
		cost = 0,
		rebirths = 0,
		order = 0,
	},
	{
		id = "livingroom",
		name = "Pajama Party Lounge",
		multiplier = 2.0,
		cost = 75000,
		rebirths = 0,
		order = 1,
	},
	{
		id = "hotelsuite",
		name = "Grand Hotel Suite",
		multiplier = 4.0,
		cost = 4000000,
		rebirths = 0,
		order = 2,
	},
	{
		id = "cloudrealm",
		name = "Cloud Kingdom",
		multiplier = 8.0,
		cost = 250000000,
		rebirths = 1,
		order = 3,
	},
}

local byId: { [string]: Zone } = {}
for _, z in list do
	byId[z.id] = z
end

return table.freeze({ list = table.freeze(list), byId = table.freeze(byId), start = "bedroom" })
