--!strict
-- Integration: Analytics-Bündelung (Quellen gesammelt, Senken sofort, Progression bei Zone/Rebirth).
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local Tele = reg.TelemetryService
	local data = PD:get(player)
	local backup = { feathers = data.feathers, lifetimeFeathers = data.lifetimeFeathers, rank = data.rank }

	local function lastOf(kind: string): any?
		for i = #Tele.log, 1, -1 do
			if Tele.log[i].kind == kind then
				return Tele.log[i]
			end
		end
		return nil
	end

	it("Schläge werden gesammelt und als ein Economy-Event gesendet", function()
		Tele:flush(player) -- Altbestand leeren
		local before = #Tele.log
		for _ = 1, 25 do
			PD:addFeathers(player, 4, "swing")
		end
		expect(#Tele.log).toBe(before) -- noch nichts gesendet
		Tele:flush(player)
		local e = lastOf("economy")
		expect(e ~= nil and e.flow == "Source").toBeTruthy()
		expect((e :: any).amount).toBe(100)
		expect((e :: any).source).toBe("swing")
	end)

	it("Kissenkauf wird sofort als Senke gesendet", function()
		data.feathers = 1e6
		expect(PD:spendFeathers(player, 750, "pillow:cotton")).toBeTruthy()
		local e = lastOf("economy")
		expect((e :: any).flow).toBe("Sink")
		expect((e :: any).amount).toBe(750)
		expect((e :: any).sink).toBe("pillow:cotton")
	end)

	it("Upgrade-Serien werden gebündelt", function()
		data.feathers = 1e6
		local before = #Tele.log
		for _ = 1, 10 do
			PD:spendFeathers(player, 50, "upgrade:featherPower")
		end
		expect(#Tele.log).toBe(before)
		Tele:flush(player)
		local e = lastOf("economy")
		expect((e :: any).sink).toBe("upgrade:featherPower")
		expect((e :: any).amount).toBe(500)
	end)

	it("Zonenkauf erzeugt ein Progression-Event", function()
		Tele:onSpent(player, 75000, "zone:livingroom")
		local e = lastOf("progression")
		expect((e :: any).path).toBe("Zones")
		expect((e :: any).name).toBe("livingroom")
	end)

	it("Bot-Quellen werden nicht gesendet", function()
		Tele:flush(player)
		local before = #Tele.log
		PD:addFeathers(player, 10, "bot")
		Tele:flush(player)
		expect(#Tele.log).toBe(before)
	end)

	for k, v in backup do
		data[k] = v
	end
	PD:markChanged(player, "feathers", "lifetimeFeathers", "rank")
end
