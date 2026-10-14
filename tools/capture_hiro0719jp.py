#!/usr/bin/env python3
"""Capture Hiro0719jp Freedom/FCST article pages and embedded images."""
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

BLOG = "https://ameblo.jp/hiro0719jp/"
OUT = evidence_root() / "downloads/hiro0719jp_freedom"


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: list[str] = []
        self.images: list[str] = []
        self.title: list[str] = []
        self.in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = dict(attrs)
        if tag == "a" and values.get("href"):
            self.links.append(urllib.parse.urljoin(BLOG, values["href"]))
        if tag == "img" and values.get("src"):
            self.images.append(urllib.parse.urljoin(BLOG, values["src"]))
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


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def slug(url: str) -> str:
    match = re.search(r"entry-(\d+)", url)
    return match.group(1) if match else "blog-index"


def article_links() -> list[str]:
    candidates = [evidence_root() / "downloads/hiro0719jp_blog_index.html", evidence_root() / "downloads/paddock_fcst_development.html"]
    found: set[str] = set()
    for path in candidates:
        if not path.exists():
            continue
        parser = PageParser()
        parser.feed(path.read_text(errors="replace"))
        for url in parser.links:
            parsed = urllib.parse.urlparse(url)
            if parsed.netloc == "www.google.com" and parsed.path == "/url":
                redirected = urllib.parse.parse_qs(parsed.query).get("q", [])
                if redirected:
                    url = redirected[0]
            clean = url.split("?", 1)[0].split("#", 1)[0]
            if urlparse(clean).netloc == "ameblo.jp" and "/hiro0719jp/entry-" in clean:
                found.add(clean)
    return sorted(found)


def urlparse(url: str):
    return urllib.parse.urlparse(url)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "images").mkdir(exist_ok=True)
    urls = article_links()
    manifest: dict = {"captured_at": datetime.now(timezone.utc).isoformat(), "source": BLOG, "article_count": len(urls), "articles": []}
    for url in urls:
        item = {"url": url, "status": "error", "slug": slug(url)}
        try:
            content = fetch(url)
            parser = PageParser()
            parser.feed(content.decode("utf-8", errors="replace"))
            page_path = OUT / f"entry-{item['slug']}.html"
            page_path.write_bytes(content)
            item.update({"status": "ok", "path": str(page_path), "title": "".join(parser.title).strip(), "bytes": len(content), "sha256": sha(content), "images": []})
            for index, image_url in enumerate(dict.fromkeys(parser.images)):
                try:
                    image_data = fetch(image_url)
                    extension = Path(urllib.parse.urlparse(image_url).path).suffix or ".bin"
                    image_path = OUT / "images" / f"entry-{item['slug']}-{index:03d}{extension}"
                    image_path.write_bytes(image_data)
                    item["images"].append({"url": image_url, "path": str(image_path), "bytes": len(image_data), "sha256": sha(image_data)})
                except Exception as error:
                    item["images"].append({"url": image_url, "status": "error", "error": str(error)})
        except Exception as error:
            item["error"] = str(error)
        manifest["articles"].append(item)
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"articles": len(urls), "ok": sum(x["status"] == "ok" for x in manifest["articles"]), "output": str(OUT / 'manifest.json')}, indent=2))


if __name__ == "__main__":
    main()
