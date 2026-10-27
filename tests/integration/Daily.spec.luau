--!strict
-- Integration: Daily Reward über den echten Service (Zeit simuliert über nowUnix), Boost-Stapelung.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local DailySvc = reg.DailyRewardService
	local Stats = reg.StatsService
	local Rewards = require(game:GetService("ReplicatedStorage").Shared.Config.Rewards)

	local data = PD:get(player)
	local backup = {
		dailyReward = table.clone(data.dailyReward),
		feathers = data.feathers,
		lifetimeFeathers = data.lifetimeFeathers,
		rank = data.rank,
		activeBoosts = table.clone(data.activeBoosts),
	}
	local DAY = 86400
	local t0 = 20500 * DAY + 7200
	data.dailyReward = { streakDay = 0, lastClaimUnix = 0 }
	table.clear(data.activeBoosts)

	it("Tag 1: Federn = 3 Minuten Produktion", function()
		local expected = DailySvc:productionFeathers(player, Rewards.daily[1].amount)
		local before = data.feathers
		local ok, info = DailySvc:claim(player, t0)
		expect(ok).toBeTruthy()
		expect(info.day).toBe(1)
		expect(data.feathers - before).toBeNear(expected)
		expect(data.dailyReward.streakDay).toBe(1)
	end)

	it("Zweite Abholung am selben Tag wird abgelehnt", function()
		local ok, why = DailySvc:claim(player, t0 + 3600)
		expect(ok).toBeFalsy()
		expect(why).toBe("alreadyClaimed")
		expect(data.dailyReward.streakDay).toBe(1)
	end)

	it("Tag 2: 2×-Boost für 10 Minuten", function()
		local ok, info = DailySvc:claim(player, t0 + DAY)
		expect(ok).toBeTruthy()
		expect(info.kind).toBe("boost")
		expect(Stats:extraMultiplier(player)).toBe(2)
		local left = data.activeBoosts.feathers2x - workspace:GetServerTimeNow()
		expect(left > 590 and left <= 600).toBeTruthy()
	end)

	it("Verpasste Tage pausieren die Kette (kein Reset)", function()
		local ok, info = DailySvc:claim(player, t0 + 5 * DAY)
		expect(ok).toBeTruthy()
		expect(info.day).toBe(3)
	end)

	it("Boosts stapeln und sind auf maxStackMinutes gedeckelt", function()
		Stats:addBoost(player, "feathers2x", 10 * 3600)
		local left = data.activeBoosts.feathers2x - workspace:GetServerTimeNow()
		expect(left <= Rewards.boosts.feathers2x.maxStackMinutes * 60 + 1).toBeTruthy()
		expect(left > Rewards.boosts.feathers2x.maxStackMinutes * 60 - 5).toBeTruthy()
	end)

	it("Nach Tag 7 beginnt die Kette wieder bei Tag 1", function()
		data.dailyReward = { streakDay = 7, lastClaimUnix = t0 }
		local ok, info = DailySvc:claim(player, t0 + DAY)
		expect(ok).toBeTruthy()
		expect(info.day).toBe(1)
	end)

	it("Abgelaufene Boosts werden entfernt", function()
		data.activeBoosts.feathers2x = workspace:GetServerTimeNow() - 1
		expect(Stats:extraMultiplier(player)).toBe(1)
		expect(data.activeBoosts.feathers2x == nil).toBeTruthy()
	end)

	-- Stand wiederherstellen
	for k, v in backup do
		data[k] = v
	end
	PD:markChanged(player, "dailyReward", "feathers", "lifetimeFeathers", "rank", "activeBoosts")
	Stats:refreshBoostAttributes(player)
end
