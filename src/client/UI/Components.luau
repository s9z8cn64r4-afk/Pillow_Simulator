--!strict
-- Schlanke UI-Bausteine (ADR-0003). Jede Funktion erzeugt Instanzen; Animationen respektieren Reduced Motion.
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Theme = require(script.Parent.Theme)

local Components = {}
Components.reducedMotion = false
Components.onAnyPress = nil :: (() -> ())? -- globaler Hook (z. B. Klick-Sound)

local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local dur = if Components.reducedMotion then t * 0.3 else t
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(dur, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
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
	silent: boolean?, -- kein globaler Klick-Hook (z. B. Schlag-Taste mit eigenem Sound)
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
		if Components.onAnyPress and not props.silent then
			Components.onAnyPress()
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

-- Modales Fenster mit Titel und Schließen-Knopf. Gibt { panel, body, toggle, isOpen } zurück.
function Components.modal(root: Instance, title: string, size: UDim2)
	local panel = Components.panel(size)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Visible = false
	panel.ZIndex = 5
	panel.Parent = root
	local scale = Instance.new("UIScale")
	scale.Scale = 0.85
	scale.Parent = panel
	local t = Components.text({ text = title, size = Theme.size.lg })
	t.Size = UDim2.new(1, 0, 0, 48)
	t.Parent = panel
	local close = Components.button({
		text = "X",
		size = UDim2.fromOffset(52, 52),
		color = Theme.color.danger,
		textSize = Theme.size.md,
	})
	close.instance.AnchorPoint = Vector2.new(1, 0)
	close.instance.Position = UDim2.new(1, -8, 0, 8)
	close.instance.Parent = panel
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(16, 64)
	body.Size = UDim2.new(1, -32, 1, -80)
	body.Parent = panel

	local api = {}
	api.panel = panel
	api.body = body
	function api.isOpen(): boolean
		return panel.Visible
	end
	function api.toggle(open: boolean?)
		local want = if open == nil then not panel.Visible else open
		if not want then
			tween(scale, Theme.motion.fast, { Scale = 0.85 })
			task.delay(Theme.motion.fast, function()
				panel.Visible = false
			end)
		else
			panel.Visible = true
			local fit = Components.fitScale(panel, root)
			scale.Scale = 0.85 * fit
			tween(scale, Theme.motion.base, { Scale = fit }, Enum.EasingStyle.Back)
		end
	end
	close.button.Activated:Connect(function()
		api.toggle(false)
	end)
	return api
end

-- Verkleinerung (und Zentrierung unter der Topbar), damit ein Fenster vollständig auf den (ggf. kleinen) Bildschirm passt (8 px Rand je Seite).
-- Größen in Referenz-Pixeln des HUD-Roots; 1 = passt bereits.
function Components.fitScale(panel: GuiObject, root: Instance): number
	if not root:IsA("GuiObject") then
		return 1
	end
	local rs = (root :: GuiObject).Size
	local ps = panel.Size
	local rw, rh = rs.X.Offset, rs.Y.Offset
	if rw <= 0 or rh <= 0 or ps.X.Offset <= 0 or ps.Y.Offset <= 0 then
		return 1
	end
	-- Roblox-Topbar (Menü/Chat) freihalten: Inset in Referenz-Pixel umrechnen, Fenster darunter zentrieren
	local absH = (root :: GuiObject).AbsoluteSize.Y
	local inset = GuiService:GetGuiInset().Y * (if absH > 0 then rh / absH else 1)
	panel.Position = UDim2.new(0.5, 0, 0.5, inset / 2)
	return math.min(1, (rw - 16) / ps.X.Offset, (rh - inset - 16) / ps.Y.Offset)
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
	return bg,
		function(alpha: number)
			tween(fill, Theme.motion.slow, { Size = UDim2.fromScale(math.clamp(alpha, 0, 1), 1) })
		end
end

-- Tooltip (nur Maus/Hover; Touch hat kein Hover): kleine Karte über dem Ziel, erscheint nach 0,35 s
local tooltipLabel: TextLabel? = nil
function Components.tooltip(target: GuiObject, text: string)
	local token = 0
	target.MouseEnter:Connect(function()
		token += 1
		local my = token
		task.delay(0.35, function()
			if my ~= token then
				return
			end
			local gui = target:FindFirstAncestorOfClass("ScreenGui")
			if not gui then
				return
			end
			if not tooltipLabel or tooltipLabel.Parent ~= gui then
				local t = Instance.new("TextLabel")
				t.Name = "Tooltip"
				t.AutomaticSize = Enum.AutomaticSize.XY
				t.BackgroundColor3 = Theme.color.stroke
				t.BackgroundTransparency = 0.05
				t.TextColor3 = Theme.color.surface
				t.Font = Theme.font.body
				t.TextSize = Theme.size.xs
				t.ZIndex = 200
				Components.corner(t, 8)
				Components.padding(t, 8)
				t.Parent = gui
				tooltipLabel = t
			end
			local tl = tooltipLabel :: TextLabel
			tl.Text = text
			-- AbsolutePosition liegt im Inset-Raum, die ScreenGui ignoriert den Inset und hat eine UIScale:
			-- beides herausrechnen, damit der Tooltip neben dem Ziel sitzt
			local scaleObj = gui:FindFirstChildOfClass("UIScale")
			local k = if scaleObj then scaleObj.Scale else 1
			local inset = if (gui :: ScreenGui).IgnoreGuiInset then GuiService:GetGuiInset() else Vector2.zero
			local pos = (target.AbsolutePosition + inset) / k
			local size = target.AbsoluteSize / k
			-- rechte Bildschirmhälfte: Tooltip links vom Ziel, sonst rechts
			if pos.X + size.X / 2 > gui.AbsoluteSize.X / (2 * k) then
				tl.AnchorPoint = Vector2.new(1, 0.5)
				tl.Position = UDim2.fromOffset(pos.X - 10, pos.Y + size.Y / 2)
			else
				tl.AnchorPoint = Vector2.new(0, 0.5)
				tl.Position = UDim2.fromOffset(pos.X + size.X + 10, pos.Y + size.Y / 2)
			end
			tl.Visible = true
		end)
	end)
	target.MouseLeave:Connect(function()
		token += 1
		if tooltipLabel then
			tooltipLabel.Visible = false
		end
	end)
end

return Components
