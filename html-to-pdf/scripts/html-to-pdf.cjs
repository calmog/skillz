#!/usr/bin/env node
/*
 * html-to-pdf — render any HTML file to PDF via headless Chrome (puppeteer-core).
 *
 * Why this exists: Chrome's own `--headless --print-to-pdf` hangs on this Mac, and
 * the old aviz skill's CLI broke under Node 26 (a yargs/ESM load error). This script
 * drives the already-downloaded Chrome-for-Testing binary directly through
 * puppeteer-core, with hand-rolled arg parsing (no yargs), so it stays Node-version-proof.
 *
 * Usage:
 *   node html-to-pdf.cjs input.html output.pdf [options]
 *
 * Options:
 *   --margin=16mm        Uniform page margin (default 16mm). CSS @page margins still win if set.
 *   --format=A4          Paper size (A4, Letter, Legal, A3, ...). Default A4.
 *   --landscape          Landscape orientation.
 *   --scale=1            Render scale 0.1–2 (default 1).
 *   --rtl                Force document direction to RTL (for Hebrew/Arabic without explicit dir).
 *   --max-pages=N        Fail if the result exceeds N pages (Almog cares about hard page limits).
 *   --no-page-check      Skip the page-count read-back.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');

function parseArgs(argv) {
  const pos = [];
  const opt = {};
  for (const a of argv) {
    if (a.startsWith('--')) {
      const [k, v] = a.slice(2).split('=');
      opt[k] = v === undefined ? true : v;
    } else {
      pos.push(a);
    }
  }
  return { pos, opt };
}

// Locate a Chrome-for-Testing binary in the puppeteer cache (version-agnostic).
function findChrome() {
  const base = path.join(os.homedir(), '.cache', 'puppeteer', 'chrome');
  let found = null;
  try {
    for (const ver of fs.readdirSync(base)) {
      const dir = path.join(base, ver);
      // mac: <ver>/chrome-mac-x64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing
      const macDirs = fs.readdirSync(dir).filter(d => d.startsWith('chrome-mac'));
      for (const md of macDirs) {
        const p = path.join(dir, md, 'Google Chrome for Testing.app', 'Contents', 'MacOS', 'Google Chrome for Testing');
        if (fs.existsSync(p)) found = p;
        // linux fallback: <ver>/chrome-linux*/chrome
        const lp = path.join(dir, md, 'chrome');
        if (fs.existsSync(lp)) found = lp;
      }
    }
  } catch (_) { /* no cache dir */ }
  return found;
}

function countPdfPages(file) {
  const s = fs.readFileSync(file).toString('latin1');
  const m = s.match(/\/Type\s*\/Page[^s]/g);
  return m ? m.length : 0;
}

(async () => {
  const { pos, opt } = parseArgs(process.argv.slice(2));
  if (pos.length < 2) {
    console.error('Usage: node html-to-pdf.cjs input.html output.pdf [--margin=16mm] [--format=A4] [--landscape] [--rtl] [--max-pages=N] [--no-page-check]');
    process.exit(2);
  }
  const inPath = path.resolve(pos[0]);
  const outPath = path.resolve(pos[1]);
  if (!fs.existsSync(inPath)) { console.error('Input not found: ' + inPath); process.exit(2); }

  const exe = findChrome();
  if (!exe) {
    console.error('No Chrome-for-Testing binary found in ~/.cache/puppeteer/chrome.');
    console.error('Install one with:  npx @puppeteer/browsers install chrome@stable');
    process.exit(3);
  }

  let puppeteer;
  try {
    puppeteer = require('puppeteer-core');
  } catch (_) {
    console.error('puppeteer-core is not installed in this skill. Run:  cd ' + path.dirname(__dirname) + ' && npm install');
    process.exit(3);
  }

  const margin = (opt.margin || '16mm').toString();
  const browser = await puppeteer.launch({
    executablePath: exe,
    headless: true,
    args: ['--no-sandbox', '--disable-gpu'],
  });
  try {
    const page = await browser.newPage();
    await page.goto('file://' + inPath, { waitUntil: 'networkidle0' });
    if (opt.rtl) {
      await page.evaluate(() => { document.documentElement.setAttribute('dir', 'rtl'); });
    }
    await page.pdf({
      path: outPath,
      format: (opt.format || 'A4').toString(),
      landscape: !!opt.landscape,
      scale: opt.scale ? parseFloat(opt.scale) : 1,
      printBackground: true,
      preferCSSPageSize: true,
      margin: { top: margin, bottom: margin, left: margin, right: margin },
    });
  } finally {
    await browser.close();
  }

  let pages = null;
  if (!opt['no-page-check']) {
    pages = countPdfPages(outPath);
  }
  console.log('OK ' + outPath + (pages !== null ? ('  (' + pages + ' page' + (pages === 1 ? '' : 's') + ')') : ''));
  if (opt['max-pages'] && pages !== null && pages > parseInt(opt['max-pages'], 10)) {
    console.error('PAGE LIMIT EXCEEDED: ' + pages + ' > ' + opt['max-pages']);
    process.exit(4);
  }
})().catch(e => { console.error('ERROR: ' + (e && e.message ? e.message : e)); process.exit(1); });
