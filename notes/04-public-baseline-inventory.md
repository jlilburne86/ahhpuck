# Public Freedom baseline and tune inventory

Research date: 2026-10-08

## Usable baseline files

| Source | Vehicle/configuration | Evidence level | Local asset |
|---|---|---|---|
| FCSS supplied OE base maps | AE86 A/B/C/D, AE86-TS, plus other 4-valve/4-throttle examples | Actual FCP files; calibration provenance is limited | `extracted/base_maps/BASE MAPS - FC OE DATA/` |
| FCSS supplied example | `f00611mt.FCP` | Actual FCP file; exact engine/hardware metadata not yet established | `extracted/software/.../f00611mt.FCP` |
| `MIXCONT.FCP` | Air/fuel feedback-related definition/example | Actual FCP file; not a complete engine tune | `extracted/base_maps/BASE MAPS - FC OE DATA/MIXCONT.FCP` |

## Public documented references

### AE86 with AE111 20V

Club4AG documents an AE86 with an AE111 20V managed by Freedom, including DLI ignition and the need to account for 20V injectors, individual throttles, VVT, and ISCV. It is a hardware/configuration reference, not a downloadable calibrated map.

Source: <https://www.club4ag.com/faq_and_tech_pages/ae86_project%2020V.htm>

Local capture: `downloads/public_baselines/club4ag_ae86_20v_freedom.html`

### AE86 with AE101 five-valve engine, four throttles, D-Jetronic/MAP control

The documented owner/tuner report describes starting from the built-in five-valve initial data, disabling feedback and learning for the first check, finding high-load lean and low-throttle rich areas, correcting the fuel map, reducing excessive high-RPM ignition advance, and adjusting VVT switching. It reports an initial map reaching 37 degrees at 8000 RPM and a later maximum near 34 degrees, but this is a historical owner-specific tune, not a safe target for another engine.

Source: <https://minkara.carview.co.jp/userid/427382/car/340170/1034613/note.aspx>

Local capture: `downloads/public_baselines/minkara_ae86_ae101_5valve_djtr.html`

### FCSS A/B/C/D initial-data families

The Japanese reference describes the built-in A/B/C/D initial data as cam/overlap families, roughly from normal-to-256 degrees, 256–272, 272–288, and above 288 degrees. It emphasizes choosing the family by cam specification, not by vehicle name alone.

Source: <https://www.eonet.ne.jp/~bekkan86/ugokasu.htm>

Local capture: `downloads/public_baselines/eonet_freedom_initial_data.html`

### A/B/C/D map comparison

The public comparison of `AE86-A.FCP`, `AE86-B.FCP`, `AE86-C.FCP`, and `AE86-D.FCP` explains that the files are VE-style base maps and discusses injector-size and target-AFR assumptions. It is useful for understanding map structure and provenance, but its example conversion assumes a 5-valve 295 cc/min injector and must not be applied to an unknown AE111 setup.

Source: <https://minkara.carview.co.jp/userid/832136/blog/24396196/>

Local capture: `downloads/public_baselines/minkara_freedom_base_maps_abcd.html`

### FCST map and logging behavior

Paddock-N’s FCST documentation describes reading, displaying, logging, and editing fuel, throttle, and ignition maps. It documents RPM/load/throttle grid limits and warns that ECU learning can make the displayed FCST map stale until it is re-read. It is a software-behavior reference, not a baseline tune.

Source: <https://ameblo.jp/hiro0719jp/entry-12851058740.html>

Local capture: `downloads/public_baselines/hiro0719jp_fcst_map_editor.html`

## Important negative finding

No public, provenance-complete AE111 Blacktop FC-03/Ab-1EU FCP tune was found in this pass. Public material mostly provides screenshots, setup reports, base-map families, or owner-specific adjustments. Therefore the initial AE111 baseline must be built from the car’s verified hardware plus read-back data, not copied from a screenshot or generic AE86 map.

## Baseline ranking for our optimizer

1. Exact read-back from this ECU and this engine: authoritative starting point.
2. Supplied FCSS base maps: structural reference only until hardware metadata matches.
3. Public AE86/AE101/AE111 reports: calibration hypotheses and test plans.
4. Screenshots and forum claims: context only; never imported as map values.
