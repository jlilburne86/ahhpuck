const { chromium } = require('playwright');
// Render every screen of a .dc.html design to PNG at 3x (phone frame incl. 1 px border).
// Usage: NODE_PATH=$(npm root -g) node render-design.js http://localhost:8765 "AhhPuck Mobile Build.dc.html" <outDir> ""
const [,, base, file, outDir, suffix] = process.argv;
(async () => {
  const b = await chromium.launch({ channel: 'chrome' });
  const p = await b.newPage({ viewport: { width: 1600, height: 1200 }, deviceScaleFactor: 3 });
  const errs = []; p.on('pageerror', e => errs.push(String(e)));
  await p.goto(base + '/' + encodeURIComponent(file), { waitUntil: 'networkidle', timeout: 120000 });
  await p.waitForFunction(() => document.querySelectorAll('[data-screen-label]').length > 40, null, { timeout: 120000 });
  await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(3000);
  const ids = await p.$$eval('[data-screen-label]', els => els.map(e => e.id + '|' + e.getAttribute('data-screen-label')));
  for (const row of ids) {
    const [id] = row.split('|'); if (!id) continue;
    const frame = await p.$(`#${id} > div:nth-child(2)`);
    const el = frame || await p.$('#' + id);
    await el.screenshot({ path: `${outDir}/${id}${suffix}.png` });
  }
  console.log(ids.join('\n')); if (errs.length) console.log('ERRORS', errs.slice(0,5));
  await b.close();
})();
