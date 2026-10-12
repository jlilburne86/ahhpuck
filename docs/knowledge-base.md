# Tuning knowledge base

The knowledge base is AhhPuck's definition of a good tune: what a trained calibration
engineer would check, in what order, and what "done" looks like. The AI is measured against
it, not against its own opinion.

- Sources: [`knowledge/source-manifest.json`](../knowledge/source-manifest.json)
- Starter rules: [`knowledge/rule-cards.json`](../knowledge/rule-cards.json)
- Traceability test: `python3 -m unittest tools/test_knowledge_base.py`

## Three rules

1. Every rule traces to a source id in the manifest, with the hardware it applies to.
2. Numbers come from deterministic code; the knowledge base supplies rules and limits.
3. Paid and copyrighted material is used for rules and citations only (`use: cite_only`);
   community manuals need the author's permission beyond a citation (`use: ask_permission`).

## How engineers are taught — the source layers

| Layer | Example sources |
|---|---|
| 1. Engine physics | MIT 2.61; Heywood, *Internal Combustion Engine Fundamentals* (2nd ed., 2018) |
| 2. Engine-management systems | Bosch, *Gasoline Engine Management* (Reif, 2015); Asahara (1995), by the Freedom's creator |
| 3. OEM calibration method | ASAM MCD-2 MC (A2L); model-based calibration and design of experiments |
| 4. Aftermarket tuning method | HPA 10-step process; EFI University; Banish (2007) |
| 5. Hardware facts | Bosch LSU 4.9 datasheet; injector characterisation; ECU protection docs |
| 6. Test standards | SAE J1349 power correction |
| 7. This ECU and engine | Kunugi Runner and cheap garage FCSS manuals; hiro0719jp; JDM Toyota repair manual |

## The documented process (gates)

Each step stays locked until the previous step's exit check passes.

1. Inputs and outputs — every channel plausible at key-on and idle.
2. Trigger — no sync errors; RPM matches an external reference.
3. Base tables — injector flow and dead time, fuel pressure, load source confirmed.
4. Base timing — commanded timing matches a timing light.
5. Start-up — starts and holds idle on the base map.
6. Idle — stable speed and lambda when warm.
7. Steady-state fuel, then ignition — fuel against a lambda target table; ignition only with
   verified knock sensing.
8. Transient and warm-up — no lean spikes on throttle; clean cold start.
9. Full power — dyno or closed venue; power corrected to reference conditions.
10. Validation — road or track logs confirm the result.

Steps 1–7 follow the HPA intro page; step 8 comes from `notes/03-safe-optimization-spec.md`.

## Layers to build

| Layer | Holds | Status |
|---|---|---|
| Source register | Every source with layer, licence use and hardware scope | `knowledge/source-manifest.json` |
| Rule cards | One checkable rule each, with conditions, action, evidence, source | 7 starter cards; not enforced yet |
| Map description | Freedom's "A2L": table names, axes, units, scaling, address, evidence | To do; shapes only (IGT 36×16, IJM 72×8, THM 36×10, ECM 36×8) |
| Engine profile | Hardware with confirmed / reported / inferred / unknown per field | To do; web form only |
| Process gates | The 10 steps as a state machine | To do |
| Session ledger | Every experiment and verdict; becomes the evaluation set | `tools/ai_analysis_service.py` |

## The goal

A region is "done" when every gate up to it passes and its rule cards pass with repeatable
evidence. This replaces the evidence-weighted "96%" figure with an auditable report: which
rules passed, which failed, and which could not be checked.
