# Freedom iOS native build

This folder contains the native SwiftUI direction for the imported Freedom Mobile design.

## Open and test in Xcode

Open the native project:

```sh
open /Users/boo2/ahhpuck/engine-intelligence/ios-app/FreedomIOSApp.xcodeproj
```

In Xcode:

1. Select the `FreedomMobileCore` package scheme.
2. Run the package tests with `Product → Test`.
3. Select an iOS 17+ simulator or device and run.
4. Use **Setup → Language** to switch the native shell between English and Japanese.

The app currently includes native screens for:

- Live engine dashboard;
- run capture;
- baseline/candidate/repeat assessment;
- concerns and deterministic decision;
- supervised approval checklist;
- vehicle and connection setup.

The app includes a complete local first-trial workflow so the product flow can be tested before an ECU is connected:

1. Open **Live** and review the readiness gate.
2. Load the first-trial fixture, or use **Run** to load it as a supervised local trial.
3. Review baseline, candidate, and repeat-candidate evidence.
4. Inspect the deterministic decision and concerns.
5. Complete the four approval checks to create a local approval record.

The fixture is illustrative and does not represent a real ECU capture. The backend state machine is in `Sources/FreedomMobileCore/MobileTrialSession.swift`; SwiftUI only presents the current state and next action.

For repeatable Simulator UI review, launch the native app with:

```sh
xcrun simctl launch <device> com.ahhpuck.freedom -- -loadFixture -glance
xcrun simctl launch <device> com.ahhpuck.freedom -- -loadFixture -engineer
xcrun simctl launch <device> com.ahhpuck.freedom -- -loadFixture -japanese -glance
```

These flags load local replay data, select the Live display mode, or select
Japanese. They never connect to an ECU and do not enable writes.

## Command-line validation

```sh
cd /Users/boo2/ahhpuck/engine-intelligence/ios-app
swift test
```

The native core currently validates:

- read-only transport state;
- critical-frame abort behaviour;
- USB transport placeholder behaviour;
- repeatable improvement acceptance;
- knock-triggered experiment abort.
- readiness gating and missing-evidence reporting;
- complete first-trial capture, assessment, and approval flow.

## Safety boundary

The native app does not write to the ECU. `MobileExperimentAssessor` owns only the deterministic assessment result, and its `writeAuthorization` is always `never`. Real FC-03 transport and frame decoding must be verified before connecting the live transport to engine testing.
