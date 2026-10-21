# App Store review notes

## Review build

Marketing version: `1.2`
Build: `5`

AhhPuck is a native iOS read-only companion for collecting and reviewing evidence from unsupported standalone ECUs. This build does not write to an ECU, change a calibration, or authorize a tuning change.

The current build operates in replay/demo mode until the FC-03 cable, serial electrical levels, and first real capture have been validated on a physical iPhone. Screens that show replay values are labelled `DEMO DATA`, `SIMULATED`, or `DEMO PREVIEW`. The notification and Live Activity screen is an in-app preview only; this build does not request notification access or publish Live Activities.

## Disclaimer and legal documents

On first launch the app shows the disclaimer and links to the Terms of Service and Privacy Policy, and the user must accept them ("I understand") before anything else. Every legal document can be read again, offline, under Garage › About: Terms of Service, Privacy Policy, Disclaimer, and Open-source notices. Terms and Privacy are copies of wheelhave.com/terms and /privacy, regenerated with `ios-app/scripts/sync-legal.py`. Every in-app screen carries a "DEMO DATA · Engine values are demo data until the FC-03 connection is verified" strip. Store metadata and 6.9" screenshots are in `appstore/`.

## Hardware

The eventual live workflow requires:

- E&E Systems Freedom FC-03 ECU;
- the verified FC-03 serial cable;
- a compatible USB-C serial adapter or supported iOS accessory path;
- a powered bench setup with the ECU disconnected from a running vehicle during initial validation.

For App Review, provide a physical-device video showing the iPhone running AhhPuck and interacting with the FC-03 hardware, or submit the build as a replay/demo-only release until that hardware path is ready.

## Data and privacy

The current build uses local-only replay and capture storage. It does not create an account, use third-party analytics, request location, motion, notification, camera, microphone, health, Bluetooth, or tracking permissions, or upload captured data.

Privacy policy: https://wheelhave.com/privacy

Terms: https://wheelhave.com/terms

## Test path

1. Launch the app on a fresh install.
2. Complete the vehicle/ECU profile flow.
3. Continue through the connection screen; it remains explicitly simulated until hardware validation is enabled.
4. Open Live, Map, Runs, Review, and Garage from the tab bar.
5. Use the replay capture and export paths to inspect raw bytes, validation state, and local session data.

## Safety boundary

AhhPuck is read-only in this release. ECU writes, ignition changes, map changes, automatic tuning, and safety-limit overrides are unavailable. The app presents evidence and conservative explanations; a human remains responsible for every test.
