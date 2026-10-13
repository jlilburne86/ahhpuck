# Original platform recovery audit

Date: 2026-10-13

## Finding

The original working Freedom platform is present at:

```text
/Users/boo2/ahhpuck-upstream
```

Its current branch is `feat/engine-intelligence-end-to-end`, commit
`5c9b6df`, ahead of `origin/main`. It is the platform that should be treated as
the foundation. The current `engine-intelligence` repository is a later,
reduced read-only workbench and should not replace it.

## What the original platform already contains

| Layer | Existing implementation | Status |
|---|---|---|
| Freedom research | FCSS/FCST archives, manuals, source register, AE86/AE101/AE111 notes | preserved |
| Tune adaptation | `.FCP` parser, map inventory, guarded comparison report, canonical adaptation notes | working read-only inspection |
| Raw evidence | serial capture, session manifest, SHA-256 hashes, immutable inputs | working |
| Deterministic analysis | telemetry stats, quality checks, coverage, repeatability, safety events | working |
| Incremental tuning | baseline → candidate → repeat → assessment, accept/repeat/rollback/abort | working fixture-backed flow |
| AI boundary | evidence explanation and next-measurement ranking downstream of deterministic rules | working offline contract |
| Experiment ledger | append-only iteration and approval records | working |
| Native app core | SwiftUI dashboard, readiness, live/read-only state, trial assessment, approval gates | working package-backed prototype |
| Mac transport layer | serial abstraction, protocol recorder, watchdog/live safety monitor | working guarded foundation |
| Landing/workbench | bilingual landing page and workstation/mobile views | working source |

## Validation performed

From `/Users/boo2/ahhpuck-upstream`:

- Python tools: 30 tests passed.
- iOS Swift package: 10 tests passed.
- Mac Swift package: 7 tests passed.
- Current upstream commit: `5c9b6df feat: make raw capture sessions verifiable end to end`.

## Important product behavior already implemented

The original platform does not treat AI as an ECU controller. The intended
loop is:

```text
profile → immutable baseline → bounded proposal → human approval
→ controlled run → raw + normalized telemetry → deterministic assessment
→ accept a smaller step / repeat / rollback / abort → learning ledger
```

The AI explains deterministic evidence and ranks the next discriminating
measurement. It cannot invent map semantics, bypass a safety gate, enlarge an
increment, or authorize a write.

## What was lost in the reduced repository

The current repository retained generic readiness and diagnostics, but omitted
or replaced the original platform's core:

- Freedom FC-03/FCSS identity and transport model;
- `.FCP` structure and map adaptation workflow;
- raw serial capture and verifiable session bundles;
- candidate/repeat assessment and incremental learning ledger;
- native first-trial state machine and approval model;
- original AE86/AE111/20V product context;
- original app screens and landing page assets.

The rusEFI/BMW fixture added later is useful as a parser test, but it is not a
replacement for the Freedom/AE86 foundation.

## Consolidation plan

1. Make `/Users/boo2/ahhpuck-upstream` the source platform, preserving its
   history and working tests.
2. Import the current research additions selectively: source governance,
   broader tuning-visual conventions, local tune corpus metadata, and the
   “Unsupported is not obsolete” product language.
3. Keep the original Freedom adapter and FCP workflow as the authoritative
   engine-specific path. Add the current MSQ parser only as a separate research
   adapter.
4. Move the native app forward from the original SwiftUI trial workflow,
   adding the richer dashboard, map/log visualizations, Japanese localization,
   and AE86 profile screens there.
5. Connect shadow optimization to the original assessment/ledger contracts,
   not to a separate demo-only replay store.
6. Re-run the original Python, iOS, and Mac test suites before each product
   slice, then review the complete workflow in Simulator.

No current feature should be called complete until it can be traced from a
preserved Freedom artifact or log through diagnosis, a bounded experiment, and
the original assessment/ledger flow.
