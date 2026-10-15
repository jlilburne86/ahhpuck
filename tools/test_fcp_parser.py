#!/usr/bin/env python3
import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fcp_parser import parse_fcp
from evidence_paths import evidence_root


SAMPLE = evidence_root() / "extracted/base_maps/BASE MAPS - FC OE DATA/AE86-A.FCP"


class FcpParserTest(unittest.TestCase):
    def test_common_base_map_structure(self) -> None:
        result = parse_fcp(SAMPLE)
        self.assertEqual(result["metadata"]["format"], "Freedom FCP text")
        self.assertEqual(result["scalars"]["KDK"], 50)
        self.assertEqual(result["tables"]["IGT"]["row_count"], 36)
        self.assertEqual(result["tables"]["IGT"]["column_counts"], [16])
        self.assertEqual(result["tables"]["IJM"]["row_count"], 72)
        self.assertEqual(result["tables"]["IJM"]["column_counts"], [8])

    def test_no_table_is_assigned_a_guess(self) -> None:
        result = parse_fcp(SAMPLE)
        self.assertTrue(all(item["semantic"] == "undocumented" for item in result["tables"].values()))


if __name__ == "__main__":
    unittest.main()
