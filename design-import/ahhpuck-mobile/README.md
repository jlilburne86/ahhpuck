# Handoff: AhhPuck Mobile (iOS) — read-only ECU telemetry & supervised tuning assistant

## Overview
AhhPuck is an iPhone app for owners and tuners of Toyota 4A-GE 20V (AE86/AE111 "Blacktop") cars running a Freedom FC-03 ECU. It reads live ECU telemetry over USB-C serial (9600 8N1), records repeatable test runs, compares a baseline against a candidate, and recommends the smallest safe next fuel change. **In this release the app never writes to the ECU and never proposes ignition changes.** A deterministic safety gate makes every decision. An on-device analyst explains decisions but never makes them.

Every screen answers one of four questions: *what happened? can we trust the data? why did it happen? what's the safest next step?*

Source repo: github.com/jlilburne86/ahhpuck. Read `docs/product-design-overview.md`, `docs/iphone-live-monitoring-architecture.md` and `config/tuning-safety-policy.json` for domain rules and thresholds.

## About the design files
The files in this bundle are **design references built in HTML**: prototypes that show the intended look and behaviour. They are not production code to copy. Rebuild them in the target environment. **SwiftUI is recommended**, given the iPhone-only scope, Live Activities and Core Motion. Use the codebase's existing patterns if there are any.

## Fidelity
**High fidelity.** Colours, type, spacing, copy and interactions are final. Recreate them pixel-accurately. All numbers on screen are demo data, generated from formulas in the prototype's logic class. Replace them with real telemetry and assessment outputs.

## Files
| File | What it is |
|---|---|
| `AhhPuck Mobile Build.dc.html` | **Source of truth (English).** 43 screens (S01–S43; S34–S43 added in v1.2) in flow order, plus Foundations (F00) and the colour system (F01). Open in a browser; needs `support.js` next to it. Takes about 20 s to load because it is one large page. The `live` tweak (off by default) animates demo telemetry. |
| `AhhPuck Mobile Build JA.dc.html` | The same screens in Japanese. The language pill on the header, S01 and S32 switches between the two files. |
| `ahhpuck-i18n.js` | **String catalog** (EN key → JA), about 850 entries plus regex rules for strings with numbers in them. Use it to seed `Localizable.xcstrings`. |
| `AhhPuck Platform Plan.dc.html` | Page-by-page plan: purpose, data shown, and the gate each page enforces. |
| `support.js` | Runtime for the prototypes only. Not part of the build. |

## Navigation
- **Tab bar (5 roots):** Live · Map · Runs · Review · Garage. Height 82. Active tab #FFFFFF at weight 600, inactive #6F7377, 11 px.
  - Live → S06 (with S07/S08 states), S04 connection sheet via the status bar.
  - Map → S09, S21.
  - Runs → S30 ledger (root) → S19, S20, S28/S29, S31.
  - Review → S27 gains (root) → S22, S23, S24, S25, S26; experiment flow S15 → S16 → S17 → S18.
  - Garage → S32 → S02, S03, S33.
- **First-run flow:** S01 Welcome → S34 How it works (4 steps) → S35 Permissions → S36 Hardware guide (ECU first) → S04 Connect (errors: S37) → S02 Profile → S03 Phone mount (optional) → S40 Coach marks on the first visit to Live.
- **Help:** S42 Glossary from Garage, and from a long-press on any term. S41 "Why is this locked?" opens from any gated button.
- **Full-screen modals, no tab bar:** S11 Recording, S12 Critical alert, S18 Approval. S12 can appear on top of any screen.
- **Core loop:** S02 Profile → S04 Connect → S05 Preflight → S10/S11 Baseline → S15 Proposal → S16 Expected → S17 Concerns → S18 Approve → S11 Candidate + repeat → S22 Assess → S25 Accept / Repeat / Rollback / Abort → repeat the loop.

## ECU capability profiles (S43) — limits come from the ECU, not the app
Every connected unit gets a **capability profile**, built from its silver label code and one captured session. Profiles are community-maintained JSON. Each field, setting and map has exactly one state:

| State | Meaning | Visual |
|---|---|---|
| `verified` | Decoded and confirmed against a real capture | green chip ✓ |
| `unverified` | Visible in the data, but scaling not yet proven | amber outline ◐ |
| `not_in_ecu` | This unit doesn't provide it (an ECU limitation) | fault hatch ⌀ |
| `not_decoded` | The ECU sends it but nobody has decoded it yet (an app/community task) | grey outline … |
| `unknown` | Unit not identified yet | grey ? |
| `policy` | Set by the AhhPuck safety policy, not by the ECU | filled grey ■ |

**Limits are derived from the profile:**
- No verified ignition scaling or knock signal → ignition proposals unavailable.
- Self-learning modes present → they must be OFF during tests.
- Narrowband O₂ only → lower assessment confidence.
- A program-channel dial → baseline and candidate must use the same position.
- Policy limits (fuel step 2.0%, max RPM, writes locked) are shown separately with the ■ tag.

Suggested schema: `{ id, family, labelCode, coupler, loadType, firmware, serial:{baud, format}, channels:[{key, state, scaling, evidence, source}], settings:[…], maps:[…], derivedLimits:[{key, reason, origin:'ecu'|'engine'|'policy'}] }`.

**Serial format is 9600 7E1** (corrected everywhere from 8N1). The S33 frame layout is illustrative. The real exchange is a "?DAT" poll (4-byte request, 55-byte reply), pending verification.

## Data sources & data contract
**The ECU is the main source.** The phone adds dynamics only. Add-on sensors fill the gaps the ECU leaves. Every value shows a source tag (ECU / PHONE / EXT) next to its evidence tag.

**Rule:** the safety gate, proposals and assessments use **ECU and EXT data only**. Phone data is never used to make a decision. With no ECU connected the app runs in **phone-only mode** (S39): engine values show "—", runs save as phone-only, and there is no assessment and no proposal.

| Field | Source | Rate | Evidence (today) | Used by gate | Fallback / note |
|---|---|---|---|---|---|
| RPM | ECU | 31 Hz | OBSERVED | Yes | — |
| TPS / load | ECU | 31 Hz | OBSERVED | Yes | Load strategy comes from the S02 profile |
| Lambda | ECU narrowband O₂ (mV) | 31 Hz | INFERRED | Yes, at lower confidence | **Wideband EXT recommended**; it replaces the ECU O₂ when fitted |
| Coolant temp | ECU | 31 Hz | INFERRED (offset −40 °C unconfirmed) | Yes | — |
| Intake temp | ECU | 31 Hz | INFERRED | Yes | When implausible: FAULT, excluded (S08) |
| Ignition advance | ECU | 31 Hz | UNVERIFIED | **No**, display only | Scaling unknown |
| Battery voltage | ECU | 31 Hz | OBSERVED | Yes | — |
| Knock | ECU | 31 Hz | OBSERVED | Yes (any event = STOP) | — |
| Vehicle speed | ECU | 31 Hz | OBSERVED | Yes | Cross-checked against GPS; flagged if the gap is over 3% |
| Oil pressure | EXT | 10 Hz | OBSERVED | Yes | Not reported by the FC-03 |
| Fuel pressure | EXT (optional) | 10 Hz | — | Yes, when fitted | Otherwise "not measured"; lowers confidence |
| GPS speed / position | PHONE | 1 Hz | INFERRED / OBSERVED | No | Route trace, speed cross-check |
| Long / lat g, yaw | PHONE (Core Motion) | 100 Hz | OBSERVED if the mount is calibrated | No | Run-consistency check, power estimate |
| Power / accel estimate | PHONE | derived | INFERRED ±3% | No | Always labelled as an estimate |

**Staleness:** the timestamp of each field is checked separately: under 1 s live, 1–3 s stale, over 3 s lost (S07). **Protocol:** the FC-03 frame layout is in S33. Header 0xA5, length, then fields, then XOR checksum over bytes 1–10. Bytes 8–10 are still being decoded.

## Design tokens
Fonts:
- **Barlow Condensed** (500/600/700) for numerals and titles.
- **IBM Plex Mono** (400/500/600) for labels and data.
- **IBM Plex Sans** (400/500/600) for body text.
- **IBM Plex Sans JP** (400–700) as the Japanese fallback in every stack.

### Colour — status (reserved; never decorative; always paired with a glyph and a word)
| Token | Hex | Glyph / word | Use |
|---|---|---|---|
| status/ok | #6FD087 | ✓ OK | Within limits, check passed, gain verified by a repeat |
| status/caution | #F5AE39 | ! CAUTION | Near a limit, repeat needed, an unknown field blocking a step |
| status/critical | #F75D59 | ✕ STOP | Stop, abort, telemetry lost |
| status/critical-bg | #9E141E | — | Full-screen S12 background |
| status/stop-button | #E64343 | STOP | S11 stop button |
| decision/rollback | #F1944F | ↺ | Rollback decision only |
| status/fault | hatch #3A3E42 / #24272A, 135°, 4 px | ⌀ FAULT | Implausible sensor. Excluded from assessment, never shown as red or green |
| status/stale | #24272A, text #8B8F93 | ◷ | Data older than 1 s |

### Colour — data
| Token | Hex | Use |
|---|---|---|
| trace/baseline | #7D8287 | Baseline trace; "now" ticks on range bars |
| trace/candidate | #BE85F9 | Candidate trace, expected ranges (55% fill + 1 px solid stroke), unproven gains (hatched) |
| trace/repeat | #BEBDF7 | Repeat trace |
| target | #66CFE1 | Lambda target and goal lines, always dashed |
| map/rich | #244B6B → #0080D7 | Rich error, scaled from 1.5% to 6% |
| map/on-target | #31623D | Error within ±1.5% |
| map/lean | #E09036 (text #111) | 1.5–3.5% lean |
| map/very-lean | #DB423C | More than 3.5% lean |
| map/no-data | #141517, "·" #3A3E42 | Unvisited cell; the app makes no claim about it |
| map/coverage | #1C2024 → #CCD2D7 | Hit count from 0 to 50+, single hue |
| gauge band | stop #6A2C29 · caution #845A0F · ok #31623D · marker #FFFFFF | Gauge tiles |

### Colour — neutrals
- **Backgrounds:**
  - bg/canvas #1C1D1F
  - bg/screen #0D0E0F
  - surface/card #151719
  - selected row #1C1F22
  - raised/track #24272A
  - disabled #2A2D30
- **Borders and dividers:**
  - border/card #23262A
  - border/control #2F3336
  - divider #1D2023
- **Text:**
  - primary and selection #E8E6E1
  - secondary #CFD2D4
  - tertiary #A9ADB1
  - label #8B8F93
  - faint #6F7377

**Rules:**
- Selection, ticked boxes, progress and the active tab are **white**, never a status colour.
- Evidence tags (DOCUMENTED / OBSERVED / INFERRED / UNVERIFIED) use **neutral greys only** (#E8E6E1 / #CFD2D4 / #A9ADB1 / #8B8F93).

### Type scale
- Hero numeral: Barlow 600, 64–110 px, line-height 0.9, tabular figures.
- Screen title: Barlow 700, 24.
- Tile value: Barlow 600, 22–26, with the unit at 14 in #8B8F93. Never wrap; use `white-space: nowrap` (`.lineLimit(1)`).
- Label: Plex Mono 400, 9–11, uppercase, #8B8F93.
- Data: Plex Mono 400–600, 11–14.
- Body: Plex Sans 400/600, 12–15, line-height 1.45.
- Japanese: never letter-space, never force uppercase. Use `line-break: strict`. Mono labels fall back to Plex Sans JP.

### Spacing, radii, frame
- **Frame:** 390×844 (iPhone 14/15/16). Status bar 50. Screen gutter 18. Gap between cards 10. Inner gaps 4/6/8/10/12. List rows padded 9–11 × 12.
- **Radii:**
  - tag 4
  - map cell 3–4
  - chip 8
  - tile or list 10–12
  - card 12–14
  - button 14
  - Live Activity 22
  - device 48
- **Card:** #151719, 1 px #23262A border, radius 12, padding 12/14.
- **Buttons:**
  - Primary: height 52, radius 14, 15 px weight 600, #E8E6E1 background, #111 text.
  - Gated: #2A2D30 background, #6F7377 text. The label states what is missing, e.g. "3 manual checks left".
- **Shadows:** none in the UI. The device mock uses 0 30 60 rgba(0,0,0,.4) for presentation only.

## Screens
Each entry gives the purpose, key components, and the gate (what the screen blocks) or behaviour. Exact copy is in the HTML and in `ahhpuck-i18n.js`.

**Onboarding**
- **S01 Welcome & safety boundary**
  - Shows a two-column card of what the app does and refuses to do, and legends for the evidence tags.
  - Gate: the CTA is disabled until the acknowledgement is ticked. Store the acknowledgement with the operator profile.
  - Has the EN/JA language pill.
- **S02 Vehicle profile** ("Engine passport")
  - A 7-step chip form: chassis → engine → ECU label → load strategy → injection → ignition → objective. A progress bar of 7 segments (current step white). The summary list is tappable to jump to a step.
  - "Unknown" is a valid answer. It is tagged "BLOCKS PROPOSAL" in amber and blocks S15.
- **S03 Phone mount calibration**
  - A 160 px spirit-level circle, then four guided steps.
  - Quality None / Low / Medium / High maps to red / amber / amber / green.
  - Below High, all g-force data is flagged low-confidence app-wide.

**Connect**
- **S04 Connection & identity**
  - A five-step state machine: cable → port open → bytes → valid frames → ECU identified.
  - Four stat tiles: frames, dropped, stale, last receive. ECU identity is tagged INFERRED.
  - A permanent WRITE LOCK row that cannot be toggled. A raw byte ticker.
- **S05 Preflight**
  - Automatic checks shown as glyph squares (✓ ! ✕ –). "Not measurable" is grey, lowers confidence, and does not block.
  - Four manual checkboxes. Gate: Start recording is enabled only when all four are ticked.

**Drive & capture**
- **S06 Live dashboard**
  - An RPM hero with a 7k limit bar (the red-line zone is hatched), and lambda actual vs target with a sparkline.
  - Six gauge tiles, each with a three-band bar and a state label (✓ OK / ! CAUTION / ✕ STOP) whose colour follows the threshold.
  - A telemetry health strip.
- **S07 Stale / lost telemetry**
  - Under 1 s: live.
  - 1–3 s: amber banner "! Data stale"; values turn #8B8F93 and show their age.
  - Over 3 s: red banner "✕ Telemetry lost · run paused"; values show "—" with the last value kept. A critical alert fires if recording.
  - Never show a frozen value as if it were current.
- **S08 Sensor health**
  - Rows show the value, then a status chip 74 px wide.
  - FAULT (hatched, value struck through, excluded) is distinct from STOP (a real reading past a limit).
  - Tapping a row shows the detail card with its note and range.
- **S09 Map trace**
  - A 12×10 RPM × load grid with a white 2 px outline on the current cell. Toggle between lambda error and coverage.
  - Shows the legend, and readouts for the cell, its hits and its mean error.
- **S10 Run setup**
  - Type: Baseline, Candidate or Repeat.
  - Condition fields are tagged EDITABLE (baseline), FROM BASELINE (candidate) or LOCKED (repeat; any change is flagged in Review).
- **S11 Recording**
  - RPM at 110 px, lambda error at 64 px, a coverage bar of 10 cells, a 132 px round STOP button.
  - No navigation, the screen is locked against stray taps, and alerts come by sound and haptics.
  - The saved state shows duration, frames and hash.
- **S12 Critical alert**
  - A full-screen #9E141E takeover with the trigger and three readouts.
  - Cannot be acknowledged while the condition is active. After acknowledging, tuning is locked until S13 is completed.
  - Triggers: knock, lean under load, overheat, low oil, low voltage, RPM/trigger anomaly, telemetry loss.
- **S13 Investigation log**
  - Shows the event, then a likely-cause chip, then a checklist that needs at least 2 items, then sign.
  - Choosing the cause "Unknown" keeps tuning locked; the next step is a baseline repeat. The banner turns red → green on unlock.
- **S14 Notifications & Live Activity**
  - The lock-screen Live Activity shows RPM, lambda error and coverage.
  - Notification types, each with two actions:
    - Critical
    - Assessment ready
    - Telemetry gap
    - Preflight waiting

**Experiment**
- **S15 Proposal**
  - An 8×6 grid. Only cells with at least 10 samples can be selected; selected cells are white and show a capped ± suggestion.
  - The cap is ±1.5% per cell, and ignition is never proposed.
  - Readiness bars: ≥80 green, ≥60 amber, otherwise red. Labelled as "readiness", never "perfection".
- **S16 Expected result**
  - A step-size picker (±0.5–1.5%) recalculates everything.
  - A headline range and an error-by-RPM chart (now, plus the predicted band).
  - Seven range-bar metrics, each with a verdict:
    - ✓ CLEAR GAIN: the whole expected range clears the run-to-run noise.
    - ≈ WITHIN NOISE
    - ! TRADE-OFF
    - ! NEAR LIMIT
  - Steps above ±1.0% drop confidence to LOW.
- **S17 Concerns & rollback plan**
  - An accordion of concerns sorted by severity (HIGH red, MED amber, LOW grey). Each concern must be opened before Continue is enabled.
  - Shows the stop criteria and the rollback target with its hash.
- **S18 Supervised approval**
  - Six confirmations, then press-and-hold to sign (about 0.7 s; the fill is white and turns green when signed).
  - The copy states clearly that this creates a record only and does not write to the ECU.

**Analyse & decide**
- **S19 Run overlay**
  - Lambda vs target for baseline, candidate and repeat, plus RPM and ignition. Scrub with a shared cursor.
  - Readouts per run, and the run hashes.
- **S20 Gain curve**
  - Mode: power (estimated from the phone accelerometer, ±3%, tagged INFERRED), acceleration, or lambda error.
  - Shows the noise band and a cursor delta with a verdict: REAL GAIN, WITHIN NOISE or LOSS.
- **S21 Map before / after**
  - Drag the wipe divider to compare. Or switch to change mode: ▼ improved (green), ▲ worse (orange).
  - A stacked count bar of improved / same / worse.
- **S22 Assessment**
  - The gate's decision comes first: Accept, Repeat, Rollback or Abort. Then six checks with glyph squares, the max next increment, and ignition shown as locked.
  - The operator may only choose a *more cautious* option than the gate.
- **S23 Expected vs actual**
  - The S16 range bars plus a white "actual" dot. Verdicts: ✓ IN RANGE, ✓ BETTER THAN EXPECTED or ! MISSED.
  - Shows a prediction track record of the last 10. When predictions keep missing, the ranges should widen.
- **S24 Result dial & objective radar**
  - A semicircle dial from 8% (left) to 0% (right) showing the expected arc, previous tick, goal tick and actual needle.
  - A 6-axis radar (before / expected / actual) with toggleable layers. The demo honestly shows repeatability getting worse.
- **S25 Decision flows**
  - Accept (green ✓), Rollback (#F1944F ↺) or Abort (red ✕). Each shows the steps of what happens next, then a confirm button, then a recorded state.
- **S26 Analyst**
  - Suggested questions with answers. Every claim carries a source chip (↗).
  - Read-only. It can never change the decision or the increment.

**Progress & records**
- **S27 Gains dashboard**
  - A 236 px ring (r 96, stroke 20) showing the share of the distance to the goal. Green = verified, violet = unproven, track #1C1F22. Animates in over about 2.2 s with an ease-out cubic.
  - Before/after bars for this step, and a 38-dot grid of cells on target.
- **S28 Gain bridge**
  - A waterfall from baseline to now, then the projected next step, with a dashed cyan goal line.
  - Gain-per-step columns and a steps-to-goal track.
- **S29 Progress bars:** an alternative to S28. **Pick one** before building.
- **S30 Learning ledger:** experiment cards with a decision colour stripe, and filter chips. Tuner mode adds hashes.
- **S31 Session detail & export:** the file list with hashes, operator notes, and Export (a zip via the share sheet; no cloud).
- **S32 Garage & settings**
  - Vehicle row, Units (λ/AFR), Density (Owner/Tuner), Language (English/日本語).
  - Protection thresholds, each with its evidence tag. Loosening a threshold needs a reason and is logged.
- **S33 Raw frames (tuner):** a 12-column hex grid. Tapping a column shows the field, evidence tag and note. Unknown bytes are amber, kept raw, and never used for assessment.

**Onboarding, help & data (v1.2)**
- **S34 How it works:** four steps (Connect, Baseline, Change, Decide). Each has a title, a body, "You do" and "AhhPuck does" columns, and a dashed note line. Tap a pill to jump to a step. The last button is "Get started".
- **S35 Permissions:**
  - Notifications and Live Activities are recommended.
  - Location and Motion are optional. Each says "never used to decide".
  - The Allow button turns into "✓ Allowed" (green text, outline).
  - A privacy card: no account, no cloud.
- **S36 Hardware guide:** Cable, then Port, then Plug in, then Check. Photo placeholders are 170 px tall; **real photos are needed** of the tested adapter, the FC-03 connector location and the cable routing. Step 4 runs the S04 connection check. Phone mount setup comes after, and is optional.
- **S37 Connection errors:** five cases.

  | Case | Banner | What the app does |
  |---|---|---|
  | Cable not recognised | red ✕ | Nothing is recorded until the port opens |
  | Wrong ECU identity | amber | Proposals locked |
  | Frames invalid (checksum) | amber | Bad frames dropped |
  | Phone too hot | amber | Runs below 25 Hz flagged |
  | Low battery | amber | Run auto-saves and closes at 5% |

  Each case shows three stat tiles, what it means, numbered fixes, an impact line and a CTA.
- **S38 Data sources:** rows tagged ECU (white), PHONE (grey) or EXT (outline). Tap a row for its fields with evidence tags and whether the gate uses it. Cross-checks: ECU vs GPS speed, pull consistency, and the lambda source (wideband recommended).
- **S39 Phone-only Live:** an amber banner with a Connect ECU button, a GPS speed hero, phone g-force tiles, engine tiles showing "—" ("ECU not connected"), and phone-only recording.
- **S40 Coach marks:** three tips with a white 2 px spotlight and a 999 px rgba(0,0,0,.68) scrim around it. Tooltip card #E8E6E1 with "Skip tips" and "Next/Done". Show once, on the first visit to Live.
- **S41 "Why is this locked?" sheet:** a bottom sheet (radius 22) listing every condition with a glyph square, a detail line and a deep link. The CTA reads "N to clear · proposals locked" until all items are ✓. Use this sheet for **every** gated button.
- **S42 Glossary:** search in English or Japanese, an accordion of 12 terms, and "Used on Sxx" references.

## Interactions & behaviour
- **Gated buttons** always say what is missing ("Open each concern to continue (2/4)", "4 confirmations left").
- **Hold to sign:** pointer down fills at 6%/40 ms. Releasing early resets the fill. At 100% the state is signed.
- **Telemetry ages:** under 1 s live, 1–3 s stale, over 3 s lost (see S07). Assessment ignores samples older than 1 s.
- **Units:** λ = AFR / 14.7. Every display updates with the setting, e.g. "λ 0.95" becomes "14.0 AFR".
- **Density:** owner mode shows plain-language summaries. Tuner mode adds hashes, σ, frame counts and S33.
- **Animations:**
  - Ring: about 2.2 s, ease-out cubic.
  - Dial needle and radar: tied to the same easing.
  - Avoid any other motion; this is a glance-while-driving product.
- **In-car screens** (S06, S11, S12): touch targets ≥64 px and at most three primary numbers.

## State (minimum)
- `vehicleProfile` (7 fields, each value or `unknown`)
- `ack`
- `calibration {quality, step}`
- `connection {stage 0–5, frames, dropped, lastRx}`
- `preflight {auto[], manual{}}`
- `run {type, conditions, locked}`
- `recording {active, startedAt, frames, coverage}`
- `alert {active, acknowledged, investigationId}`
- `proposal {cells[], stepSize}`
- `concerns {opened{}}`
- `approval {checks[6], signed}`
- `assessment {decision, checks[], maxIncrement}`
- `predictions[] {metric, lo, hi, actual}`
- `ledger[]`
- `settings {units, density, language}`

## Internationalisation (EN / JA)
- Ship English and Japanese from day one.
- Use `ahhpuck-i18n.js` as the starting catalog. Move to keyed strings in the build (the prototype keys on the English text). The `rx` rules show which strings need pluralisation or number placeholders.
- **Terminology** (keep consistent):

  | English | Japanese |
  |---|---|
  | Baseline | ベースライン |
  | Candidate | 候補 |
  | Repeat | リピート |
  | Accept | 採用 |
  | Rollback | ロールバック |
  | Abort | 中止 |
  | Preflight | 走行前点検 |
  | Lean / Rich | リーン / リッチ |
  | Knock | ノッキング |
  | Coolant | 水温 |
  | Intake temp | 吸気温 |
  | Oil pressure | 油圧 |
  | Fuel pressure | 燃圧 |
  | Injector duty | インジェクター開弁率 |
  | Ignition timing | 点火時期 |
  | Coverage | カバレッジ |
  | Noise | ばらつき |
  | Evidence | 根拠 |
  | Documented / Observed / Inferred / Unverified | 文書確認済 / 観測 / 推定 / 未検証 |
  | Safety gate | 安全ゲート |

- **Do not translate** hashes, IDs (EXP-04, S12), units, part codes (FC-03, Ab-1EU) or the raw hex grid.
- **Dates:** ja-JP style (10月13日) in Japanese; "13 Oct" in English. Numbers keep "," grouping in both languages.
- **Layout:**
  - Japanese strings run roughly 0.8–1.2× the English width, but each character is wider. Chips and status chips must hug their content or truncate; never wrap mid-word.
  - Check S16/S23 metric rows, S08 chips and the S22 decision grid in Japanese.
- **Text:** no uppercase transforms and no letter-spacing on Japanese text.

## Assets
None. All charts are drawn as vectors and should be rebuilt natively (Swift Charts or Canvas). No icon font is used: glyphs are Unicode (✓ ! ✕ ⌀ ◷ ↺ ↗ ▲ ▼). Fonts come from Google Fonts: Barlow Condensed, IBM Plex Mono, IBM Plex Sans, IBM Plex Sans JP.

## Content still needed
- Photos for S36: the tested adapter, the FC-03 serial connector, and the cable routing.
- A **tested adapter list** (chipsets) and the confirmed FC-03 connector location from the hardware team.
- A legal **disclaimer** (road use, liability) for first run and Settings. Not yet designed.

## Open decisions for the build
1. S28 vs S29: pick one progress view.
2. Whether S06 tiles can be rearranged in tuner mode, and the landscape dash-mount layout (not yet designed).
3. Still to design: notification settings, alert history, empty states, map-cell drill-down.
