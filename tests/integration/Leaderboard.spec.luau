--!strict
-- Integration: Leaderboard schreiben/lesen (DEV-OrderedDataStore) und Tafel-Darstellung.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local LB = reg.LeaderboardService
	local PD = reg.PlayerDataService

	it("Eigene Werte werden geschrieben und erscheinen in der Top-Liste", function()
		local data = PD:get(player)
		expect(LB:submit(player)).toBe(#LB.BOARDS)
		local list = LB:fetch("feathers")
		expect(list ~= nil).toBeTruthy()
		local found = false
		for _, e in list :: { any } do
			if e.userId == player.UserId then
				found = true
				-- Top-Liste ist „eventually consistent“: Wert > 0 und nicht größer als der aktuelle Stand
				expect(e.value > 0 and e.value <= math.floor(data.lifetimeFeathers)).toBeTruthy()
			end
		end
		expect(found).toBeTruthy()
	end)

	it("Tafeln existieren und zeigen Einträge", function()
		-- nur lesen + darstellen (erneutes Schreiben desselben Schlüssels binnen 6 s wird gedrosselt)
		local list = LB:fetch("feathers")
		LB:render("feathers", list or {})
		local board = workspace:FindFirstChild("Leaderboards")
		expect(board ~= nil).toBeTruthy()
		local part = (board :: Instance):FindFirstChild("feathers")
		expect(part ~= nil).toBeTruthy()
		local row1 = (part :: Instance):FindFirstChild("Row1", true) :: TextLabel?
		expect(row1 ~= nil and string.sub((row1 :: TextLabel).Text, 1, 2) == "1.").toBeTruthy()
	end)
end
