---
name: playwright-cli
description: Automate browser interactions, test web pages and work with Playwright tests.
author: calmog
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
---

# Browser Automation with playwright-cli

## Quick start

```bash
# open new browser
playwright-cli open
# navigate to a page
playwright-cli goto https://playwright.dev
# interact with the page using refs from the snapshot
playwright-cli click e15
playwright-cli type "page.click"
playwright-cli press Enter
# take a screenshot (rarely used, as snapshot is more common)
playwright-cli screenshot
# close the browser
playwright-cli close
```

## Commands

### Core

```bash
playwright-cli open
# open and navigate right away
playwright-cli open https://example.com/
playwright-cli goto https://playwright.dev
playwright-cli type "search query"
playwright-cli click e3
playwright-cli dblclick e7
playwright-cli fill e5 "user@example.com"
playwright-cli drag e2 e8
playwright-cli hover e4
playwright-cli select e9 "option-value"
playwright-cli upload ./document.pdf
playwright-cli check e12
playwright-cli uncheck e12
playwright-cli snapshot
playwright-cli snapshot --filename=after-click.yaml
playwright-cli eval "document.title"
playwright-cli eval "el => el.textContent" e5
playwright-cli dialog-accept
playwright-cli dialog-accept "confirmation text"
playwright-cli dialog-dismiss
playwright-cli resize 1920 1080
playwright-cli close
```

### Navigation

```bash
playwright-cli go-back
playwright-cli go-forward
playwright-cli reload
```

### Keyboard

```bash
playwright-cli press Enter
playwright-cli press ArrowDown
playwright-cli keydown Shift
playwright-cli keyup Shift
```

### Mouse

```bash
playwright-cli mousemove 150 300
playwright-cli mousedown
playwright-cli mousedown right
playwright-cli mouseup
playwright-cli mouseup right
playwright-cli mousewheel 0 100
```

### Save as

```bash
playwright-cli screenshot
playwright-cli screenshot e5
playwright-cli screenshot --filename=page.png
playwright-cli pdf --filename=page.pdf
```

### Tabs

```bash
playwright-cli tab-list
playwright-cli tab-new
playwright-cli tab-new https://example.com/page
playwright-cli tab-close
playwright-cli tab-close 2
playwright-cli tab-select 0
```

### Storage

```bash
playwright-cli state-save
playwright-cli state-save auth.json
playwright-cli state-load auth.json

# Cookies
playwright-cli cookie-list
playwright-cli cookie-list --domain=example.com
playwright-cli cookie-get session_id
playwright-cli cookie-set session_id abc123
playwright-cli cookie-set session_id abc123 --domain=example.com --httpOnly --secure
playwright-cli cookie-delete session_id
playwright-cli cookie-clear

# LocalStorage
playwright-cli localstorage-list
playwright-cli localstorage-get theme
playwright-cli localstorage-set theme dark
playwright-cli localstorage-delete theme
playwright-cli localstorage-clear

# SessionStorage
playwright-cli sessionstorage-list
playwright-cli sessionstorage-get step
playwright-cli sessionstorage-set step 3
playwright-cli sessionstorage-delete step
playwright-cli sessionstorage-clear
```

### Network

```bash
playwright-cli route "**/*.jpg" --status=404
playwright-cli route "https://api.example.com/**" --body='{"mock": true}'
playwright-cli route-list
playwright-cli unroute "**/*.jpg"
playwright-cli unroute
```

### DevTools

```bash
playwright-cli console
playwright-cli console warning
playwright-cli network
playwright-cli run-code "async page => await page.context().grantPermissions(['geolocation'])"
playwright-cli tracing-start
playwright-cli tracing-stop
playwright-cli video-start
playwright-cli video-stop video.webm
```

## Open parameters
```bash
# Show a real browser window — HEADLESS is the default, so this flag is required
playwright-cli open --headed
# Use specific browser when creating session
playwright-cli open --browser=chromium   # Chrome for Testing — PREFER THIS for headed runs (see below)
playwright-cli open --browser=chrome     # the user's installed Chrome — shares its bundle id (see below)
playwright-cli open --browser=firefox
playwright-cli open --browser=webkit
playwright-cli open --browser=msedge
# Connect to browser via extension
playwright-cli open --extension

# Use persistent profile (by default profile is in-memory)
playwright-cli open --persistent
# Use persistent profile with custom directory
playwright-cli open --profile=/path/to/profile

# Start with config file
playwright-cli open --config=my-config.json
```

### `--browser=chromium` vs `--browser=chrome` for headed runs

Default to **`--browser=chromium`** (which resolves to Google's *Chrome for Testing* build, not
the OSS Chromium project) whenever a headed window will be visible on a desktop the user is
also using.

`--browser=chrome` launches the user's installed Chrome, so the automation instance carries the
**same application bundle id** as their own browser. On macOS that means, for as long as the
automation instance is alive: every link the user clicks anywhere on the system opens in the
automation window, and their Dock/launcher Chrome icon just activates that instance instead of
opening their own profile — so with their own windows closed they effectively cannot get their
browser back. It also makes the window visually indistinguishable from their real ones. Chrome
for Testing is a separate bundle, so it never wins the URL handler and is obvious on sight.

Notes when switching an existing persistent profile over:
- **Logins/cookies carry across.** Playwright always launches with `--use-mock-keychain
  --password-store=basic`, so the cookie-encryption key is deterministic rather than tied to the
  bundle's OS keychain identity. Verify without re-authenticating by copying just
  `<profile>/Default/Cookies` into a scratch profile and reading `context.cookies()` under each
  binary.
- **It can be an older version** than the installed Chrome (it tracks the pinned playwright
  revision). Opening a newer profile with it works, but the UA reports the older version.
- **Anti-bot walls care about headlessness, not branding** — the `HeadlessChrome` UA is the tell.
  Headed Chrome for Testing presents an ordinary Chrome UA with `navigator.webdriver === false`.
- It lives in playwright's browser cache, not `/Applications`, and a playwright upgrade bumps the
  revision and needs a re-install — so unattended jobs should fall back to `--browser=chrome` if
  the open fails, rather than dying.

```bash

# Close the browser
playwright-cli close
# Delete user data for the default session
playwright-cli delete-data
```

## Snapshots

After each command, playwright-cli provides a snapshot of the current browser state.

```bash
> playwright-cli goto https://example.com
### Page
- Page URL: https://example.com/
- Page Title: Example Domain
### Snapshot
[Snapshot](.playwright-cli/page-2026-02-14T19-22-42-679Z.yml)
```

You can also take a snapshot on demand using `playwright-cli snapshot` command.

If `--filename` is not provided, a new snapshot file is created with a timestamp. Default to automatic file naming, use `--filename=` when artifact is a part of the workflow result.

## Targeting elements

By default, use refs from the snapshot to interact with page elements.

```bash
# get snapshot with refs
playwright-cli snapshot

# interact using a ref
playwright-cli click e15
```

You can also use css or role selectors, for example when explicitly asked for it.

```bash
# css selector
playwright-cli click "#main > button.submit"

# role selector
playwright-cli click "role=button[name=Submit]"

# chaining css and role selectors
playwright-cli click "#footer >> role=button[name=Submit]"
```

## Browser Sessions

```bash
# create new browser session named "mysession" with persistent profile
playwright-cli -s=mysession open example.com --persistent
# same with manually specified profile directory (use when requested explicitly)
playwright-cli -s=mysession open example.com --profile=/path/to/profile
playwright-cli -s=mysession click e6
playwright-cli -s=mysession close  # stop a named browser
playwright-cli -s=mysession delete-data  # delete user data for persistent session

playwright-cli list
# Close all browsers
playwright-cli close-all
# Forcefully kill all browser processes
playwright-cli kill-all
```

## Installation

If global `playwright-cli` command is not available, try a local version via `npx playwright-cli`:

```bash
npx --no-install playwright-cli --version
```

When local version is available, use `npx playwright-cli` in all commands. Otherwise, install `playwright-cli` as a global command:

```bash
npm install -g @playwright/cli@latest
```

## Example: Form submission

```bash
playwright-cli open https://example.com/form
playwright-cli snapshot

playwright-cli fill e1 "user@example.com"
playwright-cli fill e2 "password123"
playwright-cli click e3
playwright-cli snapshot
playwright-cli close
```

## Example: Multi-tab workflow

```bash
playwright-cli open https://example.com
playwright-cli tab-new https://example.com/other
playwright-cli tab-list
playwright-cli tab-select 0
playwright-cli snapshot
playwright-cli close
```

## Example: Debugging with DevTools

```bash
playwright-cli open https://example.com
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli console
playwright-cli network
playwright-cli close
```

```bash
playwright-cli open https://example.com
playwright-cli tracing-start
playwright-cli click e4
playwright-cli fill e7 "test"
playwright-cli tracing-stop
playwright-cli close
```

## Gotchas and tricks

### "The window never opened" — `open` is headless by default
`playwright-cli open` runs **headless**; there is no auto-detection of intent. Whenever the
point is for a human to *watch* the browser (a login with 2FA, a visual repro, a UI demo),
`--headed` must be on the `open` command — assuming it's the default gets you a session that
works fine over the CLI while no window ever appears. Applies to `-s=<session> open` too, and
`--headed` is an option of `open` alone — no later command accepts it, so a session that was
opened headless has to be `close`d and re-`open`ed to get a window.

### Editors built on ProseMirror / tiptap
If a page uses tiptap, the `.ProseMirror` DOM node exposes `.editor` which is the tiptap Editor instance. This lets you bypass keyboard-based schema enforcement (e.g., apps that force first block to be a heading when you type):

```javascript
await page.evaluate(() => {
  const pm = document.querySelector('.ProseMirror');
  const ed = pm.editor;
  ed.commands.setContent({
    type: 'doc',
    content: [
      { type: 'paragraph', content: [{ type: 'text', text: 'Line 1' }] },
      { type: 'paragraph', content: [{ type: 'text', text: 'Line 2' }] }
    ]
  });
});
```

You can also inspect schema via `ed.schema.nodes` and current doc via `ed.state.doc.toJSON()`. Commands like `setParagraph()` may be no-ops if the app's schema enforces heading on first block — `setContent` with explicit JSON is the hammer.

Note: `setContent` updates the editor view but may not always commit through the host form's onChange. Some apps require clicking an explicit Save/Publish button (via real `page.mouse.click(x, y)` on coordinates, not `btn.click()`, which can close the modal before the click registers).

### `goto` and `reload` timeouts
`playwright-cli goto` and `reload` commonly time out waiting for the AI snapshot (5s default), but the underlying navigation still completes. After a timeout, sleep 3–5s and verify with `run-code` → `page.evaluate(() => ({url: location.href, title: document.title}))`. Don't retry the navigation.

### Running scripts in background returns empty files
Running `playwright-cli -s=X run-code "..."` via Bash `run_in_background: true` often yields **empty output files** at `/tmp/.../tasks/<id>.output`. Run playwright-cli **synchronously** — the commands are generally fast enough, and the output comes back directly in the response.

### Input concatenation after partial clears
`page.keyboard.press('Backspace')` in a loop (e.g., 10×) is unreliable for clearing React-Select or controlled inputs. Previous text bleeds into new typing (e.g., "Node.js" after stale "React" → "Node.jsact"). **Always clear with `Cmd+A` → `Backspace`:**

```javascript
await page.keyboard.down('Meta'); await page.keyboard.press('a'); await page.keyboard.up('Meta');
await page.waitForTimeout(200);
await page.keyboard.press('Backspace');
```

### `btn.click()` vs `page.mouse.click(x, y)`
DOM `btn.click()` fires a synthetic event that some apps handle differently from real pointer events. For custom toolbars (rich-text editors, React-Select dropdowns), **prefer real mouse coordinates** — it preserves focus chains and triggers `mousedown` `preventDefault` patterns the app relies on.

### Triggering React onChange after programmatic setContent
After tiptap `setContent()` or direct DOM mutation, the host React form's onChange may not fire, leaving the form state stale even though the editor shows the new content. **Focus the editor and send a space+backspace to trigger the onChange path:**

```javascript
await page.mouse.click(editorX, editorY);  // focus
await page.keyboard.press('End');          // cursor to end
await page.keyboard.type(' ');              // trigger onChange
await page.keyboard.press('Backspace');     // undo the space
```

Needed when the form requires onChange to unlock the Publish/Save button, or to mark the form "dirty" for the parent component.

### React-Select placeholder text is not a matchable element
`[class*="Select"]`, `role=combobox`, and `div.textContent === "Select industry"` often all return empty — the placeholder is rendered as styled content inside a complex component. **Use mouse coordinate clicks on the visible box location** (from a screenshot), then `page.keyboard.type()` the search text, then click the matching option.

### Some save buttons aren't called "Save"
When looking for save/submit in modals, check multiple labels: `Save`, `Publish`, `Submit`, `Add experience`, `Add skills`, `Apply`. One app can use different labels in different modal contexts for the same action. Either search for a list of candidates or look for the primary button (usually right side, styled prominent).

### Escape keys and Close buttons can trigger a "Quit? progress lost" confirm
On apps that track dirty state, closing a modal via X or Escape can open a second confirmation dialog. Don't treat modal-still-present as failure — check for a "Quit" / "Discard" button and click it. Sometimes this dialog fires even when no edits were made.

### Clicking inside a react-select dropdown without an X/Y to reach the option
The expanded dropdown list is a fixed-position overlay — get the visible options via `[class*="option"]` or `[role="option"]` and click via bounding-box coordinates. Do NOT `option.click()` via DOM — it can close the dropdown without commiting the selection.

## Specific tasks

* **Running and Debugging Playwright tests** [references/playwright-tests.md](references/playwright-tests.md)
* **Request mocking** [references/request-mocking.md](references/request-mocking.md)
* **Running Playwright code** [references/running-code.md](references/running-code.md)
* **Browser session management** [references/session-management.md](references/session-management.md)
* **Storage state (cookies, localStorage)** [references/storage-state.md](references/storage-state.md)
* **Test generation** [references/test-generation.md](references/test-generation.md)
* **Tracing** [references/tracing.md](references/tracing.md)
* **Video recording** [references/video-recording.md](references/video-recording.md)
