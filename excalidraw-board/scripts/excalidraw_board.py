"""Tiny library to build editable Excalidraw boards from Python.

    from excalidraw_board import Board
    b = Board()
    b.rect(40, 40, 200, 80, fill="#a5d8ff")
    b.text(60, 70, "Hello", size=20, wrap=True, w=160)
    b.arrow(240, 80, 320, 80)
    b.save("/abs/out.excalidraw")        # strict_dashes=True -> fail on em/en dashes

Then render: uvx --with pillow python render_png.py out.excalidraw out.png
"""
import json, random

_ALNUM = 'abcdefghijklmnopqrstuvwxyz0123456789'
_TS = 1717000000000


class Board:
    def __init__(self, seed=7):
        self._r = random.Random(seed)
        self.elements = []

    def _id(self):
        return ''.join(self._r.choice(_ALNUM) for _ in range(16))

    def _seed(self):
        return self._r.randint(1, 2**31)

    def rect(self, x, y, w, h, fill="#ffffff", stroke="#1e1e1e",
             gid=None, dashed=False, sw=2, radius=True):
        self.elements.append(dict(
            id=self._id(), type="rectangle", x=x, y=y, width=w, height=h, angle=0,
            strokeColor=stroke, backgroundColor=fill, fillStyle="solid", strokeWidth=sw,
            strokeStyle="dashed" if dashed else "solid", roughness=1, opacity=100,
            groupIds=[gid] if gid else [], frameId=None,
            roundness={"type": 3} if radius else None,
            seed=self._seed(), version=1, versionNonce=self._seed(), isDeleted=False,
            boundElements=[], updated=_TS, link=None, locked=False))

    def text(self, x, y, s, size=14, color="#1e1e1e", font=2, align="left",
             w=None, gid=None, wrap=False, h=None):
        # font: 1 hand-drawn, 2 normal, 3 code. wrap=True + fixed w => Excalidraw flows lines.
        lines = s.split("\n")
        if w is None:
            w = int(max(len(l) for l in lines) * size * 0.62) + 30
        if h is None:
            h = int(len(lines) * size * 1.25) + (size if wrap else 0)
        self.elements.append(dict(
            id=self._id(), type="text", x=x, y=y, width=w, height=h, angle=0,
            strokeColor=color, backgroundColor="transparent", fillStyle="solid",
            strokeWidth=1, strokeStyle="solid", roughness=1, opacity=100,
            groupIds=[gid] if gid else [], frameId=None, roundness=None,
            seed=self._seed(), version=1, versionNonce=self._seed(), isDeleted=False,
            boundElements=[], updated=_TS, link=None, locked=False, text=s, fontSize=size,
            fontFamily=font, textAlign=align, verticalAlign="top", containerId=None,
            originalText=s, autoResize=not wrap, lineHeight=1.25, baseline=int(size * 0.9)))

    def arrow(self, x1, y1, x2, y2, stroke="#1e1e1e"):
        dx, dy = x2 - x1, y2 - y1
        self.elements.append(dict(
            id=self._id(), type="arrow", x=x1, y=y1, width=abs(dx), height=abs(dy), angle=0,
            strokeColor=stroke, backgroundColor="transparent", fillStyle="solid", strokeWidth=2,
            strokeStyle="solid", roughness=1, opacity=100, groupIds=[], frameId=None,
            roundness={"type": 2}, seed=self._seed(), version=1, versionNonce=self._seed(),
            isDeleted=False, boundElements=[], updated=_TS, link=None, locked=False,
            points=[[0, 0], [dx, dy]], lastCommittedPoint=None, startBinding=None,
            endBinding=None, startArrowhead=None, endArrowhead="arrow"))

    def save(self, path, strict_dashes=False):
        if strict_dashes:
            bad = [e["text"] for e in self.elements
                   if e["type"] == "text" and ("—" in e["text"] or "–" in e["text"])]
            if bad:
                raise ValueError(f"em/en dashes in {len(bad)} text element(s); almog-voice forbids them")
        doc = dict(type="excalidraw", version=2, source="https://excalidraw.com",
                   elements=self.elements,
                   appState=dict(gridSize=None, viewBackgroundColor="#ffffff"), files={})
        with open(path, "w") as f:
            json.dump(doc, f, indent=2)
        return path
