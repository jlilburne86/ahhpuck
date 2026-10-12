from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any

from .contracts import envelope, now, sha256_file, write_json


def create(root: Path, passport: Path, inputs: list[Path], purpose: str = "baseline") -> dict[str, Any]:
    """Create an append-only session copy; source files are never modified."""
    root.mkdir(parents=True, exist_ok=False)
    files = []
    passport_copy = root / "profile.json"
    shutil.copy2(passport, passport_copy)
    files.append({"path": passport_copy.name, "sha256": sha256_file(passport_copy), "role": "passport"})
    for source in inputs:
        if not source.is_file():
            raise FileNotFoundError(source)
        target = root / source.name
        if target.exists():
            raise ValueError(f"duplicate session filename: {target.name}")
        shutil.copy2(source, target)
        files.append({"path": target.name, "sha256": sha256_file(target), "role": "input"})
    manifest = envelope("session-manifest", {"session_id": root.name, "purpose": purpose, "files": files, "write_authorization": "never"})
    write_json(root / "manifest.json", manifest)
    return manifest
