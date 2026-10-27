--!strict
-- Integration: Einstellungen werden serverseitig validiert, gerundet und gespeichert.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local Settings = reg.SettingsService
	local data = PD:get(player)
	local backup = table.clone(data.settings)

	it("Lautstärke wird auf 25-%-Schritte gerundet und begrenzt", function()
		expect(Settings:set(player, "sfx", 0.6)).toBeTruthy()
		expect(data.settings.sfx).toBeNear(0.5)
		expect(Settings:set(player, "music", 7)).toBeTruthy()
		expect(data.settings.music).toBeNear(1)
	end)

	it("Ungültige Werte und Schlüssel werden abgelehnt", function()
		expect(Settings:set(player, "sfx", 0 / 0)).toBeFalsy()
		expect(Settings:set(player, "reducedMotion", "yes")).toBeFalsy()
		expect(Settings:set(player, "uiScale", 3)).toBeFalsy()
		expect(Settings:set(player, "feathers", 1e9)).toBeFalsy()
		expect(data.settings.feathers == nil).toBeTruthy()
	end)

	it("Schalter und UI-Größe werden gespeichert", function()
		expect(Settings:set(player, "reducedMotion", true)).toBeTruthy()
		expect(data.settings.reducedMotion).toBe(true)
		expect(Settings:set(player, "uiScale", 1.15)).toBeTruthy()
		expect(data.settings.uiScale).toBe(1.15)
	end)

	data.settings = backup
	PD:markChanged(player, "settings")
end
