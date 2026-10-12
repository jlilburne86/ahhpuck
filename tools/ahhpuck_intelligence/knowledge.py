from __future__ import annotations

import json
from pathlib import Path
from typing import Any


class KnowledgeError(ValueError):
    pass


def load_registry(root: Path) -> tuple[dict[str, Any], dict[str, Any]]:
    manifest = json.loads((root / "knowledge/source-manifest.json").read_text(encoding="utf-8"))
    cards = json.loads((root / "knowledge/rule-cards.json").read_text(encoding="utf-8"))
    sources = {item["id"]: item for item in manifest.get("sources", [])}
    if len(sources) != len(manifest.get("sources", [])):
        raise KnowledgeError("source IDs must be unique")
    for card in cards.get("cards", []):
        source_id = card.get("source", {}).get("id")
        if source_id not in sources:
            raise KnowledgeError(f"rule card {card.get('id')} cites unknown source {source_id}")
        if card.get("evidence") not in {"documented", "observed", "inferred", "unsafe/unverified"}:
            raise KnowledgeError(f"rule card {card.get('id')} has invalid evidence label")
    return manifest, cards


def claims_for(root: Path, ids: list[str] | None = None) -> list[dict[str, Any]]:
    _, cards = load_registry(root)
    selected = cards.get("cards", [])
    if ids is not None:
        selected = [card for card in selected if card.get("id") in set(ids)]
    return selected


def cite(card: dict[str, Any]) -> dict[str, str]:
    source = card["source"]
    return {"claim_id": card["id"], "source_id": source["id"], "location": source.get("location", "")}
