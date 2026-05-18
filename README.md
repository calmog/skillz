# skillz

A personal Claude Code skills library.

## Available Skills

| Skill | Description |
|-------|-------------|
| **ateam-apply** | Apply to freelance missions on A.Team (platform.a.team) — scans recommended missions, evaluates fit, fills and submits applications |

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
