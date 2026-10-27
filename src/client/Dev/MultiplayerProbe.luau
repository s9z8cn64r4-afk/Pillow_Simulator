--!strict
-- Nur Studio: zählt während des Mehrspieler-Checks (workspace-Attribut MultiplayerCheck = "live"),
-- was dieser Client vom anderen Spieler sieht: Rang-Titel, Schlag-Effekte, Rang-Hinweise.
-- Ausgabe: [MP-CLIENT] PASS/FAIL … im Client-Ausgabefenster.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NetClient = require(ReplicatedStorage:WaitForChild("Shared").Net.NetClient)

local MultiplayerProbe = {}

function MultiplayerProbe.start()
	if not RunService:IsStudio() then
		return
	end
	local me = Players.LocalPlayer
	local fxFromOthers, rankNotes = 0, 0
	local counting = false
	NetClient.on("SwingFx", function(userId: number)
		if counting and userId ~= me.UserId then
			fxFromOthers += 1
		end
	end)
	NetClient.on("Notify", function(kind: string)
		if counting and kind == "otherRankUp" then
			rankNotes += 1
		end
	end)

	local function onState()
		local state = workspace:GetAttribute("MultiplayerCheck")
		if state == "live" then
			counting = true
		elseif state == "done" and counting then
			counting = false
			local tags, others = 0, 0
			for _, p in Players:GetPlayers() do
				if p ~= me then
					others += 1
					local head = p.Character and p.Character:FindFirstChild("Head")
					local tag = head and head:FindFirstChild("RankTag")
					if tag and tag:IsA("BillboardGui") and tag.Enabled then
						tags += 1
					end
				end
			end
			local function line(ok: boolean, text: string)
				print(("[MP-CLIENT] %s %s (%s)"):format(if ok then "PASS" else "FAIL", text, me.Name))
			end
			line(others > 0 and tags == others, ("Rang-Titel anderer sichtbar %d/%d"):format(tags, others))
			line(fxFromOthers > 0, ("Schlag-Effekte des Mitspielers empfangen: %d"):format(fxFromOthers))
			line(rankNotes > 0, ("Rang-Hinweis des Mitspielers empfangen: %d"):format(rankNotes))
		end
	end
	workspace:GetAttributeChangedSignal("MultiplayerCheck"):Connect(onState)
	onState()
end

return MultiplayerProbe
