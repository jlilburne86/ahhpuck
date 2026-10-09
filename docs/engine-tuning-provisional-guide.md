# Engine tuning and engine-building guide — provisional product specification

Status: research draft, not a workshop manual or permission to operate an unverified vehicle at full load.

Audience: the product team building a read-only/log-driven calibration assistant for an AE86 with an AE101/AE111 4A-GE 20V Blacktop and Freedom FC-03. Every numerical limit must be confirmed for the actual engine, fuel, sensors, ECU configuration, and use case.

## 1. What engine tuning is

Engine tuning is calibration: selecting fuel, ignition timing, airflow control, cam timing, idle control, transient enrichment, warm-up correction, rev limiting, and protection intervention for each operating condition.

There is no universal “perfect tune.” It is a constrained trade-off among torque, response, power, fuel use, temperature, emissions, drivability, engine life, and purpose. Drift, grip, 0–100, and top-speed tunes can legitimately make different compromises.

Key terms:

- **Lambda**: measured mixture relative to stoichiometric for the fuel; preferable to raw AFR when fuel type may change.
- **VE model**: a fuel model where the main table represents estimated cylinder filling. It only becomes meaningful after injector, fuel pressure, sensor, displacement, and load calibration are correct.
- **MBT**: minimum spark advance for best torque. An engine may reach knock before MBT; then it is knock-limited and the knock threshold governs safe timing.
- **Cell**: one RPM/load location. One noisy sample is not valid evidence; cells need repeatable observations.

Research supports model-based and surrogate-assisted optimization because dyno evaluations are expensive, but safety constraints must remain separate from the performance objective. See the [engine-calibration optimization review](https://www.sciencedirect.com/science/article/pii/S0306261921012071) and [safe Bayesian optimization for engine control](https://www.sciencedirect.com/science/article/pii/S240589631731772X).

## 2. Engine-building comes before tuning

Software cannot compensate for a mechanical fault. Before calibration, document and inspect:

1. Engine identity, compression ratio, camshafts, cam timing, head gasket, piston-to-valve clearance, and bottom-end condition.
2. Compression and leak-down results, oil pressure, cooling-system pressure, thermostat/fan operation, and coolant circulation.
3. Oil level, oil temperature behavior, baffling, pickup condition, and oil-starvation risk during long corners or transitions.
4. Tank, pump, filter, regulator, rail, injector condition, fuel pressure under load, and fuel-pressure reference plumbing.
5. Intake leaks, throttle synchronization, MAP reference quality, exhaust leaks, sensor grounds, battery/charging voltage, and ignition wiring.
6. Crank/cam trigger integrity, base timing with a timing light, coil dwell, plug heat range/gap, and firing order.
7. Wideband placement and calibration, knock-sensor mounting and frequency strategy, coolant/IAT/oil/fuel-pressure sensor calibration, and logging rate.

For the 4A-GE 20V Blacktop, the engine profile must record ITBs, MAP strategy, sequential injection, switched inlet cam timing, and actual injector/ignition hardware. Haltech identifies these as key differences from other 4A-GE variants: [4AG engine reference](https://support.haltech.com/portal/en/kb/articles/4ag-engine).

## 3. Required calibration sequence

### Stage A — define the job

- **Drift**: predictable throttle response, sustained thermal margin, repeatable torque, stable fueling during long load periods.
- **Grip**: smooth torque delivery, corner-exit response, controllable transient behavior, and temperature margin.
- **0–100**: repeatable launch/response, acceleration through the usable RPM range, shift consistency, and traction-aware torque delivery.
- **Top speed**: sustained high-RPM/load stability, cooling and oil control, conservative protection margins, and gear/aerodynamic limits.

The product must never optimize one number while hiding a safety regression.

### Stage B — configure and verify the ECU

Create a read-only baseline and record engine profile, fuel, injectors, fuel pressure, load source, sensor calibrations, ignition trigger, timing offset, VVT behavior, rev limits, and protection thresholds.

Check that live readings are plausible before starting. A bad MAP, TPS, coolant, lambda, voltage, or RPM signal invalidates learning. The AI must not “learn around” a sensor fault.

### Stage C — start, idle, and light-load fuel

Start with conservative fuel and ignition values. Confirm oil pressure and stable coolant behavior. Tune the fuel model at steady, low-risk conditions by comparing measured lambda with target lambda. Change one related group of cells at a time, then repeat the same operating point.

The target table must describe the actual desired lambda. Do not hide a target-mixture error inside the VE table; otherwise closed-loop correction and future adaptation become misleading. See this [fuel-table and lambda-target guide](https://www.hpacademy.com/courses/practical-standalone-tuning/maxxecu-step-3-base-table-configuration/).

### Stage D — load-based fuel

Increase load gradually only after low-load operation is stable. Use a load-bearing dyno where possible. Monitor lambda, fuel pressure, coolant, IAT, oil pressure, voltage, and knock continuously.

Haltech's load-tuning guidance says to tune rich first, slowly approach the target, watch coolant temperature, and reduce load immediately if detonation or very lean operation appears: [applying load to an engine](https://support.haltech.com/portal/en/kb/articles/applying-load-to-the-engine).

### Stage E — ignition timing

Verify base timing physically before changing the table. Begin conservatively and approach MBT or the knock threshold in small, controlled steps. Use audio knock detection and, where available, cylinder-level knock data. ECU knock control is a protection layer, not a substitute for a sound base ignition map.

If knock occurs, stop increasing load, capture the event, identify real knock versus mechanical noise, reduce timing/load as appropriate, and correct the cause. Possible causes include low octane, excessive intake temperature, lean mixture, high coolant temperature, excessive compression/load, poor fuel delivery, or an ignition/trigger problem.

Useful teaching references are [knock-limited timing and road/dyno method](https://www.hpacademy.com/courses/practical-standalone-tuning/road-tuning-tuning-without-a-dyno-full-power-tuning/) and [knock detection tools](https://www.hpacademy.com/technical-articles/tuning-tools/).

### Stage F — transient, VVT, idle, and limits

After steady-state tables are credible, tune throttle movement, acceleration enrichment, deceleration fuel, idle control, warm-up, battery compensation, and VVT. Treat these as separate corrections; do not bake transient behavior into the main fuel table.

Validate rev limits, over-temperature behavior, low oil/fuel pressure response, sensor-failure behavior, voltage limits, and lambda/knock intervention before performance testing. Link describes this layered model as engine protection rather than performance tuning: [Link engine protection](https://linkecu.com/tech-articles/features-engine-protection/).

### Stage G — validation

Validation requires repeatability, not one impressive run:

- cold start, hot restart, idle, cruise, and transitions;
- repeated steady-state cells across the usable RPM/load range;
- controlled full-load sweeps with temperature and pressure recovery between runs;
- heat-soak and sustained-load testing appropriate to the purpose;
- repeat runs on intended fuel and representative ambient conditions;
- backup comparison, rollback test, and protection-trigger test where safe;
- independent review of the final log and calibration diff.

The product's 96% target is an evidence-readiness score, not “96% perfect.” A candidate cannot pass if safety faults exist, data coverage is sparse, sensor confidence is low, or repeatability has not been demonstrated.

## 4. What the AI/LLM is allowed to do

The LLM is an evidence interpreter and workflow coordinator. It may classify the engine/profile, detect missing assumptions, summarize logs, identify suspicious sensors, explain likely causes, compare source maps, propose a bounded next experiment, and generate a human-readable change report and rollback plan.

The numerical optimizer may propose only changes inside an approved safe region. The LLM cannot bypass protection gates, invent injector data, infer an ignition offset, or authorize a write. Every recommendation must include source data, confidence, affected cells, expected effect, safety assumptions, and rollback.

## 5. Product safety rules

1. Preserve the original map and every log immutably.
2. Never write an unknown or foreign binary directly into the FC-03.
3. Require verified axes, units, checksum behavior, and protocol before write support exists.
4. Keep fuel, ignition, VVT, transient, and protection layers separate.
5. Reject learning during knock, lean high-load operation, low oil/fuel pressure, overheating, implausible sensor readings, or unstable voltage.
6. Limit each iteration, change one variable family at a time, and require repeat measurement.
7. Keep human approval before every ECU write.
8. Never claim safety or optimization from simulation alone.

## 6. Evidence labels

- **Documented** — manufacturer/manual or primary technical source directly supports the statement.
- **Observed** — reproduced from a local file, serial capture, or controlled test.
- **Inferred** — plausible engineering interpretation awaiting confirmation.
- **Unverified/unsafe** — not suitable for a tune or ECU write.

The current FCP parser findings are **observed structure only**. The table names and dimensions do not yet prove whether a block is fuel, ignition, throttle, or correction data. That semantic decode remains a required milestone.

## 7. Software-engineering safety set

The software should be developed as a safety-constrained measurement product,
not as an autonomous “AI tuner.” ISO 26262 is the relevant automotive
functional-safety reference family; its software-level part covers safety
requirements, architecture, implementation, verification, integration, and
testing. It is not a shortcut to certification for this project, but it is a
useful process model: [ISO 26262-6](https://www.iso.org/standard/68388.html).

Minimum engineering controls:

- **Traceability**: every recommendation links to source logs, profile data,
  calibration version, software version, and assumptions.
- **Reproducibility**: the same input and policy version produce the same
  recommendation; record hashes for maps and logs.
- **Separation**: analysis, candidate generation, safety gating, ECU transport,
  and UI are separate modules with separate permissions.
- **Fail closed**: unknown protocol, unknown units, missing sensor confidence,
  stale data, checksum uncertainty, or a protection fault means no write.
- **Change control**: one calibration family per experiment, bounded deltas,
  explicit diff, approval, and rollback artifact.
- **Fault injection**: test unplugged sensors, implausible values, stale frames,
  corrupted maps, serial disconnects, partial writes, power loss, and duplicate
  frames.
- **Time and state safety**: use monotonic timestamps, detect data gaps, reject
  out-of-order samples, and model connection/write states explicitly.
- **Security**: authenticate local sessions, protect map files, avoid arbitrary
  code execution from imported files, and log all export/write attempts.
- **Human factors**: show units, axes, limits, confidence, active protection
  state, and rollback action prominently; never hide uncertainty behind a single
  score.
- **Release gates**: unit tests, parser fixtures, property tests, replay tests,
  hardware-in-the-loop tests where available, and a manual sign-off checklist.

The repository's `config/tuning-safety-policy.json` and `tools/safety_gate.py`
are the first executable form of this set. They are intentionally conservative
and still do not authorize FC-03 writes.
