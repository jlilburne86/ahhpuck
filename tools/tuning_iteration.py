#!/usr/bin/env python3
"""Assess one tune -> run -> log cycle and choose the next safe action."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


MIN_MAP_COVERAGE = 0.6

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
    # Fail closed: evidence must be explicitly True. Missing evidence is treated the
    # same as failed evidence, because "we did not check" is not "it was fine".
    if evidence.get("telemetry_complete") is not True:
        issues.append({"severity": "critical", "code": "telemetry_incomplete", "likely_issue": "dropped, stale, out-of-order, or unverified samples; do not learn from this run"})
    if evidence.get("sensor_plausibility") is not True:
        issues.append({"severity": "critical", "code": "sensor_plausibility", "likely_issue": "sensor plausibility failed or was not checked: calibration, wiring, grounding, or unit conversion"})
    if evidence.get("repeatable") is not True:
        issues.append({"severity": "warning", "code": "not_repeatable", "likely_issue": "repeatability failed or was not assessed: temperature, fuel pressure, driver input, cell coverage, or test-condition variation"})
    coverage = evidence.get("map_coverage")
    if not isinstance(coverage, (int, float)) or coverage < MIN_MAP_COVERAGE:
        issues.append({"severity": "warning", "code": "sparse_coverage", "likely_issue": "insufficient or unreported repeated samples in the affected RPM/load cells"})
    if data.get("candidate_score", 0) < data.get("baseline_score", 0):
        issues.append({"severity": "warning", "code": "performance_regression", "likely_issue": "wrong direction, unrelated hardware change, test variation, or an over-large step"})
    return issues


MAX_STEP = 0.02
FIRST_STEP = 0.01


def next_step_limit(action: str, candidate: dict[str, Any], evidence: dict[str, Any]) -> tuple[float, str]:
    """Choose the next step size so the loop can actually reach its target.

    Previously every accepted step was halved, so from 2% the total correction could
    never exceed ~4% however far the map was from target. Now:
    - abort: no next step until a human releases the session;
    - rollback/review: halve, because the last step was not proven;
    - accepted with a known remaining error: step by that error, capped at MAX_STEP,
      so large errors keep moving at the cap and small ones are not overshot;
    - accepted without a remaining-error figure: halve (the old conservative rule).
    """
    current = abs(float(candidate.get("change_fraction", 0.0))) or FIRST_STEP
    if action == "rollback_and_abort":
        return 0.0, "critical issue: no further change until a human releases the session"
    if action == "rollback_and_review":
        return min(current / 2, MAX_STEP), "last step not proven: retry at half size"
    remaining = evidence.get("remaining_error_fraction")
    if isinstance(remaining, (int, float)) and not isinstance(remaining, bool):
        remaining = abs(float(remaining))
        if remaining >= MAX_STEP:
            return MAX_STEP, "accepted and still far from target: keep stepping at the policy cap"
        return remaining, "accepted and close to target: step by the remaining error only"
    return min(current / 2, MAX_STEP), "accepted but remaining error unknown: halve to stay conservative"


def assess(data: dict[str, Any]) -> dict[str, Any]:
    issues = classify(data)
    critical = any(item["severity"] == "critical" for item in issues)
    candidate = data.get("candidate", {})
    score_up = float(data.get("candidate_score", 0)) > float(data.get("baseline_score", 0))
    repeatable = data.get("evidence", {}).get("repeatable") is True
    sparse = any(item["code"] == "sparse_coverage" for item in issues)

    if critical:
        action = "rollback_and_abort"
        reason = "critical protection or data-integrity issue"
    elif not repeatable or not score_up:
        action = "rollback_and_review"
        reason = "result is not a repeatable improvement"
    elif sparse:
        # Previously a warning only, so a change learned from a handful of cells
        # could still be accepted. Coverage is now part of the decision.
        action = "rollback_and_review"
        reason = "improvement is based on too few RPM/load cells"
    else:
        action = "accept_candidate_and_prepare_smaller_next_step"
        reason = "candidate improved the objective with clean repeatable evidence"

    next_step, step_reason = next_step_limit(action, candidate, data.get("evidence", {}))
    return {
        "iteration": data.get("iteration", 0),
        "decision": action,
        "reason": reason,
        "issues": issues,
        "next_change_fraction_limit": round(next_step, 5),
        "next_step_reason": step_reason,
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
