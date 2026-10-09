# 4A-GE provider/profile research

Research date: 2026-10-08

## Haltech reference

Haltech’s official 4AG guide separates 16V generations, Silver Top 20V, Black Top 20V, and 4AGZE. It identifies differences in compression, injector size, MAF/MAP strategy, sequential injection, ITBs, ignition/distributor arrangement, VVT, dual-solenoid 20V idle control, coolant and air-temperature sensors, and trigger wiring.

Source: <https://support.haltech.com/portal/en/kb/articles/4ag-engine>

This is useful for our profile schema, not a Freedom map. Haltech’s base-map guidance says a base map is a starting point with setup-specific values still requiring verification, especially injectors and ignition charge times.

Source: <https://www.haltech.com/news-events/base-map-basics/>

## Link reference

Link PCLink officially supports configurable multi-page tuning views, runtime values, gauges, time plots, XY plots, statistics, histograms, parameter lists, log overlays, and base-map comparison. It also states that sample maps are starting points for the engine they were designed for.

Sources:

- <https://linkecu.com/pages/pc-link>
- <https://support.linkecu.com/learn/latest/get-started/sample-maps>

The official Link search did not identify a public AE86/AE101/AE111 Freedom-compatible map. Independent AE111 20V Link examples show that even a stock or modified engine is calibrated on the specific car, with cam timing and engine condition materially affecting the result.

Examples:

- <https://ameblo.jp/garage-annex/entry-12913867698.html>
- <https://www.fujiirs.com/WP/ae111-4ag-linkg4x-re_tuning/>

## Freedom reference

Freedom’s supplied A/B/C/D families are selected by cam/overlap range, not merely chassis. The public FCST material exposes fuel, throttle, ignition, logging, and learning behavior, but does not provide a public provenance-complete AE111 Blacktop FC-03 tune.

## Profile selector fields

The application should require or record:

- chassis: AE86, AE101, AE111, other;
- engine family: 4AGE 16V, 4AGE 20V Silver Top, 4AGE 20V Black Top, 4AGZE, 7AGE, other;
- load strategy: MAP/D-Jetronic, Alpha-N/TPS, blended MAP/TPS, MAF;
- injection: sequential, batch, unknown;
- ignition: distributor, wasted spark, direct ignition/COP, unknown;
- intake: single throttle, factory ITBs, aftermarket ITBs, supercharger, turbo;
- VVT: absent, 20V inlet VVT, aftermarket control, unknown;
- idle control: factory 20V dual-solenoid, single valve, mechanical, unknown;
- injectors: part number, flow, pressure, latency/dead-time source;
- fuel: pump fuel grade or ethanol content;
- cams, compression, fuel pressure, sensors, exhaust, and modifications;
- exact Freedom application/options and current map checksum.

The selector must prevent a reference map from being treated as a tune unless the profile match and missing-data checks are visible.
