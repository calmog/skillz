---
name: todoist
author: calmog
description: "Manage Todoist — create, update, complete, and organize tasks, projects, sections, and reminders, including rescheduling. Consult before any Todoist action. Use when the user mentions Todoist or a to-do list, asks to add/track a task or set a reminder, or wants to manage projects/sections, reschedule items, or order/sort the Today view (incl. exact manual day_order via the Sync API)."
---

# Todoist Skill

## CRITICAL: Authorization Check First

**BEFORE calling any Todoist MCP tool, verify the connector is active.**

If Todoist tools are unavailable, return an auth error, or are not listed in available tools:
- Do NOT attempt workarounds
- Do NOT use the Anthropic API to call Todoist MCP directly
- STOP and tell the user exactly this:

> "The Todoist connector isn't currently active. Please reconnect it in your MCP settings, then confirm and I'll proceed."

**Signs the connector is broken mid-session:**
- `HTTP 401` or `UNAUTHORIZED` errors
- `"This connector requires authentication"` errors
- `"Tool not found"` errors for Todoist tools
- Tools disappearing after working earlier in the conversation

In all these cases: stop, show the user the error, ask them to reauth, and wait for confirmation. Never silently retry more than once.

---

## GUARDRAIL: Every task must have a date — always

**Hard rule. No task may exist without a due date. Applies to every create and every edit.**

- **On create (`add-tasks`):** always include a `dueString`. Never create a dateless task. If the user didn't say when, default to today (`dueString: "today"`) unless the context clearly implies another date — don't silently leave it blank.
- **On edit (`update-tasks` / `reschedule-tasks`):** never drop or clear an existing date. If you're changing a task for any reason, preserve its due date (or move it to a new date) — never end up with no date.
- **Never remove a task's date.** Do **not** call `update-tasks` with `dueString: "remove"`. The only exception: Almog explicitly asks, in the current request, to remove that specific task's date. Absent that explicit instruction, removing a date is forbidden — including as a side effect of any other edit.

**Bottom line: after any create or edit, the task has a date. No exceptions without an explicit "remove the date" from Almog.**

---

## Confirmed Tool Behavior

### add-sections

Normally returns a clean success response with section IDs. However, a false-error quirk has been reported (MCP response surfaces as an error even though sections were created server-side) — unverified as of 2026-05-25.

**Defensive workflow regardless:**
1. Call `add-sections` (bulk — all sections in one call)
2. If the response looks like an error, **do not retry** — call `find-sections` first to check actual state
3. Use the IDs from `find-sections`, not from the `add-sections` response, to be safe

**Never retry `add-sections` after an error response without checking `find-sections` first — it may create duplicates.**

### add-tasks

Always assign tasks to sections using `sectionId`, not just `projectId`. Tasks without a `sectionId` land in the unsectioned area regardless of project structure.

Supports: `content`, `description`, `priority` (string), `dueString`, `deadlineDate`, `duration`, `sectionId`, `projectId`, assignments to collaborators.

### reschedule-tasks vs update-tasks

- **`reschedule-tasks`** — use to shift the next due date while keeping the recurrence pattern intact. Accepts `YYYY-MM-DD` (preserves existing time) or `YYYY-MM-DDTHH:MM:SS` (sets both). Always use this for moving task dates.
- **`update-tasks` with `dueString`** — use only to (a) set/change the due date of a non-recurring task, or (b) replace the entire recurrence pattern. The new `dueString` overwrites the existing due config completely — partial updates are not possible.
- **Never use `update-tasks` to reschedule a recurring task** — it destroys the recurrence pattern.

### complete-tasks

Requires `ids` parameter (array of strings). Not `tasks`.

### Priorities

Must be strings: `"p1"`, `"p2"`, `"p3"`, `"p4"`. `p1` is highest, `p4` is lowest/default. Integer values are not accepted.

### deadlineDate

A separate field from `dueString` — use for immovable hard constraints (e.g. a submission deadline). Format: ISO 8601 `"2025-12-31"`. Remove with `deadlineDate: "remove"`. Both `dueString` and `deadlineDate` can be set on the same task simultaneously.

### duration

Supported on `add-tasks` and `update-tasks`. Formats: `"2h"`, `"90m"`, `"2h30m"`. Useful for time-blocking.

### Removing fields

- Remove due date: `update-tasks` with `dueString: "remove"` — **forbidden by default**, see the "Every task must have a date" guardrail above. Only when Almog explicitly asks to remove this task's date.
- Remove deadline: `update-tasks` with `deadlineDate: "remove"` (the deadline is separate from the due date; removing it is fine and does not violate the date guardrail)
- Remove section (move to root): omit `sectionId` entirely — there is no `sectionId: null` or empty-string variant

### Detaching tasks from sections

To move a task out of its current section to the project root: call `update-tasks` with `projectId` set to the task's current project ID, and **omit `sectionId`**. The response will no longer contain a `sectionId` field.

### Deleting sections safely

Deleting a section may delete tasks still belonging to it. Always detach tasks first:

1. `find-tasks` with `sectionId` to enumerate every task in the section
2. `update-tasks` (one batched call) with `projectId` set and `sectionId` omitted, for every task in the section
3. `delete-object` with `type: "section"` to remove the now-empty section
4. `find-tasks` on the project afterward to confirm tasks are intact

---

## Ordering tasks in the Today / Upcoming view

**Smart sort (the default) tie-break order:** due date+time → priority (P1→P4) → deadline → manual `day_order` → creation time. Timed tasks sort chronologically and ahead of untimed ones for the day; **overdue** tasks group in a pinned section at the top and can't be manually reordered. An explicit per-view sort (Priority/Date/Name) overrides Smart sort.

**To force a specific order, two paths:**

1. **Via the MCP (no token) — partial.** The MCP cannot set `day_order` (`reorder-objects` = projects/sections only; `update-tasks.order` = within-section only). Order tasks by giving each an explicit due **time** in sequence, with priority as tiebreak. Deterministic only if every task is timed; untimed tasks aren't reliably placeable.

2. **Via the Sync API (exact, preferred) — needs the API token.** Sets true `day_order` (manual position); works for untimed tasks. **Requires the user's Today view Sort = "Manual"** for `day_order` to be the primary key (under Smart sort it's only the 4th tiebreak, so it won't visibly move anything).
   - Token: read from `~/.config/todoist/api_token` (chmod 600). Never print or echo the value.
   - Command (`ids_to_orders` maps task ID → 1-based position; IDs are the same ones the MCP returns):
     ```bash
     TOKEN=$(cat ~/.config/todoist/api_token)
     CMD='[{"type":"item_update_day_orders","uuid":"'"$(uuidgen)"'","args":{"ids_to_orders":{"<taskId>":1,"<taskId>":2}}}]'
     curl -s -X POST https://api.todoist.com/api/v1/sync \
       -H "Authorization: Bearer $TOKEN" --data-urlencode "commands=$CMD"
     ```
   - Success = response contains `"sync_status": { "<uuid>": "ok" }`. (Endpoint: `https://api.todoist.com/api/v1/sync`; Sync API only — REST has no day_order.)

---

## Correct Project Creation Workflow

1. `add-projects` → capture projectId
2. `add-sections` with all sections in one call → even if response looks like an error, proceed to step 3
3. `find-sections` on the projectId → capture each sectionId from the actual response
4. `add-tasks` with correct `sectionId` for each task

Never add tasks before confirming sections exist via `find-sections`.

---

## isUncompletable Header Tasks

Use `isUncompletable: true` only for intentional visual headers within a section. Do NOT use as a fallback for sections — sections work even when the tool response looks like an error.

---

## Recurring Task dueString Formats

### Confirmed working
- `"every 4 days starting 2026-04-13 at 21:00"`
- `"every 2 days starting 2026-04-11 at 21:00"`
- `"every week starting 2026-04-16 at 21:00"`
- `"every month starting 2026-05-09 at 21:00"`
- `"every 2 weeks on saturday at 21:00 starting 2026-05-09"`
- `"every 3 weeks on saturday at 21:00 starting 2026-05-16"`
- `"every 4 weeks on saturday at 21:00 starting 2026-05-09"`
- `"every 12 weeks on saturday at 21:00 starting 2026-06-27"`

### Known failures
- `"every 3 months on saturday at 21:00 starting YYYY-MM-DD"` → HTTP 400. The `every N months on [weekday]` combination is rejected by the parser.
- **Workaround**: use weeks. Approximations: 4 weeks ≈ 1 month, 12 weeks ≈ 3 months, 24 weeks ≈ 6 months, 52 weeks ≈ 1 year. If exact calendar alignment matters, drop the weekday anchor and use `"every N months starting YYYY-MM-DD at HH:MM"`.
