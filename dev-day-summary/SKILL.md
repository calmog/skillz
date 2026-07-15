---
name: dev-day-summary
description: "Reconstructs a developer's work day into an honest summary — commits, PRs, issues/tickets (via the GitHub CLI), Claude Code sessions, and optionally today's meetings + sent mail (via Claude's Calendar/Gmail connectors, if present). Use when someone asks to summarize/review their dev day, do a daily standup or retro, or 'what did I ship today'. Not a to-do list — a factual record of output."
version: "1.0.0"
tags:
  - productivity
  - retro
  - standup
  - github
  - daily-review
setup: "./SETUP.md"
setup_complete: false
---

# Dev Day Summary — an honest record of what you shipped

Reconstruct what a developer **actually did today** — not a plan, a factual record of
output and where time went. Good for a daily standup, a personal retro, or counting
real wins. **It must be honest: an inflated win is worse than no win.**

The deterministic core (commits, PRs, issues, Claude sessions) needs only the GitHub
CLI — no OAuth, no servers. Meetings and sent mail are optional enrichment pulled from
Claude's connectors when available. Everything user-specific lives in
`~/.config/dev-day-summary/config.json` (written by `scripts/setup.sh`); nothing is
hardcoded.

## Step 0 — SETUP GATE (the `setup_complete` phase — always first)

This skill ships with `setup_complete: false` in its frontmatter. **If it is still
`false` (or `~/.config/dev-day-summary/config.json` is missing), run the setup phase
below before anything else, then flip the flag.** If it is already `true` and the config
exists, skip straight to Step 1.

Setup phase — do it *conversationally* (you have no interactive TTY, so do NOT run
`scripts/setup.sh`; that's the plain-terminal path). Keep it to one short exchange:

1. Detect defaults in one call: name + email from `~/.gitconfig` (the email is the commit
   author to match), system timezone (`realpath /etc/localtime` → strip to the zone), and
   `gh auth status`.
2. Show those defaults and ask the user to confirm/correct just two things: their **name**
   and their **local repo roots** (globs, e.g. `~/Dev/*` `~/work/*`). Everything else is
   auto-detected.
3. Write `~/.config/dev-day-summary/config.json` (via the Write tool):
   `{"name","timezone","git":{"author","repo_roots":[...]}}`. If `gh` isn't logged in, tell
   them to run `gh auth login` (grant `repo` + `read:org`).
4. Say once that meetings + sent mail are optional and come from the Google Calendar /
   Gmail connectors (enable at claude.ai → Settings → Connectors).
5. **Flip `setup_complete: false` → `true` in this SKILL.md** (Edit tool), so future runs
   skip setup. Then continue to Step 1 in the same turn — don't make them re-invoke.

## Step 1 — the review window

The pull states the real local time and the window (today 00:00 → now). State it back
("Summarizing 15.07, 00:00–16:40"). Can run any hour; if run after midnight for
"yesterday", reconstruct that date instead.

## The honesty contract — MEASURED vs INFERRED (read before reporting any number)

Two tiers, never blurred:

- **MEASURED (state as plain fact):** commit timestamps; PR/issue open+close times;
  meeting durations from calendar `start→end`; mail send times.
- **INFERRED (always labelled `~est` / "rough"):** **how long a task took.** There is no
  per-task time tracking — any "where the time went" split is a *reconstruction* from
  commit/PR clustering and surrounding meetings. Tag every such number `~est`. If you
  can't estimate honestly, write "unknown".

Also: **counting wins ≠ inflating them.** No "great progress!" framing, no padding.
And a meeting on the calendar is *scheduled*, not proof of *attended* — corroborate
(a commit, a message, their say-so) or label it "on-calendar".

## Data sources

**Deterministic core — one script call:**
`bash <skill-dir>/scripts/dev-day-pull.sh` pulls, in parallel:

1. **TIME + REVIEW WINDOW** — real local time + the window, stated back.
2. **GITHUB** — the convergence point. Local commits today (config author + repo roots)
   **+** PRs opened/merged today **+** issues opened/closed today **+** issues assigned
   to the user and touched today — all via `gh`, **org-wide** (`--author`/`--assignee=@me`,
   no repo list to configure). **De-dupe: a merged PR and its commits = one win.**
3. **CLAUDE SESSIONS** — transcripts touched today (if the user uses Claude Code). The
   script LISTS them; you summarize each as one line: what shipped. An idle session is
   not a win. **Skip `subagents/` entries** — those are tool-call transcripts, not work.

**Optional enrichment — via Claude's connectors, if present in this session:**

4. **MEETINGS** — if a Google Calendar connector/MCP is available, fetch today's
   events, each with its MEASURED span. No connector → omit meetings.
5. **SENT MAIL** — if a Gmail connector/MCP is available, fetch `in:sent` for today
   (handled correspondence, not chatter). No connector → omit.

Do NOT set up bespoke servers for 4–5. Google Calendar and Gmail are official Claude
connectors (GA): the user enables each **once** at claude.ai → Settings → Connectors,
after which they sync into Claude Code automatically (these two can't OAuth locally from
Claude Code, so claude.ai is the enable point). If a connector isn't present, just tell
the user how to turn it on — and a commits+PRs+issues+sessions summary is a complete dev
day on its own without them.

Any source printing a `*_ERROR` line means it broke — an empty payload from a broken
source is not a quiet day. Check for the error before concluding "nothing happened".

## Build the timeline, then the summary

1. Merge everything onto one chronological timeline (working notes) — commits, PRs,
   issues, meetings, sends, session outcomes, each with its real timestamp.
2. Reconstruct "where time went": meetings = measured; gaps attributed to the work
   whose commits/PRs land in them, labelled `~est`. Leave honest gaps unaccounted.
3. Fill the template below, then run the PRE-REPORT CHECK.

## The summary — MANDATORY fill-in template (do NOT freestyle)

Fill THIS skeleton, same shape every run. Scannable `label: content` lines.
**Empty section → omit it entirely.** Every duration tagged: plain time = MEASURED,
inferred span carries `~est`. Do NOT re-list the same items as separate timeline + wins
+ tally — render only this consolidated shape.

```
📓 <real local time> · <name>'s dev day · <DD.MM>, <HH:MM>–<HH:MM>

📌 HONEST READ — 1–2 lines: where real progress lived vs what fragmented the day

🎫 GITHUB — commits / PRs / issues, de-duped (a merged PR + its commits = one line)
- <repo#N — title> <(opened | merged | closed)> (<HH:MM>)

🏆 KEY ACCOMPLISHMENTS — only what accumulated to real progress
- <the win — what shipped> (<HH:MM> or ~est)

⏳ WHERE TIME WENT — measured tagged, spans ~est; leave gaps Unaccounted
- <Xh Ym measured> · <meeting> — <…>          ← only if a calendar connector was used
- <~Xh est> · <what — the work> — <commit/PR timestamps>
- <~Xh> · Unaccounted

📧 CORRESPONDENCE — only if a mail connector was used and it was real handled work
- <to — subject> (<HH:MM>)

🧾 TALLY — bare scoreboard, one line, no adjectives
- <K> commits · <P> PRs (<opened>/<merged>) · <I> issues · <S> sessions[ · <M> meetings]
```

The honest verdict lives in **📌 HONEST READ at the top** (lead with the conclusion) —
so do NOT append a closing "biggest win" line. `KEY ACCOMPLISHMENTS` already ranks the
wins biggest-first; `HONEST READ` already judges the day. Three slots restating the same
win (read + accomplishments + a closer) is the most common failure — the top line is the
verdict, the sections are the detail, nothing repeats.

**PRE-REPORT CHECK — run silently; every box true before sending:**
- [ ] Every duration tagged MEASURED or `~est` — no inferred number presented as fact
- [ ] GitHub de-duped — a merged PR's commits counted once; author is the user's
- [ ] Sessions listed only where a concrete outcome shipped; `subagents/` skipped
- [ ] Meetings/mail included ONLY if a connector actually returned them; else omitted
- [ ] No win stated twice — HONEST READ, KEY ACCOMPLISHMENTS, and (absent) closer don't restate the same item
- [ ] Empty sections omitted · no "nothing to report" filler · tally is a plain count

## First run / changing setup

`bash <skill-dir>/scripts/setup.sh` — interactive wizard, writes the config; users never
hand-edit it. Re-run any time to change name, git author, or repo roots.
