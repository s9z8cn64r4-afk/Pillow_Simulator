--!strict
-- Integration: Rang-Titel über dem Kopf und Trail ab Rank 5. Stellt den Rang wieder her.
return function(it, expect, ctx)
	local reg = ctx.registry
	local player = ctx.player
	local PD = reg.PlayerDataService
	local Rank = reg.RankService
	local Progression = require(game:GetService("ReplicatedStorage").Shared.Config.Progression)
	local data = PD:get(player)
	local backup = data.rank

	local function root(): Instance?
		return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	end

	it("Titel zeigt den aktuellen Rang", function()
		data.rank = 3
		Rank:applyTag(player)
		local head = player.Character and player.Character:FindFirstChild("Head")
		local tag = head and head:FindFirstChild("RankTag")
		expect(tag ~= nil).toBeTruthy()
		expect((tag :: any).Title.Text).toBe(Progression.ranks[3].name)
	end)

	it("Trail erst ab Rank 5", function()
		data.rank = 4
		Rank:applyTag(player)
		expect((root() :: any):FindFirstChild("RankTrail") == nil).toBeTruthy()
		data.rank = 5
		Rank:applyTag(player)
		expect((root() :: any):FindFirstChild("RankTrail") ~= nil).toBeTruthy()
	end)

	it("Trail verschwindet unter Rank 5 (z. B. nach Datenkorrektur)", function()
		data.rank = 1
		Rank:applyTag(player)
		expect((root() :: any):FindFirstChild("RankTrail") == nil).toBeTruthy()
	end)

	data.rank = backup
	Rank:applyTag(player)
end
