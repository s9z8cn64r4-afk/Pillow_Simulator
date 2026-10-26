--!strict
-- Mini-Testframework: describe/it/expect. Ausgabe "[TEST] PASS|FAIL ..." und Zusammenfassung.
local TestLib = {}

export type Results = { passed: number, failed: number, failures: { string } }

function TestLib.newResults(): Results
	return { passed = 0, failed = 0, failures = {} }
end

local function fmt(v: any): string
	if type(v) == "number" then
		return string.format("%.10g", v)
	end
	return tostring(v)
end

function TestLib.expect(actual: any)
	local e = {}
	function e.toBe(expected: any)
		if actual ~= expected then
			error(("erwartet %s, erhalten %s"):format(fmt(expected), fmt(actual)), 2)
		end
	end
	function e.toBeNear(expected: number, eps: number?)
		local tol = eps or 1e-6 * math.max(1, math.abs(expected))
		if type(actual) ~= "number" or math.abs(actual - expected) > tol then
			error(("erwartet ≈%s, erhalten %s"):format(fmt(expected), fmt(actual)), 2)
		end
	end
	function e.toBeTruthy()
		if not actual then
			error("erwartet truthy, erhalten " .. fmt(actual), 2)
		end
	end
	function e.toBeFalsy()
		if actual then
			error("erwartet falsy, erhalten " .. fmt(actual), 2)
		end
	end
	function e.toBeGreaterThan(n: number)
		if not (actual > n) then
			error(("erwartet > %s, erhalten %s"):format(fmt(n), fmt(actual)), 2)
		end
	end
	return e
end

-- spec: function(it) ... end ; it(name, fn)
function TestLib.run(suiteName: string, spec: (it: (string, () -> ()) -> ()) -> (), results: Results)
	spec(function(name: string, fn: () -> ())
		local ok, err = pcall(fn)
		local full = suiteName .. " › " .. name
		if ok then
			results.passed += 1
			print("[TEST] PASS " .. full)
		else
			results.failed += 1
			table.insert(results.failures, full .. ": " .. tostring(err))
			warn("[TEST] FAIL " .. full .. " :: " .. tostring(err))
		end
	end)
end

return TestLib
