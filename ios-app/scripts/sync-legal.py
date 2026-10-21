#!/usr/bin/env python3
"""Regenerate the app's bundled copies of wheelhave.com/terms and /privacy.

Usage: python3 sync-legal.py [base-url]   (default https://wheelhave.com)
Writes App/Resources/Legal/{terms,privacy}.txt. Run it whenever the website's
legal pages change, and commit the result, so the app says what the site says.
Format: '# ' title, '## ' and '### ' headings, '• ' list items, blank-line paragraphs.
"""
import html, re, sys, urllib.request
from html.parser import HTMLParser
from pathlib import Path

BASE = (sys.argv[1] if len(sys.argv) > 1 else 'https://wheelhave.com').rstrip('/')
OUT = Path(__file__).resolve().parent.parent / 'App' / 'Resources' / 'Legal'

class Doc(HTMLParser):
    BLOCK = {'h1': '# ', 'h2': '## ', 'h3': '### ', 'li': '• ', 'p': '', 'span': None}
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.depth_main = 0; self.skip = 0; self.out = []; self.buf = None; self.kind = None; self.stack = []
    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == 'main' and 'wh-doc-main' in (a.get('class') or ''): self.depth_main = 1; return
        if not self.depth_main: return
        if tag in ('div',) and 'wh-doc-actions' in (a.get('class') or ''): self.skip += 1; self.stack.append('skipdiv'); return
        if tag == 'div': self.stack.append('div')
        if self.skip: return
        if tag in ('h1', 'h2', 'h3', 'li', 'p') and self.buf is None:
            self.buf = []; self.kind = tag
        if tag == 'span' and 'wh-doc-kicker' in (a.get('class') or '') and self.buf is None:
            self.buf = []; self.kind = 'kicker'
        if tag == 'br' and self.buf is not None: self.buf.append(' ')
    def handle_endtag(self, tag):
        if not self.depth_main: return
        if tag == 'main': self.flush(); self.depth_main = 0; return
        if tag == 'div' and self.stack:
            if self.stack.pop() == 'skipdiv': self.skip -= 1
            return
        if self.buf is not None and (tag == self.kind or (self.kind == 'kicker' and tag == 'span')): self.flush()
    def handle_data(self, d):
        if self.depth_main and not self.skip and self.buf is not None: self.buf.append(d)
    def flush(self):
        if self.buf is None: return
        t = re.sub(r'\s+', ' ', ''.join(self.buf)).strip()
        if t:
            prefix = {'h1': '# ', 'h2': '## ', 'h3': '### ', 'li': '• ', 'p': '', 'kicker': ''}[self.kind]
            self.out.append(prefix + t)
        self.buf = None; self.kind = None

for name in ('terms', 'privacy'):
    req = urllib.request.Request(f'{BASE}/{name}', headers={'User-Agent': 'Mozilla/5.0 (AhhPuck legal sync)'})
    page = urllib.request.urlopen(req).read().decode('utf-8')
    d = Doc(); d.feed(page)
    body = '\n\n'.join(d.out)
    assert body.count('\n') > 20 and '# ' in body, f'{name}: nothing extracted'
    header = f'Copy of https://wheelhave.com/{name}, bundled so it can be read offline. The website version is the current one.\n\n'
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / f'{name}.txt').write_text(header + body + '\n', encoding='utf-8')
    print(name, len(body), 'chars,', len(d.out), 'blocks')
