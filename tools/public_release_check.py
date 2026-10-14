#!/usr/bin/env python3
"""Fail-closed checks for accidental secrets in a public source release.

This is a lightweight local guard, not a replacement for GitHub secret
scanning or a professional security review. It scans tracked text files only
and ignores research binaries/archives, which are governed by the separate
third-party notice.
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys


PATTERNS = [
    ("private key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")),
    ("AWS access key", re.compile(r"\bAKIA[0-9A-Z]{16}\b")),
    ("OpenAI key", re.compile(r"\bsk-[A-Za-z0-9]{20,}\b")),
    ("generic secret assignment", re.compile(r"(?i)\b(?:secret|password|token)\s*[:=]\s*['\"][^'\"]{8,}")),
]
SKIP_PARTS = {".git", ".build", "build", "source_files", "extracted", "downloads"}
TEXT_SUFFIXES = {".swift", ".py", ".js", ".jsx", ".ts", ".tsx", ".json", ".plist", ".xml", ".html", ".css", ".md", ".yml", ".yaml", ".toml", ".sh"}


def tracked_files(root: pathlib.Path) -> list[pathlib.Path]:
    raw = subprocess.check_output(["git", "ls-files", "-z"], cwd=root)
    return [root / pathlib.Path(item) for item in raw.decode().split("\0") if item]


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    findings: list[str] = []
    for path in tracked_files(root):
        if any(part in SKIP_PARTS for part in path.relative_to(root).parts):
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES or path.stat().st_size > 2_000_000:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for label, pattern in PATTERNS:
            if pattern.search(text):
                findings.append(f"{label}: {path.relative_to(root)}")
    if findings:
        print("Potential release secrets found:", file=sys.stderr)
        print("\n".join(f"- {finding}" for finding in findings), file=sys.stderr)
        return 1
    print("public release check: no known secret patterns in tracked source text")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
