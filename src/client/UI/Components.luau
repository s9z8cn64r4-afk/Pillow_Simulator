--!strict
-- Schlanke UI-Bausteine (ADR-0003). Jede Funktion erzeugt Instanzen; Animationen respektieren Reduced Motion.
local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.Theme)

local Components = {}
Components.reducedMotion = false

local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local dur = if Components.reducedMotion then t * 0.3 else t
	local tw = TweenService:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
Components.tween = tween

function Components.corner(parent: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or Theme.radius.button)
	c.Parent = parent
	return c
end

function Components.stroke(parent: Instance, thickness: number?, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 3
	s.Color = color or Theme.color.stroke
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function Components.padding(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	for _, side in { "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight" } do
		(p :: any)[side] = UDim.new(0, px)
	end
	p.Parent = parent
	return p
end

export type TextProps = {
	text: string,
	size: number?,
	color: Color3?,
	font: Enum.Font?,
	align: Enum.TextXAlignment?,
}

function Components.text(props: TextProps): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = props.text
	l.Font = props.font or Theme.font.display
	l.TextSize = props.size or Theme.size.sm
	l.TextColor3 = props.color or Theme.color.surface
	l.TextXAlignment = props.align or Enum.TextXAlignment.Center
	l.TextStrokeTransparency = 0.35
	l.TextStrokeColor3 = Theme.color.stroke
	l.TextWrapped = true
	l.Size = UDim2.fromScale(1, 1)
	return l
end

export type ButtonProps = {
	text: string,
	color: Color3?,
	size: UDim2,
	textSize: number?,
	onClick: (() -> ())?,
	onPress: (() -> ())?,
	onRelease: (() -> ())?,
}

-- Button mit Hover-Vergrößerung, Press-Squash und Disabled-Zustand
function Components.button(props: ButtonProps)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = props.size

	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.fromScale(0.5, 0.5)
	b.Size = UDim2.fromScale(1, 1)
	b.BackgroundColor3 = props.color or Theme.color.primary
	b.Text = ""
	b.Parent = holder
	Components.corner(b)
	Components.stroke(b)
	local label = Components.text({ text = props.text, size = props.textSize or Theme.size.sm })
	label.Parent = b

	local scale = Instance.new("UIScale")
	scale.Parent = b
	local enabled = true

	b.MouseEnter:Connect(function()
		if enabled then
			tween(scale, Theme.motion.fast, { Scale = 1.04 })
		end
	end)
	b.MouseLeave:Connect(function()
		tween(scale, Theme.motion.fast, { Scale = 1 })
	end)
	b.MouseButton1Down:Connect(function()
		if not enabled then
			return
		end
		if not Components.reducedMotion then
			tween(scale, 0.06, { Scale = 0.92 })
		end
		if props.onPress then
			props.onPress()
		end
	end)
	b.MouseButton1Up:Connect(function()
		tween(scale, Theme.motion.base, { Scale = 1 }, Enum.EasingStyle.Back)
		if props.onRelease then
			props.onRelease()
		end
	end)
	b.Activated:Connect(function()
		if enabled and props.onClick then
			props.onClick()
		end
	end)

	local api = {}
	api.instance = holder
	api.button = b
	api.label = label
	function api.setText(t: string)
		label.Text = t
	end
	function api.setColor(c: Color3)
		b.BackgroundColor3 = c
	end
	function api.setEnabled(on: boolean)
		enabled = on
		b.BackgroundTransparency = if on then 0 else 0.45
		label.TextTransparency = if on then 0 else 0.35
	end
	return api
end

function Components.panel(size: UDim2, color: Color3?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.BackgroundColor3 = color or Theme.color.bg
	Components.corner(f, Theme.radius.panel)
	Components.stroke(f, 3)
	return f
end

-- Fortschrittsbalken: gibt set(alpha) zurück
function Components.progressBar(size: UDim2, fillColor: Color3)
	local bg = Instance.new("Frame")
	bg.Size = size
	bg.BackgroundColor3 = Theme.color.bgSoft
	Components.corner(bg, 999)
	Components.stroke(bg, 2)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = fillColor
	fill.Parent = bg
	Components.corner(fill, 999)
	return bg, function(alpha: number)
		tween(fill, Theme.motion.slow, { Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1) })
	end
end

return Components
