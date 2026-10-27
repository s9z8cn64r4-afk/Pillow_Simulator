--!strict
-- Eingabe → Schlag-Anfrage. Sofortiges lokales Feedback; Federn vergibt nur der Server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local Formulas = require(Shared.Util.Formulas)
local Pillows = require(Shared.Config.Pillows)
local Signal = require(Shared.Util.Signal)

local player = Players.LocalPlayer

local SwingController = {}
SwingController.Swung = Signal.new()
SwingController.holding = false
local lastSwing = 0
local State, Fx

function SwingController:Init(registry)
	State = registry.PlayerStateController
	Fx = registry.FxController
end

function SwingController:cooldown(): number
	local s = State.state
	if not s then
		return math.huge
	end
	local pillow = Pillows.byId[s.equippedPillow] or Pillows.byId[Pillows.starter]
	return Formulas.cooldown(s.upgrades.swingSpeed, pillow.speed)
end

local function reducedMotion(): boolean
	local s = State.state
	return s ~= nil and s.settings ~= nil and s.settings.reducedMotion == true
end

-- Prozedurale Schwung-Animation (rechter Arm + Kissen-Squash) für einen beliebigen Charakter.
-- Der Arm-Schwung wird jedes Frame nach der Standard-Animation auf das Gelenk-Transform addiert
-- (RunService.Stepped). Das funktioniert für Motor6D- und AnimationConstraint-Rigs gleich.
-- Rein lokal (wird nicht repliziert); deshalb animiert jeder Client auch die Mitspieler, sobald
-- deren Schlag-Effekt ankommt (FxController → SwingFx).
type ActiveSwing = { joint: any, start: number, dur: number, angle: number }
local active: { [Model]: ActiveSwing } = {}

local function shoulderOf(char: Model): Instance?
	local arm = char:FindFirstChild("RightUpperArm")
	local j = arm and arm:FindFirstChild("RightShoulder")
	if not j then
		local torso = char:FindFirstChild("Torso")
		j = torso and torso:FindFirstChild("Right Shoulder")
	end
	if j and (j:IsA("Motor6D") or j:IsA("AnimationConstraint")) then
		return j
	end
	return nil
end

-- Winkel (Grad) über die Schwungdauer: schnell ausholen (40 %), dann mit Überschwung zurück
local function swingAngle(alpha: number, maxAngle: number): number
	if alpha < 0.4 then
		local t = alpha / 0.4
		return maxAngle * (1 - (1 - t) * (1 - t))
	end
	local t = (alpha - 0.4) / 0.6
	-- Back-Out von 1 → 0 (leichter Überschwung nach vorn)
	local c = 1.70158
	local e = 1 + (c + 1) * (t - 1) ^ 3 + c * (t - 1) ^ 2
	return maxAngle * (1 - e)
end

RunService.Stepped:Connect(function()
	local now = os.clock()
	for char, sw in active do
		local alpha = (now - sw.start) / sw.dur
		if alpha >= 1 or not sw.joint.Parent then
			active[char] = nil
		else
			local a = swingAngle(alpha, sw.angle)
			sw.joint.Transform = sw.joint.Transform
				* CFrame.Angles(math.rad(a), 0, math.rad(-20 * a / sw.angle))
		end
	end
end)

function SwingController.animateCharacter(char: Model, cd: number)
	if active[char] then
		return -- laufende Bewegung nicht abbrechen (sonst ruckelt der Arm bei schnellem Takt)
	end
	-- sichtbare Dauer: ~55 % des Cooldowns, mindestens 0,16 s, höchstens 0,32 s
	local dur = math.clamp(cd * 0.55, 0.16, 0.32)
	local joint = shoulderOf(char)
	if joint then
		active[char] = {
			joint = joint,
			start = os.clock(),
			dur = dur,
			angle = if reducedMotion() then 45 else 110,
		}
	end
	-- Squash & Stretch: SpecialMesh (Platzhalter) oder MeshPart-Größe (generierte Modelle)
	local tool = char:FindFirstChild("Pillow")
	local handle = tool and tool:FindFirstChild("Handle") :: BasePart?
	if handle and not reducedMotion() then
		local mesh = handle:FindFirstChildOfClass("SpecialMesh")
		local squash = Vector3.new(1.25, 0.7, 1.2)
		if mesh then
			mesh.Scale = squash
			TweenService
				:Create(mesh, TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
					Scale = Vector3.new(1, 1, 1),
				})
				:Play()
		else
			local base = handle:GetAttribute("BaseSize") :: Vector3?
			if base then
				handle.Size = base * squash
				TweenService
					:Create(handle, TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
						Size = base,
					})
					:Play()
			end
		end
	end
end

local function animate(cd: number)
	local char = player.Character
	if char then
		SwingController.animateCharacter(char, cd)
	end
end

function SwingController:trySwing(): boolean
	local now = os.clock()
	local cd = self:cooldown()
	if now - lastSwing < cd + 0.02 then
		return false
	end
	lastSwing = now
	NetClient.fire("SwingRequest")
	animate(cd)
	Fx:localSwing()
	self.Swung:Fire()
	return true
end

function SwingController:setHolding(on: boolean)
	self.holding = on
	if on then
		self:trySwing()
	end
end

local function hookTool(tool: Instance)
	if not tool:IsA("Tool") or tool.Name ~= "Pillow" then
		return
	end
	tool.Activated:Connect(function()
		SwingController:setHolding(true)
	end)
	tool.Deactivated:Connect(function()
		SwingController:setHolding(false)
	end)
	tool.Unequipped:Connect(function()
		SwingController:setHolding(false)
	end)
end

function SwingController:Start()
	local function onChar(char: Model)
		for _, c in char:GetChildren() do
			hookTool(c)
		end
		char.ChildAdded:Connect(hookTool)
	end
	if player.Character then
		onChar(player.Character)
	end
	player.CharacterAdded:Connect(onChar)
	-- Gamepad: R2 halten = Dauerschlag (Werkzeug-Aktivierung greift bei Gamepads nicht zuverlässig)
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.ButtonR2 and not processed then
			self:setHolding(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonR2 then
			self:setHolding(false)
		end
	end)
	-- Gedrückt halten = Dauerschlag
	RunService.Heartbeat:Connect(function()
		if self.holding then
			self:trySwing()
		end
	end)
end

return SwingController
