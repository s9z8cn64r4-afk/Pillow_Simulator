--!strict
-- Läuft nur im Server-Kontext (Migrations liegt im Server-Skript)
local ServerScriptService = game:GetService("ServerScriptService")

return function(it, expect)
	it("v0-Profil ohne schemaVersion wird auf aktuelle Version gehoben", function()
		local Migrations = require(ServerScriptService.Server.Migrations :: any)
		local PlayerData = require(game:GetService("ReplicatedStorage").Shared.Types.PlayerData)
		local old = { feathers = 10 }
		local new = Migrations.run(old)
		expect(new.schemaVersion).toBe(PlayerData.SCHEMA_VERSION)
		expect(new.feathers).toBe(10)
	end)
	it("aktuelle Version bleibt unverändert", function()
		local Migrations = require(ServerScriptService.Server.Migrations :: any)
		local PlayerData = require(game:GetService("ReplicatedStorage").Shared.Types.PlayerData)
		local d = { schemaVersion = PlayerData.SCHEMA_VERSION, feathers = 3 }
		expect(Migrations.run(d).feathers).toBe(3)
	end)
end
