-- Mehrspieler-Check (Server). Installiert als ServerStorage.DevTools.MpCheckServer (tools/studio/install_mp_check.luau).
-- Im Studio-Test „Clients and Servers“ mit 2+ Spielern in der Befehlsleiste des Server-Fensters:
--   print(require(game.ServerStorage.DevTools.MpCheckServer)())
-- Prüft je Spieler: Profil geladen, Kissen-Werkzeug in der Hand, Rang-Titel am Kopf, Boni-Attribute,
-- Abstand zueinander (Effekte werden nur im Umkreis von 80 Studs gesendet). Ergebnis als Text.
local Players = game:GetService("Players")

local lines = {}
local okAll = true
local function check(cond: boolean, label: string)
	table.insert(lines, (if cond then "OK   " else "FEHLT ") .. label)
	if not cond then
		okAll = false
	end
end

local players = Players:GetPlayers()
check(#players >= 2, ("mindestens 2 Spieler im Server (%d)"):format(#players))

for _, p in players do
	local char = p.Character
	local head = char and char:FindFirstChild("Head")
	local tool = char and char:FindFirstChild("Pillow")
	local tag = head and head:FindFirstChild("RankTag")
	local title = tag and tag:FindFirstChild("Title", true)
	check(p:FindFirstChild("leaderstats") ~= nil, p.Name .. ": Profil geladen (leaderstats)")
	check(tool ~= nil and tool:FindFirstChild("Handle") ~= nil, p.Name .. ": Kissen in der Hand")
	check(
		title ~= nil and title:IsA("TextLabel") and title.Text ~= "",
		p.Name .. ": Rang-Titel über dem Kopf" .. (if title then " („" .. title.Text .. "“)" else "")
	)
	check(p:GetAttribute("FriendsInServer") ~= nil, p.Name .. ": Freunde-Bonus berechnet (" .. tostring(p:GetAttribute("FriendsInServer")) .. ")")
end

if #players >= 2 then
	local a, b = players[1], players[2]
	local ra = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
	local rb = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
	local dist = if ra and rb then (ra.Position - rb.Position).Magnitude else math.huge
	check(dist <= 80, ("Abstand %s–%s %.0f Studs (Effekte nur ≤ 80)"):format(a.Name, b.Name, dist))
end

table.insert(lines, 1, if okAll then "=== Mehrspieler-Check Server: ALLES OK ===" else "=== Mehrspieler-Check Server: PROBLEME ===")
return table.concat(lines, "\n")
