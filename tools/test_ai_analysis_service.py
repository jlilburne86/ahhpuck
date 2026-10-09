import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from ai_analysis_service import local_analysis, record


class AIAnalysisServiceTests(unittest.TestCase):
    def test_critical_report_is_not_reusable(self):
        result = local_analysis({
            "decision": "rollback_and_abort",
            "issues": [{"severity": "critical", "code": "knock_detected", "likely_issue": "possible detonation"}],
        })
        self.assertFalse(result["reusable_learning"])
        self.assertFalse(result["guardrails"]["ecu_write_authorized"])
        self.assertEqual(result["findings"][0]["suggested_check"][:6], "Verify")

    def test_record_is_append_only_and_queryable(self):
        with tempfile.TemporaryDirectory() as directory:
            db_path = Path(directory) / "ledger.sqlite3"
            report = {"iteration": 1, "decision": "accept_candidate_and_prepare_smaller_next_step", "reason": "clean", "issues": []}
            first = record(db_path, report, "test profile", "session-1")
            second = record(db_path, report, "test profile", "session-1")
            self.assertEqual(first["session_id"], second["session_id"])
            with sqlite3.connect(db_path) as db:
                count = db.execute("SELECT COUNT(*) FROM iterations").fetchone()[0]
            self.assertEqual(count, 2)


if __name__ == "__main__":
    unittest.main()
