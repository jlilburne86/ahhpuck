#!/usr/bin/env python3
"""Offline, conservative concept model for log-driven tune proposals.

This does not connect to or write an ECU. It accepts normalized samples from a
logger, applies protection gates, scores the requested driving purpose, and
returns bounded fuel proposals plus human-review requirements.
"""
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PURPOSES = {
    "drift": {"sustained_load": 0.35, "throttle_response": 0.30, "thermal_margin": 0.35},
    "grip": {"torque_smoothness": 0.40, "throttle_response": 0.25, "thermal_margin": 0.35},
    "0-100": {"acceleration": 0.45, "torque_smoothness": 0.20, "thermal_margin": 0.35},
    "top-speed": {"high_rpm_load": 0.35, "thermal_margin": 0.35, "torque_smoothness": 0.30},
}


@dataclass(frozen=True)
class Limits:
    max_rpm: float = 7800
    max_coolant_c: float = 105
    max_iat_c: float = 65
    min_voltage_v: float = 12.0
    min_oil_pressure_kpa: float = 180
    max_knock: float = 0.15
    max_load_lambda: float = 1.05
    max_cell_change: float = 0.02


def num(sample: dict[str, Any], key: str, default: float = 0.0) -> float:
    value = sample.get(key, default)
    return float(value) if isinstance(value, (int, float)) else default


def protection(sample: dict[str, Any], limits: Limits) -> list[str]:
    faults = []
    rpm = num(sample, "rpm")
    load = num(sample, "load_kpa")
    if rpm > limits.max_rpm:
        faults.append("rpm_limit")
    if num(sample, "coolant_c", 999) >= limits.max_coolant_c:
        faults.append("coolant_high")
    if num(sample, "iat_c", 999) >= limits.max_iat_c:
        faults.append("iat_high")
    if num(sample, "voltage_v") < limits.min_voltage_v:
        faults.append("system_voltage_low")
    if load >= 80 and num(sample, "oil_pressure_kpa") < limits.min_oil_pressure_kpa:
        faults.append("oil_pressure_low_under_load")
    if num(sample, "knock_level") > limits.max_knock:
        faults.append("knock_detected")
    if load >= 80 and num(sample, "lambda", 0) > limits.max_load_lambda:
        faults.append("lean_under_load")
    return faults


def score(samples: list[dict[str, Any]], purpose: str, limits: Limits) -> dict[str, float]:
    weights = PURPOSES[purpose]
    usable = [s for s in samples if not protection(s, limits)]
    if not usable:
        return {"overall": 0.0, "usable_samples": 0, "safety": 0.0}
    count = len(usable)
    load = sum(min(num(s, "load_kpa") / 100, 1) for s in usable) / count
    throttle = sum(min(num(s, "throttle_pct") / 100, 1) for s in usable) / count
    thermal = sum(max(0, 1 - max(num(s, "coolant_c"), num(s, "iat_c")) / 120) for s in usable) / count
    smooth = max(0.0, 1 - min(sum(num(s, "torque_cv", 1) for s in usable) / count, 1))
    acceleration = min(num(usable[-1], "accel_mps2") / 10, 1)
    high_rpm = sum(min(num(s, "rpm") / limits.max_rpm, 1) for s in usable) / count
    metrics = {
        "sustained_load": load,
        "throttle_response": throttle,
        "thermal_margin": thermal,
        "torque_smoothness": smooth,
        "acceleration": acceleration,
        "high_rpm_load": high_rpm * load,
    }
    overall = sum(weights[key] * metrics[key] for key in weights)
    return {**{key: round(value, 4) for key, value in metrics.items()}, "overall": round(overall, 4), "usable_samples": count, "safety": round(thermal, 4)}


def proposals(samples: list[dict[str, Any]], limits: Limits) -> list[dict[str, Any]]:
    grouped: dict[str, list[dict[str, Any]]] = {}
    for sample in samples:
        if protection(sample, limits):
            continue
        cell = f"{int(num(sample, 'rpm') // 500) * 500}:{int(num(sample, 'load_kpa') // 10) * 10}"
        grouped.setdefault(cell, []).append(sample)
    result = []
    for cell, group in sorted(grouped.items()):
        loaded = [s for s in group if num(s, "load_kpa") >= 80 and num(s, "lambda", 0) > 0]
        if len(loaded) < 3:
            continue
        measured = sum(num(s, "lambda") for s in loaded) / len(loaded)
        target = sum(num(s, "lambda_target", 0.88) for s in loaded) / len(loaded)
        raw = (measured / target) - 1
        correction = max(-limits.max_cell_change, min(limits.max_cell_change, raw))
        result.append({
            "cell": cell,
            "fuel_change_fraction": round(correction, 4),
            "samples": len(loaded),
            "reason": "bounded lambda correction; review fuel pressure and sensor calibration first",
            "ignition_change": "none",
        })
    return result


def quality_gate(data: dict[str, Any], samples: list[dict[str, Any]], result: dict[str, Any]) -> dict[str, Any]:
    """Estimate evidence quality; this is not a claim of engine perfection."""
    total = len(samples)
    safe_fraction = (result["score"]["usable_samples"] / total) if total else 0.0
    evidence = data.get("evidence", {})
    coverage = float(evidence.get("map_coverage", 0.0))
    repeatability = float(evidence.get("repeatability", 0.0))
    sensor_confidence = float(evidence.get("sensor_confidence", 0.0))
    components = {
        "objective": result["score"]["overall"],
        "safety_pass_fraction": safe_fraction,
        "map_coverage": max(0.0, min(coverage, 1.0)),
        "repeatability": max(0.0, min(repeatability, 1.0)),
        "sensor_confidence": max(0.0, min(sensor_confidence, 1.0)),
    }
    # Evidence is intentionally weighted as heavily as performance. A fast
    # result from sparse or suspect data must not be labelled "96% perfect".
    quality = (
        0.25 * components["objective"]
        + 0.20 * components["safety_pass_fraction"]
        + 0.20 * components["map_coverage"]
        + 0.20 * components["repeatability"]
        + 0.15 * components["sensor_confidence"]
    )
    return {
        "quality_percent": round(quality * 100, 2),
        "target_percent": 96.0,
        "target_met": quality >= 0.96 and not result["protection_faults"],
        "components": {key: round(value, 4) for key, value in components.items()},
        "meaning": "evidence-weighted readiness score, not a guarantee of power, reliability, or perfection",
    }


def run(data: dict[str, Any], purpose: str) -> dict[str, Any]:
    limits = Limits(**{key: value for key, value in data.get("limits", {}).items() if key in Limits.__annotations__})
    samples = data.get("samples", [])
    if not isinstance(samples, list):
        raise ValueError("samples must be an array")
    faults = sorted({fault for sample in samples for fault in protection(sample, limits)})
    result = {
        "mode": "offline_concept_test",
        "purpose": purpose,
        "score": score(samples, purpose, limits),
        "protection_faults": faults,
        "fuel_proposals": proposals(samples, limits),
        "write_authorization": "never",
        "required_before_live_use": [
            "verify FC-03 axes, units, checksums, and serial protocol",
            "verify fuel pressure, injector data, wideband calibration, and ignition timing with a timing light",
            "add calibrated oil-pressure, fuel-pressure, coolant, IAT, voltage, and knock logging",
            "validate one bounded change at a time on a dyno or controlled test session",
            "human approval and original-map backup before any ECU write feature exists",
        ],
    }
    result["quality_gate"] = quality_gate(data, samples, result)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="Run an offline safe tune concept test")
    parser.add_argument("input", type=Path)
    parser.add_argument("--purpose", choices=sorted(PURPOSES), required=True)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = run(json.loads(args.input.read_text(encoding="utf-8")), args.purpose)
    args.report.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
