--!strict
-- Schläge: aktive Anfragen (Cooldown-geprüft) + serverseitiger Auto-Swing. Einzige Federquelle in M1.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Config.Progression)

local DUMMY_TAG = "PillowDummy"
local FX_RADIUS = 80

local SwingService = {}
local Net, PlayerData, Stats, Log
local lastSwing: { [Player]: number } = {}
SwingService.rejected = 0 -- Zähler für Tests/Monitoring

function SwingService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
end

local function rootOf(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Nächste Kissenpuppe in Reichweite (Position kommt vom Server, nicht vom Client)
local function dummyInRange(root: BasePart): Instance?
	local best, bestDist = nil, Progression.swing.dummyRange
	for _, d in CollectionService:GetTagged(DUMMY_TAG) do
		local pos: Vector3? = if d:IsA("BasePart")
			then d.Position
			elseif d:IsA("Model") then d:GetPivot().Position
			else nil
		if pos then
			local dist = (pos - root.Position).Magnitude
			if dist <= bestDist then
				best, bestDist = d, dist
			end
		end
	end
	return best
end

-- Führt einen Schlag aus und schreibt Federn gut. isAuto = Auto-Swing (kein Puppen-Bonus, 80 %).
function SwingService:performSwing(player: Player, isAuto: boolean): number
	local data = PlayerData:get(player)
	local root = rootOf(player)
	if not data or not root then
		return 0
	end
	local amount = Stats:feathersPerSwing(player)
	local dummy: Instance? = nil
	if isAuto then
		amount *= Progression.swing.autoSwingEfficiency
	else
		dummy = dummyInRange(root)
		if dummy then
			amount *= Progression.swing.dummyBonus
		end
	end
	PlayerData:addFeathers(player, amount, if isAuto then "auto_swing" else "swing")
	data.stats.totalSwings += 1
	Net:fireNear("SwingFx", root.Position, FX_RADIUS, player.UserId, amount, dummy and dummy.Name or nil, isAuto)
	return amount
end

-- Aktiver Schlag: true, wenn akzeptiert
function SwingService:requestSwing(player: Player, now: number): boolean
	if not PlayerData:isLoaded(player) then
		return false
	end
	local cd = Stats:cooldown(player)
	local last = lastSwing[player] or 0
	if now - last < cd - Progression.swing.latencyTolerance then
		self.rejected += 1
		-- Leicht zu früh ist normal (Latenz/Taktung); nur grobe Abweichungen als Verstoß werten
		if now - last < cd * 0.5 then
			Net:flag(player, "swing_too_fast")
		end
		return false
	end
	lastSwing[player] = now
	self:performSwing(player, false)
	return true
end

function SwingService:Start()
	Net:on("SwingRequest", function(player)
		self:requestSwing(player, os.clock())
	end)

	Net:on("SetAutoSwing", function(player, enabled: boolean)
		local data = PlayerData:get(player)
		if not data then
			return
		end
		if enabled and not Stats:canAutoSwing(player) then
			Net:fire("Notify", player, "error", { text = "Auto-Swing unlocks at Rank 2!" })
			enabled = false
		end
		data.autoSwingEnabled = enabled
		PlayerData:markChanged(player, "autoSwingEnabled")
	end)

	-- Auto-Swing: füllt Lücken zwischen aktiven Schlägen (gemeinsamer Cooldown)
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local data = PlayerData:get(player)
			if data and data.autoSwingEnabled and Stats:canAutoSwing(player) then
				local cd = Stats:cooldown(player)
				if now - (lastSwing[player] or 0) >= cd then
					lastSwing[player] = now
					self:performSwing(player, true)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastSwing[player] = nil
	end)
	Log:debug("SwingService bereit")
end

return SwingService
