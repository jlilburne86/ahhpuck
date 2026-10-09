#!/usr/bin/env python3
"""Deterministic local telemetry statistics for tuning experiments.

Input may be a JSON array, an object containing ``frames``, or JSONL with one
frame per line. This module never changes a tune or talks to an ECU.
"""
from __future__ import annotations

import argparse
import json
import math
import statistics
from pathlib import Path
from typing import Any, Iterable


DEFAULT_TARGET_LAMBDA = 0.90
DEFAULT_RPM_BINS = 10
DEFAULT_LOAD_BINS = 10


def load_frames(path: Path) -> list[dict[str, Any]]:
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return []
    try:
        value = json.loads(text)
        if isinstance(value, dict):
            value = value.get("frames", [])
        if isinstance(value, list):
            return [frame for frame in value if isinstance(frame, dict)]
    except json.JSONDecodeError:
        pass
    return [json.loads(line) for line in text.splitlines() if line.strip()]


def decoded(frame: dict[str, Any]) -> dict[str, Any]:
    value = frame.get("decoded", frame)
    return value if isinstance(value, dict) else {}


def numeric(frames: Iterable[dict[str, Any]], key: str) -> list[float]:
    values = []
    for frame in frames:
        value = decoded(frame).get(key)
        if isinstance(value, (int, float)) and math.isfinite(float(value)):
            values.append(float(value))
    return values


def stats(values: list[float]) -> dict[str, float | int | None]:
    if not values:
        return {"count": 0, "mean": None, "stdev": None, "min": None, "max": None}
    return {
        "count": len(values),
        "mean": round(statistics.fmean(values), 6),
        "stdev": round(statistics.stdev(values), 6) if len(values) > 1 else 0.0,
        "min": round(min(values), 6),
        "max": round(max(values), 6),
    }


def bin_index(value: float, maximum: float, count: int) -> int:
    return max(0, min(count - 1, int((value / maximum) * count)))


def cell_coverage(frames: list[dict[str, Any]], rpm_bins: int, load_bins: int) -> float:
    cells: set[tuple[int, int]] = set()
    for frame in frames:
        data = decoded(frame)
        rpm, load = data.get("rpm"), data.get("load")
        if isinstance(rpm, (int, float)) and isinstance(load, (int, float)):
            cells.add((bin_index(float(rpm), 9000, rpm_bins), bin_index(float(load), 100, load_bins)))
    return round(len(cells) / (rpm_bins * load_bins), 4)


def telemetry_completeness(frames: list[dict[str, Any]]) -> dict[str, Any]:
    sequences = [frame.get("sequence") for frame in frames if isinstance(frame.get("sequence"), int)]
    # Fail closed: completeness can only be proven from sequence numbers on every frame.
    # Previously fewer than two sequence numbers (including an empty log) counted as complete.
    if len(frames) < 2 or len(sequences) != len(frames):
        return {"complete": False, "score": 0.0, "dropped_frames": 0, "out_of_order": 0,
                "reason": "too few frames or missing sequence numbers; completeness not provable"}
    expected = max(sequences) - min(sequences) + 1
    dropped = max(0, expected - len(set(sequences)))
    out_of_order = sum(1 for left, right in zip(sequences, sequences[1:]) if right <= left)
    score = max(0.0, min(1.0, (len(sequences) - dropped) / expected))
    return {"complete": dropped == 0 and out_of_order == 0, "score": round(score, 4), "dropped_frames": dropped, "out_of_order": out_of_order}


def per_cell_mean(frames: list[dict[str, Any]], key: str) -> dict[tuple[int, int], float]:
    buckets: dict[tuple[int, int], list[float]] = {}
    for frame in frames:
        data = decoded(frame)
        rpm, load, value = data.get("rpm"), data.get("load"), data.get(key)
        if all(isinstance(item, (int, float)) for item in (rpm, load, value)):
            cell = (bin_index(float(rpm), 9000, DEFAULT_RPM_BINS), bin_index(float(load), 100, DEFAULT_LOAD_BINS))
            buckets.setdefault(cell, []).append(float(value))
    return {cell: statistics.fmean(values) for cell, values in buckets.items()}


def repeatability(run_a: list[dict[str, Any]], run_b: list[dict[str, Any]], key: str = "lambda", tolerance: float = 0.03) -> dict[str, Any]:
    a, b = per_cell_mean(run_a, key), per_cell_mean(run_b, key)
    overlap = sorted(set(a) & set(b))
    differences = [abs(a[cell] - b[cell]) for cell in overlap]
    mean_difference = statistics.fmean(differences) if differences else None
    return {
        "repeatable": bool(overlap) and mean_difference is not None and mean_difference <= tolerance,
        "overlap_cells": len(overlap),
        "mean_absolute_difference": round(mean_difference, 6) if mean_difference is not None else None,
        "tolerance": tolerance,
    }


def summarize(frames: list[dict[str, Any]], target_lambda: float = DEFAULT_TARGET_LAMBDA) -> dict[str, Any]:
    lambdas = numeric(frames, "lambda")
    lambda_errors = [abs(value - target_lambda) for value in lambdas]
    return {
        "frame_count": len(frames),
        "telemetry": telemetry_completeness(frames),
        "map_coverage": cell_coverage(frames, DEFAULT_RPM_BINS, DEFAULT_LOAD_BINS),
        "lambda": stats(lambdas),
        "lambda_error": stats(lambda_errors),
        "rpm": stats(numeric(frames, "rpm")),
        "load": stats(numeric(frames, "load")),
        "coolant_c": stats(numeric(frames, "coolant_c")),
        "iat_c": stats(numeric(frames, "iat_c")),
        "oil_pressure": stats(numeric(frames, "oil_pressure")),
        "fuel_pressure": stats(numeric(frames, "fuel_pressure")),
        "battery_v": stats(numeric(frames, "battery_v")),
        "knock_events": sum(1 for frame in frames if decoded(frame).get("knock") is True),
    }


def compare(
    baseline: list[dict[str, Any]],
    candidate: list[dict[str, Any]],
    target_lambda: float,
    candidate_repeat: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    base, cand = summarize(baseline, target_lambda), summarize(candidate, target_lambda)
    base_error, cand_error = base["lambda_error"]["mean"], cand["lambda_error"]["mean"]
    improvement = None
    if isinstance(base_error, (int, float)) and base_error > 0 and isinstance(cand_error, (int, float)):
        improvement = round((base_error - cand_error) / base_error, 4)
    repeatability_result = (
        repeatability(candidate, candidate_repeat)
        if candidate_repeat is not None
        else {"repeatable": None, "status": "not_assessed", "reason": "provide a second candidate run"}
    )
    return {
        "baseline": base,
        "candidate": cand,
        "lambda_error_improvement": improvement,
        "repeatability": repeatability_result,
        "candidate_clean": (
            candidate != []
            and cand["telemetry"]["complete"]
            and cand["knock_events"] == 0
            and isinstance(improvement, (int, float))
            and improvement > 0
            and repeatability_result["repeatable"] is True
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare two telemetry captures locally")
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--candidate-repeat", type=Path, help="second candidate run used to prove repeatability")
    parser.add_argument("--target-lambda", type=float, default=DEFAULT_TARGET_LAMBDA)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    paths = [args.baseline, args.candidate] + ([args.candidate_repeat] if args.candidate_repeat else [])
    missing = [str(path) for path in paths if not path.exists()]
    if missing:
        parser.error("telemetry file not found: " + ", ".join(missing) + ". Use real captures or the examples in tools/examples/.")
    repeat_frames = load_frames(args.candidate_repeat) if args.candidate_repeat else None
    result = compare(load_frames(args.baseline), load_frames(args.candidate), args.target_lambda, repeat_frames)
    serialized = json.dumps(result, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(serialized, encoding="utf-8")
    print(serialized, end="")


if __name__ == "__main__":
    main()
