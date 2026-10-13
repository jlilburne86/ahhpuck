"""Side-by-side + difference image of a design reference and an app screenshot.

Usage: python compare.py <design.png> <app.png> <out.png>
The design reference is the rendered 390×844 phone frame (with its 1 px border) at 3×;
the app screenshot is an iPhone 16e (1170×2532). Output: design | app | diff (brighter = more different),
and prints the mean absolute difference per channel (0–255).
"""
import sys
from PIL import Image, ImageChops, ImageOps

ref, app, out = sys.argv[1:4]
a = Image.open(ref).convert("RGB")
b = Image.open(app).convert("RGB")
# Strip the 1 px (3 device px) frame border; keep the 390×844 inner area.
a = a.crop((3, 3, 3 + 1170, 3 + 2532))
b = b.resize((1170, 2532))
d = ImageChops.difference(a, b)
stat = [sum(i * n for i, n in enumerate(d.histogram()[c * 256:(c + 1) * 256])) / (1170 * 2532) for c in range(3)]
d = ImageOps.autocontrast(d.convert("L"))
w = Image.new("RGB", (1170 * 3 + 40, 2532), (255, 0, 255))
w.paste(a, (0, 0)); w.paste(b, (1190, 0)); w.paste(d.convert("RGB"), (2380, 0))
w = w.resize((w.width // 3, w.height // 3))
w.save(out)
print("mean abs diff (RGB):", ", ".join(f"{x:.2f}" for x in stat))
