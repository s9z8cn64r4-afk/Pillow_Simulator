--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Daily = require(Shared.Util.Daily)

return function(it, expect)
	local DAY = 86400
	local t0 = 20000 * DAY + 3600 -- beliebiger Tag, 01:00 UTC

	it("noch nie abgeholt → abholbar", function()
		expect(Daily.canClaim(0, t0)).toBeTruthy()
	end)
	it("gleicher UTC-Tag → nicht abholbar, auch kurz vor Mitternacht", function()
		expect(Daily.canClaim(t0, t0 + 5)).toBeFalsy()
		expect(Daily.canClaim(t0, 20001 * DAY - 1)).toBeFalsy()
	end)
	it("nächster UTC-Tag → abholbar, auch eine Sekunde nach Mitternacht", function()
		expect(Daily.canClaim(t0, 20001 * DAY)).toBeTruthy()
		expect(Daily.canClaim(t0, t0 + 5 * DAY)).toBeTruthy()
	end)
	it("Kette 1..7, danach wieder 1", function()
		expect(Daily.nextDay(0)).toBe(1)
		expect(Daily.nextDay(3)).toBe(4)
		expect(Daily.nextDay(7)).toBe(1)
	end)
	it("Sekunden bis zum nächsten Tag", function()
		expect(Daily.secondsUntilNext(t0)).toBe(DAY - 3600)
	end)
end
