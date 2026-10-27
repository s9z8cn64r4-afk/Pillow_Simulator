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

local UI = script.Parent.Parent:WaitForChild("UI")
local Theme = require(UI.Theme)
local C = require(UI.Components)
local RebirthPanel = require(UI.RebirthPanel)
local ZonesPanel = require(UI.ZonesPanel)
local SettingsPanel = require(UI.SettingsPanel)
local IndexPanel = require(UI.IndexPanel)
local Celebration = require(UI.Celebration)

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
		{ Position = UDim2.fromOffset(0, 130), Size = UDim2.fromOffset(110, 340), BackgroundTransparency = 1 },
		root
	)
	make("UIListLayout", { Padding = UDim.new(0, 10) }, menu)
	local shopBtn = C.button({
		text = "🛒 Shop",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.primary,
		textSize = Theme.size.md,
	})
	shopBtn.instance.Parent = menu
	local zonesBtn = C.button({
		text = "🗺️ Zones",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.secondary,
		textSize = Theme.size.sm,
	})
	zonesBtn.instance.Parent = menu
	local rebirthBtn = C.button({
		text = "🔄 Rebirth",
		size = UDim2.fromOffset(110, 56),
		color = Theme.color.feather,
		textSize = Theme.size.sm,
	})
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
	indexBtn.instance.Parent = menu
	settingsBtn.instance.Parent = menu

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
	local settingsPanel = SettingsPanel.build(root)
	local index = IndexPanel.build(root)
	local celebration = Celebration.build(root)
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
	local modals = { rebirth, zones, settingsPanel, index }
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

	-- ---------- Binden an Zustand ----------
	local lastFeathers = 0
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
		goalLabel.Text = ("%s  (%s / %s)"):format(text, NumberFormat.short(have), NumberFormat.short(need))
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
	end
	autoBtn.button.Activated:Connect(function()
		local s = State.state
		if s then
			NetClient.fire("SetAutoSwing", not s.autoSwingEnabled)
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

	local function show(which: string)
		pillowList.Visible = which == "pillows"
		upgradeList.Visible = which == "upgrades"
		tabPillows.setColor(if which == "pillows" then Theme.color.primary else Theme.color.bgSoft)
		tabUpgrades.setColor(if which == "upgrades" then Theme.color.primary else Theme.color.bgSoft)
	end
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
			pscale.Scale = 0.85
			C.tween(pscale, Theme.motion.base, { Scale = 1 }, Enum.EasingStyle.Back)
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
