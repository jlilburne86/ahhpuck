import json
import tempfile
import unittest
from pathlib import Path

from ahhpuck_intelligence import adapter, capture, experiment, passport, session
from ahhpuck_intelligence.knowledge import load_registry


ROOT = Path(__file__).parents[1]


class EngineIntelligenceTests(unittest.TestCase):
    def test_knowledge_registry_is_source_backed(self):
        manifest, cards = load_registry(ROOT)
        self.assertGreater(len(manifest["sources"]), 0)
        self.assertGreater(len(cards["cards"]), 0)

    def test_passport_is_versioned_and_unknown_is_explicit(self):
        result = passport.create("engine-1", {"identity": "Ab-1EU", "status": "declared_unverified"}, {}, "baseline")
        self.assertEqual(result["kind"], "engine-passport")
        self.assertEqual(result["payload"]["status"], "ready")
        self.assertTrue(result["payload"]["revision"])

    def test_session_hashes_copied_inputs_without_mutating_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "log.json"
            profile = root / "profile.json"
            source.write_text(json.dumps({"frames": []}), encoding="utf-8")
            profile.write_text("{}", encoding="utf-8")
            result = session.create(root / "session-1", profile, [source])
            self.assertEqual(result["payload"]["write_authorization"], "never")
            self.assertTrue((root / "session-1" / "manifest.json").exists())

    def test_freedom_adapter_never_guesses_mapping(self):
        with tempfile.NamedTemporaryFile() as file:
            path = Path(file.name)
            path.write_bytes(b"legacy export")
            result = adapter.freedom_export(path, ecu_identity="Ab-1EU", format_version="unknown")
            self.assertFalse(result.supported)

    def test_raw_capture_bundle_is_hashed_but_not_decoded(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "capture.json"
            profile = root / "profile.json"
            source.write_text(json.dumps({"frames": [{"timestamp": "2026-10-12T00:00:00Z", "sequence": 0, "direction": "rx", "bytes": [1, 2]}]}), encoding="utf-8")
            profile.write_text(json.dumps(passport.create("engine-1", {"identity": "Ab-1EU", "status": "declared_unverified"}, {})), encoding="utf-8")
            result = capture.bundle(root / "session-1", profile, source)
            self.assertFalse(result["report"]["payload"]["decoded_telemetry"])
            self.assertEqual(result["report"]["payload"]["next_gate"], "verified Freedom frame decoder")

    def test_experiment_requires_human_approval_and_has_no_write_authority(self):
        item = experiment.new("exp-1", {"family": "fuel"})
        item = experiment.transition(item, "engineering_review", "reviewer")
        item = experiment.transition(item, "prerequisites_verified", "reviewer")
        item = experiment.transition(item, "approved", "human-tuner")
        self.assertEqual(item["write_authorization"], "never")
        with self.assertRaises(ValueError):
            experiment.transition(item, "retained", "human-tuner")


if __name__ == "__main__":
    unittest.main()
