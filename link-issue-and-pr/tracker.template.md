# Tracker config — copy to `<project>/.claude/tracker.md`

The `link-issue-and-pr` skill reads this file. Keep one block; delete the backend you don't use.
Free-text notes below the block are read too — put project quirks there.

```yaml
backend: github            # github | linear
base_branch: main          # PR base; omit = repo default branch
repos:                     # repos to scan for changes; omit = current repo only
  - ~/code/backend
  - ~/code/frontend

# --- github ---
tracker: my-org/my-tracker-repo     # where new tickets are filed
project:                            # omit to skip board steps
  owner: my-org
  number: 5
  id: PVT_xxx
  status_field: PVTSSF_xxx
  statuses: { backlog: xxxxxxxx, in_review: xxxxxxxx, done: xxxxxxxx }

# --- linear ---
team: ENG                           # team key or name
project: Platform                   # optional
labels: []                          # optional, added to new tickets
statuses: { backlog: Backlog, in_review: In Review }
```

## Notes
- <quirks: e.g. "PRs target develop, so GitHub closing keywords are inert — rely on the board.">
