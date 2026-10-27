--!strict
-- Einlösbare Codes (handgepflegt; Veröffentlichung von Codes = öffentlicher Post → nur mit Owner-Freigabe).
-- Schlüssel in GROSSBUCHSTABEN. reward wie Daily Reward: feathersMinutes (Minuten Produktion) oder boost.
-- expiresUnix = nil → läuft nicht ab.
export type Code = {
	reward: { kind: string, amount: number?, boost: string?, minutes: number? },
	expiresUnix: number?,
}

local codes: { [string]: Code } = {
	-- Start-/Beta-Codes (Entwurf, Owner gibt frei, bevor sie öffentlich genannt werden)
	PILLOWFIGHT = { reward = { kind = "feathersMinutes", amount = 5 } },
	FLUFFY = { reward = { kind = "boost", boost = "feathers2x", minutes = 15 } },
	BETATESTER = { reward = { kind = "feathersMinutes", amount = 10 }, expiresUnix = 1798761600 }, -- 2027-01-01
}

return table.freeze(codes)
