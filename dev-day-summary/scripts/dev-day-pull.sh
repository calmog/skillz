#!/usr/bin/env bash
# dev-day-pull.sh — deterministic, read-only pull for a developer's day summary.
# ONE call = your day's dev output in one shot, every source in parallel. Covers the
# OAuth-free, universally-available signals: local git commits, GitHub PRs + issues
# (via the gh CLI), and Claude Code sessions. Meetings and sent mail are NOT pulled
# here — those come from Claude's Calendar/Gmail connectors at report time (see
# SKILL.md), so this script needs no OAuth and no bespoke servers, just `gh`.
#
# Everything user-specific (name, git identity, repos) is read from
# ~/.config/dev-day-summary/config.json (written by setup.sh). Nothing is hardcoded.
#
# HONESTY: commit/PR/issue timestamps are MEASURED facts. How long a task *took* is
# NOT tracked or invented here — that stays the model's labelled estimate (~est).
set -uo pipefail

CONFIG="${DEV_DAY_CONFIG:-$HOME/.config/dev-day-summary/config.json}"
if [[ ! -r "$CONFIG" ]]; then
  echo "CONFIG_ERROR: no config at $CONFIG — run scripts/setup.sh (or set DEV_DAY_CONFIG)." >&2
  exit 1
fi

# --- read config once ---
eval "$(python3 - "$CONFIG" <<'PY'
import json,sys
c=json.load(open(sys.argv[1]))
def g(p,d=""):
    cur=c
    for k in p.split("."):
        if isinstance(cur,dict) and k in cur: cur=cur[k]
        else: return d
    return cur
git=g("git",{})
roots=" ".join(git.get("repo_roots",[])) if isinstance(git.get("repo_roots"),list) else ""
print("NAME=%r"%g("name","you"))
print("TZ=%r"%g("timezone","UTC"))
print("GIT_AUTHOR=%r"%git.get("author",""))
print("REPO_ROOTS=%r"%roots)
PY
)"

DAY_START="$(date +%Y-%m-%d) 00:00"
TODAY="$(date +%Y-%m-%d)"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

sec_time() {
  { echo "$(date "+%A %Y-%m-%d %H:%M %Z") · reviewing $NAME's day"
    echo "review window: today $(date +%d.%m) 00:00 → $(date +%H:%M) $TZ (state it back)"
  } > "$TMP/time"
}

sec_github() {
  # Commits + PRs + issues all converge on GitHub. Commits from local repos
  # (config author + roots); PRs/issues via gh (@me = the gh-authed user).
  local out="$TMP/github"
  {
    echo "--- git commits today (${GIT_AUTHOR:-any author}; %h %H:%M %s) ---"
    local found=0 r d log
    for r in $REPO_ROOTS; do
      for d in $(eval echo "$r"); do
        [[ -d "$d/.git" ]] || continue
        log=$(git -C "$d" log --since="$DAY_START" ${GIT_AUTHOR:+--author="$GIT_AUTHOR"} --pretty='  %h %ad %s' --date=format:'%H:%M' 2>/dev/null)
        [[ -n "$log" ]] && { echo "== ${d/#$HOME/~}"; echo "$log"; found=1; }
      done
    done
    [[ $found -eq 0 ]] && echo "  (no commits today by ${GIT_AUTHOR:-configured author} in configured roots)"

    if command -v gh >/dev/null 2>&1; then
      echo "--- PRs (gh; de-dupe a merged PR with its commits above) ---"
      local pro prm io ic
      if pro=$(gh search prs --author=@me --created ">=$TODAY" --limit 20 2>/dev/null); then
        [[ -n "$pro" ]] && { echo "  opened today:"; echo "$pro" | sed 's/^/    /'; }
      else
        echo "  (gh PR search failed — check 'gh auth status')"
      fi
      prm=$(gh search prs --author=@me --merged ">=$TODAY" --limit 20 2>/dev/null); [[ -n "$prm" ]] && { echo "  merged today:"; echo "$prm" | sed 's/^/    /'; }
      echo "--- issues / tickets (gh; org-wide via @me, no repo config) ---"
      local ia
      io=$(gh search issues --author=@me --created ">=$TODAY" --limit 20 2>/dev/null); [[ -n "$io" ]] && { echo "  opened today:"; echo "$io" | sed 's/^/    /'; }
      ic=$(gh search issues --author=@me --closed ">=$TODAY" --limit 20 2>/dev/null); [[ -n "$ic" ]] && { echo "  closed today:"; echo "$ic" | sed 's/^/    /'; }
      ia=$(gh search issues --assignee=@me --updated ">=$TODAY" --state all --limit 20 2>/dev/null); [[ -n "$ia" ]] && { echo "  assigned to me, touched today (de-dupe vs above):"; echo "$ia" | sed 's/^/    /'; }
    else
      echo "  gh not installed — PRs/issues skipped (install GitHub CLI + 'gh auth login')"
    fi
  } > "$out"
}

sec_sessions() {
  local out="$TMP/sessions" base="$HOME/.claude/projects"
  if [[ ! -d "$base" ]]; then echo "(no ~/.claude/projects — not a Claude Code user, or no sessions)" > "$out"; return; fi
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    printf '  %s · %s · %s\n' "$(date -r "$f" "+%H:%M" 2>/dev/null)" "$(basename "$(dirname "$f")")" "$(basename "$f" .jsonl)"
  done < <(find "$base" -name '*.jsonl' -newermt "$DAY_START" 2>/dev/null) | sort > "$TMP/.sess"
  if [[ -s "$TMP/.sess" ]]; then
    { echo "--- transcripts touched today (HH:MM · project · id); summarize outcomes, skip idle ---"; cat "$TMP/.sess"
      echo "  ($(wc -l < "$TMP/.sess" | tr -d ' ') sessions touched)"; } > "$out"
  else echo "(no Claude sessions touched today)" > "$out"; fi
  rm -f "$TMP/.sess"
}

sec_time & sec_github & sec_sessions &
wait

echo "=== TIME + REVIEW WINDOW ==="; cat "$TMP/time"
echo; echo "=== GITHUB (commits + PRs + issues/tickets — all converge; de-dupe when reporting) ==="; cat "$TMP/github"
echo; echo "=== CLAUDE SESSIONS (transcripts touched today — summarize what shipped) ==="; cat "$TMP/sessions"
echo
echo "--- MEETINGS + SENT MAIL are not pulled here ---"
echo "  If a Google Calendar / Gmail connector is available in this Claude session,"
echo "  fetch today's meetings + sent mail via those (see SKILL.md). Otherwise omit them."
