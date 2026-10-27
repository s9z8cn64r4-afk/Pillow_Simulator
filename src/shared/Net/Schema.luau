--!strict
-- VERTRAG (nur Tech Lead ändert): jedes Remote des Spiels. Kein Remote außerhalb dieser Liste.
-- dir: "c2s" Client->Server | "s2c" Server->Client
-- args: Validierer-Namen aus Net/Validate (nur c2s)
-- rate/burst: Token-Bucket je Spieler (nur c2s)
-- unreliable: UnreliableRemoteEvent (nur kosmetisch)
export type Entry = {
	dir: "c2s" | "s2c",
	args: { string }?,
	rate: number?,
	burst: number?,
	unreliable: boolean?,
}

local Schema: { [string]: Entry } = {
	-- Client -> Server
	SwingRequest = { dir = "c2s", args = {}, rate = 8, burst = 10 },
	BuyPillow = { dir = "c2s", args = { "pillowId" }, rate = 4, burst = 6 },
	EquipPillow = { dir = "c2s", args = { "pillowId" }, rate = 4, burst = 6 },
	BuyUpgrade = { dir = "c2s", args = { "upgradeKind" }, rate = 6, burst = 10 },
	SetAutoSwing = { dir = "c2s", args = { "boolean" }, rate = 2, burst = 4 },
	TeleportZone = { dir = "c2s", args = { "zoneId" }, rate = 1, burst = 3 },
	Rebirth = { dir = "c2s", args = {}, rate = 0.5, burst = 2 },
	TutorialSkip = { dir = "c2s", args = {}, rate = 0.5, burst = 2 },
	ClaimDaily = { dir = "c2s", args = {}, rate = 0.5, burst = 2 },
	RedeemCode = { dir = "c2s", args = { "codeText" }, rate = 0.2, burst = 3 },
	SetSetting = { dir = "c2s", args = { "settingKey", "settingValue" }, rate = 4, burst = 8 },
	PromptPurchase = { dir = "c2s", args = { "storeKind", "storeItemId" }, rate = 1, burst = 3 },
	SendFeedback = { dir = "c2s", args = { "feedbackCategory", "feedbackText" }, rate = 0.05, burst = 2 },

	-- Server -> Client
	StateInit = { dir = "s2c" }, -- (snapshot)
	StateDelta = { dir = "s2c" }, -- ({ [key]: value })
	SwingFx = { dir = "s2c", unreliable = true }, -- (userId, amount, hitDummyName?)
	Notify = { dir = "s2c" }, -- (kind, payload)
}

return table.freeze(Schema)
