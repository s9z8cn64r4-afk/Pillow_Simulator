--!strict
-- Kissen-Werkzeug (Shared/Util/PillowTool): Server und Studio-Fotomodus bauen dasselbe Tool
local Shared = game:GetService("ReplicatedStorage").Shared
local Pillows = require(Shared.Config.Pillows)
local PillowTool = require(Shared.Util.PillowTool)

return function(it, expect)
	it("jedes Kissen ergibt ein Tool mit Handle, Kissen-ID und ohne Physik am Griff", function()
		for _, p in Pillows.list do
			local tool = PillowTool.build(p.id)
			local handle = tool:FindFirstChild("Handle")
			expect(tool.Name).toBe(PillowTool.TOOL_NAME)
			expect(tool:GetAttribute("PillowId")).toBe(p.id)
			expect(handle ~= nil and handle:IsA("BasePart")).toBeTruthy()
			if handle and handle:IsA("BasePart") then
				expect(handle.Anchored).toBeFalsy()
				expect(handle.CanCollide).toBeFalsy()
				expect(handle.Massless).toBeTruthy()
			end
			tool:Destroy()
		end
	end)

	it("Seltenheits-Effekte: Aura ab Epic, Spur nur bei Legendary", function()
		for _, p in Pillows.list do
			local tool = PillowTool.build(p.id)
			local handle = tool:FindFirstChild("Handle") :: Instance
			local aura = handle:FindFirstChild("RarityFxAura") ~= nil
			local trail = handle:FindFirstChild("RarityFxTrail") ~= nil
			local epicPlus = p.rarity == "Epic" or p.rarity == "Legendary"
			expect(aura).toBe(epicPlus)
			expect(trail).toBe(p.rarity == "Legendary")
			tool:Destroy()
		end
	end)

	it("unbekannte ID fällt auf das Startkissen zurück", function()
		local tool = PillowTool.build("does-not-exist")
		expect(tool:GetAttribute("PillowId")).toBe(Pillows.starter)
		tool:Destroy()
	end)
end
