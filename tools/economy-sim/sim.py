#!/usr/bin/env python3
"""
Economy-Simulation Pillow Simulator.

Simuliert Spielerprofile mit einem gierigen Kauf-Bot (kürzeste Amortisationszeit zuerst)
und gibt Zeit-bis-Meilenstein-Tabellen aus. Formeln müssen identisch zu
src/shared/Util/Formulas.luau sein (Paritätstest: tests/unit/Formulas.spec.luau).

Aufruf:  python3 tools/economy-sim/sim.py [--check] [--md PFAD]
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import content as C  # noqa: E402

PILLOWS = [dict(zip(["id", "name", "rarity", "power", "cost", "zone", "rebirths", "speed"], p)) for p in C.PILLOWS]
ZONES = [dict(zip(["id", "name", "mult", "cost", "rebirths"], z)) for z in C.ZONES]
ZONE_BY_ID = {z["id"]: z for z in ZONES}
RANKS = [dict(zip(["name", "need", "bonus"], r)) for r in C.RANKS]
UP = C.UPGRADES
RB = C.REBIRTH


# ---------------- Formeln (Spiegel von Formulas.luau) -----------------------
def upgrade_cost(kind, level):
    u = UP[kind]
    return math.floor(u["baseCost"] * u["growth"] ** level)


def rebirth_cost(rebirths):
    return math.floor(RB["baseCost"] * RB["costGrowth"] ** rebirths)


def rebirth_mult(rebirths):
    soft = RB["softcapAfter"]
    if rebirths <= soft:
        return 1 + RB["bonusPerRebirth"] * rebirths
    return 1 + RB["bonusPerRebirth"] * soft + RB["bonusAfterSoftcap"] * (rebirths - soft)


def rank_index(lifetime):
    idx = 0
    for i, r in enumerate(RANKS):
        if lifetime >= r["need"]:
            idx = i
    return idx


def cooldown(speed_level, pillow_speed):
    s = C.SWING
    cd = (s["baseCooldown"] - UP["swingSpeed"]["cooldownPerLevel"] * speed_level) * pillow_speed
    return max(s["minCooldown"], cd)


def feathers_per_swing(pillow_power, fp_level, zone_mult, rebirths, rank_bonus, extra_mult=1.0):
    # Bewusst ohne Abrunden: Federn werden als Kommazahl geführt und nur abgerundet angezeigt,
    # sonst wären kleine Boni (+25 % auf 1 Feder) am Spielanfang wirkungslos.
    return (
        pillow_power
        * (1 + UP["featherPower"]["bonusPerLevel"] * fp_level)
        * zone_mult
        * rebirth_mult(rebirths)
        * (1 + rank_bonus)
        * extra_mult
    )


# ---------------- Simulation ------------------------------------------------
class Player:
    def __init__(self, profile):
        self.p = profile
        self.feathers = 0.0
        self.lifetime = 0.0
        self.rebirths = 0
        self.owned = {"worn"}
        self.equipped = "worn"
        self.fp = 0
        self.speed = 0
        self.zones = {"bedroom"}
        self.zone = "bedroom"  # Bot steht immer in der besten freigeschalteten Zone
        self.t = 0.0
        self.milestones = {}

    def mark(self, key):
        if key not in self.milestones:
            self.milestones[key] = self.t

    def pillow(self, pid=None):
        return next(p for p in PILLOWS if p["id"] == (pid or self.equipped))

    def rate(self, fp=None, speed=None, pillow=None, zone=None, rebirths=None):
        """Federn pro Sekunde für das Profil."""
        fp = self.fp if fp is None else fp
        speed = self.speed if speed is None else speed
        pil = self.pillow(pillow)
        zmult = ZONE_BY_ID[zone or self.zone]["mult"]
        rb = self.rebirths if rebirths is None else rebirths
        rank_bonus = RANKS[rank_index(self.lifetime)]["bonus"]
        extra = self.p["gamepassMult"]
        per_swing = feathers_per_swing(pil["power"], fp, zmult, rb, rank_bonus, extra)
        cd = cooldown(speed, pil["speed"])
        auto_ok = rank_index(self.lifetime) + 1 >= C.SWING["autoSwingRank"]
        active_share = self.p["activeShare"] if auto_ok else 1.0
        active = active_share * self.p["clickEfficiency"] * (
            1 + (C.SWING["dummyBonus"] - 1) * self.p["dummyShare"]
        )
        auto = (1 - active_share) * C.SWING["autoSwingEfficiency"] if auto_ok else 0.0
        return per_swing / cd * (active + auto)

    def candidates(self):
        base = self.rate()
        out = []
        # Kissen
        for p in PILLOWS:
            if p["id"] in self.owned or p["zone"] not in self.zones or p["rebirths"] > self.rebirths:
                continue
            if p["power"] / p["speed"] <= self.pillow()["power"] / self.pillow()["speed"]:
                continue
            gain = self.rate(pillow=p["id"]) - base
            out.append(("pillow", p["id"], p["cost"], gain))
        # Upgrades
        if self.fp < UP["featherPower"]["maxLevel"]:
            c = upgrade_cost("featherPower", self.fp)
            out.append(("fp", None, c, self.rate(fp=self.fp + 1) - base))
        if self.speed < UP["swingSpeed"]["maxLevel"]:
            c = upgrade_cost("swingSpeed", self.speed)
            out.append(("speed", None, c, self.rate(speed=self.speed + 1) - base))
        # Zonen (nächste in Reihenfolge)
        for z in ZONES:
            if z["id"] in self.zones:
                continue
            if z["rebirths"] <= self.rebirths:
                out.append(("zone", z["id"], z["cost"], self.rate(zone=z["id"]) - base))
            break
        return [c for c in out if c[3] > 0]

    def buy(self, kind, ident, cost):
        self.feathers -= cost
        if kind == "pillow":
            self.owned.add(ident)
            self.equipped = ident
            self.mark("pillow:" + ident)
            self.mark("firstPillow")
        elif kind == "fp":
            self.fp += 1
            self.mark("firstUpgrade")
        elif kind == "speed":
            self.speed += 1
            self.mark("firstUpgrade")
        elif kind == "zone":
            self.zones.add(ident)
            self.zone = ident
            self.mark("zone:" + ident)

    def try_rebirth(self):
        cost = rebirth_cost(self.rebirths)
        if self.feathers < cost:
            return False
        self.feathers = 0
        self.rebirths += 1
        self.fp = 0
        self.speed = 0
        self.zones = {"bedroom"}
        self.zone = "bedroom"
        self.mark("rebirth:%d" % self.rebirths)
        return True

    def step(self, dt):
        r = self.rate()
        self.feathers += r * dt
        self.lifetime += r * dt
        self.t += dt
        rk = rank_index(self.lifetime) + 1
        self.mark("rank:%d" % rk)

    def run(self, max_seconds, max_rebirths=12):
        dt = 1.0
        while self.t < max_seconds:
            self.step(dt)
            # So viel kaufen, wie sinnvoll ist (Amortisation)
            for _ in range(50):
                cands = self.candidates()
                if not cands:
                    break
                best = min(cands, key=lambda c: c[2] / c[3])
                if best[2] <= self.feathers:
                    self.buy(best[0], best[1], best[2])
                else:
                    break
            # Rebirth, sobald bezahlbar und der Bot alles Sinnvolle der Zone gekauft hat
            if self.rebirths < max_rebirths and self.feathers >= rebirth_cost(self.rebirths):
                self.try_rebirth()
            if len(self.owned) == len(PILLOWS) and rank_index(self.lifetime) == len(RANKS) - 1:
                self.mark("allContent")
                break
        return self


PROFILES = [
    {"name": "Casual", "minutesPerDay": 15, "activeShare": 0.5, "clickEfficiency": 0.70, "dummyShare": 0.3, "gamepassMult": 1.0},
    {"name": "Regular", "minutesPerDay": 45, "activeShare": 0.6, "clickEfficiency": 0.75, "dummyShare": 0.5, "gamepassMult": 1.0},
    {"name": "Grinder", "minutesPerDay": 180, "activeShare": 0.3, "clickEfficiency": 0.80, "dummyShare": 0.5, "gamepassMult": 1.0},
    {"name": "Regular + 2x Pass", "minutesPerDay": 45, "activeShare": 0.6, "clickEfficiency": 0.75, "dummyShare": 0.5, "gamepassMult": 2.0},
]

# Zielkurven aus Masterprompt J.4 (Regular-Profil, aktive Spielminuten)
TARGETS = [
    ("firstUpgrade", 0, 0.5, "Erstes Upgrade ≤ 30 s"),
    ("firstPillow", 0, 2.0, "Erstes neues Kissen ≤ 2 Min."),
    ("zone:livingroom", 8, 16, "Zone 2 nach 10–15 Min. (Toleranz 8–16)"),
    ("rebirth:1", 40, 65, "Erster Rebirth nach 45–60 Min. (Toleranz 40–65)"),
]


def fmt_min(sec):
    if sec is None:
        return "—"
    m = sec / 60
    if m < 1:
        return "%d s" % round(sec)
    if m < 120:
        return "%.1f Min." % m
    return "%.1f h" % (m / 60)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="Exit 1, wenn Zielkurven verfehlt werden")
    ap.add_argument("--md", help="Ergebnis als Markdown-Tabelle in diese Datei schreiben")
    args = ap.parse_args()

    results = {}
    for prof in PROFILES:
        results[prof["name"]] = Player(prof).run(max_seconds=60 * 60 * 60)

    keys = ["firstUpgrade", "firstPillow", "rank:2", "zone:livingroom", "zone:hotelsuite", "rebirth:1",
            "zone:cloudrealm", "rebirth:2", "rebirth:3", "rank:5", "pillow:starlight", "rebirth:5",
            "pillow:dream", "rank:10", "allContent"]
    header = "| Meilenstein | " + " | ".join(results) + " |"
    lines = [header, "|" + "---|" * (len(results) + 1)]
    for k in keys:
        row = [k]
        for name, pl in results.items():
            t = pl.milestones.get(k)
            prof = next(p for p in PROFILES if p["name"] == name)
            if t is None:
                row.append("—")
            else:
                days = t / 60 / prof["minutesPerDay"]
                row.append(fmt_min(t) + (" (Tag %d)" % (math.floor(days) + 1) if t > 3600 else ""))
        lines.append("| " + " | ".join(row) + " |")
    table = "\n".join(lines)
    print(table)

    reg = results["Regular"].milestones
    failures = []
    print("\nZielkurven (Regular):")
    for key, lo, hi, label in TARGETS:
        t = reg.get(key)
        ok = t is not None and lo <= t / 60 <= hi
        print("  %s %s → %s" % ("OK  " if ok else "FAIL", label, fmt_min(t)))
        if not ok:
            failures.append(label)
    # Content-Dauer Regular 2–3 Wochen (Toleranz 10–28 Tage)
    t_all = reg.get("allContent")
    days_all = None if t_all is None else t_all / 60 / 45
    ok = days_all is not None and 10 <= days_all <= 28
    print("  %s MVP-Inhalte für Regular in 2–3 Wochen (Toleranz 10–28 Tage) → %s" %
          ("OK  " if ok else "FAIL", "—" if days_all is None else "%.1f Tage" % days_all))
    if not ok:
        failures.append("Content-Dauer")
    # Fairness: Pass beschleunigt höchstens ~2x, Nicht-Zahler erreichen alles
    t_pass = results["Regular + 2x Pass"].milestones.get("allContent")
    if t_all and t_pass:
        print("  INFO Beschleunigung durch 2x-Pass bis Content-Ende: %.2fx" % (t_all / t_pass))

    if args.md:
        with open(args.md, "w", encoding="utf-8") as f:
            f.write(table + "\n")
    if args.check and failures:
        print("\nZielkurven verfehlt:", ", ".join(failures))
        sys.exit(1)


if __name__ == "__main__":
    main()
