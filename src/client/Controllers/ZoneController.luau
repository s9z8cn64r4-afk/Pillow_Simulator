--!strict
-- Lokale Darstellung der Zonen-Barrieren: offen für Besitzer (Kollision lokal aus), sonst mit Preisschild.
-- Sicherheit: Der Server vergibt den Zonen-Multiplikator nur bei freigeschalteter Zone (ZoneService).
local CollectionService = game:GetService("CollectionService")

local ZoneController = {}
local State

function ZoneController:Init(registry)
	State = registry.PlayerStateController
end

local function applyBarrier(b: Instance)
	local s = State.state
	if not s or not b:IsA("BasePart") then
		return
	end
	local id = b:GetAttribute("ZoneId")
	local open = s.unlockedZones[id] == true
	b.CanCollide = not open
	b.Transparency = if open then 1 else 0.3
	for _, d in b:GetDescendants() do
		if d:IsA("ProximityPrompt") or d:IsA("SurfaceGui") then
			d.Enabled = not open
		end
	end
end

local function applyAll()
	for _, b in CollectionService:GetTagged("ZoneBarrier") do
		applyBarrier(b)
	end
end

function ZoneController:Start()
	State.Changed:Connect(function(key)
		if key == "unlockedZones" then
			applyAll()
		end
	end)
	State:onReady(applyAll)
	CollectionService:GetInstanceAddedSignal("ZoneBarrier"):Connect(function(b)
		task.defer(applyBarrier, b)
	end)
end

return ZoneController
