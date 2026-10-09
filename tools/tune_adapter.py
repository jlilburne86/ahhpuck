#!/usr/bin/env python3
"""Validate and compare normalized ECU tune metadata.

This intentionally does not parse vendor binaries or write ECU data. It creates
an auditable compatibility report before any future table conversion.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

REQUIRED_PROFILE = (
    "chassis", "engine", "load_strategy", "injection", "ignition", "vvt",
    "injectors", "fuel", "map_units", "ignition_offset_verified"
)


def load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def profile_value(profile: dict[str, Any], key: str) -> str:
    value = profile.get(key)
    if isinstance(value, dict):
        return str(value.get("value", "unknown"))
    return str(value or "unknown")


def build_report(source: dict[str, Any], target: dict[str, Any]) -> dict[str, Any]:
    source_profile = source.get("profile", {})
    target_profile = target.get("profile", target)
    warnings: list[str] = []
    mismatches: list[dict[str, str]] = []

    for key in REQUIRED_PROFILE:
        source_value = profile_value(source_profile, key)
        target_value = profile_value(target_profile, key)
        if source_value == "unknown" or target_value == "unknown":
            warnings.append(f"{key}: unknown on source or target")
        elif source_value.lower() != target_value.lower():
            mismatches.append({"field": key, "source": source_value, "target": target_value})

    tables = source.get("tables", {})
    fuel_units = str(tables.get("fuel", {}).get("units", "unknown"))
    ignition_units = str(tables.get("ignition", {}).get("units", "unknown"))
    if fuel_units.lower() not in {"ve", "volumetric_efficiency"}:
        warnings.append("fuel table is not verified VE; Freedom conversion is blocked")
    if ignition_units.lower() not in {"deg_btdc", "degrees_btdc"}:
        warnings.append("ignition table units or trigger reference are not verified")
    if not source.get("metadata", {}).get("provenance"):
        warnings.append("source provenance is missing")
    if not source.get("metadata", {}).get("validated_on_engine"):
        warnings.append("source tune has no confirmed engine validation record")

    if warnings or mismatches:
        confidence = "amber" if not any("blocked" in item or "unknown" in item for item in warnings) else "red"
    else:
        confidence = "green"

    return {
        "source": source.get("metadata", {}).get("name", "unnamed source"),
        "target": target_profile,
        "confidence": confidence,
        "mismatches": mismatches,
        "warnings": warnings,
        "conversion_status": "comparison_only" if confidence != "green" else "eligible_for_review",
        "next_steps": [
            "preserve the original source file",
            "verify injector data, fuel pressure, fuel type, and ignition offset",
            "decode Freedom axes and scaling before resampling",
            "review fuel and ignition differences before any write candidate is created",
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Create a safe tune compatibility report")
    parser.add_argument("source", type=Path, help="normalized source tune JSON")
    parser.add_argument("target", type=Path, help="target profile JSON")
    parser.add_argument("--report", type=Path, help="write report JSON")
    args = parser.parse_args()
    report = build_report(load_json(args.source), load_json(args.target))
    rendered = json.dumps(report, indent=2, sort_keys=True)
    if args.report:
        args.report.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)


if __name__ == "__main__":
    main()
