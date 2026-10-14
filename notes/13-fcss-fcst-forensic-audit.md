# FCSS / FCST forensic software audit

Audit date: 2026-10-14

Scope: the complete extracted FCSS/FCST bundle currently preserved under
`/Users/boo2/ahhpuck-evidence/extracted/`, including executables, app-package metadata, configuration,
embedded data, help files, maps, logs and nested archives.

## Executive finding

The capture contains two generations of Windows software plus their data files:

- `FCST.exe`: a 32-bit managed .NET/Mono Windows GUI, package version 0.2.7.0.
- `FCSS.EXE`: a 32-bit native legacy Windows GUI with direct Win32 serial I/O.
- `LOGDSP.EXE`: a 32-bit native log-display utility.
- `F9100108.EXE` and `F9100152.EXE`: MS-DOS LHa self-extracting archives.
- `KDATA.F00` through `KDATA.F13`, `KDATA.FCS`, `KTABL.FCS` and
  `KDNOTBL.FCS`: calibration/parameter tables and vehicle associations.
- `HELPDATA.FCS` and `HELPDATA.FCW`: legacy help databases/text resources.
- `.FCP` files: map/parameter files.
- `SAMPLE.LOG`: 24-column numeric sample data.
- two CDFV2 files (`26509910`, `DEF51400`): Microsoft Excel data documents.

The original source code is not present. The audit therefore recovers all
available executable metadata, imports, strings, UI/event identifiers,
configuration values and data structures. A binary string is evidence that a
feature or symbol exists, not proof of its exact wire command or firmware
compatibility.

## Cryptographic inventory

| Artifact | Type | Size | SHA-256 |
|---|---|---:|---|
| `FCST/AnyCPU/FCST/FCST.exe` | PE32 .NET/Mono GUI | 510,976 | `dc86e549051ecf62e9d4a182ea3911db92648d55a8d5b51fb894721647e641de` |
| `FCSS.../FCSS.EXE` | PE32 native GUI | 473,600 | `da55a34cb55595e26424c9a4d75d594ecee2b263417696251cddaf57dc33e3a7` |
| `FCSS.../LOGDSP.EXE` | PE32 native GUI | 290,304 | `068c1472cff279daa1496f07bde4aadecd319e5441fd41170a573901f65cd97c` |
| `HELPDATA.FCS` | legacy help data | 61,440 | `d125db8d2dc0d14d353a1db1cc913bbdad5a6cc79fd3276c79385d96de9aa44d` |
| `HELPDATA.FCW` | legacy help data | 61,440 | `0aaf8d2d6a671d781b614bcd865ba3dc656e09a770310f8c9d0c5612537c4813` |
| `KTABL.FCS` | scale/format table | 8,081 | `286451d4022d130781edfa1e34c29fef3000ceb5c58dbb22b54147da301ac6d` |
| `KDNOTBL.FCS` | engine/model table | 252 | `95efdbbb360e220ad8ad4d4623e1ea89972cd82b56b0e51cef8b1b0587ad5626` |
| `FCSS.CNF` | legacy settings | 45 | `a2df4f5f24a28394b23fd7ece095386ae5d623e20e42dbab55af2f8902ceae9d` |
| `KDATA.FCS` | calibration data | 4,338 | `0344ff2e041d224712daca4e348499b6343a40ca38c79a4c17f6634a90d690f3` |
| `FCKEY.FCS` | key/license marker | 37 | `f9b0c8e3f2f84fdb666a79ace8d4a8dd699739399011b25b584913cd8cacc5ee` |

## FCST package metadata

Recovered from `AppxManifest.xml`:

- Display name: `FreedomComputerSettingTool`.
- Publisher: `Paddock-N`.
- Package version: `0.2.7.0`.
- Architecture: neutral package containing `FCST/FCST.exe`.
- Target: Windows Universal/Desktop, minimum `10.0.14393.0`.
- Full-trust desktop capability is required.
- Resource language: Japanese (`JA-JP`).
- Build metadata identifies Visual Studio 2022 and target framework metadata
  `.NETFramework,Version=v4.5.1`.
- The executable configuration declares .NET Framework 4.8 runtime support.

`FCST.exe.config` values:

```text
DefaultCOMPort = COM3
FCCS_LearnRate = 40
SwitchThreshold = 740
latency = 0
Kstable = 0.03
Kaccstable = 0.8
```

These are application defaults, not verified ECU-wide constants.

## FCST executable findings

The executable contains 4,694 printable strings and a CLR runtime header. It
references `System.IO.Ports.SerialPort` and exposes the following recoverable
areas.

### Serial and command transport

Recovered identifiers include:

`SerialPort`, `SerialPort1`, `SerialPortNames`, `PortSelect`, `Port_Tab`,
`SerialPortSetting`, `set_PortName`, `set_BaudRate`, `set_DataBits`,
`set_Parity`, `set_StopBits`, `ReadExisting`, `BytesToRead`, `Write`,
`WriteLine`, `CommandIn`, `CommandTest`, `CommandTestButton`,
`CommandTestButton_Click`, `FC_Command_Send`, `CommThroughput`, `CommTime`,
`Send_Throughput`, `Receive_Throughput`, `rcvdata`, `ConnectButton_Click`,
`DisconnectButton_Click`, `PortStop`, `LogPath` and `LogTime`.

This establishes a selectable serial transport, serialized command exchange,
raw command testing and communication logging. It does not expose the full
command bytes in readable strings.

### Monitor and captured engine values

Identifiers include:

`EngineData`, `EngineDataDispSW`, `DataMonitor_Tab`, `CorrectionData`,
`CorrectionDataDispSW`, `EngineRev`, `EngineRev_d`, `Throttle`, `Throttle_d`,
`IntakePressure`, `IntakePressure_d`, `AirPressure`, `AirPressure_d`,
`WaterTemp`, `WaterTemp_d`, `AirTemp`, `AirTemp_d`, `BattVoltage`,
`BattVoltage_d`, `IgnitionTiming`, `IgnitionTiming_d`, `InjRe`, `InjRe_d`,
`VehicleSpeed`, `VehicleSpeed_d`, `A_F_d`, `A_F_Target_d`, `Kair_d`,
`Kwater_d`, `Kfbk_d`, `Kpow_d`, `Kpres_d`, `Kacc_d`, `Kidle_d`,
`KidleIG_d`, `Kinj_d`, `KinjIG_d`, `KknkIG_d`, `Kstart_d`, `Kstable_d`,
`Kaccstable_d`, `Kair_d` and `Kwater_d`.

The app should capture these as raw channels first. Only fields with verified
offset, endian order, scale, unit and plausibility range should enter safety
decisions.

### Maps

Recovered UI and event identifiers include:

- Fuel: `FuelMap`, `FuelMapDisp`, `FuelMap_Load`, `FuelMap_Load_Click_1`,
  `FuelMap_CellValueChanged`.
- Throttle: `ThrottleMap`, `ThrottleMapDisp`, `ThrottleMap_Load`,
  `ThrottleMap_Load_Click_1`, `ThrottleMap_CellValueChanged`.
- Ignition: `IGMap`, `IGMapDisp`, `IGMap_Load`, `IGMap_CellValueChanged`.
- Air/fuel: `AFMap`, `AFMapDisp`, `AFMap_Load`, `AFMap_Load_Click_1`,
  `AFMap_CellValueChanged`.
- Air pressure: `AirPressureMap_Learn`, `AirPressureMap_Learn_request`.
- VVT: `VVTOnMap`, `VVTOffMap`.
- Automatic map controls: `AutoMapEnable`, `MapEditEnable`, `AutoSaveSettings`.

The recovered `.FCP` files are key/value parameter maps. They are useful for
offline comparison and map identity, but do not prove live ECU map addresses.

### Learning and feedback

Recovered identifiers include:

`FCCS_LearnSW`, `FCCS_LearnSW_CheckedChanged`, `FCCS_LearnRate`,
`FCCS_LearnRate_d`, `FCCS_Learn_Meter`, `FCCS_Learn_IdleSW`, `LearnSW`,
`LearnSW_Click`, `FuelMap_LearnProtect`, `FuelMap_LearnProtect_CheckedChanged`,
`FuelMap_Learn_protect_request`, `ThrottleMap_Learn`,
`ThrottleMap_Learn_CheckedChanged`, `ThrottleMap_Learn_request`,
`AirPressureMap_Learn_CheckedChanged`, `AirPressureMap_Learn_request`,
`FeedbackSW`, `FeedbackSW_Click`, `Feedback_request`, `Feedback_idle`,
`Feedback_idle_CheckedChanged`, `Feedback_idle_request`, `Autoset_A_F_Target`,
`Autoset_A_F_d` and `Autoset_Kfbk_d`.

These are write-capable or behavior-changing areas. They remain locked in the
iPhone app until a version-gated read/write protocol is captured and a backup
and recovery procedure is proven.

### Start, idle, response and latency

Recovered areas include:

- Start/warm-up: `Starting_Tab`, `Start_Parm_Load`, `Start_Parm_Load_Click`,
  `StartInjectionTime`, `StartISC`, `StartPosition`, `Start_Inj`,
  `Start_Warmup_Param_Load_request`, `Start_Warmup_Param_Write_request`,
  `AfterStartIncrease`, `Cold_Parm_Load`, `Cold_Parm_Load_Click`.
- Idle: `Idle_Tab`, `Idle_Parm_Load`, `Idle_Parm_Load_Click`,
  `IdleStabilizeCorrection`, `idleIGTiming`, `IdleFLG`, `IdleSetupEnable`.
- Response/correction: `Response_Tab`, `Resp_Parm_Load`,
  `Resp_Parm_Load_Click`, `Resp_TempCorrection`, `Resp_FuelCutCorrection`,
  `Resp_SynchronousInjection`, `Resp_AsynchronousInjection`,
  `FuelUpRate`, `Fuel_Map_Adjust`, `Accel_Map_Adjust`.
- Latency: `Latency_Tab`, `LatencyMap`, `LatencyData`, `LatencySetup`,
  `LatencyTestStart_Click`, `LatencyTest_request`, `LatencyTimeChart1`,
  `LatencyTimeChart2`, plus throttle, engine-rev, injection, intake-pressure,
  air-temperature and water-temperature latency fields.

### Parameter controls

FCST exposes many `Kxx_d` controls and `ValueChanged` handlers, including
`K01` through `K06`, `K30`, `K31`, `K33`, `K35`, `K36`, `K38`, `K3D`, `K43`,
`K45` through `K52`, `K57`, `K61` through `K67`, `K69` through `K7F`, `K81`
through `K8F`, `K98`, `K9A`, `K9B`, `K9D`, `K9E`, `K9F`, `KA0` through `KA7`,
`KC2` through `KCF`, `KF0` through `KF7`, `KG2` through `KG4`, `KN8` through
`KND`, `KO9`, `KOA`, `KT1`, and `KV1` through `KV4`.

`KTABL.FCS` supplies parameter identifiers with scale/format columns, for
example `KSD`, `KDK`, `KKL`, `KKH`, `KKK`, `KKD`, `KPK`, `KPT`, `KA0` onward,
and many `KQ0`-style values. The table is not a semantic dictionary; names
must be mapped using controlled captures and known settings.

## FCSS native executable findings

`FCSS.EXE` imports direct Win32 serial functions:

`CreateFileA`, `ReadFile`, `WriteFile`, `SetCommState`, `SetCommTimeouts`,
`SetCommMask` and `PurgeComm`.

It references `COM0:`, `COM1:`, `FCDATA`, `KDATA.F*`, `HELPDATA.*`, `.FCP`,
`.LOG` and `LOGDSP`. This confirms a direct legacy serial client and a file-
based map/log workflow. It is not a modern OBD-II or CAN implementation.

`FCSS.CNF` contains:

```text
DR = 20v
KN = 0
KS = 0
CM = 0
HX = 0
```

`KDNOTBL.FCS` associates engine families and chassis examples including 4A-GE,
4A-GZE, B6-ZE, BP-ZE, 4E-FE/FTE, 3S-GE/GTE, 2E-E and WEBER applications.

`LOGDSP.EXE` is a separate native log display program, so `.LOG` files should
be treated as a first-class import/replay format, not merely debug output.

## Data and map audit

The nested FCSS archive contains 29 files totaling approximately 3.9 MB. It
includes the two executables, help databases, 14 KDATA variants, model tables,
one FCP map, configuration and key files.

The supplied base-map directory contains 18 `.FCP` files and one `SAMPLE.LOG`.
The text maps use lines such as:

```text
KSD = 0
KDK = 50
KKL = 12
KKH = 108
KPK = 1180
KA0 = 745
```

`SAMPLE.LOG` contains 24 numeric columns per row. It has no labels, header,
units or checksum definition. It must be imported as raw numeric data until a
matching FCSS/LOGDSP capture identifies each column.

## Protocol findings

### Confirmed starting transport

The project’s current documented starting profile is:

```text
RS-232C
9600 baud
7 data bits
even parity
1 stop bit
no flow control
```

### Candidate read-only transaction

The current research evidence identifies:

```text
Request:  ?DAT  (4 bytes)
Reply:    55-byte payload, with a possible trailing terminator
```

The terminator, handshake, checksum, field offsets, units, retries, timeout,
identity exchange and correction-data exchange remain unverified. No map,
parameter, learning or write command is implemented.

## Security and safety findings

| Severity | Finding | Action |
|---|---|---|
| Critical | Legacy software exposes write and learning controls that can affect engine behavior immediately. | Never replay these frames from the iPhone until ECU/version/backup gates exist. |
| High | Field names appear in software metadata, but raw byte offsets and scaling are not proven. | Keep raw payloads and label values unverified. |
| High | Physical custom cable pinout and voltage levels are not proven by the software. | Verify cable continuity, DB9 pinout, signal levels and ground before power. |
| Medium | `SAMPLE.LOG` has unlabeled numeric columns. | Preserve raw rows and require a mapping fixture before safety use. |
| Medium | FCST settings such as learn rate and thresholds are local application defaults. | Do not promote them to ECU defaults. |

## Correct app deployment model

The recovered capabilities belong in the existing workflows:

| Captured output | App destination | Initial state |
|---|---|---|
| Serial settings and connection timing | Connection screen | Read-only diagnostics |
| Raw `?DAT` bytes and timestamps | Raw frames and session bundle | Always retained |
| Verified live fields | Live dashboard | Only after field verification |
| FCP maps and map axes | Map tab | Offline/reference first |
| LOG samples | Runs/Review | Replay and comparison |
| Corrections/learning observations | Runs/Review | Analysis only |
| Parameter identities and limits | Garage/ECU capabilities | Evidence-labelled |
| Writes and learning toggles | No user action yet | Permanently locked in current release |

## Current app changes

- Removed the user-facing FCSS/FCST category.
- Distributed the useful recovered capabilities into Live, Settings, Maps and
  Limits in `S43View`.
- Added the read-only capture plan to the Connection screen.
- Updated Data Sources to show raw `?DAT` capture and unverified field status.
- Added `transport.json` and `fc03-dat.raw` to the session export model.
- Kept the native `FC03Protocol` implementation read-only.

## What cannot be extracted from this capture alone

- Original C#/VB source code and comments.
- Exact serial command bytes for every UI action.
- Complete field semantics for `Kxx` identifiers.
- Firmware-specific map memory addresses.
- Exact checksum/CRC algorithm.
- ECU identity/version handshake.
- Safe write/rollback semantics.

Those require a controlled serial capture with the actual ECU, cable and
adapter. The next safe experiment is repeated connection and `?DAT` capture
with the engine stopped, followed by field correlation against known inputs.

