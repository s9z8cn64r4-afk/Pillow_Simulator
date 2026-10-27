--!strict
-- Integration: Logging-Relay (PS-36) mit Test-Sender (kein Netzwerk) – Zusammenfassen, Datenschutz,
-- Summen, Puffer-Obergrenze, Ausfallsicherheit, sofortiger Versand bei „critical“.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local Relay = reg.RelayService
	local Log = reg.LogService
	local HttpService = game:GetService("HttpService")

	local wasEnabled = Relay.enabled
	local origSend = Relay.send
	local bodies: { any } = {}
	local function okSender(body: string)
		table.insert(bodies, HttpService:JSONDecode(body))
		return true, 200
	end
	local function lastEvents(): { any }
		local b = bodies[#bodies]
		return if b then b.events else {}
	end

	it("Gleiche Meldung mit anderen Zahlen wird zu einem Event mit Zähler", function()
		Relay:_setForTest(true, okSender)
		Relay:push("error", "DataStore Fehler 502 bei Key 17")
		Relay:push("error", "DataStore Fehler 503 bei Key 99")
		Relay:flush()
		local ev = lastEvents()
		expect(#ev).toBe(1)
		expect(ev[1].count).toBe(2)
		expect(bodies[#bodies].v).toBe(1)
		expect(bodies[#bodies].env).toBe("DEV")
	end)

	it("Datenschutz: UserId wird Pseudonym, Namen fliegen raus", function()
		Relay:_setForTest(true, okSender)
		Relay:push(
			"warn",
			"Test",
			{ userId = player.UserId, name = player.Name, displayName = player.DisplayName }
		)
		Relay:flush()
		local raw = HttpService:JSONEncode(bodies[#bodies])
		expect(string.find(raw, tostring(player.UserId), 1, true) == nil).toBeTruthy()
		expect(string.find(raw, player.Name, 1, true) == nil).toBeTruthy()
		expect(lastEvents()[1].ctx.p).toBe(reg.SessionReportService.pseudonym(player.UserId))
	end)

	it("Log:warn mit category = exploit landet als Anti-Exploit-Event", function()
		Relay:_setForTest(true, okSender)
		Log:warn("Netz-Verstoß", { reason = "spam", userId = player.UserId, category = "exploit" })
		Relay:flush()
		local ev = lastEvents()
		expect(#ev).toBe(1)
		expect(ev[1].cat).toBe("exploit")
		expect(ev[1].ctx.category == nil).toBeTruthy()
	end)

	it("Sitzungs-Summen werden addiert", function()
		Relay:_setForTest(true, okSender)
		Relay:push("session", "Sitzungen beendet", { seconds = 100, newPlayers = 1 }, true)
		Relay:push("session", "Sitzungen beendet", { seconds = 50, newPlayers = 0 }, true)
		Relay:flush()
		local e = lastEvents()[1]
		expect(e.count).toBe(2)
		expect(e.ctx.seconds).toBe(150)
		expect(e.ctx.newPlayers).toBe(1)
	end)

	it("Puffer-Obergrenze: Überschuss wird gezählt und gemeldet", function()
		Relay:_setForTest(true, okSender)
		for i = 1, Relay.MAX_EVENTS + 5 do
			-- verschiedene Fingerprints: Unterschied in den ersten 80 Zeichen, ohne Ziffern
			Relay:push("warn", "M-" .. string.rep("a", i % 50) .. string.rep("b", i // 50))
		end
		Relay:flush()
		expect(#lastEvents()).toBe(Relay.MAX_EVENTS)
		expect(bodies[#bodies].dropped).toBe(5)
	end)

	it("Relay down: kein Fehler im Spiel, nach 3 Versuchen verworfen", function()
		local calls = 0
		Relay:_setForTest(true, function()
			calls += 1
			error("HTTP 500")
		end)
		Relay:push("error", "boom")
		local ok = pcall(function()
			Relay:flush()
			Relay:flush()
			Relay:flush()
		end)
		expect(ok).toBeTruthy()
		expect(calls).toBe(3)
		expect(Relay.stats.failed).toBe(1)
		-- danach ist der Puffer frei, neue Meldungen gehen wieder raus
		Relay.send = okSender
		Relay:push("error", "wieder da")
		Relay:flush()
		expect(lastEvents()[1].msg).toBe("wieder da")
	end)

	it("critical wird nach kurzer Verzögerung von selbst gesendet", function()
		Relay:_setForTest(true, okSender)
		local before = #bodies
		Relay:push("critical", "Kauf-Fehler")
		task.wait(Relay.CRITICAL_DELAY + 0.5)
		expect(#bodies).toBe(before + 1)
		expect(lastEvents()[1].cat).toBe("critical")
	end)

	-- Aufräumen: Originalzustand (ohne Secrets in Studio aus)
	Relay:_setForTest(wasEnabled, origSend)
end
