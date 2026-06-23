---
name: html-to-pdf
description: Render any HTML file to a PDF via headless Chrome. Use when asked to 'convert HTML to PDF', 'generate a PDF from HTML', 'export to PDF', or to produce a PDF from a markdown/HTML document. Handles full CSS, images, web fonts and Hebrew/RTL (it is real Chromium).
version: "1.0.0"
author: calmog
tags:
  - pdf
  - html
  - conversion
  - rtl
  - hebrew
allowed-tools: Bash, Read, Write, Glob
---

# html-to-pdf

Render an HTML file to PDF by driving the already-downloaded **Chrome-for-Testing**
binary through `puppeteer-core`. Full headless Chromium, so anything Chrome can display
(CSS, JS, images, web fonts, RTL/Hebrew) comes out pixel-accurate in the PDF.

## Why this exists (read before reaching for anything else)

- Chrome's own `--headless --print-to-pdf` **hangs** on this Mac (ARM/Rosetta). Do not use it.
- `pandoc`, `wkhtmltopdf`, `weasyprint`, `md-to-pdf` are **not installed**.
- An earlier version of this skill's CLI broke under Node 26 (a `yargs` extensionless-file
  ESM load error). This skill uses hand-rolled arg parsing (no yargs) so it is Node-version-proof.

## Usage

```bash
node ~/.claude/skills/html-to-pdf/scripts/html-to-pdf.cjs input.html output.pdf [options]
```

One-time setup (only if `node_modules` is missing):

```bash
cd ~/.claude/skills/html-to-pdf && npm install
```

### Options

| Option | Default | Meaning |
|--------|---------|---------|
| `--margin=16mm` | 16mm | Uniform page margin. CSS `@page { margin }` still wins if set. |
| `--format=A4` | A4 | Paper size: A4, Letter, Legal, A3, … |
| `--landscape` | off | Landscape orientation. |
| `--scale=1` | 1 | Render scale 0.1–2. |
| `--rtl` | off | Force document direction RTL (Hebrew/Arabic with no explicit `dir`). |
| `--max-pages=N` | — | Exit non-zero if the result exceeds N pages (Almog cares about hard page limits). |
| `--no-page-check` | — | Skip the page-count read-back. |

It prints `OK <out>  (N pages)` on success. The page count is read back from the PDF so
you can verify a hard limit without poppler installed.

## Rendering markdown

There is no markdown step here. Convert the `.md` to a **self-contained HTML** first
(embed a print stylesheet: A4, ~14–16mm margins, ~10.5pt body, line-height ~1.32, no
heading rules), then run this script. Keep the `.md` as the source of truth and regenerate
the HTML before each render. See `~/.claude/pdf-rendering.md`.

## How it finds Chrome

`scripts/html-to-pdf.cjs` globs `~/.cache/puppeteer/chrome/*/chrome-mac*/…` for the
"Google Chrome for Testing" binary (version-agnostic, so a Chrome update won't break it).
If none is found it tells you to run `npx @puppeteer/browsers install chrome@stable`.
