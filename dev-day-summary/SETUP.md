# dev-day-summary — setup

One command, ~2 minutes. It asks for your details and writes the config for you —
**you never edit a config file by hand.**

```bash
bash <skill-dir>/scripts/setup.sh
```

Re-run any time to change anything (it backs up the previous config).

## What it asks

| Step | It asks / does | Required? |
|---|---|---|
| **Identity** | Your name + timezone (pre-filled from git config / system) | — |
| **GitHub** | Confirms `gh` is logged in (offers to run `gh auth login`); asks your git author and local repo roots | ✅ required |

It writes `~/.config/dev-day-summary/config.json` and offers a test pull. That's the
whole setup.

## Prerequisites

- **`gh`** — [GitHub CLI](https://cli.github.com) (`brew install gh`, or your package
  manager). The only hard requirement. Log in with `gh auth login` and grant the
  `repo` + `read:org` scopes so it can see PRs/issues across your orgs.
- **`python3`** — ships with macOS / most Linux.

## Meetings + sent mail (optional, one-time enable)

These are pulled by **Claude's connectors** at report time, not by this skill — so
there's nothing to install or authenticate here. **Google Calendar** and **Gmail** are
official Claude connectors: enable each once at **claude.ai → Settings → Connectors**
(read-only). Because these two can't authenticate locally from Claude Code, claude.ai is
the enable point — once connected there, they appear in Claude Code automatically (check
`/mcp`), and today's meetings + sent mail then show up in the summary.

Skip them and the summary is built from commits + PRs + issues + Claude sessions — a
complete dev day on its own.

## Then

Ask Claude to **"summarize my dev day"** — or run the pull directly:

```bash
bash <skill-dir>/scripts/dev-day-pull.sh
```

Keep your config elsewhere? Point both scripts at it with `DEV_DAY_CONFIG=/path/to.json`.
