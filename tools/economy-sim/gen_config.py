#!/usr/bin/env python3
"""Erzeugt src/shared/Config/*.luau aus content.py (einzige Wertequelle).
Aufruf: python3 tools/economy-sim/gen_config.py"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import content as C  # noqa: E402

OUT = os.path.normpath(os.path.join(HERE, "..", "..", "src", "shared", "Config"))
HEADER = "--!strict\n-- GENERIERT aus tools/economy-sim/content.py – nicht von Hand bearbeiten.\n-- Werte ändern: content.py anpassen, gen_config.py ausführen, sim.py --check.\n\n"


def lua(v, indent=1):
    pad = "\t" * indent
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        if isinstance(v, float) and v.is_integer() and abs(v) < 1e15:
            return repr(v)
        return repr(v)
    if isinstance(v, str):
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(v, (list, tuple)):
        if not v:
            return "{}"
        items = ",\n".join(pad + lua(x, indent + 1) for x in v)
        return "{\n" + items + ",\n" + "\t" * (indent - 1) + "}"
    if isinstance(v, dict):
        if not v:
            return "{}"
        parts = []
        for k, x in v.items():
            key = k if k.isidentifier() else "[" + lua(k) + "]"
            parts.append(pad + key + " = " + lua(x, indent + 1))
        return "{\n" + ",\n".join(parts) + ",\n" + "\t" * (indent - 1) + "}"
    raise TypeError(type(v))


def write(name, body):
    path = os.path.join(OUT, name + ".luau")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER + body)
    print("geschrieben:", os.path.relpath(path))


def main():
    os.makedirs(OUT, exist_ok=True)
    pillows = [
        {"id": p[0], "name": p[1], "rarity": p[2], "power": p[3], "cost": p[4],
         "zone": p[5], "rebirths": p[6], "speed": p[7], "order": i}
        for i, p in enumerate(C.PILLOWS)
    ]
    rar = [{"id": r[0], "color": list(r[1]), "symbol": r[2], "order": i} for i, r in enumerate(C.RARITIES)]
    write("Pillows", "export type Pillow = {\n\tid: string,\n\tname: string,\n\trarity: string,\n\tpower: number,\n"
          "\tcost: number,\n\tzone: string,\n\trebirths: number,\n\tspeed: number,\n\torder: number,\n}\n\n"
          "local list: { Pillow } = " + lua(pillows) + "\n\nlocal byId: { [string]: Pillow } = {}\n"
          "for _, p in list do\n\tbyId[p.id] = p\nend\n\n"
          "local rarities = " + lua(rar) + "\n\n"
          "return table.freeze({ list = table.freeze(list), byId = table.freeze(byId), rarities = rarities, starter = \"worn\" })\n")
    zones = [{"id": z[0], "name": z[1], "multiplier": z[2], "cost": z[3], "rebirths": z[4], "order": i}
             for i, z in enumerate(C.ZONES)]
    write("Zones", "export type Zone = {\n\tid: string,\n\tname: string,\n\tmultiplier: number,\n\tcost: number,\n"
          "\trebirths: number,\n\torder: number,\n}\n\nlocal list: { Zone } = " + lua(zones) +
          "\n\nlocal byId: { [string]: Zone } = {}\nfor _, z in list do\n\tbyId[z.id] = z\nend\n\n"
          "return table.freeze({ list = table.freeze(list), byId = table.freeze(byId), start = \"bedroom\" })\n")
    ranks = [{"name": r[0], "lifetimeFeathers": r[1], "bonus": r[2]} for r in C.RANKS]
    write("Progression", "return table.freeze({\n\tswing = " + lua(C.SWING, 2) + ",\n\tupgrades = " +
          lua(C.UPGRADES, 2) + ",\n\trebirth = " + lua(C.REBIRTH, 2) + ",\n\tranks = " + lua(ranks, 2) + ",\n})\n")
    write("Rewards", "return table.freeze({\n\tdaily = " + lua(C.DAILY_REWARDS, 2) + ",\n\tsocial = " +
          lua(C.SOCIAL, 2) + ",\n\tboosts = " + lua(C.BOOSTS, 2) + ",\n})\n")
    write("Products", "-- robux = nil: Preis noch nicht vom Owner freigegeben; assetId/productId = 0: noch nicht angelegt.\n"
          "return " + lua(C.PRODUCTS) + "\n")


if __name__ == "__main__":
    main()
