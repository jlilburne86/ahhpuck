# Tuning UI visual research

AhhPuck borrows interaction patterns from established tuning and analysis tools, while keeping its own read-only, evidence-first safety model.

## Patterns brought into the native app

| Pattern | Reference tool | AhhPuck adaptation |
| --- | --- | --- |
| Multi-channel time plot with a movable cursor | HP Tuners, MaxxECU | One shared cursor links lambda, RPM/load, and the selected frame readout. |
| Target line and channel legend | HP Tuners, Link PCLink | The lambda target is a dashed reference, with baseline, candidate, and repeat shown as distinct channels. |
| Difference/current/compare map | Haltech NSP | The review screen makes the before → after → smaller next step explicit, rather than showing a raw percentage alone. |
| RPM/load operating map | Speeduino and common VE table workflows | Coverage cells show observed, incomplete, protection, and unvisited regions. They describe evidence coverage, not tune quality. |
| Analysis views and cursor-linked context | MoTeC i2, Link PCLink | Engineer mode separates a glanceable causal reading from the denser review surface. |

## Local reference captures

These are stored for design review only. They are not imported as product assets.

- [HP Tuners graph](../artifacts/research/tuning-ui/hp-tuners-graph.png)
- [MaxxECU live logger](../artifacts/research/tuning-ui/maxxecu-live-logger.png)
- [Speeduino VE table](../artifacts/research/tuning-ui/speeduino-ve-table.png)
- [MoTeC i2 analysis](../artifacts/research/tuning-ui/motec-i2-analysis.png)
- [Link PCLink runtime](../artifacts/research/tuning-ui/link-pclink-runtime.png)

## Source documentation

- [HP Tuners layouts](https://www.hptuners.eu/help/vcm-scanner/layouts-overview.html)
- [HP Tuners graph](https://www.hptuners.eu/help/vcm-scanner/graph.html)
- [MaxxECU live logger](https://www.maxxecu.com/webhelp/mtune-live_logger.html)
- [Speeduino VE table](https://wiki.speeduino.com/en/configuration/VE_table)
- [Haltech Compare Map](https://support.haltech.com/portal/en/kb/articles/compare-maps)
- [MoTeC i2](https://motec.com.au/products/i2)
- [Link PCLink](https://linkecu.com/pages/pc-link)

## Product boundary

The visual patterns are useful, but AhhPuck does not imply that a replay is live ECU data. The provenance badge remains persistent, the target is a reference line rather than an authorization, and protection evidence overrides optimization visuals.
