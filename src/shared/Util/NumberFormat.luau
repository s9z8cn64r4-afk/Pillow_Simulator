--!strict
-- Zahlen mit Suffixen anzeigen: 1234 -> "1.23K". Abschneiden statt Runden, damit nie mehr angezeigt wird als vorhanden.
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local NumberFormat = {}

local function trimZeros(s: string): string
	if string.find(s, "%.") then
		s = string.gsub(s, "0+$", "")
		s = string.gsub(s, "%.$", "")
	end
	return s
end

function NumberFormat.short(n: number): string
	if n ~= n then
		return "0"
	end
	if n < 0 then
		return "-" .. NumberFormat.short(-n)
	end
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local tier = math.floor(math.log10(n) / 3)
	tier = math.min(tier, #SUFFIXES - 1)
	local value = n / 10 ^ (tier * 3)
	-- Gleitkomma-Korrektur (z. B. 999.9999 statt 1000)
	if value >= 1000 and tier < #SUFFIXES - 1 then
		tier += 1
		value /= 1000
	end
	local text
	if value < 10 then
		text = string.format("%.2f", math.floor(value * 100 + 1e-9) / 100)
	elseif value < 100 then
		text = string.format("%.1f", math.floor(value * 10 + 1e-9) / 10)
	else
		text = tostring(math.floor(value + 1e-9))
	end
	return trimZeros(text) .. SUFFIXES[tier + 1]
end

-- Mit Tausenderpunkten (für Tooltips): 1234567 -> "1,234,567"
function NumberFormat.full(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

return NumberFormat
