--!strict
-- Einstellungen: Lautstärken in 25-%-Schritten, Reduced Motion, Low VFX, UI-Größe.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local SettingsPanel = {}

function SettingsPanel.build(root: Instance)
	local m = C.modal(root, "SETTINGS", UDim2.fromOffset(560, 440))
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = m.body

	local refreshers: { (any) -> () } = {}
	local order = 0

	local function row(label: string)
		order += 1
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 62)
		f.BackgroundColor3 = Theme.color.bgSoft
		f.LayoutOrder = order
		f.Parent = m.body
		C.corner(f)
		local t = C.text({ text = label, size = Theme.size.sm, align = Enum.TextXAlignment.Left })
		t.Position = UDim2.fromOffset(14, 0)
		t.Size = UDim2.new(0.45, 0, 1, 0)
		t.Parent = f
		local controls = Instance.new("Frame")
		controls.BackgroundTransparency = 1
		controls.AnchorPoint = Vector2.new(1, 0.5)
		controls.Position = UDim2.new(1, -8, 0.5, 0)
		controls.Size = UDim2.new(0.55, -8, 0, 52)
		controls.Parent = f
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Right
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.Padding = UDim.new(0, 6)
		l.Parent = controls
		return controls
	end

	-- Lautstärke: − Wert +
	local function volume(key: string, label: string)
		local controls = row(label)
		local minus = C.button({ text = "-", size = UDim2.fromOffset(52, 52), color = Theme.color.bg })
		minus.instance.LayoutOrder = 1
		minus.instance.Parent = controls
		local value = C.text({ text = "", size = Theme.size.sm })
		value.Size = UDim2.fromOffset(70, 52)
		value.LayoutOrder = 2
		value.Parent = controls
		local plus = C.button({ text = "+", size = UDim2.fromOffset(52, 52), color = Theme.color.bg })
		plus.instance.LayoutOrder = 3
		plus.instance.Parent = controls
		local current = 0
		minus.button.Activated:Connect(function()
			NetClient.fire("SetSetting", key, math.max(0, current - 0.25))
		end)
		plus.button.Activated:Connect(function()
			NetClient.fire("SetSetting", key, math.min(1, current + 0.25))
		end)
		table.insert(refreshers, function(st)
			current = st[key]
			value.Text = ("%d%%"):format(math.floor(current * 100 + 0.5))
		end)
	end

	-- Ein/Aus-Schalter
	local function toggle(key: string, label: string)
		local controls = row(label)
		local b = C.button({ text = "", size = UDim2.fromOffset(120, 52), color = Theme.color.locked })
		b.instance.Parent = controls
		local current = false
		b.button.Activated:Connect(function()
			NetClient.fire("SetSetting", key, not current)
		end)
		table.insert(refreshers, function(st)
			current = st[key]
			b.setText(if current then "ON" else "OFF")
			b.setColor(if current then Theme.color.success else Theme.color.locked)
		end)
	end

	volume("music", "Music")
	volume("sfx", "Sound effects")
	toggle("reducedMotion", "Reduced motion")
	toggle("lowVfx", "Low effects")

	do
		local controls = row("UI size")
		local buttons = {}
		for i, v in { 0.9, 1, 1.15 } do
			local b = C.button({
				text = ("%d%%"):format(math.floor(v * 100 + 0.5)),
				size = UDim2.fromOffset(72, 52),
				color = Theme.color.bg,
			})
			b.instance.LayoutOrder = i
			b.instance.Parent = controls
			b.button.Activated:Connect(function()
				NetClient.fire("SetSetting", "uiScale", v)
			end)
			buttons[v] = b
		end
		table.insert(refreshers, function(st)
			for v, b in buttons do
				b.setColor(if st.uiScale == v then Theme.color.primary else Theme.color.bg)
			end
		end)
	end

	local api = {}
	api.toggle = m.toggle
	function api.refresh(s: any)
		for _, fn in refreshers do
			fn(s.settings)
		end
	end
	return api
end

return SettingsPanel
