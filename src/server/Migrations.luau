--!strict
-- Migrationen der Spielerdaten. Eintrag [n] hebt Daten von Version n auf n+1.
local PlayerData = require(game:GetService("ReplicatedStorage").Shared.Types.PlayerData)

local Migrations = {}

local steps: { [number]: (any) -> any } = {
	-- 0 -> 1: Profile ohne schemaVersion (vor dem ersten Schema) erhalten Version 1
	[0] = function(data)
		data.schemaVersion = 1
		return data
	end,
}

function Migrations.run(data: any): any
	local v = data.schemaVersion or 0
	while v < PlayerData.SCHEMA_VERSION do
		local step = steps[v]
		assert(step, "Migration fehlt für Version " .. v)
		data = step(data)
		v = data.schemaVersion
	end
	return data
end

return Migrations
