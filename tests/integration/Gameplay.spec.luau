--!strict
-- Integration im Play-Modus mit echtem Spieler. Sichert und stellt den Spielerstand wieder her.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local Shop = reg.ShopService
	local Swing = reg.SwingService
	local Stats = reg.StatsService

	local data = PD:get(player)
	local backup = {
		feathers = data.feathers,
		lifetimeFeathers = data.lifetimeFeathers,
		ownedPillows = table.clone(data.ownedPillows),
		equippedPillow = data.equippedPillow,
		upgrades = table.clone(data.upgrades),
		rank = data.rank,
		autoSwingEnabled = data.autoSwingEnabled,
	}
	data.autoSwingEnabled = false

	it("Schlag gibt Federn, zweiter Schlag sofort danach wird abgelehnt", function()
		task.wait(1) -- Cooldown seit letztem Schlag sicher abgelaufen
		local before = data.feathers
		local expected = Stats:feathersPerSwing(player)
		local t = os.clock()
		expect(Swing:requestSwing(player, t)).toBeTruthy()
		local gained = data.feathers - before
		expect(gained >= expected - 1e-9).toBeTruthy()
		expect(Swing:requestSwing(player, t + 0.05)).toBeFalsy()
	end)

	it("Kauf ohne genug Federn scheitert", function()
		data.feathers = 0
		data.ownedPillows = { worn = true }
		local ok, why = Shop:buyPillow(player, "cotton")
		expect(ok).toBeFalsy()
		expect(why).toBe("notEnough")
	end)

	it("Kauf mit genug Federn: besessen, ausgerüstet, Federn abgezogen", function()
		data.feathers = 100
		local ok = Shop:buyPillow(player, "cotton")
		expect(ok).toBeTruthy()
		expect(data.ownedPillows.cotton).toBe(true)
		expect(data.equippedPillow).toBe("cotton")
		expect(data.feathers).toBeNear(25)
	end)

	it("Doppelkauf wird abgelehnt", function()
		data.feathers = 1000
		local ok, why = Shop:buyPillow(player, "cotton")
		expect(ok).toBeFalsy()
		expect(why).toBe("owned")
		expect(data.feathers).toBeNear(1000)
	end)

	it("Kissen aus gesperrter Zone wird abgelehnt", function()
		data.feathers = 1e12
		local ok, why = Shop:buyPillow(player, "sleepover")
		expect(ok).toBeFalsy()
		expect(why).toBe("zoneLocked")
		local ok2, why2 = Shop:buyPillow(player, "memoryfoam")
		expect(ok2).toBeFalsy()
		expect(why2 == "zoneLocked" or why2 == "rebirthLocked").toBeTruthy()
	end)

	it("Ausrüsten nur besessener Kissen", function()
		local ok, why = Shop:equipPillow(player, "royal")
		expect(ok).toBeFalsy()
		expect(why).toBe("notOwned")
	end)

	it("Upgrade-Kauf erhöht Stufe und zieht Kosten ab", function()
		data.upgrades = { featherPower = 0, swingSpeed = 0 }
		data.feathers = 5
		expect((Shop:buyUpgrade(player, "featherPower"))).toBeTruthy()
		expect(data.upgrades.featherPower).toBe(1)
		expect(data.feathers).toBeNear(0)
		expect((Shop:buyUpgrade(player, "swingSpeed"))).toBeFalsy()
	end)

	it("Rank steigt mit lebenslangen Federn", function()
		data.lifetimeFeathers = 0
		data.rank = 1
		PD:addFeathers(player, 600)
		expect(data.rank).toBe(2)
	end)

	it("ProfileStore: Schreiben und Neuladen eines Test-Profils", function()
		local store = PD:_storeForTest()
		local key = "Test_RoundTrip"
		local stamp = os.time() + math.random()
		local p1 = store:StartSessionAsync(key, { Cancel = function()
			return false
		end })
		expect(p1 ~= nil).toBeTruthy()
		p1.Data.feathers = stamp
		p1:EndSession()
		task.wait(1)
		local p2 = store:StartSessionAsync(key, { Cancel = function()
			return false
		end })
		expect(p2 ~= nil).toBeTruthy()
		expect(p2.Data.feathers).toBeNear(stamp)
		p2:EndSession()
	end)

	-- Stand wiederherstellen
	for k, v in backup do
		data[k] = v
	end
	PD:markChanged(player, "feathers", "lifetimeFeathers", "ownedPillows", "equippedPillow", "upgrades", "rank", "autoSwingEnabled")
	reg.PillowToolService:give(player) -- Werkzeug passend zum wiederhergestellten Kissen
end
