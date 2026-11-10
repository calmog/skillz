---
name: my-code-review
description: >-
  Spawn senior reviewer subagent(s) over the current code changes — a line-level
  Software-Architect lens, plus an integration lens for multi-component changes. Use after
  implementing a change and before presenting it for commit, or when the user asks for a deep /
  architectural / "proper" review ("code review", "architect review", "tech-lead review",
  "review my changes", "review the diff", "review before I commit", "integration review",
  "review the moving parts / seams"). Reviews the working diff for correctness, security,
  performance, scalability, readability, SOLID/DRY, project conventions, minimal-diff, and NEW
  build/lint warnings; the integration lens traces cross-component contracts, lifecycles, shared
  state, cleanup and degradation paths; reports test coverage to the user. Accepts an additive
  EMPHASIS (change-specific scrutiny areas) on top of the standing checklists. Read-only and
  advisory — it never edits or commits. NOT for reviewing an existing GitHub PR by number (use
  the built-in `/review`) and NOT a security-only audit (use `/security-review`).
---

# Code review (architect-level)

Runs adversarial, senior-reviewer subagent(s) over the current change — one per **lens**. Reviewers
are **read-only and advisory** — they find and classify problems; they never edit code or commit.
The reviewer personas + checklists + output contracts live in the sibling files `reviewer-prompt.md`
(line-level lens) and `integration-reviewer-prompt.md` (integration lens) — pass them verbatim.

## 1. Gather inputs
- **THE WORKTREE MAP — do this FIRST, before scoping any diff.** Enumerate *every* worktree and
  branch carrying part of this change (`git worktree list` in each repo the change touches), and pass
  that full list to **every** reviewer, including reviewers scoped to a single repo.

  This is not bookkeeping — it is the difference between a review and a wasted one. Worktree-first
  means the change lives in `~/Dev/worktrees/<repo>/<wt>`, while `~/Dev/<repo>` — the path a
  reviewer will reach for by default — sits on the default branch **without the change**. A reviewer
  checking a sibling repo's side of a contract lands on the stale checkout, finds the "consumer" hasn't
  been updated, and reports a confident, well-evidenced Blocker about code that is not the code under
  review. It fails silently and looks exactly like a real finding — once a backend reviewer reported
  the frontend still coerced nulls to `0` while the fix sat, uncommitted, in a worktree the brief
  never mentioned.

  So every reviewer brief must state, explicitly: the worktree path for its own scope, the worktree
  path for every sibling repo in the change (marked **read-only**), and the sentence *"the default
  `~/Dev/<repo>` checkout does NOT contain this change — never read it as the current state."*
  Also name any sibling worktree an agent is **actively writing** right now, so a reviewer doesn't
  report a half-applied edit as a defect.
- **THE TASK** — the instruction the source agent was implementing (what the change should
  accomplish). If it isn't clear from the conversation, ask the user for it in one line.
- **THE DIFF** — run `git --no-pager diff` and `git --no-pager diff --staged` for the scope
  (default: whole working tree; honor a path/base-ref override if the user gave one). List
  untracked files in the touched dirs and read them in full. Capture the base ref (e.g.
  `git merge-base HEAD origin/<default-branch>`) as the baseline.
- **EMPHASIS** (optional) — change-specific scrutiny areas from the user or the orchestrator
  (e.g. "the SQL scripting blocks", "the FE↔BE contract"). Emphasis is **additive**: it fills
  the `{{EMPHASIS}}` placeholder on top of the standing checklist. Never hand-roll a replacement
  reviewer prompt to get emphasis — that silently drops the checklist guarantees.
- **REPO CONTEXT** — read the target repo's own `CLAUDE.md`, `README` and relevant per-folder docs
  (plus the calling project's memory, if it records build commands) to get that repo's build /
  typecheck / lint / test / coverage commands. **Do not invent build commands** — if none are
  documented, ask the user for them in one line.

## 2. Spawn the reviewer(s)
Spawn the line-level reviewer (Agent tool) with the full text of `reviewer-prompt.md`, filling its
placeholders: `{{TASK}}`, `{{DIFF}}`, `{{NEW_FILES}}`, `{{BASE_REF}}`, `{{BUILD_LINT_TEST_CMDS}}`,
`{{EMPHASIS}}`.
- Give it Read / Grep / Glob / **Bash** (it must build + lint + measure coverage) and
  **WebSearch / WebFetch** (it must verify external-system constructs against official docs) but
  **not** Edit / Write — it is read-only.
- **Withholding Edit/Write is not enough — say it, because Bash can write.** A reviewer asked to prove a
  test really fails will reach for mutation testing, and one did that **in the live uncommitted
  worktree** (caught mid-mutation, colliding with the author's restore).
  Since nothing is committed during a review, a mutation left behind ships silently. State in the brief:
  *"Never modify any file under review, not even temporarily. To prove a test fails, copy the tree to your
  scratchpad and mutate the copy."* "Read-only and advisory" and "prove the test fails" are in direct
  tension; resolve it explicitly or the reviewer resolves it the dangerous way.
- **One reviewer per lens; lenses must not overlap.** Stacking reviewers on the *same* lens
  collapses signal-to-noise. Disjoint lenses (line-level vs integration) may run in parallel.
- **Integration lens** — when the change spans components/repos, touches shared or per-tenant
  state, contracts between FE↔BE, lifecycles (create/promote/delete), or cleanup/degradation
  paths, ALSO spawn a second subagent with `integration-reviewer-prompt.md` (same placeholders).
  Default to spawning it for any multi-component change; skip only for single-file changes.

## 3. Triage the report — who owns fix vs. skip
The reviewer only recommends; it has no authority to fix or to dismiss. When its report comes back:

- **Auto-apply** only **Blocker** / **Must-fix** findings that are objectively correct and low-risk.
- **Never silently skip** anything discretionary — Should-fix, Nits, anything debatable, or anything
  you disagree with. Present the finding + your own recommendation to the user; **they decide** every
  discretionary fix/skip and any disagreement with the reviewer.
- **Test-coverage section → relay to the user verbatim.** Do **not** auto-write tests or turn it into
  a fix task. It is information for the user to decide on; requesting tests is their call, not an
  auto-action.
- **Never apply an UNVERIFIED suggested fix.** A reviewer's suggested fix carries the same
  CONFIRMED/PLAUSIBLE/UNVERIFIED tag as findings; apply an unverified one only after independently
  verifying it (docs, or a real run).
- **Delta re-review before commit.** A review certifies the diff as of review time. Any fixes
  applied afterward get a scoped re-review of just the fix diff before presenting for commit.
- Then **stop before committing** (change → present → the user decides the commit).

## Notes
- Named `my-code-review` to stay distinct from the native `/code-review` (and `/simplify`,
  `/security-review`), so both remain invokable without shadowing or auto-trigger ambiguity.
- The "no new warnings" check is only as good as the build/lint commands it is given — without
  one, the reviewer says it couldn't establish a baseline rather than silently pass.
