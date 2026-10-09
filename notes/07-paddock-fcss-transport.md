# Paddock-N FCSS transport findings

Source: user-supplied excerpt from the Paddock-N FCSS setup article. The full
page is also recorded in the project research sources as the Paddock-N FCSS
reference.

## Observed/documented claims

- FCSS is E&E Systems' configuration software for Freedom Computer.
- The Freedom Computer rotary DIP switches select, copy, or initialize already
  stored settings; they are not a replacement for FCSS configuration.
- PC-to-Freedom communication uses RS232C.
- The article reports a communication speed of 9600 bps.
- FCSS exists in DOS, Windows 1.xx, and Windows 2.xx families.
- Legacy FCSS directly accesses RS232C and can be sensitive to modern serial
  conversion adapters and Windows compatibility layers.

## Engineering implications

1. The first iPhone/macOS transport target is a raw serial bridge, not a
   modern CAN or OBD protocol.
2. 9600 bps should be the initial read-only capture setting.
3. Data bits, parity and stop bits are documented by a long-term FCSS user as
   7 data bits, even parity, 1 stop bit (7E1) at 9600 bps, with no flow control
   (`documented`, hiro0719jp FCSS article). Electrical levels, cable pinout,
   command framing, response framing, timeouts, and checksum behavior remain
   unverified until captures are made with the actual cable and ECU.
4. The app must not assume that an adapter that works with a normal USB serial
   terminal is electrically or protocol-compatible with the Freedom Computer.
5. FCSS compatibility problems strengthen the case for a narrow, deterministic
   read-only transport adapter and replay-based testing.
6. The rotary switches must be documented as vehicle/ECU state, not treated as
   an alternate way to configure unknown maps.

## Required capture plan

- Capture connection idle state at 9600 bps.
- Capture FCSS identify/read-only operations with timestamps and direction.
- Repeat each operation at least three times and compare frames byte-for-byte.
- Record adapter model, cable wiring, electrical level, OS, and FCSS version.
- Test disconnect, delayed response, malformed response, and power-cycle cases.
- Do not capture or replay a write operation until read framing and backup
  recovery are proven.

Evidence level: the 9600-bps/legacy-FCSS statements are `documented` from the
source excerpt; frame semantics and write behavior remain `unverified`.

## Kunugi Runner operational findings

The Kunugi Runner FCSS reference documents a specific FC-03K with the
air-fuel-meter-linked option and FCSS for Windows 2.14. It reports:

- FCSS can show live sensor/control values in monitor pages.
- FCSS has real-time mode where changes are applied immediately.
- Incorrect values can freeze the legacy software and may stop the engine.
- Map trace shows the currently referenced map area.
- Transfer mode can read ECU data to a file or send full/partial data back.
- Log capture is approximately every 0.2–0.25 seconds, with up to 5000 points
  (roughly 15 minutes according to the article).
- The article recommends backing up settings and states that its explanations
  are not the official manual and may contain interpretation errors.

These findings make the product boundary stricter: the first implementation may
replay and display logs and use live monitor data, but must not implement
real-time map editing, partial transfers, or writes. The timing information is a
useful capture-rate hypothesis, not proof that every FC-03 variant or option
uses identical frames.
