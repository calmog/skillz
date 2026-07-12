---
name: todoist
author: calmog
description: "Manage Todoist — create, update, complete, and organize tasks, projects, sections, and reminders, including rescheduling. Consult before any Todoist action. Use when the user mentions Todoist or a to-do list, asks to add/track a task or set a reminder, or wants to manage projects/sections, reschedule items, or order/sort the Today view (incl. exact manual day_order via the Sync API)."
---

# Todoist Skill

## Access: MCP is the registered primary; v1 token API is the explicit fallback

Two access paths. **Default to the MCP.** Use the token API only in the two cases named below — don't deduce when to switch, they're stated here.

**Primary — the Todoist MCP connector** (`mcp__todoist__*`: `add-tasks`, `find-tasks`, `reschedule-tasks`, etc.). It's a **registered Claude Code connector** (user scope, so present in every project), added via:
```
claude mcp add --scope user --transport http todoist https://ai.todoist.net/mcp
```
Streamable HTTP + OAuth; endpoint `https://ai.todoist.net/mcp`. It shows as plain `todoist` (not `claude.ai Todoist`) — that's expected, it's the CLI-registered one, separate from account-managed connectors. **Use it for everything except the fallback cases below.**

**Fallback — the direct v1 token API.** Reach for it in exactly two situations:

1. **Completed-task operations the MCP genuinely cannot do** — moving a completed/filled task (preserving `completed_at`) or backdating a completion date. Always use the token API for these; don't uncomplete→move→recomplete via the MCP (it clobbers `completed_at`).
2. **MCP unavailable mid-task** — tools not listed, `HTTP 401`/`UNAUTHORIZED`, `"This connector requires authentication"`, `"Tool not found"`, or tools that worked earlier vanishing. **Do not stop, and do not call Todoist MCP via the Anthropic API.** Note the MCP needs re-auth (tell Almog to run `/mcp` → todoist, then restart Claude Code to reload tools), but meanwhile proceed on the token API so the task still gets done.

Token API specifics:
- Token: `~/.config/todoist/api_token` (40-char bearer, chmod 600 — never echo it).
- Endpoint: **`https://api.todoist.com/api/v1`** — the only live API. **Never touch `rest/v2` or `sync/v9`; both were shut down early 2026.** Don't rediscover this by trying a dead endpoint first.
- Task CRUD is the REST-style `…/api/v1/tasks`; batch/ordering/completed-task ops go through `…/api/v1/sync` with a `commands` array.
- **Due-date field name is `date`, not `dueDate`.** On the raw API a task's due is the object `"due": {"date": "YYYY-MM-DD", ...}` (and the Sync `item_update` arg is likewise `"due": {"date": …}`). There is no `dueDate` field anywhere — don't guess it and eat a retry.
- Full how-to (backdating completions, moving completed tasks, gotchas) is in memory: `~/.claude/memory/reference-todoist-direct-api.md`.

All the guardrails below (every task has a date, priorities as strings, recurrence rules, etc.) apply identically whichever path you use. Never silently retry a failing call more than once.

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

## Moving / re-dating COMPLETED tasks (Sync API — the MCP & UI cannot)

The MCP and the Todoist UI **cannot move a completed ("filled") task** — you must uncomplete → move → recomplete, which **clobbers `completed_at` to now**. The raw Sync API does not have this limitation. Token: `~/.config/todoist/api_token` (chmod 600, never echo it). Endpoint: `https://api.todoist.com/api/v1/sync`. Verified June 2026.

- **Move a completed task (date preserved):** `item_move` works directly on a completed task and keeps `checked` + `completed_at` **unchanged**. This is the clean way to move filled tasks between projects/sections — no uncomplete needed.
  ```bash
  TOKEN=$(cat ~/.config/todoist/api_token)
  curl -s https://api.todoist.com/api/v1/sync -H "Authorization: Bearer $TOKEN" -d sync_token='*' \
    --data-urlencode commands='[{"type":"item_move","uuid":"<uuid>","args":{"id":"<taskId>","project_id":"<projId-or-inbox-id>"}}]'
  ```
  Only ONE of `project_id` / `section_id` / `parent_id` per `item_move`. Inbox is a real project — get its id from `GET /projects` (`is_inbox_project: true`). Moving to a section/project detaches a subtask to top-level (you cannot null `parent_id` directly).

- **Backdate a completion date:** if a date already got clobbered (or you must set a custom one), use `item_complete` with `date_completed` — but you must **reopen first, then complete**; `item_complete` on an already-completed task is a no-op for the date.
  ```bash
  commands='[{"type":"item_uncomplete","uuid":"<u1>","args":{"id":"<id>"}},
             {"type":"item_complete","uuid":"<u2>","args":{"id":"<id>","date_completed":"2024-04-11T20:37:28.844000Z"}}]'
  ```
  Prefer `item_move` and never clobber in the first place. Reopening a **subtask auto-reopens its parent** — re-complete the parent after.

- **Enumerating completed tasks is capped at 3-month windows.** `GET /tasks/completed/by_completion_date?since=…&until=…&project_id=…` (and the MCP `find-completed-tasks`) reject ranges > ~92 days. To get ALL completed tasks in a project, **loop every quarter** and paginate via `next_cursor` — a single window silently misses older tasks (this caused a real miss).

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
