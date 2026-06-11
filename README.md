# skillz

A personal Claude Code skills library.

## Available Skills

| Skill | Description |
|-------|-------------|
| **ateam-apply** | When you're ready to work your A.Team mission queue, this handles the full loop. Scans what's live, filters by your criteria, opens each mission and fills the application while you review and approve. |
| **web-browse** | When Claude needs to click, scroll, fill a form or scrape a page, this guides it to do that without burning tokens on screenshots. Also covers which sites will ban your account if automated and what the right fallback is for each. |
| **playwright-cli** | The command reference for playwright-cli. When you're building or debugging browser automation and need to remember how to handle cookies, intercept network requests or trigger React state changes, this is the lookup. |
| **usage-guard** | When you're running a long task and don't want Claude to freeze mid-work when it hits the token limit, this skill syncs the usage guard so Claude pauses before the limit and automatically reschedules to pick up where it left off when the window renews. |
| **linkedin-profile-optimizer** | When your LinkedIn reads like a CV paste job and isn't pulling recruiter attention, this walks through every section with concrete guidance on what to lead with, what to cut and how to make the profile tell a story instead of listing responsibilities. |
| **excalidraw-board** | When you want a diagram or board you can actually open and edit instead of a flat image, this builds a real Excalidraw file from a short Python script (boxes, arrows, wrapped text) and can render it to PNG for quick sharing. Good for architecture sketches, flows and interview boards. |
| **html-to-pdf** | When you need a PDF that looks hand-made and holds a hard page limit, this renders any HTML through real headless Chrome so full CSS, web fonts, images and Hebrew/RTL all come out right, then reads the page count back so you know before you send. Built because Chrome's own print-to-pdf hangs on Mac. |
| **todoist** | When you want Claude to add, reschedule or organize Todoist tasks, projects and reminders without mangling a recurring schedule or dropping a due date, this is the playbook it checks first. |
| **config-authoring** | When you're writing or editing anything Claude reads as instructions (a CLAUDE.md, a memory file, a SKILL.md, a guardrail doc), this is the standards and pre-flight checklist that keeps them clear and consistent. |

## Installation

### Install a single skill

```bash
cp -r skillz/SKILL_NAME ~/.claude/skills/
```

Or without cloning the repo:

```bash
mkdir -p ~/.claude/skills/SKILL_NAME && curl -L https://raw.githubusercontent.com/calmog/skillz/main/SKILL_NAME/SKILL.md -o ~/.claude/skills/SKILL_NAME/SKILL.md
```

### Install all skills

```bash
git clone https://github.com/calmog/skillz.git
cp -r skillz/* ~/.claude/skills/
```

Restart Claude Code after installing.

## License

MIT
