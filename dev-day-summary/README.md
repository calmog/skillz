# dev-day-summary

An honest summary of your work day, powered by Claude. It reconstructs **what you
actually shipped today** — commits, PRs, issues/tickets (via the GitHub CLI), Claude
Code sessions, and optionally today's meetings + sent mail (via Claude's
Calendar/Gmail connectors, if you have them). Not a to-do list; a factual record of
output — good for a daily standup, a personal retro, or counting real wins.

Config-driven and self-contained: the deterministic core needs only the GitHub CLI —
no OAuth, no servers. Everything user-specific lives in your local
`~/.config/dev-day-summary/config.json`.

## Install

The skill is one folder in the `calmog/skillz` repo. Sparse-checkout just that folder,
then drop it into your Claude Code skills dir. **Prerequisites:** `git` and the GitHub
CLI (`gh`) — plus [`gh auth login`](https://cli.github.com/) with `repo` + `read:org`.

> **Windows note:** the deterministic pull is a bash script, so Claude Code needs the
> Bash tool to run it. On native Windows that means installing
> [Git for Windows](https://git-scm.com/downloads/win) (provides Git Bash) — without it
> Claude Code falls back to the PowerShell tool and the pull won't run. WSL works too.
> The skills folder itself lives at `%USERPROFILE%\.claude\skills\` on native Windows, or
> `~/.claude/skills/` inside your WSL home.

**macOS / Linux** (and Windows via Git Bash / WSL — Claude Code runs bash there):

```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/calmog/skillz.git /tmp/skillz-dds
cd /tmp/skillz-dds && git sparse-checkout set dev-day-summary
mkdir -p ~/.claude/skills && cp -R dev-day-summary ~/.claude/skills/
rm -rf /tmp/skillz-dds
```

**Windows — PowerShell** (skills live under `%USERPROFILE%\.claude\skills\`):

```powershell
git clone --depth 1 --filter=blob:none --sparse https://github.com/calmog/skillz.git $env:TEMP\skillz-dds
cd $env:TEMP\skillz-dds; git sparse-checkout set dev-day-summary
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse -Force dev-day-summary "$env:USERPROFILE\.claude\skills\"
Remove-Item -Recurse -Force $env:TEMP\skillz-dds
```

That's it — no manual config editing. First time you invoke it (below), the skill
detects it's unconfigured and walks you through a one-time setup **conversationally**
(Claude writes `~/.config/dev-day-summary/config.json` for you), then continues. The
`scripts/setup.sh` wizard is only a plain-terminal fallback — you don't need to run it
on any OS.

## Quick start

1. **Use**: ask Claude to *"summarize my dev day"* (or `/dev-day-summary`). On first run
   it auto-configures (name + repo roots — everything else is detected), then runs one
   pull and fills the template in [SKILL.md](SKILL.md).
2. **Reconfigure** any time: `bash scripts/setup.sh`, or just tell Claude your git author
   / repo roots changed. See [SETUP.md](SETUP.md).

## What it pulls

| Source | What | How |
|---|---|---|
| GitHub | commits + PRs opened/merged + issues opened/closed + assigned tickets — **all converge here** | `gh` (required, one deterministic call) |
| Claude sessions | transcripts touched today | local files (optional) |
| Meetings | today's events with measured durations | Claude's Calendar connector, if present |
| Sent mail | correspondence handled today | Claude's Gmail connector, if present |

The first two need no auth beyond `gh`. Meetings + mail come from Claude's official
Google Calendar / Gmail connectors — enable each once at claude.ai → Settings →
Connectors (they then sync into Claude Code automatically); nothing to install. No
connectors → a commits+PRs+issues+sessions summary, which is a complete dev day on its
own.

## Layout

```
SKILL.md                 the playbook (honesty contract, template, PRE-REPORT check)
SETUP.md                 one-time setup
config.example.json      reference only — the setup wizard writes the real config
scripts/
  setup.sh               interactive wizard — writes ~/.config/dev-day-summary/config.json
  dev-day-pull.sh         deterministic pull — git + gh + Claude sessions
```

## Honesty

Measured facts (commit / PR / issue / send / meeting timestamps) are stated plainly.
Anything inferred — how long a task *took*, since there's no per-task tracking — is
tagged `~est`. Counting wins is the point; inflating them defeats it.
