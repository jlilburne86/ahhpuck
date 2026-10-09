# Code review — 2026-10-10

Reviewed commit `9292dec` against the AhhPuck North Star (expert diagnostic advisor:
understand state → verified baseline → diagnose → one controlled change → validate).

Evidence labels follow the README: `documented`, `observed`, `inferred`, `unsafe/unverified`.

## Summary

The design docs already describe most of the North Star. The code is an offline research
foundation: it does not yet talk to the ECU, the optimiser cannot reach a distant target,
and several gates treated missing data as passing.

## Findings and fixes

| # | Area | Finding | Fix branch |
|---|------|---------|------------|
| 1 | Current state | Web capture and Mac transport opened 8N1; the Freedom link is 9600 7E1 (`documented`). Mac transport ignored configured parity and data bits. | `fix/serial-7e1` |
| 2 | Current state | No live read; `?DAT` (4-byte request, 55-byte reply, note 09) is the obvious first poll. | open |
| 3 | Current state | No channel inventory: missing sensors are blank, not reported as unmonitored. | partly `fix/fail-closed-safety` (live monitor) |
| 4 | Current state | Freedom's own O2 learning state is not read; app and ECU could both correct fuel. | open |
| 5 | Onboarding | Profile is a browser form nothing else reads; lacks injectors, fuel pressure, wideband, knock source, ECU version; no evidence labels. | open |
| 6 | Onboarding | No baseline step: no readback, hash on read, or two matching warm logs before proposals. | open |
| 7 | Goal | Step halved after every accept: total correction capped near 4%. | `fix/goal-convergence` |
| 8 | Goal | Optimiser only tuned cells ≥ 80 kPa; idle and cruise never tuned. | `fix/goal-convergence` |
| 9 | Goal | No oil channel ⇒ zero proposals, with no reason given. | `fix/goal-convergence` (cruise works without oil; skips explained) |
| 10 | Goal | One lambda target for the whole map (0.90 / 0.88). | `fix/goal-convergence` (per-cell target, labelled default) |
| 11 | Goal | Three different grids; none matched Freedom's 500 rpm × 50 mmHg. | `fix/goal-convergence` |
| 12 | Goal | Purpose scores measure driving style, not the tune. | `fix/goal-convergence` (adds `tune_objective`) |
| 13 | Goal | Gains inside run-to-run noise accepted; runs compared over different cells. | `fix/goal-convergence` |
| 14 | Safety | `tuning_iteration` accepted runs with missing evidence; sparse coverage not in decision. | `fix/fail-closed-safety` |
| 15 | Safety | `safety_gate` defaulted missing channels to safe values; no lean check; empty logs passed. | `fix/fail-closed-safety` |
| 16 | Safety | Completeness passed empty/one-frame logs; iOS and web missed sequence gaps. | `fix/fail-closed-safety` |
| 17 | Safety | Live monitor skipped nil channels; watchdog never fired if no frame arrived. | `fix/fail-closed-safety` |
| 18 | Safety | 1° ignition allowed without knock sensing in required evidence. | `fix/fail-closed-safety` |

## Branch order

`fix/goal-convergence` is stacked on `fix/fail-closed-safety` (both touch
`tools/tuning_iteration.py`). Merge `fix/serial-7e1` and `fix/fail-closed-safety` first, then
`fix/goal-convergence`.

## Not verified here

Swift changes were written without a Swift toolchain; run `swift test` in `mac-app/` and
`ios-app/` before merging. Two existing parser tests need the git-ignored base maps in
`extracted/`.

## Next open items

1. Commit a scrubbed bench capture so decoding can be tested from the repo.
2. Read-only `?DAT` poll with decoded fields carrying evidence labels.
3. Channel inventory and readiness report as the home screen.
4. Shared profile file with evidence labels, loaded by every tool.
5. Baseline capture step: read + hash calibration, two matching warm logs.
