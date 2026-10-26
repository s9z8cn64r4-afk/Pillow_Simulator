--!strict
-- Kosmetische Effekte: Federburst, schwebende Zahlen, Puppen-Wackeln. Respektiert Low VFX / Reduced Motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local NumberFormat = require(Shared.Util.NumberFormat)

local player = Players.LocalPlayer
local FEATHER_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds" -- Platzhalter bis eigene Federtextur (M2)

local FxController = {}
local State
local emitters: { [Model]: ParticleEmitter } = {}

function FxController:Init(registry)
	State = registry.PlayerStateController
end

local function settings(): any
	return State.state and State.state.settings or {}
end

local function handleOf(char: Model?): BasePart?
	local tool = char and char:FindFirstChild("Pillow")
	return tool and tool:FindFirstChild("Handle") :: BasePart?
end

local function emitterFor(char: Model): ParticleEmitter?
	local handle = handleOf(char)
	if not handle then
		return nil
	end
	local existing = emitters[char]
	if existing and existing.Parent == handle then
		return existing
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "FeatherBurst"
	pe.Texture = FEATHER_TEXTURE
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 250, 240))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0.1) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(6, 12)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, -6, 0)
	pe.Drag = 3
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-180, 180)
	pe.Rate = 0
	pe.Parent = handle
	emitters[char] = pe
	return pe
end

local function burst(char: Model?, count: number)
	if not char then
		return
	end
	local pe = emitterFor(char)
	if pe then
		local n = if settings().lowVfx then math.ceil(count / 2) else count
		pe:Emit(n)
	end
end

-- Schwebende „+X“-Zahl über dem Kissen
local function floatText(at: BasePart, text: string, color: Color3)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 48)
	bb.StudsOffsetWorldSpace = Vector3.new(math.random(-10, 10) / 10, 2, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = at
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.TextStrokeColor3 = Color3.fromRGB(26, 20, 51)
	label.Parent = bb
	bb.Parent = player:WaitForChild("PlayerGui")
	local rm = settings().reducedMotion
	TweenService:Create(bb, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, if rm then 0.5 else 2.5, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(bb, 0.85)
end

local function wobbleDummy(name: string)
	if settings().reducedMotion then
		return
	end
	for _, d in CollectionService:GetTagged("PillowDummy") do
		if d.Name == name and d:IsA("Model") and d.PrimaryPart then
			local body = d.PrimaryPart
			local base = body.CFrame
			local t = TweenService:Create(body, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true), {
				CFrame = base * CFrame.Angles(math.rad(12), 0, 0),
			})
			t:Play()
			t.Completed:Once(function()
				body.CFrame = base
			end)
			return
		end
	end
end

-- Sofortiges Feedback beim eigenen Schlag (vor Serverantwort)
function FxController:localSwing()
	burst(player.Character, 8)
end

function FxController:Start()
	NetClient.on("SwingFx", function(userId: number, amount: number, dummyName: string?, isAuto: boolean?)
		local who = Players:GetPlayerByUserId(userId)
		local char = who and who.Character
		if who == player then
			local handle = handleOf(char)
			if handle then
				local color = if dummyName then Color3.fromRGB(255, 196, 60) else Color3.fromRGB(255, 226, 122)
				floatText(handle, "+" .. NumberFormat.short(amount), color)
			end
			if dummyName then
				wobbleDummy(dummyName)
				burst(char, 10)
			elseif isAuto then
				burst(char, 5)
			end
		else
			burst(char, 4)
			if dummyName then
				wobbleDummy(dummyName)
			end
		end
	end)
end

return FxController
