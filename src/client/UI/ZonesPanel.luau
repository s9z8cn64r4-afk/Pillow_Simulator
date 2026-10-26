--!strict
-- Zonen-Übersicht: Teleport zu offenen Zonen, Preise/Bedingungen der gesperrten.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local NumberFormat = require(Shared.Util.NumberFormat)
local Zones = require(Shared.Config.Zones)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local ZonesPanel = {}

function ZonesPanel.build(root: Instance)
	local m = C.modal(root, "ZONES", UDim2.fromOffset(560, 440))
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = m.body

	local rows = {}
	for _, z in Zones.list do
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 0, 74)
		f.BackgroundColor3 = Theme.color.bgSoft
		f.LayoutOrder = z.order
		f.Parent = m.body
		C.corner(f)
		local name = C.text({ text = z.name, size = Theme.size.sm, align = Enum.TextXAlignment.Left })
		name.Position = UDim2.fromOffset(14, 6)
		name.Size = UDim2.new(1, -200, 0, 30)
		name.Parent = f
		local info = C.text({ text = ("x%d feathers"):format(z.multiplier), size = Theme.size.xs, color = Theme.color.muted, font = Theme.font.body, align = Enum.TextXAlignment.Left })
		info.Position = UDim2.fromOffset(14, 40)
		info.Size = UDim2.new(1, -200, 0, 24)
		info.Parent = f
		local btn = C.button({ text = "", size = UDim2.fromOffset(170, 54), color = Theme.color.secondary })
		btn.instance.AnchorPoint = Vector2.new(1, 0.5)
		btn.instance.Position = UDim2.new(1, -8, 0.5, 0)
		btn.instance.Parent = f
		btn.button.Activated:Connect(function()
			NetClient.fire("TeleportZone", z.id)
			m.toggle(false)
		end)
		rows[z.id] = { btn = btn, zone = z, info = info }
	end

	local api = {}
	api.toggle = m.toggle
	function api.refresh(s: any)
		for id, r in rows do
			local z = r.zone
			if s.unlockedZones[id] then
				r.btn.setText("TELEPORT")
				r.btn.setColor(Theme.color.secondary)
				r.btn.setEnabled(true)
			else
				local need = if s.rebirths < z.rebirths then ("Rebirth %d"):format(z.rebirths) else "🕊️ " .. NumberFormat.short(z.cost)
				r.btn.setText("🔒 " .. need)
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			end
		end
	end
	return api
end

return ZonesPanel
