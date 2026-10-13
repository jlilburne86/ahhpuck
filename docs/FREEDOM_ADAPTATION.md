# Freedom adaptation layer

AhhPuck is not a generic dashboard that happens to display a BMW tune. The
product target is a Freedom ECU workflow for Toyota AE86 20V and 16V engines,
starting with preserved, user-owned exports and logs.

The reverse-engineered/adaptation work belongs between raw Freedom artifacts
and the deterministic diagnostic engine:

```text
preserved Freedom export
        ↓
exact firmware + channel/units contract
        ↓
AE86 engine passport and evidence state
        ↓
deterministic readiness + diagnostic findings
        ↓
AI-ranked hypotheses and next measurement
        ↓
human-approved incremental experiment ledger
```

The AI can explain findings, rank competing causes, compare repeat runs, and
propose the next discriminating measurement. It cannot silently convert an
unknown Freedom field into a known one, override a PAUSE/STOP gate, emit a
calibration patch, or write to the ECU. The Freedom ECU and its local
protections remain the real-time safety layer.

The current `FreedomExportAdapter` is the restored contract boundary. It
preserves raw rows, records exact firmware and units, exposes unresolved
channels, and reports `write_capability: false`. Alias matches are intentionally
not treated as verified semantics until they are checked against the exact
Freedom export revision and reviewed examples.

The rusEFI BMW #1813 artifact remains a research/reference fixture for parser
and visualization development. It is not the AE86 product profile and must not
be presented as an AE86 calibration.
