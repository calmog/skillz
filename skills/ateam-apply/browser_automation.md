# Browser Automation — Technical Reference

This file holds the Playwright/A.Team specifics. Read it on demand when actually filling forms — don't preload it just to scan missions.

## Session conventions

Always use the `$PLAYWRIGHT_SESSION` environment variable — never hardcode a session name. In every `playwright-cli` command, pass `-s=$PLAYWRIGHT_SESSION`. If the variable is unset, fall back to `browser-default`.

### Session startup
```bash
playwright-cli -s=$PLAYWRIGHT_SESSION run-code "async page => { return await page.evaluate(() => document.title); }"
```
Never use `snapshot` — it always times out. Use `run-code` with `page.evaluate()` instead.

### Session restart loop
The in-memory Playwright browser session can spontaneously restart mid-flow ("Browser opened with pid ..." appears mid-task and the page becomes `about:blank`). Symptoms: `goto` times out with "Target page, context or browser has been closed", every subsequent navigate triggers a fresh restart, and the loop repeats. When this happens 2+ times in a row, stop and tell the user. Do not try to push through with more navigations. Likely fixes that they need to run (not you): `playwright-cli list` to inspect, `playwright-cli close-all` then `playwright-cli kill-all` to wipe zombies, or open a fresh terminal/Claude session so `$PLAYWRIGHT_SESSION` is rebound.

## Reading page content

**Notification panel pollution.** `document.body.innerText` starts with nav sidebar content containing hundreds of invisible `‌` zero-width characters, which consume the first ~6000 chars before reaching actual mission content. Worse, if the notification panel is open, it injects text like "Team status\nBuilders proposed to company" from OTHER missions into every page read — causing false negatives.

Always close the notification panel before reading, and use the `[class*="mission"]` selector or the "last Mark as read" skip trick:

```javascript
// Option 1: close notification panel, then read from mission container
async page => {
  await page.mouse.click(640, 400); // click main content to dismiss panel
  await page.waitForTimeout(500);
  return await page.evaluate(() => {
    const els = [...document.querySelectorAll('[class*="mission"]')];
    let longest = '';
    for (const el of els) {
      if (el.innerText && el.innerText.length > longest.length) longest = el.innerText;
    }
    return longest.substring(0, 6000);
  });
}

// Option 2: skip notification panel text using "last Mark as read" anchor
async page => {
  return await page.evaluate(() => {
    const text = document.body.innerText;
    const idx = text.lastIndexOf('Mark as read\n');
    return idx >= 0 ? text.substring(idx + 13, idx + 6000) : text.substring(text.length - 4000);
  });
}
```

## Clicking buttons by text
```bash
playwright-cli -s=$PLAYWRIGHT_SESSION run-code "async page => { await page.evaluate(() => { const btn = [...document.querySelectorAll('button')].find(b => b.textContent.trim() === 'Request to join'); if (btn) btn.click(); }); await page.waitForTimeout(1500); return await page.evaluate(() => document.title); }"
```

## Filling React textareas (fiber approach — required for MobX/React state)
Write the script to /tmp first, then run it:
```javascript
// /tmp/fill_texts.js
async page => {
  const text1 = "...";
  const text2 = "...";
  await page.evaluate(([t1, t2]) => {
    const textareas = document.querySelectorAll("textarea");
    const fk = el => Object.keys(el).find(k => k.startsWith("__reactFiber") || k.startsWith("__reactInternalInstance"));
    function triggerReact(el, val) {
      let n = el[fk(el)];
      while (n) {
        if (n.memoizedProps && typeof n.memoizedProps.onChange === "function") {
          n.memoizedProps.onChange({ target: { value: val }, currentTarget: { value: val } });
          return;
        }
        n = n.return;
      }
    }
    const setter = Object.getOwnPropertyDescriptor(window.HTMLTextAreaElement.prototype, "value").set;
    if (textareas[0]) { setter.call(textareas[0], t1); textareas[0].dispatchEvent(new Event("input", { bubbles: true })); triggerReact(textareas[0], t1); }
    if (textareas[1]) { setter.call(textareas[1], t2); textareas[1].dispatchEvent(new Event("input", { bubbles: true })); triggerReact(textareas[1], t2); }
  }, [text1, text2]);
  await page.waitForTimeout(800);
  return await page.evaluate(() => {
    const tas = document.querySelectorAll("textarea");
    return { t1len: tas[0] ? tas[0].value.length : 0, t2len: tas[1] ? tas[1].value.length : 0 };
  });
}
```
Same pattern works for `<input>` — use `HTMLInputElement.prototype` setter instead.

The "Enter at least 20 characters" warning can be stale — if the char counter shows e.g. 745/3,000, the text is registered. The warning is a UI artifact and doesn't block Submit.

## Adding a required skill (rating popup flow)

1. Click the "Add" button next to the skill name (it's a `<button>` whose parent text contains the skill name)
2. A modal appears with rating 1-5. The numbers are rendered as `<div>` inside `<div class="num-0-2-1330">` inside `<div class="row-0-2-1329">`
3. Get the bounding box of the `num-0-2-1330` div for the desired rating, then use mouse coordinates to click it
4. Click the "Add skills" button inside `.ReactModal__Content` to confirm

```javascript
// Step 3: get position of rating "3"
async page => {
  return await page.evaluate(() => {
    const modal = document.querySelector(".ReactModal__Content");
    const allDivs = [...modal.querySelectorAll("div")];
    const num3 = allDivs.find(d => d.textContent.trim() === "3" && d.children.length === 0 && d.parentElement && d.parentElement.className.includes("num-0-2-1330"));
    const rect = num3.getBoundingClientRect();
    return { cx: Math.round(rect.x + rect.width/2), cy: Math.round(rect.y + rect.height/2) };
  });
}
// Then: playwright-cli -s=$PLAYWRIGHT_SESSION mousemove <cx> <cy> && playwright-cli -s=$PLAYWRIGHT_SESSION mousedown && playwright-cli -s=$PLAYWRIGHT_SESSION mouseup
// Then click "Add skills" button in modal
```

**Modal/Add-skills persistence pitfall.** Clicking "Add skills" inside the profile-edit skill modal closes the modal but does not always persist the skill on the profile — even after also clicking the main profile "Save" button at the top right and seeing edit mode exit. After reload, the added skill is gone. Workaround: don't rely on the global profile skill add. Add the skill inside a project card's "Skills used" list instead — those saves are reliable and the platform's per-mission match logic reads from project skills anyway. The "Add Role to profile" flow (next to "Additional Roles") *does* save reliably — this pitfall is specific to the Skills add modal.

## Checking/clicking consent checkbox
```javascript
async page => {
  await page.evaluate(() => {
    const checkboxes = [...document.querySelectorAll("input[type=checkbox]")];
    for (const cb of checkboxes) { if (!cb.checked) cb.click(); }
  });
}
```

## Selecting projects
```javascript
// Get list of selectable projects with their indices
async page => {
  return await page.evaluate(() => {
    const selectBtns = [...document.querySelectorAll("button")].filter(b => b.textContent.trim() === "Select");
    return selectBtns.map((b, i) => {
      const parent = b.closest("li") || b.parentElement?.parentElement?.parentElement;
      return { i, text: parent ? parent.innerText.substring(0, 100) : "?" };
    });
  });
}
// Then select by index:
async page => {
  await page.evaluate(() => {
    const selectBtns = [...document.querySelectorAll("button")].filter(b => b.textContent.trim() === "Select");
    [0, 1, 3].forEach(i => { if (selectBtns[i]) selectBtns[i].click(); });
  });
  await page.waitForTimeout(1500);
}
```

## Working hours dropdown

Working hours end-time is a React-Select dropdown, not a slider — DOM manipulation won't open it. Use `page.mouse.click(x, y)` with real viewport coordinates, then find and click the `[class*="option"]` element with the target time. If the page says "Add X hours to meet requirement", extend the end-time accordingly before submitting.

## Taking screenshots (for verification)
```bash
playwright-cli -s=$PLAYWRIGHT_SESSION screenshot --filename=/tmp/check.png
```

## Final submission check

Verify the positive confirmation banner before clicking Submit, not just absence of the negative one. The platform shows two distinct states near the bottom of the form, just above the footer:

- **Positive (ready to submit):** `"Your application is very impressive and there's nothing significant left to refine."` followed by `"You should feel confident submitting your application."`
- **Negative (incomplete):** `"Your application needs some work."` followed by a list of sections to fix.

Check explicitly for the positive banner. Submit being enabled and the negative banner being absent is a weaker check — the negative banner can be absent even when the positive one hasn't appeared yet.

```javascript
async page => {
  return await page.evaluate(() => {
    const submitBtn = [...document.querySelectorAll("button")].find(b => b.textContent.trim() === "Submit");
    const text = document.body.innerText;
    return {
      disabled: submitBtn ? submitBtn.disabled : "not found",
      hasPositiveBanner: text.includes("nothing significant left to refine") || text.includes("feel confident submitting"),
      hasNegativeBanner: text.includes("needs some work"),
    };
  });
}
```
Only proceed to Submit if `hasPositiveBanner: true` AND `hasNegativeBanner: false` AND `disabled: false`. If positive banner is missing, screenshot the page and investigate which section is incomplete.

**Submit can be automated.** Clicking Submit via `page.evaluate()` button click works and submits successfully. reCAPTCHA does not block it in practice. Don't ask the user to click Submit manually; just click it programmatically.

**Silent Submit success — the email is the source of truth.** After clicking Submit, sometimes the URL does not change and the apply page stays visually identical (no redirect, no Team Up screen, no confirmation toast). The submission may still have gone through — the A.Team confirmation email is the only reliable signal. Don't retry Submit aggressively when nothing visible happens; each retry risks duplicate applications or stale-state issues. Check Gmail for the confirmation email instead.

### Post-submit confirmation flow
1. Click Submit once via `page.evaluate()` (or mouse click) on the Submit button.
2. Wait ~10 seconds.
3. Check Gmail via `mcp__claude_ai_Gmail__search_threads` for a recent A.Team confirmation email matching this mission name (search query like `from:noreply@a.team newer_than:5m` or include the company name). If found, the application is submitted — log it and move on.
4. Only if Gmail shows no confirmation after 10-15s, check the apply page URL: if it changed to `/edit/<id>?suggest=true` (Team Up screen), also confirmed — handle the Skip flow. If neither Gmail nor URL changed, investigate before retrying.
5. Never retry Submit blindly. Each retry risks duplicate applications, rate-limits, or accidentally undoing the submission with a stale form state.

## Opening a new terminal window for a mission

Always `cd` into the project folder first, and use single-quoted outer AppleScript string to avoid escaping issues with `--dangerously-skip-permissions`:

```bash
osascript -e 'tell application "Terminal" to do script "cd <project-folder> && claude --dangerously-skip-permissions \"apply to this A.Team mission: https://...\""'
```
