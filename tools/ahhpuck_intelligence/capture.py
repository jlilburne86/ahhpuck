from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any

from .contracts import envelope, sha256_file, write_json
from .session import create as create_session


class CaptureError(ValueError):
    pass


def read_raw(path: Path) -> list[dict[str, Any]]:
    value = json.loads(path.read_text(encoding="utf-8"))
    frames = value.get("frames", value) if isinstance(value, dict) else value
    if not isinstance(frames, list):
        raise CaptureError("raw capture must be a JSON array or an object with frames")
    for index, frame in enumerate(frames):
        if not isinstance(frame, dict) or frame.get("direction") not in {"rx", "tx"}:
            raise CaptureError(f"frame {index} is missing rx/tx direction")
        if not isinstance(frame.get("timestamp"), str):
            raise CaptureError(f"frame {index} is missing an ISO timestamp")
        bytes_value = frame.get("bytes")
        if not isinstance(bytes_value, list) or any(not isinstance(item, int) or item < 0 or item > 255 for item in bytes_value):
            raise CaptureError(f"frame {index} has invalid byte data")
        if not isinstance(frame.get("sequence"), int):
            raise CaptureError(f"frame {index} is missing a sequence number")
    sequences = [frame["sequence"] for frame in frames]
    ordered = all(right > left for left, right in zip(sequences, sequences[1:]))
    if frames and not ordered:
        raise CaptureError("capture sequence is not strictly increasing")
    return frames


def bundle(output: Path, passport: Path, raw_capture: Path, *, baud: int = 9600, data_bits: int = 7, parity: str = "even", stop_bits: int = 1) -> dict[str, Any]:
    frames = read_raw(raw_capture)
    manifest = create_session(output, passport, [raw_capture], "raw-serial-capture")
    copied_capture = output / raw_capture.name
    report = envelope("raw-capture-report", {
        "capture_file": copied_capture.name,
        "capture_sha256": sha256_file(copied_capture),
        "frame_count": len(frames),
        "transport": {"baud": baud, "data_bits": data_bits, "parity": parity, "stop_bits": stop_bits, "flow_control": "none"},
        "sequence": {"present": True, "strictly_increasing": True},
        "decoded_telemetry": False,
        "next_gate": "verified Freedom frame decoder",
        "write_authorization": "never",
    })
    write_json(output / "capture-report.json", report)
    return {"manifest": manifest, "report": report}
