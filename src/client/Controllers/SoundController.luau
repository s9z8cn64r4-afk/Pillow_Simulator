--!strict
-- Soundeffekte und Hintergrundmusik (Playlist) mit SoundGroups SFX/Music, gekoppelt an die Einstellungen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local NetClient = require(Shared.Net.NetClient)

local player = Players.LocalPlayer
local SoundController = {}
SoundController.failed = {} :: { [string]: boolean } -- nicht ladbare Sounds (Diagnose)
local State, Swing
local sfxGroup: SoundGroup
local musicGroup: SoundGroup
local MUSIC_FADE = 2
local templates: { [string]: Sound } = {}

function SoundController:Init(registry)
	State = registry.PlayerStateController
	Swing = registry.SwingController
end

function SoundController:play(name: string, pitchOffset: number?)
	local t = templates[name]
	if not t or self.failed[name] then
		return
	end
	local def = (Assets.sounds :: any)[name]
	local s = t:Clone()
	s.PlaybackSpeed = 1 + (pitchOffset or 0) + (math.random() * 2 - 1) * def.pitchVariation
	s.Parent = sfxGroup
	s:Play()
	Debris:AddItem(s, math.max(s.TimeLength, 1) + 0.5)
end

local function applySettings()
	local s = State.state
	if s and s.settings then
		sfxGroup.Volume = s.settings.sfx
		musicGroup.Volume = s.settings.music
	end
end

-- Playlist in Endlosschleife mit sanftem Ein-/Ausblenden; nicht ladbare Titel werden übersprungen.
-- Lautstärke 0 in den Einstellungen = Musikgruppe stumm (Titel laufen weiter, kein Neustart beim Wiedereinschalten).
local function runPlaylist()
	local tracks = {}
	for i, def in Assets.music do
		local s = Instance.new("Sound")
		s.Name = "Music" .. i
		s.SoundId = def.id
		s.Volume = 0
		s.SoundGroup = musicGroup
		s.Parent = musicGroup
		s:SetAttribute("TargetVolume", def.volume)
		table.insert(tracks, s)
	end
	local index = math.random(1, #tracks)
	while true do
		local s = tracks[index]
		local t0 = os.clock()
		while not s.IsLoaded and os.clock() - t0 < 10 do
			task.wait(0.25)
		end
		if s.IsLoaded and s.TimeLength > MUSIC_FADE * 2 then
			s.TimePosition = 0
			s:Play()
			TweenService:Create(s, TweenInfo.new(MUSIC_FADE), { Volume = s:GetAttribute("TargetVolume") }):Play()
			task.wait(s.TimeLength - MUSIC_FADE)
			TweenService:Create(s, TweenInfo.new(MUSIC_FADE), { Volume = 0 }):Play()
			task.wait(MUSIC_FADE)
			s:Stop()
		else
			warn("[PS][WARN] Musik nicht ladbar: " .. s.SoundId)
			task.wait(1)
		end
		index = index % #tracks + 1
	end
end

function SoundController:Start()
	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "SFX"
	sfxGroup.Parent = SoundService
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "Music"
	musicGroup.Volume = 0 -- bis die Einstellungen geladen sind
	musicGroup.Parent = SoundService
	task.spawn(runPlaylist)
	local list = {}
	for name, def in Assets.sounds do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = def.id
		s.Volume = def.volume
		s.SoundGroup = sfxGroup
		templates[name] = s
		table.insert(list, s)
	end
	task.spawn(function()
		ContentProvider:PreloadAsync(list, function(assetId, status)
			if status ~= Enum.AssetFetchStatus.Success then
				for name, def in Assets.sounds do
					if def.id == assetId then
						self.failed[name] = true
					end
				end
				warn("[PS][WARN] Sound nicht ladbar: " .. assetId .. " (" .. tostring(status) .. ")")
			end
		end)
	end)

	State.Changed:Connect(function(key)
		if key == "settings" then
			applySettings()
		end
	end)
	State:onReady(applySettings)

	Swing.Swung:Connect(function()
		self:play("swing")
	end)
	NetClient.on("SwingFx", function(userId: number, _amount: number, dummyName: string?)
		if userId == player.UserId and dummyName then
			self:play("hit")
		end
	end)
	State.Notified:Connect(function(kind, payload)
		if kind == "purchaseResult" then
			if payload.ok then
				self:play("purchase")
			else
				self:play("click", -0.35)
			end
		elseif kind == "rankUp" then
			self:play("rankUp")
		end
	end)
end

return SoundController
