const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args: ['--no-sandbox','--use-gl=swiftshader','--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 1000, height: 660 }, deviceScaleFactor: 2 });
  const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => m.type()==='error' && errs.push(m.text()));
  await p.goto('http://localhost:8765/index.html', { waitUntil: 'load' });
  await p.waitForFunction(() => window.__ready === true);
  await p.waitForTimeout(1200);
  await p.screenshot({ path: process.argv[2] || 'render-orbit.png' });
  console.log('errors:', errs.length ? errs : 'none');
  await b.close();
})();
