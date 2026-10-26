--!strict
-- Regressionstests für BUG-001 (Fehl-Kick legitimer Spieler)
local Shared = game:GetService("ReplicatedStorage").Shared
local SwingGate = require(Shared.Util.SwingGate)

local CD, TOL = 0.6, 0.08

return function(it, expect)
	it("Normales Halten mit Netz-Jitter wird nie als Verstoß gewertet", function()
		local s = SwingGate.new()
		local t = 0
		local flagged = false
		math.randomseed(42)
		for i = 1, 1000 do -- ~10 Minuten
			-- Client sendet alle cd+0,02 s; Netz bündelt jedes 10. Paket (kommt 0,05 s nach dem vorigen)
			t += if i % 10 == 0 then 0.05 else CD + 0.02 + (math.random() - 0.5) * 0.1
			local _, f = SwingGate.active(s, t, CD, TOL)
			flagged = flagged or f
		end
		expect(flagged).toBeFalsy()
	end)
	it("Spam (50 Anfragen pro Sekunde) wird erkannt", function()
		local s = SwingGate.new()
		local flagged = false
		for i = 1, 50 do
			local _, f = SwingGate.active(s, i * 0.02, CD, TOL)
			flagged = flagged or f
		end
		expect(flagged).toBeTruthy()
	end)
	it("Spam bringt höchstens einen Schlag pro Cooldown", function()
		local s = SwingGate.new()
		local accepted = 0
		for i = 1, 100 do -- 2 Sekunden Spam
			if (SwingGate.active(s, i * 0.02, CD, TOL)) then
				accepted += 1
			end
		end
		expect(accepted <= math.ceil(2 / (CD - TOL)) + 1).toBeTruthy()
	end)
	it("Auto-Swing pausiert während aktiver Schläge", function()
		local s = SwingGate.new()
		SwingGate.active(s, 10, CD, TOL)
		expect(SwingGate.auto(s, 10.5, CD)).toBeFalsy()
		expect(SwingGate.auto(s, 10.85, CD)).toBeFalsy()
	end)
	it("Auto-Swing läuft weiter, wenn der Spieler aufhört", function()
		local s = SwingGate.new()
		SwingGate.active(s, 10, CD, TOL)
		expect(SwingGate.auto(s, 11.0, CD)).toBeTruthy()
		expect(SwingGate.auto(s, 11.3, CD)).toBeFalsy()
		expect(SwingGate.auto(s, 11.65, CD)).toBeTruthy()
	end)
	it("Aktiver Schlag direkt nach Auto-Schlag: verworfen, aber kein Verstoß", function()
		local s = SwingGate.new()
		expect(SwingGate.auto(s, 5, CD)).toBeTruthy()
		local ok, flagged = SwingGate.active(s, 5.1, CD, TOL)
		expect(ok).toBeFalsy()
		expect(flagged).toBeFalsy()
	end)
end
