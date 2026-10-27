--!strict
-- Konsistenz der generierten Config
local Shared = game:GetService("ReplicatedStorage").Shared
local Pillows = require(Shared.Config.Pillows)
local Zones = require(Shared.Config.Zones)
local Progression = require(Shared.Config.Progression)
local PlayerData = require(Shared.Types.PlayerData)

return function(it, expect)
	it("Kissen: aufsteigende Power und Preise, gültige Zonen/Seltenheiten", function()
		local rar = {}
		for _, r in Pillows.rarities do
			rar[r.id] = true
		end
		for i, p in Pillows.list do
			expect(Zones.byId[p.zone] ~= nil).toBeTruthy()
			expect(rar[p.rarity]).toBeTruthy()
			if i > 1 then
				expect(p.power).toBeGreaterThan(Pillows.list[i - 1].power)
				expect(p.cost).toBeGreaterThan(Pillows.list[i - 1].cost)
			end
		end
		expect(Pillows.byId[Pillows.starter].cost).toBe(0)
	end)
	it("Ranks aufsteigend, Rank 1 bei 0", function()
		expect(Progression.ranks[1].lifetimeFeathers).toBe(0)
		for i = 2, #Progression.ranks do
			expect(Progression.ranks[i].lifetimeFeathers).toBeGreaterThan(
				Progression.ranks[i - 1].lifetimeFeathers
			)
		end
	end)
	it("Template: Startkissen besessen, Startzone offen", function()
		local t = PlayerData.TEMPLATE
		expect(t.ownedPillows[Pillows.starter]).toBe(true)
		expect(t.unlockedZones[Zones.start]).toBe(true)
		expect(t.equippedPillow).toBe(Pillows.starter)
	end)
end
