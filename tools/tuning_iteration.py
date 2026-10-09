#!/usr/bin/env python3
"""Assess one tune -> run -> log cycle and choose the next safe action."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


CRITICAL = {
    "knock_detected": "possible detonation or false-knock/noise; reduce load and verify knock sensing",
    "lean_under_load": "fuel delivery, injector data, lambda calibration, air leak, or insufficient fuel correction",
    "coolant_high": "cooling capacity, heat soak, airflow, mixture, timing, or excessive load",
    "iat_high": "heat soak, intake routing, ambient conditions, or insufficient charge cooling",
    "oil_pressure_low_under_load": "oil level, pickup/baffling, oil temperature, bearing condition, or sensor fault",
    "system_voltage_low": "charging system, wiring/grounds, battery, or electrical load",
    "rpm_limit": "rev limit or signal scaling error; verify trigger and mechanical RPM limit",
    "telemetry_timeout": "USB/serial bridge, framing, power, cable, or app watchdog failure",
}


def classify(data: dict[str, Any]) -> list[dict[str, str]]:
    faults = set(data.get("protection_faults", []))
    issues: list[dict[str, str]] = []
    for fault in sorted(faults):
        issues.append({"severity": "critical", "code": fault, "likely_issue": CRITICAL.get(fault, "unknown protection fault")})
    evidence = data.get("evidence", {})
    if evidence.get("telemetry_complete") is False:
        issues.append({"severity": "critical", "code": "telemetry_incomplete", "likely_issue": "dropped, stale, or out-of-order samples; do not learn from this run"})
    if evidence.get("sensor_plausibility") is False:
        issues.append({"severity": "critical", "code": "sensor_plausibility", "likely_issue": "sensor calibration, wiring, grounding, or unit conversion problem"})
    if evidence.get("repeatable") is False:
        issues.append({"severity": "warning", "code": "not_repeatable", "likely_issue": "temperature, fuel pressure, driver input, cell coverage, or test-condition variation"})
    if evidence.get("map_coverage", 0) < 0.6:
        issues.append({"severity": "warning", "code": "sparse_coverage", "likely_issue": "insufficient repeated samples in the affected RPM/load cells"})
    if data.get("candidate_score", 0) < data.get("baseline_score", 0):
        issues.append({"severity": "warning", "code": "performance_regression", "likely_issue": "wrong direction, unrelated hardware change, test variation, or an over-large step"})
    return issues


def assess(data: dict[str, Any]) -> dict[str, Any]:
    issues = classify(data)
    critical = any(item["severity"] == "critical" for item in issues)
    candidate = data.get("candidate", {})
    current_step = abs(float(candidate.get("change_fraction", 0.0)))
    next_step = min(current_step / 2 if current_step else 0.01, 0.02)
    score_up = float(data.get("candidate_score", 0)) > float(data.get("baseline_score", 0))
    repeatable = data.get("evidence", {}).get("repeatable") is True

    if critical:
        action = "rollback_and_abort"
        reason = "critical protection or data-integrity issue"
    elif not repeatable or not score_up:
        action = "rollback_and_review"
        reason = "result is not a repeatable improvement"
    else:
        action = "accept_candidate_and_prepare_smaller_next_step"
        reason = "candidate improved the objective with clean repeatable evidence"

    return {
        "iteration": data.get("iteration", 0),
        "decision": action,
        "reason": reason,
        "issues": issues,
        "next_change_fraction_limit": round(next_step, 5),
        "next_change_family": candidate.get("family", "fuel"),
        "write_authorization": "never",
        "required_operator_actions": [
            "preserve baseline, candidate, raw log, and assessment",
            "do not continue load testing after a critical fault",
            "verify mechanical and sensor causes before changing calibration",
            "repeat the same test condition before accepting a change",
        ],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Assess one safe iterative tuning cycle")
    parser.add_argument("input", type=Path)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = assess(json.loads(args.input.read_text(encoding="utf-8")))
    args.report.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
