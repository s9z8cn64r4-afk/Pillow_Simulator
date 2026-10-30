"""
Einzige Quelle aller Spielwerte (Design & Economy).
Aus dieser Datei werden src/shared/Config/*.luau generiert (gen_config.py)
und die Economy-Simulation (sim.py) gespeist. Werte NUR hier ändern.
"""

# --- Schlag -----------------------------------------------------------------
SWING = {
    "baseCooldown": 0.60,        # Sekunden zwischen Schlägen ohne Upgrade
    "minCooldown": 0.30,         # Untergrenze
    "latencyTolerance": 0.08,    # Server akzeptiert Schläge bis zu so viel früher
    "autoSwingEfficiency": 0.80, # Auto-Swing liefert 80 % (Gamepass: 100 %)
    "autoSwingRank": 2,          # ab diesem Rank kostenlos
    "dummyBonus": 1.5,           # Multiplikator bei Treffer auf eine Kissenpuppe
    "dummyRange": 9,             # Studs Trefferreichweite (Server prüft)
}

# --- Kissen -----------------------------------------------------------------
# power = Federn pro Schlag (Basis); speed = Faktor auf Cooldown (<1 = schneller)
PILLOWS = [
    # id,                 name,                  rarity,      power,   cost,          zone,         rebirths, speed
    ("worn",            "Worn-Out Pillow",     "Common",          1,          0,  "bedroom",        0, 1.00),
    ("cotton",          "Cotton Pillow",       "Common",          3,         75,  "bedroom",        0, 1.00),
    ("striped",         "Striped Pillow",      "Common",          7,        600,  "bedroom",        0, 1.00),
    ("fluffy",          "Fluffy Pillow",       "Uncommon",       16,      4_500,  "bedroom",        0, 1.00),
    ("sleepover",       "Sleepover Pillow",    "Uncommon",       38,      35_000,  "livingroom",     0, 1.00),
    ("heart",           "Heart Pillow",        "Uncommon",       90,     250_000,  "livingroom",     0, 0.97),
    ("satin",           "Satin Pillow",        "Rare",          210,    1_800_000,  "livingroom",     0, 0.97),
    ("hotel",           "Hotel Deluxe Pillow", "Rare",          480,  13_000_000,  "hotelsuite",     0, 0.95),
    ("royal",           "Royal Velvet Pillow", "Rare",        1_100, 90_000_000,  "hotelsuite",     0, 0.95),
    ("memoryfoam",      "Memory Foam Pillow",  "Epic",        2_600, 650_000_000,  "hotelsuite",     1, 0.93),
    ("cloud",           "Cloud Puff Pillow",   "Epic",        6_200, 4_500_000_000, "cloudrealm",     1, 0.93),
    ("thunder",         "Thunder Pillow",      "Epic",       15_000, 32_000_000_000, "cloudrealm",   2, 0.90),
    ("starlight",       "Starlight Pillow",    "Legendary",  36_000, 230_000_000_000, "cloudrealm",  3, 0.90),
    ("dream",           "Dreamweaver Pillow",  "Legendary",  90_000, 1_600_000_000_000, "cloudrealm",  5, 0.88),
]

RARITIES = [
    # id,          color (RGB),         Symbol für farbunabhängige Kennzeichnung
    ("Common",    (190, 196, 204), "●"),
    ("Uncommon",  (120, 214, 140), "◆"),
    ("Rare",      (90, 170, 255),  "★"),
    ("Epic",      (190, 120, 255), "❖"),
    ("Legendary", (255, 196, 60),  "👑"),
]

# --- Zonen ------------------------------------------------------------------
ZONES = [
    # id,           name,                 multiplier, cost,          rebirths
    ("bedroom",    "Cozy Bedroom",              1.0,             0, 0),
    ("livingroom", "Pajama Party Lounge",       2.0,        75_000, 0),
    ("hotelsuite", "Grand Hotel Suite",         4.0,     4_000_000, 0),
    ("cloudrealm", "Cloud Kingdom",             8.0,   250_000_000, 1),
]

# --- Upgrades ---------------------------------------------------------------
UPGRADES = {
    "featherPower": {"name": "Feather Power", "baseCost": 5, "growth": 1.28,
                      "bonusPerLevel": 0.25, "maxLevel": 100},
    "swingSpeed":   {"name": "Swing Speed",   "baseCost": 100, "growth": 4.0,
                      "cooldownPerLevel": 0.05, "maxLevel": 6},
}

# --- Rebirth ----------------------------------------------------------------
REBIRTH = {
    "baseCost": 80_000_000,  # Federn, die man besitzen muss (und abgibt)
    "costGrowth": 6.0,        # Kosten(n) = baseCost * growth^n
    "bonusPerRebirth": 0.5,   # +50 % additiv ...
    "softcapAfter": 10,       # ... ab hier nur noch +25 % je Rebirth
    "bonusAfterSoftcap": 0.25,
}

# --- Ranks (lebenslange Federn) --------------------------------------------
RANKS = [
    # name,                lifetimeFeathers, bonus (multiplikativ als +x)
    ("Sleepyhead",                     0, 0.00),
    ("Pillow Rookie",                500, 0.03),
    ("Feather Fighter",           25_000, 0.06),
    ("Fluff Brawler",            500_000, 0.09),
    ("Cushion Champion",       8_000_000, 0.12),
    ("Duvet Duke",           150_000_000, 0.15),
    ("Slumber Knight",     2_000_000_000, 0.18),
    ("Dream Warden",      30_000_000_000, 0.21),
    ("Night Sovereign",  400_000_000_000, 0.25),
    ("Pillow Legend",  5_000_000_000_000, 0.30),
]

# --- Belohnungen ------------------------------------------------------------
# Daily Reward: Wert in "Minuten aktueller Produktion" (skaliert mit Fortschritt) + Boosts
DAILY_REWARDS = [
    {"day": 1, "kind": "feathersMinutes", "amount": 3},
    {"day": 2, "kind": "boost", "boost": "feathers2x", "minutes": 10},
    {"day": 3, "kind": "feathersMinutes", "amount": 6},
    {"day": 4, "kind": "boost", "boost": "feathers2x", "minutes": 15},
    {"day": 5, "kind": "feathersMinutes", "amount": 10},
    {"day": 6, "kind": "boost", "boost": "feathers2x", "minutes": 20},
    {"day": 7, "kind": "feathersMinutes", "amount": 20},
]

SOCIAL = {
    "friendBonusPerFriend": 0.10,
    "friendBonusMax": 0.30,
    "groupBonus": 0.10,
}

BOOSTS = {
    "feathers2x": {"name": "2x Feathers", "multiplier": 2.0, "maxStackMinutes": 120},
}

# --- Monetarisierung (Preise: vom Owner an Claude delegiert, 2026-10-27; echter Preis wird im Creator Hub gesetzt und muss hier gleich sein) ---
PRODUCTS = {
    "gamepasses": [
        {"id": "doubleFeathers", "name": "2x Feathers", "multiplier": 2.0, "robux": 149, "assetId": 0},
        {"id": "vip", "name": "VIP", "multiplier": 1.10, "robux": 99, "assetId": 0},
        {"id": "fasterAutoSwing", "name": "Better Auto-Swing", "autoSwingEfficiency": 1.0, "robux": 79, "assetId": 0},
    ],
    "devProducts": [
        {"id": "boost2x30", "name": "2x Feathers (30 min)", "boost": "feathers2x", "minutes": 30, "robux": 25, "productId": 0},
    ],
}
