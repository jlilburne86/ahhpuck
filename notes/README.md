# AhhPuck research notes

Research notes preserve protocol deductions and experiment outputs. The original evidence archive is kept outside the public repository at `/Users/boo2/ahhpuck-evidence` (with `source_files/`, `downloads/` and `extracted/` underneath it). It must not be overwritten. Set `AHHPUCK_EVIDENCE_ROOT` when using the tools from another local checkout.

Historical paths in older notes and generated JSON intentionally retain their original relative names; resolve them against the private evidence archive.

Important current notes:

- [`07-paddock-fcss-transport.md`](07-paddock-fcss-transport.md) — initial RS-232C transport and capture plan.
- [`11-ecu-unit-label.md`](11-ecu-unit-label.md) — purchased FC-03 label and engine-profile implications.
- [`12-fcst-fcss-capability-and-protocol-inventory.md`](12-fcst-fcss-capability-and-protocol-inventory.md) — recovered FCSS/FCST menus, settings, maps, logs and capability vocabulary.
- [`13-fcss-fcst-forensic-audit.md`](13-fcss-fcst-forensic-audit.md) — forensic audit of binaries, imports, strings, configuration and protocol evidence.

Evidence labels:

- `documented` — supported by a manual, pinout or supplied artifact.
- `observed` — confirmed by a real serial capture or controlled file comparison.
- `inferred` — plausible but not experimentally confirmed.
- `unsafe/unverified` — must not drive ECU writes or tuning decisions.

The next expected artifact is a real desk capture from the FC-03 using the tested cable. Preserve the original bytes, connection settings, ECU label, cable/pin notes and timestamps before analysis.
