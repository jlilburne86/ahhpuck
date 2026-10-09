# FreedomMac

Mac-native foundation for an FC-03 / FCSS-compatible tool.

This is a clean compatibility layer, not a direct conversion of the Windows executable. The original FCST package is preserved under `../source_files/FCST`; its extracted .NET assembly is the behavioral reference. The first milestone is read-only serial capture and offline analysis.

## Run

```sh
swift test
swift run freedom-cli ports
swift run freedom-cli settings
```

## Safety boundary

The transport refuses ECU writes. The FC-03 wire protocol, framing, checksum, baud rate, and write semantics must be confirmed from recorded FCSS/FCST traffic before adding a write path. Do not connect this to a running engine for testing.

## Porting strategy

- `FreedomCore`: platform-neutral settings, frames, recorder, and safety policy.
- `DarwinSerialTransport`: macOS serial transport using `/dev/cu.*`.
- Future iPhone/Android transport: BLE/Wi-Fi serial bridge, sharing the same core protocol package.
- Future UI: SwiftUI desktop/mobile front end.
- Future AI: offline recommendations from logged AFR/RPM/load/ignition data, with human approval and hard range checks before any ECU write.
