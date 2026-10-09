#!/usr/bin/env python3
"""Create a structural inventory of a directory of Freedom .FCP files."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

from fcp_parser import parse_fcp


def inventory(root: Path) -> dict:
    files = []
    for path in sorted(root.rglob("*.FCP")):
        parsed = parse_fcp(path)
        files.append({
            "name": path.name,
            "path": str(path),
            "sha256": parsed["metadata"]["sha256"],
            "bytes": parsed["metadata"]["byte_length"],
            "scalar_count": len(parsed["scalars"]),
            "tables": {
                name: {
                    "rows": data["row_count"],
                    "columns": data["column_counts"],
                    "rectangular": data["rectangular"],
                }
                for name, data in parsed["tables"].items()
            },
        })
    return {"root": str(root), "file_count": len(files), "files": files}


def main() -> None:
    parser = argparse.ArgumentParser(description="Inventory Freedom .FCP structures")
    parser.add_argument("root", type=Path)
    parser.add_argument("--json-out", type=Path, required=True)
    args = parser.parse_args()
    result = inventory(args.root)
    args.json_out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({"file_count": result["file_count"], "output": str(args.json_out)}, indent=2))


if __name__ == "__main__":
    main()
