--!strict
-- Validierer für Client-Argumente. Jeder gibt true zurück, wenn der Wert sicher ist.
local Config = script.Parent.Parent.Config
local Pillows = require(Config.Pillows)
local Progression = require(Config.Progression)
local Zones = require(Config.Zones)
local Products = require(Config.Products)

local storeIds: { [string]: boolean } = {}
for _, p in Products.gamepasses do
	storeIds[p.id] = true
end
for _, p in Products.devProducts do
	storeIds[p.id] = true
end

local Validate = {}

local function isFiniteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

Validate.validators = {
	boolean = function(v: any): boolean
		return type(v) == "boolean"
	end,
	pillowId = function(v: any): boolean
		return type(v) == "string" and #v <= 32 and Pillows.byId[v] ~= nil
	end,
	upgradeKind = function(v: any): boolean
		return type(v) == "string" and #v <= 32 and (Progression.upgrades :: any)[v] ~= nil
	end,
	zoneId = function(v: any): boolean
		return type(v) == "string" and #v <= 32 and Zones.byId[v] ~= nil
	end,
	settingKey = function(v: any): boolean
		return v == "music" or v == "sfx" or v == "reducedMotion" or v == "lowVfx" or v == "uiScale"
	end,
	settingValue = function(v: any): boolean
		return type(v) == "boolean" or isFiniteNumber(v)
	end,
	finiteNumber = isFiniteNumber,
	-- Codes: nur Buchstaben/Ziffern, 1–20 Zeichen (Groß-/Kleinschreibung egal)
	codeText = function(v: any): boolean
		return type(v) == "string" and #v >= 1 and #v <= 20 and string.match(v, "^%w+$") ~= nil
	end,
	storeKind = function(v: any): boolean
		return v == "pass" or v == "product"
	end,
	storeItemId = function(v: any): boolean
		return type(v) == "string" and #v <= 32 and storeIds[v] == true
	end,
	feedbackCategory = function(v: any): boolean
		return v == "bug" or v == "idea" or v == "other"
	end,
	-- Feedback: 3–300 Zeichen, gültiges UTF-8 (Filterung erst auf dem Server)
	feedbackText = function(v: any): boolean
		if type(v) ~= "string" or #v > 1200 then
			return false
		end
		local len = utf8.len(v)
		return len ~= nil and len >= 3 and len <= 300
	end,
	shortString = function(v: any): boolean
		return type(v) == "string" and #v <= 64
	end,
}

-- Prüft eine Argumentliste gegen die Validierer-Namen. Überzählige Argumente sind ein Fehler.
function Validate.args(spec: { string }, args: { any }, count: number): (boolean, string?)
	if count > #spec then
		return false, "zu viele Argumente"
	end
	for i, name in spec do
		local fn = Validate.validators[name]
		if not fn then
			return false, "unbekannter Validierer " .. name
		end
		if not fn(args[i]) then
			return false, ("Argument %d ungültig (%s)"):format(i, name)
		end
	end
	return true, nil
end

return Validate
