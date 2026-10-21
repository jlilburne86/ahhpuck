# AhhPuck: TestFlight and App Store metadata

Build: version **1.2**, build **4** (bundle `com.wheelhave.ahhpuck`, team QX3BJMA6SP).
Target now: **public TestFlight beta** (external testing + public link). App Store submission comes later, after the FC-03 path is verified on a phone and the disclaimer has had a lawyer's review. Apple rejects App Store builds that call themselves beta (guideline 2.2), which is why the "BETA" tag and wording are for TestFlight only.

Nothing here has been entered in App Store Connect.

## 1. Create the app record (owner, in App Store Connect)

Apps → + → New App:
- **Platform:** iOS
- **Name:** AhhPuck
- **Primary language:** English (Australia)
- **Bundle ID:** com.wheelhave.ahhpuck (already registered)
- **SKU:** AHHPUCK-IOS
- **User access:** Full access

## 2. TestFlight › Test Information (needed for external testing)

- **Beta App Description:**
  AhhPuck is a read-only companion for engines run by an E&E Systems Freedom FC-03 ECU. It is built to record what the ECU reports, compare controlled runs and explain the evidence. This beta shows demo data until the FC-03 cable connection is verified on a phone. You can explore every screen, import a run (JSON) or an FC-03 raw session from Files, and export sessions. It never writes to the ECU. Use it only with the vehicle stationary, on a bench or a closed course, never on a public road or while driving.
- **Feedback Email:** contact@wheelhave.com
- **Marketing URL:** https://wheelhave.com/ahhpuck
- **Privacy Policy URL:** https://wheelhave.com/privacy#ahhpuck
- **What to Test:**
  First launch: read and accept the beta disclaimer. Go through the setup (vehicle profile, connection, phone mount). Explore the Live, Map, Runs, Review and Garage tabs. Import a run JSON or an FC-03 raw session from Files in Runs, and export a session. Tell us about anything confusing, anything that looks like real data but isn't labelled as demo, and any crash.
- **Beta App Review Information:**
  - Contact: Justin Lilburne, contact@wheelhave.com (phone: add in App Store Connect)
  - Sign-in required: **No** (no accounts)
  - Review notes: see section 6

## 3. App Store listing (for later, en-AU)

- **Name (≤30):** AhhPuck
- **Subtitle (≤30):** Read your FC-03. Change nothing (28)
- **Promotional text:** Record what your Freedom FC-03 ECU reports, compare runs and see the evidence. Read-only: AhhPuck never writes to the ECU.
- **Description:**
  AhhPuck is a read-only companion for engines run by an E&E Systems Freedom FC-03 ECU.

  READ, DON'T WRITE
  AhhPuck reads what the ECU reports. It never writes to the ECU, changes a calibration or ignition timing, or controls the engine.

  EVIDENCE ON EVERY VALUE
  Each number is tagged DOCUMENTED, OBSERVED, INFERRED or UNVERIFIED, so you can see where it came from. Unverified values are never used for decisions.

  COMPARE CONTROLLED RUNS
  Record a baseline, then compare later runs against it on the map trace, lambda overlay and gain charts. The ledger keeps every run, with what was accepted, repeated or rolled back.

  YOUR DATA STAYS ON YOUR PHONE
  No account and no analytics. Sessions are stored on the phone. You choose what to export.

  ENGLISH AND JAPANESE
  Switch language from Garage.

  IMPORTANT
  Information only, not tuning advice. Use only with the vehicle stationary, on a bench or a closed course, never on a public road or while driving. You are responsible for your vehicle and for complying with local laws, including emissions rules.
  *(While the FC-03 path is unverified, the description must also say that engine values are demo data. Remove that line only once live readings work.)*
- **Keywords (≤100):** ecu,fc-03,freedom,engine,tuning,lambda,afr,datalog,dyno,ae86,4a-ge,jdm,motorsport,track (95)
- **Support URL:** https://wheelhave.com/ahhpuck
- **Marketing URL:** https://wheelhave.com/ahhpuck
- **Privacy Policy URL:** https://wheelhave.com/privacy#ahhpuck
- **Category:** primary **Utilities**, secondary **Reference**. Not Navigation or Sports.
- **Copyright:** 2026 Wheel Have
- **Screenshots (6.9", 1320×2868):** `iphone-6.9/` 1-welcome, 2-live, 3-map, 4-review, 5-ledger, 6-disclaimer. Every in-app shot shows the BETA · demo-data strip, so they are TestFlight-honest. For the App Store, retake them once live data works and the BETA strip is gone. iPhone-only app (`TARGETED_DEVICE_FAMILY = 1`), so no iPad screenshots are needed.

## 4. Age rating answers

None of the content categories apply (no violence, sexual content, profanity, drugs, gambling, horror, medical, or contests). No unrestricted web access, no user-generated content, no messaging or chat, no advertising, and no in-app purchases. Expected result: **4+**. If the questionnaire asks about guidance on dangerous activities, answer **No**: the app explicitly refuses to give tuning advice.

## 5. App Privacy

**Data Not Collected.** The app has no account, no analytics, crash or ad SDK, and no network calls. Captures and sessions stay on the device. Exports go only where the user sends them through the share sheet. The privacy manifest (`App/PrivacyInfo.xcprivacy`) declares no collected data and no tracking, with UserDefaults (CA92.1) as the only required-reason API.

**Export compliance:** `ITSAppUsesNonExemptEncryption = NO` is in Info.plist, so there is no encryption question per build.

**Content rights:** no third-party content shown. **Advertising identifier:** not used.

## 6. Review notes (TestFlight Beta App Review, and later App Store)

AhhPuck is a read-only companion for the E&E Systems Freedom FC-03 ECU. No account or sign-in. It never writes to the ECU: ECU writes, ignition changes, map changes and automatic tuning do not exist in the build.

Hardware: live reading needs an FC-03 ECU and its serial cable, which aren't verified on a phone yet. Until they are, every in-app screen shows a "BETA · Demo data until the FC-03 connection is verified" strip, and the engine numbers are demo data. You can review every screen without hardware:

1. On first launch, read and accept the beta disclaimer ("I understand").
2. Go through the setup: How it works, Permissions (none are requested), Hardware guide, Connection (it explains the cable), Vehicle profile, Phone mount.
3. Explore the Live, Map, Runs, Review and Garage tabs.
4. Runs → "Import run JSON" or "Import FC-03 raw session" reads a file from Files. Session detail → Export writes one.
5. Garage → About → Disclaimer shows the disclaimer again. "Permissions, privacy and terms" opens the legal links.

Permissions: none are requested (no location, motion, Bluetooth, camera, notifications or tracking). Privacy: no data leaves the device. Safety: information only, for use with the vehicle stationary or on a closed course, never on a public road.

## 7. What remains (owner)

1. Create the app record (section 1).
2. Upload build 4 (archive and upload with the team's App Store Connect key, as for Wheel Have), then add it to an external group, fill in Test Information (section 2), submit it for Beta App Review and turn on the public link.
3. **Get a lawyer to review the disclaimer and terms wording** before any public App Store release.
4. For the App Store later: a real FC-03 capture on a phone, a short video of it for the review notes (guideline 2.1, hardware), new screenshots without the BETA strip, and removal of the "beta" wording.
