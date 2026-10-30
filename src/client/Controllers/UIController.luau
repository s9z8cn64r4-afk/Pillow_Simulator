--!strict
-- HUD v0: Federzähler, Rank-Fortschritt, Shop, Schlag-Taste, Auto-Swing, Nächstes Ziel, Toasts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local NetClient = require(Shared.Net.NetClient)
local NumberFormat = require(Shared.Util.NumberFormat)
local Formulas = require(Shared.Util.Formulas)
local Pillows = require(Shared.Config.Pillows)
local Zones = require(Shared.Config.Zones)
local Progression = require(Shared.Config.Progression)
local Products = require(Shared.Config.Products)

local UI = script.Parent.Parent:WaitForChild("UI")
local Theme = require(UI.Theme)
local C = require(UI.Components)
local RebirthPanel = require(UI.RebirthPanel)
local ZonesPanel = require(UI.ZonesPanel)
local SettingsPanel = require(UI.SettingsPanel)
local FeedbackPanel = require(UI.FeedbackPanel)
local IndexPanel = require(UI.IndexPanel)
local Celebration = require(UI.Celebration)
local TutorialHint = require(UI.TutorialHint)
local DailyPanel = require(UI.DailyPanel)

local player = Players.LocalPlayer
local UIController = {}
local State, Swing, Sound

local rarityInfo: { [string]: any } = {}
for _, r in Pillows.rarities do
	rarityInfo[r.id] = { color = Color3.fromRGB(r.color[1], r.color[2], r.color[3]), symbol = r.symbol }
end

local REASONS = {
	notEnough = "Not enough feathers!",
	zoneLocked = "Unlock the zone first!",
	rebirthLocked = "Needs more rebirths!",
	maxLevel = "Already maxed!",
	owned = "You already own this!",
	notOwned = "You don't own this pillow.",
	previousLocked = "Unlock the previous zone first!",
	busy = "One moment...",
}

function UIController:Init(registry)
	State = registry.PlayerStateController
	Swing = registry.SwingController
	Sound = registry.SoundController
end

-- ---------- Aufbau ----------
local gui: ScreenGui
local toastStack: Frame

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UIController:toast(text: string, color: Color3?)
	-- Dunkler Hintergrund, farbiger Rand + Text: lesbar auch bei hellen Seltenheitsfarben
	local f = C.panel(UDim2.fromOffset(360, 44), Theme.color.bg)
	local stroke = f:FindFirstChildOfClass("UIStroke")
	if stroke and color then
		stroke.Color = color
	end
	local label = C.text({ text = text, size = Theme.size.sm, color = color or Theme.color.surface })
	label.Parent = f
	f.BackgroundTransparency = 1
	f.Parent = toastStack
	C.tween(f, Theme.motion.base, { BackgroundTransparency = 0 })
	task.delay(2.4, function()
		C.tween(f, Theme.motion.base, { BackgroundTransparency = 1 })
		C.tween(label, Theme.motion.base, { TextTransparency = 1, TextStrokeTransparency = 1 })
		task.wait(Theme.motion.base + 0.05)
		f:Destroy()
	end)
end

-- Rollender Zähler
local function rollingCounter(label: TextLabel)
	local value = make("NumberValue", { Value = 0 })
	value.Changed:Connect(function(v)
		label.Text = NumberFormat.short(v)
	end)
	return function(target: number)
		C.tween(value, Theme.motion.slow, { Value = target })
	end
end

local function nextGoal(s: any): (string, number, number)
	-- Günstigstes noch nicht gekauftes, verfügbares Kissen oder nächste Zone
	local best: any = nil
	for _, p in Pillows.list do
		if not s.ownedPillows[p.id] and s.unlockedZones[p.zone] and s.rebirths >= p.rebirths then
			if not best or p.cost < best.cost then
				best = p
			end
		end
	end
	local zoneGoal: any = nil
	for _, z in Zones.list do
		if not s.unlockedZones[z.id] then
			zoneGoal = z
			break
		end
	end
	if best and (not zoneGoal or best.cost <= zoneGoal.cost) then
		return "Next: " .. best.name, s.feathers, best.cost
	elseif zoneGoal then
		return "Next: " .. zoneGoal.name, s.feathers, zoneGoal.cost
	end
	return "Next: Rebirth", s.feathers, Formulas.rebirthCost(s.rebirths)
end

function UIController:build()
	gui = make("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local uiScale = make("UIScale", {}, gui)
	local root = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, gui)
	-- Touch-Geräte: höhere Mindestskalierung, damit Tippziele ≥ 44 px bleiben
	local minScale = if UserInputService.TouchEnabled then 0.8 else 0.62
	local function rescale()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, Theme.referenceHeight)
		-- Nur Studio: Attribut DebugViewport (Vector2) simuliert eine Bildschirmgröße (z. B. Phone 844x390)
		local debugVp = gui:GetAttribute("DebugViewport")
		if typeof(debugVp) == "Vector2" then
			vp = debugVp
			root.Size = UDim2.fromOffset(vp.X, vp.Y)
			minScale = if gui:GetAttribute("DebugTouch") then 0.8 else minScale
		else
			root.Size = UDim2.fromScale(1, 1)
		end
		local user = State.state and State.state.settings and State.state.settings.uiScale or 1
		local s = math.clamp(vp.Y / Theme.referenceHeight, minScale, 1.3) * user
		uiScale.Scale = s
		-- Root in Referenz-Pixeln dimensionieren, damit Anker am Rand des (simulierten) Bildschirms liegen
		root.Size = UDim2.fromOffset(vp.X / s, vp.Y / s)
	end
	gui:GetAttributeChangedSignal("DebugViewport"):Connect(rescale)
	gui:GetAttributeChangedSignal("DebugTouch"):Connect(rescale)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	end
	rescale()
	make("UIPadding", {
		PaddingTop = UDim.new(0, 16),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingBottom = UDim.new(0, 16),
	}, root)

	-- Federanzeige (oben links)
	local featherBox = C.panel(UDim2.fromOffset(250, 64))
	featherBox.Position = UDim2.fromOffset(0, 40)
	featherBox.Parent = root
	local icon = C.text({ text = "🕊️", size = 34 })
	icon.Size = UDim2.fromOffset(56, 64)
	icon.Parent = featherBox
	local featherLabel = C.text({
		text = "0",
		size = Theme.size.lg,
		color = Theme.color.feather,
		align = Enum.TextXAlignment.Left,
	})
	featherLabel.Position = UDim2.fromOffset(58, 0)
	featherLabel.Size = UDim2.new(1, -66, 1, 0)
	featherLabel.Parent = featherBox
	local setFeathers = rollingCounter(featherLabel)
	local featherScale = make("UIScale", {}, featherBox)

	-- Boost-Anzeige unter den Federn (Server setzt BoostMult/BoostEndsAt am Spieler)
	local boostBox = C.panel(UDim2.fromOffset(250, 30), Theme.color.feather)
	boostBox.Position = UDim2.fromOffset(0, 110)
	boostBox.Visible = false
	boostBox.Parent = root
	local boostLabel = C.text({ text = "", size = Theme.size.sm, color = Theme.color.stroke })
	boostLabel.Size = UDim2.fromScale(1, 1)
	boostLabel.Parent = boostBox
	-- Freunde-/Gruppen-Bonus (Server setzt FriendsInServer/GroupMember), neben bzw. statt Boost-Anzeige
	local socialBox = C.panel(UDim2.fromOffset(150, 30), Theme.color.secondary)
	socialBox.Visible = false
	socialBox.Parent = root
	local socialLabel = C.text({ text = "", size = Theme.size.sm })
	socialLabel.Size = UDim2.fromScale(1, 1)
	socialLabel.Parent = socialBox
	C.tooltip(socialBox, "Play with friends: +10% feathers per friend (max +30%)")
	task.spawn(function()
		while gui do
			local friends = player:GetAttribute("FriendsInServer")
			local pct = (if typeof(friends) == "number" then friends * 10 else 0)
				+ (if player:GetAttribute("GroupMember") then 10 else 0)
			socialBox.Visible = pct > 0
			socialLabel.Text = ("👥 +%d%%"):format(pct)
			socialBox.Position = UDim2.fromOffset(if boostBox.Visible then 260 else 0, 110)
			task.wait(1)
		end
	end)
	task.spawn(function()
		while gui do
			local mult = player:GetAttribute("BoostMult")
			local endsAt = player:GetAttribute("BoostEndsAt")
			local left = if typeof(endsAt) == "number" then endsAt - workspace:GetServerTimeNow() else 0
			if typeof(mult) == "number" and left > 0 then
				boostBox.Visible = true
				boostLabel.Text = ("%gx BOOST %d:%02d"):format(mult, left // 60, math.floor(left % 60))
			else
				boostBox.Visible = false
			end
			task.wait(0.5)
		end
	end)

	-- Rank (oben Mitte)
	local rankBox = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(360, 58),
		BackgroundTransparency = 1,
	}, root)
	local rankLabel = C.text({ text = "Sleepyhead", size = Theme.size.md })
	rankLabel.Size = UDim2.new(1, 0, 0, 30)
	rankLabel.Parent = rankBox
	local bar, setRank = C.progressBar(UDim2.new(1, 0, 0, 18), Theme.color.secondary)
	bar.Position = UDim2.fromOffset(0, 34)
	bar.Parent = rankBox

	-- Linke Menüleiste
	local menu = make(
		"Frame",
		{ Position = UDim2.fromOffset(0, 150), Size = UDim2.fromOffset(110, 406), BackgroundTransparency = 1 },
		root
	)
	-- Raster statt Liste: einspaltig, bei wenig Höhe (Phone quer) zweispaltig mit 3 Zeilen
	local menuGrid = make("UIGridLayout", {
		CellSize = UDim2.fromOffset(110, 56),
		CellPadding = UDim2.fromOffset(10, 10),
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, menu)
	local function layoutMenu()
		local availableHeight = root.Size.Y.Offset - 150 - 32
		local twoColumns = availableHeight < 6 * 56 + 5 * 10
		menuGrid.FillDirectionMaxCells = if twoColumns then 3 else 6
		menu.Size = if twoColumns then UDim2.fromOffset(230, 188) else UDim2.fromOffset(110, 386)
	end
	root:GetPropertyChangedSignal("Size"):Connect(layoutMenu)
	local shopBtn = C.button({
		text = "🛒 Shop",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.primary,
		textSize = Theme.size.md,
	})
	shopBtn.instance.LayoutOrder = 1
	shopBtn.instance.Parent = menu
	local zonesBtn = C.button({
		text = "🗺️ Zones",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.secondary,
		textSize = Theme.size.sm,
	})
	zonesBtn.instance.LayoutOrder = 2
	zonesBtn.instance.Parent = menu
	local rebirthBtn = C.button({
		text = "🔄 Rebirth",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.feather,
		textSize = Theme.size.sm,
	})
	rebirthBtn.instance.LayoutOrder = 3
	rebirthBtn.instance.Parent = menu
	local settingsBtn = C.button({
		text = "⚙️ Settings",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.bgSoft,
		textSize = Theme.size.sm,
	})
	local indexBtn = C.button({
		text = "📖 Index",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.primary,
		textSize = Theme.size.sm,
	})
	indexBtn.instance.LayoutOrder = 4
	indexBtn.instance.Parent = menu
	local dailyBtn = C.button({
		text = "🎁 Daily",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.success,
		textSize = Theme.size.sm,
	})
	dailyBtn.instance.LayoutOrder = 5
	dailyBtn.instance.Parent = menu
	-- roter Punkt: Belohnung abholbar
	local dailyDot = make("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Theme.color.danger,
		Visible = false,
		ZIndex = 10,
	}, dailyBtn.instance)
	C.corner(dailyDot, 9)
	settingsBtn.instance.LayoutOrder = 6
	settingsBtn.instance.Parent = menu
	layoutMenu()

	-- Schlag-Taste + Auto (unten rechts)
	local swingBtn = C.button({
		text = "SWING!",
		size = UDim2.fromOffset(150, 150),
		color = Theme.color.primary,
		textSize = Theme.size.lg,
		silent = true,
		onPress = function()
			Swing:setHolding(true)
		end,
		onRelease = function()
			Swing:setHolding(false)
		end,
	})
	swingBtn.instance.AnchorPoint = Vector2.new(1, 1)
	swingBtn.instance.Position = UDim2.fromScale(1, 1)
	swingBtn.instance.Parent = root
	C.corner(swingBtn.button, 999)
	swingBtn.button.MouseLeave:Connect(function()
		Swing:setHolding(false)
	end)
	if not UserInputService.TouchEnabled then
		swingBtn.instance.Size = UDim2.fromOffset(120, 120)
	end

	local autoBtn = C.button({
		text = "AUTO: OFF",
		size = UDim2.fromOffset(150, 56),
		color = Theme.color.locked,
		textSize = Theme.size.sm,
	})
	autoBtn.instance.AnchorPoint = Vector2.new(1, 1)
	autoBtn.instance.Position = UDim2.new(1, 0, 1, -166)
	autoBtn.instance.Parent = root

	-- Nächstes Ziel (unten Mitte)
	local goal = C.panel(UDim2.fromOffset(340, 64))
	goal.AnchorPoint = Vector2.new(0.5, 1)
	goal.Position = UDim2.fromScale(0.5, 1)
	goal.Parent = root
	local goalLabel = C.text({ text = "", size = Theme.size.sm })
	goalLabel.Size = UDim2.new(1, -16, 0, 30)
	goalLabel.Position = UDim2.fromOffset(8, 4)
	goalLabel.Parent = goal
	local goalBar, setGoal = C.progressBar(UDim2.new(1, -24, 0, 14), Theme.color.feather)
	goalBar.Position = UDim2.fromOffset(12, 40)
	goalBar.Parent = goal

	-- Toasts (oben Mitte, unter Rank)
	toastStack = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.fromOffset(360, 200),
		BackgroundTransparency = 1,
	}, root)
	make(
		"UIListLayout",
		{ Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center },
		toastStack
	)

	C.onAnyPress = function()
		Sound:play("click")
	end

	local shop = self:buildShop(root)
	local rebirth = RebirthPanel.build(root)
	local zones = ZonesPanel.build(root)
	local feedback = FeedbackPanel.build(root)
	local openFeedback -- gesetzt, sobald openOnly existiert
	local settingsPanel = SettingsPanel.build(root, {
		onFeedback = function()
			if openFeedback then
				openFeedback()
			end
		end,
	})
	local index = IndexPanel.build(root)
	local celebration = Celebration.build(root)
	local tutorialHint = TutorialHint.build(root, {
		swing = swingBtn.instance,
		shop = shopBtn.instance,
		rank = bar,
		goal = goal,
	})
	local function celebrate(title: string, subtitle: string?, color: Color3?)
		local st = State.state and State.state.settings or {}
		celebration.show({
			title = title,
			subtitle = subtitle,
			color = color,
			reducedMotion = st.reducedMotion == true,
			lowVfx = st.lowVfx == true,
		})
	end
	-- Immer nur ein Fenster offen
	local daily = DailyPanel.build(root)
	local modals = { rebirth, zones, settingsPanel, index, daily, feedback }
	local function openOnly(target: any?)
		if target ~= shop and shop.isOpen() then
			shop.toggle()
		end
		for _, m in modals do
			if m ~= target then
				m.toggle(false)
			end
		end
		if target then
			target.toggle()
		end
	end
	shopBtn.button.Activated:Connect(function()
		openOnly(shop)
	end)
	zonesBtn.button.Activated:Connect(function()
		openOnly(zones)
	end)
	rebirthBtn.button.Activated:Connect(function()
		openOnly(rebirth)
	end)
	settingsBtn.button.Activated:Connect(function()
		openOnly(settingsPanel)
	end)
	indexBtn.button.Activated:Connect(function()
		openOnly(index)
	end)
	dailyBtn.button.Activated:Connect(function()
		openOnly(daily)
	end)
	openFeedback = function()
		openOnly(feedback)
	end

	-- ---------- Binden an Zustand ----------
	local lastFeathers = 0
	local dailyAutoShown = false
	local function refresh()
		local s = State.state
		if not s then
			return
		end
		C.reducedMotion = s.settings.reducedMotion
		if s.feathers > lastFeathers and not s.settings.reducedMotion then
			featherScale.Scale = 1.08
			C.tween(featherScale, Theme.motion.base, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		lastFeathers = s.feathers
		setFeathers(s.feathers)
		local rank = s.rank
		local cur = Progression.ranks[rank]
		local nxt = Progression.ranks[rank + 1]
		rankLabel.Text = ("Rank %d · %s"):format(rank, cur.name)
		if nxt then
			setRank(
				(s.lifetimeFeathers - cur.lifetimeFeathers) / (nxt.lifetimeFeathers - cur.lifetimeFeathers)
			)
		else
			setRank(1)
		end
		local text, have, need = nextGoal(s)
		goalLabel.Text = if have >= need
			then ("%s  –  ready! (%s)"):format(text, NumberFormat.short(need))
			else ("%s  (%s / %s)"):format(text, NumberFormat.short(have), NumberFormat.short(need))
		setGoal(if need > 0 then have / need else 1)
		local canAuto = s.rank >= Progression.swing.autoSwingRank
		if not canAuto then
			autoBtn.setText("AUTO 🔒 Rank 2")
			autoBtn.setColor(Theme.color.locked)
		elseif s.autoSwingEnabled then
			autoBtn.setText("AUTO: ON")
			autoBtn.setColor(Theme.color.success)
		else
			autoBtn.setText("AUTO: OFF")
			autoBtn.setColor(Theme.color.secondary)
		end
		shop.refresh(s)
		rebirth.refresh(s)
		zones.refresh(s)
		settingsPanel.refresh(s)
		index.refresh(s)
		tutorialHint.refresh(s)
		daily.refresh(s)
		local claimable = daily.claimable(s)
		dailyDot.Visible = claimable
		-- Willkommen-zurück: einmal pro Sitzung automatisch öffnen (nicht während des Tutorials)
		if claimable and not dailyAutoShown and s.tutorial and s.tutorial.completed then
			dailyAutoShown = true
			task.delay(1.5, function()
				if daily.claimable(State.state) and not daily.isOpen() then
					openOnly(daily)
				end
			end)
		end
	end
	local function toggleAuto()
		local s = State.state
		if s then
			NetClient.fire("SetAutoSwing", not s.autoSwingEnabled)
		end
	end
	autoBtn.button.Activated:Connect(toggleAuto)

	-- Tooltips (Maus)
	C.tooltip(shopBtn.button, "Buy pillows and upgrades")
	C.tooltip(zonesBtn.button, "Unlock and travel to zones")
	C.tooltip(rebirthBtn.button, "Start over with a permanent bonus")
	C.tooltip(indexBtn.button, "Your pillow collection")
	C.tooltip(settingsBtn.button, "Sound, effects and UI size")
	C.tooltip(dailyBtn.button, "Free reward every day")
	C.tooltip(autoBtn.button, "Auto-Swing hits for you at 80% power")

	-- Gamepad-Grundbedienung: R2 = Schlag (Tool), Y = Shop, X = Auto-Swing, B = Fenster schließen
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.ButtonY then
			openOnly(shop)
		elseif input.KeyCode == Enum.KeyCode.ButtonX then
			toggleAuto()
		elseif input.KeyCode == Enum.KeyCode.ButtonB then
			openOnly(nil)
		end
	end)
	State.Changed:Connect(function(key)
		if key == "settings" then
			rescale()
		end
		refresh()
	end)
	State.Notified:Connect(function(kind, payload)
		if kind == "purchaseResult" then
			if payload.ok then
				if payload.kind == "pillow" then
					local p = Pillows.byId[payload.id]
					if p.rarity == "Epic" or p.rarity == "Legendary" then
						celebrate(p.rarity:upper() .. "!", p.name, rarityInfo[p.rarity].color)
					else
						self:toast(
							("New pillow: %s %s!"):format(rarityInfo[p.rarity].symbol, p.name),
							rarityInfo[p.rarity].color
						)
					end
				elseif payload.kind == "upgrade" then
					self:toast("Upgrade bought!", Theme.color.success)
				elseif payload.kind == "zone" then
					self:toast(
						("Zone unlocked: %s!"):format(Zones.byId[payload.id].name),
						Theme.color.secondary
					)
				end
			else
				self:toast(REASONS[payload.reason] or "Not possible right now.", Theme.color.danger)
			end
		elseif kind == "rankUp" then
			celebrate("RANK UP!", payload.name, Theme.color.secondary)
			if payload.rank == Progression.swing.autoSwingRank then
				self:toast("Auto-Swing unlocked!", Theme.color.success)
			end
		elseif kind == "rebirth" then
			celebrate(
				("REBIRTH %d!"):format(payload.rebirths),
				("Feathers x%.2f forever"):format(payload.multiplier),
				Theme.color.feather
			)
		elseif kind == "codeResult" then
			if payload.ok then
				local info = payload.info
				local sub = if info.kind == "boost"
					then ("2x Feathers for %d min"):format(info.minutes)
					else ("+%s feathers"):format(NumberFormat.short(info.amount))
				celebrate("CODE REDEEMED!", sub, Theme.color.success)
			else
				local msg = ({
					unknown = "That code doesn't exist.",
					expired = "That code has expired.",
					used = "You already used that code.",
				})[payload.reason] or "Code not possible right now."
				self:toast(msg, Theme.color.danger)
			end
		elseif kind == "storeResult" then
			if payload.ok then
				celebrate("THANK YOU!", "Your purchase is active.", Theme.color.robux)
			else
				local msg = ({
					notAvailable = "Coming soon!",
					owned = "You already own this.",
				})[payload.reason] or "Purchase not possible right now."
				self:toast(msg, Theme.color.muted)
			end
		elseif kind == "feedbackResult" then
			feedback.sent(payload.ok)
			if payload.ok then
				self:toast("Thanks for your feedback!", Theme.color.success)
			else
				local msg = ({
					limit = "That's enough feedback for now. Thank you!",
					filterFailed = "Couldn't send right now. Please try again later.",
					saveFailed = "Couldn't send right now. Please try again later.",
				})[payload.reason] or "Couldn't send feedback."
				self:toast(msg, Theme.color.danger)
			end
		elseif kind == "dailyResult" then
			if payload.ok then
				local info = payload.info
				local sub = if info.kind == "boost"
					then ("2x Feathers for %d min"):format(info.minutes)
					else ("+%s feathers"):format(NumberFormat.short(info.amount))
				celebrate(("DAY %d!"):format(info.day), sub, Theme.color.success)
				task.delay(1.2, function()
					daily.toggle(false)
				end)
			else
				self:toast("Already claimed today. Come back tomorrow!", Theme.color.muted)
			end
		elseif kind == "tutorialDone" then
			celebrate(
				"TUTORIAL COMPLETE!",
				("%gx Feathers for %d min"):format(payload.mult, payload.seconds // 60),
				Theme.color.feather
			)
		elseif kind == "otherRankUp" then
			self:toast(("%s reached %s!"):format(payload.name, payload.rank), Theme.color.muted)
		elseif kind == "error" then
			self:toast(payload.text, Theme.color.danger)
		end
	end)
	State:onReady(refresh)
	gui.Parent = player:WaitForChild("PlayerGui")
end

-- ---------- Shop ----------
function UIController:buildShop(root: Frame)
	local panel = C.panel(UDim2.fromOffset(620, 440))
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Visible = false
	panel.Parent = root
	local pscale = make("UIScale", { Scale = 0.85 }, panel)

	local title = C.text({ text = "SHOP", size = Theme.size.lg })
	title.Size = UDim2.new(1, 0, 0, 48)
	title.Parent = panel
	local close = C.button({
		text = "X",
		size = UDim2.fromOffset(52, 52),
		color = Theme.color.danger,
		textSize = Theme.size.md,
	})
	close.instance.AnchorPoint = Vector2.new(1, 0)
	close.instance.Position = UDim2.new(1, -8, 0, 8)
	close.instance.Parent = panel

	local tabs = make(
		"Frame",
		{ Position = UDim2.fromOffset(16, 52), Size = UDim2.new(1, -32, 0, 52), BackgroundTransparency = 1 },
		panel
	)
	make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }, tabs)
	local tabPillows =
		C.button({ text = "Pillows", size = UDim2.fromOffset(150, 50), color = Theme.color.primary })
	tabPillows.instance.Parent = tabs
	local tabUpgrades =
		C.button({ text = "Upgrades", size = UDim2.fromOffset(150, 50), color = Theme.color.bgSoft })
	tabUpgrades.instance.Parent = tabs
	local tabStore =
		C.button({ text = "⭐ Extras", size = UDim2.fromOffset(150, 50), color = Theme.color.bgSoft })
	tabStore.instance.Parent = tabs

	local function list(): ScrollingFrame
		local sf = make("ScrollingFrame", {
			Position = UDim2.fromOffset(16, 112),
			Size = UDim2.new(1, -32, 1, -128),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 8,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
		}, panel)
		make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
		return sf
	end
	local pillowList = list()
	local upgradeList = list()
	upgradeList.Visible = false
	local storeList = list()
	storeList.Visible = false

	local function row(parent: Instance, order: number)
		local f = make(
			"Frame",
			{ Size = UDim2.new(1, -12, 0, 70), BackgroundColor3 = Theme.color.bgSoft, LayoutOrder = order },
			parent
		)
		C.corner(f)
		local name = C.text({ text = "", size = Theme.size.sm, align = Enum.TextXAlignment.Left })
		name.Position = UDim2.fromOffset(14, 4)
		name.Size = UDim2.new(1, -200, 0, 28)
		name.Parent = f
		local info = C.text({
			text = "",
			size = Theme.size.xs,
			color = Theme.color.muted,
			font = Theme.font.body,
			align = Enum.TextXAlignment.Left,
		})
		info.Position = UDim2.fromOffset(14, 36)
		info.Size = UDim2.new(1, -200, 0, 24)
		info.Parent = f
		local btn = C.button({ text = "", size = UDim2.fromOffset(170, 54), color = Theme.color.success })
		btn.instance.AnchorPoint = Vector2.new(1, 0.5)
		btn.instance.Position = UDim2.new(1, -8, 0.5, 0)
		btn.instance.Parent = f
		return name, info, btn
	end

	local pillowRows = {}
	for i, p in Pillows.list do
		local name, info, btn = row(pillowList, i)
		local ri = rarityInfo[p.rarity]
		name.Text = ("%s %s"):format(ri.symbol, p.name)
		name.TextColor3 = ri.color
		-- 3D-Vorschau links, Text rückt nach rechts
		local icon = C.pillowIcon(p.id, UDim2.fromOffset(62, 62), ri.color)
		icon.frame.Position = UDim2.fromOffset(4, 4)
		icon.frame.Parent = name.Parent
		name.Position = UDim2.fromOffset(74, 4)
		name.Size = UDim2.new(1, -260, 0, 28)
		info.Position = UDim2.fromOffset(74, 36)
		info.Size = UDim2.new(1, -260, 0, 24)
		btn.button.Activated:Connect(function()
			local s = State.state
			if not s then
				return
			end
			if s.ownedPillows[p.id] then
				NetClient.fire("EquipPillow", p.id)
			else
				NetClient.fire("BuyPillow", p.id)
			end
		end)
		pillowRows[p.id] = { info = info, btn = btn, pillow = p }
	end

	local upgradeRows = {}
	local order = 0
	for kind, def in Progression.upgrades do
		order += 1
		local name, info, btn = row(upgradeList, order)
		name.Text = def.name
		btn.button.Activated:Connect(function()
			NetClient.fire("BuyUpgrade", kind)
		end)
		upgradeRows[kind] = { name = name, info = info, btn = btn, def = def }
	end

	-- Robux-Artikel (PS-34): klar als Robux gekennzeichnet; ohne Owner-Preis/ID „SOON“ und nicht kaufbar
	local storeRows = {}
	local localPlayer = game:GetService("Players").LocalPlayer
	local function storeEntry(kind: string, def: any, order2: number, effect: string)
		local name, info, btn = row(storeList, order2)
		name.Text = def.name
		info.Text = effect
		btn.button.Activated:Connect(function()
			NetClient.fire("PromptPurchase", kind, def.id)
		end)
		storeRows[def.id] = { kind = kind, def = def, btn = btn }
	end
	for i, def in Products.gamepasses do
		local effect = if def.multiplier
			then ("Forever: x%g feathers"):format(def.multiplier)
			else ("Forever: Auto-Swing at %d%%"):format(
				math.floor((def.autoSwingEfficiency or 1) * 100 + 0.5)
			)
		storeEntry("pass", def, i, effect)
	end
	for i, def in Products.devProducts do
		storeEntry("product", def, 100 + i, ("2x feathers for %d min (stacks)"):format(def.minutes or 0))
	end
	local function refreshStore()
		for id, r in storeRows do
			local def = r.def
			local available = def.robux ~= nil and (def.assetId or def.productId or 0) > 0
			if r.kind == "pass" and localPlayer:GetAttribute("Pass_" .. id) then
				r.btn.setText("OWNED")
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			elseif not available then
				r.btn.setText("SOON")
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			else
				r.btn.setText(("R$ %d"):format(def.robux))
				r.btn.setColor(Theme.color.robux)
				r.btn.setEnabled(true)
			end
		end
	end
	refreshStore()
	localPlayer.AttributeChanged:Connect(function(attr)
		if string.sub(attr, 1, 5) == "Pass_" then
			refreshStore()
		end
	end)

	local function show(which: string)
		pillowList.Visible = which == "pillows"
		upgradeList.Visible = which == "upgrades"
		storeList.Visible = which == "store"
		tabPillows.setColor(if which == "pillows" then Theme.color.primary else Theme.color.bgSoft)
		tabUpgrades.setColor(if which == "upgrades" then Theme.color.primary else Theme.color.bgSoft)
		tabStore.setColor(if which == "store" then Theme.color.robux else Theme.color.bgSoft)
	end
	tabStore.button.Activated:Connect(function()
		show("store")
	end)
	tabPillows.button.Activated:Connect(function()
		show("pillows")
	end)
	tabUpgrades.button.Activated:Connect(function()
		show("upgrades")
	end)

	local api = {}
	function api.isOpen(): boolean
		return panel.Visible
	end
	function api.toggle()
		if panel.Visible then
			C.tween(pscale, Theme.motion.fast, { Scale = 0.85 })
			task.delay(Theme.motion.fast, function()
				panel.Visible = false
			end)
		else
			panel.Visible = true
			local fit = C.fitScale(panel, root)
			pscale.Scale = 0.85 * fit
			C.tween(pscale, Theme.motion.base, { Scale = fit }, Enum.EasingStyle.Back)
		end
	end
	close.button.Activated:Connect(api.toggle)

	function api.refresh(s: any)
		for id, r in pillowRows do
			local p = r.pillow
			r.info.Text = ("Power %s · Zone: %s%s"):format(
				NumberFormat.short(p.power),
				Zones.byId[p.zone].name,
				if p.rebirths > 0 then (" · Rebirth %d"):format(p.rebirths) else ""
			)
			if s.equippedPillow == id then
				r.btn.setText("EQUIPPED")
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			elseif s.ownedPillows[id] then
				r.btn.setText("EQUIP")
				r.btn.setColor(Theme.color.secondary)
				r.btn.setEnabled(true)
			elseif not s.unlockedZones[p.zone] or s.rebirths < p.rebirths then
				r.btn.setText("🔒 " .. NumberFormat.short(p.cost))
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			else
				r.btn.setText("🕊️ " .. NumberFormat.short(p.cost))
				r.btn.setColor(if s.feathers >= p.cost then Theme.color.success else Theme.color.locked)
				r.btn.setEnabled(s.feathers >= p.cost)
			end
		end
		for kind, r in upgradeRows do
			local level = s.upgrades[kind]
			local def = r.def
			local effect = if kind == "featherPower"
				then ("+%d%% feathers per swing"):format(math.floor(def.bonusPerLevel * level * 100 + 0.5))
				else ("%.2fs per swing"):format(
					Formulas.cooldown(
						level,
						(Pillows.byId[s.equippedPillow] or Pillows.byId[Pillows.starter]).speed
					)
				)
			r.name.Text = ("%s  Lv %d"):format(def.name, level)
			r.info.Text = effect
			if level >= def.maxLevel then
				r.btn.setText("MAX")
				r.btn.setColor(Theme.color.locked)
				r.btn.setEnabled(false)
			else
				local cost = Formulas.upgradeCost(kind, level)
				r.btn.setText("🕊️ " .. NumberFormat.short(cost))
				r.btn.setColor(if s.feathers >= cost then Theme.color.success else Theme.color.locked)
				r.btn.setEnabled(s.feathers >= cost)
			end
		end
	end
	return api
end

function UIController:Start()
	self:build()
end

return UIController
