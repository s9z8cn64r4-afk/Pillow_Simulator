--!strict
-- Führt alle Unit-Specs (unit/) und, wenn ein Spieler geladen ist, Integrations-Specs (integration/) aus.
local Players = game:GetService("Players")
local TestLib = require(script.Parent.TestLib)

local RunTests = {}

local function runFolder(folder: Instance, results: TestLib.Results, ctx: any)
	local modules = folder:GetChildren()
	table.sort(modules, function(a, b)
		return a.Name < b.Name
	end)
	for _, m in modules do
		if m:IsA("ModuleScript") then
			local ok, spec = pcall(require, m)
			if not ok then
				results.failed += 1
				table.insert(results.failures, m.Name .. ": Laden fehlgeschlagen: " .. tostring(spec))
				warn("[TEST] FAIL " .. m.Name .. " (Laden) :: " .. tostring(spec))
			else
				-- Integrations-Specs dürfen den Spielerstand nicht verändern (Restore-Wächter)
				local pd = ctx.player and ctx.registry.PlayerDataService:get(ctx.player)
				local before = pd and pd.feathers
				TestLib.run(m.Name, function(it)
					(spec :: any)(it, TestLib.expect, ctx)
				end, results)
				local after = pd and ctx.registry.PlayerDataService:get(ctx.player).feathers
				if pd and before ~= after then
					results.failed += 1
					local msg = ("%s: Spielerstand nicht wiederhergestellt (Federn %s -> %s)"):format(
						m.Name,
						tostring(before),
						tostring(after)
					)
					table.insert(results.failures, msg)
					warn("[TEST] FAIL " .. msg)
				end
			end
		end
	end
end

function RunTests.run(registry: any?): TestLib.Results
	local results = TestLib.newResults()
	runFolder(script.Parent:WaitForChild("unit"), results, { registry = registry })
	if registry then
		-- Integration: auf einen geladenen Spieler warten (max. 20 s)
		local deadline = os.clock() + 20
		local player: Player? = nil
		while os.clock() < deadline do
			local p = Players:GetPlayers()[1]
			if p and registry.PlayerDataService:isLoaded(p) then
				player = p
				break
			end
			task.wait(0.25)
		end
		if player then
			runFolder(
				script.Parent:WaitForChild("integration"),
				results,
				{ registry = registry, player = player }
			)
		else
			print("[TEST] SKIP integration (kein geladener Spieler)")
		end
	end
	print(("[TEST] SUMMARY %d/%d passed"):format(results.passed, results.passed + results.failed))
	return results
end

return RunTests
