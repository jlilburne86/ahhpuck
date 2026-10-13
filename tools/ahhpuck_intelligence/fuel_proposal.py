"""Deterministic, read-only fuel proposal generation for reviewed telemetry."""
from __future__ import annotations

import math
from collections import defaultdict
from statistics import fmean
from typing import Any, Iterable


def _data(frame: dict[str, Any]) -> dict[str, Any]:
    value = frame.get("decoded", frame)
    return value if isinstance(value, dict) else {}


def _number(value: Any) -> float | None:
    return float(value) if isinstance(value, (int, float)) and math.isfinite(float(value)) else None


def _cell(frame: dict[str, Any]) -> tuple[int, int] | None:
    data = _data(frame)
    rpm, load = _number(data.get("rpm")), _number(data.get("load"))
    if rpm is None or load is None:
        return None
    return (int(rpm // 500) * 500, int(load // 10) * 10)


def propose(
    frames: Iterable[dict[str, Any]],
    *,
    evidence: dict[str, Any],
    target_lambda: float = 0.90,
    max_change_fraction: float = 0.02,
    minimum_samples: int = 3,
) -> dict[str, Any]:
    """Return a bounded fuel-only proposal, or a fail-closed blocker.

    A positive correction means the measured lambda is leaner than target and
    needs review for additional fuel. This is a proposal for human review, not
    a write package or an authorization.
    """
    required = ("telemetry_complete", "sensor_plausibility", "repeatable", "map_coverage")
    blockers = [key for key in required if evidence.get(key) is not True and not (key == "map_coverage" and float(evidence.get(key, 0)) >= 0.60)]
    rows: dict[tuple[int, int], list[float]] = defaultdict(list)
    protection_faults: set[str] = set()
    for frame in frames:
        data = _data(frame)
        cell = _cell(frame)
        value = _number(data.get("lambda"))
        if cell is None or value is None:
            continue
        if _number(data.get("knock_level")) is not None and float(data["knock_level"]) > 0.15:
            protection_faults.add("knock_detected")
        if _number(data.get("coolant_c")) is not None and float(data["coolant_c"]) >= 105:
            protection_faults.add("coolant_high")
        rows[cell].append(value)
    if protection_faults:
        blockers.extend(sorted(protection_faults))

    proposals = []
    for cell, values in sorted(rows.items()):
        if len(values) < minimum_samples:
            continue
        measured = fmean(values)
        correction = max(-max_change_fraction, min(max_change_fraction, measured / target_lambda - 1))
        if abs(correction) < 0.002:
            continue
        proposals.append({
            "rpm_start": cell[0],
            "rpm_end": cell[0] + 499,
            "load_start": cell[1],
            "load_end": cell[1] + 9,
            "samples": len(values),
            "measured_lambda": round(measured, 5),
            "target_lambda": target_lambda,
            "fuel_change_fraction": round(correction, 5),
            "ignition_change": "locked",
            "reason": "repeatable lambda error in a covered RPM/load cell; verify fuel pressure and sensor calibration before review",
        })

    return {
        "status": "blocked" if blockers else "review_required",
        "profile": "AE86 / AE111 Blacktop / Freedom FC-03",
        "family": "fuel",
        "proposals": [] if blockers else proposals,
        "blockers": sorted(set(blockers)),
        "write_authorization": "never",
        "human_review_required": True,
        "disclaimer": "A bounded diagnostic proposal is not a calibration write or engine-safety authorization.",
    }
