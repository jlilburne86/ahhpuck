# Closed-loop tuning workflow

## Purpose

This is the operating flow for the AE86 chassis with AE111 4A-GE 20V Blacktop and the Freedom FC-03/FCSS environment.

The system improves a calibration through small, evidence-based iterations. It does not chase a target number in one jump. Every change is treated as an experiment with a known baseline, a controlled test, a complete log, and a reversible decision.

The workflow is suitable for fuel, ignition, VVT, idle, and other calibration families only after the relevant sensors, map semantics, and ECU identity have been verified. Fuel-only learning is the first planned calibration family.

## Core loop

```text
Vehicle profile
      ↓
Verified baseline + immutable backup
      ↓
Bounded proposal
      ↓
Human approval
      ↓
Controlled test run
      ↓
Live telemetry + raw capture
      ↓
Data integrity and safety assessment
      ├── Critical fault → protect / stop / rollback / investigate
      ├── Uncertain result → rollback / repeat test / review
      └── Clean improvement → accept candidate / halve next step
```

The loop never treats a missing or unreliable measurement as proof that a calibration change worked.

## State machine

### 1. Profile

Record the complete test configuration before selecting a tune:

- chassis and ECU identity;
- engine family and 20V variant;
- sequential or batch injection;
- direct ignition, distributor, or wasted spark;
- load strategy and sensor calibration;
- VVT configuration;
- injectors, fuel pressure, fuel type, compression, cams, ITBs, intake, exhaust, and forced induction;
- purpose: street, grip, drift, 0–100, or top speed;
- environmental conditions and test restrictions.

An incomplete profile blocks automated proposal generation.

### 2. Baseline

Before any experiment:

1. identify the exact Freedom unit and option set;
2. capture an ECU readback where supported;
3. preserve the original file and raw serial capture;
4. calculate file hashes;
5. verify wideband AFR/lambda, RPM, coolant, intake temperature, load, battery voltage, fuel pressure, and knock channels;
6. run the same controlled condition at least twice when practical;
7. mark the baseline as immutable.

The baseline is the comparison reference, not necessarily a claim that the engine is correctly tuned.

### 3. Proposal

The optimizer may propose one calibration family at a time. It must include:

- affected RPM/load cells;
- change direction and magnitude;
- expected effect;
- reason and evidence;
- sensor prerequisites;
- stop limits;
- rollback source;
- confidence and uncertainty;
- the exact test condition required.

The first change is deliberately small. After a successful iteration, the next change is reduced, normally by half, and capped by the safety policy.

The AI/LLM can summarize evidence, detect patterns, and suggest a bounded experiment. It cannot invent map meaning, bypass limits, authorize a write, or declare an engine safe.

### 4. Approval and application boundary

The operator must approve the proposal after reviewing the profile, baseline, expected effect, and stop criteria.

The current product implementation generates a write plan only. ECU writes remain disabled until all of the following are independently proven:

- protocol framing and command semantics;
- correct map addresses and scaling;
- ECU identity and option compatibility;
- read-after-write verification;
- power-loss and communication-failure recovery;
- immutable backup and rollback procedure;
- bench and vehicle tests with an experienced operator.

No browser or phone disconnect, timeout, or software “failsafe” can guarantee a safe engine state. Mechanical and ECU protection must remain authoritative.

### 5. Controlled test run

Use a repeatable test condition. Hold constant as many variables as possible:

- gear and speed range;
- throttle/load target;
- starting coolant and intake temperature;
- fuel and fuel pressure;
- test route or dyno condition;
- driver input;
- sensor and logging configuration.

Abort immediately for knock, lean operation under load, excessive coolant or intake temperature, low oil pressure, low system voltage, trigger/RPM anomaly, telemetry loss, or sensor implausibility.

### 6. Telemetry and capture

Capture both the raw transport stream and normalized frames. Each frame should carry:

```json
{
  "timestamp": "monotonic-or-utc-time",
  "sequence": 123,
  "direction": "rx",
  "raw_bytes": [0, 1, 2],
  "decoded": {
    "rpm": 0,
    "load": 0,
    "lambda": 0,
    "coolant_c": 0,
    "iat_c": 0,
    "battery_v": 0
  }
}
```

The assessor must reject data with dropped, stale, duplicated, out-of-order, or implausible frames. Raw captures are retained even when normalized decoding fails.

### 7. Assessment

The assessor compares baseline and candidate results using:

- safety events;
- telemetry completeness;
- sensor plausibility;
- repeatability;
- RPM/load cell coverage;
- target error and stability;
- drivability or performance objective;
- environmental differences;
- change magnitude.

The assessment has three outcomes.

#### Accept candidate and prepare a smaller next step

Conditions:

- objective improved;
- no critical protection event;
- telemetry complete;
- sensors plausible;
- test repeatable;
- map coverage sufficient.

Action: retain the candidate as the new working reference and return a smaller bounded proposal.

#### Roll back and review

Conditions:

- result is not repeatable;
- objective regressed;
- cell coverage is sparse;
- test conditions changed;
- data quality is uncertain.

Action: restore the last accepted calibration in the controlled workflow, preserve all evidence, and repeat or redesign the test. Do not “average away” uncertainty.

#### Roll back and abort

Conditions:

- knock or possible detonation;
- lean operation under load;
- excessive coolant or intake temperature;
- low oil pressure;
- low voltage;
- RPM/trigger anomaly;
- telemetry timeout or corrupt stream;
- implausible safety-critical sensor.

Action: stop the run, enter protection state, preserve the raw log, investigate mechanical/electrical/sensor causes, and require a human release before any further test.

## Issue diagnosis matrix

| Alert | Possible causes | Immediate response |
|---|---|---|
| Knock detected | Detonation, excessive timing, mixture, heat, false-knock, mechanical noise | Abort load, reduce risk, verify knock sensing and engine condition |
| Lean under load | Fuel pressure, injector data, pump/filter, air leak, lambda calibration | Abort load, verify fuel system and sensors |
| Coolant high | Cooling capacity, airflow, heat soak, mixture, timing, excessive load | Abort load, cool engine, inspect cooling system |
| IAT high | Heat soak, intake routing, ambient temperature, charge cooling | Reduce load and repeat only after conditions normalize |
| Oil pressure low | Oil level, pickup/baffling, oil temperature, bearings, sensor fault | Stop engine/load immediately and inspect |
| System voltage low | Alternator, battery, grounds, wiring, electrical load | Stop write/test activity and verify charging system |
| RPM limit/trigger anomaly | Rev limit, trigger setup, scaling, signal loss | Abort and verify trigger and mechanical limits |
| Telemetry timeout | USB/serial bridge, cable, framing, power, watchdog | Stop learning; preserve raw stream and inspect transport |
| Sensor implausible | Calibration, wiring, grounding, unit conversion, failed sensor | Block proposal and correct measurement chain |

## Logging requirements

Each iteration creates a session directory containing:

```text
session/
  profile.json
  baseline.fcp-or-readback
  baseline.sha256
  candidate-plan.json
  raw-serial.bin
  normalized-telemetry.jsonl
  operator-notes.md
  assessment.json
  rollback-plan.json
```

The assessment is append-only. Never overwrite the baseline or reuse a session for a different hardware configuration.

## AI progress loop

```text
Observe → validate → diagnose → propose → approve → test → evaluate → learn
```

“Learn” means updating the evidence ledger, confidence, and next bounded experiment. It does not mean allowing the model to silently alter the ECU or expand limits. The AI should report what it knows, what it cannot determine, and which additional measurement would reduce uncertainty.

## Product release gates

### Gate A — Offline

- parse and compare files;
- run the safety gate;
- assess synthetic and imported logs;
- produce rollback plans;
- no ECU writes.

### Gate B — Read-only live telemetry

- identify the actual unit;
- capture raw serial data;
- decode only verified fields;
- detect dropped and stale frames;
- display alerts;
- export a complete session;
- no ECU writes.

### Gate C — Bench write validation

- only after protocol and map semantics are verified;
- backup and hash before every change;
- explicit human confirmation;
- read-after-write verification;
- power-loss and disconnect recovery;
- no engine load testing.

### Gate D — Supervised vehicle testing

- experienced operator present;
- independent wideband and safety instrumentation;
- dyno or controlled test environment where appropriate;
- incremental changes only;
- abort criteria enforced;
- manual rollback available.

### Gate E — Production assistance

Only after repeated, independently reviewed evidence may the product assist with a verified calibration family. “96% confidence” is a readiness score for the evidence and process, never a guarantee of engine safety or optimum power.

## Current implementation mapping

- `tools/tuning_iteration.py` implements the decision logic.
- `tools/safety_gate.py` blocks unsafe candidate experiments.
- `tools/fcp_adapter_report.py` keeps unknown map semantics in comparison-only mode.
- `web-ui/` captures raw serial data through Web Serial and remains read-only.
- `ios-app/` provides a native transport/dashboard boundary but does not claim a verified direct ECU protocol.

The next engineering step is to feed a real, operator-captured FCSS session into the read-only decoder and prove framing, timing, field semantics, and disconnect behavior before implementing any write command.
