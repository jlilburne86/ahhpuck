# Future ECU and tuner candidates

## Scope

These platforms are documented as future candidates only. They are not part of the current product target, transport implementation, safety approval, or tuning workflow.

The active target remains the user's Freedom Computer FC-03, option Ab-1EU, controlling an AE111 4A-GE 20V Blacktop installed in an AE86.

No additional ECU is promoted into development until the Freedom FC-03 trial has been connected, captured, assessed, and reviewed against real vehicle evidence.

## Candidate register

| Candidate | Why it was recorded | Current status | Possible later value |
| --- | --- | --- | --- |
| MoTeC M4 / M48 / M800 | Capable legacy ECUs with obsolete EMP software and difficult modern Windows support | Research only | Calibration and log conversion, evidence-led diagnostics |
| Autronic SM2 / SM3 / SM4 | Strong legacy fuel, ignition, cam and logging capability with old Windows/x86 software | Research only | Modern backup, log analysis and guided commissioning |
| Emerald K3 / K6 | Older capable ECUs with published manuals, logger material, CAN information and serial-adapter guidance | Research only | Cross-platform setup and diagnostic assistant |
| Haltech Platinum | Established legacy standalone family with separate older software generation | Research only | Read-only session/log analysis |
| AEM Infinity / Series 2 | Rich calibration and logging concepts with documented session/log files | Research only | Import, compare and explain existing data |
| Link G1 / G2 / G3 / G4 / G4+ | Large installed base with generation-specific PCLink software and logs | Research only | Version-aware analysis layer |
| DTA S-series | Older motorsport ECU family with continuing documentation and firmware archive | Research only | Guided configuration and log review |
| VEMS V3 | Serial-connected ECU with trigger logging, wideband support and extensive documentation | Research only | Cross-platform monitoring and setup guidance |
| MegaSquirt MS2 / MS3 | Accessible, well-documented reference ecosystem using TunerStudio and standard logs | Research only | Test adapter architecture and normalized telemetry |
| rusEFI / Speeduino | Open ecosystems with accessible logging and protocol concepts | Research only | Development fixtures and adapter test references |

## Promotion gates

A candidate may only move from this register into active development after the Freedom FC-03 trial demonstrates:

1. Verified identity and transport capture.
2. Correct normalized telemetry and data-quality checks.
3. Repeatable readiness and safety assessment.
4. Immutable backup and rollback evidence.
5. A complete supervised trial record.
6. A clear user need that the candidate platform solves.

The future adapter must begin at log import or read-only telemetry. Calibration writes require separate proof of protocol, table semantics, checksum behaviour, rollback behaviour and human approval.

## Source notes

- [MoTeC M4/M48/M800 connectivity](https://motec.zendesk.com/hc/en-gb/articles/13648981319695-M4-M48-and-M8-connectivity)
- [Autronic legacy downloads](https://autronic.com.au/downloads.html)
- [Emerald software and manuals](https://www.emeraldm3d.com/software-manuals)
- [Haltech downloads](https://store.haltech.com/downloads)
- [AEM engine-management support](https://www.aemelectronics.com/support/engine_management/)
- [Link legacy software](https://support.linkecu.com/pclink/latest/legacy-software)
- [DTAFast downloads](https://dtafast.co.uk/pages/downloads)
- [VEMS documentation](https://www.vems.com/documentation/)
- [MegaSquirt documentation](https://www.megamanual.com/mtabcon.htm)
- [rusEFI diagnostics and logging](https://github.com/rusefi/rusefi/wiki/Diagnostics-and-Logging)

## Decision

Do not build these adapters yet. Preserve this register for staged expansion after the Freedom FC-03/AE86/AE111 trial produces real results.
