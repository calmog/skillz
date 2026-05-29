---
name: todoist
author: calmog
description: "Manage Todoist — create, update, complete, and organize tasks, projects, sections, and reminders, including rescheduling. Consult before any Todoist action. Use when the user mentions Todoist or a to-do list, asks to add/track a task or set a reminder, or wants to manage projects/sections or reschedule items."
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

- Remove due date: `update-tasks` with `dueString: "remove"`
- Remove deadline: `update-tasks` with `deadlineDate: "remove"`
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
