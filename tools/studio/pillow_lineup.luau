-- In Studio (Edit) ausführen: stellt alle Kissenmodelle in Config-Reihenfolge nebeneinander (Ordner
-- Workspace.PillowLineup, verankert) und richtet die Kamera darauf aus. Zum Aufräumen erneut mit CLEAR = true.
local CLEAR = false
local old = workspace:FindFirstChild("PillowLineup")
if old then
	old:Destroy()
end
if CLEAR then
	return "cleared"
end
local Pillows = require(game.ReplicatedStorage.Shared.Config.Pillows)
local folder = game.ReplicatedStorage.Assets.Pillows
local lineup = Instance.new("Folder")
lineup.Name = "PillowLineup"
lineup.Parent = workspace
local origin = Vector3.new(0, 4, -40)
local missing = {}
for i, p in Pillows.list do
	local tpl = folder:FindFirstChild(p.id)
	if tpl then
		local c = tpl:Clone()
		c.Anchored = true
		local col = (i - 1) % 7
		local row = (i - 1) // 7
		c.CFrame = CFrame.new(origin + Vector3.new(col * 3.2, -row * 2.6, 0))
		c.Parent = lineup
	else
		table.insert(missing, p.id)
	end
end
workspace.CurrentCamera.CFrame = CFrame.lookAt(origin + Vector3.new(9.6, 0.5, 17), origin + Vector3.new(9.6, -1.3, 0))
return "lineup ok, fehlend: " .. table.concat(missing, ",")
