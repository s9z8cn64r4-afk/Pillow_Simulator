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

-- Kachel je Zone (Farben wie die Tapete der Zone, `tools/studio/build_zones_v2.luau`)
local LOOK: { [string]: { icon: string, color: Color3 } } = {
	bedroom = { icon = "🛏️", color = Color3.fromRGB(178, 205, 240) },
	livingroom = { icon = "🎉", color = Color3.fromRGB(255, 204, 180) },
	hotelsuite = { icon = "🏨", color = Color3.fromRGB(150, 35, 60) },
	cloudrealm = { icon = "☁️", color = Color3.fromRGB(205, 195, 255) },
}

function ZonesPanel.build(root: Instance)
	local m = C.modal(root, "ZONES", UDim2.fromOffset(560, 400)) -- 4 Zeilen à 74 + Abstände; passt ungeschrumpft auf Phone
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
		local look = LOOK[z.id] or { icon = "🗺️", color = Theme.color.secondary }
		local tile = Instance.new("Frame")
		tile.BackgroundColor3 = look.color
		tile.Position = UDim2.fromOffset(8, 8)
		tile.Size = UDim2.fromOffset(58, 58)
		tile.Parent = f
		C.corner(tile)
		local icon = C.text({ text = look.icon, size = Theme.size.lg })
		icon.Size = UDim2.fromScale(1, 1)
		icon.Parent = tile
		local name = C.text({ text = z.name, size = Theme.size.sm, align = Enum.TextXAlignment.Left })
		name.Position = UDim2.fromOffset(78, 6)
		name.Size = UDim2.new(1, -260, 0, 30)
		name.Parent = f
		local info = C.text({
			text = ("x%d feathers"):format(z.multiplier),
			size = Theme.size.xs,
			color = Theme.color.feather,
			align = Enum.TextXAlignment.Left,
		})
		info.Position = UDim2.fromOffset(78, 40)
		info.Size = UDim2.new(1, -260, 0, 24)
		info.Parent = f
		-- „Du bist hier“-Markierung (Attribut Zone, setzt ZoneService)
		local here = C.text({ text = "📍 YOU ARE HERE", size = Theme.size.xs, color = Theme.color.success })
		here.AnchorPoint = Vector2.new(1, 0)
		here.Position = UDim2.new(1, -186, 0, 44)
		here.Size = UDim2.fromOffset(150, 22)
		here.TextXAlignment = Enum.TextXAlignment.Right
		here.Visible = false
		here.Parent = f
		local btn = C.button({ text = "", size = UDim2.fromOffset(170, 54), color = Theme.color.secondary })
		btn.instance.AnchorPoint = Vector2.new(1, 0.5)
		btn.instance.Position = UDim2.new(1, -8, 0.5, 0)
		btn.instance.Parent = f
		btn.button.Activated:Connect(function()
			NetClient.fire("TeleportZone", z.id)
			m.toggle(false)
		end)
		rows[z.id] = { btn = btn, zone = z, info = info, here = here, frame = f }
	end

	local api = {}
	api.toggle = m.toggle
	local player = game:GetService("Players").LocalPlayer
	local function markHere()
		local cur = player:GetAttribute("Zone")
		for id, r in rows do
			local isHere = id == cur
			r.here.Visible = isHere
			r.frame.BackgroundColor3 = if isHere then Theme.color.bgSoft:Lerp(Theme.color.success, 0.12) else Theme.color.bgSoft
		end
	end
	player:GetAttributeChangedSignal("Zone"):Connect(markHere)
	function api.refresh(s: any)
		markHere()
		for id, r in rows do
			local z = r.zone
			if s.unlockedZones[id] then
				r.btn.setText("TELEPORT")
				r.btn.setColor(Theme.color.secondary)
				r.btn.setEnabled(true)
			else
				local need = if s.rebirths < z.rebirths
					then ("Rebirth %d"):format(z.rebirths)
					else "🕊️ " .. NumberFormat.short(z.cost)
				r.btn.setText("🔒 " .. need)
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			end
		end
	end
	return api
end

return ZonesPanel
