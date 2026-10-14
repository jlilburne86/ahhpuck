#!/usr/bin/env python3
"""Capture the Paddock-N Freedom Computer subsection and linked image assets."""
from __future__ import annotations

import hashlib
import json
import re
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path

from evidence_paths import evidence_root

ROOT = "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%88%88%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%97"
# Correct URL encoded root; kept separately so the path is readable above.
ROOT = "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%88%88%E3%83%83%E3%88%88%E3%83%88"

PAGES = [
    ("setup", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%83%97"),
    ("what-is-freedom-computer", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%83%97/freedom-computer%E3%81%A8%E3%81%AF"),
    ("fcss-usage", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%88%88%E3%83%83%E3%88%88%E3%83%88/fcss%E3%81%AE%E6%B4%BB%E7%94%A8"),
    ("fcss-limitations", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%88%88%E3%83%83%E3%88%88%E3%83%88/fcss%E3%81%AE%E9%99%90%E7%95%8C"),
    ("future-freedom-computer", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%83%97/freedom-computer%E3%81%AE%E6%B4%BB%E7%94%A8%E3%81%AB%E5%90%91%E3%81%91%E3%81%A6"),
    ("fcst-development", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%83%88%E3%82%A2%E3%83%83%E3%97/fcst%E3%81%AE%E9%96%8B%E7%99%BA"),
    ("fcst-environment", "https://sites.google.com/view/paddock-n/home/car-life/ecufreedom-computer%E3%82%BB%E3%83%83%E3%88%88%E3%83%83%E3%88%88%E3%83%88/fcst%E6%B4%BB%E7%94%A8%E7%92%B0%E5%A2%83"),
]


class Links(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.images: list[str] = []
        self.title: list[str] = []
        self.in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "img" and values.get("src"):
            self.images.append(values["src"])
        if tag == "title":
            self.in_title = True

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title.append(data)


def fetch(url: str) -> bytes:
    request = urllib.request.Request(url, headers={"User-Agent": "FreedomResearchCapture/0.1"})
    with urllib.request.urlopen(request, timeout=45) as response:
        return response.read()


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def safe_name(url: str) -> str:
    path = urllib.parse.urlparse(url).path.rsplit("/", 1)[-1] or "asset"
    return re.sub(r"[^A-Za-z0-9._-]+", "_", urllib.parse.unquote(path))[:180]


def main() -> None:
    root = evidence_root() / "downloads/paddock_freedom"
    asset_root = root / "assets"
    asset_root.mkdir(parents=True, exist_ok=True)
    manifest: dict = {"captured_at": datetime.now(timezone.utc).isoformat(), "pages": []}
    for slug, url in PAGES:
        record = {"slug": slug, "url": url, "status": "error"}
        try:
            content = fetch(url)
            page_path = root / f"{slug}.html"
            page_path.write_bytes(content)
            parser = Links()
            parser.feed(content.decode("utf-8", errors="replace"))
            record.update({"status": "ok", "path": str(page_path), "sha256": digest(content), "bytes": len(content), "title": "".join(parser.title).strip(), "image_count": len(parser.images), "images": []})
            for index, image in enumerate(dict.fromkeys(parser.images)):
                image_url = urllib.parse.urljoin(url, image)
                try:
                    image_data = fetch(image_url)
                    image_path = asset_root / f"{slug}-{index:03d}-{safe_name(image_url)}"
                    image_path.write_bytes(image_data)
                    record["images"].append({"url": image_url, "path": str(image_path), "sha256": digest(image_data), "bytes": len(image_data)})
                except Exception as error:
                    record["images"].append({"url": image_url, "status": "error", "error": str(error)})
        except Exception as error:
            record["error"] = str(error)
        manifest["pages"].append(record)
    output = root / "manifest.json"
    output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"pages": len(manifest["pages"]), "output": str(output), "ok": sum(p["status"] == "ok" for p in manifest["pages"])}, indent=2))


if __name__ == "__main__":
    main()
