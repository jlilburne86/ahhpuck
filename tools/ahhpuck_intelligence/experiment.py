from __future__ import annotations

from typing import Any

STATES = ("draft", "engineering_review", "prerequisites_verified", "approved", "performed_externally", "post_test_review", "retained", "reverted", "inconclusive", "cancelled")
TRANSITIONS = {
    "draft": {"engineering_review", "cancelled"},
    "engineering_review": {"prerequisites_verified", "cancelled"},
    "prerequisites_verified": {"approved", "cancelled"},
    "approved": {"performed_externally", "cancelled"},
    "performed_externally": {"post_test_review"},
    "post_test_review": {"retained", "reverted", "inconclusive"},
}


def transition(experiment: dict[str, Any], target: str, actor: str, note: str = "") -> dict[str, Any]:
    current = experiment.get("state", "draft")
    if target not in TRANSITIONS.get(current, set()):
        raise ValueError(f"invalid experiment transition: {current} -> {target}")
    if target == "approved" and not actor:
        raise ValueError("human approver is required")
    history = list(experiment.get("history", []))
    history.append({"from": current, "to": target, "actor": actor, "note": note})
    return {**experiment, "state": target, "history": history, "write_authorization": "never"}


def new(experiment_id: str, proposal: dict[str, Any]) -> dict[str, Any]:
    return {"experiment_id": experiment_id, "state": "draft", "proposal": proposal, "history": [], "write_authorization": "never"}
