# Code review: our custom skill vs. Claude Code's built-in `/code-review`

Decision doc comparing **Tool A** (our project-local `code-review` skill — `SKILL.md` + `reviewer-prompt.md`) against **Tool B** (Claude Code's bundled `/code-review`, plus its `/simplify` and `/security-review` siblings). Goal: decide what, if anything, to pull from the built-in into ours.

## TL;DR

- **They solve different problems.** The built-in is a **PR-time gate** (reads a GitHub PR via `gh`, posts inline comments, explicitly refuses to build/typecheck) with a slick apply/comment surface and a battle-tested confidence-scoring pipeline. Ours is a **pre-commit local reviewer** (reads the working tree, actually builds+lints+measures coverage, ties findings to `coding-standards.md`, and hands a three-tier ownership model to the user). Ours is deeper and more grounded; theirs is more integrated and lower-friction.
- **Two ideas are worth stealing now:** the built-in's `--comment` (post findings as inline PR comments, for the future PR path) and its `outcome` re-reporting field (needed only if we ever add apply mode). The single genuinely-useful-today borrow is the **verify/CONFIRMED-vs-PLAUSIBLE stamp** — but ours already gets ~90% of it via the ≥80-confidence gate + mandatory input→outcome trace, so it's an *adapt*, not an adopt.
- **Skip the rest by design:** `--fix` collides head-on with our deliberate read-only / user-owns-fix model; tunable effort levels are redundant with our fixed high-bar single-reviewer stance; the ~32 cap and `ReportFindings` schema are UX plumbing for a binary tool we can't hook into from a skill.

---

## 1. What the built-in does that ours doesn't — adopt / adapt / skip

| Built-in capability | What it is | Why it helps | Recommendation |
|---|---|---|---|
| **Tunable effort (low/med/high→max)** | A dial trading finding-count/coverage against confidence; high→max surfaces uncertain findings too. | Lets a caller pick "few high-confidence" vs "broad, some noise" per situation. | **Skip.** Ours is deliberately fixed at the high-confidence end (≥80 gate, "a noisy review is a failed review"). A dial invites the low-effort path we intentionally don't want pre-commit. Revisit only if we ever want a fast "quick scan" mode. |
| **Adversarial VERIFY pass → CONFIRMED / PLAUSIBLE stamp** | A separate pass re-checks each finding and stamps it CONFIRMED (verified) vs PLAUSIBLE (unverified) before reporting. | Gives the reader a per-finding trust signal grounded in a second look; separates "I traced this" from "I suspect this." | **Adapt (worth it).** Ours already forces an input→outcome trace and drops anything <80, which is most of the value. But we don't *label* the residual uncertainty. Cheap, high-value add: require the reviewer to tag each finding `CONFIRMED` (ran a command / traced end-to-end) vs `PLAUSIBLE` (reasoned but unrun), and prefer running the build/test to promote PLAUSIBLE→CONFIRMED. Fits our grounding section without adding an agent. |
| **`--fix` apply mode** | After reviewing, applies the findings to the working tree. | One-shot review-and-fix; less manual work. | **Skip (by design).** Our skill is deliberately read-only/advisory; SKILL.md §3 gives the user ownership of every discretionary fix/skip and forbids auto-writing tests. `--fix` is the exact behavior we rejected. Keep the split: review here, fix under the user's call. (`/simplify` and built-in `--fix` remain available directly to anyone who wants auto-apply.) |
| **`--comment` inline-PR-comment mode** | Posts each finding as an inline comment on the PR at the right file:line. | Puts feedback where review actually happens; no copy-paste; survives across sessions. | **Adapt / nice-to-have.** Irrelevant to the pre-commit local flow ours targets, and SKILL.md already defers real-PR review to built-in `/review`. But if we later add a "review my open PR" path, an inline-comment output is the right surface — worth a future optional mode, not now. |
| **~32-finding cap** | Hard ceiling on reported findings, ranked most-severe-first. | Bounds output; forces prioritization on huge diffs. | **Skip (mostly redundant).** Our ≥80 gate + severity ordering already bounds output far below 32 in practice. A cap only matters on very large diffs; if that ever bites, add "cap at N, note how many were suppressed" — cheap, but not needed now. |
| **`ReportFindings` structured tool + `outcome` (fixed/skipped/no_change_needed)** | Findings emitted through a typed tool with a machine-readable schema; `outcome` set when re-reporting after `--fix`. | Enables reliable downstream automation (posting, apply-tracking, dedupe). | **Skip.** This is binary-tool plumbing a markdown skill can't emit. Our output contract (fixed sections, `SEVERITY · confidence NN · file:line`, `Disposition`) already gives structured, greppable output. `outcome` only matters if we add apply mode, which we're not. |
| **Sibling `/security-review` and `/simplify`** | Dedicated security-only and quality-only variants. | Focused single-axis passes. | **Skip / already handled.** SKILL.md explicitly defers security-only to `/security-review`; ours folds security + simplification into one pass on purpose (one reviewer, depth via checklist). No change. |
| **Multi-agent PR pipeline (plugin variant: 4–5 parallel reviewers + per-issue Haiku scorer)** | Fan-out reviewers (CLAUDE.md / bugs / git-blame / prior-PR-comments / code-comments) then independent confidence scoring. | Diverse perspectives; git-history & prior-PR-comment context ours doesn't gather. | **Adapt one piece.** We deliberately rejected the reviewer *stack* (SKILL.md: "a stack of overlapping reviewers collapses signal-to-noise"). Keep one reviewer. But **git-blame / historical-context** grounding is a real gap — worth adding as an optional checklist step ("when a changed line looks wrong, check `git blame` / the commit that introduced it before flagging"), not a second agent. |

---

## 2. Where the built-in is genuinely better (honest)

- **PR integration is a real product surface.** `gh`-driven PR fetch + `--comment` inline posting + the exact SHA/line-range link format put findings where humans review. Ours produces a report in the terminal; for anything that lives on GitHub, the built-in wins outright, and ours concedes this (defers to `/review`).
- **The verify pass is a cleaner trust primitive.** CONFIRMED-vs-PLAUSIBLE is a first-class, legible label. Ours buries the same signal inside a 0–100 score and a prose trace — same rigor, worse ergonomics for the reader.
- **Effort dial = adaptability.** A one-line knob to go broad-and-noisy or tight-and-safe is genuinely useful on diffs of very different sizes/risk. Ours has one gear.
- **Battle-tested & maintained.** It ships in the CLI, is authored/owned inside Anthropic, has a structured tool + cap tuned across huge real-world usage. Ours is bespoke and unproven; its false-positive control is only as good as our prompt.
- **`--fix` / `/simplify` close the loop** for people who want auto-apply — a legitimate workflow ours refuses on purpose (a strength for us, a feature gap in absolute terms).
- **Historical context.** The plugin variant reads git blame and prior-PR review comments; ours judges the diff largely in isolation.

## 3. Where ours is better / does things the built-in doesn't

- **Actually establishes a build/lint baseline and runs it.** Ours captures `{{BASE_REF}}`, builds+lints the working tree, and reports **only NEW** warnings/errors with quoted command output. The built-in *explicitly refuses* to build/typecheck ("these will run separately … not relevant"). For a pre-commit gate, running the tools is the whole point — this is our biggest edge.
- **Real test-coverage section, user-owned.** Ours measures coverage of the new feature, lists uncovered behaviors, and **requests specific named tests** — framed as information for the user, never an auto-fix. The built-in treats coverage as an ignorable general-quality issue.
- **Senior-architect + explicitly adversarial persona.** "You did not write this code… your stance is adversarial… correctness over agreeableness." Broader/deeper mandate than the built-in's bug+guideline focus.
- **Minimal-diff / every-line-required check tied to `coding-standards.md`.** Ours flags gratuitous reformatting, drive-by refactors, and scope creep, and names lines that could be reverted. The built-in has no equivalent — it *ignores* "changes likely intentional or related to the broader change," the opposite stance.
- **Breadth: SOLID/DRY, scalability, performance under tenant/data growth.** Explicit checklist axes (N+1, unbounded loops, missing pagination, coupling, backward-compat, migrations). The built-in is deliberately narrow (bugs + CLAUDE.md), punting quality to `/simplify`.
- **Loads project conventions properly.** Reads the target repo's `CLAUDE.md` + per-folder docs **and** its documented build/test commands ("do not invent build commands"). Convention-aware in a way the PR built-in isn't (it only lists CLAUDE.md paths).
- **Three-tier ownership model.** Auto-apply only objectively-correct low-risk Blockers/Must-fixes; everything discretionary → present to the user with our own recommendation, they decide; coverage → relay verbatim; stop before commit. A deliberate human-in-the-loop governance the built-in's `--fix`/auto-comment flow doesn't offer.
- **Grounding discipline as a first-class rule.** Mandatory premise → execution-path → concrete triggering input→outcome for every correctness/security finding, or drop it. Comparable to the built-in's verify pass in rigor, and it's baked into the single reviewer rather than a separate stage.

## 4. Recommendation — prioritized

### Adopt now
1. **Add a `CONFIRMED` / `PLAUSIBLE` tag per finding.** — Cheapest high-value borrow: makes our existing grounding legible and nudges the reviewer to *run* the check to promote a finding. Add to the "Confidence & severity" + output-format sections of `reviewer-prompt.md`.
2. **Add a git-history grounding step to the checklist.** — "Before flagging a suspicious changed line, check `git blame` / the introducing commit to avoid mis-attributing intentional or pre-existing behavior." Closes a real context gap the built-in has and ours lacks, without adding an agent.

### Nice-to-have (defer)
3. **Optional finding cap with suppression note.** — On very large diffs, cap reported findings (e.g. 25–30) and state how many lower-severity ones were suppressed. Only matters at scale; skip until it bites.
4. **Future "review my open PR" mode with `--comment`-style inline output.** — If/when we want ours to touch real PRs, add a mode that posts findings as inline PR comments in the built-in's SHA/line-range format. Today SKILL.md correctly defers PR-by-number to `/review`; no change needed yet.

### Explicitly do NOT adopt
5. **`--fix` apply mode** — collides with our deliberate read-only/advisory design and the user's fix/skip ownership. Keep the review/fix split.
6. **Tunable effort dial** — redundant with our fixed high-confidence bar; a low-effort mode is exactly what we don't want pre-commit.
7. **Multi-reviewer fan-out** — we already rejected it on signal-to-noise grounds; depth comes from the checklist + grounding, not agent count.
8. **`ReportFindings` schema / `outcome` field** — binary-tool plumbing a markdown skill can't emit; our fixed-section output already gives structured results.
