# A.Team Apply — Setup

This skill applies to A.Team missions on your behalf. It needs your professional profile to evaluate missions and write applications. Setup takes about 5 minutes.

## Step 1 — Export your LinkedIn profile as PDF

1. Open LinkedIn in your browser and go to your profile page
2. Click **More** below your name → **Save to PDF**
3. Move the downloaded PDF into this skill's directory:

```bash
mv ~/Downloads/Profile.pdf ~/.claude/skills/ateam-apply/linkedin.pdf
```

## Step 2 — Run the skill

Open Claude Code and run:

```
/ateam-apply
```

Because `setup_complete` is `false`, Claude will:
1. Detect the LinkedIn PDF
2. Read and extract your work history, stack and highlights
3. Ask you a few questions about job search preferences (availability, rate range, location, domain priorities, honest gaps to flag in applications)
4. Generate `profile.md` in the skill directory with everything combined
5. Show you the output for review before saving

## Step 3 — Review profile.md

Check that the extracted info is accurate. Edit `profile.md` directly if anything is wrong or missing. Pay attention to:
- Stack items that got inflated or missed
- CV metrics (DAU, revenue, team size) — verify these are exactly right
- Any framing notes about honest gaps

## Step 4 — Mark setup complete

Once `profile.md` looks right, open `SKILL.md` and change:

```yaml
setup_complete: false
```

to:

```yaml
setup_complete: true
```

The skill is ready. `/ateam-apply` will now use your profile automatically on every run.

---

## What gets saved in profile.md

- Professional summary and CV highlights with metrics
- Tech stack split by primary / secondary / adjacent
- Job search preferences: availability, rate range, domain priorities, location
- Framing notes (gaps to address honestly in applications, strengths to lead with)

`profile.md` stays local — it is listed in `.gitignore` and never committed.
