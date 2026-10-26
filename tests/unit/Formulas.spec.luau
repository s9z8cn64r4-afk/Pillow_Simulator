--!strict
-- Paritätstest: Vektoren erzeugt mit tools/economy-sim/sim.py (2026-10-27)
local Shared = game:GetService("ReplicatedStorage").Shared
local Formulas = require(Shared.Util.Formulas)

return function(it, expect)
	it("feathersPerSwing entspricht sim.py", function()
		local vectors = {
			{ 1, 0, 1.0, 0, 0.0, 1.0, 1.0 },
			{ 16, 7, 2.0, 0, 0.06, 1.0, 93.28 },
			{ 480, 23, 4.0, 1, 0.12, 1.5, 32659.2 },
			{ 90000, 60, 8.0, 12, 0.3, 2.0, 194688000.0 },
		}
		for _, v in vectors do
			expect(Formulas.feathersPerSwing(v[1], v[2], v[3], v[4], v[5], v[6])).toBeNear(v[7])
		end
	end)
	it("upgradeCost featherPower", function()
		expect(Formulas.upgradeCost("featherPower", 0)).toBe(5)
		expect(Formulas.upgradeCost("featherPower", 1)).toBe(6)
		expect(Formulas.upgradeCost("featherPower", 10)).toBe(59)
		expect(Formulas.upgradeCost("featherPower", 40)).toBe(97133)
	end)
	it("upgradeCost swingSpeed", function()
		expect(Formulas.upgradeCost("swingSpeed", 0)).toBe(100)
		expect(Formulas.upgradeCost("swingSpeed", 1)).toBe(400)
		expect(Formulas.upgradeCost("swingSpeed", 5)).toBe(102400)
	end)
	it("rebirthCost und -Multiplikator", function()
		expect(Formulas.rebirthCost(0)).toBe(80000000)
		expect(Formulas.rebirthCost(1)).toBe(480000000)
		expect(Formulas.rebirthCost(3)).toBe(17280000000)
		expect(Formulas.rebirthMultiplier(0)).toBeNear(1)
		expect(Formulas.rebirthMultiplier(1)).toBeNear(1.5)
		expect(Formulas.rebirthMultiplier(10)).toBeNear(6)
		expect(Formulas.rebirthMultiplier(12)).toBeNear(6.5)
	end)
	it("rankIndex", function()
		expect(Formulas.rankIndex(0)).toBe(1)
		expect(Formulas.rankIndex(499)).toBe(1)
		expect(Formulas.rankIndex(500)).toBe(2)
		expect(Formulas.rankIndex(25000)).toBe(3)
		expect(Formulas.rankIndex(5e12)).toBe(10)
	end)
	it("cooldown mit Untergrenze", function()
		expect(Formulas.cooldown(0, 1.0)).toBeNear(0.6)
		expect(Formulas.cooldown(3, 0.95)).toBeNear(0.4275)
		expect(Formulas.cooldown(6, 0.88)).toBeNear(0.3)
	end)
end
