--!strict
-- VERTRAG (nur Tech Lead ändert): Spielerdaten-Schema. Änderungen => SCHEMA_VERSION erhöhen + Migration.
export type PlayerData = {
	schemaVersion: number,
	feathers: number,
	lifetimeFeathers: number,
	rebirths: number,
	rank: number,
	equippedPillow: string,
	ownedPillows: { [string]: boolean },
	upgrades: { featherPower: number, swingSpeed: number },
	unlockedZones: { [string]: boolean },
	autoSwingEnabled: boolean,
	dailyReward: { streakDay: number, lastClaimUnix: number },
	redeemedCodes: { [string]: boolean },
	tutorial: { step: number, completed: boolean },
	purchaseHistory: { [string]: boolean },
	activeBoosts: { [string]: number },
	settings: { music: number, sfx: number, reducedMotion: boolean, lowVfx: boolean, uiScale: number },
	stats: { totalSwings: number, playtimeSeconds: number, firstJoinUnix: number },
}

local SCHEMA_VERSION = 1

local TEMPLATE: PlayerData = {
	schemaVersion = SCHEMA_VERSION,
	feathers = 0,
	lifetimeFeathers = 0,
	rebirths = 0,
	rank = 1,
	equippedPillow = "worn",
	ownedPillows = { worn = true },
	upgrades = { featherPower = 0, swingSpeed = 0 },
	unlockedZones = { bedroom = true },
	autoSwingEnabled = false,
	dailyReward = { streakDay = 0, lastClaimUnix = 0 },
	redeemedCodes = {},
	tutorial = { step = 0, completed = false },
	purchaseHistory = {},
	activeBoosts = {},
	settings = { music = 0.6, sfx = 0.8, reducedMotion = false, lowVfx = false, uiScale = 1 },
	stats = { totalSwings = 0, playtimeSeconds = 0, firstJoinUnix = 0 },
}

-- Felder, die NICHT an den Client repliziert werden
local PRIVATE_KEYS = { purchaseHistory = true, redeemedCodes = true }

return table.freeze({
	SCHEMA_VERSION = SCHEMA_VERSION,
	TEMPLATE = TEMPLATE,
	PRIVATE_KEYS = PRIVATE_KEYS,
})
