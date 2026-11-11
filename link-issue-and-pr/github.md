# GitHub backend (Issues + Projects v2)

Run `gh` from inside the repo's working tree for PR commands. Anything touching a **ticket**
(`gh issue …`, `gh project …`) always passes `--repo <tracker>` explicitly — the tracker is often
a different repo than the one the PR lands in. Board steps need the `project` scope on the token
(`gh auth refresh -s project -h github.com`, once).

Tickets that predate the current tracker may live in another repo: take `owner/repo` from the
ticket's URL instead of `<tracker>`.

## Step 2 — File the ticket

```bash
gh issue list --repo <tracker> --state open --search "<keywords>"   # dedupe first
gh issue create --repo <tracker> --title "<problem statement>" --body "<Problem/Scope/Acceptance>"
```

New tickets go **only** in `<tracker>`, never the repo the fix lands in. If a board is
configured, add it: `gh project item-add <project.number> --owner <project.owner> --url <issue-url>`.
Ticket filed for later (no PR now) → set Status to the config's backlog option with Step 5's
snippet.

## Step 3 — Reference line

`Closes <tracker>#<N>.` — always fully qualified; a bare `#N` resolves to the PR's own repo.

**Caveat:** GitHub only honours closing keywords when the PR targets the repo's **default
branch** ([docs](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)).
On a PR into any other base (e.g. `develop`), `Closes` is inert: no link, no auto-close, and
`closingIssuesReferences` is always empty — don't "fix" that. The line is still worth writing as
a human pointer; the board move in Step 5 is the real progress signal.

## Step 4 — Stamp

```bash
gh issue view <N> --repo <tracker> --json body --jq .body   # read, prepend/replace the line, then:
gh issue edit <N> --repo <tracker> --body "<new body>"
```

## Step 5 — Ensure on board, set In review

Skip if no board is configured. Safe to re-run (`item-add` on an existing item returns its id).

```bash
ISSUE=<N>
REPO_OWNER=<owner of the repo the ISSUE lives in>
REPO_NAME=<that repo>
PROJECT_OWNER=<project.owner>      # the BOARD's owner — doesn't vary per ticket
PROJECT_NUMBER=<project.number>
PROJECT_ID="<project.id>"
STATUS_FIELD="<project.status_field>"
OPT_STATUS="<project.statuses.in_review>"

ITEM_ID=$(gh api graphql -f query='
  query($o:String!,$n:String!,$num:Int!){ repository(owner:$o,name:$n){
    issue(number:$num){ projectItems(first:20){ nodes { id project{ id } } } } } }' \
  -F o="$REPO_OWNER" -F n="$REPO_NAME" -F num="$ISSUE" \
  --jq ".data.repository.issue.projectItems.nodes[] | select(.project.id==\"$PROJECT_ID\") | .id")

if [ -z "$ITEM_ID" ]; then
  ITEM_ID=$(gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" \
    --url "https://github.com/$REPO_OWNER/$REPO_NAME/issues/$ISSUE" --format json --jq .id)
  echo "Added #$ISSUE to the board."
fi

gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD" --single-select-option-id "$OPT_STATUS"
```

Finding the ids for a new config:
`gh project list --owner <owner>` (number) ·
`gh project view <number> --owner <owner> --format json --jq .id` (project id) ·
`gh project field-list <number> --owner <owner> --format json` (Status field id + option ids).
