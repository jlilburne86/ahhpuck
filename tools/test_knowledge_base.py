"""The knowledge base must stay traceable: every rule card cites a real source."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "knowledge"
MANIFEST = json.loads((ROOT / "source-manifest.json").read_text(encoding="utf-8"))
CARDS = json.loads((ROOT / "rule-cards.json").read_text(encoding="utf-8"))
EVIDENCE = {"documented", "observed", "inferred", "unsafe/unverified"}
USES = {"summarise_and_cite", "cite_only", "ask_permission"}


class KnowledgeBaseTests(unittest.TestCase):
    def test_source_ids_are_unique(self):
        ids = [source["id"] for source in MANIFEST["sources"]]
        self.assertEqual(len(ids), len(set(ids)))

    def test_every_source_has_layer_use_and_url(self):
        for source in MANIFEST["sources"]:
            with self.subTest(source=source["id"]):
                self.assertIn(source["layer"], range(1, 8))
                self.assertIn(source["use"], USES)
                self.assertTrue(source["url"].startswith("https://"))

    def test_every_card_cites_a_known_source(self):
        known = {source["id"] for source in MANIFEST["sources"]}
        for card in CARDS["cards"]:
            with self.subTest(card=card["id"]):
                self.assertIn(card["source"]["id"], known)
                self.assertTrue(card["source"].get("location"))

    def test_every_card_has_an_evidence_label_and_action(self):
        for card in CARDS["cards"]:
            with self.subTest(card=card["id"]):
                self.assertIn(card["evidence"], EVIDENCE)
                self.assertTrue(card["action"])


if __name__ == "__main__":
    unittest.main()
