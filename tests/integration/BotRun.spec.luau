--!strict
-- PS-22 Bot-Durchlauf: spielt mit den echten Services bis Rebirth 3 (Zeitraffer: je Tick der Ertrag von
-- TICK_SECONDS aktiven Schlägen ohne Puppen-Bonus). Findet Sackgassen im Fortschrittspfad und grobe
-- Balance-Abweichungen gegenüber der Economy-Simulation. Stellt den Spielerstand vollständig wieder her.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local Stats = reg.StatsService
	local Shop = reg.ShopService
	local ZoneSvc = reg.ZoneService
	local Rebirth = reg.RebirthService
	local Shared = game:GetService("ReplicatedStorage").Shared
	local Pillows = require(Shared.Config.Pillows)
	local Zones = require(Shared.Config.Zones)
	local Progression = require(Shared.Config.Progression)
	local Formulas = require(Shared.Util.Formulas)

	local TICK_SECONDS = 10
	local MAX_SIM_SECONDS = 6 * 3600
	local TARGET_REBIRTHS = 3

	local data = PD:get(player)
	local function deepClone(t: any): any
		if type(t) ~= "table" then
			return t
		end
		local c = {}
		for k, v in t do
			c[k] = deepClone(v)
		end
		return c
	end
	local backup = {}
	for k, v in data do
		backup[k] = deepClone(v)
	end
	local startCFrame = player.Character and player.Character:GetPivot()

	-- frisches Profil (wie ein neuer Spieler, Tutorial abgeschlossen)
	data.feathers = 0
	data.lifetimeFeathers = 0
	data.rank = 1
	data.rebirths = 0
	data.upgrades = { featherPower = 0, swingSpeed = 0 }
	data.ownedPillows = { [Pillows.starter] = true }
	data.equippedPillow = Pillows.starter
	data.unlockedZones = { [Zones.start] = true }
	data.autoSwingEnabled = false
	data.tutorial = { step = 6, completed = true }
	PD:markChanged(player, "feathers", "lifetimeFeathers", "rank", "rebirths", "upgrades", "ownedPillows")
	PD:markChanged(player, "equippedPillow", "unlockedZones", "autoSwingEnabled", "tutorial")

	local simSeconds = 0
	local milestones: { [string]: number } = {}
	local function mark(key: string)
		if milestones[key] == nil then
			milestones[key] = simSeconds
			print(("[BOT] %-18s %6.1f Min."):format(key, simSeconds / 60))
		end
	end

	local function goTo(zoneId: string)
		ZoneSvc:teleport(player, zoneId)
		task.wait(0.4) -- Zonen-Erkennung (0,25-s-Takt) abwarten
	end

	local function bestPillowToBuy(): any?
		local cur = Pillows.byId[data.equippedPillow]
		local best = nil
		for _, p in Pillows.list do
			local available = not data.ownedPillows[p.id]
				and data.unlockedZones[p.zone]
				and data.rebirths >= p.rebirths
				and p.power / p.speed > cur.power / cur.speed
			if available and p.cost <= data.feathers and (not best or p.power > best.power) then
				best = p
			end
		end
		return best
	end

	local function shop()
		-- 1. nächste Zone
		for _, z in Zones.list do
			if not data.unlockedZones[z.id] then
				if z.rebirths <= data.rebirths and data.feathers >= z.cost then
					assert((ZoneSvc:unlock(player, z.id)), "Zonenkauf fehlgeschlagen: " .. z.id)
					mark("zone:" .. z.id .. ":r" .. data.rebirths)
					goTo(z.id)
				end
				break
			end
		end
		-- 2. bestes leistbares Kissen
		local p = bestPillowToBuy()
		if p then
			assert((Shop:buyPillow(player, p.id)), "Kissenkauf fehlgeschlagen: " .. p.id)
			mark("pillow:" .. p.id)
		end
		-- 3. Upgrades, solange sie höchstens die Hälfte der Federn kosten
		for _ = 1, 25 do
			local bought = false
			for _, kind in { "featherPower", "swingSpeed" } do
				local level = data.upgrades[kind]
				local def = (Progression.upgrades :: any)[kind]
				if level < def.maxLevel and Formulas.upgradeCost(kind, level) <= data.feathers * 0.5 then
					assert((Shop:buyUpgrade(player, kind)), "Upgrade fehlgeschlagen: " .. kind)
					bought = true
				end
			end
			if not bought then
				break
			end
		end
	end

	it("Bot erreicht Rebirth 3 ohne Sackgasse", function()
		goTo(Zones.start)
		local ticks = 0
		while data.rebirths < TARGET_REBIRTHS and simSeconds < MAX_SIM_SECONDS do
			local swings = TICK_SECONDS / Stats:cooldown(player)
			PD:addFeathers(player, Stats:feathersPerSwing(player) * swings, "bot")
			simSeconds += TICK_SECONDS
			mark("rank:" .. data.rank)
			shop()
			-- Rebirth, sobald bezahlbar und alle aktuell möglichen Zonen offen sind
			local allZones = true
			for _, z in Zones.list do
				if not data.unlockedZones[z.id] and z.rebirths <= data.rebirths then
					allZones = false
				end
			end
			if allZones and data.feathers >= Formulas.rebirthCost(data.rebirths) then
				assert((Rebirth:rebirth(player)), "Rebirth fehlgeschlagen")
				mark("rebirth:" .. data.rebirths)
				task.wait(0.4) -- Rebirth teleportiert verzögert in die Startzone
			end
			ticks += 1
			if ticks % 25 == 0 then
				task.wait() -- nicht zu lange ohne Yield laufen
			end
		end
		expect(data.rebirths).toBe(TARGET_REBIRTHS)
	end)

	it("Meilensteine liegen im Rahmen der Simulation (Faktor 0,4–2,5)", function()
		-- Referenz sim.py, Profil Regular: Zone 2 ≈ 9 Min., Rebirth 1 ≈ 47 Min., Rebirth 3 ≈ 2,1 h.
		-- Der Bot schlägt ohne Puppen-Bonus und ohne Auto-Swing-Mix, daher großzügige Toleranz.
		local function within(key: string, refMinutes: number)
			local t = milestones[key]
			expect(t ~= nil).toBeTruthy()
			local ratio = (t :: number) / 60 / refMinutes
			print(("[BOT] %s: %.1f Min. (Sim %.0f, Faktor %.2f)"):format(key, (t :: number) / 60, refMinutes, ratio))
			expect(ratio >= 0.4 and ratio <= 2.5).toBeTruthy()
		end
		within("zone:livingroom:r0", 9.1)
		within("rebirth:1", 47)
		within("rebirth:3", 126)
	end)

	-- Stand wiederherstellen
	for k in data do
		if backup[k] == nil then
			data[k] = nil
		end
	end
	for k, v in backup do
		data[k] = v
	end
	-- nur öffentliche Schlüssel replizieren (purchaseHistory/redeemedCodes bleiben serverseitig)
	local private = require(Shared.Types.PlayerData).PRIVATE_KEYS
	for k in data do
		if not private[k] then
			PD:markChanged(player, k)
		end
	end
	reg.PillowToolService:give(player)
	reg.RankService:applyTag(player)
	if startCFrame and player.Character then
		player.Character:PivotTo(startCFrame)
	end
end
