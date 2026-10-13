from __future__ import annotations

import json
import shutil
from pathlib import Path
from typing import Any

from .contracts import envelope, sha256_file, write_json


class ArtifactError(ValueError):
    """Raised when a local artifact cannot be preserved safely."""


def _metadata(value: dict[str, Any] | None) -> dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise ArtifactError("metadata must be a JSON object")
    return value


def _copy_artifact(source: Path, output: Path, *, kind: str, metadata: dict[str, Any], parser: str) -> dict[str, Any]:
    if not source.is_file():
        raise FileNotFoundError(source)
    if output.exists():
        raise FileExistsError(output)
    output.mkdir(parents=True)
    raw = output / source.name
    shutil.copy2(source, raw)
    record = envelope("artifact-record", {
        "artifact_id": output.name,
        "artifact_type": kind,
        "original_name": source.name,
        "raw_path": raw.name,
        "raw_sha256": sha256_file(raw),
        "format": source.suffix.lower().lstrip(".") or "unknown",
        "parser": {"name": parser, "version": "0.1"},
        "metadata": metadata,
        "evidence_status": "declared_unverified",
        "write_authorization": "never",
    })
    write_json(output / "record.json", record)
    return record


def create_tune(source: Path, output: Path, metadata: dict[str, Any] | None = None) -> dict[str, Any]:
    """Preserve a tune and provenance without assigning undocumented semantics."""
    parser = "raw-preservation"
    parsed_summary: dict[str, Any] | None = None
    if source.suffix.lower() == ".fcp":
        from fcp_parser import parse_fcp

        parsed = parse_fcp(source)
        parser = "fcp_parser.py"
        parsed_summary = {
            "scalars": sorted(parsed["scalars"]),
            "tables": {
                name: {
                    "row_count": value["row_count"],
                    "column_counts": value["column_counts"],
                    "semantic": value["semantic"],
                }
                for name, value in parsed["tables"].items()
            },
        }
    record = _copy_artifact(source, output, kind="tune", metadata=_metadata(metadata), parser=parser)
    if parsed_summary is not None:
        record["payload"]["parser_summary"] = parsed_summary
        write_json(output / "record.json", record)
    return record


def create_log(source: Path, output: Path, metadata: dict[str, Any] | None = None) -> dict[str, Any]:
    """Preserve a log; decoding and channel mapping remain explicit later steps."""
    parser = "raw-preservation"
    if source.suffix.lower() in {".json", ".jsonl"}:
        parser = "canonical-json-or-raw-capture"
    return _copy_artifact(source, output, kind="log", metadata=_metadata(metadata), parser=parser)


def load_record(path: Path) -> dict[str, Any]:
    record = json.loads((path / "record.json").read_text(encoding="utf-8"))
    if record.get("kind") != "artifact-record" or record.get("payload", {}).get("write_authorization") != "never":
        raise ArtifactError("invalid or unsafe artifact record")
    return record
