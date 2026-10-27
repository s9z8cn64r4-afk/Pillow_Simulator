--!strict
-- Daily Reward / Willkommen-zurück-Karte: 7 Tage, aktueller Tag hervorgehoben, Abholen per Server.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local Rewards = require(Shared.Config.Rewards)
local Daily = require(Shared.Util.Daily)

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local DailyPanel = {}

local function rewardText(def: any): string
	if def.kind == "feathersMinutes" then
		return ("🕊️ %d min"):format(def.amount)
	end
	local b = Rewards.boosts[def.boost]
	return ("%gx\n%d min"):format(b and b.multiplier or 2, def.minutes)
end

function DailyPanel.build(root: Instance)
	local m = C.modal(root, "DAILY REWARD", UDim2.fromOffset(640, 380))
	local title = m.panel:FindFirstChildWhichIsA("TextLabel") :: TextLabel

	local sub = C.text({
		text = "Come back every day! Missing a day only pauses your streak.",
		size = Theme.size.xs,
		color = Theme.color.muted,
		font = Theme.font.body,
	})
	sub.Size = UDim2.new(1, 0, 0, 22)
	sub.Parent = m.body

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Position = UDim2.fromOffset(0, 32)
	row.Size = UDim2.new(1, 0, 0, 130)
	row.Parent = m.body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(78, 126)
	grid.CellPadding = UDim2.fromOffset(6, 0)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = row

	local tiles = {}
	for i, def in Rewards.daily do
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Theme.color.bgSoft
		f.LayoutOrder = i
		f.Parent = row
		C.corner(f)
		local stroke = C.stroke(f, 3, Theme.color.bgSoft)
		local dayLabel = C.text({ text = "Day " .. i, size = Theme.size.xs, color = Theme.color.muted })
		dayLabel.Size = UDim2.new(1, 0, 0, 26)
		dayLabel.Parent = f
		local reward = C.text({
			text = rewardText(def),
			size = Theme.size.sm,
			color = if def.kind == "boost" then Theme.color.secondary else Theme.color.feather,
		})
		reward.Position = UDim2.fromOffset(0, 30)
		reward.Size = UDim2.new(1, 0, 0, 56)
		reward.TextWrapped = true
		reward.Parent = f
		local state = C.text({ text = "", size = Theme.size.xs, color = Theme.color.success })
		state.Position = UDim2.fromOffset(0, 92)
		state.Size = UDim2.new(1, 0, 0, 26)
		state.Parent = f
		tiles[i] = { frame = f, stroke = stroke, state = state }
	end

	local claim = C.button({ text = "CLAIM", size = UDim2.fromOffset(260, 64), color = Theme.color.success })
	claim.instance.AnchorPoint = Vector2.new(0.5, 1)
	claim.instance.Position = UDim2.new(0.5, 0, 1, 0)
	claim.instance.Parent = m.body
	claim.button.Activated:Connect(function()
		NetClient.fire("ClaimDaily")
	end)

	local api = {}
	api.toggle = m.toggle
	api.isOpen = m.isOpen
	local lastState: any = nil

	function api.claimable(s: any): boolean
		return s ~= nil
			and s.dailyReward ~= nil
			and Daily.canClaim(s.dailyReward.lastClaimUnix, workspace:GetServerTimeNow())
	end

	function api.refresh(s: any)
		lastState = s
		local dr = s.dailyReward
		if not dr then
			return
		end
		local can = api.claimable(s)
		title.Text = if dr.streakDay > 0 and can then "WELCOME BACK!" else "DAILY REWARD"
		-- Tage dieser Runde: abgeholt bis streakDay; ist heute abholbar, ist der nächste Tag „heute“
		local today = if can then Daily.nextDay(dr.streakDay) else dr.streakDay
		local cycleDone = can and dr.streakDay == Daily.CYCLE -- neue Runde beginnt
		for i, t in tiles do
			local claimed = not cycleDone and i <= dr.streakDay
			local isToday = i == today
			t.frame.BackgroundTransparency = if claimed and not isToday then 0.45 else 0
			t.stroke.Color = if isToday then Theme.color.feather else Theme.color.bgSoft
			t.stroke.Thickness = if isToday then 4 else 3
			t.state.Text = if claimed and not (isToday and can)
				then "CLAIMED"
				elseif isToday and can then "TODAY"
				else ""
			t.state.TextColor3 = if isToday and can then Theme.color.feather else Theme.color.success
		end
		if can then
			claim.setText("CLAIM")
			claim.setColor(Theme.color.success)
			claim.setEnabled(true)
		else
			local left = Daily.secondsUntilNext(workspace:GetServerTimeNow())
			claim.setText(("Next in %dh %02dm"):format(left // 3600, (left % 3600) // 60))
			claim.setColor(Theme.color.locked)
			claim.setEnabled(false)
		end
	end

	-- Countdown aktuell halten, solange das Fenster offen ist
	task.spawn(function()
		while true do
			task.wait(30)
			if lastState and m.isOpen() then
				api.refresh(lastState)
			end
		end
	end)

	return api
end

return DailyPanel
