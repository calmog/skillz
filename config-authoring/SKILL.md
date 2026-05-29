---
name: config-authoring
description: >
  Standards and pre-flight checklist for writing or editing any Claude-facing
  instruction file — CLAUDE.md (global ~/.claude or any project), auto-memory
  (MEMORY.md index + topic files), SKILL.md skills, and guardrail/reference .md
  docs Claude loads as instructions, anywhere on disk. Use before creating or
  editing any of these, or when deciding where a new rule belongs (CLAUDE.md vs
  hook vs skill vs memory). Does NOT apply to ordinary content markdown produced
  as a deliverable (READMEs, drafts, reports).
---

# Authoring Claude-facing instruction files

The one principle behind every rule here: **CLAUDE.md and the MEMORY.md index are
loaded into context on EVERY session. Every line is paid for every time, used or
not.** So the job is always: put content at the *cheapest tier that still works*,
and keep the always-on tiers ruthlessly small.

## 1. Placement — decide the tier BEFORE writing

Ask "what kind of thing is this?" and route it:

| The content is… | Put it in | Why |
|---|---|---|
| An always-on behavioral rule (applies to most/every response) | **CLAUDE.md**, compressed | Must be in context always; that's what CLAUDE.md is for |
| A hard "always/never" with a deterministic trigger event (a tool call, a file write) | **A hook** (settings.json → use the `update-config` skill) | Prose only *advises*; a hook *enforces*. A miss here is expensive |
| A multi-step procedure or domain knowledge that's relevant only sometimes | **A skill** (SKILL.md) | Loads on demand by description match; costs ~nothing until triggered |
| A learned fact, correction, or project state | **Auto-memory** (topic file + MEMORY.md line) | Persists across sessions; topic file is lazy-loaded |
| A long reference used only in specific tasks | **A standalone .md**, pointed to *lazily* from CLAUDE.md | Keeps the bytes out of every session |

The reliability ladder (know which you're choosing): **prose** = Claude must
remember it every time · **trigger/skill** = Claude must first *recognize* the
situation, then load it · **hook** = the harness enforces it deterministically.
The more expensive a miss, the further down the ladder it belongs.

## 2. Editing CLAUDE.md (global or project)

- **Read it first.** Then classify the new content per §1 — most additions do NOT belong in CLAUDE.md.
- **Tier it:** hard guardrails → behavioral defaults → project bookkeeping → load-on-demand pointers. Keep the global file lean (it currently sits ~45 lines — treat large jumps as a smell).
- **Lazy pointers, never `@import`.** Write `When X → read ~/.claude/foo.md`. `@import` expands the file eagerly at launch and defeats the savings. Prose pointers cost nothing until the trigger fires.
- **Pruning test for every line:** "Would removing this cause a concrete, specific mistake?" If no, cut it. Delete personality rules ("be a senior engineer"), self-evident practices (Claude already knows the language), and stale architecture notes.
- **No duplication.** A rule lives in exactly one place. If it's in a hook or a memory file, CLAUDE.md gets at most a one-line pointer, not a copy.
- **When adding, consider what to cut.** Always-on budget is zero-sum.

## 3. Editing auto-memory

- **MEMORY.md is an index, not a store.** One line per memory: `- [Title](file.md) — hook`. Never put memory content in MEMORY.md itself.
- **One fact per topic file**, with frontmatter: `name` (kebab-case slug), `description` (used for recall relevance), `metadata.type` = `user | feedback | project | reference`. For `feedback`/`project`, follow the fact with **Why:** and **How to apply:** lines.
- **Check for an existing file first** — update it rather than create a duplicate. Delete memories that turn out wrong.
- **Link related memories** with `[[other-name]]`. **Convert relative dates to absolute.**
- Don't save what the repo/git/CLAUDE.md already records, or what only matters to the current conversation.

## 4. Authoring a SKILL.md

- **Lives at `~/.claude/skills/<name>/SKILL.md`** (uppercase `SKILL.md`).
- **The description is the trigger** — skills load by description match, so a vague description = a skill that never fires. Pack it with the concrete phrases/contexts that should activate it, and state what it does NOT cover.
- **One skill = one capability.** Before creating, check existing skills for overlap — skill sprawl and near-duplicates are an anti-pattern.
- **Keep SKILL.md focused;** push heavy detail, long references, and scripts into sibling files the skill points to, so the listing stays cheap.

## 5. Hooks vs prose (the rule that catches the expensive misses)

If a rule contains "always" or "never" AND there's a concrete event that should
trigger it (a specific tool call, a file write/edit, session start), it almost
certainly belongs in a **hook**, not a sentence Claude has to remember. Use the
`update-config` skill to add it. Keep a one-line pointer in CLAUDE.md only if the
prose also shapes the *happy-path workflow* or covers tools the hook's matcher
can't catch — otherwise the hook stands alone.

## 6. Pre-edit checklist (run every time)

1. Read the target file.
2. Classify the content (§1) → pick the cheapest correct tier. Default assumption: it does NOT go in CLAUDE.md.
3. Grep for duplication across CLAUDE.md / memory / skills / hooks before adding.
4. If it's enforce-able and a miss is costly → make it a hook instead of (or alongside) prose.
5. Write it lazily where possible (pointer, skill, topic file) — eager only when always-needed.
6. After editing: re-check size and that nothing eager crept in that should be lazy. If you added to an always-on file, note what you removed to offset it.
