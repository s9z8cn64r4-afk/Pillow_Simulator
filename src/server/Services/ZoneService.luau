--!strict
-- Zonen: Erkennung per Position (ZoneVolume-Tags), Freischaltung per ProximityPrompt an der Barriere, Teleport.
-- Der Zonen-Multiplikator gilt nur, wenn der Server den Spieler in einer freigeschalteten Zone verortet.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared.Config.Zones)

local VOLUME_TAG = "ZoneVolume"
local BARRIER_TAG = "ZoneBarrier"
local SPAWN_TAG = "ZoneSpawn"
local CHECK_INTERVAL = 0.25

local ZoneService = {}
local Net, PlayerData, Stats, Log

function ZoneService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
	Stats = registry.StatsService
	Log = registry.LogService
end

local function inside(part: BasePart, pos: Vector3): boolean
	local p = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end

-- Zone an einer Position (nil = außerhalb aller Volumen)
function ZoneService:zoneAt(pos: Vector3): string?
	for _, v in CollectionService:GetTagged(VOLUME_TAG) do
		if v:IsA("BasePart") and inside(v, pos) then
			return v:GetAttribute("ZoneId") :: string?
		end
	end
	return nil
end

-- Gibt (true) oder (false, Grund) zurück
function ZoneService:unlock(player: Player, zoneId: string): (boolean, string?)
	local data = PlayerData:get(player)
	local zone = Zones.byId[zoneId]
	if not data or not zone then
		return false, "invalid"
	end
	if data.unlockedZones[zoneId] then
		return false, "owned"
	end
	-- Zonen nur in Reihenfolge
	local prev = Zones.list[zone.order] -- order ist 0-basiert, list 1-basiert → Vorgänger
	if prev and not data.unlockedZones[prev.id] then
		return false, "previousLocked"
	end
	if data.rebirths < zone.rebirths then
		return false, "rebirthLocked"
	end
	if not PlayerData:spendFeathers(player, zone.cost) then
		return false, "notEnough"
	end
	data.unlockedZones[zoneId] = true
	PlayerData:markChanged(player, "unlockedZones")
	Log:info("Zone freigeschaltet", { userId = player.UserId, zone = zoneId })
	return true, nil
end

function ZoneService:spawnCFrame(zoneId: string): CFrame?
	for _, s in CollectionService:GetTagged(SPAWN_TAG) do
		if s:IsA("BasePart") and s:GetAttribute("ZoneId") == zoneId then
			return s.CFrame + Vector3.new(0, 4, 0)
		end
	end
	return nil
end

function ZoneService:teleport(player: Player, zoneId: string): (boolean, string?)
	local data = PlayerData:get(player)
	if not data or not data.unlockedZones[zoneId] then
		return false, "zoneLocked"
	end
	local cf = self:spawnCFrame(zoneId)
	local char = player.Character
	if not cf or not char then
		return false, "invalid"
	end
	char:PivotTo(cf)
	return true, nil
end

local function setupBarrier(barrier: Instance)
	if not barrier:IsA("BasePart") then
		return
	end
	local zoneId = barrier:GetAttribute("ZoneId") :: string?
	local zone = zoneId and Zones.byId[zoneId]
	if not zone or barrier:FindFirstChildOfClass("ProximityPrompt") then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Unlock " .. zone.name
	prompt.ObjectText = "Zone"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = barrier
	prompt.Triggered:Connect(function(player)
		local ok, why = ZoneService:unlock(player, zone.id)
		Net:fire("Notify", player, "purchaseResult", { ok = ok, kind = "zone", id = zone.id, reason = why })
	end)
end

function ZoneService:Start()
	for _, b in CollectionService:GetTagged(BARRIER_TAG) do
		setupBarrier(b)
	end
	CollectionService:GetInstanceAddedSignal(BARRIER_TAG):Connect(setupBarrier)

	Net:on("TeleportZone", function(player, zoneId: string)
		local ok, why = self:teleport(player, zoneId)
		if not ok then
			Net:fire("Notify", player, "purchaseResult", { ok = false, kind = "teleport", id = zoneId, reason = why })
		end
	end)

	-- Zonen-Erkennung (gedrosselt). Gesperrte Zone oder außerhalb → kein Zonen-Multiplikator.
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < CHECK_INTERVAL then
			return
		end
		acc = 0
		for _, player in Players:GetPlayers() do
			local data = PlayerData:get(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if data and root then
				local z = self:zoneAt(root.Position)
				local effective = if z and data.unlockedZones[z] then z else nil
				Stats.currentZone[player] = effective
				if player:GetAttribute("Zone") ~= effective then
					player:SetAttribute("Zone", effective)
				end
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		Stats.currentZone[player] = nil
	end)
end

return ZoneService
