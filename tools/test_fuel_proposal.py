import unittest

from ahhpuck_intelligence.fuel_proposal import propose


def frames(values):
    return [
        {"sequence": index, "decoded": {"rpm": 3200, "load": 55, "lambda": value, "knock_level": 0.0, "coolant_c": 84}}
        for index, value in enumerate(values)
    ]


GOOD_EVIDENCE = {"telemetry_complete": True, "sensor_plausibility": True, "repeatable": True, "map_coverage": 0.82}


class FuelProposalTests(unittest.TestCase):
    def test_clean_lambda_error_creates_bounded_fuel_review(self):
        result = propose(frames([1.00, 0.99, 1.01]), evidence=GOOD_EVIDENCE)
        self.assertEqual(result["status"], "review_required")
        self.assertEqual(result["family"], "fuel")
        self.assertGreater(result["proposals"][0]["fuel_change_fraction"], 0)
        self.assertLessEqual(result["proposals"][0]["fuel_change_fraction"], 0.02)
        self.assertEqual(result["write_authorization"], "never")
        self.assertEqual(result["proposals"][0]["ignition_change"], "locked")

    def test_incomplete_evidence_blocks_and_emits_no_proposal(self):
        result = propose(frames([1.0, 1.0, 1.0]), evidence={})
        self.assertEqual(result["status"], "blocked")
        self.assertEqual(result["proposals"], [])
        self.assertIn("telemetry_complete", result["blockers"])

    def test_knock_blocks_even_with_complete_metadata(self):
        samples = frames([1.0, 1.0, 1.0])
        samples[0]["decoded"]["knock_level"] = 0.2
        result = propose(samples, evidence=GOOD_EVIDENCE)
        self.assertEqual(result["status"], "blocked")
        self.assertIn("knock_detected", result["blockers"])


if __name__ == "__main__":
    unittest.main()
