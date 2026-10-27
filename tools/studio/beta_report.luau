-- Beta-Auswertung (PS-41 / Gate M3). Läuft im Edit-DataModel über DevTools.RunToolScript(sha, path)
-- oder per execute_luau. Liest DataStores "Sessions_<ENV>" und "Feedback_<ENV>" und gibt einen
-- Textbericht zurück. Studio-Sitzungen (studio = true) zählen nicht mit.
-- Optionen über Attribute an ServerStorage: BetaReportEnv (Standard "DEV"), BetaReportSinceUnix (0 = alle),
-- BetaReportIncludeStudio (true = auch Studio-Sitzungen, nur zum Prüfen des Berichts).
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")

local ENV = ServerStorage:GetAttribute("BetaReportEnv") or "DEV"
local SINCE = ServerStorage:GetAttribute("BetaReportSinceUnix") or 0
local INCLUDE_STUDIO = ServerStorage:GetAttribute("BetaReportIncludeStudio") == true
local MIN_SECONDS = 60 -- kürzere Sitzungen gelten als „Abbruch“, nicht als ausgewertete Sitzung

local function readAll(storeName: string, maxEntries: number)
	local store = DataStoreService:GetDataStore(storeName)
	local out = {}
	local pages = store:ListKeysAsync(nil, 100)
	while true do
		for _, keyInfo in pages:GetCurrentPage() do
			local ok, value = pcall(function()
				return store:GetAsync(keyInfo.KeyName)
			end)
			if ok and value then
				table.insert(out, value)
			end
			if #out >= maxEntries then
				return out
			end
		end
		if pages.IsFinished then
			break
		end
		pages:AdvanceToNextPageAsync()
	end
	return out
end

local function pct(a: number, b: number): string
	return if b > 0 then ("%d %%"):format(math.floor(a / b * 100 + 0.5)) else "–"
end

local function median(list: { number }): number
	if #list == 0 then
		return 0
	end
	table.sort(list)
	local m = math.ceil(#list / 2)
	return list[m]
end

local lines = {}
local function add(s: string)
	table.insert(lines, s)
end

-- Sitzungen
local sessions = {}
for _, r in readAll("Sessions_" .. ENV, 2000) do
	if (INCLUDE_STUDIO or not r.studio) and (r.startUnix or 0) >= SINCE then
		table.insert(sessions, r)
	end
end
local counted, short, testers, newSessions, newTutDone, errSessions = 0, 0, {}, 0, 0, 0
local lengths, perMinute, rebirthSessions = {}, {}, 0
for _, r in sessions do
	testers[r.u] = true
	if r.seconds < MIN_SECONDS then
		short += 1
	else
		counted += 1
		table.insert(lengths, r.seconds / 60)
		table.insert(perMinute, r.feathersEarned / math.max(1, r.seconds / 60))
		if r.serverErrors > 0 then
			errSessions += 1
		end
		if r.rebirthsGained > 0 then
			rebirthSessions += 1
		end
	end
	if r.newPlayer then
		newSessions += 1
		if r.tutDoneEnd then
			newTutDone += 1
		end
	end
end
local nTesters = 0
for _ in testers do
	nTesters += 1
end

add(("=== Beta-Bericht %s (%s)%s ==="):format(
	ENV,
	os.date("!%Y-%m-%d %H:%M UTC"),
	if INCLUDE_STUDIO then " – inkl. Studio-Sitzungen (nur Prüfung)" else ""
))
add(("Sitzungen gesamt: %d · ausgewertet (≥ %d s): %d · kurz: %d · eindeutige Tester: %d"):format(
	#sessions,
	MIN_SECONDS,
	counted,
	short,
	nTesters
))
add(("Gate M3 – Sitzungen ≥ 20: %s"):format(if counted >= 20 then "ERFÜLLT" else "offen"))
add(("Tutorial-Abschluss (Erstsitzungen): %d / %d = %s · Gate ≥ 80 %%: %s"):format(
	newTutDone,
	newSessions,
	pct(newTutDone, newSessions),
	if newSessions > 0 and newTutDone / newSessions >= 0.8 then "ERFÜLLT" else "offen"
))
add(("Sitzungen mit Serverfehlern: %d / %d = %s"):format(errSessions, counted, pct(errSessions, counted)))
add(("Sitzungslänge Median: %.1f Min. · Federn/Min. Median: %d · Sitzungen mit Rebirth: %d"):format(
	median(lengths),
	math.floor(median(perMinute)),
	rebirthSessions
))

-- Feedback
local fb = {}
for _, e in readAll("Feedback_" .. ENV, 500) do
	if (e.unix or 0) >= SINCE then
		table.insert(fb, e)
	end
end
table.sort(fb, function(a, b)
	return (a.unix or 0) > (b.unix or 0)
end)
local byCat = { bug = 0, idea = 0, other = 0 }
for _, e in fb do
	byCat[e.category] = (byCat[e.category] or 0) + 1
end
add(("Feedback: %d (Bugs %d · Ideen %d · Sonstiges %d)"):format(#fb, byCat.bug, byCat.idea, byCat.other))
for i, e in fb do
	if i > 30 then
		add(("… %d weitere"):format(#fb - 30))
		break
	end
	add(("- [%s] %s (Rank %s, Zone %s, v%s)"):format(
		e.category,
		tostring(e.text),
		tostring(e.rank),
		tostring(e.zone),
		tostring(e.placeVersion)
	))
end

return table.concat(lines, "\n")
