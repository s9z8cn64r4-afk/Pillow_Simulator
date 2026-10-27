--!strict
-- Zentrales Logging. Phase 1: Konsole. Phase 3: Weiterleitung warn+ an das Relay (ADR-0004).
local RunService = game:GetService("RunService")

local LEVELS = { debug = 1, info = 2, warn = 3, error = 4, critical = 5 }

local LogService = {}
LogService.minLevel = if RunService:IsStudio() then LEVELS.debug else LEVELS.info
LogService.counts = { warn = 0, error = 0, critical = 0, scriptError = 0 }
-- Weiterleitung warn+ (setzt RelayService): sink(level, msg, ctx). ctx.noRelay = true unterdrückt sie.
LogService.sink = nil :: ((string, string, { [string]: any }?) -> ())?

local function encode(ctx: { [string]: any }?): string
	if not ctx then
		return ""
	end
	local parts = {}
	for k, v in ctx do
		table.insert(parts, k .. "=" .. tostring(v))
	end
	table.sort(parts)
	return " {" .. table.concat(parts, ", ") .. "}"
end

function LogService:log(level: string, msg: string, ctx: { [string]: any }?)
	local lv = LEVELS[level] or LEVELS.info
	if self.counts[level] then
		self.counts[level] += 1
	end
	if lv >= LEVELS.warn and self.sink and not (ctx and ctx.noRelay) then
		pcall(self.sink, level, msg, ctx) -- Logging darf nie das Spiel stören
	end
	if lv < self.minLevel then
		return
	end
	local line = ("[PS][%s] %s%s"):format(string.upper(level), msg, encode(ctx))
	if lv >= LEVELS.warn then
		warn(line)
	else
		print(line)
	end
end

function LogService:debug(msg: string, ctx: { [string]: any }?)
	self:log("debug", msg, ctx)
end
function LogService:info(msg: string, ctx: { [string]: any }?)
	self:log("info", msg, ctx)
end
function LogService:warn(msg: string, ctx: { [string]: any }?)
	self:log("warn", msg, ctx)
end
function LogService:error(msg: string, ctx: { [string]: any }?)
	self:log("error", msg, ctx)
end
function LogService:critical(msg: string, ctx: { [string]: any }?)
	self:log("critical", msg, ctx)
end

-- Unbehandelte Server-Skriptfehler mitzählen (Fehlerrate für Gate M3, SessionReportService)
function LogService:Start()
	game:GetService("ScriptContext").Error:Connect(function(message: string, trace: string)
		self.counts.scriptError += 1
		if self.sink then
			-- erste Stack-Zeile als Ort (ohne Zeilennummer im Fingerprint, das macht der Relay-Puffer)
			local where = string.match(trace or "", "^[^\n]+") or ""
			pcall(self.sink, "error", message, { where = where })
		end
	end)
end

-- Summe aller Fehler (error + critical + unbehandelte Skriptfehler)
function LogService:errorTotal(): number
	return self.counts.error + self.counts.critical + self.counts.scriptError
end

return LogService
