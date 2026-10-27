--!strict
-- Automatischer Mehrspieler-Check (PS-21, Restpunkt Gate M2) für Studio-Test „Clients and Servers“ mit 2 Spielern.
-- Start: Attribut RunMultiplayerCheck am Server-Skript (nur Studio). Wartet bis 120 s auf 2 geladene Spieler,
-- prüft serverseitig und setzt workspace-Attribut MultiplayerCheck = "live", damit die Clients
-- (Client/Dev/MultiplayerProbe) zählen, was sie vom anderen Spieler sehen. Ausgabe: [MP] PASS/FAIL, [MP] SUMMARY.
-- Spielstände werden danach wiederhergestellt (Federn, Auto-Swing, Positionen).
local Players = game:GetService("Players")

local MultiplayerCheck = {}

local function waitForPlayers(registry: any, n: number, timeout: number): { Player }
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local loaded = {}
		for _, p in Players:GetPlayers() do
			if
				registry.PlayerDataService:isLoaded(p)
				and p.Character
				and p.Character:FindFirstChild("Head")
			then
				table.insert(loaded, p)
			end
		end
		if #loaded >= n then
			return loaded
		end
		task.wait(0.5)
	end
	return {}
end

-- Ersetzt ein Remote kurzzeitig durch einen Spion, der Empfänger aufzeichnet (kein Senden)
local function spyRemote(Net: any, name: string): ({ any }, () -> ())
	local calls = {}
	local real = Net.remotes[name]
	Net.remotes[name] = {
		FireClient = function(_, target: Player, ...)
			table.insert(calls, { target = target, args = { ... } })
		end,
	}
	return calls, function()
		Net.remotes[name] = real
	end
end

function MultiplayerCheck.run(registry: any)
	local PD = registry.PlayerDataService
	local Net = registry.NetService
	local Swing = registry.SwingService
	local Social = registry.SocialService
	local Rank = registry.RankService
	local LB = registry.LeaderboardService
	local SR = registry.SessionReportService

	print("[MP] Warte auf 2 Spieler (Studio: Test → Clients and Servers → 2 Spieler → Start) …")
	local ps = waitForPlayers(registry, 2, 120)
	if #ps < 2 then
		print("[MP] SKIP – keine 2 Spieler innerhalb von 120 s")
		return
	end
	local A, B = ps[1], ps[2]
	local dA, dB = PD:get(A), PD:get(B)
	local passed, failed = 0, 0
	local function check(name: string, ok: boolean, detail: string?)
		if ok then
			passed += 1
			print("[MP] PASS " .. name)
		else
			failed += 1
			warn("[MP] FAIL " .. name .. (if detail then " :: " .. detail else ""))
		end
	end

	-- Zustand sichern
	local saved = {
		fA = dA.feathers,
		lA = dA.lifetimeFeathers,
		fB = dB.feathers,
		lB = dB.lifetimeFeathers,
		autoA = dA.autoSwingEnabled,
		autoB = dB.autoSwingEnabled,
		posB = (B.Character :: Model):GetPivot(),
	}
	dA.autoSwingEnabled, dB.autoSwingEnabled = false, false

	-- 1) Getrennte Spielstände
	check("Getrennte Spielstände", dA ~= dB and A.UserId ~= B.UserId)

	-- 2) Rang-Titel an beiden Köpfen (repliziert automatisch zu allen Clients)
	for _, p in { A, B } do
		local head = (p.Character :: Model):FindFirstChild("Head")
		local tag = head and head:FindFirstChild("RankTag")
		local title = tag and tag:FindFirstChild("Title") :: TextLabel?
		check(
			"Rang-Titel über dem Kopf von " .. p.Name,
			title ~= nil and title.Text ~= "",
			if title then nil else "RankTag fehlt"
		)
	end

	-- B neben A stellen (Effekt-Radius)
	local rootA = (A.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart;
	(B.Character :: Model):PivotTo(rootA.CFrame * CFrame.new(5, 0, 0))
	task.wait(0.3)

	-- 3) Schlag-Effekte erreichen den Mitspieler in der Nähe, Federn nur beim Schlagenden
	do
		local calls, restore = spyRemote(Net, "SwingFx")
		local fB = dB.feathers
		Swing:performSwing(A, false)
		restore()
		local toA, toB = false, false
		for _, c in calls do
			toA = toA or c.target == A
			toB = toB or c.target == B
		end
		check("Schlag-Effekt an Schlagenden und Mitspieler (fireNear)", toA and toB)
		check("Federn nur beim Schlagenden", dB.feathers == fB and dA.feathers > saved.fA)
	end

	-- 4) Rang-Aufstieg wird dem Mitspieler gemeldet
	do
		local calls, restore = spyRemote(Net, "Notify")
		PD.RankChanged:Fire(A, dA.rank, math.max(1, dA.rank - 1))
		task.wait(0.1)
		restore()
		local toB = false
		for _, c in calls do
			if c.target == B and c.args[1] == "otherRankUp" then
				toB = true
			end
		end
		check("Rang-Aufstieg an Mitspieler gemeldet", toB)
		Rank:applyTag(A)
	end

	-- 5) Freunde-Bonus: echte Prüfung darf nicht abstürzen; als Freunde simuliert +10 % für beide
	do
		local ok = pcall(function()
			Social:recompute(A)
			Social:recompute(B)
		end)
		check(
			"Freundes-Prüfung (IsFriendsWith) ohne Fehler",
			ok and A:GetAttribute("FriendsInServer") ~= nil,
			"echte Werte: A=" .. tostring(A:GetAttribute("FriendsInServer"))
		)
		-- Studio-Testspieler sind keine echten Freunde → Freundschaft simulieren
		Social:apply(A, 1, false)
		Social:apply(B, 1, false)
		check(
			"Freunde-Bonus +10 % für beide",
			math.abs(Social:multiplier(A) - 1.1) < 1e-9 and math.abs(Social:multiplier(B) - 1.1) < 1e-9
		)
		Social:recompute(A)
		Social:recompute(B)
	end

	-- 6) Leaderboard schreibt beide Spieler
	check("Leaderboard: beide Spieler geschrieben", LB:submit(A) >= 1 and LB:submit(B) >= 1)

	-- 7) Sitzungsberichte laufen für beide
	check("Sitzungsberichte für beide", SR:build(A) ~= nil and SR:build(B) ~= nil)

	-- 8) Live-Phase für die Clients: echte Schläge beider Spieler nebeneinander + echter Rang-Hinweis
	workspace:SetAttribute("MultiplayerCheck", "live")
	for _ = 1, 4 do
		Swing:performSwing(A, false)
		Swing:performSwing(B, false)
		task.wait(0.7)
	end
	PD.RankChanged:Fire(A, dA.rank, math.max(1, dA.rank - 1))
	PD.RankChanged:Fire(B, dB.rank, math.max(1, dB.rank - 1))
	task.wait(3)
	workspace:SetAttribute("MultiplayerCheck", "done")

	-- Zustand wiederherstellen
	dA.feathers, dA.lifetimeFeathers = saved.fA, saved.lA
	dB.feathers, dB.lifetimeFeathers = saved.fB, saved.lB
	dA.autoSwingEnabled, dB.autoSwingEnabled = saved.autoA, saved.autoB
	for _, p in { A, B } do
		PD:markChanged(p, "feathers", "lifetimeFeathers", "autoSwingEnabled")
	end
	(B.Character :: Model):PivotTo(saved.posB)

	print(
		("[MP] SUMMARY Server %d/%d passed – Client-Ergebnisse stehen in den Client-Ausgaben ([MP-CLIENT])"):format(
			passed,
			passed + failed
		)
	)
end

return MultiplayerCheck
