--!strict
-- Integration: Sitzungsberichte (PS-41) – Inhalt, Pseudonym statt UserId, Schlüsselformat, Fehlerzählung.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local SR = reg.SessionReportService
	local PD = reg.PlayerDataService
	local Log = reg.LogService
	local data = PD:get(player)

	local origSave = SR.save
	local saved: { [string]: any } = {}
	SR.save = function(key, record)
		saved[key] = record
	end
	local backup = { feathers = data.feathers, lifetime = data.lifetimeFeathers, rank = data.rank }

	it("Pseudonym: stabil, 16 Hex-Zeichen, enthält die UserId nicht", function()
		local a = SR.pseudonym(player.UserId)
		expect(a).toBe(SR.pseudonym(player.UserId))
		expect(#a).toBe(16)
		expect(string.match(a, "^%x+$") ~= nil).toBeTruthy()
		expect(string.find(a, tostring(player.UserId), 1, true) == nil).toBeTruthy()
		expect(a ~= SR.pseudonym(player.UserId + 1)).toBeTruthy()
	end)

	it("Bericht enthält Fortschritt und Fehler der Sitzung, keine UserId/Namen", function()
		SR:begin(player, data)
		PD:addFeathers(player, 1234, "test")
		Log.counts.error += 1 -- simulierter Serverfehler während der Sitzung
		local r = SR:build(player)
		Log.counts.error -= 1
		expect(r ~= nil).toBeTruthy()
		expect(r.feathersEarned).toBe(1234)
		expect(r.serverErrors).toBe(1)
		expect(r.studio).toBe(true)
		expect(type(r.tutDoneEnd)).toBe("boolean")
		for k, v in r do
			expect(v ~= player.UserId and v ~= player.Name and v ~= player.DisplayName).toBeTruthy()
			expect(k ~= "userId").toBeTruthy()
		end
	end)

	it("Abschluss speichert unter <Tag>_<Unix>_<Pseudonym>", function()
		SR:finish(player)
		local key = next(saved)
		expect(key ~= nil).toBeTruthy()
		expect(string.match(key :: string, "^%d%d%d%d%d%d%d%d_%d+_%x+$") ~= nil).toBeTruthy()
		expect(SR.last.u).toBe(SR.pseudonym(player.UserId))
	end)

	-- Aufräumen: Sitzung neu beginnen (wie nach dem Laden), Spielstand zurück
	SR.save = origSave
	data.feathers = backup.feathers
	data.lifetimeFeathers = backup.lifetime
	data.rank = backup.rank
	PD:markChanged(player, "feathers", "lifetimeFeathers", "rank")
	SR:begin(player, data)
end
