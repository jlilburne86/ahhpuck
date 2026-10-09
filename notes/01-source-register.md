# Source register

## User-provided sources

| Source | Status | Notes |
|---|---|---|
| `source_files/FCSS_MAP_BASE_DATA.zip` | Preserved/extracted | 19 files: AE86 maps, generic 4-valve/4-throttle maps, MIXCONT.FCP, and SAMPLE.LOG. No filename explicitly identifies an AE101/AE111 map. |
| `source_files/FCSS_ECU_SOFTWARE.zip` | Preserved/extracted | Contains nested FCSS package, FCSS/LOGDSP executables, help databases, KDATA tables and one example FCP map. |
| Club4AG serial cable diagram | Pending local download | External reference for the physical RS-232 cable. |
| Kunugi Runner FCSS manual | Partially captured via web research | Community manual covering FCSS menus, maps, option codes and setup. |
| Paddock-N Freedom/FCSS/FCST setup site | Captured locally | Describes live connection/logging workflow and a separate FCST companion tool. |
| Microsoft Store `9nt9s7zvmvft` | Store metadata and package captured locally | `FreedomComputerSettingTool` / `FCST`, publisher `Paddock-N`, Japan-market listing. Product metadata: `downloads/microsoft_store_product_JP.json`; package family `Paddock-N.8081498DAC5B_tgkkskx45dcaa`; version `0.2.7.0`. |
| Microsoft official web installer | Captured locally | `source_files/FCST/FreedomComputerSettingTool-WebInstaller.exe`; PE32 .NET Store web-installer stub, SHA-256 `8e4960e8a4acb669a21e57a89d0ae8a7ca1329f5208c03fd5a440b14efe20179`. Static strings show generic Store package download/install APIs; it is not the FCST app payload. |
| FCST Store bundle | Downloaded and verified | `source_files/FCST/Paddock-N.8081498DAC5B_0.2.7.0_neutral_~_tgkkskx45dcaa.appxbundle`; SHA-256 `6a16ebd3b37e7aa9ec3244b155631deb01a4f359f9bf17baf07faef0abebf9aa`, matching Store digest `ahbr07N+eqnsMkSxVWMd6wGk81n5vxe68H+u8Kvr+ao=`. ZIP integrity passes; nested `Setup_0.2.7.0_AnyCPU.appx` contains `FCST/FCST.exe`. |

## Important external research leads

- Club4AG archives FCSS support files, base maps and a serial cable pin diagram: https://club4ag.com/FREEDOM/FCSS.htm
- Kunugi Runner community FCSS manual index: https://kunugi-runner.com/info/4377/
- Kunugi Runner product/option identification: https://kunugi-runner.com/2020/10/21/4361/
- AE86/AE111 owner report describing FCSS serial protocol analysis with PortMon: https://ameblo.jp/hiro0719jp/entry-11412525148.html

## Known research gap

No complete public modern FC-03 protocol implementation, map editor, or autonomous learning tool has been identified yet. The protocol-analysis report is the strongest lead for building a read-only logger.

## New high-value lead: FCST

The Paddock-N material describes `FCST`, a companion application developed around Freedom. It is intended to assist with injection-map, throttle-correction and transient tuning where FCSS is difficult to use. The material explicitly says FCST is not standalone, does not provide parameter persistence, and requires frequent FCSS backups. It also states that A/F-map protocol support was not implemented, so FCSS remains required for A/F-map editing. This is an existing partial third-party implementation, not a complete self-learning ECU replacement.

Local captures:

- `downloads/paddock_freedom_setup.html`
- `downloads/paddock_fcst_development.html`
- `downloads/paddock_fcst_environment.html`
- `downloads/paddock_fcss_limits.html`

Local FCST package analysis:

- `extracted/FCST/.../AnyCPU/FCST/FCST.exe` is a 32-bit .NET assembly; executable SHA-256 `dc86e549051ecf62e9d4a182ea3911db92648d55a8d5b51fb894721647e641de`.
- Static identifiers expose `System.IO.Ports.SerialPort`, serial-port selection, baud-rate settings, FCSS learn controls, fuel/ignition/throttle/A/F maps, logging, and adjustment controls. This is a strong starting point for documenting the live protocol and map model.
- The app manifest identifies target Windows Universal/Desktop, minimum version `10.0.14393.0`, and .NET Framework `4.5.1`.
- The package resolver source is preserved at `tools/ms_store_download.py` (SHA-256 `e5402982efa9dafb35b5e77e86c5895b835e9a1432f52379d85c75d41cedb825`).
