import unittest

from telemetry_stats import compare, repeatability, summarize


def frames(values, start=0):
    return [
        {"sequence": start + index, "decoded": {"rpm": 3000 + index * 100, "load": 50, "lambda": value, "coolant_c": 85, "battery_v": 13.8}}
        for index, value in enumerate(values)
    ]


class TelemetryStatsTests(unittest.TestCase):
    def test_summary_and_completeness(self):
        result = summarize(frames([0.95, 0.93, 0.91]))
        self.assertEqual(result["frame_count"], 3)
        self.assertTrue(result["telemetry"]["complete"])
        self.assertEqual(result["battery_v"]["mean"], 13.8)

    def test_repeatability(self):
        result = repeatability(frames([0.91, 0.92]), frames([0.92, 0.91]))
        self.assertTrue(result["repeatable"])

    def test_compare_reports_improvement(self):
        candidate = frames([0.93, 0.92, 0.91])
        result = compare(frames([1.0, 1.0, 1.0]), candidate, 0.90, frames([0.92, 0.91, 0.90]))
        self.assertGreater(result["lambda_error_improvement"], 0)
        self.assertTrue(result["candidate_clean"])

    def test_compare_requires_repeat_run(self):
        result = compare(frames([1.0, 1.0]), frames([0.93, 0.92]), 0.90)
        self.assertIsNone(result["repeatability"]["repeatable"])
        self.assertFalse(result["candidate_clean"])


if __name__ == "__main__":
    unittest.main()
