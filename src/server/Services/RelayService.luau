--!strict
-- Logging-Relay (PS-36, ADR-0004): sammelt warn+/Skriptfehler, Anti-Exploit, Feedback und Sitzungs-Summen,
-- fasst gleiche Meldungen zusammen (Fingerprint + Zähler) und sendet alle 30 s einen Batch an das Relay
-- (bei „critical“ nach 2 s). Zugang über Roblox-Secrets: relay_url (Basis-URL) + relay_token (Bearer).
-- Ohne Secrets (z. B. lokaler Studio-Test) bleibt der Dienst aus. Das Spiel hängt nie vom Relay ab:
-- Puffer mit Obergrenze, Verwerfen nach MAX_ATTEMPTS Fehlversuchen, alles in pcall.
-- Datenschutz: userId → Pseudonym (p), Namen werden entfernt.
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Pseudonym = require(script.Parent.Parent.Pseudonym)

local RelayService = {}
RelayService.FLUSH_INTERVAL = 30
RelayService.CRITICAL_DELAY = 2
RelayService.MAX_EVENTS = 100
RelayService.MAX_ATTEMPTS = 3
RelayService.enabled = false
RelayService.stats = { sent = 0, failed = 0, dropped = 0, batches = 0 }

type Event = { cat: string, msg: string, fp: string, count: number, ctx: { [string]: any }, sum: boolean }

local Log, PlayerData
local queue: { [string]: Event } = {}
local order: { string } = {}
local pending: { body: string, events: number, attempts: number }? = nil
local criticalScheduled = false
local urlSecret: any, tokenSecret: any = nil, nil

local VALID = { critical = true, error = true, warn = true, exploit = true, feedback = true, session = true }
local DROP_KEYS =
	{ userId = true, name = true, displayName = true, username = true, noRelay = true, category = true }

-- Versand (austauschbar für Tests): gibt (ok, Status) zurück
RelayService.send = function(body: string): (boolean, any)
	local res = HttpService:RequestAsync({
		Url = urlSecret:AddSuffix("/ingest"),
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Authorization"] = tokenSecret:AddPrefix("Bearer "),
		},
		Body = body,
	})
	return res.Success, res.StatusCode
end

function RelayService:Init(registry)
	Log = registry.LogService
	PlayerData = registry.PlayerDataService
	local ok1, u = pcall(function()
		return HttpService:GetSecret("relay_url")
	end)
	local ok2, t = pcall(function()
		return HttpService:GetSecret("relay_token")
	end)
	if ok1 and ok2 then
		urlSecret, tokenSecret = u, t
		self.enabled = true
	end
end

-- Kontext bereinigen: Pseudonym statt UserId, nur einfache Werte, kurze Texte
local function clean(ctx: { [string]: any }?): { [string]: any }
	local out = {}
	if not ctx then
		return out
	end
	if type(ctx.userId) == "number" then
		out.p = Pseudonym.of(ctx.userId)
	end
	local n = 0
	for k, v in ctx do
		if n >= 8 then
			break
		end
		if not DROP_KEYS[k] then
			local t = type(v)
			if t == "number" or t == "boolean" then
				out[k] = v
				n += 1
			elseif t == "string" then
				out[k] = string.sub(v, 1, 200)
				n += 1
			end
		end
	end
	return out
end

-- Fingerprint: Kategorie + Meldung ohne Zahlen (gleiche Fehler mit anderen Werten werden zusammengefasst)
function RelayService.fingerprint(cat: string, msg: string): string
	return string.sub(cat .. ":" .. string.gsub(msg, "%d+", "#"), 1, 80)
end

-- Meldung einreihen. sum = true: Zahlen im Kontext werden bei gleichem Fingerprint addiert.
function RelayService:push(cat: string, msg: string, ctx: { [string]: any }?, sum: boolean?)
	if not self.enabled then
		return -- ohne Relay nichts sammeln
	end
	if not VALID[cat] then
		cat = "warn"
	end
	local fp = self.fingerprint(cat, msg)
	local e = queue[fp]
	if e then
		e.count += 1
		if e.sum then
			for k, v in clean(ctx) do
				if type(v) == "number" and type(e.ctx[k]) == "number" then
					e.ctx[k] += v
				end
			end
		end
	elseif #order >= self.MAX_EVENTS then
		self.stats.dropped += 1
		return
	else
		queue[fp] = {
			cat = cat,
			msg = string.sub(msg, 1, 300),
			fp = fp,
			count = 1,
			ctx = clean(ctx),
			sum = sum == true,
		}
		table.insert(order, fp)
	end
	if cat == "critical" and not criticalScheduled then
		criticalScheduled = true
		task.delay(self.CRITICAL_DELAY, function()
			criticalScheduled = false
			self:flush()
		end)
	end
end

-- Batch bauen (leert den Puffer). Gibt nil zurück, wenn nichts anliegt.
function RelayService:buildBatch(): (string?, number)
	if #order == 0 and self.stats.dropped == 0 then
		return nil, 0
	end
	local events = {}
	for _, fp in order do
		local e = queue[fp]
		table.insert(events, { cat = e.cat, msg = e.msg, fp = e.fp, count = e.count, ctx = e.ctx })
	end
	table.clear(queue)
	table.clear(order)
	if #events == 0 then
		events = {
			{ cat = "warn", msg = "Relay-Puffer übergelaufen", fp = "relay:overflow", count = 1, ctx = {} },
		}
	end
	local body = HttpService:JSONEncode({
		v = 1,
		env = PlayerData.environment(),
		place = game.PlaceVersion,
		server = if game.JobId ~= "" then string.sub(game.JobId, 1, 8) else "studio",
		dropped = self.stats.dropped,
		events = events,
	})
	self.stats.dropped = 0
	return body, #events
end

-- Senden: offener Wiederholversuch zuerst, sonst neuer Batch
function RelayService:flush()
	if not self.enabled then
		return
	end
	if not pending then
		local body, n = self:buildBatch()
		if not body then
			return
		end
		pending = { body = body, events = n, attempts = 0 }
	end
	local p = pending :: any
	local ok, sent, status = pcall(self.send, p.body)
	if ok and sent then
		self.stats.sent += p.events
		self.stats.batches += 1
		pending = nil
	else
		p.attempts += 1
		if p.attempts >= self.MAX_ATTEMPTS then
			self.stats.failed += p.events
			pending = nil
			-- noRelay: diese Warnung nicht selbst wieder einreihen
			Log:warn("Relay nicht erreichbar – Batch verworfen", {
				status = tostring(if ok then status else sent),
				noRelay = true,
			})
		end
	end
end

-- Nur für Tests: Dienst mit eigenem Sender einschalten / Zustand zurücksetzen
function RelayService:_setForTest(enabled: boolean, sender: ((string) -> (boolean, any))?)
	assert(RunService:IsStudio(), "nur in Studio")
	self.enabled = enabled
	if sender then
		self.send = sender
	end
	table.clear(queue)
	table.clear(order)
	pending = nil
	self.stats = { sent = 0, failed = 0, dropped = 0, batches = 0 }
end

function RelayService:Start()
	Log.sink = function(level: string, msg: string, ctx: { [string]: any }?)
		local cat = (ctx and ctx.category) or level
		self:push(cat, msg, ctx)
	end
	if not self.enabled then
		Log:info("Relay aus (Secrets relay_url/relay_token fehlen)", { noRelay = true })
		return
	end
	task.spawn(function()
		while true do
			task.wait(self.FLUSH_INTERVAL)
			pcall(self.flush, self)
		end
	end)
	game:BindToClose(function()
		pcall(self.flush, self)
	end)
end

return RelayService
