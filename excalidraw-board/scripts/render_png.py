"""Render an .excalidraw file to PNG.

    uvx --with pillow python render_png.py input.excalidraw output.png

Reproduces rectangles, wrapped text, and arrows at 2x for crispness. The hand-drawn
font is approximated with a clean unicode font (Arial Unicode on macOS covers circled
digits, arrows, stars, etc.).
"""
import json, os, sys, math
from PIL import Image, ImageDraw, ImageFont

if len(sys.argv) < 3:
    sys.exit("usage: render_png.py input.excalidraw output.png")
IN, OUT = sys.argv[1], sys.argv[2]

doc = json.load(open(IN))
els = doc["elements"]
maxx = max(e["x"] + e.get("width", 0) for e in els)
maxy = max(e["y"] + e.get("height", 0) for e in els)
W, H = int(maxx + 60), int(maxy + 60)
S = 2  # supersample

img = Image.new("RGB", (W * S, H * S), "#ffffff")
d = ImageDraw.Draw(img)

UNI = next((p for p in [
    "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
    "/Library/Fonts/Arial Unicode.ttf",
] if os.path.exists(p)), None)
MONO = next((p for p in [
    "/System/Library/Fonts/Menlo.ttc",
    "/System/Library/Fonts/Supplemental/Courier New.ttf",
] if os.path.exists(p)), None)
_fc = {}


def font(size, mono=False):
    key = (size, mono)
    if key not in _fc:
        path = MONO if (mono and MONO) else UNI
        _fc[key] = ImageFont.truetype(path, int(size * S)) if path else ImageFont.load_default()
    return _fc[key]


def wrap(text, f, maxw):
    out = []
    for para in text.split("\n"):
        if para == "":
            out.append("")
            continue
        line = ""
        for word in para.split(" "):
            t = (line + " " + word).strip()
            if d.textlength(t, font=f) <= maxw * S or not line:
                line = t
            else:
                out.append(line)
                line = word
        out.append(line)
    return out


for e in els:
    t = e["type"]
    if t == "rectangle":
        x, y, w, h = e["x"] * S, e["y"] * S, e["width"] * S, e["height"] * S
        fill = e["backgroundColor"]
        fill = None if fill == "transparent" else fill
        d.rounded_rectangle([x, y, x + w, y + h], radius=10 * S, fill=fill,
                            outline=e["strokeColor"], width=max(1, int(e["strokeWidth"] * S)))
    elif t == "arrow":
        x, y = e["x"] * S, e["y"] * S
        x2, y2 = x + e["points"][-1][0] * S, y + e["points"][-1][1] * S
        d.line([x, y, x2, y2], fill=e["strokeColor"], width=int(2 * S))
        ang = math.atan2(y2 - y, x2 - x)
        for da in (math.pi - 0.4, math.pi + 0.4):
            d.line([x2, y2, x2 + 10 * S * math.cos(ang + da), y2 + 10 * S * math.sin(ang + da)],
                   fill=e["strokeColor"], width=int(2 * S))
    elif t == "text":
        f = font(e["fontSize"], mono=(e.get("fontFamily") == 3))
        x, y = e["x"] * S, e["y"] * S
        lh = e["fontSize"] * 1.25 * S
        lines = e["text"].split("\n") if e.get("autoResize", True) else wrap(e["text"], f, e["width"])
        for i, ln in enumerate(lines):
            if e.get("textAlign") == "center":
                lx = x + (e["width"] * S - d.textlength(ln, font=f)) / 2
            else:
                lx = x
            d.text((lx, y + i * lh), ln, font=f, fill=e["strokeColor"])

img.resize((W, H), Image.LANCZOS).save(OUT, "PNG")
print("saved", OUT)
