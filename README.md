# skillz

A personal Claude Code skills library.

## Available Skills

| Skill | Description |
|-------|-------------|
| **ateam-apply** | Apply to freelance missions on A.Team (platform.a.team) — scans recommended missions, evaluates fit, fills and submits applications |
| **web-browse** | Strategic guide for browser automation with playwright-cli — token-efficient patterns, React form filling, account-ban-risk rules, Chrome extension fallback |
| **playwright-cli** | Full playwright-cli command reference — navigation, clicking, keyboard, mouse, tabs, storage, network mocking, DevTools, and React-specific gotchas |
| **usage-guard** | Calibrate Claude Code's token usage guard — syncs the window limit from `/usage` output so the PreToolUse hook fires accurately |
| **linkedin-profile-optimizer** | Optimize LinkedIn profiles for tech leadership roles — headlines, About sections, experience entries, and CTO-to-IC/freelance narrative strategy |

## Installation

### Install a single skill

```bash
cp -r skillz/skills/SKILL_NAME ~/.claude/skills/
```

Or without cloning the repo:

```bash
mkdir -p ~/.claude/skills/SKILL_NAME && curl -L https://raw.githubusercontent.com/calmog/skillz/main/skills/SKILL_NAME/SKILL.md -o ~/.claude/skills/SKILL_NAME/SKILL.md
```

### Install all skills

```bash
git clone https://github.com/calmog/skillz.git
cp -r skillz/skills/* ~/.claude/skills/
```

Restart Claude Code after installing.

## License

MIT
