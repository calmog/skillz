---
name: docx-editing
author: calmog
description: Edit .docx Word documents by extracting XML, modifying content, and repacking. Claude Code cannot read .docx files directly — this skill provides the extract/edit/repack workflow.
  TRIGGER when: user references a .docx file path or mentions a Word document and wants to read, edit, modify, or create it.
  DO NOT TRIGGER when: user is working with other document formats (PDF, txt, markdown, etc.).
argument-hint: [path-to-docx]
---

# Edit .docx Files via XML Extraction

`.docx` files are ZIP archives containing XML. The workflow is: **extract → edit XML → repack**.

## Step 1: Extract

```bash
mkdir -p /tmp/docx_work && unzip -o 'path/to/file.docx' -d /tmp/docx_work/extracted/
```

### Quick text-only read (no editing needed)
```bash
unzip -p 'path/to/file.docx' word/document.xml | sed 's/<[^>]*>//g' | sed '/^$/d'
```

## Step 2: Read the XML

Use the Read tool on the extracted files:
- `word/document.xml` — **main body content** (all text lives here)
- `word/styles.xml` — style definitions
- `word/header1.xml` / `word/footer1.xml` — header/footer
- `word/numbering.xml` — list/bullet numbering definitions

## Step 3: Edit

Use the Edit tool on `/tmp/docx_work/extracted/word/document.xml`.

### XML Structure

```xml
<w:p>                          <!-- paragraph -->
  <w:pPr>                      <!-- paragraph properties (style, spacing) -->
    <w:pStyle w:val="Heading"/>
  </w:pPr>
  <w:r>                        <!-- run = text segment with uniform formatting -->
    <w:rPr>                    <!-- run properties (font, size, bold, color) -->
      <w:sz w:val="18"/>       <!-- font size in half-points (18 = 9pt) -->
    </w:rPr>
    <w:t>Actual text here</w:t>
  </w:r>
</w:p>
```

### Editing Rules

- **Text content** lives in `<w:t>` tags inside `<w:r>` runs
- **One visible sentence** is often split across multiple `<w:r>` elements (each with its own formatting) — read them together
- **To change text only**: modify `<w:t>` content, keep `<w:rPr>` formatting untouched
- **`xml:space="preserve"`** on `<w:t>` preserves leading/trailing whitespace — don't remove this attribute
- **To add a new bullet point**: copy an existing `<w:p>` that has `<w:numPr>` and modify its text
- **To add a new paragraph**: copy an existing `<w:p>` block with the desired style and change the text

### Things to Avoid

- Don't touch `<mc:AlternateContent>` blocks — these are decorative shapes/lines
- Don't modify `<w:fldChar>` field code sequences unless intentionally editing hyperlinks
- Don't change `<w:numId>` values unless you understand `numbering.xml` references

### Hyperlinks

Hyperlinks use field codes, not simple tags:
```xml
<w:fldChar w:fldCharType="begin"/>
<w:instrText> HYPERLINK "https://example.com"</w:instrText>
<w:fldChar w:fldCharType="separate"/>
<w:t>Display Text</w:t>
<w:fldChar w:fldCharType="end"/>
```

## Step 4: Repack

```bash
cd /tmp/docx_work/extracted && zip -r /tmp/docx_work/output.docx . -x ".*"
cp /tmp/docx_work/output.docx 'path/to/file.docx'
```

## Step 5: Clean Up

```bash
rm -rf /tmp/docx_work
```

## Why the zip/unzip approach

This skill relies only on the `zip` and `unzip` CLI tools — no Python (`python-docx`)
or Node library required — so it works on any machine without installing
dependencies:

- `unzip` and `zip` are preinstalled on macOS and most Linux distributions. On
  Windows, run these under Git Bash or WSL (or use `tar` to extract).
- Because `.docx` is just a ZIP of XML, editing the XML directly and repacking is
  reliable and library-free.
- The repacked file may be slightly larger than the original (a different
  compression level) — this is normal, and the file opens correctly in Word.
