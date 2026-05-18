# skillz

A personal Claude Code skills library.

## Available Skills

| Skill | Description |
|-------|-------------|
| **ateam-apply** | Apply to freelance missions on A.Team (platform.a.team). Scans recommended missions, evaluates fit, fills and submits applications. |
| **web-browse** | Browser automation with playwright-cli. Covers token-efficient patterns, React form filling, account-ban-risk rules and Chrome extension fallback. |
| **playwright-cli** | playwright-cli command reference covering navigation, clicking, keyboard, mouse, tabs, storage, network mocking, DevTools and React-specific gotchas. |
| **usage-guard** | Calibrate Claude Code's token usage guard. Syncs the window limit from `/usage` output so the PreToolUse hook fires accurately. |
| **linkedin-profile-optimizer** | Optimize LinkedIn profiles for tech leadership roles. Covers headlines, About sections, experience entries and common mistakes. |

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
