---
name: ateam-apply
description: Apply to freelance positions on A.Team (platform.a.team) for Almog Cohen. Use when the user says "apply to A.Team", "check recommended missions", "work through my A.Team queue", "any new missions?", or otherwise references platform.a.team. Also serve as the default for open-ended start-work requests ("let's go", "next", "continue", "what's next") when the current working directory is the A.Team applications project.
---

# A.Team Freelance Application Manager

## Context

Almog Cohen — Engineering Team Leader / Co-Founder & CTO, 15+ years mobile & full-stack.

**CV highlights:**
- Co-Founder & CTO at VIVID (AI-driven personal growth app, Dr. Tal Ben-Shahar). 0→35K DAU, $2M raised, $1M revenue. Sole technical owner.
- Team Leader of 3 Dev Teams at Testim.io (restructured R&D org, doubled team size)
- Full-Stack Mobile Team Leader at Sears Israel (8 devs + 1 QA, 40% velocity gain)
- Mobile Team Leader at OnO Apps (6 devs, built & sold a product)
- B.Sc. Biology, Technion (Honors) | IDF Fighter & Ops Commander | Patent pending

**Stack:** Flutter, React Native, iOS (Swift), Android (Kotlin), Node.js, TypeScript, GCP, Firebase/Firestore, NoSQL, MySQL, AI-augmented dev (Claude Code, Cursor), Agile, CI/CD, TDD

**Important distinction:** The user has built agents on personal projects but not at a company. Don't pretend otherwise. Frame their agent work as personal/exploratory and their production AI experience as building *with* AI tools (Claude Code, Cursor).

## Communicating with the user

Refer to the user in second person when presenting analysis, asking questions, or summarizing work. Say "this fits your stack" / "you're missing Go", not "this fits his stack". This applies to every message back to the user, not just application copy.

## Job Search Preferences

- **Role type:** IC and hands-on lead roles. Solution Architect / pre-sales consulting is a soft no unless approved per-mission.
- **Availability:** Available immediately. Prefers full-time (~45 hrs/week) but open to part-time missions of any hours range. Landing a mission is the priority — do not auto-skip on low hours.
- **Rate strategy:** see [Rate strategy](#rate-strategy). Personal rate targets are kept out of this skill — the user will tell you the number per mission if it matters.
- **Domain priority:** 1) AI / AI Agents / Agentic systems startups, 2) Consumer apps, 3) B2B SaaS
- **Location:** Remote preferred. Open to on-site Tel Aviv, Israel.
- **Engagement length:** Flexible.
- **Stack preferences:**
  - Primary: Flutter, React Native, iOS (Swift), Android (Kotlin)
  - Secondary (open with learning curve): Node.js, TypeScript, Python, Go, Elixir, other backend languages
  - Less aligned (still not an auto-skip): DevOps/Kubernetes, Data Engineering — present with honest gap framing
  - Unfamiliar languages are not a hard filter. The user is willing to learn a new language on the job (e.g. Go). Skip only when the role is *majority-time* in a stack they've never touched AND there's no AI/agentic or product-ownership upside to balance it.

## Platform: A.Team

- URL: https://platform.a.team/mission-control/recommended
- The user is logged in — if session expired, ask them to log in
- Missions are listed as cards; click a card to open its detail page
- Each mission has multiple roles with "Request to join" buttons
- "Show more info" buttons reveal application-specific guidance ("How to stand out", etc.) — always click these before writing applications

## Mission Evaluation Process

### Step 1 — Scan all recommended missions
Go to https://platform.a.team/mission-control/recommended and scroll through every card. Collect company name, mission title, available roles, and any "Matched on X" tags.

### Step 2 — For each strong/possible fit, open and read
- Every role description — some missions have 20+ roles and the right one is buried below the obvious ones
- Rate ranges (hourly and monthly)
- Required skills and any gaps flagged by the platform
- Working hours overlap — platform-enforced; when flagged, take it literally, don't apply assuming it's negotiable
- Location requirements — hard filter, check early to save time
- Team status (actively looking vs. builders already proposed)
- The "What We're Building" section — critical for tailoring applications

### Step 3 — Present analysis to the user with:
- Why it'd interest them
- Why they're suitable
- Why they might not be suitable (honest assessment)

### Step 4 — For missions the user approves, apply

### Step 5 — Before submitting, show the user the Q&A

Always show the user the exact question text and your drafted answer for every application field before filling the form. Format it as:

> **Q: [exact question from platform]**
> [your drafted answer]

This lets them review for tone, accuracy, and exaggeration before anything is submitted. Don't fill the form until they approve the text.

When revising drafts after the user gives feedback, present a contextual diff (not the full text again). Use a fenced `diff` code block. Show unchanged surrounding sentences with a leading space (renders white), removed text with `-` (renders red), added text with `+` (renders green). Scope the change to the sentence/clause level so the user can read the change in context without scanning the full paragraph. Insert mocked line breaks at clause boundaries if needed for readability. Only show the full re-draft if the changes are too pervasive to diff cleanly.

## Filtering Logic

### #1 Application Order Rule

> **HIGH-FIT+ACTIVE > LOW-FIT+ACTIVE > HIGH-FIT+PROPOSED > LOW-FIT+PROPOSED**

When building an application queue, sort strictly by these four tiers in that order. Never put a proposed mission ahead of any active mission, even if the proposed one is a stronger stack match. Within each tier, sort by fit quality (high fit first). Acceptance odds rank: actively-looking > builders-proposed, full stop — fit only tie-breaks *inside* a tier, never across tiers.

"Low fit" = location flag, rate well below the company's stated minimum, missing required skill with no realistic justification, no honest project showcasing the required work, or any other substantial gap relative to what the company/platform explicitly wants.

### Auto-skip (don't present to the user):
- Pure non-dev roles: Designer, Community Manager, Growth Marketer, IT Consultant, pure QA-IC, Data Analyst, Data Architect-only, Recruiter/Interviewer-type roles
- Requires direct domain background the user clearly lacks (e.g., "must have worked at [specific company]")
- Hard location blocks (e.g., US-only on-site, India-only)
- Core stack mismatch only when the role is majority-time in a stack the user has never touched AND there's no AI/agentic angle and no product-ownership angle. Unfamiliar languages alone (Go, Elixir, etc.) are not a skip — the user will learn on the job.
- Rate ceiling well below the company's stated minimum with no AI/agentic upside

In-scope role titles: IC engineer, hands-on lead/CTO, Engineering Manager, Project Manager, Program Manager, Delivery Manager. Solution Architect / pre-sales consulting is a soft no unless approved per-mission.

### "Builders already proposed" missions
- Don't skip these — apply if the user otherwise qualifies for the role
- Order: process all "Actively looking" missions first (sorted by fit), then all "Builders proposed" missions (sorted by fit). Never interleave.
- The risk is lower acceptance odds, not zero — still worth submitting a strong application

### Present despite concerns (let the user decide)
- AI/agentic startups, including ones at the lower end of the rate range — the domain matters
- Missing 1-2 skills if the domain is strong and the user can ramp quickly
- Overlap requirement that's tight but workable (Israel UTC+3, EST overlap = 4pm-9pm local)
- React/Next.js roles (React Native → React transfer is reasonable)

### Watch out for
- Roles labeled "Developer" that are actually recruiting/interviewing roles (read the responsibilities, not just the title)
- Roles requiring prior employment at specific named companies
- Missions where the role appears open but the team is clearly already staffed

## Application Process

### Before writing anything
0. Load the `almog-voice` skill before drafting any text. It carries the voice rules (no em-dashes, no AI-syntax tells, no Oxford comma, no micro-header labels, etc.). Don't restate those rules here, and don't draft a single word of application copy without it loaded.
1. Navigate to the mission detail page
2. Click "Show more info" on the specific role being applied to
3. Read every piece of guidance: "How to stand out", "What the company is looking for", any company-specific questions
4. Read the full "What We're Building" section
5. Check rate compatibility and note any gaps to address
6. **Tune project cards for this mission.** A.Team's own guidance: *"Edit your project cards to highlight those relevant to the mission… You can do this by hiding your less relevant project cards from your mission request. The remaining project cards should primarily showcase abilities and experience that will contribute to the specific mission."* The application form exposes per-application visibility toggles on each project card. Surface only the cards aligned with this role and hide the rest. Pick the 2–4 most relevant cards; bias toward fewer-and-sharper over showing everything. Confirm the choice with the user before locking it in.
7. **Match role-card availability to the role.** The role card has its own availability / hours-per-week / timezone-overlap fields, separate from the global profile. If the role expects e.g. 30 hrs/week, set the role card to 30 even though the global profile is set higher — A.Team explicitly says this raises acceptance odds. Confirm overrides with the user if they diverge from their stated availability.
8. **Refine each selected project until the banner is fully positive.** Never submit on the intermediate banners ("needs some work", "should be refined", "right track but room for improvement", "thorough and meets requirements / consider refining"). Only submit when the banner reads "your application is very impressive and there's nothing significant left to refine" / "you should feel confident submitting". Being on top of the applicant list materially affects acceptance odds, so refining to fully-green is worth the iteration. For each selected project, open Edit and: (a) switch the project's Role dropdown to the mission's required role when honest (e.g. "iOS Developer" for an iOS mission, "Project Manager" for a PM mission), (b) add the mission's required and preferred skills to the project's skill list (12-skill cap — remove a less-relevant skill to make room), (c) verify dates and management/0-to-1 toggles are accurate. Improvements must be *realistic* — never invent skills the user doesn't have or roles they didn't hold. Republish each project, then re-check the banner. Iterate until fully green.

### Application principles
- Lead with outcomes, not responsibilities (e.g., "shipped 0→35K DAU" not "managed team")
- For AI roles: highlight building *with* AI tools (Claude Code, Cursor) and VIVID as AI product experience
- For mobile roles: lead with breadth (iOS + Android + Flutter + React Native) and depth
- Address skill gaps directly and honestly (e.g., "Python is a learning curve, but I learn fast and have shipped complex systems before")
- Mirror the company's language from "What We're Building" — use their words back at them
- For Israeli companies: mention Israel location explicitly as a timezone/culture advantage
- **Be calibrated — don't exaggerate skill depth.** If something is on the user's profile at level 3 (e.g., Docker, Node.js), say they work with it, not that it's a primary tool. If they use MCP as a power user but haven't built agent frameworks, say that — don't claim they've built integrations they haven't.
- **Don't underplay product strengths.** VIVID is a product success story (0→35K DAU, $2M raised, sole technical owner). When a role values product-minded engineers, lean into this. Also highlight: autonomous delivery, end-to-end ownership, shipping under constraints.

### Rate strategy
- Enter a rate within the company's stated budget range, never above the ceiling. The platform warns when rate exceeds budget and explicitly lowers acceptance odds.
- Don't pick the top of the range. Maxing the range tends to look tone-deaf and hurts acceptance odds.
- Pick a clean round number (e.g., $105/hr, $110/hr, $17,000/mo, $18,000/mo), not the exact percentage math output.
- Strong fit (clear alignment on core skills, domain, platform-rated "great fit"): aim around the upper-middle of the range, rounded to a clean number just below.
- Stretch fit (AI/agentic stretch roles, missing-a-skill roles, stack-adjacent roles): aim around the middle of the range, rounded to a clean number.
- Examples:
  - Range $92–$115/hr, stretch fit → $105/hr. Monthly $12,790–$19,985 → $17,000/mo.
  - Range $92–$115/hr, strong fit → $110/hr. Monthly $12,790–$19,985 → $19,000/mo.
  - Range $13,986–$17,483/mo, strong fit → $17,000/mo (not $17,483).
- Hourly-only roles have no monthly rate field — only fill monthly when the field actually exists in the form.
- Rate range shown = company budget, not ceiling. You can apply above it, but the platform warns and it reduces acceptance odds.
- Ask the user for the rate when the company range is below the level you'd normally pick — don't guess their floor.
- Always check the "If selected, I agree to work on this role at or above the rate entered below" checkbox. It appears in the Rate section of every application and must be checked before submitting.

## Applied Missions Tracker

The list of missions already applied to lives in `applied_missions.md` in the current working directory (the project folder this skill is invoked from).

**Before scanning recommended missions:** Read `applied_missions.md` and treat every row in it as already-applied — don't re-surface those missions to the user as candidates.

**After every successful submit:** Append a new row to the table with `Date | Company | Mission | Role | Status`. Use the same day's date in `YYYY-MM-DD` format. The skill is only useful if this file is maintained, so do it immediately, not "later".

**When status changes** (e.g., In review → Team Up, or Rejected): update the existing row's Status column rather than appending a new one.

If `applied_missions.md` doesn't exist in the working directory, ask the user where it lives before proceeding — don't create a blank one in an unexpected place.

## References

These files in the skill directory hold reference material — read them on demand, not preemptively:

- **`browser_automation.md`** — Playwright session conventions, page-reading patterns, form-filling snippets (React fiber textareas, skill rating popups, project selection), submission flow (positive-banner check, post-submit Gmail confirmation), and terminal-window automation. Read this before driving the application form.
- **`profile_editing.md`** — UI archaeology for the `/almog` profile page: tiptap/ProseMirror editor quirks, project vs. job modal differences, skill-add input coordinates, dropdown handling. Read this only when the user asks to refine their profile (not for the standard mission-application workflow).
