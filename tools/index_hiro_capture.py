#!/usr/bin/env python3
"""Index an existing Hiro0719jp capture without downloading anything."""
from __future__ import annotations

import hashlib
import json
from html.parser import HTMLParser
from pathlib import Path

from evidence_paths import evidence_root


class P(HTMLParser):
    def __init__(self) -> None:
        super().__init__(); self.title = []; self.in_title = False
    def handle_starttag(self, tag, attrs):
        if tag == "title": self.in_title = True
    def handle_endtag(self, tag):
        if tag == "title": self.in_title = False
    def handle_data(self, data):
        if self.in_title: self.title.append(data)


def main() -> None:
    root = evidence_root() / "downloads/hiro0719jp_freedom"
    articles = []
    for page in sorted(root.glob("entry-*.html")):
        raw = page.read_bytes(); parser = P(); parser.feed(raw.decode(errors="replace"))
        images = sorted((root / "images").glob(page.stem + "-*"))
        articles.append({
            "slug": page.stem,
            "url": f"https://ameblo.jp/hiro0719jp/{page.stem}.html",
            "path": str(page),
            "title": "".join(parser.title).strip(),
            "bytes": len(raw),
            "sha256": hashlib.sha256(raw).hexdigest(),
            "captured_images": [
                {"path": str(image), "bytes": image.stat().st_size, "sha256": hashlib.sha256(image.read_bytes()).hexdigest()}
                for image in images
            ],
        })
    out = {"source": "https://ameblo.jp/hiro0719jp/", "articles": articles, "article_count": len(articles), "image_count": sum(len(x["captured_images"]) for x in articles)}
    (root / "manifest.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"articles": out["article_count"], "images": out["image_count"], "manifest": str(root / "manifest.json")}, indent=2))


if __name__ == "__main__": main()
