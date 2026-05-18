---
name: web-browse
description: Generic web browsing and page interaction skill. Use for ANY task involving opening URLs, reading pages, clicking, filling forms, scraping content, or automating web workflows. Default to playwright-cli; the Chrome extension (mcp__claude-in-chrome__*) is only allowed as a fallback when playwright-cli is blocked by bot/automation detection (Cloudflare/Turnstile/hCaptcha, headless fingerprinting, etc.).
author: calmog
allowed-tools: Bash(playwright-cli:*) Bash(cat:*) Write(/tmp/*) Read(/tmp/*)
---

# Web Browsing with playwright-cli

**Rule:** Default to `playwright-cli` with the patterns below. The Chrome extension (`mcp__claude-in-chrome__*`) is only for the bot-detection fallback case — it drives the user's real Chrome via screenshots, which is much more expensive (~1200 tokens per screenshot) but bypasses automation fingerprinting. Don't fall back to it for selector/JS-heavy/"feels slow" reasons; state the bot-detection symptom first.

**Token principle:** Every `run-code` call echoes the full script + a result block. Minimize calls and return only what you need.

**Screenshot ban:** Never use `playwright-cli screenshot`. Screenshots cost ~1200 tokens fixed. If you don't know the selector, use scoped `innerText` on a container or search for a keyword — never a screenshot.

---

## Account-Ban-Risk Sites — Never Automate

Some sites fingerprint automation and **close accounts** when they detect it. **Never use playwright-cli on these sites — not headless, not with `--persistent --profile=...` pointing at the user's real Chrome, not in any form.** Personal accounts on these services are irreplaceable; the asymmetry is total (lose account = lose years of history; alternative paths cost minutes).

**Banned for playwright-cli automation:**
- **LinkedIn** — never log in via playwright; never point playwright at a profile that has LinkedIn cookies. Confirmed failure modes: signed-out → authwall; signed-in → fingerprint-based account restriction.
- **Twitter/X, Facebook, Instagram, Threads** — same model.
- **Gmail / Google account surfaces** — account lockout is unrecoverable.
- **Any service the user has a personal account on that they can't afford to lose.**

### Fallback ladder for these sites (LinkedIn worked example)

1. **WebSearch** — `site:linkedin.com/in <name>`, `site:linkedin.com/posts <name>`, `site:linkedin.com/pulse <name>`. Returns Google snippets (headline, post titles, partial bodies) plus URLs.
2. **WebFetch on public mirrors** — RocketReach, ZoomInfo, TheOrg, Crunchbase, Wellfound, company website. Essentially LinkedIn re-served; undated but rich on history/education/role.
3. **WebFetch on the LinkedIn URL itself** — works for `/pulse/` articles (full body); partial guest view on `/posts/` URLs (metadata + outside comments, NOT original post body); `/in/` profile URLs return 404.
4. **Manual paste workflow** — ask the user to open the page in their real Chrome and paste relevant content into the conversation. Zero ban risk, full data, ~30 seconds of their time. **Default to this when you need rich post content / activity feed / recommendations / "voice" signal — that data genuinely isn't accessible any other way without paying.**
5. **Paid LinkedIn-data API** (Proxycurl, Bright Data, CoreSignal, Lix) — scraping risk is on the provider, not you. ~$0.01–$0.10 per profile lookup. Use only when a programmatic workflow truly needs it.
6. **Chrome-extension MCP** (`mcp__claude-in-chrome__*`) — drives the user's real Chrome via screenshots; lower ban risk because the fingerprint is genuinely theirs. **Only as a passive reader on pages they're already viewing — never let it click/scroll/paginate on LinkedIn.**

### What playwright-cli IS still good for

- Public sites without aggressive bot detection
- Application portals where the user has legitimate auth and the site tolerates automation
- Pages where you need to interact (click, fill, submit) and the site isn't ban-risk
- His own dashboards / internal tools

---

## Session Setup

```bash
# Check what's already open (free — no output block)
playwright-cli list

# Open with logged-in Chrome profile
playwright-cli -s=mysession open --browser=chrome --persistent --profile="/Users/YOUR_USERNAME/Library/Application Support/Google/Chrome/Profile 1" https://example.com
```

Always use a named session (`-s=name`). Navigate + verify in one call — don't use standalone `goto` (it triggers a snapshot attempt):

```bash
# Bad: goto triggers snapshot attempt
playwright-cli -s=s goto https://example.com

# Good: navigate and confirm in one block
playwright-cli -s=s run-code "async page => { await page.goto('https://example.com'); await page.waitForTimeout(1500); return await page.evaluate(() => document.title); }"
```

---

## Reading Page Content

**Never use `snapshot`** — always times out. **Never dump `body.innerText`** — expensive and imprecise.

### Step 1 — Try a targeted selector (cheapest, ~5–50 tokens in result)
```bash
# Extract exactly what you need
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => ({ title: document.title, price: document.querySelector('.price')?.innerText, status: document.querySelector('[data-status]')?.dataset.status })); }"
```

### Step 2 — If you don't know the selector, scope innerText tightly
```bash
# Scope to a known container, not body
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => document.querySelector('main, article, [class*=content], [class*=form]')?.innerText?.substring(0, 1500) ?? document.body.innerText.substring(0, 1500)); }"

# Or search for a keyword and return context around it only
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => { const t = document.body.innerText; const i = t.indexOf('Required skills'); return i >= 0 ? t.substring(i, i + 600) : 'not found'; }); }"
```

**Never** use `body.innerText.substring(0, 6000)` — it's ~1000 tokens in the result alone.

---

## Clicking Elements

Batch click + wait + verify into one call:

### By text content
```bash
playwright-cli -s=s run-code "async page => { await page.evaluate(() => { const btn = [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Submit'); if (btn) btn.click(); }); await page.waitForTimeout(1500); return await page.evaluate(() => ({ title: document.title, url: location.href })); }"
```

### Identify available buttons (minimal return)
```bash
# Return text + disabled state — enough to pick the right one
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => [...document.querySelectorAll('button')].map(b => b.textContent.trim()).filter(Boolean)); }"
```

### By coordinates (when JS click is blocked by an overlay)
```bash
# Get position and click in one call
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => { const el = document.querySelector('.target'); const r = el.getBoundingClientRect(); return { cx: Math.round(r.x + r.width/2), cy: Math.round(r.y + r.height/2) }; }); }"
# Then one command with coordinates (3 commands, but each is tiny)
playwright-cli -s=s mousemove 531 216 && playwright-cli -s=s mousedown && playwright-cli -s=s mouseup
```

---

## Filling Forms

### Simple inputs (non-React) — batch fill + verify
```bash
playwright-cli -s=s run-code "async page => { const i = await page.$('input[name=email]'); await i.fill('user@example.com'); return await page.evaluate(() => document.querySelector('input[name=email]').value); }"
```

### React/MobX inputs — fiber approach (required, standard DOM setters don't work)

Write to `/tmp/fill.js` to avoid inline quoting issues. Return only lengths to confirm — not the full text:

```javascript
// /tmp/fill.js
async page => {
  await page.evaluate(([t1, t2]) => {
    const fk = el => Object.keys(el).find(k => k.startsWith("__reactFiber") || k.startsWith("__reactInternalInstance"));
    function set(el, val, proto) {
      Object.getOwnPropertyDescriptor(proto, "value").set.call(el, val);
      el.dispatchEvent(new Event("input", { bubbles: true }));
      let n = el[fk(el)];
      while (n) { if (n.memoizedProps?.onChange) { n.memoizedProps.onChange({ target: { value: val }, currentTarget: { value: val } }); break; } n = n.return; }
    }
    const tas = document.querySelectorAll("textarea");
    if (tas[0]) set(tas[0], t1, window.HTMLTextAreaElement.prototype);
    if (tas[1]) set(tas[1], t2, window.HTMLTextAreaElement.prototype);
  }, ["text one", "text two"]);
  await page.waitForTimeout(500);
  // Return lengths only — not the full text (avoids echoing back hundreds of words)
  return await page.evaluate(() => [...document.querySelectorAll("textarea")].map(t => t.value.length));
}
```

---

## Modals and Popups

### Detect and read in one call
```bash
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => { const m = document.querySelector('.ReactModal__Content, [role=dialog]'); if (!m) return null; return { text: m.innerText.substring(0, 300), buttons: [...m.querySelectorAll('button')].map(b => b.textContent.trim()) }; }); }"
```

### Dismiss beforeunload dialog
```bash
playwright-cli -s=s dialog-dismiss
```

---

## Scrolling

Never scroll as a standalone call — always chain it with the next action:

```bash
# Bad: separate scroll + separate read = 2 blocks
playwright-cli -s=s run-code "async page => { await page.evaluate(() => window.scrollTo(0, 2000)); return 'scrolled'; }"
playwright-cli -s=s run-code "async page => { return await page.evaluate(() => document.querySelector('.target')?.innerText); }"

# Good: scroll + read in one block
playwright-cli -s=s run-code "async page => { await page.evaluate(() => window.scrollTo(0, 2000)); await page.waitForTimeout(300); return await page.evaluate(() => document.querySelector('.target')?.innerText); }"
```

---

## Writing and Running Scripts

Use `/tmp/` files only when inline quoting is the problem — the script is echoed in full either way, so keep them short. Avoid long scripts just for organization.

```bash
cat << 'SCRIPT' > /tmp/task.js
async page => {
  await page.evaluate(() => document.querySelector('button.confirm').click());
  await page.waitForTimeout(1000);
  return await page.evaluate(() => ({ done: !document.querySelector('.loading'), count: document.querySelectorAll('.item').length }));
}
SCRIPT
playwright-cli -s=mysession run-code "$(cat /tmp/task.js)"
```

---

## Session Management

```bash
playwright-cli list           # list open sessions
playwright-cli -s=name close  # close one session
playwright-cli close-all      # close all
```

---

## Token Cost Reference

| Pattern | Cost | Use when |
|---|---|---|
| Targeted `querySelector` extraction | ~5–50 tokens | You know the selector |
| Screenshot + Read | ~1200 tokens fixed | **Never** |
| Scoped `innerText` (container, not body) | ~200–600 tokens | No good selector, page is structured |
| `body.innerText` dump | ~1000–2000 tokens | **Never** — use scoped innerText instead |
| `snapshot` | Very high + timeout | **Never** |
| Batched multi-step `run-code` | 1 block total | Always batch when possible |
| Separate `run-code` per action | N blocks | Only when steps genuinely can't be combined |

---

## Common Gotchas

- **Snapshot timeouts**: `playwright-cli snapshot` always times out on complex pages.
- **React state**: Setting `element.value` directly doesn't update React state. Always use the fiber `onChange` pattern above.
- **Modals blocking clicks**: If a click times out with "subtree intercepts pointer events", a modal is open. Read it first.
- **Inline quoting**: Avoid nested quotes in inline `run-code` strings — write to `/tmp/` instead.
- **Persistent session**: Use `--persistent --profile=<path>` to reuse an existing logged-in browser profile.
- **Verify with lengths, not values**: When confirming form fills, return `.value.length` not `.value` — avoids echoing hundreds of words back.
