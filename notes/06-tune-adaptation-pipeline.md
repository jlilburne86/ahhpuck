# Tune adaptation pipeline

## Principle

Tune data is portable at the meaning level, not necessarily at the file or number level. A Haltech, Link, or Freedom file may use different axes, units, load sources, injector assumptions, correction layers, and map equations. The application must never import a foreign binary file directly into the FC-03.

## Canonical tune model

All imported sources are first converted to a neutral, inspectable model:

- engine profile and vehicle profile;
- fuel type and measured fuel pressure;
- injector flow, dead time, voltage compensation, and fuel-pressure reference;
- load source and units: MAP, absolute pressure, gauge pressure, TPS, MAF, or blended;
- RPM axis and load axis;
- fuel base table and whether values mean VE, pulse width, mass flow, or a vendor-specific coefficient;
- AFR/lambda target table and closed-loop/learning settings;
- ignition table in degrees BTDC plus trigger offset/base timing assumptions;
- throttle/transient, warm-up, battery, atmospheric, VVT, idle, and limiter corrections;
- source file, source provider, version, checksum, author, vehicle, hardware, fuel, and validation evidence.

## Conversion stages

1. **Import**: accept only documented formats or manually entered tables. Preserve the original file unchanged.
2. **Identify**: require a matching engine profile. Flag mismatched chassis, engine generation, injectors, load strategy, fuel, or ignition hardware.
3. **Decode**: translate source-specific tables into the canonical model. Unknown fields remain unknown rather than being guessed.
4. **Normalize**: convert pressure units, temperature units, lambda/AFR representation, injector flow conditions, and axis ordering.
5. **Resample**: interpolate onto the exact Freedom grid only after the FC-03 grid and map semantics are known. Do not extrapolate beyond measured source data without a visible warning.
6. **Adapt fuel**: use the verified Freedom fuel/VE equation and the actual injector data. Target AFR correction must be explicit; do not silently bake it into VE.
7. **Adapt ignition**: preserve degrees BTDC only after trigger offset and base timing are verified with a timing light. Reject a source ignition map when trigger assumptions are missing.
8. **Adapt auxiliary maps**: treat throttle, transient, VVT, idle, warm-up, battery, and atmospheric corrections as separate layers. Never merge them into the base fuel table invisibly.
9. **Review**: show source map, canonical map, proposed Freedom map, difference map, confidence, and all assumptions side by side.
10. **Validate**: run offline checks, then read-only engine checks, then controlled dyno/log validation. Only a human-approved and backed-up map can become a write candidate.

## Freedom-specific requirements

The public FCST description reports map grid limits including 500-RPM steps, 50-mmHg pressure steps, and 5-percent throttle steps. These are useful conversion hints, but the actual FC-03 map definitions, scaling, checksums, and write protocol must be confirmed from FCSS/FCST captures before a converter can write anything.

The public Freedom comparison describes the supplied maps as VE-style base maps and warns that injector-size and target-AFR assumptions affect conversion. Therefore `AE86-A/B/C/D.FCP` can be structural/reference inputs, but they are not universal AE111 Blacktop tunes.

## Confidence and rejection rules

- **Green**: exact engine/hardware/profile match, known units, known injector data, verified axes, and validation evidence.
- **Amber**: compatible engine family but one or more hardware or provenance fields differ; recommendation only.
- **Red**: unknown map units, unknown injector data, unknown ignition offset, forced-induction mismatch, or missing fuel/knock evidence; comparison only, no proposal.

The first implementation should support canonical import, visual comparison, metadata, and fuel-error proposals. Automatic binary conversion and ECU writes come only after the FC-03 protocol and map semantics are verified.

## Implemented local inspection layer

`tools/fcp_parser.py` now parses the supplied text-based `.FCP` files without
changing them. `tools/fcp_inventory.py` records hashes, scalar counts, table
names, and dimensions. `tools/fcp_adapter_report.py` compares an FCP structure
with a target profile and always forces `comparison_only`; it cannot create an
ECU write file. The current AE86 reference maps commonly contain 511 scalars
and four blocks: `IGT` 36×16, `IJM` 72×8, `THM` 36×10, and `ECM` 36×8. These
names and shapes are observations, not semantic assignments.
