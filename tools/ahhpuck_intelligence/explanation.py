from __future__ import annotations

from typing import Any

from .knowledge import cite, claims_for


def build(root, observation: str, findings: list[dict[str, Any]], claim_ids: list[str] | None = None) -> dict[str, Any]:
    cards = claims_for(root, claim_ids)
    return {
        "observation": observation,
        "findings": findings,
        "evidence": [cite(card) for card in cards],
        "uncertainty": "A hypothesis is not a diagnosis; missing or unverified measurements remain blockers.",
        "next_action": "Collect the discriminating measurement before proposing a calibration change.",
        "write_authorization": "never",
    }
