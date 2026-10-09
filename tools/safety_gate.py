#!/usr/bin/env python3
"""Evaluate a calibration experiment against the provisional safety policy."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def evaluate(data: dict[str, Any], policy: dict[str, Any]) -> dict[str, Any]:
    hard = policy["hard_limits"]
    passed: list[str] = []
    blocked: list[str] = []
    warnings: list[str] = []

    evidence = data.get("evidence", {})
    for key in policy["required_evidence"]:
        if evidence.get(key) is True:
            passed.append(key)
        else:
            blocked.append(f"missing evidence: {key}")

    candidate = data.get("candidate", {})
    if abs(float(candidate.get("fuel_cell_change_fraction", 0))) > hard["max_fuel_cell_change_fraction"]:
        blocked.append("fuel cell change exceeds policy limit")
    if abs(float(candidate.get("ignition_cell_change_deg", 0))) > hard["max_ignition_cell_change_deg"]:
        blocked.append("ignition cell change exceeds policy limit")
    if candidate.get("change_families", []) and len(candidate["change_families"]) > 1:
        blocked.append("more than one calibration family changed")

    faults = data.get("protection_faults", [])
    if faults:
        blocked.append("protection faults present: " + ", ".join(sorted(set(faults))))

    for sample in data.get("samples", []):
        checks = [
            (float(sample.get("rpm", 0)) > hard["max_rpm"], "RPM limit exceeded"),
            (float(sample.get("coolant_c", 0)) >= hard["max_coolant_c"], "coolant limit exceeded"),
            (float(sample.get("iat_c", 0)) >= hard["max_iat_c"], "IAT limit exceeded"),
            (float(sample.get("voltage_v", 99)) < hard["min_voltage_v"], "voltage limit exceeded"),
            (float(sample.get("knock_level", 0)) > hard["max_knock_level"], "knock detected"),
        ]
        if float(sample.get("load_kpa", 0)) >= 80:
            checks.append((float(sample.get("oil_pressure_kpa", 0)) < hard["min_oil_pressure_kpa_under_load"], "oil pressure low under load"))
        for failed, message in checks:
            if failed:
                blocked.append(message)

    for key in policy["write_blockers"]:
        if data.get("write_evidence", {}).get(key) is not True:
            warnings.append(f"write unavailable: {key}")

    status = "blocked" if blocked else "review_required"
    return {
        "policy_version": policy["policy_version"],
        "status": status,
        "passed": sorted(set(passed)),
        "blocked": sorted(set(blocked)),
        "warnings": sorted(set(warnings)),
        "write_authorization": "never",
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Run provisional ECU calibration safety gates")
    parser.add_argument("input", type=Path)
    parser.add_argument("--policy", type=Path, default=Path("config/tuning-safety-policy.json"))
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = evaluate(json.loads(args.input.read_text()), json.loads(args.policy.read_text()))
    args.report.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
