#!/usr/bin/env python3
"""Evaluate a calibration experiment against the provisional safety policy."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ALWAYS_REQUIRED = ("rpm", "load_kpa", "coolant_c", "iat_c", "voltage_v")
LOAD_THRESHOLD_KPA = 80


def _value(sample: dict[str, Any], key: str) -> float | None:
    value = sample.get(key)
    return float(value) if isinstance(value, (int, float)) and not isinstance(value, bool) else None


def _has(sample: dict[str, Any], key: str) -> bool:
    return _value(sample, key) is not None


def _over(sample: dict[str, Any], key: str, limit: float) -> bool:
    value = _value(sample, key)
    return value is not None and value > limit


def _at_or_over(sample: dict[str, Any], key: str, limit: float) -> bool:
    value = _value(sample, key)
    return value is not None and value >= limit


def _under(sample: dict[str, Any], key: str, limit: float) -> bool:
    value = _value(sample, key)
    return value is not None and value < limit


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

    ignition_change = abs(float(candidate.get("ignition_cell_change_deg", 0))) > 0
    if ignition_change and evidence.get("knock_sensing_verified") is not True:
        # Policy rule: ignition stays locked until knock sensing is proven.
        blocked.append("ignition change requires verified knock sensing")

    faults = data.get("protection_faults", [])
    if faults:
        blocked.append("protection faults present: " + ", ".join(sorted(set(faults))))

    samples = data.get("samples", [])
    if not samples:
        # Fail closed: a gate with nothing to inspect cannot pass the experiment.
        blocked.append("no telemetry samples supplied")

    for sample in samples:
        # Missing channels are reported as missing, never defaulted to a safe value.
        for key in ALWAYS_REQUIRED:
            if not _has(sample, key):
                blocked.append(f"missing channel: {key}")
        load = _value(sample, "load_kpa")
        under_load = load is not None and load >= LOAD_THRESHOLD_KPA
        checks = [
            (_over(sample, "rpm", hard["max_rpm"]), "RPM limit exceeded"),
            (_at_or_over(sample, "coolant_c", hard["max_coolant_c"]), "coolant limit exceeded"),
            (_at_or_over(sample, "iat_c", hard["max_iat_c"]), "IAT limit exceeded"),
            (_under(sample, "voltage_v", hard["min_voltage_v"]), "voltage limit exceeded"),
            (_over(sample, "knock_level", hard["max_knock_level"]), "knock detected"),
        ]
        if ignition_change and not _has(sample, "knock_level"):
            blocked.append("missing channel: knock_level (required for ignition changes)")
        if under_load:
            if _has(sample, "oil_pressure_kpa"):
                checks.append((_under(sample, "oil_pressure_kpa", hard["min_oil_pressure_kpa_under_load"]), "oil pressure low under load"))
            else:
                blocked.append("missing channel under load: oil_pressure_kpa")
            if _has(sample, "lambda"):
                checks.append((_over(sample, "lambda", hard["max_lambda_under_load"]), "lean under load"))
            else:
                blocked.append("missing channel under load: lambda")
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
