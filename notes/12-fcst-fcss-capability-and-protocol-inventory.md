# FCSS / FCST software and protocol inventory

Status: static inventory complete; live ECU protocol still requires a captured
read-only session with the user's FC-03 unit.

## Executive result

The supplied software is not one single program:

| Layer | Local artifact | What it appears to do | Porting status |
|---|---|---|---|
| Legacy ECU client | Private archive: `extracted/software/(FCSS) Freedom Computer Support System Software/FCSS.EXE` | Direct Windows serial access, ECU setup, maps, parameters and live operation | Preserve as reference; do not run or reproduce writes yet |
| Log viewer | `.../LOGDSP.EXE` | Opens/displays legacy `.LOG` data | Reproduce the file reader only after field labels are confirmed |
| Newer companion UI | Private archive: `extracted/FCST/AnyCPU/FCST/FCST.exe` | Serial connection, monitor values, map/parameter views, learning and adjustment tools | Port the read-only monitor first |
| Data tables/help | `KDATA.*`, `KTABL.FCS`, `KDNOTBL.FCS`, `HELPDATA.*`, `.FCP`, `SAMPLE.LOG` | Labels, scale/format data, vehicle references, help text and example maps/logs | Use for metadata and replay fixtures; not proof of wire offsets |

`FCST.exe` is a 32-bit .NET/Mono Windows GUI application. `FCSS.EXE` and
`LOGDSP.EXE` are older 32-bit Windows binaries. The FCST configuration records
`.NET Framework 4.8`, default `COM3`, and an FCCS learn rate of `40`; these are
application defaults, not ECU protocol requirements.

## Capability inventory recovered from FCST

The following names are present in the executable's managed metadata and are
therefore strong evidence that the UI contains, or was built to contain, these
functions. They are not proof that every function is compatible with every
FC-03 firmware revision.

### Connection and diagnostics

- Serial-port enumeration and selection (`SerialPortNames`, `PortSelect`).
- Connect/disconnect actions and connection state.
- Serial settings, including baud rate, data bits, parity and stop bits.
- Raw command entry/test (`CommandIn`, `CommandTest`, `FC_Command_Send`).
- Read/write byte transport and existing-buffer reads.
- Send/receive throughput and communication-time measurements.
- Command logging, log path and timestamp controls.

### Monitor and live data

- Engine-data monitor and correction-data monitor.
- Engine revolution, throttle, intake pressure, air pressure, water
  temperature, air temperature, battery voltage, ignition timing and related
  correction values.
- Display switches for engine and correction data.
- Feedback/learning indicators, idle feedback and fuel-cut state.
- Charting/data-grid UI components.

### Maps and calibration pages

- Fuel map load/display/edit and cell-change handlers.
- Throttle map load/display/edit and cell-change handlers.
- Ignition map load/display/edit and cell-change handlers.
- Air/fuel map load/display/edit and cell-change handlers.
- Atmospheric/air-pressure map and air-pressure learning.
- VVT on/off maps.
- Base parameter and base-setting load paths.

### Learning, correction and automatic adjustment

- FCCS learning switch, learning rate, learning display/meter and idle-learning
  controls.
- Fuel-map learning protection.
- Throttle-map learning.
- Air-pressure-map learning.
- Automatic fuel/air-fuel target and feedback adjustment controls.
- Fuel-up rate, fuel-map adjustment, acceleration-map adjustment and throttle
  ratio controls.
- Air, water and temperature correction values.
- Fuel-cut correction and transient/response correction.
- Latency maps/tests for throttle, intake pressure, air temperature and water
  temperature.

### Start, idle, ignition and engine behaviour

- Starting/warm-up parameters and cold parameters.
- Start injection time, start ISC and start position.
- Idle parameters, idle stabilisation correction and idle ignition timing.
- Ignition parameters and ignition timing.
- Ignition knock-control settings.
- Throttle asynchronous injection and fuel-cut flags.
- Stable RPM and latency-related settings.

### Persistence and file operations

- Load/save controls for maps and parameter groups.
- Automatic-save setting.
- FCST user settings persisted through its configuration store.
- FCSS file families include `.FCP` maps and `.LOG` captures.

## Legacy FCSS evidence

Static strings in `FCSS.EXE` show direct Win32 serial APIs (`CreateFile`,
`ReadFile`, `WriteFile`, `SetCommState`, `SetCommTimeouts`, `PurgeComm`) and
legacy port names (`COM0:`, `COM1:`). It also references `FCDATA`, `KDATA.F*`,
`.FCP`, `.LOG`, help data and `LOGDSP`. This confirms that FCSS is a direct
serial ECU client and not a modern OBD/CAN abstraction.

`KTABL.FCS` contains parameter identifiers such as `KSD`, `KDK`, `KKL`, `KKH`,
`KKK`, `KKD`, `KPK`, `KPT` and `KA0` onward with scale/format columns.
`KDNOTBL.FCS` contains engine/model associations including 4A-GE, 4A-GZE,
B6-ZE, BP-ZE, 4E-FE/FTE and 3S-GE/GTE. These are useful calibration metadata,
but do not establish the physical meaning of a live-data byte.

## Protocol evidence and confidence

### Transport profile — documented starting point

| Item | Starting value | Confidence |
|---|---:|---|
| Electrical family | RS-232C | documented by community FCSS setup material |
| Baud | 9600 | documented by community FCSS setup material |
| Data bits | 7 | documented community setting |
| Parity | even | documented community setting |
| Stop bits | 1 | documented community setting |
| Flow control | none | engineering starting assumption; verify on capture |
| Direction | serialized request/response | observed/reported workflow |

### First read-only exchange — hypothesis to validate

The preserved research notes report a four-byte `?DAT` request and a 55-byte
response, with a terminating byte in each direction. This is enough to build a
capture harness and a shape validator, but not enough to decode telemetry.
Unknown items include:

- whether the terminator is `CR`, `LF`, NUL, or another byte;
- whether the 55 bytes are always present across FC-03 variants;
- field offsets, endian order, signedness, scaling and units;
- ECU identity/version handshake before polling;
- checksum/CRC, if any;
- timeout and retry rules;
- correction-data exchange after the main data exchange;
- command IDs for maps, constants, learning and writes.

The software and UI names must not be treated as command names. `FuelMap_Load`
or `Start_Warmup_Param_Write_request` tells us the feature exists in FCST; it
does not reveal a safe frame, address, checksum or rollback procedure.

### Version-specific research

Community notes describe feedback/learning flag commands for an FC-03a with a
particular internal version and FCSS release. Those commands are deliberately
not included in the iPhone transport. They must be treated as versioned
research vectors until the user's ECU identifies itself and the same frames are
captured and replayed safely.

## What is implemented in the iPhone app

`FreedomMobileCore/FC03Protocol.swift` now contains:

- a typed 9600/7E1/no-flow-control starting profile;
- a read-only `?DAT` request;
- strict 55-byte or 56-byte response-shape validation;
- preservation of the raw payload and candidate terminator;
- an explicit `isFieldDecoded == false` boundary;
- no ECU write API.

`IOSUSBTransport` exposes the profile and validator for the future bridge, but
still refuses to connect until the exact USB-C adapter, cable pinout and iOS
USB path are tested. This is intentional: a successful serial open is not
protocol verification.

## Capture protocol for the desk ECU

1. Photograph and record ECU model, serial/firmware/internal version, adapter,
   cable wiring and power supply.
2. Verify the custom cable with a multimeter before applying ECU power.
3. Capture idle bytes with direction and timestamps at 9600 7E1.
4. Run only connection/identify and monitor/read operations in FCSS/FCST.
5. Repeat each operation at least three times and compare raw frames.
6. Save captures as immutable fixtures with adapter and ECU metadata.
7. Infer framing, terminators, lengths and checksums before mapping fields.
8. Decode one field at a time against a known instrument or controlled input.
9. Keep map, parameter, learning and real-time write commands disabled until a
   complete backup/restore procedure and version gate exist.

## Porting plan

### Phase A — safe and already in progress

- Replay raw `.LOG` and captured frames.
- Add connection diagnostics and raw byte capture.
- Implement ECU identity and `?DAT` shape validation.
- Build normalized telemetry only from verified field definitions.

### Phase B — read-only parity

- Decode monitor and correction data.
- Reproduce live monitor timing, stale-data detection and immutable logs.
- Import/display `.FCP` and the supplied base maps as offline reference data.
- Show map/cell context without sending edits to the ECU.

### Phase C — gated authoring, only after evidence

- Add versioned map/parameter schemas.
- Add backup hash, diff, operator approval and recovery verification.
- Keep writes behind an explicit development build flag and a hardware profile
  gate.

### Phase D — learning assistant

- Use baseline/candidate/repeat-run comparisons in the app.
- Generate recommendations from verified telemetry and operator-approved
  changes.
- Do not silently apply learning. FCST's learning controls are evidence that
  the capability exists, not authorization to reproduce it automatically.

## External references

- Club4AG FCSS archive and FC-03 cable reference:
  https://www.club4ag.com/FREEDOM/FCSS.htm
- Hiro0719jp FC-03 RS-232/USB connection report:
  https://ameblo.jp/hiro0719jp/entry-12788073257.html
- Hiro0719jp FC cable repair and wiring warning:
  https://ameblo.jp/hiro0719jp/entry-12814058069.html
- Kunugi Runner FCSS setup/operation notes:
  https://kunugi-runner.com/2020/10/22/4409/

