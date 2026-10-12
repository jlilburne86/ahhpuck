# Hiro0719jp Freedom/FCST cross-platform research

## Local capture

- Blog source: `https://ameblo.jp/hiro0719jp/`
- Local archive: `downloads/hiro0719jp_freedom/`
- Manifest: `downloads/hiro0719jp_freedom/manifest.json`
- Captured: 34 article pages and 468 embedded image/assets files.
- Capture utility: `tools/capture_hiro0719jp.py`

The archive includes unrelated AE86 maintenance posts because the blog homepage
is chronological. The Freedom/FCST-specific entries are identified by titles in
the manifest and include the protocol-analysis and FCST-development series.

## Highest-value findings

### 1. USB-RS232 communication is the core architecture

The early development posts describe using a USB-RS232 converter to send
commands to Freedom and receive responses. The author explicitly treats stable,
accurate serial communication as the central reliability problem and develops a
command-send/receive function around it.

Evidence: `entry-11412516410`, `entry-11412525148`, `entry-11543390264`.

Engineering consequence: our transport must be a serialized request/response
queue with one in-flight command, explicit timeout, response-length/framing
validation, and replay tests. UI button actions must never interrupt an active
serial transaction.

### 2. PortMon was used to reverse-engineer FCSS traffic

The author used PortMon while operating FCSS to observe the RS232 traffic and
identify useful commands. This is a strong practical lead for our read-only
protocol work, but it is a community investigation, not an E&E Systems
specification.

Evidence: `entry-11412525148`.

Engineering consequence: capture the same operations with direction, timestamp,
baud/framing, ECU identity, FCSS version, and cable/adapter details. Do not
generalize a command from one FC-03a/internal-version combination to the user's
Ab-1EU unit.

### 3. A published timing estimate supports live monitoring

One article reports a `?DAT` request of four bytes and a 55-byte response, with
one terminating byte on each direction, for 61 bytes / 488 bits. At 9600 bps,
the serial transfer alone is estimated at approximately 51 ms. A second
correction-data exchange gives an estimated total above 100 ms before ECU and
application processing.

Evidence: `entry-11572229193`.

Engineering consequence: design initial live monitoring around measured
approximately 5–10 Hz behavior, but treat this as a hypothesis. The app must
measure actual frame age and declare stale data; it must not assume a fixed rate.

### 4. Community flag commands exist but are version-specific

An article reports read/write experiments for five feedback/learning-related
flags on an FC-03a, internal version 6.51, using FCSS 1.62. The author explicitly
limits the result to that tested combination and disclaims compatibility with
other versions.

Evidence: `entry-11548558605`.

Engineering consequence: store these as unverified research vectors only. Do not
send them to the user's FC-03/Ab-1EU. First identify the ECU, internal version,
option flags, response shape, and rollback behavior in a read-only session.

### 5. MacBook/Boot Camp was a compatibility workaround

The author experimented with a MacBook Air running Windows through Boot Camp
and an RS232-to-USB cable. A 64-bit driver problem was encountered with an older
adapter, motivating older/32-bit Windows or another adapter/workaround.

Evidence: `entry-11492183426`.

Engineering consequence: this proves a Mac can host the legacy workflow through
an operating-system compatibility layer, not that iOS can directly access the
same adapter. It also confirms adapter drivers are a real compatibility risk.

### 6. iPhone/Android use was initially a remote-display workflow

The older field-test article describes using an iPhone as a touch-enabled
secondary display over Wi-Fi with Air Display. The ECU connection remained on a
computer; the phone was not necessarily a direct RS232 host.

Evidence: `entry-11586352118`, `entry-11616893447`.

Engineering consequence: the article supports a useful fallback architecture:
Mac/PC owns the ECU serial link, while an iPhone/Android device displays live
telemetry and receives safe UI actions over a local network. This is lower risk
than assuming direct iPhone USB serial support.

### 7. Surface/UGREEN is a useful direct-host reference

The later FCST article reports a working environment with an FC-03a configured
for an AE111, direct ignition and air-fuel feedback option, a UGREEN USB-RS232C
serial cable, and Microsoft Surface Go2 on Windows 10/11. The described flow is
select COM port, power the ECU, connect, view Monitor data, then load maps or
constants in the Set tab.

Evidence: `entry-12853087956`.

Engineering consequence: this is the strongest practical adapter/host
reference, but it is still FC-03a-specific and includes map-setting operations.
Use it to reproduce read-only connection/monitor behavior first; do not infer
that the same UGREEN chipset will be accepted by iOS.

### 8. Apple Silicon Mac required another compatibility layer

The later development entry describes an Apple Silicon MacBook Air, Visual
Studio/ARM difficulties, serial-driver problems, and eventual Windows 11 in
Parallels as the working route for the development environment.

Evidence: `entry-12897880008`.

Engineering consequence: native macOS/iOS transport is still valuable, but the
legacy Windows tool and its drivers should be treated as separate from our
portable protocol core.

## Confirmed design direction

Use three transport modes:

1. **Native direct**: iPhone/macOS USB bridge, only after iOS adapter and FC-03
   framing are verified.
2. **Local bridge**: Mac/Windows/Linux host owns RS232; iPhone/Android connects
   over a local authenticated network for display and control.
3. **Replay**: captured FCSS/FCST frames drive the UI and safety monitor without
   a vehicle attached.

All modes share the same normalized telemetry, LiveSafetyMonitor, immutable log,
and read-only protocol layer. Write commands remain disabled.

## Evidence boundary

- `documented by author`: adapter/host combinations and workflow described in
  the article;
- `observed local capture`: article content and image assets preserved here;
- `inferred`: likely portable transport and sampling architecture;
- `unverified`: compatibility of any command, adapter, framing, or write path
  with the user's FC-03 Ab-1EU.
