"""Summarize LCOV line coverage; no dependencies or source modifications.

Usage: python tool/coverage_summary.py coverage/lcov.info
DA records describe executable lines, not branch coverage. Missing files are
not assigned an invented percentage. Generated .g.dart files are reported in
the overall result and excluded in the separate handwritten result.
"""

import json
import sys
from pathlib import Path


def summarize(path):
    files = {}
    current = None
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if line.startswith("SF:"):
            current = line[3:].replace("\\", "/")
            files.setdefault(current, {})
        elif line.startswith("DA:") and current is not None:
            number, hits, *_ = line[3:].split(",")
            records = files[current]
            records[int(number)] = max(records.get(int(number), 0), int(hits))
    rows = []
    for name, records in sorted(files.items()):
        rows.append({
            "file": name,
            "hit": sum(value > 0 for value in records.values()),
            "found": len(records),
            "uncovered": [number for number, hits in records.items() if hits == 0],
        })

    def totals(selected):
        hit = sum(row["hit"] for row in selected)
        found = sum(row["found"] for row in selected)
        return {"hit": hit, "found": found,
                "percent": round(100 * hit / found, 2) if found else None}

    return {"overall": totals(rows),
            "handwritten": totals([r for r in rows if not r["file"].endswith(".g.dart")]),
            "files": rows}


if __name__ == "__main__":
    print(json.dumps(summarize(sys.argv[1]), indent=2, ensure_ascii=False))
