from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .contracts import sha256_file


class AdapterResult:
    def __init__(self, *, adapter: str, supported: bool, frames: list[dict[str, Any]], reason: str, source_hash: str):
        self.adapter, self.supported, self.frames, self.reason, self.source_hash = adapter, supported, frames, reason, source_hash

    def as_dict(self) -> dict[str, Any]:
        return {"adapter": self.adapter, "supported": self.supported, "frame_count": len(self.frames), "reason": self.reason, "source_sha256": self.source_hash}


def load_json(path: Path) -> AdapterResult:
    value = json.loads(path.read_text(encoding="utf-8"))
    frames = value.get("frames", value) if isinstance(value, dict) else value
    if not isinstance(frames, list) or not all(isinstance(frame, dict) for frame in frames):
        return AdapterResult(adapter="json", supported=False, frames=[], reason="expected a JSON array or {frames: []}", source_hash=sha256_file(path))
    if frames and not any(isinstance(frame.get("decoded", frame), dict) and "rpm" in frame.get("decoded", frame) for frame in frames):
        return AdapterResult(adapter="raw-serial-json", supported=False, frames=frames, reason="raw serial capture is preserved; a verified Freedom decoder is required before telemetry analysis", source_hash=sha256_file(path))
    return AdapterResult(adapter="canonical-json", supported=True, frames=frames, reason="canonical fixture/log format", source_hash=sha256_file(path))


def freedom_export(path: Path, *, ecu_identity: str | None, format_version: str | None) -> AdapterResult:
    """Never guess a Freedom export mapping: identity and format must be declared."""
    if not ecu_identity or not format_version:
        return AdapterResult(adapter="freedom-export", supported=False, frames=[], reason="missing ECU identity or export format version", source_hash=sha256_file(path))
    return AdapterResult(adapter="freedom-export", supported=False, frames=[], reason="Freedom export mapping is not yet verified for this identity/version", source_hash=sha256_file(path))
