import json
import tempfile
import unittest
from pathlib import Path

from ahhpuck_intelligence.artifacts import create_log, create_tune, load_record


ROOT = Path(__file__).parents[1]
FCP = ROOT / "extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP"


class ArtifactTests(unittest.TestCase):
    def test_tune_record_preserves_hash_and_unknown_table_semantics(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "ae86-tune"
            record = create_tune(FCP, output, {"vehicle": "AE86", "engine": "AE111 4A-GE 20V Blacktop"})
            payload = record["payload"]
            self.assertEqual(payload["artifact_type"], "tune")
            self.assertEqual(payload["metadata"]["vehicle"], "AE86")
            self.assertEqual(payload["parser"]["name"], "fcp_parser.py")
            self.assertTrue(payload["raw_sha256"])
            self.assertTrue(all(item["semantic"] == "undocumented" for item in payload["parser_summary"]["tables"].values()))
            self.assertEqual(load_record(output)["payload"]["write_authorization"], "never")

    def test_log_record_copies_source_without_mutating_it(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "run.json"
            source.write_text(json.dumps({"frames": []}), encoding="utf-8")
            before = source.read_bytes()
            create_log(source, root / "run-record", {"profile": "AE86 / AE111 Blacktop"})
            self.assertEqual(source.read_bytes(), before)
            self.assertTrue((root / "run-record" / "run.json").exists())


if __name__ == "__main__":
    unittest.main()
