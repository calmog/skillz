#!/usr/bin/env bash
# setup.sh — one-time interactive setup for dev-day-summary.
# Asks only for your own details (name, git author, repos) and WRITES
# ~/.config/dev-day-summary/config.json for you — no hand-editing. Re-runnable.
# Meetings + sent mail are pulled by Claude's connectors at report time, so there is
# NOTHING to authenticate here beyond the GitHub CLI.
set -uo pipefail

CONFIG="${DEV_DAY_CONFIG:-$HOME/.config/dev-day-summary/config.json}"
CONFIG_DIR="$(dirname "$CONFIG")"
INTERACTIVE=0; [ -t 0 ] && INTERACTIVE=1

c_b() { printf '\033[1m%s\033[0m' "$1"; }
say() { printf '%s\n' "$*"; }
hr() { printf '%s\n' "────────────────────────────────────────────────────"; }
ask() {  # ask <var> <prompt> <default>  — empty input keeps the default
  local __var="$1" __prompt="$2" __def="${3:-}" __in=""
  if [[ -n "$__def" ]]; then printf '%s [%s]: ' "$__prompt" "$__def"; else printf '%s: ' "$__prompt"; fi
  IFS= read -r __in || true; [[ -z "$__in" ]] && __in="$__def"
  printf -v "$__var" '%s' "$__in"
}
yes_no() {  # yes_no <prompt> <default y|n>
  local p="$1" d="${2:-n}" a=""
  printf '%s %s ' "$p" "$([ "$d" = y ] && echo '[Y/n]' || echo '[y/N]')"
  IFS= read -r a || true; a="${a:-$d}"; [[ "$a" =~ ^[Yy] ]]
}

hr; say "$(c_b 'dev-day-summary · one-time setup')"
say "Writes $CONFIG for you. Nothing is sent anywhere."
hr

DEF_NAME="$(git config user.name 2>/dev/null || echo)"
DEF_GITAUTHOR="$(git config user.email 2>/dev/null || echo)"
DEF_TZ="$( (readlink /etc/localtime 2>/dev/null | sed -E 's#.*/zoneinfo/##') )"; [[ -z "$DEF_TZ" ]] && DEF_TZ="UTC"
ask NAME "Your name (for the summary header)" "$DEF_NAME"
ask TZ   "Timezone (IANA, e.g. Europe/London)" "$DEF_TZ"

say; say "$(c_b 'GitHub') — commits, PRs, issues/tickets"
if ! command -v gh >/dev/null 2>&1; then
  say "  ⚠ GitHub CLI not found. Install it (e.g. 'brew install gh'), then re-run this setup."
elif ! gh auth status >/dev/null 2>&1; then
  if [[ $INTERACTIVE -eq 1 ]] && yes_no "  gh is not logged in. Run 'gh auth login' now?" y; then
    gh auth login || say "  (login didn't complete — run 'gh auth login' later)"
  else
    say "  ↪ Run 'gh auth login' before your first summary (grant 'repo' + 'read:org')."
  fi
else
  say "  ✓ gh logged in as $(gh api user --jq .login 2>/dev/null)"
fi
ask GIT_AUTHOR  "  Your git commit author (matches 'git log --author=')" "$DEF_GITAUTHOR"
ask REPO_ROOTS  "  Local repo roots (space-separated globs)" "~/Dev/*"
# (no issue-repo prompt: PRs/issues are found org-wide via 'gh search --author/--assignee=@me')

say; say "$(c_b 'Meetings + mail')"
say "  Pulled at report time via Claude's Google Calendar / Gmail connectors."
say "  Enable them ONCE at claude.ai → Settings → Connectors (they then sync into"
say "  Claude Code automatically). Nothing to authenticate here."

mkdir -p "$CONFIG_DIR"
[[ -f "$CONFIG" ]] && cp "$CONFIG" "$CONFIG.bak.$(date +%s)" 2>/dev/null && say "" && say "  (backed up existing config)"
NAME="$NAME" TZ="$TZ" GIT_AUTHOR="$GIT_AUTHOR" REPO_ROOTS="$REPO_ROOTS" \
python3 - "$CONFIG" <<'PY'
import json,os,sys
def arr_ws(s): return [x for x in (s or "").split() if x]
cfg={
  "name": os.environ.get("NAME") or "you",
  "timezone": os.environ.get("TZ") or "UTC",
  "git": {"author": os.environ.get("GIT_AUTHOR",""), "repo_roots": arr_ws(os.environ.get("REPO_ROOTS"))},
}
json.dump(cfg, open(sys.argv[1],"w"), indent=2, ensure_ascii=False)
open(sys.argv[1],"a").write("\n")
PY

say; hr; say "$(c_b '✓ Setup complete') → $CONFIG"
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ $INTERACTIVE -eq 1 ]] && yes_no "Run a test pull now?" y; then
  say; bash "$SELF_DIR/dev-day-pull.sh"
else
  say "Run it any time:  bash $SELF_DIR/dev-day-pull.sh   (or ask Claude to \"summarize my dev day\")"
fi
