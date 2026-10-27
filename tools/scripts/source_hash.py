#!/usr/bin/env python3
"""Drift-Prüfung Repo ↔ Studio (ADR-0001).
Berechnet für jede Luau-Datei den Studio-Instanzpfad und denselben Hash wie tools/scripts/studio_hash.luau.
Aufruf: python3 tools/scripts/source_hash.py [studio_output.txt]
Ohne Argument: gibt Pfad=Hash aus. Mit Datei (Ausgabe des Studio-Skripts): vergleicht und meldet Abweichungen."""
import os
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
MAP = [
    ("src/server", "ServerScriptService.Server"),
    ("src/client", "StarterPlayer.StarterPlayerScripts.Client"),
    ("src/shared", "ReplicatedStorage.Shared"),
    ("tests", "ServerStorage.Tests"),
    ("src/first", "ReplicatedFirst"),
]


def h(data: bytes) -> int:
    v = 0
    for b in data:
        v = (v * 31 + b) % 2147483647
    return v


def instance_path(rel_dir: str, base: str, fname: str) -> str:
    name = fname[: -len(".luau")]
    for suffix in (".server", ".client"):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
    parts = [base] + ([p for p in rel_dir.split(os.sep) if p] if rel_dir else [])
    if name != "init":
        parts.append(name)
    return ".".join(parts)


def repo_hashes():
    out = {}
    for src, base in MAP:
        top = os.path.join(ROOT, src)
        for d, _, files in os.walk(top):
            for f in files:
                if f.endswith(".luau"):
                    rel = os.path.relpath(d, top)
                    rel = "" if rel == "." else rel
                    with open(os.path.join(d, f), "rb") as fh:
                        data = fh.read()
                    # Studio speichert ohne abschließenden Zeilenumbruch nicht anders – beides normalisieren
                    out[instance_path(rel, base, f)] = h(data.rstrip(b"\n"))
    return out


def main():
    repo = repo_hashes()
    if len(sys.argv) < 2:
        for k in sorted(repo):
            print(f"{k}={repo[k]}")
        return
    studio = {}
    with open(sys.argv[1], encoding="utf-8") as fh:
        for line in fh:
            if "=" in line:
                k, v = line.strip().rsplit("=", 1)
                studio[k] = int(v)
    drift = 0
    for k in sorted(set(repo) | set(studio)):
        if repo.get(k) != studio.get(k):
            drift += 1
            print(f"ABWEICHUNG {k}: repo={repo.get(k)} studio={studio.get(k)}")
    print("OK – keine Abweichung" if drift == 0 else f"{drift} Abweichung(en)")
    sys.exit(1 if drift else 0)


if __name__ == "__main__":
    main()
