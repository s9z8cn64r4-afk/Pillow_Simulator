--!strict
-- Spieler-Einstellungen: serverseitig validiert und gespeichert (Musik, SFX, Reduced Motion, Low VFX, UI-Größe).
local SettingsService = {}
local Net, PlayerData

-- Erlaubte Schlüssel und ihre Prüfung (gibt den bereinigten Wert oder nil zurück)
local RULES: { [string]: (any) -> any } = {
	music = function(v)
		return if type(v) == "number" and v == v then math.clamp(math.floor(v * 4 + 0.5) / 4, 0, 1) else nil
	end,
	sfx = function(v)
		return if type(v) == "number" and v == v then math.clamp(math.floor(v * 4 + 0.5) / 4, 0, 1) else nil
	end,
	reducedMotion = function(v)
		return if type(v) == "boolean" then v else nil
	end,
	lowVfx = function(v)
		return if type(v) == "boolean" then v else nil
	end,
	uiScale = function(v)
		if v == 0.9 or v == 1 or v == 1.15 then
			return v
		end
		return nil
	end,
}
SettingsService.RULES = RULES

function SettingsService:Init(registry)
	Net = registry.NetService
	PlayerData = registry.PlayerDataService
end

-- Gibt true zurück, wenn gespeichert
function SettingsService:set(player: Player, key: string, value: any): boolean
	local data = PlayerData:get(player)
	local rule = RULES[key]
	if not data or not rule then
		return false
	end
	local clean = rule(value)
	if clean == nil then
		return false
	end
	data.settings[key] = clean
	PlayerData:markChanged(player, "settings")
	return true
end

function SettingsService:Start()
	Net:on("SetSetting", function(player, key: string, value: any)
		if not self:set(player, key, value) then
			Net:flag(player, "bad_setting", { key = key })
		end
	end)
end

return SettingsService
