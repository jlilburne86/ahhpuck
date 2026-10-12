"""The loop must be able to reach a target, starting with idle and cruise."""
import unittest

from concept_optimizer import Limits, proposals
from freedom_grid import cell, cell_label
from telemetry_stats import compare
from tuning_iteration import assess

CLEAN = {"telemetry_complete": True, "sensor_plausibility": True, "repeatable": True, "map_coverage": 0.8}


def accepted(step, remaining):
    return assess({"baseline_score": 0.5, "candidate_score": 0.6,
                   "evidence": dict(CLEAN, remaining_error_fraction=remaining),
                   "candidate": {"change_fraction": step}})


class StepSizeTests(unittest.TestCase):
    def test_eight_percent_error_is_reachable(self):
        error, step, steps = 0.08, 0.02, 0
        while error > 0.001 and steps < 20:
            error -= step
            steps += 1
            step = accepted(step, error)["next_change_fraction_limit"]
        self.assertLessEqual(error, 0.001)
        self.assertLessEqual(steps, 5)

    def test_does_not_overshoot_small_remaining_error(self):
        self.assertAlmostEqual(accepted(0.02, 0.005)["next_change_fraction_limit"], 0.005)

    def test_unknown_remaining_error_halves(self):
        result = assess({"baseline_score": 0.5, "candidate_score": 0.6, "evidence": CLEAN,
                         "candidate": {"change_fraction": 0.02}})
        self.assertAlmostEqual(result["next_change_fraction_limit"], 0.01)

    def test_abort_stops_stepping(self):
        result = assess({"protection_faults": ["knock_detected"], "evidence": CLEAN,
                         "candidate": {"change_fraction": 0.02}})
        self.assertEqual(result["next_change_fraction_limit"], 0.0)


def warm(rpm, load, lam, **extra):
    return dict({"rpm": rpm, "load_kpa": load, "lambda": lam, "coolant_c": 85, "iat_c": 30,
                 "voltage_v": 13.8, "knock_level": 0.0}, **extra)


class ProposalTests(unittest.TestCase):
    def test_cruise_is_tuned_without_oil_channel(self):
        fuel, _ = proposals([warm(3000, 50, 1.04)] * 3, Limits())
        self.assertEqual(len(fuel), 1)
        self.assertEqual(fuel[0]["region"], "cruise")
        self.assertEqual(fuel[0]["target_source"], "default_by_region")
        self.assertAlmostEqual(fuel[0]["fuel_change_fraction"], 0.02)  # 4% lean, capped
        self.assertAlmostEqual(fuel[0]["remaining_error_fraction"], 0.04)

    def test_high_load_needs_explicit_permission(self):
        samples = [warm(6000, 95, 0.95, oil_pressure_kpa=400)] * 3
        fuel, skipped = proposals(samples, Limits())
        self.assertEqual(fuel, [])
        self.assertEqual(skipped["high_load_not_allowed"], 3)
        fuel, _ = proposals(samples, Limits(), allow_high_load=True)
        self.assertEqual(fuel[0]["region"], "high_load")

    def test_cold_engine_is_skipped_with_reason(self):
        fuel, skipped = proposals([warm(3000, 50, 1.04, coolant_c=50)] * 3, Limits())
        self.assertEqual(fuel, [])
        self.assertEqual(skipped["engine_not_warm"], 3)

    def test_idle_before_cruise(self):
        samples = [warm(3000, 50, 1.03)] * 3 + [warm(900, 35, 1.03)] * 3
        fuel, _ = proposals(samples, Limits())
        self.assertEqual([item["region"] for item in fuel], ["idle", "cruise"])


class GridTests(unittest.TestCase):
    def test_freedom_cells(self):
        self.assertEqual(cell(3249, 66.6), (3000, 450))
        self.assertEqual(cell_label(3500, 101.3), "3500rpm:750mmHg")


def frames(points, start=0):
    return [{"sequence": start + i, "decoded": {"rpm": rpm, "load": load, "lambda": lam}}
            for i, (rpm, load, lam) in enumerate(points)]


class ComparisonTests(unittest.TestCase):
    def test_only_shared_cells_are_compared(self):
        baseline = frames([(3000, 50, 1.10), (3000, 50, 1.10), (6000, 95, 0.90), (6000, 95, 0.90)])
        candidate = frames([(6000, 95, 0.90), (6000, 95, 0.90)])
        result = compare(baseline, candidate, 0.90)
        self.assertEqual(result["shared_cell_comparison"]["shared_cells"], 1)
        self.assertEqual(result["lambda_error_improvement"], None)  # both already on target there

    def test_gain_inside_noise_is_not_clean(self):
        baseline = frames([(3000, 50, 0.95)] * 3)
        candidate = frames([(3000, 50, 0.94)] * 3)
        repeat = frames([(3000, 50, 0.92)] * 3)
        result = compare(baseline, candidate, 0.90, repeat)
        self.assertTrue(result["repeatability"]["repeatable"])
        self.assertFalse(result["improvement_above_noise"])
        self.assertFalse(result["candidate_clean"])


if __name__ == "__main__":
    unittest.main()
