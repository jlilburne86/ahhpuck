"""Fail-closed behaviour: missing evidence or channels must never count as a pass."""
import json
import unittest
from pathlib import Path

from safety_gate import evaluate
from telemetry_stats import telemetry_completeness
from tuning_iteration import assess

POLICY = json.loads((Path(__file__).resolve().parent.parent / "config" / "tuning-safety-policy.json").read_text())
ALL_EVIDENCE = {key: True for key in POLICY["required_evidence"]}
GOOD_SAMPLE = {"rpm": 3000, "load_kpa": 50, "coolant_c": 85, "iat_c": 30, "voltage_v": 13.8}


class IterationFailClosedTests(unittest.TestCase):
    def test_missing_evidence_is_not_accepted(self):
        result = assess({"baseline_score": 0.5, "candidate_score": 0.51,
                         "evidence": {"repeatable": True, "map_coverage": 0.9},
                         "candidate": {"change_fraction": 0.02}})
        self.assertEqual(result["decision"], "rollback_and_abort")
        codes = {issue["code"] for issue in result["issues"]}
        self.assertIn("telemetry_incomplete", codes)
        self.assertIn("sensor_plausibility", codes)

    def test_sparse_coverage_blocks_acceptance(self):
        result = assess({"baseline_score": 0.5, "candidate_score": 0.6,
                         "evidence": {"telemetry_complete": True, "sensor_plausibility": True,
                                      "repeatable": True, "map_coverage": 0.1},
                         "candidate": {"change_fraction": 0.01}})
        self.assertEqual(result["decision"], "rollback_and_review")

    def test_clean_evidence_still_accepts(self):
        result = assess({"baseline_score": 0.5, "candidate_score": 0.6,
                         "evidence": {"telemetry_complete": True, "sensor_plausibility": True,
                                      "repeatable": True, "map_coverage": 0.8},
                         "candidate": {"change_fraction": 0.01}})
        self.assertEqual(result["decision"], "accept_candidate_and_prepare_smaller_next_step")


class SafetyGateFailClosedTests(unittest.TestCase):
    def gate(self, samples, candidate=None, evidence=None):
        return evaluate({"evidence": evidence or ALL_EVIDENCE,
                         "candidate": candidate or {"fuel_cell_change_fraction": 0.01, "change_families": ["fuel"]},
                         "samples": samples}, POLICY)

    def test_complete_clean_sample_reaches_review(self):
        self.assertEqual(self.gate([GOOD_SAMPLE])["status"], "review_required")

    def test_no_samples_blocks(self):
        self.assertIn("no telemetry samples supplied", self.gate([])["blocked"])

    def test_missing_coolant_blocks(self):
        sample = {key: value for key, value in GOOD_SAMPLE.items() if key != "coolant_c"}
        self.assertIn("missing channel: coolant_c", self.gate([sample])["blocked"])

    def test_missing_oil_and_lambda_under_load_block(self):
        blocked = self.gate([dict(GOOD_SAMPLE, load_kpa=95)])["blocked"]
        self.assertIn("missing channel under load: oil_pressure_kpa", blocked)
        self.assertIn("missing channel under load: lambda", blocked)

    def test_lean_under_load_blocks(self):
        sample = dict(GOOD_SAMPLE, load_kpa=95, oil_pressure_kpa=350, **{"lambda": 1.1})
        self.assertIn("lean under load", self.gate([sample])["blocked"])

    def test_ignition_change_needs_knock_sensing(self):
        candidate = {"ignition_cell_change_deg": 0.5, "change_families": ["ignition"]}
        blocked = self.gate([GOOD_SAMPLE], candidate=candidate)["blocked"]
        self.assertIn("ignition change requires verified knock sensing", blocked)
        self.assertIn("missing channel: knock_level (required for ignition changes)", blocked)


class CompletenessFailClosedTests(unittest.TestCase):
    def test_empty_and_single_frame_logs_are_incomplete(self):
        self.assertFalse(telemetry_completeness([])["complete"])
        self.assertFalse(telemetry_completeness([{"sequence": 1}])["complete"])

    def test_frames_without_sequence_numbers_are_incomplete(self):
        self.assertFalse(telemetry_completeness([{"sequence": 1}, {}])["complete"])

    def test_gap_is_detected(self):
        self.assertFalse(telemetry_completeness([{"sequence": 1}, {"sequence": 5}])["complete"])


if __name__ == "__main__":
    unittest.main()
