from PIL import Image, ImageDraw, ImageFont
import math

SIZE = 512
PADDING = 64
GREEN = (22, 155, 98)       # Ireland green
DARK_GREEN = (14, 110, 68)
WHITE = (255, 255, 255)

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Rounded rectangle background
radius = 96
draw.rounded_rectangle([0, 0, SIZE, SIZE], radius=radius, fill=GREEN)

# --- Draw a document shape ---
doc_x1, doc_y1 = 148, 100
doc_x2, doc_y2 = 364, 380
corner = 18
draw.rounded_rectangle([doc_x1, doc_y1, doc_x2, doc_y2], radius=corner, fill=WHITE)

# Folded corner (top-right)
fold = 52
points = [doc_x2 - fold, doc_y1, doc_x2, doc_y1 + fold, doc_x2 - fold, doc_y1 + fold]
draw.polygon(points, fill=GREEN)
draw.line([doc_x2 - fold, doc_y1, doc_x2 - fold, doc_y1 + fold, doc_x2, doc_y1 + fold], fill=DARK_GREEN, width=3)

# Lines on document
line_color = (180, 220, 200)
lx1, lx2 = doc_x1 + 28, doc_x2 - 28
for y in [175, 205, 235, 265, 295]:
    w = lx2 if y < 230 else lx1 + int((lx2 - lx1) * 0.6)
    draw.rounded_rectangle([lx1, y, w, y + 10], radius=5, fill=line_color)

# --- Green checkmark circle (bottom right) ---
cx, cy, cr = 352, 352, 68
draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=DARK_GREEN)
draw.ellipse([cx - cr + 5, cy - cr + 5, cx + cr - 5, cy + cr - 5], fill=(26, 180, 110))

# Checkmark
ck_pts = [
    (cx - 32, cy),
    (cx - 10, cy + 26),
    (cx + 34, cy - 28),
]
draw.line([ck_pts[0], ck_pts[1]], fill=WHITE, width=10)
draw.line([ck_pts[1], ck_pts[2]], fill=WHITE, width=10)
# Round line caps
for pt in ck_pts:
    r = 5
    draw.ellipse([pt[0]-r, pt[1]-r, pt[0]+r, pt[1]+r], fill=WHITE)

img = img.convert("RGB")
img.save("icon_512.png", "PNG")
print("Saved icon_512.png")
