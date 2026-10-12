# AhhPuck engine-intelligence handoff

This is the implementation handoff for the standalone AhhPuck repo. The Wheel
Have site describes the project; this repo contains the engineering workbench.
The current product is read-only: it can inspect files and logs, explain evidence,
and prepare a human-reviewed experiment, but it cannot authorize or perform an
ECU write.

## The seven-process build

| Process | Implemented in this repo | Exit evidence |
| --- | --- | --- |
| 1. Establish truth | `knowledge/source-manifest.json`, `knowledge/rule-cards.json`, `tools/test_knowledge_base.py` | Every rule card cites a registered source and carries an evidence label. |
| 2. Describe the engine | `tools/ahhpuck_intelligence/passport.py` | A versioned passport makes unknown and unverified hardware explicit. |
| 3. Preserve the evidence | `tools/ahhpuck_intelligence/session.py` | Inputs are copied into an immutable session manifest with SHA-256 hashes. |
| 4. Understand the ECU | `tools/fcp_parser.py`, `tools/fcp_inventory.py`, `tools/ahhpuck_intelligence/adapter.py` | Known map structures are parsed; unsupported Freedom identity/version mappings fail closed. |
| 5. Diagnose before changing | `tools/telemetry_stats.py`, `tools/safety_gate.py`, `tools/tuning_iteration.py`, `tools/engine_intelligence.py diagnose` | Incomplete telemetry becomes a blocker, not a guessed correction. |
| 6. Explain and propose | `tools/ai_analysis_service.py`, `tools/ahhpuck_intelligence/explanation.py` | Findings include uncertainty, next measurement, source claims and `write_authorization: never`. |
| 7. Verify and learn | `tools/ahhpuck_intelligence/experiment.py`, `tools/ai_analysis_service.py` | Human approval, controlled external test, post-test review, retain/revert decision and append-only ledger. |

## Working flow

```text
source review → engine passport → baseline/session hash → adapter check
      ↓
telemetry validation → deterministic diagnosis → evidence-linked explanation
      ↓
draft experiment → engineering review → prerequisites verified → human approval
      ↓
external controlled test → post-test review → retain / revert / inconclusive
```

The AI layer is downstream of deterministic calculations and the safety gate. It
can summarize observations and rank the next measurement. It cannot invent map
semantics, promote an anecdote to a verified fact, enlarge an increment, or bypass
a blocker.

## Working commands

From the repository root:

```sh
python3 tools/engine_intelligence.py knowledge-check
python3 tools/engine_intelligence.py diagnose tools/examples/baseline-telemetry.json
python3 tools/engine_intelligence.py capture-bundle /tmp/ahhpuck-session /tmp/ahhpuck-passport.json tools/examples/raw-freedom-capture.json
python3 tools/fcp_parser.py "extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP"
python3 -m unittest discover -s tools -p 'test_*.py'
```

To create a session, first create a passport and then copy the passport plus raw
inputs into a new directory. A session directory must never be reused for another
hardware configuration.

## Explicitly not complete yet

These are gates for a later release, not missing safety shortcuts:

- a verified Freedom live-frame/export adapter for each identity and format version;
- a real captured telemetry corpus with expert labels and regression fixtures;
- bench validation of protocol framing, map scaling, checksums, recovery and rollback;
- a qualified operator and independent reviewer for any future write-enabled trial.

Until those exist, the correct product behavior is read-only inspection and a clear
request for the next measurement or human review.

## What makes the full path possible

The first complete path does not require an ECU write or an invented decoder:

1. Chrome/Edge or the Mac app opens the documented 9600/7E1 link.
2. Every received byte chunk is timestamped, sequenced and exported with the transport settings.
3. The local bundle command copies the raw capture and passport, hashes both, and records that telemetry is not decoded.
4. A verified adapter is the only component allowed to turn frames into canonical channels such as RPM, lambda, load, temperature and pressure.
5. The existing deterministic statistics, safety gate and experiment ledger can then analyse canonical frames.

This makes a real cable session useful immediately, while making the missing
protocol knowledge visible instead of silently turning bytes into unsafe advice.
