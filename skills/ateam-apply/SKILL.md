---
name: ateam-apply
description: Apply to freelance missions on A.Team (platform.a.team). Use when the user says "apply to A.Team", "check recommended missions", "work through my A.Team queue", "any new missions?", or references platform.a.team.
author: calmog
disable-model-invocation: true
setup: "./SETUP.md"
setup_complete: false
---

# A.Team Freelance Application Manager

> **First time?** If `setup_complete: false` above, check whether `linkedin.pdf` exists in this skill's directory (`~/.claude/skills/ateam-apply/linkedin.pdf`). If it does, read it now, extract the user's work history and stack, ask about their job search preferences, and save everything to `profile.md` in the same directory. Show the output for review before writing the file. Then tell the user to set `setup_complete: true` in `SKILL.md`. If the PDF is not there yet, tell the user to follow `SETUP.md` first.

## Your Profile

!`cat "${CLAUDE_SKILL_DIR}/profile.md" 2>/dev/null || echo "[PROFILE NOT FOUND — follow SETUP.md to generate profile.md before running this skill]"`

---

## Communicating with the user

Refer to the user in second person in all messages. Say "this fits your stack" not "this fits his stack".

## Platform: A.Team

- URL: https://platform.a.team/mission-control/recommended
- The user is logged in — if the session expired, ask them to log in
- Missions are listed as cards; click a card to open its detail page
- Each mission has multiple roles with "Request to join" buttons
- "Show more info" buttons reveal role-specific application guidance — always click these before writing anything

## Mission Evaluation Process

### Step 1 — Scan all recommended missions
Go to https://platform.a.team/mission-control/recommended and scroll through every card. Collect company name, mission title, available roles, and any "Matched on X" tags.

### Step 2 — For each strong or possible fit, open and read
- Every role description (some missions have 20+ roles — scroll past the obvious ones)
- Rate ranges (hourly and monthly)
- Required skills and any gaps flagged by the platform
- Working hours overlap — hard constraint, take it literally
- Location requirements — hard filter, check early
- Team status: actively looking vs. builders already proposed
- The "What We're Building" section — critical for tailoring applications

### Step 3 — Present analysis to the user
For each mission worth discussing:
- Why it'd interest them
- Why they're a fit
- Why they might not be a fit (honest)

### Step 4 — Apply to missions the user approves

### Step 5 — Before submitting, show every Q&A for review

Show the exact question text and your drafted answer for every application field before touching the form:

> **Q: [exact question from platform]**
> [your drafted answer]

Don't fill the form until the user approves. When revising after feedback, show a diff not the full text again — use a fenced `diff` block with `-` for removed and `+` for added, scoped to the clause level.

## Filtering Logic

### Application order rule

> **HIGH-FIT+ACTIVE > LOW-FIT+ACTIVE > HIGH-FIT+PROPOSED > LOW-FIT+PROPOSED**

Sort strictly by these four tiers. Never put a proposed mission ahead of any active mission. Fit only breaks ties inside a tier, never across tiers.

"Low fit" = location conflict, rate below stated minimum, missing required skill with no realistic path, or no honest project that showcases the work.

### Auto-skip (don't surface to the user)
- Pure non-dev roles: Designer, Community Manager, Growth Marketer, pure QA-IC, Data Analyst, Recruiter
- Hard location blocks that conflict with the user's location (from `profile.md`)
- Core stack mismatch where the role is majority-time in a language the user has never touched AND there's no adjacent upside

### Builders already proposed
- Don't skip these — apply if the user otherwise qualifies
- Process all "Actively looking" missions first (sorted by fit), then "Builders proposed" (sorted by fit). Never interleave.

### Present despite concerns (let the user decide)
- Missing 1–2 skills if the domain is strong and the user can ramp
- Tight but workable timezone overlap
- Stack-adjacent roles where the transfer is reasonable

### Watch for
- Roles labeled "Developer" that are actually recruiting or interviewing roles — read the responsibilities, not just the title
- Missions where the team appears staffed but the role still shows open

## Application Process

### Before writing anything
1. If you have a voice or writing-style skill available, load it before drafting any copy. If not, write plainly: no em-dashes, no Oxford commas, no AI-syntax tells ("directly aligns with", "uniquely positioned", dramatic colons), no braggy filler. State facts.
2. Navigate to the mission detail page
3. Click "Show more info" on the specific role
4. Read all guidance: "How to stand out", company questions, "What We're Building"
5. Check rate compatibility and note any gaps to address

### Tune project cards
A.Team guidance: surface only the cards aligned with this role and hide the rest. Pick 2–4 most relevant; fewer and sharper beats showing everything. Confirm the selection with the user before locking it in.

### Match role-card availability
The role card has its own availability / hours-per-week / timezone fields, separate from the global profile. Set them to match what the role expects. Confirm with the user if they diverge from their stated preferences.

### Refine until the banner is fully positive
Never submit on intermediate banners ("needs some work", "should be refined"). Only submit when the banner reads fully green. For each selected project: (a) switch the Role dropdown to the mission's required role when accurate, (b) add the mission's required and preferred skills (12-skill cap — drop a less-relevant skill to make room), (c) verify dates and toggles. Republish, re-check the banner. Iterate until green. Improvements must be honest — never add skills the user doesn't have.

### Application principles
- Lead with outcomes, not responsibilities
- Address skill gaps directly and honestly
- Mirror the company's language from "What We're Building"
- Be calibrated — don't exaggerate skill depth
- Don't underplay genuine product strengths

### Rate strategy
- Stay within the company's stated budget range. Never exceed the ceiling.
- Don't pick the top of the range — it hurts acceptance odds.
- Use clean round numbers ($105/hr, $17,000/mo — not exact math outputs).
- Strong fit: upper-middle of the range. Stretch fit: around the middle.
- Ask the user when the range is below what they'd normally accept — don't guess their floor.
- Always check the "I agree to work at or above the rate entered" checkbox before submitting.

## Applied Missions Tracker

The list of already-applied missions lives in `applied_missions.md` in the current working directory.

**Before scanning:** Read `applied_missions.md` and skip those missions entirely — don't resurface them as candidates.

**After every successful submit:** Append a row: `Date | Company | Mission | Role | Status`. Use `YYYY-MM-DD`. Do it immediately, not later.

**When status changes:** Update the existing row's Status column. Don't append a new row.

If `applied_missions.md` doesn't exist, ask where it lives before proceeding — don't create it in an unexpected place.

## Reference files

Read these on demand, not preemptively:

- **`browser_automation.md`** — Playwright session conventions, page-reading patterns, React fiber form-filling, submission flow and banner checks. Read this before driving the application form.
