# Contributing to AhhPuck

AhhPuck is an open engineering project around read-only evidence collection for unsupported ECUs. Contributions are welcome when they preserve the safety and provenance boundaries.

## Before opening a change

- Read [`docs/continuation-handoff.md`](docs/continuation-handoff.md), [`SECURITY.md`](SECURITY.md) and [`TERMS-OF-USE.md`](TERMS-OF-USE.md).
- Do not add ECU write commands, map-write controls, raw command consoles or autonomous tuning.
- Do not commit API keys, passwords, certificates, private keys, provisioning profiles, customer data or vehicle-identifying captures.
- Do not add FCSS/FCST binaries, copied manuals, screenshots or downloaded material unless the licence and redistribution permission are documented.
- Keep raw evidence separate from derived interpretations.

## Required for protocol changes

Every new protocol claim must include:

1. Source or capture provenance.
2. Evidence label: documented, observed, inferred or unsafe/unverified.
3. A regression test or a reproducible capture fixture.
4. A clear statement of whether the value may enter telemetry, safety assessment or neither.

## Checks

```sh
swift test --package-path ios-app
python3 -m unittest discover -s tools -p 'test_*.py'
python3 tools/public_release_check.py
git diff --check
```

Keep pull requests small and explain hardware assumptions. A passing simulator build does not prove ECU or cable compatibility.
