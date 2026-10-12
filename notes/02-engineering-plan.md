# Engineering plan

## Phase 0 — preserve and identify

- Hash original archives.
- Record archive listings and timestamps.
- Record exact ECU label, serial code, connectors, options and conversion harness.
- Identify engine: AE101 Silvertop or AE111 Blacktop; document injectors, fuel pressure, ignition, MAP sensor, TPS, IAT, coolant sensor and idle valve.

## Phase 1 — static file analysis

- Extract printable strings from FCSS/LOGDSP and help databases.
- Determine whether KDATA files are parameter tables, labels, or lookup metadata.
- Compare all FCP files byte-for-byte and by structure.
- Locate map dimensions, axis values, checksums and version/application identifiers.
- Parse SAMPLE.LOG and identify live-data channel labels/scaling.

### Porting milestone completed — Mac foundation

- Preserved the original FCST Windows package and extracted `FCST.exe` without modifying it.
- Confirmed it is a .NET Framework 4.8-era 32-bit Windows desktop assembly, so there is no source-level automatic conversion to Swift.
- Created `mac-app/`, a Swift Package with `FreedomCore` and `freedom-cli`.
- Recovered FCST configuration defaults: learning rate `40`, switch threshold `740 RPM`, latency `0`, stable gain `0.03`, acceleration stable gain `0.8`.
- Added macOS `/dev/cu.*` discovery, serial transport, JSON frame recording, and tests.
- Verified with `swift test`: 2 tests passed.
- ECU writes are intentionally blocked until FC-03 framing, checksum, baud rate and command semantics are verified from captures.

## Phase 2 — communication setup

- Use the documented cable diagram and a known-good isolated USB/RS-232 adapter.
- Start with ECU powered but engine stopped.
- Confirm serial settings without sending writes.
- Capture FCSS traffic for identification and read-only operations.
- Store raw captures with timestamps and adapter settings.

### Existing implementation to study

Study FCST as a reference implementation before writing a new protocol layer. Its documentation indicates that it can connect, display/log data, and edit or assist with injection/throttle maps, while leaving A/F-map handling to FCSS. This may reduce the amount of protocol work required, but its lack of complete parameter persistence means FCSS backups remain authoritative.

## Phase 3 — protocol model

- Identify request/response framing, command IDs, lengths, checksums and error responses.
- Correlate each request with the FCSS screen/action that generated it.
- Reproduce only identification and read commands in a separate tool.
- Validate that repeated reads are identical and non-destructive.

## Phase 4 — backup and viewer

- Implement ECU identification.
- Implement complete readback of configuration, coefficients, maps and learned values.
- Save raw binary plus decoded JSON/CSV.
- Build a map viewer/comparator; never edit the raw backup.

## Phase 5 — AE86 20V calibration research

- Compare supplied AE86 base maps against the seller’s `Ab-1EU` application.
- Find or obtain AE101/AE111-specific base data.
- Separate Blacktop and Silvertop assumptions.
- Validate injector, sensor, ignition and sequential-injection settings before using any map as a starting point.

## Phase 6 — controlled tuning assistance

- Add wideband AFR and engine-log import.
- Implement fuel-only correction suggestions first.
- Apply strict RPM/load/temperature/AFR limits and a rollback mechanism.
- Keep ignition changes manual until timing and knock monitoring are proven.
- Test on a stationary/low-risk procedure, then dyno/road validate with professional safeguards.

## Phase 7 — validated optimization product

- Treat `notes/03-safe-optimization-spec.md` as a release gate.
- Add provenance metadata to every imported map and tune log.
- Build a deterministic AFR-error proposal engine before adding AI explanations.
- Require exact vehicle/hardware identity and a complete immutable backup before enabling recommendations.
- Keep ignition optimization locked until calibrated knock monitoring is present.
- Validate every accepted change on controlled equipment and retain a known-good rollback map.
