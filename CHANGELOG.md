# Changelog

## 2026-06-11

### Added
- **html-to-pdf** skill. Renders any HTML file to PDF by driving the cached Chrome-for-Testing binary through `puppeteer-core`. Full headless Chromium, so CSS, web fonts, images and Hebrew/RTL all render correctly. Hand-rolled arg parsing (no yargs), so it survives Node upgrades. Reads the page count back from the output and can enforce a hard page limit with `--max-pages=N`. Replaces the old `aviz-html-to-pdf`, whose CLI broke under Node 26 with a yargs/ESM load error.

### Changed
- README skills table now lists every public skill. Added `html-to-pdf`, `todoist` and `config-authoring`, which were shipped but missing from the table.
