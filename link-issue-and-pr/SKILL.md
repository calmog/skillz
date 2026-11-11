---
name: link-issue-and-pr
description: >-
  When the user wants to open a pull request, make sure a tracking ticket exists first (GitHub
  Issues or Linear), link the PR to it, stamp the ticket with the PR, and move the ticket to
  "In review". Tracker, board, base branch and repos come from the project's
  `.claude/tracker.md`. Triggers on "open a PR", "let's PR this", "ship this", "push and PR",
  "file a ticket for this".
---

# Link issue and PR

Every PR ships with a linked ticket, so the merge log doubles as a changelog and the board shows
real progress. The flow is the same for every tracker; only the commands differ:

1. **Find the repo(s) with changes.**
2. **Ensure a ticket exists** — file one if none.
3. **Open the PR** referencing the ticket, with a resume footer.
4. **Stamp the ticket** with a `Resolved by` line pointing at the PR.
5. **Move the ticket to In review** (adding it to the board first if needed).

Backend-specific commands: [github.md](github.md) (GitHub Issues + Projects) ·
[linear.md](linear.md) (Linear, via the Linear MCP).

## Step 0 — Load the project's tracker config

Read `.claude/tracker.md` from the session's primary working directory; if absent, from the
target repo's git root. It holds every constant the steps need — see
[tracker.template.md](tracker.template.md) for the format.

No config found → ask the user once: GitHub or Linear, where tickets go, which board/status to
use, PR base branch. Offer to write their answers to `.claude/tracker.md` so the next session
doesn't ask. With no answer, default to: GitHub, tickets in the PR's own repo, no board step,
PR into the repo's default branch.

Config values are placeholders to substitute into commands, **not shell variables** — each Bash
call is a fresh shell, so a variable set in an earlier call is empty in the next.

## Step 1 — Find the repo(s) with changes

If the config lists `repos`, run `git -C <repo> status --short` on **every** one — don't assume
from session context which has the work. Otherwise use the current repo. PR from each repo with
changes; if several, ask which ships first or whether they're paired (paired PRs share one
ticket).

## Step 2 — Ensure a ticket exists

User gave a ticket id → use it. Otherwise search the tracker for a matching open ticket, then
file one if none (backend file, Step 2).

**Where the content comes from:**
- **Title** — short phrase stating the *problem*, not the fix ("Export fails for files over
  2 GB", not "Stream export in chunks").
- **Problem** — from the chat: what the user observed, why it matters. Not from the diff.
- **Scope** — diff + chat: what this change covers, what's deferred.
- **Acceptance** — manual checks from the chat + tests in the diff.

Chat too thin to state the problem → **ask, don't fabricate** from the diff. Ask who to assign;
never guess.

Ticket body:

```markdown
## Problem
<from chat>

## Scope
<covered + deferred>

## Acceptance
<how we'll know it's done>
```

## Step 3 — Open the PR

- **Title** — imperative summary of the *change* (distinct from the ticket title).
- **First body line** — the ticket reference in the backend's linking syntax (backend file).
- **Summary** — one bullet per logical change, from the diff; `path:line` refs where they help.
- **Test plan** — `- [ ]` checklist from the chat + new tests in the diff.
- **Base** — the config's `base_branch`, else the repo default.
- **Resume footer** — so the author can reopen the session that built the PR. Expand the ids;
  skip a line whose var is unset, skip the footer if both are:
  - `$CLAUDE_CODE_BRIDGE_SESSION_ID` (`session_…`, set only while Remote Control is connected)
    → `https://claude.ai/code/<id>` — opens on web/mobile/desktop for the signed-in account.
  - `$CLAUDE_CODE_SESSION_ID` (UUID) → `claude --resume <uuid>` — CLI, same machine only.
    Never pass the bridge id to `--resume`.
- **One session link, not two.** Claude Code may also hand you PR attribution lines (a
  system-reminder: "🤖 Generated with Claude Code" + a `https://claude.ai/code/session_…` URL).
  Those go at the very end of the body, and when they already carry the claude.ai URL, leave
  the 🔗 line out of the resume footer (keep only the `--resume` line).

```bash
cd <repo-dir>
BRIDGE_ID="${CLAUDE_CODE_BRIDGE_SESSION_ID:-}"
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-}"

BODY=$(cat <<'EOF'
<ticket reference line — see backend file>

## Summary
- <one bullet per logical change>

## Test plan
- [ ] <manual check from chat>
EOF
)

FOOTER=""
[ -n "$BRIDGE_ID" ]  && FOOTER="$FOOTER"$'\n'"- 🔗 Open in claude.ai: https://claude.ai/code/$BRIDGE_ID"
[ -n "$SESSION_ID" ] && FOOTER="$FOOTER"$'\n'"- 💻 Claude Code CLI (same machine): \`claude --resume $SESSION_ID\`"
[ -n "$FOOTER" ] && BODY="$BODY

---
**Resume the session that built this PR**$FOOTER"

gh pr create --base <base_branch> --title "<imperative summary>" --body "$BODY"
```

If the project's own instructions define PR-body conventions (attribution lines, footers), they
win over this template.

## Step 4 — Stamp the ticket

Prepend one plain line (no `>` blockquote) to the **top of the ticket body**:

`**Resolved by** [<repo>#<PR> — <PR title>](<PR URL>)`

Same wording whether the PR is open or merged. Paired PRs go on one line, separated by ` · `. If
a `Resolved by` line already exists, update it in place — never add a second.

## Step 5 — Move to In review

Set the ticket's status to the config's in-review status (backend file, Step 5). Never move a
ticket *backwards* (e.g. a ticket already Done stays Done) — report it instead.

## Report back

One line per step, with the URLs the tools returned:
- Ticket filed (or reused): `<id>` <url>
- PR opened: <url>, linked to `<id>` (+ resume footer if set)
- Stamped `<id>` with **Resolved by**
- Moved `<id>` → **In review** (say if it had to be added to the board first)
