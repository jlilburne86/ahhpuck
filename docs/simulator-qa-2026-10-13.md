# Simulator product review — 2026-10-13

Device: iPhone 15 Pro Simulator  
Build: `FreedomIOSApp` Debug  
Fixture mode: local first-trial replay via `-loadFixture`  
Safety mode: read-only; no ECU transport or write path

## Walkthrough completed

1. Installed and launched the native app.
2. Reviewed the empty/readiness state.
3. Added a controlled `-loadFixture` launch path for repeatable QA.
4. Reviewed the populated Live screen with baseline replay data.
5. Verified the lambda trace renders and uses the replay frames.
6. Verified the RPM/load, evidence-quality, and causal panels are part of the
   populated Live flow.
7. Confirmed the app remains read-only and the readiness state is visible.

Screenshots:

- [`freedom-qa-start.png`](../artifacts/freedom-qa-start.png) — empty/readiness
  state.
- [`freedom-qa-fixture.png`](../artifacts/freedom-qa-fixture.png) — populated
  replay state.

## What worked

- The app opens to a clear protection/readiness state.
- The user sees what is missing before a test can proceed.
- The fixture produces a real trace rather than placeholder graph artwork.
- The dashboard separates engine telemetry from the later phone-context section.
- Read-only status is visible at the top of the screen.
- The visual language is calm, high-contrast, and legible at the default iPhone
  size.

## Findings and improvements

### P1 — Populate the dashboard from actual frames

The first implementation displayed static RPM, lambda, and coolant values even
when no run was loaded. This was misleading. The dashboard now derives these
summary values from the latest baseline frame and shows `—` when no evidence is
available.

Next improvement: derive all summary cards from the active run or live snapshot,
and label whether the value is live, replay, stale, or unavailable.

### P1 — Bring the causal explanation above the fold

The first screen is vertically long. On an iPhone, the user sees the readiness
card and the beginning of the lambda graph before reaching RPM/load and causal
interpretation.

Next improvement: add a compact “What changed / Why it matters / Next check”
summary immediately below the readiness card, with the detailed graphs below it.

### P1 — Add a graph mode switch

The current Live screen stacks graphs vertically. That is useful for review but
too slow in-car.

Next improvement: provide two modes:

- **Glance:** protection, current values, one trend, next action.
- **Engineer:** synchronized graphs, cursor inspection, quality, and coverage.

### P1 — Complete language consistency

The main shell switches between English and Japanese, but some generated
assessment strings and state labels still come from hardcoded English values.

Next improvement: localize every user-visible assessment enum, concern, toast,
button, and graph annotation through the same `appText`/resource layer. Add an
automated UI check for zero mixed-language labels in each mode.

### P2 — Make the graph actionable

The lambda trace currently communicates trend and target but not the exact frame
or operating context.

Next improvement:

- tap/drag cursor;
- show timestamp, RPM, load, lambda, coolant, pressure, and knock at cursor;
- display target error as a shaded band;
- mark gaps and protection events directly on the trace.

### P2 — Add tuner evidence views

The current first-trial fixture is intentionally small. A real tuner still needs:

- RPM/load cell coverage heatmap;
- baseline/candidate/repeat overlays;
- residual/delta view;
- event timeline;
- sensor plausibility ranges;
- sample-rate, gap, jitter, and provenance details.

### P2 — Make fixture status impossible to confuse with a real car

The replay is labelled in the Run flow, but the Live surface should make it
unmistakable that the data is local replay and not a connected vehicle.

Next improvement: add a persistent `LOCAL REPLAY · NO ECU` badge beside the
read-only state and make the transport source part of the graph header.

### P3 — Improve review navigation

The Review flow contains the right decision concepts but needs a clearer visual
sequence: evidence → interpretation → proposal → approval. The current screen
is more form-like than an experiment review.

Next improvement: introduce a four-step review rail and keep the decision card
sticky while the operator inspects detailed evidence.

## Product decision

The current build is suitable for continued product development and replay
testing. It is not yet suitable for live vehicle validation because the actual
FC-03 capture path, channel semantics, synchronized safety instrumentation, and
fault-injection validation are not complete.

The next implementation slice should be:

1. Glance/Engineer display modes.
2. Persistent replay/live provenance badge.
3. Cursor-linked synchronized graph.
4. RPM/load coverage heatmap.
5. Full localization pass.
