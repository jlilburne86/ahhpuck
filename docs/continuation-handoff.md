# AhhPuck continuation handoff

Updated: 15 October 2026  
Canonical repository: `/Users/boo2/ahhpuck-testflight`  
Working branch: `feat/testflight`

## Goal

Build a native iOS companion for unsupported Freedom FC-03 ECUs that collects trustworthy read-only evidence: vehicle/engine profile, ECU identity, raw serial data, synchronized context, repeatable baselines and conservative assessments. The app must learn from verified captures without pretending that unknown bytes are known or authorizing ECU writes.

## Complete

- FCSS/FCST binaries, configuration, help/data files, maps and logs were inventoried.
- Capability and protocol findings are recorded in notes 12 and 13.
- Native iOS onboarding collects vehicle, engine, ECU, modification and capture-source data.
- Recovered functions are placed in the existing Live, Settings, Maps and Limits surfaces.
- FC-03 contract is represented as `9600 7E1`, `?DAT`, 55-byte payload validation and optional raw terminator retention.
- `FC03CaptureRecorder` retains raw request/reply bytes, timestamps, validation result, response length and evidence note.
- `FC03CaptureCoordinator` provides the bench-facing read-only path and persists a `FC03CaptureSession` JSON file.
- `FC03CaptureFileStore` stores sessions under Application Support and Runs/Review exports `fc03-capture.json`.
- `MobileRunRecord` stores baseline, candidate, repeat and observation runs with raw telemetry frames and vehicle/modification context.
- `MobileBaselineSummary` calculates signal statistics, frame coverage, timestamp gaps, missing channels and a conservative quality score.
- `MobileRunComparison` compares lambda error across baseline/candidate/repeat runs and only confirms improvement when the repeat is within tolerance.
- `MobileRunStore` persists run records locally with millisecond timestamp precision for later review and export.
- `MobileReplayTransport` replays persisted decoded frames through the read-only transport contract for UI and assessment testing without claiming USB compatibility.
- Runs/Review can import a run JSON file, shows real stored evidence when available, and exports run JSON, assessment and manifest files with `writeAuthorization: never`.
- Runs/Review can also import a raw `FC03CaptureSession` JSON from the desktop/bench workflow; the session remains byte-for-byte raw and exports as `fc03-capture.json`.
- `FC03VerifiedTelemetryDecoder` refuses to decode until field offsets/scaling are verified.
- ECU writes, map writes, raw command testing and autonomous tuning remain locked.
- Heavy demo projections are cached and the demo ticker is 250 ms for better responsiveness.

## Verification

```sh
cd /Users/boo2/ahhpuck-testflight
swift test --package-path ios-app
```

Current result: 16 core tests pass, including baseline statistics, repeat confirmation, run-store round trips, ordered replay transport coverage and raw FC-03 capture persistence.

The Release archive/export succeeds with:

```sh
xcodebuild -project ios-app/FreedomIOSApp.xcodeproj \
  -scheme AhhPuck -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/AhhPuck.xcarchive \
  -allowProvisioningUpdates archive

xcodebuild -exportArchive \
  -archivePath build/AhhPuck.xcarchive \
  -exportOptionsPlist build/ExportOptions.plist \
  -exportPath build/testflight-export \
  -allowProvisioningUpdates
```

An earlier signed export was produced at `build/testflight-export/AhhPuck.ipa`; rebuild and sign again after any source change before TestFlight submission.

## TestFlight upload

The export is ready, but `xcrun altool` stops before submission because no App Store Connect authentication is configured:

```text
Either JWT (--api-issuer and --api-key) or username and app password
(--username, --app-password and --provider-public-id) authentication is required.
```

After configuring credentials locally, upload with an API key. Never commit the private key, password or token:

```sh
xcrun altool --upload-app \
  -f build/testflight-export/AhhPuck.ipa \
  -t ios \
  --api-key "$ASC_KEY_ID" \
  --api-issuer "$ASC_ISSUER_ID"
```

If App Store Connect reports a duplicate build, increment `CURRENT_PROJECT_VERSION` in the Xcode project before rebuilding. Do not change the marketing version without an explicit release decision.

## First real desk capture

1. Confirm the FC-03 label, harness and cable pinout. Do not splice into the vehicle loom.
2. Use the isolated serial adapter/cable checked for the FC-03 interface; USB-C alone does not convert RS-232 levels.
3. Start with ignition off and the ECU disconnected from engine load where practical.
4. Configure 9600 baud, 7 data bits, even parity, 1 stop bit, no flow control.
5. Send only `?DAT` and retain the complete reply, including any trailing byte.
6. Create metadata with ECU label/profile, cable notes, vehicle profile, modifications and `sessionKind: observation`.
7. Feed the response into `FC03CaptureCoordinator.ingestDAT(response:)`, then call `finish()`.
8. Export the session bundle and preserve the original JSON/raw bytes before analysis.
9. Repeat captures in known conditions. Only after stable repeated evidence should a field mapping be added to the decoder.

## Do not do yet

- Do not implement or expose ECU writes based on recovered FCSS/FCST menu names.
- Do not infer RPM, TPS, MAP, temperature, O₂, ignition or injector scaling from one response.
- Do not use phone GPS/motion as ECU truth; they are context and cross-check sources.
- Do not accept a tune candidate without baseline, candidate and repeat evidence.
- Do not treat demo numbers or simulator success as real ECU compatibility.

## Where to continue coding

- Protocol: `ios-app/Sources/FreedomMobileCore/FC03Protocol.swift`
- Capture/persistence: `ios-app/Sources/FreedomMobileCore/FC03Capture.swift` and `FC03DataPipeline.swift`
- Transport boundary: `ios-app/Sources/FreedomMobileCore/MobileModels.swift`
- Shared state/performance: `ios-app/App/Model/AppModel.swift`
- Connection UI: `ios-app/App/Screens/S04.swift`
- Vehicle profile: `ios-app/App/Screens/S02.swift`
- Provenance: `ios-app/App/Screens/S38.swift`
- Export: `ios-app/App/Screens/S31.swift`
- Capability presentation: `ios-app/App/Screens/S43.swift`

Keep changes read-only and add a test for every newly verified protocol fact.
