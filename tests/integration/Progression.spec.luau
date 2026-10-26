--!strict
-- Integration: Zonen-Freischaltung, Zonen-Erkennung, Rebirth. Sichert und stellt den Spielerstand wieder her.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local ZoneSvc = reg.ZoneService
	local Rebirth = reg.RebirthService
	local Stats = reg.StatsService
	local Formulas = require(game:GetService("ReplicatedStorage").Shared.Util.Formulas)

	local data = PD:get(player)
	local backup = {
		feathers = data.feathers,
		rebirths = data.rebirths,
		upgrades = table.clone(data.upgrades),
		unlockedZones = table.clone(data.unlockedZones),
		ownedPillows = table.clone(data.ownedPillows),
		autoSwingEnabled = data.autoSwingEnabled,
	}
	data.autoSwingEnabled = false
	data.unlockedZones = { bedroom = true }
	data.rebirths = 0

	it("Zone kaufen: zu wenig Federn → abgelehnt", function()
		data.feathers = 10
		local ok, why = ZoneSvc:unlock(player, "livingroom")
		expect(ok).toBeFalsy()
		expect(why).toBe("notEnough")
	end)

	it("Zonen nur in Reihenfolge", function()
		data.feathers = 1e12
		local ok, why = ZoneSvc:unlock(player, "hotelsuite")
		expect(ok).toBeFalsy()
		expect(why).toBe("previousLocked")
	end)

	it("Zone kaufen mit genug Federn, Doppelkauf abgelehnt", function()
		data.feathers = 100000
		expect((ZoneSvc:unlock(player, "livingroom"))).toBeTruthy()
		expect(data.unlockedZones.livingroom).toBe(true)
		expect(data.feathers).toBeNear(25000)
		local ok, why = ZoneSvc:unlock(player, "livingroom")
		expect(ok).toBeFalsy()
		expect(why).toBe("owned")
	end)

	it("Cloud Kingdom braucht Rebirth 1", function()
		data.feathers = 1e12
		expect((ZoneSvc:unlock(player, "hotelsuite"))).toBeTruthy()
		local ok, why = ZoneSvc:unlock(player, "cloudrealm")
		expect(ok).toBeFalsy()
		expect(why).toBe("rebirthLocked")
	end)

	it("Zonen-Erkennung: Multiplikator nur in freigeschalteter Zone", function()
		expect((ZoneSvc:teleport(player, "livingroom"))).toBeTruthy()
		task.wait(0.8)
		expect(Stats.currentZone[player]).toBe("livingroom")
		-- in gesperrte Zone versetzen (Cloud Kingdom) → kein Zonen-Multiplikator
		local cf = ZoneSvc:spawnCFrame("cloudrealm")
		player.Character:PivotTo(cf)
		task.wait(0.8)
		expect(Stats.currentZone[player]).toBe(nil)
		expect(Stats:zoneOf(player)).toBe("bedroom")
	end)

	it("Teleport in gesperrte Zone abgelehnt", function()
		local ok, why = ZoneSvc:teleport(player, "cloudrealm")
		expect(ok).toBeFalsy()
		expect(why).toBe("zoneLocked")
	end)

	it("Rebirth: zu wenig Federn → abgelehnt", function()
		data.feathers = 10
		local ok, why = Rebirth:rebirth(player)
		expect(ok).toBeFalsy()
		expect(why).toBe("notEnough")
	end)

	it("Rebirth: Reset von Federn/Upgrades/Zonen, Kissen bleiben, Rebirths +1", function()
		data.feathers = Formulas.rebirthCost(0)
		data.upgrades = { featherPower = 7, swingSpeed = 2 }
		data.ownedPillows = { worn = true, cotton = true }
		expect((Rebirth:rebirth(player))).toBeTruthy()
		expect(data.rebirths).toBe(1)
		expect(data.feathers).toBe(0)
		expect(data.upgrades.featherPower).toBe(0)
		expect(data.upgrades.swingSpeed).toBe(0)
		expect(data.unlockedZones.livingroom == nil).toBeTruthy()
		expect(data.unlockedZones.bedroom).toBe(true)
		expect(data.ownedPillows.cotton).toBe(true)
	end)

	-- Stand wiederherstellen
	for k, v in backup do
		data[k] = v
	end
	PD:markChanged(player, "feathers", "rebirths", "upgrades", "unlockedZones", "ownedPillows", "autoSwingEnabled")
	ZoneSvc:teleport(player, "bedroom")
end
