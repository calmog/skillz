# Profile Editing (the /almog page)

Reference for editing the user's A.Team profile (projects, jobs, skills). Read on demand when the user asks to refine their profile — not needed for the main mission-application workflow.

## Entering edit mode
Profile page is `https://platform.a.team/almog`. When signed in, a top-right "Edit" button (y<100) toggles edit mode. In edit mode, each project/job card shows "Edit" and "Delete" buttons. In view mode, cards show "Open Project" instead.

## Project/Job modals use tiptap (ProseMirror)
The description editor is `.ReactModal__Content .ProseMirror`. The DOM node exposes `.editor` which is the tiptap Editor instance.

The first block of a project description is always rendered as `<h3>` by A.Team's design (it's the "headline"). This is not a bug and does not block publishing. Don't try to fix it — toolbar toggle, keyboard shortcuts, and `ed.commands.setParagraph()` all get overridden. Write your "headline" line as the first paragraph and trust the platform to render it as h3.

### Bypassing text-entry schema with setContent
Typing into the ProseMirror via `page.keyboard.type()` triggers schema rules (e.g., first line → h3). To write exactly the structure you want (e.g., two-paragraph description), use tiptap's API directly:

```javascript
await page.evaluate(() => {
  const pm = document.querySelector('.ReactModal__Content .ProseMirror');
  const ed = pm.editor;
  ed.commands.setContent({
    type: 'doc',
    content: [
      { type: 'paragraph', content: [{ type: 'text', text: 'First line.' }] },
      { type: 'paragraph', content: [{ type: 'text', text: 'Second paragraph.' }] }
    ]
  });
});
```

Schema node types available: `paragraph, doc, text, heading, listItem, bulletList, orderedList, hardBreak`.

After `setContent`, click the modal's **Publish** button (not "Save") to persist. Verify via `page.mouse.click(x, y)` on real coordinates — `btn.click()` via DOM can close the modal without committing.

**Verification:** after Publish, re-open the same modal. The first paragraph will render as `<h3>` again (headline), but the text content (including punctuation changes) will persist — that's proof it saved.

## Project modal structure
- Title input: `input[name="title"]`
- Company input: unnamed text input
- Role input: `input[name="jobRole"]`
- Related job: `input[name="relatedJobId"]` (hidden)
- Description: `.ProseMirror` (tiptap)
- Outcomes: six `<textarea>` elements with placeholders like "60,000" and "Bounce rate reduction"
- Skills: shown as chips with 1-5 rating buttons per chip
- Buttons at bottom: "Start writing", "Cancel", "Publish"

## Cross-modal state contamination
If you close one project modal (via Cancel or backend save) and immediately open another, the previous modal's ProseMirror content can briefly appear in the new modal. Reload the page before editing a different project, or discard and re-open.

## "Maximized visibility" banner
"Great work! You've maximized your company visibility." appears at the top of the profile page when everything is publishable. This is A.Team's positive signal — it does not mean "capped" or "limited", it means the profile is fully eligible for discovery. If this banner is present, the profile is fine.

## Project edit buttons filter
When looking for Edit buttons in the Projects section, filter by parent card containing the expected project title substring:

```javascript
const cards = [...document.querySelectorAll('*')].filter(el =>
  el.children.length > 0 &&
  el.textContent.includes('VIVID - Practical Personal Growth') &&
  el.textContent.length < 500
);
const editBtn = cards.flatMap(c => [...c.querySelectorAll('button')])
  .find(b => b.textContent.trim() === 'Edit');
```

The `length < 500` constraint prevents matching ancestor containers that include multiple cards.

## Job Edit buttons vs Project Edit buttons
In edit mode, both Jobs and Projects sections show "Edit" buttons. Job section buttons render at x > 1000, Project section at x ~595/885. Filter by `x > 1000` to limit to Jobs.

## Skills input in job modals (narrow, hidden)
The skill-add input in job modals is a React-Select `input[type="text"]` with no placeholder/name, width ~43px, at approximately `y=362` (exact coordinate varies by job). To type:

1. Mouse-click on the input's coordinates to focus.
2. Use `Cmd+A, Backspace` to clear any stale text (important — leftover text concatenates with next search: "Node.js" after unclear "React" → "Node.jsact"). `10×Backspace` is unreliable.
3. Type the skill name. Wait ~1000ms for dropdown.
4. Find and click the matching `[class*="option"]` element where `textContent.trim() === skillName`.
5. Set rating by finding the chip row (element containing skill name with 5 rating divs) and mouse-clicking the target rating's coordinates.

## Skill taxonomy gotchas
- "Test Automation" is not in A.Team's skill taxonomy (dropdown returns "No options"). Don't try to add it.
- "React" matches multiple options ("React Native", "React", "Preact", "React Flow"). Filter strictly by `textContent.trim() === 'React'`.

## Job modal differs from Project modal
- **Buttons.** Project modal uses "Publish" and "Cancel"; Job modal uses **"Add experience" and "Close"**. When saving a job edit, look for "Add experience" button. The title "Create a job experience" in the modal header is the signal it's a Job modal, not a Project modal.
- **Required fields.** Jobs require Industry and Specialization to save. Legacy jobs created before this requirement may have empty values. When saving, you'll see "Industry is required" / "Specialization is required" errors. Also requires at least one skill (same error pattern). Fill them before clicking Add experience.

### Industry / Specialization dropdowns are React-Select (coordinate clicks needed)
The dropdowns render as a div containing placeholder text ("Select industry" / "Select specialization"). They don't match `div.textContent === "Select industry"` when children.length constraints are applied. Use mouse coordinate click (approximately 640, 155 for industry; 640, 307 for specialization — exact y varies by job layout), then type the filter, then click the matching option at y ≈ 208.

After selecting Industry, the dropdown re-opens to show the full list — click outside the dropdown (e.g., x=370, y=90 near the modal header) to close it before interacting with the next field.

## Finding a Job row vs Project row with the same company text
When a company has both a Job and a Project, searching for the company name matches both. The Jobs section uses the role title above the company; Projects show company first then subtitle. To target the Job specifically, filter by the role title (e.g., `textContent.trim() === 'Full Stack Mobile Team Leader'`), then walk up to the container with Edit+Delete.

## Job Save confirmation: "Are you sure you want to quit" dialog
Clicking the X/Close button on any Job/Project modal with unsaved content opens a confirmation dialog with "Quit" / "Never mind". Click "Quit" to dismiss. Happens even if you didn't visibly modify anything (e.g., from opening-then-closing a modal).

## Main profile skill ratings are not inline-editable
The main Skills section displays chips like `React Native | 3` with a Close (X) icon for removal. There's no inline rating edit. To change a rating, remove the chip and re-add the skill via the rating popup. Don't try to click the chip or look for a pencil — neither exists at this level. Ratings are effectively set-at-add-time only.

## Project Role field — prefer IC titles over management titles
Projects have their own Role field separate from the related Job. Setting Role to a dev title (Mobile Developer, Software Engineer, iOS Developer) signals IC positioning to the platform — more useful for mission matching than "Engineering Manager" / "CTO" even when the underlying job was leadership. When the user has a project tagged with a management title, retagging it to the IC title for the actual technical work they did is honest and aligns with the roles they're targeting now.

## Writing project descriptions that stay IC-focused
When the underlying job was management, but the project deliverable was technical: lead with the engineering outcome and verb ("Rebuilt X", "Shipped Y"), then mention team scale as context, not the headline. Don't open with "Restructured the org" — open with the thing that was built/shipped.
