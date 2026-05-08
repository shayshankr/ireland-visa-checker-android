from PIL import Image, ImageDraw, ImageFont

W, H = 1024, 500
GREEN = (22, 155, 98)
DARK_GREEN = (14, 110, 68)
WHITE = (255, 255, 255)
LIGHT = (180, 230, 205)

img = Image.new("RGB", (W, H), GREEN)
draw = ImageDraw.Draw(img)

# Subtle diagonal stripes
for i in range(-H, W, 60):
    draw.line([(i, 0), (i + H, H)], fill=DARK_GREEN, width=1)

# Left: icon with green background circle so transparency blends
circle_x, circle_y, circle_r = 190, 250, 140
draw.ellipse([circle_x - circle_r, circle_y - circle_r,
              circle_x + circle_r, circle_y + circle_r], fill=DARK_GREEN)

icon = Image.open("icon_512.png").convert("RGBA")
icon_size = 230
icon = icon.resize((icon_size, icon_size))
# Composite onto a green backing to avoid black corners
backing = Image.new("RGBA", (icon_size, icon_size), (*GREEN, 255))
composite = Image.alpha_composite(backing, icon).convert("RGB")
img.paste(composite, (circle_x - icon_size // 2, circle_y - icon_size // 2))

try:
    font_big = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 56)
    font_med = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 28)
    font_sm  = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 24)
except:
    font_big = font_med = font_sm = ImageFont.load_default()

tx = 380
draw.text((tx, 75),  "Ireland Visa Checker",              font=font_big, fill=WHITE)
draw.text((tx, 155), "Instant visa decision lookups for", font=font_med, fill=LIGHT)
draw.text((tx, 190), "5 Irish embassies worldwide",       font=font_med, fill=LIGHT)

embassies = ["New Delhi  (India)", "Beijing  (China)", "Abuja  (Nigeria)",
             "Abu Dhabi  (UAE)", "Ankara  (Türkiye)"]
y = 255
for e in embassies:
    draw.ellipse([tx, y + 7, tx + 10, y + 17], fill=WHITE)
    draw.text((tx + 20, y), e, font=font_sm, fill=WHITE)
    y += 36

draw.text((tx, 452), "Free  •  No login  •  Data sourced from ireland.ie",
          font=font_sm, fill=LIGHT)

img.save("feature_1024x500.png", "PNG")
print("Saved feature_1024x500.png")
