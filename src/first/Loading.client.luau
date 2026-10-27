--!strict
-- Ladebildschirm (ReplicatedFirst): ersetzt den Standard-Ladebildschirm, zeigt Titel, sanfte Feder-Animation
-- und Tipps, bis das Spiel geladen und das HUD aufgebaut ist (max. 20 s). Ohne Abhängigkeiten zu Shared,
-- weil ReplicatedFirst vor allem anderen läuft.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local C = Color3.fromRGB
local MAX_WAIT = 20

local TIPS = {
	"Hold SWING to keep hitting!",
	"Training Dummies give x1.5 feathers.",
	"Auto-Swing unlocks at Rank 2.",
	"New zones multiply your feathers.",
	"Rebirth keeps your pillows and boosts you forever.",
}

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.ResetOnSpawn = false

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = C(255, 255, 255) -- UIGradient multipliziert: Weiß = Verlaufsfarben unverfälscht
bg.Parent = gui
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new(C(92, 78, 168), C(43, 35, 80))
grad.Rotation = 90
grad.Parent = bg

local function label(text: string, size: number, color: Color3, y: number, font: Enum.Font): TextLabel
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, y)
	t.Size = UDim2.new(0.9, 0, 0, size + 12)
	t.BackgroundTransparency = 1
	t.Font = font
	t.TextSize = size
	t.TextColor3 = color
	t.Text = text
	t.TextWrapped = true
	t.Parent = bg
	return t
end

local feather = label("🕊️", 72, C(255, 255, 255), 0.36, Enum.Font.FredokaOne)
label("PILLOW SIMULATOR", 54, C(255, 226, 122), 0.5, Enum.Font.FredokaOne)
local status = label("Fluffing the pillows...", 22, C(255, 246, 236), 0.6, Enum.Font.GothamBold)
local tip = label("Tip: " .. TIPS[math.random(1, #TIPS)], 18, C(156, 147, 201), 0.88, Enum.Font.GothamBold)

gui.Parent = playerGui
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- sanftes Schweben der Feder (dezent, kein Flackern)
local float = TweenService:Create(
	feather,
	TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
	{ Position = UDim2.fromScale(0.5, 0.33), Rotation = 8 }
)
float:Play()

local t0 = os.clock()
local tipTimer = os.clock()
local function waitFor(check: () -> boolean, text: string)
	status.Text = text
	while not check() and os.clock() - t0 < MAX_WAIT do
		task.wait(0.1)
		if os.clock() - tipTimer > 4 then
			tipTimer = os.clock()
			tip.Text = "Tip: " .. TIPS[math.random(1, #TIPS)]
		end
	end
end

waitFor(function()
	return game:IsLoaded()
end, "Fluffing the pillows...")
waitFor(function()
	return playerGui:FindFirstChild("HUD") ~= nil
end, "Collecting feathers...")
-- kurz warten, bis der Spielstand angekommen ist (Federzähler ungleich Platzhalter)
task.wait(0.3)

float:Cancel()
local fade = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
TweenService:Create(bg, fade, { BackgroundTransparency = 1 }):Play()
for _, d in bg:GetChildren() do
	if d:IsA("TextLabel") then
		TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
	end
end
task.wait(0.55)
gui:Destroy()
