# AhhPuck: App Store metadata

App Store Connect app **6825259927** (AhhPuck, bundle `com.wheelhave.ahhpuck`, SKU AHHPUCK-IOS, en-AU). Version **1.2**, build **5**. A normal App Store release: no beta wording anywhere. Engine values are honestly labelled as demo data until the FC-03 path is verified.

## Listing (en-AU)

- **Name (≤30):** AhhPuck
- **Subtitle (≤30):** Read the ECU. Change nothing (27)
- **Promotional text:** Record what your Freedom FC-03 ECU reports, compare runs and see the evidence. Read-only: AhhPuck never writes to the ECU.
- **Description:** see `DESCRIPTION` in `ios-app/scripts/asc-fill.py`, which is the exact text sent to App Store Connect.
- **Keywords (≤100):** ecu,fc-03,freedom,engine,tuning,lambda,afr,datalog,dyno,ae86,4a-ge,jdm,motorsport,track
- **Support URL:** https://wheelhave.com/ahhpuck · **Marketing URL:** https://wheelhave.com/ahhpuck · **Privacy Policy URL:** https://wheelhave.com/privacy
- **Category:** primary Utilities, secondary Reference
- **Copyright:** 2026 Wheel Have
- **Content rights:** does not use third-party content
- **Licence agreement:** Apple's standard EULA. The in-app Terms of Service (a copy of wheelhave.com/terms) apply alongside it and don't require a custom EULA.
- **Age rating:** none of the content categories apply; no web access, user-generated content, messaging, ads, gambling or contests. Expected 4+.
- **App Privacy:** Data Not Collected. There is no account, no analytics, ads, crash or tracking SDK, and no network requests. Imports and exports are user-initiated, on-device file operations.
- **Export compliance:** `ITSAppUsesNonExemptEncryption = NO`
- **Screenshots (6.9", 1320×2868):** `iphone-6.9/` 1-welcome, 2-live, 3-map, 4-review, 5-ledger, 6-disclaimer. They come from the build itself, with the honest demo-data labels visible. iPhone-only, so no iPad set is needed.

## Legal coverage in the app

First launch: the disclaimer, plus "By continuing you agree to the Terms of Service and the Privacy Policy" with both readable in place, and an "I understand" acknowledgement.

Garage › About lists:
- **Terms of Service and Privacy Policy:** offline copies of wheelhave.com/terms and /privacy, including the AhhPuck sections, the ABN, governing law (Victoria, Australia), the consumer-law carve-out and contact details. Regenerate them with `ios-app/scripts/sync-legal.py`.
- **Disclaimer.**
- **Open-source notices:** the fonts' SIL OFL 1.1 licences and a trademark/non-affiliation note.

Each document has an "Open on wheelhave.com" link.

## Review notes

See `REVIEW_NOTES` in `ios-app/scripts/asc-fill.py`, the exact text sent to App Store Connect.
