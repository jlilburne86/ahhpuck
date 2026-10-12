from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
from typing import Any

from .contracts import envelope, now, stable, write_json

STATES = {"verified", "declared_unverified", "inferred", "unknown", "contradicted"}


def _status(value: Any) -> str:
    if isinstance(value, dict):
        return value.get("status", "unknown")
    return "unknown"


def validate(passport: dict[str, Any]) -> list[str]:
    errors = []
    for key in ("engine_id", "ecu", "components"):
        if key not in passport:
            errors.append(f"missing {key}")
    if _status(passport.get("ecu")) not in STATES:
        errors.append("ecu.status is invalid")
    for name, item in passport.get("components", {}).items():
        if _status(item) not in STATES:
            errors.append(f"components.{name}.status is invalid")
    return errors


def revision(passport: dict[str, Any]) -> str:
    material = copy.deepcopy(passport)
    material.pop("revision", None)
    material.pop("updated_at", None)
    return hashlib.sha256(stable(material).encode("utf-8")).hexdigest()[:16]


def create(engine_id: str, ecu: dict[str, Any], components: dict[str, Any], purpose: str = "diagnostic") -> dict[str, Any]:
    result = {"engine_id": engine_id, "ecu": ecu, "components": components, "purpose": purpose, "created_at": now()}
    result["revision"] = revision(result)
    result["status"] = "ready" if not validate(result) else "incomplete"
    return envelope("engine-passport", result)


def save(path: Path, passport: dict[str, Any]) -> None:
    payload = passport.get("payload", passport)
    errors = validate(payload)
    if errors:
        raise ValueError("invalid passport: " + ", ".join(errors))
    write_json(path, passport)
