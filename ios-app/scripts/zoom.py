"""Zoomed side-by-side of one region: python zoom.py <design.png> <app.png> <out.png> <y0_pt> <y1_pt> [x0_pt x1_pt]"""
import sys
from PIL import Image
ref, app, out = sys.argv[1:4]
y0, y1 = int(sys.argv[4]) * 3, int(sys.argv[5]) * 3
x0, x1 = (int(sys.argv[6]) * 3, int(sys.argv[7]) * 3) if len(sys.argv) > 7 else (0, 1170)
a = Image.open(ref).convert("RGB").crop((3, 3, 1173, 2535)).crop((x0, y0, x1, y1))
b = Image.open(app).convert("RGB").resize((1170, 2532)).crop((x0, y0, x1, y1))
w = Image.new("RGB", (a.width, a.height * 2 + 12), (255, 0, 255))
w.paste(a, (0, 0)); w.paste(b, (0, a.height + 12))
w.save(out)
