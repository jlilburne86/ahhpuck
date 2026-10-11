# 11 — The purchased FC-03 unit: label decode

Source: seller's listing photo of the unit (shop.neostyle-racing.com), 11 October
2026, plus the seller's written reply. Decoding rules come from the captured
Kunugi Runner "product identification" page (`downloads/kunugi_4361_product_identification.html`).

## What the label says

Silver E&E label, two lines, plus a separate printed sticker:

```text
Ab-1EU
Z-J01030
```

Sticker beside it: `同時噴射` ("simultaneous injection", i.e. group / batch injection).

## Decode

| Field | Value | Meaning | Evidence |
| --- | --- | --- | --- |
| Top line, vehicle code | `Ab-1` | The vehicle family / factory ECU coupler the unit was built for. Kunugi's worked example reads `Aa-1` as the AE86 · AW11 · early AE92 coupler, so `Ab-1` is a different coupler from the AE86 one. | documented (format), inferred (which coupler: the code table is an image not captured here) |
| Top line, option letters | `EU` | Options fitted that are non-standard for that vehicle code. Letter meanings are in Kunugi's option table (image, not captured). `E` and `U` are present; there is **no `S`**. | documented (format), unverified (letters) |
| Bottom line | `Z-J01030` | `J01` = base-board lot, `030` = serial within the lot. Kunugi documents `K-` as the FC-03K prefix and blank for other FC-03; a `Z-` prefix is not described in the captured text. | documented (lot / serial), unverified (`Z-`) |
| Sticker | `同時噴射` | Group injection. Matches the seller: "it was definitely used with group injection and direct ignition." | observed (seller statement + sticker) |

Earlier notes wrote the code as `Ab-1ESU`. The photo shows `Ab-1EU`; the `S` was
a transcription error and has been corrected throughout.

## What this means for the project

- **Injection mode is group / batch, not sequential.** The sticker, the seller
  and the missing `S` agree. The engine profile default is now "Batch fire
  (group injection)". Treat any sequential assumption in base-map comparisons
  as wrong until the ECU read-back says otherwise.
- **Direct ignition is fitted** (seller statement). Kunugi: once the DI option is
  fitted the unit can no longer drive a stock ignition, and setting data from
  before the option is not usable. So the stored map is a DI map, and the
  engine needs a DI-capable trigger (5-valve distributor or the crank pickup
  kit on an AE86 shell).
- **The harness plug is a Toyota OEM ECU connector for the `Ab-1` vehicle
  family, not a Freedom part.** Given the 5-valve, direct-ignition history and
  the AE111 Blacktop target, `Ab-1` is most likely the AE101/AE111 coupler.
  Confirm against Kunugi's code table (`fc_code00.jpg` on kunugi-runner.com)
  before buying connectors. Routes: a donor AE111 engine harness (the club4ag
  AE86 20V owner did exactly this), or AE111 ECU connector housings and
  terminals built into an adapter from the AE86 harness.
- **Provenance stops at the listing.** The seller does not know the firmware
  revision, the donor engine or whether a map backup exists. Those come from
  the read-only identity capture, which is already release gate 3.

## Still to confirm

1. `Ab-1` coupler mapping and the `E` / `U` option letters, from Kunugi's two
   code-table images.
2. The meaning of the `Z-` serial prefix (board version).
3. Whether the AFR-link option (`M` in Kunugi's examples) is absent; the label
   suggests it is.
