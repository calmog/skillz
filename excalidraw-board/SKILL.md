---
name: excalidraw-board
description: Build an editable Excalidraw board/diagram/canvas from Python, and optionally render it to PNG. Use when creating a diagram, whiteboard, architecture board, system map, flow, or any visual artifact the user will open and edit in Excalidraw (excalidraw.com). Triggers - "make an excalidraw", "build a board/canvas/diagram", "architecture diagram I can edit", "render the board to an image".
---

# Excalidraw Board Builder

Generate a real `.excalidraw` file programmatically (boxes, wrapped text, arrows, colors). The user opens and edits it at excalidraw.com. Optionally render a PNG for quick viewing or sharing on a phone.

## Why use this
Excalidraw's hand-sketched look reads as "thinking", not "polished product", which suits design, architecture, and interview artifacts the user will narrate and edit live. Building from Python gives a regenerable source instead of a hand-placed one-off, and lets you diff/update it later.

There is no Excalidraw cloud API in this environment. You cannot mint a share link; you produce a file (and optionally a PNG). The user gets a share link from inside their own Excalidraw via the Share button.

## Build a board
`scripts/excalidraw_board.py` exposes a `Board` class:

```python
import sys; sys.path.insert(0, "<this skill>/scripts")
from excalidraw_board import Board

b = Board()
b.rect(40, 40, 500, 60, fill="#a5d8ff", stroke="#1971c2", sw=3, gid="z0")
b.text(40, 56, "ZONE TITLE", size=21, font=1, align="center", w=500, wrap=True, gid="z0")
b.text(58, 120, "• bullet one\n\n• bullet two", size=14, wrap=True, w=464)
b.arrow(548, 70, 600, 70)
b.save("/abs/path/out.excalidraw")          # strict_dashes=True to enforce almog-voice
```

- `gid` groups a rect with its text so they move together when the user drags them.
- `font`: 1 = hand-drawn, 2 = normal (default), 3 = code/monospace.
- `wrap=True` plus a fixed `w` puts the text in fixed-width mode, so Excalidraw flows the line breaks itself. Keep only structural newlines (between bullets/paragraphs) in the string; do not hand-wrap mid-sentence.
- Layout is plain coordinates. A left-to-right strip of zones reads as a linear narrative; group each zone in its own colored header + white body for a clean board.

## Render to PNG
```
uvx --with pillow python <this skill>/scripts/render_png.py /abs/in.excalidraw /abs/out.png
```
Reproduces rectangles, wrapped text, arrows at 2x for crispness.

## Gotchas
- Size boxes generously. A fixed-width text box narrower than a single-line title will truncate it.
- The PNG renderer approximates the hand-drawn font with a clean unicode font. Circled digits, arrows, stars, etc. need Arial Unicode (present on macOS); it falls back otherwise.
- If the board will be shown to anyone other than Almog, apply the almog-voice skill: no em-dashes or en-dashes, plain phrasing in full sentences. Call `b.save(path, strict_dashes=True)` to fail the build if any slipped in.
