# dev-day-summary

An honest summary of your work day, powered by Claude. It reconstructs **what you
actually shipped today** — commits, PRs, issues/tickets (via the GitHub CLI), Claude
Code sessions, and optionally today's meetings + sent mail (via Claude's
Calendar/Gmail connectors, if you have them). Not a to-do list; a factual record of
output — good for a daily standup, a personal retro, or counting real wins.

Config-driven and self-contained: the deterministic core needs only the GitHub CLI —
no OAuth, no servers. Everything user-specific lives in your local
`~/.config/dev-day-summary/config.json`.

## Quick start

1. **Setup** (once, ~2 min): `bash scripts/setup.sh` — an interactive wizard that asks
   for your details and writes the config (no hand-editing). Only requirement is
   `gh auth login`. See [SETUP.md](SETUP.md).
2. **Use**: ask Claude to *"summarize my dev day"*. It runs one pull and fills the
   template in [SKILL.md](SKILL.md).

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
