--!strict
-- Pillow Index: Sammlung aller Kissen (besessen / gesperrt mit Bedingung) und Fortschritt x/14.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared.Util.NumberFormat)
local Pillows = require(Shared.Config.Pillows)
local Zones = require(Shared.Config.Zones)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local IndexPanel = {}

function IndexPanel.build(root: Instance)
	local m = C.modal(root, "PILLOW INDEX", UDim2.fromOffset(640, 440))
	local progress = C.text({ text = "", size = Theme.size.sm, color = Theme.color.feather })
	progress.Size = UDim2.new(1, 0, 0, 26)
	progress.Parent = m.body

	local grid = Instance.new("ScrollingFrame")
	grid.Position = UDim2.fromOffset(0, 32)
	grid.Size = UDim2.new(1, 0, 1, -32)
	grid.BackgroundTransparency = 1
	grid.BorderSizePixel = 0
	grid.ScrollBarThickness = 8
	grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	grid.CanvasSize = UDim2.new()
	grid.Parent = m.body
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(140, 110)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid

	local rarity: { [string]: any } = {}
	for _, r in Pillows.rarities do
		rarity[r.id] = { color = Color3.fromRGB(r.color[1], r.color[2], r.color[3]), symbol = r.symbol }
	end

	local cards = {}
	for _, p in Pillows.list do
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Theme.color.bgSoft
		f.LayoutOrder = p.order
		f.Parent = grid
		C.corner(f)
		local stroke = C.stroke(f, 3, rarity[p.rarity].color)
		local sym =
			C.text({ text = rarity[p.rarity].symbol, size = Theme.size.lg, color = rarity[p.rarity].color })
		sym.Size = UDim2.new(1, 0, 0, 40)
		sym.Parent = f
		local name = C.text({ text = p.name, size = Theme.size.xs })
		name.Position = UDim2.fromOffset(4, 40)
		name.Size = UDim2.new(1, -8, 0, 34)
		name.Parent = f
		local state =
			C.text({ text = "", size = Theme.size.xs, font = Theme.font.body, color = Theme.color.muted })
		state.Position = UDim2.fromOffset(4, 76)
		state.Size = UDim2.new(1, -8, 0, 28)
		state.Parent = f
		cards[p.id] = { frame = f, stroke = stroke, state = state, name = name, pillow = p }
	end

	local api = {}
	api.toggle = m.toggle
	function api.refresh(s: any)
		local owned = 0
		for id, c in cards do
			local p = c.pillow
			if s.ownedPillows[id] then
				owned += 1
				c.state.Text = "✔ Owned"
				c.state.TextColor3 = Theme.color.success
				c.frame.BackgroundTransparency = 0
			else
				local need = if s.rebirths < p.rebirths
					then ("🔒 Rebirth %d"):format(p.rebirths)
					elseif not s.unlockedZones[p.zone] then "🔒 " .. Zones.byId[p.zone].name
					else "🕊️ " .. NumberFormat.short(p.cost)
				c.state.Text = need
				c.state.TextColor3 = Theme.color.muted
				c.frame.BackgroundTransparency = 0.35
			end
		end
		progress.Text = ("Collected %d / %d"):format(owned, #Pillows.list)
	end
	return api
end

return IndexPanel
