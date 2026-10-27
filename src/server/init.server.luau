--!strict
-- Server-Bootstrap: Services in fester Reihenfolge laden, Init() dann Start().
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local ORDER = {
	"LogService",
	"NetService",
	"PlayerDataService",
	"StatsService",
	"PillowToolService",
	"ShopService",
	"SwingService",
	"ZoneService",
	"RebirthService",
	"RankService",
	"SettingsService",
	"TutorialService",
	"DailyRewardService",
	"TelemetryService",
	"CodeService",
	"LeaderboardService",
}

local servicesFolder = script:WaitForChild("Services")
local registry: { [string]: any } = {}

for _, name in ORDER do
	local module = servicesFolder:FindFirstChild(name)
	assert(module, "Service fehlt: " .. name)
	registry[name] = require(module) :: any
end

for _, name in ORDER do
	local svc = registry[name]
	if svc.Init then
		svc:Init(registry)
	end
end

for _, name in ORDER do
	local svc = registry[name]
	if svc.Start then
		task.spawn(function()
			svc:Start()
		end)
	end
end

registry.LogService:info("Server gestartet", { services = #ORDER })

-- Tests nur in Studio und nur wenn ausdrücklich angefordert (Attribut RunTestsOnStart am Server-Skript)
if RunService:IsStudio() and script:GetAttribute("RunTestsOnStart") then
	local tests = ServerStorage:FindFirstChild("Tests")
	if tests and tests:FindFirstChild("RunTests") then
		task.defer(function()
			require(tests.RunTests :: any).run(registry)
		end)
	end
end
