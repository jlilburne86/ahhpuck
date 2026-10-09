# Freedom ECU tuning app user stories

## Product goal

Help an AE86 owner running an AE111 Blacktop 4A-GE with a Freedom FC-03 move from uncertain tuning changes to a controlled, evidence-based improvement loop:

```text
Understand the car → capture a baseline → choose a goal → run a controlled test
→ review engine and vehicle data → receive a small suggestion → approve or rollback
```

The product must make the next safe action obvious while making unsafe or unsupported actions impossible to approve accidentally.

## Primary user

### Owner-operator

The owner knows the car well but is not necessarily a professional calibrator. They want to understand what the engine is doing, improve the car for a defined purpose, and avoid damaging an expensive or difficult-to-replace engine.

They need:

- plain-language explanations;
- visible evidence rather than unexplained AI recommendations;
- a record of every change and test;
- small, reversible steps;
- warnings that explain likely causes;
- confidence that the app will stop rather than continue when data is unsafe.

### Supporting user: tuner or engineer

The tuner needs dense graphs, raw logs, map/cell coverage, sensor validation, repeatability, and exportable evidence. They must be able to inspect the owner-facing explanation and the underlying values.

### Supporting user: developer/reviewer

The developer needs deterministic rules, reproducible assessments, clear protocol boundaries, and no hidden ECU write path.

## Jobs to be done

### JTBD-01: establish what is connected

When I connect an unfamiliar Freedom ECU, I want the app to identify the transport, ECU variant, firmware evidence, and available channels so that I do not tune the wrong hardware profile.

Success means the app shows verified, unverified, and unknown fields separately.

### JTBD-02: understand the current engine

When the engine is running, I want to see the important engine values and their quality so that I can tell whether the car is healthy enough to test.

Success means the dashboard prioritizes RPM, load, lambda, coolant, intake temperature, oil pressure, fuel pressure, voltage, ignition, knock, and telemetry health.

### JTBD-03: create a trustworthy baseline

Before changing anything, I want to capture an immutable baseline and repeat the same test condition so that later improvements are meaningful.

Success means the app stores the raw capture, normalized telemetry, profile, conditions, hashes, and operator notes.

### JTBD-04: define the reason for tuning

I want to choose whether I am optimizing for grip, drift, acceleration, top speed, drivability, economy, or reliability so that the assessment uses the right objective.

The app must never treat maximum power as the only objective.

### JTBD-05: understand vehicle behaviour

I want the phone to record acceleration, braking, cornering, yaw, speed, and GPS context so that the app can distinguish an engine change from wheelspin, road slope, driver variation, or braking variation.

Vehicle-dynamics data is supporting evidence. It does not replace engine safety instrumentation.

### JTBD-06: test one small change

I want the app to propose one bounded experiment with an expected effect, affected cells, stop conditions, and rollback source so that I know exactly what I am testing.

### JTBD-07: understand concerns before approval

I want the app to explain warnings and critical issues in plain language so that I can decide whether to inspect the car, repeat the test, or stop.

Warnings may be acknowledged. Critical issues cannot be overridden by the user interface.

### JTBD-08: approve a supervised experiment

I want to review the proposed change and explicitly approve a supervised test so that the system never makes a consequential change silently.

Approval means permission to run the defined experiment. It does not mean the engine is guaranteed safe.

### JTBD-09: assess the result

After a run, I want the app to compare baseline, candidate, and repeat candidate data so that it can distinguish an improvement from noise.

The app must show the measured improvement, repeatability, telemetry completeness, cell coverage, safety events, and uncertainty.

### JTBD-10: choose the next action

I want one clear recommendation after each assessment:

- accept and test a smaller increment;
- repeat the same test;
- rollback and investigate;
- stop immediately.

The app must not return a vague score without an action.

### JTBD-11: preserve learning

I want every experiment stored against this exact vehicle and hardware profile so that future suggestions improve from verified history without mixing data from incompatible engines.

### JTBD-12: inspect the evidence

I want to export raw bytes, decoded telemetry, graphs, decisions, warnings, hashes, and notes so that another tuner can independently review the work.

## Epics and user stories

## Epic A: vehicle and ECU setup

### US-A1: create a vehicle profile

As an owner, I want to record my chassis, engine, ECU label, ignition, injection, VVT, sensors, injectors, fuel pressure, fuel, and modifications so that the app analyses the correct configuration.

Acceptance criteria:

- AE86, AE101, and AE111 chassis options exist.
- 4A-GE Blacktop and Silvertop are distinct profiles.
- Direct ignition, injection mode, load strategy, VVT, and modifications are explicit.
- Unknown values remain unknown and produce a warning.
- The profile is saved locally and attached to every session.

### US-A2: identify the transport

As an operator, I want to select the serial transport and baud rate so that the app can capture the ECU without guessing.

Acceptance criteria:

- The app shows the selected port and baud rate.
- The app records connection time, disconnect time, and transport errors.
- A raw capture can be saved even when decoding fails.
- The app does not send unverified commands during identification.

### US-A3: verify the ECU

As a tuner, I want to see which ECU identity and options are verified so that a map or protocol is not applied to the wrong unit.

Acceptance criteria:

- Verified, inferred, and unknown identity fields are visually distinct.
- A profile mismatch blocks experiment approval.
- ECU writes remain locked until protocol and rollback gates pass.

## Epic B: baseline and logging

### US-B1: run a preflight check

As an owner, I want a checklist before a test so that missing sensors or backups are caught first.

Acceptance criteria:

- Baseline backup and hash are required.
- Wideband/lambda, RPM, coolant, intake, oil pressure, fuel pressure, voltage, and knock status are checked.
- Missing critical inputs block approval.
- The checklist result is stored in the session.

### US-B2: capture a baseline

As an owner, I want to capture a baseline run with notes and conditions so that I have a trustworthy reference.

Acceptance criteria:

- Raw serial data and normalized frames are stored together.
- Each frame has a timestamp and sequence where available.
- Fuel, temperature, gear, route/dyno, and driver notes can be recorded.
- The baseline cannot be overwritten from the UI.

### US-B3: capture phone dynamics

As a driver, I want the app to record accelerometer, gyro, GPS speed, braking, and cornering context so that a run can be interpreted in relation to vehicle behaviour.

Acceptance criteria:

- The phone mounting orientation is calibrated before recording.
- Sensor availability and quality are displayed.
- Dynamics data is timestamped against ECU data.
- Phone data is marked as supporting evidence, not engine safety authority.

## Epic C: experiment planning

### US-C1: choose an objective

As an owner, I want to select grip, drift, 0–100, top speed, drivability, economy, or reliability so that the system measures the result I actually care about.

Acceptance criteria:

- The objective is required before a proposal is created.
- The objective changes the displayed metrics and explanation.
- Safety limits never relax because of the selected objective.

### US-C2: receive a bounded suggestion

As an owner, I want a small suggested change with a reason so that I can understand what will be tested.

Acceptance criteria:

- Only one calibration family is changed per experiment.
- The proposal lists affected RPM/load cells, direction, magnitude, expected effect, and rollback source.
- The next step is smaller after a successful iteration.
- No suggestion is generated when critical evidence is missing.

### US-C3: review the risk

As an owner, I want to see warnings, critical faults, missing evidence, and likely causes before approving a test.

Acceptance criteria:

- Critical concerns disable approval.
- Warnings require acknowledgement.
- Each concern includes a suggested mechanical, sensor, or data check.
- The app clearly distinguishes measured evidence from AI explanation.

## Epic D: supervised testing

### US-D1: approve an experiment

As an operator, I want to tick explicit acknowledgements before approving a supervised test so that I understand the change and rollback plan.

Acceptance criteria:

- The user must confirm the profile, backup, warnings, stop limits, and supervision.
- Approval is tied to one proposal hash and one baseline hash.
- Approval never authorizes an ECU write by itself.

### US-D2: monitor the run

As a driver or tuner, I want live engine and vehicle data with clear stop alerts so that I can end a test before damage occurs.

Acceptance criteria:

- Critical alerts are prominent and persistent.
- Telemetry loss is shown as a fault, not silently ignored.
- The app records the alert frame and time.
- The app does not rely on the LLM for real-time protection.

### US-D3: stop safely

As an operator, I want the app to tell me why to stop and what to inspect so that I do not continue after a dangerous event.

Acceptance criteria:

- Knock, lean operation, overheating, low oil pressure, low voltage, implausible sensors, and telemetry timeout have explicit stop states.
- The next tuning action is locked until a human clears the investigation.

## Epic E: assessment and learning

### US-E1: compare three runs

As a tuner, I want baseline, candidate, and repeat candidate comparisons so that improvements are not accepted from a single noisy run.

Acceptance criteria:

- Lambda error, safety events, telemetry completeness, cell coverage, and repeatability are shown.
- Missing repeat data returns `not_assessed`, never pass.
- The system preserves the raw input files and assessment output.

### US-E2: receive a clear assessment

As an owner, I want the app to return accept, repeat, rollback, or abort so that I know what to do next.

Acceptance criteria:

- A positive result without repeatability cannot be accepted.
- A critical fault always returns abort.
- A regression returns rollback or review.
- A clean improvement returns a smaller next increment.

### US-E3: understand likely causes

As an owner, I want possible causes ranked and explained so that I check the engine, fuel system, sensors, wiring, or test conditions before changing the map again.

Acceptance criteria:

- The cause list is linked to measured evidence.
- The app labels causes as possible, not certain, unless directly verified.
- The app suggests the next measurement that would reduce uncertainty.

### US-E4: record learning

As a tuner, I want the system to store what happened and whether the operator accepted or rejected the recommendation so that later suggestions use verified vehicle-specific evidence.

Acceptance criteria:

- Each iteration is append-only.
- Profile and hardware hashes are stored.
- Rejected or unsafe experiments are not reused as successful calibration evidence.
- The app can export the learning ledger.

## Epic F: AI assistant

### US-F1: ask for an explanation

As an owner, I want to ask questions in plain language, such as “Why did this run fail?”, so that I can understand the data without being a calibration expert.

Acceptance criteria:

- The assistant uses the structured statistics and stored evidence.
- The assistant states uncertainty.
- The assistant cannot change the assessment decision.
- The assistant cannot send ECU commands.

### US-F2: request a smaller experiment

As a tuner, I want the assistant to explain the smallest permitted next step so that improvements remain incremental.

Acceptance criteria:

- The deterministic policy supplies the maximum permitted change.
- The AI cannot increase that maximum.
- The response is structured and stored with the experiment.

### US-F3: work offline

As an owner, I want analysis to work without a cloud account so that vehicle logs remain private and the app is usable at a track.

Acceptance criteria:

- Statistics and safety assessment work without an LLM.
- A local model is optional.
- Offline mode clearly shows when AI explanation is unavailable.

## User journey acceptance test

The minimum complete journey is:

1. Create an AE86 / AE111 Blacktop / Freedom FC-03 profile.
2. Complete the preflight checklist.
3. Import or capture a baseline.
4. Select an objective, for example grip or 0–100.
5. Generate one bounded proposal.
6. Review concerns and acknowledge only non-critical warnings.
7. Approve a supervised experiment.
8. Capture candidate and repeat candidate runs.
9. Review engine telemetry and phone dynamics together.
10. Receive accept, repeat, rollback, or abort.
11. Store the session and export the evidence.

The journey must never produce an automatic ECU write.

## Non-goals for the first working release

- Fully autonomous tuning.
- Guaranteed “perfect” or 96% optimal engine performance.
- Automatic interpretation of undocumented Freedom map semantics.
- Phone accelerometer replacing oil pressure, fuel pressure, wideband, or knock instrumentation.
- Unsupervised road testing.
- ECU writes before protocol, map semantics, backup, recovery, and read-after-write verification are proven.

## Release priorities

### P0: trustworthy evidence

- Profile, read-only connection, raw capture, normalized telemetry, local statistics, baseline/candidate/repeat assessment, warnings, rollback, and export.

### P1: useful vehicle context

- iPhone motion sensors, GPS, run objectives, driver notes, synchronized dynamics, and clearer charts.

### P2: local AI assistance

- Offline explanations, question answering over the session, likely-cause summaries, and bounded suggestion wording.

### P3: verified ECU write workflow

- Only after the exact Freedom unit and protocol are experimentally verified with a recoverable bench process.
