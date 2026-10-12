# Freedom ECU AE86 20V / AE101 / AE111 Research Workspace

Purpose: understand the E&E Systems Freedom FC-03/FCSS ecosystem before connecting or writing to an ECU, with emphasis on an AE86 chassis using an AE101/AE111 20-valve 4A-GE.

## Safety boundary

The first engineering milestone is read-only documentation, file analysis, ECU identification, and serial logging. No ECU write, map modification, or engine-load test is authorized until the original ECU state is backed up and the electrical/sensor configuration is verified.

## Landing page

The AhhPuck landing page is `index.html` at the repository root, with its assets in `landing/`. It is a sub-URL of wheelhave.com, so it carries the Wheel Have site header, an AhhPuck sub-bar in the same frame as the PuckIt one, and the shared footer groups; those links point at wheelhave.com. The page is bilingual: all copy lives in `landing/i18n.js` in English and Japanese, the English/日本語 switch remembers the choice under the same key the PuckIt pages use, and `?lang=ja` opens it in Japanese. It is a static page, so any local server pointed at the repository (or its parent folder) will serve it, for example `python3 -m http.server 3000`. The app screenshots in `landing/img/` are captures of the local mobile prototype and browser workbench running the demo fixture, not ECU data.

## Workspace layout

- `source_files/` — original user-supplied archives, preserved unchanged.
- `downloads/` — externally sourced diagrams and documentation.
- `extracted/` — extracted working copies.
- `notes/` — research notes, source register, and decoded findings.
- `logs/` — ECU/FCSS serial captures and engine data; do not overwrite originals.
- `tools/` — analysis utilities and future read-only tooling.

## Current source inventory

- `FCSS_MAP_BASE_DATA.zip`: base maps and `SAMPLE.LOG`.
- `FCSS_ECU_SOFTWARE.zip`: nested FCSS package containing `FCSS.EXE`, `LOGDSP.EXE`, `HELPDATA.FCS`, `HELPDATA.FCW`, `KDATA.F00`–`KDATA.F13`, `KTABL.FCS`, `KDNOTBL.FCS`, configuration files, executables and an example map.
- External target: Club4AG FCSS serial data cable diagram.
- External target: Kunugi Runner FCSS manual pages.

## Planned milestones

1. Preserve hashes and inventory all files.
2. Extract and classify FCSS binaries, help databases, KDATA tables, maps and logs.
3. Document the FCSS menu/model/option vocabulary from manuals and help data.
4. Decode `.FCP` and `.LOG` structures without modifying originals.
5. Obtain the exact ECU label, connector, harness and option configuration.
6. Validate RS-232 electrical interface and perform ECU identification only.
7. Capture FCSS read operations: identify, read settings, read live data, read map.
8. Build a read-only logger and complete ECU backup workflow.
9. Compare AE86 20V, AE101 Silvertop and AE111 Blacktop base data.
10. Only after validation, design a fuel-only learning/logging prototype with rollback.

## Evidence policy

Every decoded field will be tagged as one of:

- `documented` — directly supported by a manual or pinout;
- `observed` — confirmed by serial capture or controlled file comparison;
- `inferred` — plausible but not yet experimentally confirmed;
- `unsafe/unverified` — not suitable for ECU writing or tuning decisions.

## Provisional engineering guide

See [docs/engine-tuning-provisional-guide.md](docs/engine-tuning-provisional-guide.md) for the documented calibration sequence, engine-building prerequisites, AI/LLM boundaries, protection rules, validation process, and evidence labels.

See [docs/iphone-live-monitoring-architecture.md](docs/iphone-live-monitoring-architecture.md) for the USB-C/iPhone transport boundary, live-session state machine, alerts, and software-failsafe design.

See [notes/07-paddock-fcss-transport.md](notes/07-paddock-fcss-transport.md) for the FCSS/RS232C/9600-bps transport findings and capture plan.

See [notes/08-paddock-n-page-inventory.md](notes/08-paddock-n-page-inventory.md) for the page-by-page inventory of captured Paddock-N Freedom pages and remaining crawl gaps.

See [notes/09-hiro0719jp-cross-platform-research.md](notes/09-hiro0719jp-cross-platform-research.md) for the captured Hiro0719jp Freedom/FCST article archive, images, serial-protocol findings, Surface/UGREEN reference, and iPhone/Android architecture conclusions.

See [docs/native-mobile-ecu-product-goal.md](docs/native-mobile-ecu-product-goal.md) for the native iOS/Android product goal, direct USB strategy, dashboard scope, and release gates.

See [docs/closed-loop-tuning-workflow.md](docs/closed-loop-tuning-workflow.md) for the complete baseline → proposal → controlled run → assessment → rollback/smaller-step tuning flow, issue diagnosis matrix, logging contract, AI boundaries, and release gates.

See [docs/user-stories.md](docs/user-stories.md) for the owner, tuner, and developer journeys, jobs to be done, acceptance criteria, release priorities, and first complete user journey.

See [docs/product-design-overview.md](docs/product-design-overview.md) for the engineering product design, application surfaces, collected and displayed data, normalized telemetry model, processing pipeline, assessment states, safety boundaries, storage, and implementation phases.

See [notes/11-ecu-unit-label.md](notes/11-ecu-unit-label.md) for the decoded label of the purchased FC-03 unit (`Ab-1EU`, `Z-J01030`, group injection, direct ignition) and what it changes for the harness plug and engine profile.

See [notes/10-future-platform-candidates.md](notes/10-future-platform-candidates.md) for separately documented ECU and tuner candidates. These remain out of scope until the Freedom FC-03 trial is connected, tested, and reviewed against real vehicle evidence.

The native SwiftUI/Xcode implementation is in [ios-app](ios-app/README.md). It includes the imported mobile flow, deterministic experiment assessment, read-only safety boundary, and a fixture-backed first-trial workflow.

The first-trial state machine runs profile/readiness → baseline → candidate → repeat → assessment → supervised approval locally. It is deliberately fixture-backed and read-only until the FC-03 protocol is verified.

The complete standalone handoff is [docs/engine-intelligence-end-to-end.md](docs/engine-intelligence-end-to-end.md). The local orchestration CLI connects the source registry, engine passport, hashed session bundle, telemetry diagnosis, evidence-linked explanation, and human-only experiment state machine. It remains read-only by design and reports `write_authorization: never`.

```sh
python3 tools/engine_intelligence.py knowledge-check
python3 tools/engine_intelligence.py diagnose tools/examples/baseline-telemetry.json
python3 tools/engine_intelligence.py capture-bundle /tmp/ahhpuck-session /tmp/ahhpuck-passport.json tools/examples/raw-freedom-capture.json
```

Record and explain an iteration in the local learning ledger:

```sh
python3 tools/ai_analysis_service.py \
  notes/tuning-iteration-report.json \
  --db data/tuning-ledger.sqlite3
```

The current analyst is deterministic and offline. It is the contract that a future on-device LLM must satisfy; it cannot authorize ECU writes.

Compare two local telemetry captures without an AI service:

```sh
python3 tools/telemetry_stats.py \
  tools/examples/baseline-telemetry.json \
  tools/examples/candidate-telemetry.json \
  --output notes/telemetry-comparison.json
```

Add `--candidate-repeat path/to/second-candidate-run.json` before accepting an improvement. Without a second run, repeatability is reported as `not_assessed` and the candidate cannot be marked clean.

Complete example using the included sample captures:

```sh
python3 tools/telemetry_stats.py \
  tools/examples/baseline-telemetry.json \
  tools/examples/candidate-telemetry.json \
  --candidate-repeat tools/examples/candidate-repeat-telemetry.json \
  --output notes/telemetry-comparison.json
```

This calculates lambda error, improvement, repeatability, telemetry completeness, RPM/load coverage, sensor statistics, and knock events locally.

Assess one back-and-forth tune iteration with:

```sh
python3 tools/tuning_iteration.py \
  tools/examples/tuning-iteration-input.json \
  --report notes/tuning-iteration-report.json
```

Run the provisional safety gate against a candidate experiment:

```sh
python3 tools/safety_gate.py tools/examples/safety-gate-input.json \
  --report notes/safety-gate-report.json
```

## Implemented inspection commands

Inspect one Freedom map and preserve its structure as JSON:

```sh
python3 tools/fcp_parser.py \
  "extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP" \
  --json-out notes/AE86-A.parsed.json
```

Inventory all supplied base maps:

```sh
python3 tools/fcp_inventory.py \
  "extracted/base_maps/BASE MAPS - FC OE DATA" \
  --json-out notes/fcp-structure-inventory.json
```

Create a guarded comparison report against the AE111 Blacktop profile:

```sh
python3 tools/fcp_adapter_report.py \
  "extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP" \
  tools/examples/ae111_blacktop_fc03_target.json \
  --report notes/AE86-A-to-AE111-report.json
```

The report is deliberately comparison-only until Freedom table semantics,
scaling, axes, checksum, and the read/write protocol are experimentally
verified. Run the parser tests with:

```sh
python3 -m unittest tools/test_fcp_parser.py
```

## Offline purpose-learning concept test

The experimental optimizer accepts normalized logs and supports `drift`,
`grip`, `0-100`, and `top-speed` scoring. It only proposes bounded fuel-cell
changes; ignition is never advanced automatically and ECU writes are disabled:

```sh
python3 tools/concept_optimizer.py tools/examples/concept-log.json \
  --purpose drift --report notes/concept-drift-report.json
```

Protection gates reject samples with excessive RPM, coolant or intake
temperature, low voltage, low oil pressure under load, knock, or lean operation
under load. This reflects the layered protection practices described by Link
and Haltech, but the thresholds remain configurable and must be validated for
the actual engine and sensors.

The report also includes a `quality_gate`. “96%” means an evidence-weighted
readiness target combining objective score, safety-pass fraction, map coverage,
repeatability, and sensor confidence. It is not a claim that the engine is 96%
perfect. Missing evidence counts as zero, so the system cannot reach the target
from a few attractive dyno pulls or an LLM opinion.
