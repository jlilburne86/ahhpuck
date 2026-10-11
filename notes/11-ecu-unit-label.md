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
  family, not a Freedom part.** Freedom units are coupler-on for their own
  vehicle (Kunugi: swap for the stock ECU; other vehicles need rewiring), and an
  AE111-coupler unit does plug straight into an AE111 loom: hiro0719jp runs an
  "FC-03a for AE111" on an AE111 harness transplanted into an AE86, and the
  Paddock-N owner did the same. **Whether `Ab-1` is the AE111 coupler is not
  confirmed.** Two readings of the evidence:
  - For AE111: the 5-valve, direct-ignition history and the AE111 Blacktop target.
  - Against AE111: Kunugi lists sequential injection as *standard* on AE101 and
    AE111 units and only conditional on the AE86/AW11/early-AE92 family, yet this
    unit is labelled group injection with no `S` option. That fits an
    AE86-family or AE92/AE101-era unit, which can still run direct ignition with
    the DI option plus a 4A-GZ / late-AE92 distributor or the crank pickup kit.

  Do not buy an AE111 loom on the AE111 assumption until one of these confirms
  it: the seller names the car it came off, a photo of the connector face is
  matched against an AE111 ECU, or the `Ab-1` row in Kunugi's code table
  (`fc_code00.jpg` on kunugi-runner.com) is read. Whether AE101 and AE111
  factory ECUs share a connector is also unverified here.
- **Provenance stops at the listing.** The seller does not know the firmware
  revision, the donor engine or whether a map backup exists. Those come from
  the read-only identity capture, which is already release gate 3.

## Seller's further photos (11 October 2026)

- **Harness side:** one grey moulded header with three cavities, all male blade
  pins, Toyota factory-ECU style. A three-cavity header is normal for Toyota
  ECUs of the era, so the shape alone does not separate AE86-family from
  AE111; the pin count per cavity would. The photo is angled, so no count yet.
  A straight-on photo has been requested.
- **Label side:** a 10-pin white Molex-style socket (2 × 5), a small rotary
  dial marked OFF, 0, 1, 2, 3, 4, 5…, a small indicator hole, four screws. The
  socket is where the FCSS serial cable or an option harness attaches, not
  part of the loom question.
- **Mounting:** a bracket on the connector end with a slotted tab.

Lead from hiro0719jp's screenshots: on connection FCSS prints the model and
serial itself ("Internal Ver 6.51, S/N FC-03a-C04041" for their AE111-coupler
unit). The read-only identity capture (release gate 3) will therefore report
whether this unit is an FC-03, FC-03a or FC-03K and its internal version
without needing the Kunugi table. Their lot is C04; ours is J01, a later build.

## Still to confirm

1. `Ab-1` coupler mapping and the `E` / `U` option letters, from Kunugi's two
   code-table images.
2. The meaning of the `Z-` serial prefix (board version).
3. Whether the AFR-link option (`M` in Kunugi's examples) is absent; the label
   suggests it is.
