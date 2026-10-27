--!strict
-- Onboarding (GDD 4.9): sechs Aufgaben, serverseitig ausgewertet, jede erledigte Aufgabe = Funnel-Event.
-- data.tutorial.step = Anzahl erledigter Aufgaben (0–6). Überspringbar; erfahrene Profile werden still beendet.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Config.Progression)

local TutorialService = {}
TutorialService.STEPS = table.freeze({ "swing", "buyPower", "hitDummy", "buyPillow", "rank2", "goal" })
TutorialService.GOAL_DELAY = 4 -- Sekunden, die das Ziel „nächste Zone“ gezeigt wird, bevor das Tutorial endet
TutorialService.REWARD_MULT = 2
TutorialService.REWARD_SECONDS = 120
TutorialService.VETERAN_RANK = 3 -- ab diesem Rank gilt ein Profil ohne Tutorial-Fortschritt als erfahren

local Net, PlayerData, Stats, Log

function TutorialService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
	self.registry = registry
end

local function ownedCount(data: any): number
	local n = 0
	for _ in data.ownedPillows do
		n += 1
	end
	return n
end

-- Zustandsbasierte Aufgaben gelten als erledigt, wenn der Spieler sie schon vorher erfüllt hat
local function satisfied(name: string, data: any): boolean
	if name == "buyPower" then
		return data.upgrades.featherPower >= 1
	elseif name == "buyPillow" then
		return ownedCount(data) >= 2
	elseif name == "rank2" then
		return data.rank >= Progression.swing.autoSwingRank
	end
	return false
end

local function funnel(player: Player, step: number, name: string)
	Log:info("Tutorial", { userId = player.UserId, step = step, name = name })
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

function TutorialService:current(player: Player): string?
	local data = PlayerData:get(player)
	if not data or data.tutorial.completed then
		return nil
	end
	return self.STEPS[data.tutorial.step + 1]
end

function TutorialService:complete(player: Player, reward: boolean)
	local data = PlayerData:get(player)
	if not data or data.tutorial.completed then
		return
	end
	data.tutorial.completed = true
	PlayerData:markChanged(player, "tutorial")
	if reward then
		Stats:addBoost(player, "feathers2x", self.REWARD_SECONDS)
		Net:fire("Notify", player, "tutorialDone", { mult = self.REWARD_MULT, seconds = self.REWARD_SECONDS })
	end
end

-- Aufgabe abschließen, wenn sie die aktuelle ist; danach bereits erfüllte Folgeaufgaben nachziehen
function TutorialService:tryComplete(player: Player, name: string)
	local data = PlayerData:get(player)
	if not data or data.tutorial.completed or self.STEPS[data.tutorial.step + 1] ~= name then
		return
	end
	data.tutorial.step += 1
	PlayerData:markChanged(player, "tutorial")
	funnel(player, data.tutorial.step, name)
	self:catchUp(player)
end

function TutorialService:catchUp(player: Player)
	local data = PlayerData:get(player)
	local nextName = self:current(player)
	if not data or not nextName then
		return
	end
	if satisfied(nextName, data) then
		self:tryComplete(player, nextName)
	elseif nextName == "goal" then
		local stepAtStart = data.tutorial.step
		task.delay(self.GOAL_DELAY, function()
			local d = PlayerData:get(player)
			if d and not d.tutorial.completed and d.tutorial.step == stepAtStart then
				d.tutorial.step += 1
				funnel(player, d.tutorial.step, "goal")
				self:complete(player, true)
			end
		end)
	end
end

function TutorialService:skip(player: Player)
	local data = PlayerData:get(player)
	if not data or data.tutorial.completed then
		return
	end
	-- Kein Funnel-Schritt (Schrittnummern müssen eindeutige Namen behalten), sondern eigenes Event
	Log:info("Tutorial übersprungen", { userId = player.UserId, step = data.tutorial.step })
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "TutorialSkipped", data.tutorial.step)
	end)
	self:complete(player, false)
end

function TutorialService:Start()
	local reg = self.registry
	reg.SwingService.Swung:Connect(function(player, isAuto: boolean, dummy)
		if not isAuto then
			self:tryComplete(player, "swing")
			if dummy then
				self:tryComplete(player, "hitDummy")
			end
		end
	end)
	reg.ShopService.Purchased:Connect(function(player, kind: string, id: string)
		if kind == "upgrade" and id == "featherPower" then
			self:tryComplete(player, "buyPower")
		elseif kind == "pillow" then
			self:tryComplete(player, "buyPillow")
		end
	end)
	PlayerData.RankChanged:Connect(function(player)
		self:catchUp(player)
	end)
	PlayerData.Loaded:Connect(function(player, data)
		if not data.tutorial.completed and data.rank >= self.VETERAN_RANK then
			self:complete(player, false)
			return
		end
		self:catchUp(player)
	end)
	Net:on("TutorialSkip", function(player)
		self:skip(player)
	end)
end

return TutorialService
