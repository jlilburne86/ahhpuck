"""Paths to the local, non-public AhhPuck research evidence archive."""
from __future__ import annotations

import os
from pathlib import Path


def evidence_root() -> Path:
    """Return the evidence root, overridable for another local checkout."""
    return Path(os.environ.get("AHHPUCK_EVIDENCE_ROOT", "/Users/boo2/ahhpuck-evidence")).expanduser()
