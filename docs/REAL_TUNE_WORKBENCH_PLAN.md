# AhhPuck Real Tune Workbench Plan

Status: planned next build sequence

This plan moves AhhPuck from a single real tune record plus reference replay into a complete, read-only tuning evidence workbench. It follows the conventional capabilities users expect from tools such as HP Tuners VCM Scanner and Link PCLink: configurable gauges, channel-driven time plots, cursor-linked review, XY plots, histograms, statistics, parameter lists, calibration tables, surface views, and tune comparison. The product remains evidence-first and does not write to an ECU.

## Product boundary

AhhPuck can ingest and review real tune files, logs, definitions, dyno evidence, and vehicle metadata. It can calculate hashes, normalize verified channels, visualize calibration tables, compare versions, and surface evidence gaps.

AhhPuck must not:

- flash, write, or authorize an ECU operation;
- call a tune compatible because the engine name matches;
- call a tune safe because it came from a public repository;
- fabricate live telemetry from a tune file;
- silently infer units, sensor semantics, timebase, latency, or ECU identity;
- make emissions-disablement or protection-removal recommendations.

Every screen must distinguish `observed`, `declared`, `inferred`, `unknown`, and `contradicted` evidence.

## What the workbench must contain

### 1. Glance dashboard

For an in-car or bench review, with large type and minimal interaction:

- gate state: STOP, PAUSE, TEST, or VALIDATE;
- ECU identity and tune/log pairing status;
- RPM, throttle, MAP, lambda actual/target, coolant temperature, intake temperature;
- oil pressure, fuel pressure, battery voltage, injector pulse width, ignition timing;
- knock control, sync loss, sensor timeout, warning and fault state;
- min/max/peak values with timestamps;
- sample rate and dropped/stale-channel indicator;
- configurable pages, units, warning thresholds, and color-safe alarm states;
- a visible read-only indicator and an explicit “no write path” statement.

The glance dashboard is not the place for a dense 16x16 map or a long diagnostic narrative.

### 2. Log review

This is the primary professional review surface:

- multi-channel time plot with independent or shared axes;
- channel picker grouped by engine, fuel, ignition, boost, thermal, electrical, protection, and diagnostic domains;
- synchronized cursor across all plots;
- zoom, pan, range selection, markers, notes, and event sections;
- overlay of baseline, test, and repeat logs;
- offset alignment with the alignment method recorded;
- XY plot, e.g. RPM vs MAP, lambda error vs RPM, ignition vs load;
- histogram, distribution, min/max/mean/median, standard deviation, and percentile summaries;
- value list with exact timestamp, raw value, normalized value, and unit;
- navigator overview showing where the selected window sits in the full run;
- stale, flatline, clipping, impossible-range, time-jump, and missing-channel warnings;
- exportable chart image and machine-readable selection report.

### 3. Calibration-map review

Tune files are not logs. A tune screen must show configuration values as configuration values:

- scalar settings with name, value, units, source file, and evidence state;
- 1D curves and 2D/3D tables;
- RPM/load axes displayed beside the table, never assumed;
- table heatmap with accessible cell values;
- surface view for expert review, with a synchronized table alternative;
- min/max/mean and gradient checks;
- suspicious discontinuity and outlier flags, presented as observations rather than tuning advice;
- side-by-side or diff view for two tune versions;
- changed-cell highlighting with exact old/new values;
- calibration checksum and raw-file hash;
- firmware/definition compatibility gate before interpreting a table.

The first product adapter is the Freedom export contract for Toyota AE86 20V/16V, using preserved user-owned exports and logs with exact firmware and channel/units review. The rusEFI/TunerStudio `.msq` parser and bundled Online record #1813 remain a research/reference fixture for parser and visualization development, not the product identity. Every adapter must preserve the raw artifact and record the firmware signature and parser revision.

### 4. Diagnostics and evidence

- event timeline for sync loss, knock events, over-temperature, pressure warnings, sensor timeout, and fault codes;
- finding cards with observation, timestamp/range, affected channels, data quality, competing hypotheses, and disconfirming test;
- readiness matrix covering engine identity, ECU identity, firmware, mechanical health, sensors, protections, log semantics, and tune/log pairing;
- unsupported/unknown values remain visible;
- each finding links to the exact plot range, tune field, raw file, or source record that supports it;
- report view summarizes what was observed, what remains unknown, and what measurement is needed next.

## Data model additions

Add these versioned contracts beside the existing `EnginePassport`, `LogSession`, and `ReadinessReport` contracts:

### CalibrationArtifact

```json
{
  "schema_version": "0.2",
  "artifact_id": "rusefi-online-1813",
  "artifact_type": "tune",
  "format": "tuner_studio_msq",
  "raw_sha256": "...",
  "source_url": "https://rusefi.com/online/view.php?msq=1813",
  "license_or_rights": "unknown_until_confirmed",
  "ecu": {"manufacturer": "rusEFI", "model": null, "firmware": "...", "evidence_status": "declared"},
  "vehicle": {"make": "BMW", "model": "E30 325 is", "engine_code": "B20", "evidence_status": "declared"},
  "parser": {"name": "ahhpuck-rusefi-msq", "version": "0.1"},
  "tables": [],
  "scalars": [],
  "warnings": []
}
```

### LogArtifact

```json
{
  "schema_version": "0.2",
  "artifact_id": "...",
  "format": "csv|mlg|other",
  "raw_sha256": "...",
  "source": "user_upload|public_source|local_fixture",
  "tune_artifact_id": "...",
  "timebase": {"unit": "s", "monotonic": true, "evidence_status": "verified"},
  "channels": [],
  "quality": {},
  "privacy": {"vin_redacted": true}
}
```

### Channel contract

Every rendered value needs: canonical name, source name, raw value, normalized value, unit, timestamp, evidence state, parser revision, and quality flags. Initial canonical channels should include engine speed, throttle, MAP, lambda actual/target, coolant temperature, intake temperature, oil pressure, fuel pressure, battery voltage, injector pulse width, ignition timing, knock control, and sync loss count.

## Implementation sequence

### R1 — Replace the reference replay with a real artifact browser

- Parse the bundled rusEFI `.msq` file rather than hard-coding its metadata.
- Show real scalars: cylinders, compression, RPM limit, injector flow, fuel algorithm, firmware signature.
- Parse axis bins and table values for `veTable`, `ignitionTable`, and `lambdaTable`.
- Add fixture tests against tune #1813 and malformed XML.
- Keep the reference replay visibly separate from tune configuration.

Exit: changing the fixture file changes the displayed metadata only through the parser; no tune values are silently invented.

### R2 — Calibration map review

- Add a native map browser with table, heatmap, and surface modes.
- Add table search, scalar search, axis labels, units, and changed-cell highlighting.
- Add a read-only compare view for two `.msq` artifacts.
- Add firmware signature mismatch and missing-definition gates.

Exit: a reviewer can identify exactly which cells differ between two tune files and export the comparison.

### R3 — Real log intake and normalization

- Extend CSV import to retain raw bytes and source columns.
- Implement column mapping with explicit unit selection and no index-based alignment.
- Add timestamp diagnostics: non-monotonic time, gaps, duplicates, rate, jitter, and stale channels.
- Add pairing of a log to a tune by explicit user selection and hash.
- Add privacy redaction for VIN, names, locations, and free-text metadata.

Exit: five representative real logs can be imported, quality-scored, and reviewed without losing raw columns.

### R4 — Professional log visuals

- Time plot with synchronized cursor, markers, selection, zoom, and overlays.
- XY plot, histogram, statistics, value list, and navigator.
- Channel presets for idle, steady-state, transient, boost, thermal, and protection review.
- Mobile glance view plus iPad/desktop review view.
- Export selected window and chart metadata as JSON/CSV/PNG.

Exit: a user can reproduce a finding from a report by opening the exact log, channel set, and selected time range.

### R5 — Diagnostic engine integration

- Feed real quality flags and normalized channels into existing deterministic findings.
- Add findings for flatline lambda, delayed lambda, sync loss, pressure drop, thermal excursions, knock activity, and tune/log mismatch.
- Keep hypotheses and next measurements separate from calibration recommendations.
- Add adversarial fixtures for missing, stale, contradictory, clipped, and unit-mismatched data.

Exit: incomplete or contradictory evidence can only produce PAUSE/STOP states, never optimization permission.

### R6 — Upload and corpus ingestion

- Website upload flow: artifact → vehicle/engine → ECU/firmware → modifications → fuel/conditions → evidence → rights/privacy → visibility.
- Accept tune, log, definition, dyno report, and supporting image artifacts.
- Store immutable original, hash, metadata revision, parser revision, and source attribution.
- Public library records require confirmed rights, license, provenance, and visible “starting point only” language.
- Keep the downloaded rusEFI and Speeduino corpus as research fixtures, not automatically public AhhPuck records.

Exit: a real tune can be uploaded, reviewed, paired with a log, searched by exact identity, and audited without becoming an implied flash recommendation.

### R7 — Native and website completion

- Native iPhone/iPad: glance dashboard, artifact browser, map review, log review, diagnostics, case report.
- Website: bilingual upload/search/library/review pages using the same contracts.
- Japanese translation for all graph controls, warning states, evidence labels, and reports.
- Accessibility: VoiceOver labels, Dynamic Type, reduced motion, contrast, non-color state encoding, keyboard navigation on web.
- Capture verified English/Japanese iPhone and iPad screens from the actual native build.

Exit: product/design review approves all primary flows at mobile and iPad sizes, with no placeholder data visible in the real-artifact path.

## Acceptance test matrix

- Real `.msq` parses and displays source hash, firmware, vehicle, engine, scalar values, axes, and tables.
- A malformed or unsupported tune remains viewable as raw evidence with a clear unsupported status.
- A CSV with missing time, duplicate time, bad units, or flatline channels cannot be shown as healthy.
- Tune-only artifact never appears as telemetry.
- Log-only artifact never appears to prove calibration compatibility.
- Two tune versions produce deterministic scalar/table diffs.
- Two logs can be overlaid only when units and channel semantics are compatible.
- Every chart cursor and finding links to an exact source artifact and range.
- Public records retain rights, source, hash, uploader, visibility, and disclaimer metadata.
- English and Japanese expose identical fields, states, and warnings.
- Existing Python suite remains green; native build and parser tests run offline.

## Reference patterns reviewed

- HP Tuners VCM Scanner documents gauge, graph, and chart-vs-time panels with configurable channels: https://support.hptuners.com/support/solutions/articles/153000101005-layouts-in-vcm-scanner
- Link PCLink documents Time Plot, Navigator, XY Plot, Statistics, Histogram, Value List, Parameter List, overlays, synchronized cursors, and 3D surface graphs: https://linkecu.com/pages/pc-link
- Haltech NSP documents configurable dash screens, alarms, shift lights, and data logging: https://support.haltech.com/portal/en/kb/articles/navigating-dashes-in-nsp
