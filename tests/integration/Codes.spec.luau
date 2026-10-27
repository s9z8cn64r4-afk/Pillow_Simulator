--!strict
-- Integration: Codes (einmal je Spieler, Ablauf, unbekannt, Groß-/Kleinschreibung, Belohnungen).
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local CodeSvc = reg.CodeService
	local Stats = reg.StatsService
	local Validate = require(game:GetService("ReplicatedStorage").Shared.Net.Validate)

	local data = PD:get(player)
	local backup = {
		redeemedCodes = table.clone(data.redeemedCodes),
		feathers = data.feathers,
		lifetimeFeathers = data.lifetimeFeathers,
		rank = data.rank,
		activeBoosts = table.clone(data.activeBoosts),
	}
	data.redeemedCodes = {}
	table.clear(data.activeBoosts)

	it("Federn-Code: Groß-/Kleinschreibung egal, Federn gutgeschrieben", function()
		local before = data.feathers
		local ok, info = CodeSvc:redeem(player, "pillowFight")
		expect(ok).toBeTruthy()
		expect(info.code).toBe("PILLOWFIGHT")
		expect(data.feathers > before).toBeTruthy()
	end)

	it("Zweites Einlösen wird abgelehnt", function()
		local ok, why = CodeSvc:redeem(player, "PILLOWFIGHT")
		expect(ok).toBeFalsy()
		expect(why).toBe("used")
	end)

	it("Boost-Code aktiviert 2×", function()
		local ok = CodeSvc:redeem(player, "fluffy")
		expect(ok).toBeTruthy()
		expect(Stats:extraMultiplier(player)).toBe(2)
	end)

	it("Unbekannte und abgelaufene Codes", function()
		local ok, why = CodeSvc:redeem(player, "NOPE123")
		expect(ok).toBeFalsy()
		expect(why).toBe("unknown")
		local ok2, why2 = CodeSvc:redeem(player, "BETATESTER", 1798761600 + 1)
		expect(ok2).toBeFalsy()
		expect(why2).toBe("expired")
		expect(data.redeemedCodes.BETATESTER == nil).toBeTruthy()
	end)

	it("Validierer lässt nur kurze alphanumerische Codes durch", function()
		local v = Validate.validators.codeText
		expect(v("FLUFFY")).toBeTruthy()
		expect(v("")).toBeFalsy()
		expect(v("A B")).toBeFalsy()
		expect(v(string.rep("A", 21))).toBeFalsy()
		expect(v("DROP;--")).toBeFalsy()
		expect(v(123)).toBeFalsy()
	end)

	for k, v in backup do
		data[k] = v
	end
	PD:markChanged(player, "feathers", "lifetimeFeathers", "rank", "activeBoosts")
	Stats:refreshBoostAttributes(player)
end
