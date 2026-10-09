# Freedom ECU tuning assistant: product design overview

## 1. Product summary

The Freedom ECU tuning assistant is an iOS-first, local-first application for vehicles using a Freedom FC-03/FCSS ECU, initially an AE86 chassis with an AE111 4A-GE 20V Blacktop engine.

The app connects to the ECU in read-only mode, captures engine telemetry, combines it with phone-based vehicle dynamics, assesses controlled experiments, and recommends the next smallest evidence-based action.

The product is an engineering and decision-support tool. It is not an autonomous tuner and it does not claim that a calibration is perfect or safe merely because an AI model recommends it.

## 2. Product promise

The app answers four questions after every controlled run:

1. What happened to the engine?
2. Was the data complete and repeatable?
3. What could have caused the result or fault?
4. What is the safest next action?

The permitted answer is always one of:

```text
Accept candidate and prepare a smaller next step
Repeat the experiment
Rollback and investigate
Stop and abort
```

## 3. Primary user

The primary user is an AE86 owner/operator running an AE111 Blacktop 4A-GE with a Freedom ECU. They may understand the car well but need the application to explain calibration evidence clearly and prevent accidental escalation.

Secondary users are tuners, engine builders, and engineers who need raw data, dense graphs, repeatability, cell coverage, hashes, and exportable evidence.

## 4. Operating principles

- Engine telemetry is the core evidence.
- Phone sensors add vehicle context; they do not replace oil pressure, fuel pressure, lambda, or knock instrumentation.
- Statistics and safety rules are deterministic.
- AI explains evidence and proposes bounded experiments; it does not control the ECU.
- Every candidate is compared against an immutable baseline and, where possible, a repeat run.
- Missing evidence produces uncertainty, not a positive result.
- Critical faults cannot be overridden in the UI.
- All current ECU access is read-only.
- Every session must be reproducible and exportable.

## 5. User journey

```text
Create vehicle profile
        ↓
Connect and identify transport
        ↓
Run preflight checks
        ↓
Capture immutable baseline
        ↓
Choose tuning objective
        ↓
Create bounded experiment proposal
        ↓
Review concerns and rollback plan
        ↓
Approve supervised test
        ↓
Capture candidate and repeat runs
        ↓
Assess engine and vehicle data
        ↓
Accept smaller step, repeat, rollback, or abort
        ↓
Store learning ledger and export evidence
```

## 6. Application surfaces

### 6.1 Vehicle profile

Captures:

- chassis: AE86, AE101, AE111, or other;
- engine: 4A-GE 20V Blacktop, Silvertop, 16V, 4A-GZE, or other;
- ECU label, option configuration, firmware evidence, and connector information;
- load strategy: MAP/D-Jetronic, Alpha-N/TPS, blended, or MAF;
- injection mode: sequential, batch, or unknown;
- ignition: direct ignition, distributor, wasted spark, or unknown;
- VVT configuration;
- injectors, fuel pressure, fuel type, compression, cams, ITBs, intake, exhaust, and forced induction;
- selected objective: grip, drift, acceleration, top speed, drivability, economy, or reliability.

Unknown fields remain explicitly unknown and can block proposals.

### 6.2 Connection and identity

Shows:

- selected serial/USB transport;
- baud rate and framing settings;
- connection state;
- ECU identity state: verified, inferred, or unknown;
- raw frame count;
- dropped, stale, duplicated, or out-of-order frames;
- last receive time;
- read-only/write-lock state.

The first transport target is the Freedom serial connection. Protocol decoding is separate from transport capture so unknown bytes can still be preserved for analysis.

### 6.3 Live dashboard

Engine-first dashboard values:

- RPM;
- load/MAP/TPS;
- lambda/AFR and target;
- coolant temperature;
- intake temperature;
- oil pressure;
- fuel pressure;
- battery voltage;
- ignition timing;
- injector duty cycle;
- VVT position;
- knock status;
- telemetry health.

Secondary vehicle values:

- speed;
- longitudinal acceleration;
- lateral acceleration;
- yaw rate;
- pitch and roll;
- braking event;
- GPS accuracy;
- motion-sensor calibration state.

Live alerts are deterministic and must continue to work if AI is unavailable.

### 6.4 Run capture

The operator selects:

- baseline, candidate, or repeat run;
- tuning objective;
- test gear and RPM/load range;
- route, dyno, or track context;
- fuel and environmental conditions;
- driver/operator notes.

The app records a monotonic timestamp for synchronization and an optional wall-clock timestamp for review.

### 6.5 Experiment review

The review screen contains three steps:

```text
1. Load runs
2. Review assessment
3. Approve or rollback
```

It displays:

- baseline, candidate, and repeat file names/hashes;
- lambda error and improvement;
- repeatability;
- telemetry completeness;
- RPM/load coverage;
- knock and protection events;
- sensor ranges and plausibility;
- engine graph;
- vehicle-dynamics graph;
- warnings and likely causes;
- recommended next action;
- maximum permitted next increment.

### 6.6 Approval

The operator must confirm:

- correct vehicle and ECU profile;
- baseline backup and rollback path;
- changed experiment and expected effect;
- displayed warnings;
- supervised test conditions;
- stop criteria.

Approval creates an experiment record. It does not authorize ECU writing in the current release.

## 7. Data collected

### 7.1 ECU telemetry

```text
timestamp
sequence
raw frame bytes
RPM
load / MAP / TPS
lambda / AFR
coolant temperature
intake temperature
oil pressure
fuel pressure
battery voltage
ignition timing
injector duty cycle
VVT position
knock state
ECU corrections and feedback flags where verified
```

Only fields with verified decoding are used for automated assessment. Unknown fields remain in the raw capture and are labelled unknown.

### 7.2 Phone and vehicle dynamics

```text
accelerometer
gyroscope
device attitude
magnetometer when available
GPS speed and course
location accuracy
altitude when available
derived longitudinal acceleration
derived lateral acceleration
derived yaw rate
derived braking event
derived cornering event
```

Phone data must include device orientation and calibration quality. A phone mounted loosely, held by hand, or placed in an unknown orientation produces low-confidence dynamics data.

### 7.3 Session metadata

```text
session ID
vehicle profile ID
ECU identity evidence
software/app version
transport settings
baseline hash
candidate hash
operator ID or local profile name
objective
fuel and environmental conditions
route/dyno context
operator notes
approval record
assessment record
rollback record
```

## 8. Normalized telemetry model

The transport decoder must emit a common model so the statistics engine is independent of Freedom-specific framing:

```json
{
  "timestamp": 1728390000.241,
  "sequence": 1842,
  "source": "freedom_fc03",
  "engine": {
    "rpm": 3820,
    "load": 54.2,
    "lambda": 0.914,
    "coolant_c": 86.1,
    "iat_c": 38.4,
    "oil_pressure": 3.8,
    "fuel_pressure": 3.0,
    "battery_v": 13.8,
    "ignition_deg": 24.0,
    "knock": false
  },
  "vehicle": {
    "speed_kmh": 64.2,
    "longitudinal_g": 0.42,
    "lateral_g": 0.18,
    "yaw_rate": 0.07,
    "braking_event": false
  },
  "quality": {
    "ecu_frame_valid": true,
    "motion_calibrated": true,
    "gps_accuracy_m": 2.4
  }
}
```

## 9. Processing pipeline

```text
Raw ECU bytes + phone sensors
        ↓
Transport capture
        ↓
Frame validation and timestamp alignment
        ↓
Protocol decoder
        ↓
Normalized telemetry
        ↓
Data-quality checks
        ↓
Deterministic statistics
        ↓
Safety gate
        ↓
Optional local AI explanation
        ↓
Operator review and decision
```

### Deterministic statistics

The statistics engine calculates:

- mean, range, and standard deviation;
- lambda/AFR target error;
- baseline-to-candidate improvement;
- candidate repeatability;
- RPM/load cell coverage;
- frame completeness and sequence gaps;
- sensor plausibility;
- knock-event count;
- coolant, intake, oil pressure, fuel pressure, and voltage ranges;
- acceleration, braking, and cornering consistency.

The current local implementation is `tools/telemetry_stats.py`.

### AI assistance

The optional local model receives structured statistics and evidence, not unrestricted ECU access. It can:

- explain why an assessment passed or failed;
- summarize likely causes;
- identify missing evidence;
- explain the recommended next step;
- answer questions about the session;
- translate technical findings into owner-friendly language.

It cannot:

- decode unknown map semantics by guessing;
- override critical faults;
- increase the permitted increment;
- authorize ECU writes;
- claim the engine is safe or optimal;
- silently change the decision.

## 10. Assessment decisions

### Accept candidate and prepare a smaller next step

Requires:

- candidate objective improved;
- candidate and repeat telemetry complete;
- repeat result within tolerance;
- no critical safety event;
- sensor plausibility passed;
- adequate cell coverage.

Action: retain the candidate as the working reference and suggest a smaller bounded increment.

### Repeat experiment

Used when:

- conditions changed;
- repeatability is not proven;
- cell coverage is sparse;
- telemetry quality is uncertain;
- improvement is too small or ambiguous.

Action: no new calibration change. Repeat the same test condition.

### Rollback and investigate

Used for regression, suspicious sensor behaviour, mechanical uncertainty, or an unsupported hardware profile.

Action: preserve evidence, return to the last accepted state in the controlled workflow, and investigate before another experiment.

### Stop and abort

Used for knock, lean operation under load, overheating, low oil pressure, low voltage, trigger/RPM anomaly, telemetry loss, or implausible safety-critical sensors.

Action: stop the test immediately and lock further tuning until a human investigation is recorded.

## 11. Storage and privacy

All initial processing is local-first.

Recommended session layout:

```text
session/
  profile.json
  baseline.raw
  baseline.jsonl
  candidate.raw
  candidate.jsonl
  candidate-repeat.jsonl
  hashes.json
  preflight.json
  experiment-plan.json
  assessment.json
  approval.json
  operator-notes.md
```

The iOS implementation should use a local database for session metadata and file-backed storage for raw captures. Export must create a portable session bundle without requiring a cloud account.

## 12. Safety and permissions

### Current release

- ECU connection: read-only capture only;
- map reads: only after protocol and field semantics are verified;
- map writes: disabled;
- AI: explanation and bounded suggestions only;
- phone dynamics: contextual evidence only;
- live protection: deterministic app alerts plus the vehicle’s own ECU/mechanical protections;
- human supervision: required for every vehicle test.

### Future write gate

ECU writes require separate approval after:

1. exact ECU identity verification;
2. protocol framing and timing verification;
3. map addresses and scaling verification;
4. immutable backup and hash;
5. read-after-write verification;
6. disconnect and power-loss recovery testing;
7. bench testing without engine load;
8. supervised vehicle testing.

## 13. Engineering modules

```text
Transport layer
  RS232/USB capture, connection state, raw bytes

Protocol layer
  FCSS/FC-03 framing, decoding, identity evidence

Normalization layer
  Common engine and vehicle telemetry model

Sensor layer
  iPhone Core Motion, GPS, calibration, synchronization

Safety layer
  Limits, data quality, protection events, state machine

Statistics layer
  Baseline/candidate/repeat comparison and coverage

Experiment layer
  Objective, proposal, increment bounds, rollback plan

AI layer
  Local explanation, issue summary, structured suggestions

Storage layer
  Sessions, raw files, hashes, learning ledger

UI layer
  Live, capture, assessment, suggestions, approval, export
```

## 14. Initial implementation plan

### Phase 1: local assessment app

- browser review screen;
- local JSON/JSONL import;
- statistics and repeatability;
- concerns and decision states;
- approval checklist;
- session export;
- no ECU writes.

### Phase 2: read-only live transport

- actual serial capture;
- raw frame archive;
- verified frame timing;
- protocol identification;
- normalized fields;
- live engine dashboard.

### Phase 3: iOS sensor fusion

- Core Motion capture;
- GPS speed and course;
- phone-mount calibration;
- synchronized engine/dynamics sessions;
- acceleration, braking, and cornering analysis.

### Phase 4: local AI assistant

- structured prompt and response schema;
- local model runtime;
- evidence-linked explanations;
- no authority over safety gate or ECU writes.

### Phase 5: verified write workflow

- only after the complete write release gate is satisfied;
- explicit bench and vehicle validation;
- read-after-write verification;
- manual recovery path.

## 15. Success criteria

The product is useful when an operator can complete a session and answer:

- what hardware was connected;
- what the engine did;
- whether the data is trustworthy;
- what changed;
- whether the result repeated;
- what concerns remain;
- what the next smallest action is;
- how to return to the last accepted state.

The product is safe when it refuses to turn incomplete or dangerous evidence into an approved calibration change.
