--!strict
-- Tutorial-Hinweis (GDD 4.9): Karte unter der Rang-Leiste + pulsierende Markierung des Ziel-Elements.
-- Fortschritt kommt vom Server (state.tutorial); „Skip“ beendet das Tutorial ohne Belohnung.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local TutorialHint = {}

-- Text und Ziel-Element je Aufgabe (Index = step + 1)
local TASKS = {
	{ text = "Tap SWING to hit with your pillow!", target = "swing" },
	{ text = "Open the Shop and buy Feather Power!", target = "shop" },
	{ text = "Hit a Training Dummy for a x1.5 bonus!", target = nil },
	{ text = "Buy your first new pillow in the Shop!", target = "shop" },
	{ text = "Keep swinging to reach Rank 2 and unlock Auto-Swing!", target = "rank" },
	{ text = "Your next goal: unlock the next zone!", target = "goal" },
}
TutorialHint.TASKS = TASKS

function TutorialHint.build(root: Instance, targets: { [string]: GuiObject })
	local card = Instance.new("Frame")
	card.Name = "TutorialHint"
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 70)
	card.Size = UDim2.fromOffset(520, 60)
	card.BackgroundColor3 = Theme.color.bg
	card.Visible = false
	card.ZIndex = 20
	card.Parent = root
	C.corner(card, Theme.radius.panel)
	C.stroke(card, 3, Theme.color.feather)

	local stepLabel = C.text({ text = "", size = Theme.size.xs, color = Theme.color.feather })
	stepLabel.Position = UDim2.fromOffset(12, 0)
	stepLabel.Size = UDim2.fromOffset(44, 60)
	stepLabel.ZIndex = 21
	stepLabel.Parent = card

	local label = C.text({ text = "", size = Theme.size.sm, align = Enum.TextXAlignment.Left })
	label.Position = UDim2.fromOffset(58, 0)
	label.Size = UDim2.new(1, -150, 1, 0)
	label.TextWrapped = true
	label.ZIndex = 21
	label.Parent = card

	local skip = C.button({
		text = "Skip",
		size = UDim2.fromOffset(76, 44),
		color = Theme.color.bgSoft,
		textSize = Theme.size.xs,
	})
	skip.instance.AnchorPoint = Vector2.new(1, 0.5)
	skip.instance.Position = UDim2.new(1, -8, 0.5, 0)
	skip.instance.ZIndex = 21
	skip.instance.Parent = card
	skip.button.Activated:Connect(function()
		NetClient.fire("TutorialSkip")
	end)

	-- Markierung: eigener Rahmen über dem Ziel (Ziele haben schon einen UIStroke), pulsiert;
	-- Reduced Motion: statisch
	local ring = Instance.new("Frame")
	ring.Name = "TutorialHighlight"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.new(1, 12, 1, 12)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 30
	C.corner(ring, Theme.radius.panel)
	local highlight = C.stroke(ring, 4, Theme.color.feather)
	local pulse: Tween? = nil
	local currentTarget: string? = nil

	local function setTarget(name: string?, reducedMotion: boolean)
		if name == currentTarget then
			return
		end
		currentTarget = name
		if pulse then
			pulse:Cancel()
			pulse = nil
		end
		local obj = name and targets[name]
		if not obj then
			ring.Parent = nil
			return
		end
		ring.Parent = obj
		highlight.Transparency = 0
		highlight.Thickness = 4
		if not reducedMotion then
			local t = TweenService:Create(
				highlight,
				TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.75, Thickness = 7 }
			)
			t:Play()
			pulse = t
		end
	end

	local api = {}
	function api.refresh(s: any)
		local tut = s.tutorial
		local entry = tut and not tut.completed and TASKS[tut.step + 1]
		if not entry then
			card.Visible = false
			setTarget(nil, true)
			return
		end
		card.Visible = true
		stepLabel.Text = ("%d/%d"):format(tut.step + 1, #TASKS)
		label.Text = entry.text
		setTarget(entry.target, s.settings and s.settings.reducedMotion == true)
	end
	return api
end

return TutorialHint
