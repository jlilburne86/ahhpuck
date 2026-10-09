# Freedom Workshop browser UI

This is the Mac/browser front end. It uses Web Serial from Chrome or Edge on macOS, so no Windows support is required. Serve it from localhost:

```sh
cd /Users/boo2/freedom-ecu-research/web-ui
python3 -m http.server 8765
```

Open <http://localhost:8765>. Choose the USB serial adapter and the baud rate only after it has been confirmed from FCSS traffic.

The build is intentionally read-only. It captures raw bytes and exports JSON. The Review experiment screen also accepts baseline, candidate, and repeat telemetry files locally, calculates comparison statistics, shows concerns, and gates supervised approval. It does not send ECU commands, alter maps, or make autonomous tuning changes.

## Imported Freedom Mobile design

The Claude Design export is preserved as a runnable local design build:

```text
web-ui/freedom-mobile/Freedom Mobile.dc.html
web-ui/freedom-mobile/ios-frame.jsx
web-ui/freedom-mobile/support.js
```

Start the local server from `web-ui`:

```sh
cd /Users/boo2/freedom-ecu-research/web-ui
python3 -m http.server 8766
```

Open:

```text
http://localhost:8766/freedom-mobile/Freedom%20Mobile.dc.html
```

The imported design is a self-contained interaction prototype with owner/tuner density, live, run, review, ledger, setup, approval, fault, and scenario states. Its displayed telemetry is currently demo state from the design source; the existing workbench remains the read-only telemetry import and statistics implementation.
