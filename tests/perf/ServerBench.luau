--!strict
-- Server-Lastmessung (nur Studio, über BindableFunction ServerStorage.DevBench, siehe init.server.luau).
-- 12 echte Spieler lassen sich per Werkzeug nicht starten; stattdessen:
--   1. micro: Kosten eines Schlags (aktiv/auto) inkl. Federn, Statistik, Delta, SwingFx – Mittel in ms.
--   2. load: echte Schlag-Last wie bei N Spielern im Maximaltempo, über den echten Server-Pfad auf dem
--      eingeloggten Spieler, dabei Heartbeat-FPS messen.
-- Spielstand des Testspielers wird danach wiederhergestellt (Federn, Lebenszeit-Federn, Rang, Schlagzähler).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Bench = {}

local function snapshot(PD: any, player: Player)
	local d = PD:get(player)
	return {
		feathers = d.feathers,
		swings = d.stats.totalSwings,
		lifetime = d.lifetimeFeathers,
		rank = d.rank,
	}
end

local function restore(PD: any, player: Player, s: any)
	local d = PD:get(player)
	d.feathers = s.feathers
	d.stats.totalSwings = s.swings
	d.lifetimeFeathers = s.lifetime
	PD:markChanged(player, "feathers", "lifetimeFeathers", "stats")
	if d.rank ~= s.rank then
		local cur = d.rank
		d.rank = s.rank
		PD:markChanged(player, "rank")
		PD.RankChanged:Fire(player, s.rank, cur)
	end
end

function Bench.run(registry: any, opts: any): { [string]: any }
	opts = opts or {}
	assert(RunService:IsStudio(), "nur in Studio")
	local player = Players:GetPlayers()[1]
	assert(player, "kein Spieler im Server")
	local PD, Swing = registry.PlayerDataService, registry.SwingService
	assert(PD:isLoaded(player), "Spielstand nicht geladen")
	-- Testhilfe (nur Studio): Federn gutschreiben, ohne Rücksetzen (für UI-Tests mit frischem Spielstand)
	if opts.mode == "grant" then
		PD:addFeathers(player, opts.amount or 0, "studio_test")
		return { feathers = PD:get(player).feathers }
	end
	-- Testhilfe: Zonenkauf wie über den ProximityPrompt (Prompts erscheinen im automatisierten Fenster nicht)
	if opts.mode == "zoneBuy" then
		local ok, why = registry.ZoneService:unlock(player, opts.zone)
		registry.NetService:fire(
			"Notify",
			player,
			"purchaseResult",
			{ ok = ok, kind = "zone", id = opts.zone, reason = why }
		)
		return { ok = ok, reason = why }
	end
	-- Testhilfe: Zeitraffer wie der Bot (BotRun.spec), aber OHNE Rücksetzen – für UI-Prüfungen in späteren
	-- Spielphasen mit frischem Spielstand (Workspace-Attribut Environment = DEVFRESH…). Stoppt nach Rebirth
	-- opts.untilRebirth oder – mit opts.stopBeforeRebirth – wenn dieser Rebirth gerade bezahlbar wäre.
	if opts.mode == "fastforward" then
		local Shared = game:GetService("ReplicatedStorage").Shared
		local Pillows = require(Shared.Config.Pillows)
		local Zones = require(Shared.Config.Zones)
		local Progression = require(Shared.Config.Progression)
		local Formulas = require(Shared.Util.Formulas)
		local Stats, Shop, ZoneSvc, Rebirth =
			registry.StatsService, registry.ShopService, registry.ZoneService, registry.RebirthService
		local data = PD:get(player)
		local target = opts.untilRebirth or 1
		local sim = opts.simSeconds or 0
		local log = {}
		local function mark(text: string)
			table.insert(log, ("%6.1f Min. %s"):format(sim / 60, text))
		end
		local function allZonesOpen(): boolean
			for _, z in Zones.list do
				if not data.unlockedZones[z.id] and z.rebirths <= data.rebirths then
					return false
				end
			end
			return true
		end
		local ticks = 0
		while sim < 8 * 3600 do
			local swings = 10 / Stats:cooldown(player)
			PD:addFeathers(player, Stats:feathersPerSwing(player) * swings, "studio_test")
			sim += 10
			for _, z in Zones.list do
				if not data.unlockedZones[z.id] then
					if z.rebirths <= data.rebirths and data.feathers >= z.cost then
						ZoneSvc:unlock(player, z.id)
						mark("Zone " .. z.id)
						ZoneSvc:teleport(player, z.id)
						task.wait(0.4) -- Zonen-Erkennung (0,25-s-Takt) abwarten, sonst fehlt der Zonen-Multiplikator
					end
					break
				end
			end
			local cur = Pillows.byId[data.equippedPillow]
			local best = nil
			for _, pl in Pillows.list do
				if
					not data.ownedPillows[pl.id]
					and data.unlockedZones[pl.zone]
					and data.rebirths >= pl.rebirths
					and pl.power / pl.speed > cur.power / cur.speed
					and pl.cost <= data.feathers
					and (not best or pl.power > best.power)
				then
					best = pl
				end
			end
			if best then
				Shop:buyPillow(player, best.id)
				mark("Kissen " .. best.id)
			end
			for _ = 1, 25 do
				local bought = false
				for _, kind in { "featherPower", "swingSpeed" } do
					local level = data.upgrades[kind]
					local def = (Progression.upgrades :: any)[kind]
					if level < def.maxLevel and Formulas.upgradeCost(kind, level) <= data.feathers * 0.5 then
						Shop:buyUpgrade(player, kind)
						bought = true
					end
				end
				if not bought then
					break
				end
			end
			if allZonesOpen() and data.feathers >= Formulas.rebirthCost(data.rebirths) then
				if opts.stopBeforeRebirth and data.rebirths + 1 >= target then
					mark("Rebirth " .. (data.rebirths + 1) .. " bezahlbar – Stopp")
					break
				end
				Rebirth:rebirth(player)
				mark("Rebirth " .. data.rebirths)
				task.wait(0.4)
				if data.rebirths >= target then
					break
				end
			end
			ticks += 1
			if ticks % 25 == 0 then
				task.wait()
			end
		end
		return { simSeconds = sim, log = table.concat(log, "\n"), rebirths = data.rebirths, rank = data.rank }
	end
	local before = snapshot(PD, player)
	local out: { [string]: any } = {}

	if opts.mode == "micro" then
		local n = opts.n or 500
		for _, isAuto in { false, true } do
			local t0 = os.clock()
			for _ = 1, n do
				Swing:performSwing(player, isAuto)
			end
			out[if isAuto then "autoMs" else "activeMs"] = (os.clock() - t0) * 1000 / n
			task.wait() -- Deltas abfließen lassen
		end
	else
		-- Last: rate Schläge pro Sekunde (12 Spieler × 3,33/s bei maximalem Swing Speed = 40/s), seconds lang
		local rate = opts.rate or 40
		local seconds = opts.seconds or 20
		local frames, minFps, worstMs = 0, math.huge, 0
		local budget = 0
		local done = false
		local hb = RunService.Heartbeat:Connect(function(dt)
			frames += 1
			minFps = math.min(minFps, 1 / dt)
			worstMs = math.max(worstMs, dt * 1000)
			budget += dt * rate
			local t0 = os.clock()
			while budget >= 1 and not done do
				budget -= 1
				Swing:performSwing(player, (frames % 2) == 0)
			end
			out.swingCpuMs = (out.swingCpuMs or 0) + (os.clock() - t0) * 1000
		end)
		local start = os.clock()
		task.wait(seconds)
		done = true
		hb:Disconnect()
		local elapsed = os.clock() - start
		out.rate = rate
		out.seconds = elapsed
		out.avgFps = frames / elapsed
		out.minFps = minFps
		out.worstFrameMs = worstMs
		out.swingCpuMsPerFrame = (out.swingCpuMs or 0) / math.max(frames, 1)
	end

	restore(PD, player, before)
	return out
end

return Bench
