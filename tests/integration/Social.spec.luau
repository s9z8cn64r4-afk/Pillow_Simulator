--!strict
-- Integration: Freunde-/Gruppen-Bonus (PS-33) – Rechnung, Deckel, Wirkung auf Federn pro Schlag, Attribute.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local SocialSvc = reg.SocialService
	local Stats = reg.StatsService
	local PD = reg.PlayerDataService

	local data = PD:get(player)
	local savedBoosts = table.clone(data.activeBoosts)
	table.clear(data.activeBoosts)

	it("Multiplikator: +10 % je Freund, max. 3, Gruppe +10 %", function()
		expect(SocialSvc.multiplierFor(0, false)).toBe(1)
		expect(math.abs(SocialSvc.multiplierFor(2, false) - 1.2) < 1e-9).toBeTruthy()
		expect(math.abs(SocialSvc.multiplierFor(7, false) - 1.3) < 1e-9).toBeTruthy()
		expect(math.abs(SocialSvc.multiplierFor(3, true) - 1.43) < 1e-9).toBeTruthy()
	end)

	it("Bonus wirkt auf Federn pro Schlag und setzt Attribute", function()
		SocialSvc:apply(player, 0, false)
		local base = Stats:feathersPerSwing(player)
		SocialSvc:apply(player, 2, false)
		local boosted = Stats:feathersPerSwing(player)
		expect(math.abs(boosted / base - 1.2) < 1e-6).toBeTruthy()
		expect(player:GetAttribute("FriendsInServer")).toBe(2)
		expect(player:GetAttribute("GroupMember")).toBe(false)
	end)

	it("Solo-Server: Neuberechnung ergibt 0 Freunde", function()
		SocialSvc:recompute(player)
		expect(player:GetAttribute("FriendsInServer")).toBe(0)
		expect(SocialSvc:multiplier(player)).toBe(1)
	end)

	for k, v in savedBoosts do
		data.activeBoosts[k] = v
	end
	PD:markChanged(player, "activeBoosts")
	Stats:refreshBoostAttributes(player)
end
