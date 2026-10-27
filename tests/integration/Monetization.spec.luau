--!strict
-- Integration: Monetarisierung (PS-34) – Pass-Wirkung, Kaufsperre ohne ID/Preis, idempotente Quittungen,
-- gekaufte Boost-Zeit ohne Deckel, keine Gutschrift für unbekannte Produkte oder fremde Spieler.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local M = reg.MonetizationService
	local Stats = reg.StatsService
	local PD = reg.PlayerDataService

	local data = PD:get(player)
	local savedBoosts = table.clone(data.activeBoosts)
	local savedHistory = table.clone(data.purchaseHistory)
	local savedOwned = { doubleFeathers = M:owns(player, "doubleFeathers"), fasterAutoSwing = M:owns(player, "fasterAutoSwing"), vip = M:owns(player, "vip") }
	local origSave = M.saveCheck
	table.clear(data.activeBoosts)
	M:setOwned(player, "doubleFeathers", false)
	M:setOwned(player, "vip", false)
	M:setOwned(player, "fasterAutoSwing", false)

	-- Test-Produkt-ID (nur in diesem Lauf), echte IDs kommen vom Owner
	local TEST_PRODUCT_ID = 999000111
	local boostProduct = nil
	for _, p in require(game:GetService("ReplicatedStorage").Shared.Config.Products).devProducts do
		boostProduct = p
	end
	M.productByProductId[TEST_PRODUCT_ID] = boostProduct

	it("2x-Pass verdoppelt Federn pro Schlag, VIP +10 %", function()
		local base = Stats:feathersPerSwing(player)
		M:setOwned(player, "doubleFeathers", true)
		expect(math.abs(Stats:feathersPerSwing(player) / base - 2) < 1e-6).toBeTruthy()
		M:setOwned(player, "vip", true)
		expect(math.abs(Stats:feathersPerSwing(player) / base - 2.2) < 1e-6).toBeTruthy()
		M:setOwned(player, "doubleFeathers", false)
		M:setOwned(player, "vip", false)
	end)

	it("Auto-Swing-Pass: 100 % statt 80 %", function()
		expect(M:autoSwingEfficiency(player)).toBe(0.8)
		M:setOwned(player, "fasterAutoSwing", true)
		expect(M:autoSwingEfficiency(player)).toBe(1)
		M:setOwned(player, "fasterAutoSwing", false)
	end)

	it("Ohne Owner-ID/Preis: Kauf wird abgelehnt (kein Prompt)", function()
		local ok, why = M:prompt(player, "pass", "doubleFeathers")
		expect(ok).toBeFalsy()
		expect(why).toBe("notAvailable")
		local ok2, why2 = M:prompt(player, "product", "boost2x30")
		expect(ok2).toBeFalsy()
		expect(why2).toBe("notAvailable")
	end)

	it("Quittung: einmal gutgeschrieben, Wiederholung ohne Doppelgutschrift", function()
		M.saveCheck = function()
			return true
		end
		local receipt = { PlayerId = player.UserId, ProductId = TEST_PRODUCT_ID, PurchaseId = "TEST-RECEIPT-1", CurrencySpent = 0 }
		expect(M:processReceipt(receipt)).toBe(Enum.ProductPurchaseDecision.PurchaseGranted)
		local endsAt = data.activeBoosts.feathers2x
		expect(endsAt ~= nil).toBeTruthy()
		expect(M:processReceipt(receipt)).toBe(Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(data.activeBoosts.feathers2x).toBe(endsAt)
	end)

	it("Speichern nicht bestätigt → NotProcessedYet, Gutschrift bleibt einmalig", function()
		M.saveCheck = function()
			return false
		end
		local receipt = { PlayerId = player.UserId, ProductId = TEST_PRODUCT_ID, PurchaseId = "TEST-RECEIPT-2", CurrencySpent = 0 }
		local before = data.activeBoosts.feathers2x
		expect(M:processReceipt(receipt)).toBe(Enum.ProductPurchaseDecision.NotProcessedYet)
		local after1 = data.activeBoosts.feathers2x
		expect(after1 > before).toBeTruthy()
		M.saveCheck = function()
			return true
		end
		expect(M:processReceipt(receipt)).toBe(Enum.ProductPurchaseDecision.PurchaseGranted)
		expect(data.activeBoosts.feathers2x).toBe(after1)
	end)

	it("Gekaufte Boost-Zeit ist nicht gedeckelt", function()
		table.clear(data.activeBoosts)
		for i = 1, 6 do -- 6 × 30 Min. = 180 Min. > Deckel 120 Min.
			M:processReceipt({ PlayerId = player.UserId, ProductId = TEST_PRODUCT_ID, PurchaseId = "TEST-STACK-" .. i })
		end
		local left = data.activeBoosts.feathers2x - workspace:GetServerTimeNow()
		expect(left > 175 * 60).toBeTruthy()
	end)

	it("Unbekanntes Produkt / unbekannter Spieler → keine Gutschrift", function()
		local before = data.activeBoosts.feathers2x
		expect(M:processReceipt({ PlayerId = player.UserId, ProductId = 123, PurchaseId = "X1" })).toBe(
			Enum.ProductPurchaseDecision.NotProcessedYet
		)
		expect(M:processReceipt({ PlayerId = 1, ProductId = TEST_PRODUCT_ID, PurchaseId = "X2" })).toBe(
			Enum.ProductPurchaseDecision.NotProcessedYet
		)
		expect(data.activeBoosts.feathers2x).toBe(before)
	end)

	-- Aufräumen
	M.saveCheck = origSave
	M.productByProductId[TEST_PRODUCT_ID] = nil
	for id, v in savedOwned do
		M:setOwned(player, id, v)
	end
	table.clear(data.activeBoosts)
	for k, v in savedBoosts do
		data.activeBoosts[k] = v
	end
	table.clear(data.purchaseHistory)
	for k, v in savedHistory do
		data.purchaseHistory[k] = v
	end
	PD:markChanged(player, "activeBoosts")
	Stats:refreshBoostAttributes(player)
end
