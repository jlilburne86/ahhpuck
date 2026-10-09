#!/usr/bin/env python3
"""Local, safety-first analysis service for tuning iteration reports.

This prototype deliberately uses a deterministic local analyst. A future on-device
LLM can implement the same interface, but it must not replace the safety gate or
gain direct ECU-write authority.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sqlite3
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA = """
PRAGMA journal_mode=WAL;
CREATE TABLE IF NOT EXISTS sessions (
    session_id TEXT PRIMARY KEY,
    created_at TEXT NOT NULL,
    vehicle_profile TEXT NOT NULL,
    mode TEXT NOT NULL,
    immutable_baseline_hash TEXT
);
CREATE TABLE IF NOT EXISTS iterations (
    iteration_id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(session_id),
    iteration INTEGER NOT NULL,
    recorded_at TEXT NOT NULL,
    source_hash TEXT NOT NULL,
    decision TEXT NOT NULL,
    reason TEXT NOT NULL,
    write_authorization TEXT NOT NULL,
    report_json TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS findings (
    finding_id INTEGER PRIMARY KEY AUTOINCREMENT,
    iteration_id INTEGER NOT NULL REFERENCES iterations(iteration_id),
    severity TEXT NOT NULL,
    code TEXT NOT NULL,
    explanation TEXT NOT NULL,
    suggested_check TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS learning_ledger (
    ledger_id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL REFERENCES sessions(session_id),
    iteration_id INTEGER NOT NULL REFERENCES iterations(iteration_id),
    observation TEXT NOT NULL,
    evidence TEXT NOT NULL,
    confidence REAL NOT NULL,
    reusable INTEGER NOT NULL DEFAULT 0
);
"""


CAUSE_CHECKS = {
    "knock_detected": "Verify knock sensor mounting, noise rejection, ignition timing, mixture, fuel quality, and engine condition before another load test.",
    "lean_under_load": "Verify fuel pressure under load, injector data, pump/filter capacity, lambda calibration, and intake leaks.",
    "coolant_high": "Verify coolant level, bleeding, radiator/airflow, thermostat, fan control, mixture, and timing.",
    "iat_high": "Allow heat soak to normalize and inspect intake routing, shielding, and ambient conditions.",
    "oil_pressure_low_under_load": "Stop testing and verify oil level, pressure with an independent gauge, pickup/baffling, oil temperature, and bearings.",
    "system_voltage_low": "Verify battery, alternator output, grounds, ECU supply, wiring, and electrical loads.",
    "rpm_limit": "Verify trigger configuration, RPM scaling, rev limits, and mechanical engine speed limits.",
    "telemetry_timeout": "Inspect bridge power, cable, serial framing, sequence numbers, and application watchdog behavior.",
    "telemetry_incomplete": "Discard this run for learning and inspect dropped, stale, duplicated, or out-of-order frames.",
    "sensor_plausibility": "Verify sensor calibration, wiring, grounding, units, and independent reference measurements.",
    "not_repeatable": "Repeat the same test with controlled temperature, fuel pressure, driver input, gear, and RPM/load coverage.",
    "sparse_coverage": "Collect more repeated samples in the affected RPM/load cells before changing the calibration.",
    "performance_regression": "Return to the last accepted candidate and check test variation, hardware changes, and step size.",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def stable_json(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def digest(value: Any) -> str:
    return hashlib.sha256(stable_json(value).encode("utf-8")).hexdigest()


def local_analysis(report: dict[str, Any]) -> dict[str, Any]:
    """Create an explainable analysis without making a calibration decision."""
    decision = report.get("decision", "unknown")
    issues = report.get("issues", [])
    findings = []
    for issue in issues:
        code = issue.get("code", "unknown")
        findings.append({
            "severity": issue.get("severity", "warning"),
            "code": code,
            "explanation": issue.get("likely_issue", "unclassified issue"),
            "suggested_check": CAUSE_CHECKS.get(code, "Inspect the raw log and verify the relevant sensor or mechanical system."),
        })

    if decision == "accept_candidate_and_prepare_smaller_next_step":
        observation = "The candidate improved the objective with clean repeatable evidence. The next experiment must remain bounded and smaller."
        evidence = "decision plus absence of critical findings"
        confidence = 0.75 if not issues else 0.6
        reusable = 1 if not issues else 0
    elif decision == "rollback_and_abort":
        observation = "A critical protection or data-integrity issue occurred. Do not learn a calibration change from this run."
        evidence = ", ".join(item["code"] for item in findings) or "critical decision"
        confidence = 0.95
        reusable = 0
    else:
        observation = "The result is not strong enough to accept. Preserve the evidence and repeat or redesign the test."
        evidence = ", ".join(item["code"] for item in findings) or "non-improving or incomplete result"
        confidence = 0.85
        reusable = 0

    return {
        "analysis_mode": "deterministic_local",
        "summary": observation,
        "evidence": evidence,
        "confidence": confidence,
        "reusable_learning": bool(reusable),
        "findings": findings,
        "guardrails": {
            "safety_gate_is_authoritative": True,
            "ecu_write_authorized": False,
            "llm_direct_control": False,
        },
    }


def record(db_path: Path, report: dict[str, Any], profile: str, session_id: str | None = None) -> dict[str, Any]:
    session_id = session_id or str(uuid.uuid4())
    analysis = local_analysis(report)
    source_hash = digest(report)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(db_path) as db:
        db.executescript(SCHEMA)
        db.execute(
            "INSERT OR IGNORE INTO sessions(session_id, created_at, vehicle_profile, mode) VALUES (?, ?, ?, ?)",
            (session_id, now(), profile, "local_read_only"),
        )
        cursor = db.execute(
            """INSERT INTO iterations(session_id, iteration, recorded_at, source_hash, decision,
               reason, write_authorization, report_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (session_id, report.get("iteration", 0), now(), source_hash,
             report.get("decision", "unknown"), report.get("reason", ""),
             "never", json.dumps(report, sort_keys=True)),
        )
        iteration_id = cursor.lastrowid
        for finding in analysis["findings"]:
            db.execute(
                "INSERT INTO findings(iteration_id, severity, code, explanation, suggested_check) VALUES (?, ?, ?, ?, ?)",
                (iteration_id, finding["severity"], finding["code"], finding["explanation"], finding["suggested_check"]),
            )
        db.execute(
            "INSERT INTO learning_ledger(session_id, iteration_id, observation, evidence, confidence, reusable) VALUES (?, ?, ?, ?, ?, ?)",
            (session_id, iteration_id, analysis["summary"], analysis["evidence"], analysis["confidence"], int(analysis["reusable_learning"])),
        )
    return {"session_id": session_id, "iteration_id": iteration_id, "source_hash": source_hash, **analysis}


def main() -> None:
    parser = argparse.ArgumentParser(description="Record and explain one safe tuning iteration locally")
    parser.add_argument("report", type=Path, help="tuning_iteration.py JSON report")
    parser.add_argument("--db", type=Path, default=Path("data/tuning-ledger.sqlite3"))
    parser.add_argument("--profile", default="AE86 / AE111 Blacktop / Freedom FC-03")
    parser.add_argument("--session-id")
    args = parser.parse_args()
    result = record(args.db, json.loads(args.report.read_text(encoding="utf-8")), args.profile, args.session_id)
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
