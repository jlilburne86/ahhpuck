#!/usr/bin/env python3
"""End-to-end, read-only AhhPuck intelligence workbench.

This CLI connects the existing parser, telemetry, safety gate and local ledger
without granting any component ECU-write authority.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

TOOLS = Path(__file__).parent
sys.path.insert(0, str(TOOLS))

from ahhpuck_intelligence import adapter, artifacts, capture, experiment, explanation, passport, session
from ahhpuck_intelligence.fuel_proposal import propose as propose_fuel
from ahhpuck_intelligence.contracts import write_json
from ahhpuck_intelligence.knowledge import load_registry
from telemetry_stats import load_frames, summarize


def main() -> None:
    parser = argparse.ArgumentParser(description="AhhPuck read-only engineering intelligence workbench")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("passport")
    p.add_argument("output", type=Path)
    p.add_argument("--engine-id", required=True)
    p.add_argument("--ecu", required=True)
    s = sub.add_parser("session")
    s.add_argument("directory", type=Path)
    s.add_argument("passport", type=Path)
    s.add_argument("inputs", nargs="+", type=Path)
    s.add_argument("--purpose", default="baseline")
    a = sub.add_parser("adapter")
    a.add_argument("input", type=Path)
    a.add_argument("--freedom", action="store_true")
    a.add_argument("--ecu-identity")
    a.add_argument("--format-version")
    k = sub.add_parser("knowledge-check")
    k.add_argument("--root", type=Path, default=Path("."))
    d = sub.add_parser("diagnose")
    d.add_argument("telemetry", type=Path)
    d.add_argument("--root", type=Path, default=Path("."))
    d.add_argument("--output", type=Path)
    f = sub.add_parser("propose-fuel")
    f.add_argument("telemetry", type=Path)
    f.add_argument("--evidence", type=Path, required=True)
    f.add_argument("--target-lambda", type=float, default=0.90)
    f.add_argument("--output", type=Path)
    c = sub.add_parser("capture-bundle")
    c.add_argument("output", type=Path)
    c.add_argument("passport", type=Path)
    c.add_argument("raw_capture", type=Path)
    c.add_argument("--baud", type=int, default=9600)
    r = sub.add_parser("artifact")
    r.add_argument("kind", choices=("tune", "log"))
    r.add_argument("input", type=Path)
    r.add_argument("output", type=Path)
    r.add_argument("--metadata", type=Path)
    e = sub.add_parser("experiment")
    e.add_argument("output", type=Path)
    e.add_argument("--id", required=True)
    e.add_argument("--proposal", required=True)
    args = parser.parse_args()

    if args.command == "passport":
        result = passport.create(args.engine_id, {"identity": args.ecu, "status": "declared_unverified"}, {}, "diagnostic")
        passport.save(args.output, result)
    elif args.command == "session":
        result = session.create(args.directory, args.passport, args.inputs, args.purpose)
    elif args.command == "adapter":
        result = adapter.freedom_export(args.input, ecu_identity=args.ecu_identity, format_version=args.format_version) if args.freedom else adapter.load_json(args.input)
        result = result.as_dict()
    elif args.command == "knowledge-check":
        manifest, cards = load_registry(args.root)
        result = {"manifest_version": manifest["manifest_version"], "rule_cards_version": cards["rule_cards_version"], "sources": len(manifest["sources"]), "cards": len(cards["cards"]), "status": "valid"}
    elif args.command == "diagnose":
        frames = load_frames(args.telemetry)
        summary = summarize(frames)
        findings = []
        if not summary["telemetry"]["complete"]:
            findings.append({"severity": "critical", "code": "telemetry_incomplete", "message": summary["telemetry"]["reason"]})
        if summary["frame_count"] == 0:
            findings.append({"severity": "critical", "code": "no_samples", "message": "No samples were supplied."})
        if frames and not any("rpm" in (frame.get("decoded", frame) if isinstance(frame, dict) else {}) for frame in frames):
            findings.append({"severity": "critical", "code": "decoder_required", "message": "Raw serial frames are present, but no verified Freedom decoder has produced canonical telemetry."})
        if summary["map_coverage"] < 0.6:
            findings.append({"severity": "warning", "code": "sparse_coverage", "message": "Insufficient repeated RPM/load cell coverage for a calibration proposal."})
        result = {"summary": summary, "explanation": explanation.build(args.root, "Telemetry baseline inspection", findings, ["ecu.learning.state.known"]), "proposal_status": "blocked" if findings else "review_required", "write_authorization": "never"}
        if args.output:
            write_json(args.output, result)
            return
    elif args.command == "propose-fuel":
        frames = load_frames(args.telemetry)
        evidence = json.loads(args.evidence.read_text(encoding="utf-8"))
        result = propose_fuel(frames, evidence=evidence, target_lambda=args.target_lambda)
        if args.output:
            write_json(args.output, result)
            return
    elif args.command == "capture-bundle":
        result = capture.bundle(args.output, args.passport, args.raw_capture, baud=args.baud)
        print(json.dumps(result, indent=2, sort_keys=True))
        return
    elif args.command == "artifact":
        metadata = json.loads(args.metadata.read_text(encoding="utf-8")) if args.metadata else {}
        result = artifacts.create_tune(args.input, args.output, metadata) if args.kind == "tune" else artifacts.create_log(args.input, args.output, metadata)
        print(json.dumps(result, indent=2, sort_keys=True))
        return
    else:
        result = experiment.new(args.id, json.loads(args.proposal))
    write_json(args.output, result) if hasattr(args, "output") and args.output else print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
