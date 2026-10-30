--!strict
-- Rebirth-Menü: „Du verlierst / Du behältst / Du bekommst“ + Bestätigung (GDD 4.6).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local NumberFormat = require(Shared.Util.NumberFormat)
local Formulas = require(Shared.Util.Formulas)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local RebirthPanel = {}

function RebirthPanel.build(root: Instance)
	local m = C.modal(root, "REBIRTH", UDim2.fromOffset(620, 440))
	local function column(x: number, icon: string, heading: string, color: Color3)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Theme.color.bgSoft
		f.Position = UDim2.new(x, 4, 0, 0)
		f.Size = UDim2.new(1 / 3, -8, 0, 196)
		f.Parent = m.body
		C.corner(f)
		C.stroke(f, 2, color)
		local ic = C.text({ text = icon, size = Theme.size.lg })
		ic.Position = UDim2.fromOffset(0, 4)
		ic.Size = UDim2.new(1, 0, 0, 36)
		ic.Parent = f
		local h = C.text({ text = heading, size = Theme.size.sm, color = color })
		h.Position = UDim2.fromOffset(0, 38)
		h.Size = UDim2.new(1, 0, 0, 28)
		h.Parent = f
		-- größere Schrift (Phone): Karten haben genug Platz
		local body = C.text({ text = "", size = Theme.size.sm, font = Theme.font.body })
		body.Position = UDim2.fromOffset(8, 70)
		body.Size = UDim2.new(1, -16, 1, -76)
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.TextWrapped = true
		body.LineHeight = 1.25
		body.Parent = f
		return body
	end
	local lose = column(0, "🕊️", "You lose", Theme.color.danger)
	local keep = column(1 / 3, "🛏️", "You keep", Theme.color.secondary)
	local gain = column(2 / 3, "✨", "You get", Theme.color.success)
	keep.Text = "All pillows\nYour rank\nDaily rewards\nSettings"

	local status = C.text({ text = "", size = Theme.size.sm })
	status.Position = UDim2.fromOffset(0, 204)
	status.Size = UDim2.new(1, 0, 0, 28)
	status.Parent = m.body
	-- Fortschritt bis zur Rebirth-Bedingung
	local bar, setBar = C.progressBar(UDim2.new(0.7, 0, 0, 18), Theme.color.feather)
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 236)
	bar.Parent = m.body

	local confirmArmed = false
	local btn = C.button({
		text = "REBIRTH",
		size = UDim2.fromOffset(260, 60),
		color = Theme.color.primary,
		textSize = Theme.size.md,
	})
	btn.instance.AnchorPoint = Vector2.new(0.5, 1)
	btn.instance.Position = UDim2.new(0.5, 0, 1, 0)
	btn.instance.Parent = m.body
	btn.button.Activated:Connect(function()
		-- Zweistufige Bestätigung gegen versehentliches Zurücksetzen
		if not confirmArmed then
			confirmArmed = true
			btn.setText("TAP AGAIN TO CONFIRM")
			btn.setColor(Theme.color.danger)
			task.delay(3, function()
				confirmArmed = false
				btn.setText("REBIRTH")
				btn.setColor(Theme.color.primary)
			end)
		else
			confirmArmed = false
			NetClient.fire("Rebirth")
			m.toggle(false)
		end
	end)

	local api = {}
	api.toggle = m.toggle
	function api.refresh(s: any)
		local cost = Formulas.rebirthCost(s.rebirths)
		local cur = Formulas.rebirthMultiplier(s.rebirths)
		local nxt = Formulas.rebirthMultiplier(s.rebirths + 1)
		lose.Text = ("All feathers (%s)\nAll upgrades\nUnlocked zones"):format(NumberFormat.short(s.feathers))
		gain.Text = ("Feather multiplier\nx%.2f → x%.2f\nRebirth %d"):format(cur, nxt, s.rebirths + 1)
		local can = s.feathers >= cost
		status.Text = if can
			then ("Ready! (%s feathers needed)"):format(NumberFormat.short(cost))
			else ("%s / %s feathers"):format(NumberFormat.short(s.feathers), NumberFormat.short(cost))
		setBar(s.feathers / cost)
		status.TextColor3 = if can then Theme.color.success else Theme.color.muted
		btn.setEnabled(can)
	end
	return api
end

return RebirthPanel
