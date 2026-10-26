--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Validate = require(Shared.Net.Validate)
local RateLimiter = require(Shared.Net.RateLimiter)
local Schema = require(Shared.Net.Schema)

return function(it, expect)
	it("pillowId akzeptiert nur Config-IDs", function()
		local v = Validate.validators.pillowId
		expect(v("cotton")).toBeTruthy()
		expect(v("doesnotexist")).toBeFalsy()
		expect(v(5)).toBeFalsy()
		expect(v(string.rep("a", 1000))).toBeFalsy()
		expect(v(nil)).toBeFalsy()
	end)
	it("upgradeKind und boolean", function()
		expect(Validate.validators.upgradeKind("featherPower")).toBeTruthy()
		expect(Validate.validators.upgradeKind("__index")).toBeFalsy()
		expect(Validate.validators.boolean(true)).toBeTruthy()
		expect(Validate.validators.boolean("true")).toBeFalsy()
	end)
	it("finiteNumber verwirft NaN/inf", function()
		local v = Validate.validators.finiteNumber
		expect(v(1.5)).toBeTruthy()
		expect(v(0 / 0)).toBeFalsy()
		expect(v(math.huge)).toBeFalsy()
		expect(v(-math.huge)).toBeFalsy()
	end)
	it("args: zu viele Argumente und falsche Typen", function()
		expect((Validate.args({ "pillowId" }, { "cotton" }, 1))).toBeTruthy()
		expect((Validate.args({ "pillowId" }, { "cotton", "extra" }, 2))).toBeFalsy()
		expect((Validate.args({}, { {} }, 1))).toBeFalsy()
		expect((Validate.args({ "pillowId" }, { { huge = true } }, 1))).toBeFalsy()
	end)
	it("RateLimiter: Burst, dann Nachfüllen", function()
		local rl = RateLimiter.new(2, 3)
		expect(rl:take("p", 0)).toBeTruthy()
		expect(rl:take("p", 0)).toBeTruthy()
		expect(rl:take("p", 0)).toBeTruthy()
		expect(rl:take("p", 0)).toBeFalsy()
		expect(rl:take("p", 0.5)).toBeTruthy() -- 1 Token nach 0,5 s
		expect(rl:take("p", 0.5)).toBeFalsy()
		expect(rl:take("other", 0)).toBeTruthy() -- getrennte Eimer
	end)
	it("Schema: jedes c2s-Remote hat Rate und gültige Validierer", function()
		for name, e in Schema do
			if e.dir == "c2s" then
				expect(e.rate ~= nil and e.burst ~= nil).toBeTruthy()
				for _, a in e.args or {} do
					expect(Validate.validators[a] ~= nil).toBeTruthy()
				end
			end
		end
	end)
end
