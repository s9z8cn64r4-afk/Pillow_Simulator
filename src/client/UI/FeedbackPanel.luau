--!strict
-- Feedback-/Bug-Fenster (PS-37): Kategorie wählen, Text (3–300 Zeichen), senden. Server filtert und speichert.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local Validate = require(Shared.Net.Validate)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local FeedbackPanel = {}

local CATEGORIES = {
	{ id = "bug", label = "🐞 BUG" },
	{ id = "idea", label = "💡 IDEA" },
	{ id = "other", label = "💬 OTHER" },
}

function FeedbackPanel.build(root: Instance)
	local m = C.modal(root, "FEEDBACK", UDim2.fromOffset(560, 420))
	local category = "bug"

	local hint = C.text({
		text = "Tell us what to fix or add! Please don't share personal info.",
		size = Theme.size.xs,
		color = Theme.color.muted,
		font = Theme.font.body,
	})
	hint.Size = UDim2.new(1, 0, 0, 22)
	hint.Parent = m.body

	local catRow = Instance.new("Frame")
	catRow.BackgroundTransparency = 1
	catRow.Position = UDim2.fromOffset(0, 30)
	catRow.Size = UDim2.new(1, 0, 0, 52)
	catRow.Parent = m.body
	local l = Instance.new("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	l.Padding = UDim.new(0, 8)
	l.Parent = catRow
	local catButtons = {}
	local function paint()
		for id, b in catButtons do
			b.setColor(if id == category then Theme.color.primary else Theme.color.bg)
		end
	end
	for i, c in CATEGORIES do
		local b = C.button({ text = c.label, size = UDim2.fromOffset(150, 52), color = Theme.color.bg })
		b.instance.LayoutOrder = i
		b.instance.Parent = catRow
		b.button.Activated:Connect(function()
			category = c.id
			paint()
		end)
		catButtons[c.id] = b
	end
	paint()

	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(0, 92)
	box.Size = UDim2.new(1, 0, 0, 150)
	box.BackgroundColor3 = Theme.color.bgSoft
	box.TextColor3 = Theme.color.surface
	box.PlaceholderText = "Type here..."
	box.PlaceholderColor3 = Theme.color.muted
	box.Font = Theme.font.body
	box.TextSize = Theme.size.sm
	box.TextWrapped = true
	box.MultiLine = true
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.Text = ""
	box.Parent = m.body
	C.corner(box)
	C.padding(box, 10)

	local counter = C.text({ text = "0/300", size = Theme.size.xs, color = Theme.color.muted })
	counter.AnchorPoint = Vector2.new(1, 0)
	counter.Position = UDim2.new(1, 0, 0, 246)
	counter.Size = UDim2.fromOffset(100, 20)
	counter.Parent = m.body

	local send = C.button({ text = "SEND", size = UDim2.fromOffset(220, 60), color = Theme.color.success })
	send.instance.AnchorPoint = Vector2.new(0.5, 1)
	send.instance.Position = UDim2.new(0.5, 0, 1, 0)
	send.instance.Parent = m.body

	box:GetPropertyChangedSignal("Text"):Connect(function()
		local len = utf8.len(box.Text) or 999
		if len > 300 then
			box.Text = string.sub(box.Text, 1, utf8.offset(box.Text, 301) - 1)
			return
		end
		counter.Text = ("%d/300"):format(len)
		send.setColor(if len >= 3 then Theme.color.success else Theme.color.locked)
	end)
	send.setColor(Theme.color.locked)

	local api = {}
	api.toggle = m.toggle
	api.isOpen = m.isOpen
	-- Text bleibt erhalten, bis der Server den Empfang bestätigt
	function api.sent(ok: boolean)
		if ok then
			box.Text = ""
			m.toggle(false)
		end
	end
	send.button.Activated:Connect(function()
		if Validate.validators.feedbackText(box.Text) then
			NetClient.fire("SendFeedback", category, box.Text)
		end
	end)
	return api
end

return FeedbackPanel
