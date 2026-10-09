#!/usr/bin/env python3
"""Build a guarded comparison report for a Freedom .FCP and target profile."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from fcp_parser import parse_fcp
from tune_adapter import build_report


def as_source(fcp: dict[str, Any]) -> dict[str, Any]:
    tables = {
        name: {
            "rows": data["row_count"],
            "columns": data["column_counts"],
            "units": "unknown",
        }
        for name, data in fcp["tables"].items()
    }
    return {
        "metadata": {
            "name": fcp["metadata"]["name"],
            "provenance": f"local FCP parse; sha256 {fcp['metadata']['sha256']}",
            "validated_on_engine": False,
            "format": fcp["metadata"]["format"],
        },
        "profile": {},
        "tables": tables,
        "freedom_structure": {
            "scalar_count": len(fcp["scalars"]),
            "table_count": len(fcp["tables"]),
            "table_names": sorted(fcp["tables"]),
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare an FCP structure to a target profile")
    parser.add_argument("fcp", type=Path)
    parser.add_argument("target", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    fcp = parse_fcp(args.fcp)
    target = json.loads(args.target.read_text(encoding="utf-8"))
    report = build_report(as_source(fcp), target)
    report["source_structure"] = as_source(fcp)["freedom_structure"]
    report["conversion_status"] = "comparison_only"
    report["warnings"].append("FCP table semantics, axis mapping, scaling, checksum, and write protocol are not decoded")
    args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
