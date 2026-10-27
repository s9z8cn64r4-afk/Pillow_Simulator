--!strict
-- Sitzungsberichte für die Beta-Auswertung (PS-41, Gate M3): beim Verlassen ein kompakter Datensatz
-- in DataStore "Sessions_<ENV>" (Schlüssel <Tag>_<Unix>_<Pseudonym>). Keine Namen, keine UserId –
-- nur ein Pseudonym (Hash), damit eindeutige Tester gezählt werden können. Auswertung:
-- tools/studio/beta_report.luau. Fehler beim Schreiben werden geloggt, nie geworfen.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local SessionReportService = {}
SessionReportService.VERSION = 1
SessionReportService.last = nil :: any -- letzter Datensatz (Tests/Diagnose)

local PlayerData, Log
local store: DataStore? = nil
local open: { [Player]: any } = {}

-- austauschbar für Tests
SessionReportService.save = function(key: string, record: any)
	if store then
		store:SetAsync(key, record)
	end
end

-- Pseudonym: nicht umkehrbar ohne Wörterbuch; reicht zum Zählen eindeutiger Tester
function SessionReportService.pseudonym(userId: number): string
	local s = "ps-beta:" .. tostring(userId)
	local h1, h2 = 5381, 52711
	for i = 1, #s do
		local b = string.byte(s, i)
		h1 = (h1 * 33 + b) % 4294967296
		h2 = (h2 * 31 + b * 7) % 4294967296
	end
	return string.format("%08x%08x", h1, h2)
end

local function countTrue(t: { [string]: boolean }?): number
	local n = 0
	for _, v in t or {} do
		if v then
			n += 1
		end
	end
	return n
end

function SessionReportService:Init(registry)
	PlayerData = registry.PlayerDataService
	Log = registry.LogService
	local ok, s = pcall(function()
		return DataStoreService:GetDataStore("Sessions_" .. PlayerData.environment())
	end)
	store = if ok then s else nil
end

function SessionReportService:begin(player: Player, data: any)
	open[player] = {
		data = data, -- dieselbe Tabelle wie im Profil; bleibt nach EndSession lesbar
		unix = os.time(),
		clock = os.clock(),
		isNew = (data.stats.playtimeSeconds or 0) == 0,
		tutStep = data.tutorial.step,
		tutDone = data.tutorial.completed,
		lifetime = data.lifetimeFeathers,
		rebirths = data.rebirths,
		rank = data.rank,
		errors = Log:errorTotal(),
	}
end

-- Datensatz bauen (ohne zu speichern)
function SessionReportService:build(player: Player): any?
	local o = open[player]
	if not o then
		return nil
	end
	local d = o.data
	return {
		v = self.VERSION,
		u = self.pseudonym(player.UserId),
		startUnix = o.unix,
		seconds = math.floor(os.clock() - o.clock),
		newPlayer = o.isNew,
		tutStepStart = o.tutStep,
		tutStepEnd = d.tutorial.step,
		tutDoneStart = o.tutDone,
		tutDoneEnd = d.tutorial.completed,
		feathersEarned = math.floor(math.max(0, d.lifetimeFeathers - o.lifetime)),
		rankStart = o.rank,
		rankEnd = d.rank,
		rebirthsGained = d.rebirths - o.rebirths,
		zones = countTrue(d.unlockedZones),
		pillows = countTrue(d.ownedPillows),
		serverErrors = Log:errorTotal() - o.errors, -- Fehler im Server während der Sitzung (alle Spieler)
		placeVersion = game.PlaceVersion,
		studio = RunService:IsStudio(),
	}
end

function SessionReportService:finish(player: Player)
	local record = self:build(player)
	open[player] = nil
	if not record then
		return
	end
	self.last = record
	local key = ("%s_%d_%s"):format(os.date("!%Y%m%d", record.startUnix), record.startUnix, record.u)
	local ok, err = pcall(self.save, key, record)
	if not ok then
		Log:warn("Sitzungsbericht nicht gespeichert", { err = tostring(err) })
	end
end

function SessionReportService:Start()
	PlayerData.Loaded:Connect(function(player, data)
		self:begin(player, data)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:finish(player)
	end)
end

return SessionReportService
