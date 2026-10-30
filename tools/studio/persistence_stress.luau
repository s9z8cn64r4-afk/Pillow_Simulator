-- Persistenz-Stresstest (MVP-Mindestanforderung „kein Datenverlust in 100 Join/Leave/Shutdown-Zyklen“).
-- Läuft im SERVER-DataModel (Play, Studio) per execute_luau, gegen den echten DataStore PlayerData_<ENV>,
-- aber NUR auf Test-Schlüsseln (Test_Stress_1..4) – nie auf Spieler-Schlüsseln.
-- Ablauf je Zyklus (4 Schlüssel im Wechsel = 4 „Spieler“):
--   Sitzung starten (Join) → Prüfsumme der geladenen Daten = erwartete Prüfsumme? → Daten ändern
--   (Federn, Kissen, Upgrades, Rebirths, Quittung) → neue Prüfsumme merken → Sitzung beenden (Leave).
--   Jeder 5. Zyklus: sofortiges Wieder-Laden desselben Schlüssels (Schnell-Rejoin).
--   Jeder 10. Zyklus: Shutdown-Pfad wie BindToClose (Save() und sofort EndSession, ohne Warten).
-- Am Ende: alle Schlüssel neu laden und gegen die letzte Prüfsumme vergleichen, Schlüssel zurücksetzen.
-- Läuft im Hintergrund (Studio-Aufrufe dürfen nicht lange blockieren). Fortschritt/Ergebnis als Attribute an
-- ServerStorage: StressProgress ("n/100"), StressResult (Textbericht, sobald fertig).
-- Echte Server-Abstürze und Übernahmen zwischen zwei Servern sind in Studio nicht nachstellbar → Beta/Live.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CYCLES = ServerStorage:GetAttribute("StressCycles") or 100
local KEYS = 4
local ENV = Workspace:GetAttribute("Environment") or "DEV"

local ProfileStore = require(ServerStorage.Vendor.ProfileStore :: any)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local Pillows = require(ReplicatedStorage.Shared.Config.Pillows)

local store = ProfileStore.New("PlayerData_" .. ENV, PlayerDataTypes.TEMPLATE)

local function checksum(d: any): string
	local owned = {}
	for id, v in d.ownedPillows or {} do
		if v then
			table.insert(owned, id)
		end
	end
	table.sort(owned)
	local ups = {}
	for k, v in d.upgrades or {} do
		table.insert(ups, k .. "=" .. tostring(v))
	end
	table.sort(ups)
	local receipts = 0
	for _ in d.purchaseHistory or {} do
		receipts += 1
	end
	return table.concat({
		string.format("%.3f", d.feathers or 0),
		tostring(d.rebirths or 0),
		table.concat(owned, ","),
		table.concat(ups, ","),
		tostring(receipts),
		tostring(d.equippedPillow),
	}, "|")
end

local function start(key: string): any
	local deadline = os.clock() + 60
	return store:StartSessionAsync(key, {
		Cancel = function()
			return os.clock() > deadline
		end,
	})
end

local function mutate(d: any, cycle: number)
	d.feathers = math.random(0, 1e9) + math.random()
	d.rebirths = (d.rebirths or 0) + 1
	local list = Pillows.list
	local pick = list[math.random(1, #list)]
	d.ownedPillows[pick.id] = true
	d.equippedPillow = pick.id
	d.upgrades = d.upgrades or {}
	d.upgrades.featherPower = math.random(0, 50)
	d.upgrades.swingSpeed = math.random(0, 20)
	d.purchaseHistory["stress_" .. cycle] = true
end

ServerStorage:SetAttribute("StressResult", nil)
ServerStorage:SetAttribute("StressProgress", "0/" .. CYCLES)

task.spawn(function()
	local t0 = os.clock()
	local expected: { [string]: string } = {}
	local mismatches, failedLoads, rejoins, shutdowns = 0, 0, 0, 0
	local notes = {}

	-- Ausgangszustand: Schlüssel leeren, damit alte Läufe nicht stören
	for k = 1, KEYS do
		local key = "Test_Stress_" .. k
		local p = start(key)
		if p then
			local T = PlayerDataTypes.TEMPLATE
			p.Data.feathers = T.feathers
			p.Data.rebirths = T.rebirths
			p.Data.equippedPillow = T.equippedPillow
			p.Data.ownedPillows = table.clone(T.ownedPillows)
			p.Data.upgrades = table.clone(T.upgrades)
			p.Data.purchaseHistory = {}
			expected[key] = checksum(p.Data)
			p:EndSession()
		else
			failedLoads += 1
		end
	end

	for cycle = 1, CYCLES do
		local key = "Test_Stress_" .. ((cycle - 1) % KEYS + 1)
		local ok, p = pcall(start, key)
		if not ok or not p then
			failedLoads += 1
			table.insert(notes, ("Zyklus %d: Laden fehlgeschlagen (%s)"):format(cycle, tostring(p)))
		else
			local got = checksum(p.Data)
			if got ~= expected[key] then
				mismatches += 1
				table.insert(notes, ("Zyklus %d %s: erwartet %s, geladen %s"):format(cycle, key, expected[key], got))
			end
			mutate(p.Data, cycle)
			expected[key] = checksum(p.Data)
			if cycle % 10 == 0 then
				shutdowns += 1
				p:Save() -- Shutdown-Pfad: speichern anstoßen und sofort beenden (wie BindToClose)
			end
			p:EndSession()
			if cycle % 5 == 0 then
				rejoins += 1
				local ok2, p2 = pcall(start, key) -- Schnell-Rejoin ohne Wartezeit
				if not ok2 or not p2 then
					failedLoads += 1
					table.insert(notes, ("Zyklus %d: Rejoin fehlgeschlagen (%s)"):format(cycle, tostring(p2)))
				else
					if checksum(p2.Data) ~= expected[key] then
						mismatches += 1
						table.insert(notes, ("Zyklus %d %s: Rejoin-Daten weichen ab"):format(cycle, key))
					end
					p2:EndSession()
				end
			end
		end
		ServerStorage:SetAttribute("StressProgress", ("%d/%d"):format(cycle, CYCLES))
	end

	-- Schlussprüfung + Aufräumen
	local finalOk = 0
	for k = 1, KEYS do
		local key = "Test_Stress_" .. k
		local ok, p = pcall(start, key)
		if ok and p then
			if checksum(p.Data) == expected[key] then
				finalOk += 1
			else
				mismatches += 1
				table.insert(notes, key .. ": Schlussprüfung weicht ab")
			end
			p.Data.purchaseHistory = {}
			p:EndSession()
		else
			failedLoads += 1
		end
	end

	local passed = mismatches == 0 and failedLoads == 0 and finalOk == KEYS
	local lines = {
		("=== Persistenz-Stresstest: %s · %d Zyklen auf %d Schlüsseln · %.0f s ==="):format(
			if passed then "BESTANDEN" else "PROBLEME",
			CYCLES,
			KEYS,
			os.clock() - t0
		),
		("Join/Leave %d · Schnell-Rejoins %d · Shutdown-Pfad %d"):format(CYCLES, rejoins, shutdowns),
		("Prüfsummen-Abweichungen %d · Ladefehler %d · Schlussprüfung %d/%d"):format(mismatches, failedLoads, finalOk, KEYS),
	}
	for i = 1, math.min(#notes, 10) do
		table.insert(lines, "  " .. notes[i])
	end
	ServerStorage:SetAttribute("StressResult", table.concat(lines, "\n"))
end)

return ("gestartet: %d Zyklen, PlayerData_%s, Test_Stress_1..%d"):format(CYCLES, ENV, KEYS)
