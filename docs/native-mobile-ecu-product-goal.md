# Native mobile ECU product goal

## Goal

Build an iOS-first native AI-assisted tuning system that connects directly to
the Freedom ECU over USB/USB-C, provides live in-car engine-management and
dashboard views, records engineering-quality telemetry, and progresses toward
controlled, reversible, on-the-fly calibration experiments.

The primary product value is not displaying gauges. It is helping the engineer
make measured progress toward the selected purpose—drift, grip, 0–100, or
top-speed—without confusing a model prediction with proof of a safe tune.

## AI-assisted progress loop

```text
observe -> validate -> diagnose -> propose -> approve -> test -> evaluate
    ^                                                              |
    +---------------------- learn from evidence ------------------+
```

The AI layer should:

- understand the vehicle/engine/hardware profile and missing evidence;
- correlate RPM/load/cell, lambda, ignition, knock, temperature, pressure,
  voltage, VVT, and objective performance;
- identify likely causes and distinguish sensor/data faults from tuning faults;
- propose the smallest useful next experiment with expected outcome;
- score confidence, safety margin, repeatability, and map coverage;
- compare the result with the previous baseline and maintain a progress ledger;
- stop when evidence is insufficient, regressions appear, or protection triggers.

The optimizer, not the language model, owns numerical bounds and safety gates.
The LLM explains evidence and proposes experiments in a structured schema. It
cannot bypass gates, invent a calibration value, or authorize a write.

## Product modes

### Monitor

Read-only ECU identity, live telemetry, graphs, map trace, sensor plausibility,
alerts, session recording, and test abort. This is the first vehicle-capable
release.

### Engineer

Profile the vehicle, engine, sensors, fuel, injectors, ignition, VVT,
modifications, and purpose. Compare baselines, review logs, calculate coverage,
and produce a proposed change report. No ECU write.

### Optimize

Use bounded, evidence-based experiments. Only fuel proposals are initially
eligible; ignition proposals require verified timing offset and knock evidence.
The optimizer stops on protection faults, stale telemetry, bad data, or loss of
connection.

### Tune live

Future capability only after FC-03 protocol, axes, units, checksums, timing,
rollback, and hardware variants are verified. Every change is a signed diff,
one calibration family at a time, with human approval and immediate rollback.

## Platform strategy — iOS first

The primary implementation is now iOS/SwiftUI. The repository contains an
iOS-first scaffold in `ios-app/`, including a read-only dashboard controller,
transport boundary, safety adapter, placeholder USB transport, and tests.

Android remains a later adapter. Android documents USB host mode in which the
phone enumerates connected USB devices and applications request access to them:
[Android USB host overview](https://developer.android.com/develop/connectivity/usb/host).

iOS requires a supported accessory path. Apple documents `ExternalAccessory` for
MFi accessories and `AccessoryAccess` for connected USB accessories through
`IOUSBHost`; the latter is currently beta. [Apple External Accessory](https://developer.apple.com/documentation/externalaccessory/),
[Apple Accessory Access](https://developer.apple.com/documentation/AccessoryAccess).

The app must support a local bridge mode as well: a Mac/Windows/Linux device
owns the serial connection and an iPhone/Android device receives authenticated
telemetry over local Wi-Fi. This provides a useful fallback while direct iOS
USB support is being validated.

## Shared core

The iOS and Android UIs should use the same platform-neutral concepts:

- `TransportAdapter`: USB/serial, local network bridge, or replay;
- `FC03FrameDecoder`: read-only first, version/profile aware;
- `TelemetryNormalizer`: units, timestamps, data gaps, plausibility;
- `LiveSafetyMonitor`: critical faults, watchdog, session abort;
- `SessionRecorder`: append-only logs and hashes;
- `ProfileEngine`: AE86/AE101/AE111/4A-GE variant and hardware identity;
- `OptimizerGate`: proposal-only until all gates pass;
- `WriteController`: disabled until protocol and rollback milestones are signed.

The existing Swift monitor is in
`mac-app/Sources/FreedomCore/LiveSafetyMonitor.swift`. It should be reused in
the iOS target. Android should later implement an equivalent Kotlin adapter against
the same normalized telemetry contract.

## In-car dashboard

The primary screen must show connection state and telemetry age more prominently
than performance scores. Minimum channels:

- RPM, load/MAP, throttle, lambda/AFR, coolant, IAT;
- oil pressure, fuel pressure, battery voltage;
- ignition advance, VVT state, injector duty, knock status;
- active correction, current map cell, protection state;
- session timer, sample rate, dropped frames, and map/calibration identity.

Critical alerts must be visible, audible, and haptic where supported. A phone
screen is not the only protection layer; the driver must remain able to remove
load immediately.

## Release gates

1. Replay and simulated telemetry.
2. USB device enumeration without ECU commands.
3. Read-only ECU identity capture.
4. Read-only live monitor and logging.
5. Fault-injection tests: disconnect, stale frames, malformed frames, bad
   sensors, power loss, and corrupted files.
6. Vehicle validation at idle and light load.
7. Controlled load testing with independent safety instrumentation.
8. Human-reviewed proposal generation.
9. Only then consider a restricted write experiment.

No release may claim “safe optimized tune” merely because the dashboard works or
an AI model predicts a performance improvement.
