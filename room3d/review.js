const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium', args: ['--no-sandbox','--use-gl=swiftshader','--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 1000, height: 660 } });
  const log = [];
  p.on('console', m => log.push(`[${m.type()}] ${m.text()}`));
  p.on('pageerror', e => log.push(`[pageerror] ${e.message}`));
  p.on('requestfailed', r => log.push(`[requestfailed] ${r.url()} ${r.failure()?.errorText}`));
  p.on('response', r => { if (r.status() >= 400) log.push(`[http ${r.status()}] ${r.url()}`); });
  await p.goto(process.argv[2], { waitUntil: 'load' });
  await p.waitForTimeout(4000);
  console.log(log.join('\n') || 'no messages');
  await p.screenshot({ path: process.argv[3] });
  await b.close();
})();
