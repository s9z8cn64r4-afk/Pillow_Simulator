--!strict
-- Kosmetische Effekte: 3D-Federburst, schwebende Zahlen, Puppen-Wackeln. Respektiert Low VFX / Reduced Motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local NumberFormat = require(Shared.Util.NumberFormat)
local Assets = require(Shared.Config.Assets)

local player = Players.LocalPlayer
local MAX_FEATHERS = 60 -- Performance-Budget G.6: aktive Partikel pro Spieler

local FxController = {}
local State
local pool: { BasePart } = {}
local active = 0
local featherTemplate: BasePart? = nil
local fxFolder: Folder

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

local function takeFeather(): BasePart?
	if active >= MAX_FEATHERS or not featherTemplate then
		return nil
	end
	active += 1
	local f = table.remove(pool)
	if not f then
		f = (featherTemplate :: BasePart):Clone()
	end
	f.Transparency = 0
	f.Parent = fxFolder
	return f
end

local function releaseFeather(f: BasePart)
	active -= 1
	f.Parent = nil
	table.insert(pool, f)
end

-- Federn fliegen aus dem Kissen, trudeln und verblassen (rein lokal, verankert, ohne Physik)
local function burst(origin: Vector3?, count: number)
	if not origin then
		return
	end
	local n = if settings().lowVfx then math.ceil(count / 2) else count
	local rm = settings().reducedMotion
	for _ = 1, n do
		local f = takeFeather()
		if not f then
			return
		end
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
		local dist = (if rm then 1.5 else 3) + math.random() * 2.5
		local start = CFrame.new(origin)
			* CFrame.Angles(math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		f.CFrame = start
		local life = 0.7 + math.random() * 0.5
		local target = CFrame.new(origin + dir * dist + Vector3.new(0, -1.2, 0))
			* CFrame.Angles(math.random() * 6.28, math.random() * 6.28, math.random() * 6.28)
		local t1 = TweenService:Create(
			f,
			TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = target }
		)
		local t2 = TweenService:Create(
			f,
			TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1 }
		)
		t1:Play()
		t2:Play()
		task.delay(life, releaseFeather, f)
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

local function dummyByName(name: string): Model?
	for _, d in CollectionService:GetTagged("PillowDummy") do
		if d.Name == name and d:IsA("Model") then
			return d
		end
	end
	return nil
end

local function wobbleDummy(d: Model)
	if settings().reducedMotion or not d.PrimaryPart then
		return
	end
	local body = d.PrimaryPart :: BasePart
	local base = body:GetAttribute("BaseCFrame") :: CFrame?
	if not base then
		base = body.CFrame
		body:SetAttribute("BaseCFrame", base)
	end
	local t = TweenService:Create(
		body,
		TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true),
		{
			CFrame = (base :: CFrame) * CFrame.Angles(math.rad(12), 0, 0),
		}
	)
	t:Play()
	t.Completed:Once(function()
		body.CFrame = base :: CFrame
	end)
end

-- Sofortiges Feedback beim eigenen Schlag (vor Serverantwort)
function FxController:localSwing()
	local h = handleOf(player.Character)
	burst(h and h.Position, 6)
end

function FxController:Start()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "LocalFx"
	fxFolder.Parent = workspace
	local assetsFolder = ReplicatedStorage:WaitForChild("Assets", 10)
	local tpl = assetsFolder and assetsFolder:FindFirstChild(Assets.models.feather)
	if tpl and tpl:IsA("BasePart") then
		featherTemplate = tpl
	else
		warn("[PS][WARN] Feder-Modell fehlt (ReplicatedStorage.Assets." .. Assets.models.feather .. ")")
	end

	-- Seltenheits-Effekte fremder und eigener Kissen (Server: "RarityFx…") folgen Low Effects
	local function applyRarityFx(inst: Instance)
		if (inst:IsA("ParticleEmitter") or inst:IsA("Trail")) and inst.Name:sub(1, 8) == "RarityFx" then
			inst.Enabled = not settings().lowVfx
		end
	end
	workspace.DescendantAdded:Connect(applyRarityFx)
	State.Changed:Connect(function(key)
		if key == "settings" then
			for _, d in workspace:GetDescendants() do
				applyRarityFx(d)
			end
		end
	end)

	NetClient.on("SwingFx", function(userId: number, amount: number, dummyName: string?, isAuto: boolean?)
		local who = Players:GetPlayerByUserId(userId)
		local char = who and who.Character
		local handle = handleOf(char)
		local dummy = dummyName and dummyByName(dummyName)
		if who == player then
			if handle then
				local color = if dummyName
					then Color3.fromRGB(255, 196, 60)
					else Color3.fromRGB(255, 226, 122)
				floatText(handle, "+" .. NumberFormat.short(amount), color)
			end
			if dummy then
				wobbleDummy(dummy)
				burst(dummy:GetPivot().Position + Vector3.new(0, 2, 0), 10)
			elseif isAuto then
				burst(handle and handle.Position, 4)
			end
		else
			burst(handle and handle.Position, 3)
			if dummy then
				wobbleDummy(dummy)
			end
		end
	end)
end

return FxController
