# AhhPuck product goals and user stories

## Product north star

Help an owner of a Freedom-equipped AE86 4A-GE 20V or 16V understand what the
engine is doing, prove whether a change helped, and make the next smallest
reversible improvement without turning uncertainty into a dangerous guess.

AhhPuck is a local-first diagnostic and experiment workbench. It is not an
autonomous tuner. The product earns trust by making evidence, uncertainty,
causal hypotheses, and stop conditions visible.

## Product goals

### G1 — Make the next safe action obvious

Every live or reviewed session ends in one clear state:

- continue observing;
- repeat the same experiment;
- inspect a mechanical or sensor cause;
- rollback and investigate; or
- stop immediately.

Success measure: a first-time owner can identify the next action and why it is
recommended without needing to interpret a raw number or an AI paragraph.

### G2 — Turn telemetry into understanding

Numbers must be presented in context. The app should show the relationship
between RPM, load, lambda, temperature, pressure, ignition, knock, and vehicle
motion—not isolated gauges.

Success measure: every important metric has a visible target, range, trend,
quality state, or causal relationship attached to it.

### G3 — Protect the original vehicle and its evidence

Baseline captures, raw bytes, decoded frames, hashes, maps, notes, and decisions
must remain locally recoverable and immutable. Unsupported fields stay visible
as unknown instead of being silently inferred.

Success measure: any assessment can be reproduced from its recorded inputs, and
no UI path can accidentally authorize an ECU write.

### G4 — Support both the mechanic and the data nerd

The glance experience should be calm and readable in the car. The engineer
experience should expose dense graphs, cell coverage, timestamps, provenance,
units, gaps, and raw evidence.

Success measure: the same session can be understood in under ten seconds by a
driver and audited in detail by a tuner.

### G5 — Improve through controlled experiments

AhhPuck should learn from verified vehicle history without mixing incompatible
engines, sensors, fuels, or ECU variants. AI may explain evidence and rank the
next measurement; deterministic gates own numerical bounds and safety.

Success measure: every accepted experiment has a baseline, candidate, repeat
run, objective, affected cells, rollback source, and review record.

## Product principles

- Unsupported is not obsolete: an unknown signal is an evidence gap.
- Engine safety channels outrank phone context and performance scores.
- A graph should answer a question, not decorate a screen.
- Show cause and uncertainty together; never imply diagnosis is certainty.
- One experiment changes one calibration family at a time.
- Missing repeatability means `not assessed`, never success.
- Read-only is the default release posture.
- English and Japanese use the same data model and information hierarchy.

## Personas

### Owner-driver

Owns and drives the AE86. Understands the car but may not be a professional
calibrator. Needs a clear preflight, readable live state, warnings with plain
language, and confidence that the app will pause rather than encourage a bad
test.

### Tuner / engine builder

Needs synchronized traces, RPM/load cell coverage, repeatability, sensor
plausibility, and a clear distinction between a tuning problem and a mechanical
or measurement problem.

### Data-minded reviewer

Needs timestamps, sample rate, sequence continuity, units, raw versus decoded
values, hashes, provenance, parser version, and enough detail to reproduce the
assessment.

### Maintainer / protocol researcher

Needs unknown FC-03 frames preserved, parser behaviour documented, write paths
kept disabled, and fixture data separated from real vehicle evidence.

## Core user stories

### Epic A — Establish identity and readiness

**US-A1 — Create the correct vehicle profile**  
As an owner, I want to record AE86 chassis, 4A-GE 20V/16V variant, Freedom ECU,
fuel, injectors, sensors, and modifications so that evidence is interpreted in
the correct context.

Acceptance criteria:

- 20V Blacktop, 20V Silvertop, and 16V remain distinct profiles.
- Unknown fields are explicit and never silently defaulted.
- Every run and proposal stores the profile identity and version.

**US-A2 — Verify connection and ECU identity**  
As a tuner, I want to know what is verified, inferred, or unknown before I
interpret a trace or proposal.

Acceptance criteria:

- Transport, baud, framing, ECU identity, firmware evidence, and channel
  availability have separate states.
- A profile mismatch blocks experiment approval.
- Raw bytes are preserved even when decoding fails.

**US-A3 — Run preflight**  
As a driver, I want a readiness card that explains missing evidence and the next
check before I load the engine.

Acceptance criteria:

- Missing lambda, oil pressure, fuel pressure, knock, identity, or baseline
  evidence is visible.
- Critical gaps create a pause/stop state.
- The card explains what evidence would clear the state.

### Epic B — Understand the live engine

**US-B1 — See a glance-safe dashboard**  
As a driver, I want the current protection state, telemetry health, RPM/load,
lambda, coolant, pressure, voltage, and knock status prioritized above detail.

Acceptance criteria:

- Protection state and telemetry age are visually dominant.
- Critical state uses text and iconography as well as colour.
- The screen remains readable with Dynamic Type and VoiceOver.

**US-B2 — See relationships, not isolated values**  
As a tuner, I want synchronized graphs for RPM/load, lambda versus target,
ignition, pressure, temperature, and knock so that I can reason about what
happened.

Acceptance criteria:

- Every graph has units, target/range, time or operating-axis context, and a
  quality state.
- Selecting a point reveals the frame timestamp and related channels.
- Missing or stale channels are visually marked.

**US-B3 — Separate engine evidence from phone context**  
As a reviewer, I want acceleration, speed, yaw, and GPS shown as supporting
context so that motion is not mistaken for engine safety evidence.

Acceptance criteria:

- Phone dynamics are labelled as contextual.
- Sensor calibration and GPS accuracy are visible.
- Phone data cannot clear an engine protection gate.

### Epic C — Capture a trustworthy experiment

**US-C1 — Capture an immutable baseline**  
As an owner, I want baseline, candidate, and repeat runs saved with raw data,
conditions, notes, timestamps, and hashes so that comparisons are meaningful.

Acceptance criteria:

- The baseline cannot be overwritten through the UI.
- File hash, parser version, source, and channel availability are recorded.
- Replay fixtures are clearly labelled as fixtures, not real vehicle evidence.

**US-C2 — See operating coverage**  
As a tuner, I want an RPM/load heatmap showing tested, valid, missing, and
protection-triggered cells so that I know where a conclusion is supported.

Acceptance criteria:

- Coverage is computed separately for baseline, candidate, and repeat.
- Unvisited cells never appear as “good”.
- The assessment states when coverage is insufficient.

**US-C3 — Record the experiment intent**  
As an owner, I want to choose drivability, grip, drift, acceleration, top speed,
economy, or reliability and define the test window so that success is measured
against the purpose of the run.

Acceptance criteria:

- Objective, route/dyno context, gear, RPM/load range, fuel, and notes are
  required before assessment.
- Safety limits do not change with the objective.

### Epic D — Explain cause and uncertainty

**US-D1 — Understand an alert**  
As a mechanic, I want each finding expressed as observed signal, likely
interpretation, and next check so that I know whether to inspect hardware,
validate a sensor, or change the calibration.

Acceptance criteria:

- The observed evidence is displayed separately from the hypothesis.
- Causes are labelled possible unless directly verified.
- The next check is actionable and tied to the missing evidence.

**US-D2 — Diagnose data quality**  
As a data-minded reviewer, I want frame count, sample rate, gaps, duplicates,
jitter, outliers, channel coverage, and unit conversions visible before I trust
the result.

Acceptance criteria:

- A run with gaps or missing critical channels cannot pass silently.
- Raw and normalized values can be distinguished.
- Data quality is part of the decision, not a hidden log detail.

**US-D3 — Distinguish tuning from mechanical fault**  
As an owner, I want the app to say when the evidence cannot distinguish a map
problem from fuel pressure, injector, wiring, air leak, knock, or sensor fault.

Acceptance criteria:

- The app pauses rather than proposing a calibration change when causal evidence
  is insufficient.
- Mechanical and measurement checks appear before a fuel proposal.

### Epic E — Make bounded progress

**US-E1 — Review one small proposal**  
As a tuner, I want affected cells, direction, maximum change, expected effect,
rollback source, and stop limits shown before I approve a test.

Acceptance criteria:

- One calibration family changes per experiment.
- Ignition remains locked until timing offset and knock evidence are verified.
- AI cannot bypass deterministic limits.

**US-E2 — Compare baseline, candidate, and repeat**  
As a reviewer, I want before/after/repeat overlays and residuals so that I can
separate improvement from noise.

Acceptance criteria:

- Lambda error, repeatability, protection events, data quality, and coverage are
  shown together.
- No repeat run means the result is not accepted as repeatable.

**US-E3 — Record supervised approval**  
As an operator, I want approval tied to exact hashes, warnings, rollback path,
and stop criteria so that the experiment is auditable.

Acceptance criteria:

- Approval is explicit and reviewable.
- Approval does not enable ECU writes in the current release.
- Critical concerns disable approval.

## Visual information architecture

### Glance layer

For the driver in the car:

- protection state;
- telemetry age and connection;
- RPM/load and lambda trend;
- stop/pause reason;
- one next action.

### Tuner layer

For controlled test review:

- synchronized channel charts;
- RPM/load coverage heatmap;
- baseline/candidate/repeat overlays;
- event timeline;
- sensor plausibility and operating ranges;
- affected map cells and proposal bounds.

### Evidence layer

For the data nerd and maintainer:

- raw versus decoded values;
- timestamps, sequence, sample rate, gaps, jitter, and dropped frames;
- units and transformations;
- file hashes, parser version, provenance, and fixture/real status;
- deterministic rule outputs and structured AI explanations.

## Release roadmap

### Now — restore trust

- Native iOS shell and simulator replay.
- AE86 / 4A-GE 20V and 16V profile direction.
- Read-only state and readiness gates.
- Lambda trace, RPM/load relationship, evidence quality, causal explanation.
- English/Japanese shell and local artifact records.

### Next — make the graphs useful

- RPM/load cell heatmap.
- Synchronized multi-channel chart with cursor inspection.
- Event timeline and data-quality detail.
- Baseline/candidate/repeat comparison view.
- Complete Japanese localization for generated findings and review states.

### Later — validate on the actual platform

- FC-03 capture from the original reverse-engineered boundary.
- Idle and light-load vehicle validation with independent instrumentation.
- Fault-injection runs: disconnect, stale frames, malformed frames, bad sensors,
  power loss, and corrupted files.
- Human-reviewed bounded proposal generation against real AE86 captures.

### Future — only after protocol evidence

- Authenticated live bridge or supported direct accessory path.
- Signed calibration diffs and rollback records.
- Restricted write experiments only after protocol, checksum, axes, units,
  timing, and rollback are independently verified.

## Definition of product readiness

AhhPuck is ready for a real controlled test when:

- the correct AE86 / engine / ECU profile is verified;
- the original map or baseline is backed up and hashed;
- critical engine safety channels are present and plausible;
- the test window has adequate RPM/load coverage;
- baseline, candidate, and repeat data are synchronized;
- protection events and data gaps are visible;
- the decision is reproducible from local artifacts;
- a human understands the next action and rollback path.

It is not ready merely because a graph renders, a model produces a score, or a
candidate appears better in one unrepeatable run.
