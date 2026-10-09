# Safe optimization specification

## Product objective

Connect to the Freedom FC-03 in the AE86 with an AE111 20V Blacktop, read and back up the current calibration, compare it with documented and provenance-tracked reference maps, and produce conservative tuning recommendations from measured engine data.

The product must not claim or promise “100% safe” or “maximum power” from software alone. The achievable target is a controlled, evidence-based calibration process with explicit limits, human approval, rollback, and dyno/road validation.

## Required vehicle identity

Before recommendations are enabled, record:

- FC-03 hardware label, serial, firmware/application/options, and current map checksum.
- AE111 Blacktop confirmation, compression and camshafts.
- Injector manufacturer, flow rating, dead time/latency, fuel pressure and regulator reference.
- Fuel type and ethanol content where relevant.
- MAP/air-temperature/coolant/TPS sensors and calibration.
- Ignition coils, plugs, trigger arrangement, and base timing procedure.
- Wideband controller, sensor location, calibration status, and sample rate.
- Knock sensor or external knock-monitoring equipment.
- Intake, exhaust, throttle bodies, VVT status, and idle-control hardware.

If any of these are unknown, the application remains in backup/viewer mode.

## Data provenance

Every reference map or example tune must carry source, engine, injector, fuel, hardware, date, and validation notes. Maps from an AE86, AE101 Silvertop, AE111 Blacktop, turbo engine, or different injectors must never be silently treated as interchangeable.

The supplied FCSS maps are references for structure and comparison, not proof that their values are correct for this vehicle. A reference tune can seed a proposal only after the metadata matches or the mismatch is explicitly accepted by the tuner.

## Tuning order

1. Read-only ECU identification and complete backup.
2. Sensor and wiring plausibility checks.
3. Cranking, idle, and warm-up verification.
4. Conservative fuel correction using measured AFR.
5. Part-load and transient fuel validation.
6. High-load fuel validation under controlled dyno conditions.
7. Ignition changes only with reliable knock monitoring and verified base timing.
8. VVT, throttle, and limiter refinement after fuel and ignition are stable.
9. Repeatability runs, hot/cold checks, and rollback test.

## Operating loop

Each tuning iteration is deliberately small and reversible:

1. Select a baseline with matching vehicle and hardware provenance.
2. Save an immutable ECU backup and label the baseline.
3. Run a defined test window under controlled conditions.
4. Review AFR, RPM, load, temperature, ignition, battery voltage, and knock evidence.
5. Propose one bounded change or one tightly related cell group.
6. Require human approval and preserve the pre-change map.
7. Write only after protocol and checksum checks pass.
8. Repeat the same test window and compare results.
9. Keep the change only if it improves the target without violating limits; otherwise roll back.

## Software safety gates

- Default mode is read-only.
- Preserve an immutable raw ECU backup before every write session.
- Never write without a verified protocol frame, checksum, expected response, and stable power.
- Require user confirmation for every map write.
- Enforce configurable RPM, load, coolant-temperature, AFR, battery-voltage, and rate-of-change limits.
- Reject recommendations when data is sparse, inconsistent, out of range, or missing knock/AFR context.
- Keep fuel and ignition recommendations separate; ignition recommendations are locked until knock data is available.
- Store before/after maps, data windows, assumptions, and rollback instructions.
- Stop the session on communication errors, voltage instability, sensor disagreement, or unexpected ECU response.

## AI role

AI may classify logs, identify cells with repeatable error, compare provenance-matched maps, and suggest small changes. It may not invent missing sensor data, infer a safe ignition advance from AFR alone, bypass limits, or autonomously write to the ECU.

The first optimizer should be deterministic and auditable: calculate measured AFR error by RPM/load cell, reject outliers, apply a bounded correction, smooth neighbouring cells, and generate a reviewable proposal. AI can explain the proposal after the calculation, not replace it.
