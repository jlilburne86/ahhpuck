#!/usr/bin/env python3
"""Parse the text-based Freedom Computer Support System .FCP files.

This is a lossless-enough inspection parser, not an ECU writer.  It keeps the
original key names and table values, reports dimensions, and deliberately does
not assign semantic meaning to undocumented tables.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any

HEADER = re.compile(r"^\s*([A-Za-z0-9]+)\s*=\s*(.*?)\s*$")


def _number(value: str) -> int | float | str:
    value = value.strip()
    try:
        return int(value, 10)
    except ValueError:
        try:
            return float(value)
        except ValueError:
            return value


def _row(line: str) -> list[int | float | str] | None:
    if "," not in line:
        return None
    values = [part.strip() for part in line.split(",")]
    if not values or any(part == "" for part in values):
        return None
    parsed = [_number(part) for part in values]
    if all(isinstance(value, (int, float)) for value in parsed):
        return parsed
    return None


def parse_fcp(path: Path) -> dict[str, Any]:
    raw = path.read_bytes()
    text = raw.decode("ascii", errors="replace").replace("\r\n", "\n")
    lines = text.splitlines()
    scalars: dict[str, int | float | str] = {}
    tables: dict[str, dict[str, Any]] = {}
    current_table: str | None = None
    table_start = 0

    for line_number, line in enumerate(lines, 1):
        match = HEADER.match(line)
        if match:
            key, value = match.groups()
            if value == "":
                current_table = key
                table_start = line_number
                tables.setdefault(key, {"rows": [], "start_line": line_number})
            else:
                current_table = None
                scalars[key] = _number(value)
            continue

        if current_table is not None:
            parsed = _row(line)
            if parsed is not None:
                tables[current_table]["rows"].append(parsed)

    for table in tables.values():
        rows = table["rows"]
        widths = sorted({len(row) for row in rows})
        table["row_count"] = len(rows)
        table["column_counts"] = widths
        table["rectangular"] = len(widths) <= 1
        table["semantic"] = "undocumented"

    return {
        "metadata": {
            "name": path.name,
            "source_path": str(path),
            "format": "Freedom FCP text",
            "sha256": hashlib.sha256(raw).hexdigest(),
            "byte_length": len(raw),
            "line_count": len(lines),
            "parser": "fcp_parser.py",
        },
        "scalars": scalars,
        "tables": tables,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Inspect a Freedom .FCP file")
    parser.add_argument("path", type=Path)
    parser.add_argument("--json-out", type=Path)
    args = parser.parse_args()
    result = parse_fcp(args.path)
    rendered = json.dumps(result, indent=2, sort_keys=True)
    if args.json_out:
        args.json_out.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)


if __name__ == "__main__":
    main()
