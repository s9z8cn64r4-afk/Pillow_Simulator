-- Mehrspieler-Check (Client). Installiert als ReplicatedStorage.DevToolsClient.MpCheckClient
-- (tools/studio/install_mp_check.luau). In JEDEM Client-Fenster möglichst gleichzeitig (Befehlsleiste):
--   print(require(game.ReplicatedStorage.DevToolsClient.MpCheckClient)()) Sendet 4 eigene Schläge über das echte Remote,
-- zählt 10 s lang ankommende Schlag-Effekte anderer Spieler und prüft, was dieser Client von den anderen sieht.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local me = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local lines = {}
local okAll = true
local function check(cond: boolean, label: string)
	table.insert(lines, (if cond then "OK   " else "FEHLT ") .. label)
	if not cond then
		okAll = false
	end
end

-- Effekte anderer Spieler zählen
local fromOthers: { [number]: number } = {}
local conn = remotes.SwingFx.OnClientEvent:Connect(function(userId: number)
	if userId ~= me.UserId then
		fromOthers[userId] = (fromOthers[userId] or 0) + 1
	end
end)
local rankUps = 0
local conn2 = remotes.Notify.OnClientEvent:Connect(function(kind)
	if kind == "otherRankUp" then
		rankUps += 1
	end
end)

-- eigene Schläge (echtes Remote, Cooldown beachten)
for _ = 1, 4 do
	remotes.SwingRequest:FireServer()
	task.wait(0.8)
end
task.wait(6.8)
conn:Disconnect()
conn2:Disconnect()

for _, p in Players:GetPlayers() do
	if p ~= me then
		local char = p.Character
		local head = char and char:FindFirstChild("Head")
		local tool = char and char:FindFirstChild("Pillow")
		local handle = tool and tool:FindFirstChild("Handle", true)
		local tag = head and head:FindFirstChild("RankTag")
		local title = tag and tag:FindFirstChild("Title", true)
		check(handle ~= nil, ("sehe Kissen von %s"):format(p.Name))
		check(title ~= nil and (title :: any).Text ~= "", ("sehe Rang-Titel von %s"):format(p.Name))
		check((fromOthers[p.UserId] or 0) > 0, ("Schlag-Effekte von %s empfangen: %d"):format(p.Name, fromOthers[p.UserId] or 0))
	end
end
table.insert(lines, ("(Rang-Aufstieg anderer gemeldet: %d – nur > 0, wenn jemand währenddessen aufsteigt)"):format(rankUps))
table.insert(
	lines,
	1,
	("=== Mehrspieler-Check Client %s: %s ==="):format(me.Name, if okAll then "ALLES OK" else "PROBLEME")
)
return table.concat(lines, "\n")
