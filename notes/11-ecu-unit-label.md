# 11 — The purchased FC-03 unit: label decode

Sources: the seller's listing (Neo Style, Wakayama — product page 35,
"AE86用フリーダムECU AE111"), the seller's written reply and four photos, 11
October 2026; the captured Kunugi Runner "product identification" page
(`downloads/kunugi_4361_product_identification.html`, full text re-read 11
October); and search-engine excerpts of Yahoo auction listings for the same
class of unit (the pages themselves are unreachable from the sandbox, so those
are quoted as excerpts, not captures).

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
| Bottom line | `Z-J01030` | `J01` = base-board lot, `030` = serial within the lot. Kunugi documents `K-` as the FC-03K prefix and blank for other FC-03; `Z-` is not in that 2020/2024 text. Yahoo auction titles sell late DI / 5-valve AE86-swap units as "FC-03Z" / "FC03Z", so `Z-` most likely marks a later board sold under that name. Lot letters read as sequential (Kunugi example `A09`, hiro0719jp `C04`, Kunugi `E01`, ours `J01`), so this is a late build. | documented (lot / serial), inferred (`Z-` = FC-03Z) |
| Sticker | `同時噴射` | Simultaneous injection — a batch mode. The seller says "group injection"; FCSS treats the two as different flag values (see below), but both are non-sequential. | observed (sticker + seller statement) |

Earlier notes wrote the code as `Ab-1ESU`. The photo shows `Ab-1EU`; the `S` was
a transcription error and has been corrected throughout.

## What this means for the project

- **Injection mode is group / batch, not sequential.** The sticker, the seller
  and the missing `S` agree. The engine profile default is now "Batch fire
  (group injection)". Treat any sequential assumption in base-map comparisons
  as wrong until the ECU read-back says otherwise.
- **Direct ignition is fitted** (seller statement), and on an AE111-coupler
  unit it is *standard*, not an option: Kunugi lists AE111 as the one car with
  DI as factory fit, and its option-table footnote says a unit built for a
  natively-DI car runs DI with no option added. So the `E` and `U` letters are
  **not** the DI option; they are something else (still unread — the two
  code tables are images). The stored map is a DI map either way, and the
  engine needs a DI-capable trigger (the 20V's own distributor-less setup, or
  the crank pickup kit on a 16V).
- **Standard on an AE111-coupler Freedom** (Kunugi lineup table): direct
  ignition, 5-valve support, sequential injection *capability*, fuel-pump
  control. The AFR-link option (`M` in Kunugi's examples) is available on all
  models but board-dependent; the label has no `M`, so assume no AFR link.
- **The harness plug is the AE111 factory ECU coupler: the unit plugs straight
  into an AE111 engine loom.** Confirmed three ways — see "How it was sold and
  installed" below. Sourcing route: an AE111 4A-GE engine loom (or a
  coupler-on AE86 conversion harness built for the AE111 ECU). An AE86 loom
  will not plug in.
  - Injection wording: FCSS's model flag (Kunugi, page 11) distinguishes
    `0: 4A-G 同時噴射` (simultaneous) from `1: 4A-G グループ噴射` (group). The
    sticker says 同時噴射, the seller says グループ噴射. Both are batch modes
    and either is a plausible choice for a 20V on ITBs; the read-back of that
    flag will say which one is actually set. Kunugi lists sequential as the
    AE111 *standard*, so this unit was deliberately run in a batch mode.
- **Provenance stops at the listing.** The seller does not know the firmware
  revision, the donor engine or whether a map backup exists. Those come from
  the read-only identity capture, which is already release gate 3.

## How it was sold and installed (confirmed 11 October 2026)

Three independent lines agree that this is an **AE111-coupler** Freedom.

1. **The listing.** Neo Style (ネオスタイル, Kinokawa, Wakayama; a drift-car
   tuning shop) sold it as product 35, titled **"AE86用フリーダムECU AE111"** —
   a Freedom ECU *for an AE86*, *AE111 type*. List price ¥88,000, sold at
   ¥66,000 (tax in). The description: "AE111 20Vエンジンでグループ噴射、
   ダイレクトイグニッションで使用していました" — used on an AE111 20V engine
   with group injection and direct ignition. The seller's reply adds that it
   came off a car they bought and they know nothing beyond the page. Read
   together with the title, the donor was an **AE86 running a 20V on an AE111
   harness with an AE111-coupler Freedom** — exactly the hiro0719jp and
   Paddock-N arrangement. (search-engine excerpt of the listing; the page
   itself could not be fetched from the sandbox)
2. **The photos.** The connector face is one grey Toyota-style three-cavity
   ECU header; the owner matched it against an AE111 loom. (observed)
3. **The same class of unit, described by other sellers.** A Yahoo auction for
   an "FC03Z … AE111 / 4AG 5-valve" Freedom says, in substance: for the AE111,
   or for a 5-valve-swapped AE86 wired with AE111 ECU couplers; **cannot be
   used with AE86 ECU couplers**. (excerpt; paraphrased)

Kunugi's rule for the top line — the vehicle code names the factory coupler
the unit was built for — then makes `Ab-1` the AE111 coupler for this unit,
even though the `Ab-1` row of the code-table image is still unread.

**Consequence:** the project car needs an AE111 engine loom (or a conversion
harness that presents the AE111 ECU couplers). The existing AE86 loom cannot
drive this unit.

## Sourcing the loom

What to look for, and what to avoid:

- **Donor AE111 4A-GE 20V engine harness (エンジンハーネス), manual-transmission
  car.** Brings the three ECU couplers plus the matching injector, coil, VVT,
  TPS, MAP and temperature-sensor plugs. Community notes on AE86 swaps say
  wire colours and some connector shapes changed with model year
  (前期 E-AE111 1995–97 vs 後期 GF-AE111 1997–2000), so get the wiring diagram
  for the year of the loom you buy, not a generic one. One AE101 owner reports
  the AE111 ECU uses 26P / 16P / 22P couplers (AE101: 26P / 16P / 12P) — count
  the pins on our unit's header against the loom before paying. (unverified)
- **Coupler-on AE86 conversion harness kits built for the AE111 ECU.** Yahoo
  listing "AE86変換ハーネスキット AE111/AE101エンジンスワップ用" (also mirrored
  at ai8.uk) is designed for "control by the AE111 MT computer", plugs into
  the ECU with one-touch couplers and adds new wires for signals the AE86 body
  lacks. RS Chita sells a 5-valve swap kit for AE86. Both present the AE111
  ECU side, which is what this unit needs. (excerpts)
- **Do not buy the e-impulse kit 074** ("AE86用5バルブスワップ新品ハーネスキット").
  Its ECU-side coupler is the **AE86 shape** with the Freedom pin-out — built
  for an AE86-coupler Freedom (`Aa-1`), the opposite of ours. (excerpt)

Known body-side snags when an AE111-coupler ECU goes into an AE86, from the
`ae86-5valve.junkbox.jp` harness write-ups (about the factory AE111 ECU; the
Freedom follows the same coupler, so the same body signals are involved, but
check which pins the Freedom actually uses on the FCSS wiring sheet):

- early AE86 has an `FS` wire the AE111 ECU has no terminal for — ground it;
- A/C request (`AC1`) logic is inverted and at a different voltage;
- the speed signal (`SPD`) type differs, so speed may read zero as wired;
- the AE111 loom is short for the AE86's left cowl-side ECU position; one
  owner extended by about 60 cm.

Price context from closed Yahoo auctions (excerpts, 2026): plain FC-03A units
¥35k–75k, an FC-03K ¥91,868, an "FC-03Z full option with DI coil kit" ¥186,000.
At ¥66,000 for a DI, AE111-coupler unit this purchase sits in the middle.

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

1. The `E` / `U` option letters (and the `Ab-1` row, for the record) from
   Kunugi's two code-table images (`fc_code00.jpg`, `fc_code01.jpg`; the host
   is unreachable from the sandbox). They are not DI; see above.
2. That `Z-` is the FC-03Z board: the FCSS identity string ("Internal Ver …,
   S/N FC-03?-…") on first connect settles the model variant.
3. Pin count per cavity on the unit's header, counted straight-on, against the
   loom on offer (expected 26 / 16 / 22 if the AE101 owner's note is right).
4. Which batch mode the unit actually runs (`同時` flag 0 vs `グループ` flag 1),
   from the read-back; the profile default stays batch fire either way.
