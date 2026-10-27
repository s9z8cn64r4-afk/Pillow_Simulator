"""Selene json2-Ausgabe in GitHub-Annotations umwandeln (Logs sind aus der Cloud-Umgebung
nicht abrufbar, Annotations schon). Exit 1 bei Fehlern, Warnungen brechen nicht ab."""
import json
import sys


def main(path: str) -> int:
    errors = warnings = 0
    raw = open(path, encoding="utf-8").read()
    for line in raw.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        if d.get("type") != "Diagnostic":
            continue
        sev = str(d.get("severity", "Warning")).lower()
        label = d.get("primary_label") or {}
        span = label.get("span") or {}
        f = label.get("filename", "")
        ln = int(span.get("start_line", 0)) + 1
        col = int(span.get("start_column", 0)) + 1
        msg = f"[{d.get('code', '')}] {d.get('message', '')}".replace("\n", " ")
        kind = "error" if sev == "error" else "warning"
        if kind == "error":
            errors += 1
        else:
            warnings += 1
        print(f"::{kind} file={f},line={ln},col={col}::{msg}")
    if errors == 0 and warnings == 0 and raw.strip() and '"Diagnostic"' not in raw and '"Summary"' not in raw:
        # Unerwartete Ausgabe (z. B. Parse-/Konfigurationsfehler) sichtbar machen
        print("::error::selene: " + raw.strip().replace("\n", " ")[:900])
        return 1
    print(f"selene: {errors} errors, {warnings} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
