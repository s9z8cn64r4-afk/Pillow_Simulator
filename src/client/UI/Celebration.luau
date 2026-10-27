--!strict
-- Große Feier-Einblendung (Rank-Up, Rebirth, seltene Kissen): Banner mit Pop + Konfetti.
-- Reduced Motion: kein Pop, kein Konfetti. Low Effects: halbes Konfetti. Nie mehr als ein Banner gleichzeitig.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local Celebration = {}

local CONFETTI = 36
local SHOW_TIME = 2.2
local COLORS = {
	Theme.color.primary,
	Theme.color.secondary,
	Theme.color.feather,
	Theme.color.success,
	Color3.fromRGB(196, 140, 255),
}

export type Options = { title: string, subtitle: string?, color: Color3?, reducedMotion: boolean?, lowVfx: boolean? }

function Celebration.build(root: Instance)
	local layer = Instance.new("Frame")
	layer.Name = "Celebration"
	layer.Size = UDim2.fromScale(1, 1)
	layer.BackgroundTransparency = 1
	layer.ZIndex = 50
	layer.Parent = root

	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.3)
	banner.Size = UDim2.fromOffset(520, 130)
	banner.BackgroundColor3 = Theme.color.bg
	banner.Visible = false
	banner.ZIndex = 52
	banner.Parent = layer
	C.corner(banner, Theme.radius.panel)
	local stroke = C.stroke(banner, 4, Theme.color.secondary)
	local scale = Instance.new("UIScale")
	scale.Parent = banner

	local title = C.text({ text = "", size = Theme.size.xl })
	title.Size = UDim2.new(1, -24, 0, 66)
	title.Position = UDim2.fromOffset(12, 10)
	title.ZIndex = 53
	title.Parent = banner
	local sub = C.text({ text = "", size = Theme.size.md, color = Theme.color.surface })
	sub.Size = UDim2.new(1, -24, 0, 40)
	sub.Position = UDim2.fromOffset(12, 76)
	sub.ZIndex = 53
	sub.Parent = banner

	local token = 0

	local function confetti(count: number)
		for _ = 1, count do
			local f = Instance.new("Frame")
			local w = math.random(8, 14)
			f.Size = UDim2.fromOffset(w, math.floor(w * 1.6))
			f.Position = UDim2.new(math.random(), 0, -0.05, 0)
			f.Rotation = math.random(0, 360)
			f.BackgroundColor3 = COLORS[math.random(1, #COLORS)]
			f.BorderSizePixel = 0
			f.ZIndex = 51
			f.Parent = layer
			local life = 1.4 + math.random() * 0.9
			TweenService:Create(f, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(f.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.05, 0),
				Rotation = f.Rotation + math.random(-360, 360),
			}):Play()
			Debris:AddItem(f, life + 0.1)
		end
	end

	local api = {}

	function api.show(o: Options)
		token += 1
		local my = token
		local color = o.color or Theme.color.secondary
		title.Text = o.title
		title.TextColor3 = color
		sub.Text = o.subtitle or ""
		stroke.Color = color
		banner.Visible = true
		if o.reducedMotion then
			scale.Scale = 1
		else
			scale.Scale = 0.4
			TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()
			confetti(if o.lowVfx then CONFETTI // 2 else CONFETTI)
		end
		task.delay(SHOW_TIME, function()
			if token == my then
				banner.Visible = false
			end
		end)
	end

	return api
end

return Celebration
