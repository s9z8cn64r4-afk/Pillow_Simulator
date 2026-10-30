--!strict
-- Lebendige Deko (PS-43), rein lokal: Discokugel dreht sich langsam (Tag "AmbientSpin"), Lichterketten
-- funkeln leicht (Tag "AmbientTwinkle": alle 0,4 s werden wenige zufällige Lampen kurz gedimmt).
-- Reduced Motion: kein Drehen, kein Funkeln. Low VFX: kein Funkeln. StreamingEnabled-sicher (Tags kommen/gehen).
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local SPIN_SPEED = math.rad(20) -- Grad pro Sekunde
local TWINKLE_INTERVAL = 0.4
local TWINKLE_COUNT = 6
local DIM = 0.55

local AmbientController = {}
local State

local spinners: { [Instance]: CFrame } = {}
local bulbs: { BasePart } = {}
local dimmed: { [BasePart]: boolean } = {}

local function settings(): any
	return State and State.state and State.state.settings or {}
end

local function addSpinner(inst: Instance)
	if inst:IsA("Model") then
		spinners[inst] = inst:GetPivot()
	end
end
local function addBulb(inst: Instance)
	if inst:IsA("BasePart") then
		table.insert(bulbs, inst)
	end
end
local function removeBulb(inst: Instance)
	local i = table.find(bulbs, inst :: any)
	if i then
		table.remove(bulbs, i)
	end
	dimmed[inst :: any] = nil
end

local function undimAll()
	for b in dimmed do
		b.Transparency = 0
	end
	table.clear(dimmed)
end

function AmbientController:Init(registry)
	State = registry.PlayerStateController
end

function AmbientController:Start()
	for _, inst in CollectionService:GetTagged("AmbientSpin") do
		addSpinner(inst)
	end
	CollectionService:GetInstanceAddedSignal("AmbientSpin"):Connect(addSpinner)
	CollectionService:GetInstanceRemovedSignal("AmbientSpin"):Connect(function(inst)
		spinners[inst] = nil
	end)
	for _, inst in CollectionService:GetTagged("AmbientTwinkle") do
		addBulb(inst)
	end
	CollectionService:GetInstanceAddedSignal("AmbientTwinkle"):Connect(addBulb)
	CollectionService:GetInstanceRemovedSignal("AmbientTwinkle"):Connect(removeBulb)

	local angle = 0
	RunService.RenderStepped:Connect(function(dt)
		if settings().reducedMotion then
			return
		end
		angle = (angle + SPIN_SPEED * dt) % (math.pi * 2)
		for model, base in spinners do
			if model.Parent then
				model:PivotTo(base * CFrame.Angles(0, angle, 0))
			end
		end
	end)

	local rng = Random.new()
	task.spawn(function()
		while true do
			task.wait(TWINKLE_INTERVAL)
			local s = settings()
			undimAll()
			if not s.reducedMotion and not s.lowVfx and #bulbs > 0 then
				for _ = 1, math.min(TWINKLE_COUNT, #bulbs) do
					local b = bulbs[rng:NextInteger(1, #bulbs)]
					b.Transparency = DIM
					dimmed[b] = true
				end
			end
		end
	end)
end

return AmbientController
