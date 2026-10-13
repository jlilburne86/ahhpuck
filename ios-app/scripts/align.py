"""Per-band vertical/horizontal offset between a design reference and an app screenshot.

Usage: python align.py <design.png> <app.png> [band_pt=40]
For each horizontal band of the design (in points), finds the (dx, dy) shift of the app image
that best matches it. Non-zero offsets show where the app layout drifts from the design.
"""
import sys
from PIL import Image, ImageChops

ref, app = sys.argv[1:3]
band = int(sys.argv[3]) if len(sys.argv) > 3 else 40
a = Image.open(ref).convert("L").crop((3, 3, 1173, 2535)).resize((390, 844))
b = Image.open(app).convert("L").resize((390, 844))

def score(y0, y1, dx, dy):
    if y0 + dy < 0 or y1 + dy > 844: return 1e9
    ra = a.crop((10, y0, 380, y1)); rb = b.crop((10 + dx, y0 + dy, 380 + dx, y1 + dy))
    h = ImageChops.difference(ra, rb).histogram()
    return sum(i * n for i, n in enumerate(h)) / ((y1 - y0) * 370)

for y0 in range(0, 844, band):
    y1 = min(844, y0 + band)
    if a.crop((0, y0, 390, y1)).getextrema()[1] < 40: continue
    best = min(((score(y0, y1, dx, dy), dx, dy) for dx in range(-4, 5) for dy in range(-12, 13)))
    base = score(y0, y1, 0, 0)
    print(f"y {y0:3d}-{y1:3d}  best dx={best[1]:+d} dy={best[2]:+d}  diff {base:5.1f} -> {best[0]:5.1f}")
