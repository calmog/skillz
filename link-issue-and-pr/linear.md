# Linear backend (Linear MCP)

Uses the Linear MCP tools (`list_issues`, `save_issue`, `get_issue`, `list_issue_statuses`).
They accept human-readable refs — team key/name, `ENG-123`, user email or `"me"` — so no id
lookups are needed. Statuses are per-team: if the config's status names don't resolve, run
`list_issue_statuses` for the team and ask which to use.

How linking works, per [Linear's GitHub docs](https://linear.app/docs/github) — only when the
workspace has Linear's GitHub integration; without it nothing links and Steps 4–5 do it by hand:
- A PR links when the issue ID is in the **branch name**, the **PR title**, or the **PR
  description** with a magic word. Links form when the title/description is saved — to link an
  already-open PR, edit its description.
- **Magic words in PR comments don't link.** On GitHub Enterprise Server, only the PR description
  works.
- Linked PRs show up on the issue automatically (plus a linkback comment, if enabled).
- Default automation: linked issue → **In Progress** when the PR opens, **Done** when it merges.
  Review-requested / ready-to-merge moves exist but only if the team configured them
  (Settings → Team → Workflows & automations).
- Teams can set **target-branch rules** (e.g. merge into `staging` → "In QA"). The docs don't say
  what the default rules do for a PR into a non-default branch — if the config's `base_branch`
  isn't the default, check once on a real PR and record the result in `.claude/tracker.md`.

## Step 2 — File the ticket

1. Dedupe: `list_issues` with `team: <team>`, `query: "<keywords>"`; reuse an open match.
2. Create: `save_issue` with `team`, `title`, `description` (Problem/Scope/Acceptance, real
   newlines), plus `project` / `labels` from the config if set, and `assignee` once the user
   names one. Filed for later → `state: <statuses.backlog>`.
3. Keep the returned identifier (`ENG-123`) and URL.

## Step 3 — Reference line

First body line: `Fixes ENG-123` — a closing word, so the merge triggers the team's merge
automation. When the PR doesn't finish the ticket, use a non-closing word: `Part of ENG-123`
(also `refs`, `contributes to`, `towards`). Closing words: close(s/d), fix(es/ed), resolve(s/d),
complete(s/d), implement(s/ed). `Skip ENG-123` / `Ignore ENG-123` prevents a link.

## Step 4 — Stamp

1. `get_issue` the ticket. If the integration already lists the PR, don't add it again;
   otherwise `save_issue` with `id` + `links: [{url: <PR URL>, title: "<repo>#<PR> — <PR title>"}]`.
2. Banner: `save_issue` with `id` + `patch: [{op: "prepend", text: "**Resolved by** [...](...)\n\n"}]`.
   If a `Resolved by` line exists, use a `replace` op on it instead.

## Step 5 — In review

`get_issue` and read its status. The default automation only sets **In Progress** on PR open, so
unless the team mapped review-requested to the in-review status, set it yourself: `save_issue`
with `id` + `state: <statuses.in_review>`. If it's already in-review or later, leave it — never
move it backwards.
