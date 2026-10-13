const { chromium } = require('playwright');
// Dump the rendered box geometry of one design screen (points, relative to the phone frame).
// Usage: NODE_PATH=$(npm root -g) node design-geometry.js "http://localhost:8765/AhhPuck%20Mobile%20Build.dc.html" S06 [depth=2]
// Serve design-import/ahhpuck-mobile with `python3 -m http.server 8765` first. Uses system Chrome.
const [,, url, id, depthArg] = process.argv; const maxDepth = +(depthArg || 2);
(async () => {
  const b = await chromium.launch({ channel: 'chrome' });
  const p = await b.newPage({ viewport: { width: 1600, height: 1200 } });
  await p.goto(url, { waitUntil: 'networkidle', timeout: 120000 });
  await p.waitForFunction(() => document.querySelectorAll('[data-screen-label]').length > 40, null, { timeout: 120000 });
  await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(1500);
  const out = await p.evaluate((id) => {
    const f = document.querySelector('#' + id + ' > div:nth-child(2)');
    const fr = f.getBoundingClientRect();
    const rows = [];
    const walk = (el, depth) => {
      const r = el.getBoundingClientRect();
      if (depth <= maxDepth) rows.push(`${'  '.repeat(depth)}${el.tagName.toLowerCase()} y=${(r.top - fr.top - 1).toFixed(1)} h=${r.height.toFixed(1)} x=${(r.left - fr.left - 1).toFixed(1)} w=${r.width.toFixed(1)} "${(el.innerText||'').slice(0,30).replace(/\n/g,' ')}"`);
      if (depth < maxDepth) for (const c of el.children) walk(c, depth + 1);
    };
    walk(f, 0);
    return rows.join('\n');
  }, id);
  console.log(out); await b.close();
})();
