--!strict
-- Licht-Profile je Zone (Art Bible): rein lokal, folgt dem Spieler-Attribut "Zone" (setzt ZoneService,
-- nur für freigeschaltete Zonen). Überblendung 1,5 s; Reduced Motion: sofort. Außerhalb/gesperrt: Profil bleibt.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local C = Color3.fromRGB
local FADE = 1.5

local LightingController = {}
local State

export type Profile = {
	ClockTime: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	Brightness: number,
	atmosphere: { Color: Color3, Decay: Color3, Density: number },
}

-- Lesbarkeit vor Stimmung: nie dunkler als Dämmerung (Spieler/Federn auf 6-Zoll-Phones sichtbar)
LightingController.PROFILES = table.freeze({
	bedroom = {
		ClockTime = 14,
		Ambient = C(120, 110, 140),
		OutdoorAmbient = C(150, 140, 170),
		Brightness = 2,
		atmosphere = { Color = C(220, 210, 255), Decay = C(180, 170, 220), Density = 0.25 },
	},
	livingroom = {
		ClockTime = 16.8,
		Ambient = C(150, 120, 105),
		OutdoorAmbient = C(185, 150, 125),
		Brightness = 2,
		atmosphere = { Color = C(255, 222, 190), Decay = C(230, 170, 140), Density = 0.28 },
	},
	hotelsuite = {
		ClockTime = 17.6,
		Ambient = C(140, 105, 95),
		OutdoorAmbient = C(165, 125, 110),
		Brightness = 1.9,
		atmosphere = { Color = C(255, 205, 170), Decay = C(200, 130, 110), Density = 0.3 },
	},
	cloudrealm = {
		ClockTime = 18.6,
		Ambient = C(150, 140, 195),
		OutdoorAmbient = C(180, 170, 225),
		Brightness = 1.8,
		atmosphere = { Color = C(215, 205, 255), Decay = C(170, 150, 230), Density = 0.3 },
	},
} :: { [string]: Profile })

local current: string? = nil
local tweens: { Tween } = {}

local function atmosphere(): Atmosphere
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then
		a = Instance.new("Atmosphere")
		a.Parent = Lighting
	end
	return a :: Atmosphere
end

function LightingController:apply(zoneId: string?, instant: boolean?)
	local p = zoneId and self.PROFILES[zoneId]
	if not p or zoneId == current then
		return
	end
	current = zoneId
	for _, t in tweens do
		t:Cancel()
	end
	table.clear(tweens)
	local reduced = State.state and State.state.settings and State.state.settings.reducedMotion == true
	local lightProps = {
		Ambient = p.Ambient,
		OutdoorAmbient = p.OutdoorAmbient,
		Brightness = p.Brightness,
		ClockTime = p.ClockTime,
	}
	local atm = atmosphere()
	if instant or reduced then
		for k, v in lightProps do
			(Lighting :: any)[k] = v
		end
		for k, v in p.atmosphere do
			(atm :: any)[k] = v
		end
		return
	end
	local info = TweenInfo.new(FADE, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for _, t in
		{ TweenService:Create(Lighting, info, lightProps), TweenService:Create(atm, info, p.atmosphere) }
	do
		t:Play()
		table.insert(tweens, t)
	end
end

function LightingController:Init(registry)
	State = registry.PlayerStateController
end

function LightingController:Start()
	local player = Players.LocalPlayer
	self:apply(player:GetAttribute("Zone") or "bedroom", true)
	player:GetAttributeChangedSignal("Zone"):Connect(function()
		local z = player:GetAttribute("Zone")
		if typeof(z) == "string" then
			self:apply(z)
		end
	end)
end

return LightingController
