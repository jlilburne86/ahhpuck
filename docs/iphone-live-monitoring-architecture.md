# iPhone live monitoring and USB-C architecture

## Capability boundary

The iPhone application can connect, decode verified telemetry, display alerts,
record logs, abort the software test session, and prevent further tune proposals.
It cannot create an ECU limp mode unless the ECU itself exposes a documented,
verified protection command and the vehicle wiring supports it. A phone alert is
not a substitute for ECU-side protection, a mechanical oil-pressure switch, or
a trained operator removing load.

Apple's current documentation has two relevant paths:

- `ExternalAccessory` is for manufacturer-supported MFi accessories and requires
  the accessory protocol to be declared and known to the app.
- `AccessoryAccess` is a newer beta framework for connected USB accessories via
  `IOUSBHost`; it must be tested against the shipping iOS version and the exact
  USB bridge. See [External Accessory](https://developer.apple.com/documentation/externalaccessory/)
  and [Accessory Access](https://developer.apple.com/documentation/AccessoryAccess).

The supplied FCSS documentation reports RS232C at 9600 bps. Therefore the first
phone transport profile should be 9600 bps read-only capture, while data bits,
parity, stop bits, electrical levels, framing, and checksum remain unverified.
A generic USB-C-to-RS-232 cable should not be assumed to work on an iPhone. The
FC-03 electrical layer, cable level shifting, iOS USB class support, power
budget, and app entitlement must be verified with the actual adapter.

## Recommended system layout

```text
FC-03 serial port
    -> electrically correct, isolated USB/serial bridge
    -> iPhone USB-C transport adapter
    -> verified FC-03 frame decoder
    -> normalized telemetry stream
    -> LiveSafetyMonitor
       -> on-screen alert + audible/haptic alert
       -> immutable log
       -> abort test / disarm optimizer
       -> no ECU write
```

The bridge should provide electrical isolation and correct automotive power
handling. The phone must not source uncontrolled vehicle power into the ECU
connector. Cable pinout, ground reference, voltage levels, baud, framing,
termination, and transient protection require bench verification first.

## Test-session state machine

```text
idle -> connected -> read-only verified -> armed -> running
                                      \-> fault/timeout -> aborted
running -> completed only after clean stop and log finalization
```

Rules:

1. The app starts in offline mode.
2. Connection does not imply protocol verification.
3. Read-only identity and live-data capture must pass before arming.
4. A telemetry timeout is a critical fault, not a zero reading.
5. Any critical fault aborts the app's test session and blocks optimization.
6. The app stays foreground, keeps the display awake, and shows connection age.
7. Every alert includes timestamp, sample, threshold, source, and operator action.
8. Reconnection requires a new identity/read-only verification; it does not
   silently resume a run.

The Kunugi Runner FCSS reference reports approximately 0.2–0.25-second log
sampling and up to 5000 points for its FC-03K/FCSS 2.14 setup. The monitor can
use this as an initial design target, but should negotiate or measure the actual
rate for the user's ECU and treat missing frames as data-quality failures.

## Alert classes

- **Critical**: knock, lean under load, low oil pressure, high coolant/IAT, RPM
  limit, voltage failure, invalid/stale telemetry, decoder desynchronization.
  Abort the test immediately and block learning.
- **Warning**: approaching a limit, low sample coverage, high variance, sensor
  drift, or an unvalidated profile. Continue only at reduced test scope and with
  explicit operator acknowledgement.
- **Information**: cell coverage, current map version, connection state, and
  candidate change awaiting approval.

## What “failsafe” means here

The first implemented failsafe is a software failsafe: it changes the session to
`aborted`, raises a critical alert, stops candidate generation, and records the
event. It does not attempt to send an undocumented fuel-cut, ignition-cut, or
limp command to the FC-03.

The reference also reports that FCSS real-time edits apply immediately and that
bad values can stop the engine. Accordingly, “real-time” in this product means
live observation and alerting only until FC-03 command semantics are proven.

Later ECU-side protection should be implemented only after captures prove the
command semantics and only if the ECU's own protection behavior is understood.
An independent physical protection circuit may be considered by a qualified
automotive electrical engineer, but it must not be improvised from a phone app.

## Native app modules

- `Transport`: iPhone USB accessory/bridge, macOS serial, and replay transport.
- `FrameDecoder`: FC-03 protocol implementation, initially read-only.
- `TelemetryNormalizer`: units, timestamps, plausibility, and missing-data flags.
- `LiveSafetyMonitor`: the platform-neutral monitor in
  `mac-app/Sources/FreedomCore/LiveSafetyMonitor.swift`.
- `SessionStore`: append-only logs, hashes, calibration identity, and alerts.
- `SwiftUI`: dashboard, graph, alert banner, connection age, and operator
  acknowledgement.
- `OptimizerGate`: receives data only when the safety monitor is healthy; it
  cannot arm a write path.

The current Swift core is tested on macOS. The same monitor should be reused in
an iOS target, while only the transport and UI layers change. iPhone hardware
validation remains pending until the exact USB bridge and FC-03 serial protocol
are confirmed.
