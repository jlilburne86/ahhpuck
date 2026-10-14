# AhhPuck by Wheel Have

**Unsupported is not obsolete.** AhhPuck brings modern logging and evidence-based, repeatable tuning to second-hand standalone ECUs that their makers no longer support. It starts with the E&E Systems **Freedom FC-03** on Toyota 4A-GE 20V engines (AE86 / AE101 / AE111), and the same process is meant to carry over to every unsupported ECU like it.

**Landing page: [wheelhave.com/ahhpuck](https://wheelhave.com/ahhpuck)** (English / 日本語)

How it works, in one loop: plug a phone into the ECU over USB-C serial, record a baseline run, make one small capped fuel change by hand, then run the candidate and a repeat under the same conditions. A fixed safety gate decides whether to accept, repeat, roll back or abort, and an improvement only counts when the repeat confirms it. AhhPuck is **read-only**: in this release it never writes to the ECU and never proposes ignition changes.

### About Wheel Have

AhhPuck is built by [Wheel Have](https://wheelhave.com), a global car-culture marketplace for wheels, tyres, parts, cars and enthusiast gear, with direct deals and no platform cut. Wheel Have also makes [PuckIt](https://wheelhave.com/puckit), an open-hardware driver alert button for grassroots motorsport. AhhPuck sits alongside PuckIt as one of Wheel Have's tools for people who still drive, fix and tune these cars.

Contact: [contact@wheelhave.com](mailto:contact@wheelhave.com?subject=AhhPuck) · [Instagram](https://www.instagram.com/wheelhave)

### This repository

This is the AhhPuck research and build workspace: the Freedom FC-03 / FCSS protocol research, the read-only analysis tools, the native iOS app, the Mac logger, and the landing page source. It started as a research workspace with one purpose: understand the Freedom FC-03/FCSS ecosystem before connecting to or writing to an ECU, with emphasis on an AE86 chassis running an AE101/AE111 20-valve 4A-GE.

## Current continuation status — 15 October 2026

The active product path is the native iOS app in [`ios-app`](ios-app/README.md). The FCSS/FCST audit is complete and its safe findings are represented in the existing Live, Settings, Maps, Limits, Connection, Data Sources, Runs and Review flows. The app is ready for the first desk capture when the FC-03 and direct serial cable are available.

Current boundaries:

- FC-03 transport: `9600 baud · 7 data bits · even parity · 1 stop bit · no flow control`.
- First request: `?DAT`; documented response: 55-byte payload, with a possible trailing byte retained as raw evidence.
- Captures include timestamps, response length, validation state, ECU profile, vehicle profile, modifications, session kind and capture sources.
- Unverified byte offsets/scaling are refused by the decoder and never promoted into telemetry or tuning decisions.
- ECU map/settings writes, raw command testing and autonomous tuning remain locked.

The latest TestFlight export is `build/testflight-export/AhhPuck.ipa`. The archive/export are valid for App Store distribution; upload still requires App Store Connect authentication on the Mac. See [`docs/continuation-handoff.md`](docs/continuation-handoff.md).

## Public collaboration and security

Original AhhPuck code is intended to be buildable and reusable under the [Apache-2.0 license](LICENSE). Research archives, downloaded pages, FCSS/FCST binaries, fonts, images and trademarks are not automatically covered; see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). Contributors should follow [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and [TERMS-OF-USE.md](TERMS-OF-USE.md). Run `python3 tools/public_release_check.py` before publishing a source snapshot.

Raw research evidence has been moved to the local private sibling repository `/Users/boo2/ahhpuck-evidence`. It is intentionally not part of the open build repository.

## Safety boundary

The first engineering milestone is read-only documentation, file analysis, ECU identification, and serial logging. No ECU write, map modification, or engine-load test is authorized until the original ECU state is backed up and the electrical/sensor configuration is verified.

## Landing page

The live page is [wheelhave.com/ahhpuck](https://wheelhave.com/ahhpuck). Its source is `index.html` at the repository root, with its assets in `landing/`. It is built from the "AhhPuck Landing" Claude Design file: a sticky AhhPuck bar, the hero, the roadmap with an ECU request picker, every-Freedom-unit capabilities, the nine-step loop with its three release modes, evidence, data sources, safety limits, honest status, community, FAQ and the closing call to action. The page is bilingual: all copy lives in `landing/i18n.js` in English and Japanese, the EN/日本語 switch remembers the choice under the same key the PuckIt pages use (`puckit-lang`), and `?lang=ja` opens it in Japanese. It is a static page, so any local server pointed at the repository will serve it, for example `python3 -m http.server 3000`. wheelhave.com/ahhpuck is ported from these files by `scripts/port-ahhpuck-landing.mjs` in the wheelhave-marketplace repository; everything between the `ahp:start` and `ahp:end` markers is copied, and the page's own footer is left out there because the site has one. The app screenshots in `landing/img/` are captures of the mobile prototype running the demo fixture, not ECU data.

## Workspace layout

- `source_files/`, `downloads/`, `extracted/` — private evidence is maintained in `/Users/boo2/ahhpuck-evidence`; this public repo retains derived notes, parsers and implementation contracts only.
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

See [notes/12-fcst-fcss-capability-and-protocol-inventory.md](notes/12-fcst-fcss-capability-and-protocol-inventory.md) for the recovered FCSS/FCST capability inventory.

See [notes/13-fcss-fcst-forensic-audit.md](notes/13-fcss-fcst-forensic-audit.md) for the forensic audit of binaries, imports, strings, configuration, maps, logs and protocol evidence.

See [docs/continuation-handoff.md](docs/continuation-handoff.md) for the current implementation map, verification results, signing/upload status, bench procedure and non-negotiable safety boundaries.

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

For local evidence-backed commands, point the environment variable at the private archive first:

```sh
export AHHPUCK_EVIDENCE_ROOT=/Users/boo2/ahhpuck-evidence
```

Inspect one Freedom map and preserve its structure as JSON:

```sh
python3 tools/fcp_parser.py \
  "$AHHPUCK_EVIDENCE_ROOT/extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP" \
  --json-out notes/AE86-A.parsed.json
```

Inventory all supplied base maps:

```sh
python3 tools/fcp_inventory.py \
  "$AHHPUCK_EVIDENCE_ROOT/extracted/base_maps/BASE MAPS - FC OE DATA" \
  --json-out notes/fcp-structure-inventory.json
```

Create a guarded comparison report against the AE111 Blacktop profile:

```sh
python3 tools/fcp_adapter_report.py \
  "$AHHPUCK_EVIDENCE_ROOT/extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP" \
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
