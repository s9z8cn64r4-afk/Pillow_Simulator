#!/usr/bin/env python3
"""Erzeugt Luau-Chunks, die Repo-Quellen nach Studio übertragen (per execute_luau im Edit-DataModel).
Aufruf: python3 tools/scripts/studio_sync.py OUT_DIR [drift_report.txt] [--github SHA]
--github SHA: kleiner Chunk, der die Dateien in Studio per HttpService von raw.githubusercontent.com
(öffentliches Repo, gepinnter Commit) lädt, statt den Quelltext einzubetten.
Mit drift_report (Ausgabe von source_hash.py studio.txt) werden nur abweichende Skripte übertragen.
Bestehende Skripte: nur Source wird gesetzt. Fehlende Skripte werden mit passender Klasse angelegt.
Pfade werden als Teil-Listen übergeben, damit Namen mit Punkt (z. B. "Gameplay.spec") funktionieren."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from source_hash import MAP, ROOT, instance_path  # noqa: E402

MAX_CHUNK = 45_000

HEADER = """local function resolve(parts, className)
	local cur = game
	for i, p in parts do
		local nxt = cur:FindFirstChild(p)
		if not nxt then
			if i < #parts then
				nxt = Instance.new("Folder")
			else
				nxt = Instance.new(className)
			end
			nxt.Name = p
			nxt.Parent = cur
		end
		cur = nxt
	end
	return cur
end
local n = 0
"""


def entries():
    for src, base in MAP:
        top = os.path.join(ROOT, src)
        for d, _, files in os.walk(top):
            for f in sorted(files):
                if not f.endswith(".luau"):
                    continue
                rel = os.path.relpath(d, top)
                rel = "" if rel == "." else rel
                name = f[: -len(".luau")]
                cls = "ModuleScript"
                if name.endswith(".server"):
                    cls, name = "Script", name[: -len(".server")]
                elif name.endswith(".client"):
                    cls, name = "LocalScript", name[: -len(".client")]
                parts = base.split(".") + ([p for p in rel.split(os.sep) if p] if rel else [])
                if name != "init":
                    parts.append(name)
                with open(os.path.join(d, f), encoding="utf-8") as fh:
                    source = fh.read()
                repo_path = os.path.relpath(os.path.join(d, f), ROOT).replace(os.sep, "/")
                yield instance_path(rel, base, f), parts, cls, source, repo_path


def long_string(s: str) -> str:
    level = 0
    while ("]" + "=" * level + "]") in s:
        level += 1
    eq = "=" * level
    return f"[{eq}[\n{s}]{eq}]"


REPO_RAW = "https://raw.githubusercontent.com/s9z8cn64r4-afk/Pillow_Simulator"


def github_chunk(sha, items):
    lines = [HEADER, 'local HttpService = game:GetService("HttpService")', "local list = {"]
    for _path, parts, cls, _src, repo_path in items:
        parts_lua = "{" + ", ".join(f'"{p}"' for p in parts) + "}"
        lines.append(f'\t{{ "{repo_path}", {parts_lua}, "{cls}" }},')
    lines.append("}")
    lines.append(f'local base = "{REPO_RAW}/{sha}/"')
    lines.append("""local failed = {}
for _, e in list do
	local ok, src = pcall(HttpService.GetAsync, HttpService, base .. e[1], true)
	if ok then
		resolve(e[2], e[3]).Source = src
		n += 1
	else
		table.insert(failed, e[1] .. ": " .. tostring(src))
	end
end
return ("synced %d/%d %s"):format(n, #list, table.concat(failed, "; "))""")
    return "\n".join(lines) + "\n"


def main():
    args = sys.argv[1:]
    sha = None
    if "--github" in args:
        i = args.index("--github")
        sha = args[i + 1]
        del args[i : i + 2]
    sys.argv = [sys.argv[0]] + args
    out_dir = sys.argv[1]
    only = None
    if len(sys.argv) > 2:
        only = set()
        with open(sys.argv[2], encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("ABWEICHUNG "):
                    only.add(line[len("ABWEICHUNG ") :].split(":")[0])
    os.makedirs(out_dir, exist_ok=True)
    if sha:
        items = [e for e in entries() if only is None or e[0] in only]
        with open(os.path.join(out_dir, "sync_github.luau"), "w", encoding="utf-8") as fh:
            fh.write(github_chunk(sha, items))
        print(f"{len(items)} Datei(en) → {out_dir}/sync_github.luau")
        return
    chunks, cur, names = [], HEADER, []
    for path, parts, cls, source, _repo_path in entries():
        if only is not None and path not in only:
            continue
        parts_lua = "{" + ", ".join(f'"{p}"' for p in parts) + "}"
        stmt = f'resolve({parts_lua}, "{cls}").Source = {long_string(source)}\nn += 1\n'
        if len(cur) + len(stmt) > MAX_CHUNK and names:
            chunks.append(cur + 'return "synced " .. n\n')
            cur, names = HEADER, []
        cur += stmt
        names.append(path)
    if names:
        chunks.append(cur + 'return "synced " .. n\n')
    for i, c in enumerate(chunks):
        with open(os.path.join(out_dir, f"sync_{i:02d}.luau"), "w", encoding="utf-8") as fh:
            fh.write(c)
    print(f"{len(chunks)} Chunk(s) in {out_dir}")


if __name__ == "__main__":
    main()
