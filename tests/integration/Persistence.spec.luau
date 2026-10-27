--!strict
-- Integration: Persistenz-Stresstest (PS-39) gegen echten DataStore (DEV), nur Test-Schlüssel (Test_*).
-- Schnelle Sitzungswechsel, Doppel-Laden-Schutz, großer Spielstand, bestätigtes Speichern des echten Profils.
return function(it, expect, ctx)
	local PD = ctx.registry.PlayerDataService
	local player = ctx.player
	local store = PD:_storeForTest()

	local function start(key: string, timeout: number?)
		local deadline = os.clock() + (timeout or 30)
		return store:StartSessionAsync(key, {
			Cancel = function()
				return os.clock() > deadline
			end,
		})
	end

	it("8 schnelle Sitzungswechsel ohne Datenverlust", function()
		local key = "Test_RapidRejoin"
		local p0 = start(key)
		expect(p0 ~= nil).toBeTruthy()
		p0.Data.feathers = 0
		p0:EndSession()
		local t0 = os.clock()
		local lost = 0
		for i = 1, 8 do
			local p = start(key)
			if not p then
				lost += 100
				break
			end
			if p.Data.feathers ~= i - 1 then
				lost += 1
			end
			p.Data.feathers = i
			p:EndSession() -- sofort weiter, ohne Wartezeit
		end
		local final = start(key)
		expect(lost).toBe(0)
		expect(final ~= nil and final.Data.feathers).toBe(8)
		if final then
			final:EndSession()
		end
		print(("[PERSIST] 8 Wechsel in %.1f s"):format(os.clock() - t0))
	end)

	it("Doppel-Laden im selben Server wird verweigert, Daten bleiben erhalten", function()
		-- Echte Übernahme zwischen zwei Servern lässt sich in Studio nicht nachstellen → Beta-Test (TEST_RESULTS)
		local key = "Test_SessionSteal"
		local p1 = start(key)
		expect(p1 ~= nil).toBeTruthy()
		if not p1 then
			return
		end
		local stamp = os.time() + math.random()
		p1.Data.feathers = stamp
		local ok, err = pcall(start, key, 5)
		expect(ok).toBeFalsy()
		expect(string.find(tostring(err), "already loaded", 1, true) ~= nil).toBeTruthy()
		expect(p1:IsActive()).toBeTruthy()
		p1:EndSession()
		local p2 = start(key)
		expect(p2 and p2.Data.feathers).toBeNear(stamp)
		if p2 then
			p2:EndSession()
		end
	end)

	it("Großer Spielstand (1000 Quittungen, alle Kissen) speichert und lädt", function()
		local key = "Test_LargeProfile"
		local p1 = start(key)
		expect(p1 ~= nil).toBeTruthy()
		if not p1 then
			return
		end
		for i = 1, 1000 do
			p1.Data.purchaseHistory["receipt_" .. i .. "_" .. string.rep("x", 20)] = true
		end
		for _, pl in require(game:GetService("ReplicatedStorage").Shared.Config.Pillows).list do
			p1.Data.ownedPillows[pl.id] = true
		end
		p1:EndSession()
		local p2 = start(key)
		expect(p2 ~= nil).toBeTruthy()
		local n = 0
		if p2 then
			for _ in p2.Data.purchaseHistory do
				n += 1
			end
			p2.Data.purchaseHistory = {} -- Test-Schlüssel klein halten
			p2:EndSession()
		end
		expect(n).toBe(1000)
	end)

	it("Echtes Profil: Speichern wird bestätigt (Grundlage für Käufe)", function()
		local t0 = os.clock()
		expect(PD:saveAndWait(player, 15)).toBeTruthy()
		print(("[PERSIST] saveAndWait in %.1f s"):format(os.clock() - t0))
	end)
end
