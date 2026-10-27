--!strict
-- Integration: Tutorial-Ablauf über echte Services (Schlag, Upgrade-Kauf, Puppe, Kissenkauf, Rank, Ziel),
-- Belohnung (2×-Boost), Überspringen. Sichert und stellt den Spielerstand wieder her.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local Tutorial = reg.TutorialService
	local Swing = reg.SwingService
	local Shop = reg.ShopService
	local Stats = reg.StatsService
	local CollectionService = game:GetService("CollectionService")

	local data = PD:get(player)
	local backup = {
		tutorial = table.clone(data.tutorial),
		feathers = data.feathers,
		lifetimeFeathers = data.lifetimeFeathers,
		rank = data.rank,
		upgrades = table.clone(data.upgrades),
		ownedPillows = table.clone(data.ownedPillows),
		equippedPillow = data.equippedPillow,
		autoSwingEnabled = data.autoSwingEnabled,
	}
	local startCFrame = player.Character and player.Character:GetPivot()
	data.autoSwingEnabled = false
	data.tutorial = { step = 0, completed = false }
	data.upgrades = { featherPower = 0, swingSpeed = 0 }
	data.ownedPillows = { worn = true }
	data.equippedPillow = "worn"
	data.rank = 1

	local function swingNow()
		task.wait(1) -- Cooldown sicher abwarten (SwingGate)
		return Swing:requestSwing(player, os.clock())
	end

	it("Schritt 1: erster aktiver Schlag", function()
		expect(Tutorial:current(player)).toBe("swing")
		-- weit weg von Puppen, damit nur der Schlag zählt
		player.Character:PivotTo(CFrame.new(0, 200, 0))
		expect(swingNow()).toBeTruthy()
		expect(data.tutorial.step).toBe(1)
	end)

	it("Schritt 2: Feather Power kaufen", function()
		data.feathers = 1e6
		expect((Shop:buyUpgrade(player, "featherPower"))).toBeTruthy()
		expect(data.tutorial.step).toBe(2)
	end)

	it("Schritt 3: Puppe treffen", function()
		local dummy = CollectionService:GetTagged("PillowDummy")[1]
		expect(dummy ~= nil).toBeTruthy()
		local pos = if dummy:IsA("Model") then dummy:GetPivot().Position else (dummy :: BasePart).Position
		player.Character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 4)))
		task.wait(0.2)
		expect(swingNow()).toBeTruthy()
		expect(data.tutorial.step).toBe(3)
	end)

	it("Schritt 4–5: Kissenkauf, Rank 2 wird nachgezogen, wenn schon erreicht", function()
		data.rank = 2
		expect((Shop:buyPillow(player, "cotton"))).toBeTruthy()
		expect(data.tutorial.step).toBe(5)
		expect(data.tutorial.completed).toBe(false)
	end)

	it("Schritt 6: Ziel-Hinweis, danach Abschluss mit 2×-Boost", function()
		task.wait(Tutorial.GOAL_DELAY + 0.5)
		expect(data.tutorial.step).toBe(6)
		expect(data.tutorial.completed).toBe(true)
		expect(Stats:extraMultiplier(player)).toBe(Tutorial.REWARD_MULT)
		expect(player:GetAttribute("BoostEndsAt") ~= nil).toBeTruthy()
	end)

	it("Ereignisse nach Abschluss ändern nichts", function()
		Tutorial:tryComplete(player, "swing")
		expect(data.tutorial.step).toBe(6)
	end)

	it("Überspringen beendet ohne Belohnung", function()
		Stats:clearBoost(player)
		data.tutorial = { step = 1, completed = false }
		Tutorial:skip(player)
		expect(data.tutorial.completed).toBe(true)
		expect(Stats:extraMultiplier(player)).toBe(1)
	end)

	it("Reihenfolge: späte Aufgabe vor der aktuellen zählt nicht", function()
		data.tutorial = { step = 0, completed = false }
		Tutorial:tryComplete(player, "hitDummy")
		expect(data.tutorial.step).toBe(0)
	end)

	-- Stand wiederherstellen
	Stats:clearBoost(player)
	for k, v in backup do
		data[k] = v
	end
	PD:markChanged(
		player,
		"tutorial",
		"feathers",
		"lifetimeFeathers",
		"rank",
		"upgrades",
		"ownedPillows",
		"equippedPillow",
		"autoSwingEnabled"
	)
	reg.PillowToolService:give(player)
	if startCFrame then
		player.Character:PivotTo(startCFrame)
	end
end
