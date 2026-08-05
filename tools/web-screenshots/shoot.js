// Captures real screenshots of the app running as a Flutter Web build, via a
// real Chromium browser. See README.md for the required build steps first.
const path = require('node:path');
const { chromium } = require('playwright');

const BASE = process.env.SCREENSHOT_BASE_URL || 'http://localhost:8765';
const OUT = path.join(__dirname, 'screenshots');
const VIEWPORT = { width: 390, height: 844 };
const LOCAL_FONT =
  process.env.SCREENSHOT_FALLBACK_FONT || '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf';

async function withFontFallback(context) {
  // fonts.gstatic.com may be unreachable (sandboxed network); CanvasKit needs
  // real font bytes to rasterize text, so serve a local substitute instead.
  await context.route('https://fonts.gstatic.com/**', (route) => {
    route.fulfill({ path: LOCAL_FONT, contentType: 'font/ttf' });
  });
}

async function newPage(browser) {
  const context = await browser.newContext({ viewport: VIEWPORT });
  await withFontFallback(context);
  return { context, page: await context.newPage() };
}

async function shootUrl(browser, url, outFile) {
  const { context, page } = await newPage(browser);
  await page.goto(url);
  await page.waitForTimeout(6000);
  await page.screenshot({ path: path.join(OUT, outFile) });
  await context.close();
}

async function shootOnboardingFlow(browser) {
  const { context, page } = await newPage(browser);
  await page.goto(`${BASE}/#/`);
  await page.waitForTimeout(6000);

  // CanvasKit draws everything to <canvas>; DOM/ARIA nodes for text only
  // appear once the hidden semantics placeholder is activated (the same
  // thing a screen reader would trigger).
  await page.locator('flt-semantics-placeholder').dispatchEvent('click');
  await page.waitForTimeout(1500);

  await page.getByText('Empezar', { exact: true }).click({ timeout: 5000 });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(OUT, '02-idioma.png') });

  // English is preselected as the default target language.
  await page.getByText('Continuar', { exact: true }).click({ timeout: 5000 });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(OUT, '02b-nivel.png') });

  await page.getByText('Continuar', { exact: true }).click({ timeout: 5000 });
  await page.waitForTimeout(2000);
  await page.getByText('Continuar como invitado', { exact: true }).click({ timeout: 5000 });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: path.join(OUT, '05-lecciones.png') });

  await context.close();
}

async function main() {
  const executablePath = process.env.SCREENSHOT_CHROMIUM_PATH;
  const browser = await chromium.launch({
    executablePath,
    args: ['--no-sandbox'],
  });

  await shootUrl(browser, `${BASE}/#/`, '01-welcome.png');
  await shootUrl(browser, `${BASE}/#/lesson/en/u1/u1_l1`, '03-ejercicio.png');
  await shootUrl(browser, `${BASE}/#/lesson/en/u2/u2_l1`, '04-ejercicio2.png');
  await shootUrl(browser, `${BASE}/#/paywall`, '06-premium.png');
  await shootOnboardingFlow(browser);

  await browser.close();
  console.log(`Screenshots written to ${OUT}`);
}

main().catch((err) => {
  console.error('FATAL', err);
  process.exit(1);
});
