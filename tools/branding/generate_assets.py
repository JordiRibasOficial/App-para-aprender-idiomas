#!/usr/bin/env python3
"""Generates a first-pass app icon and Play Store feature graphic.

Placeholder brand mark, not a professional logo: a globe emblem matching the
in-app Icons.language motif, on the app's seed color (see AppTheme._seed).
Supersamples at 4x and downsamples with LANCZOS for anti-aliased edges since
PIL's ImageDraw does not antialias by default.
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

SEED = (0x3D, 0x5A, 0xFE)  # AppTheme._seed, #3D5AFE
SEED_DARK = (0x24, 0x33, 0xB8)  # darker shade for gradient depth
WHITE = (255, 255, 255, 255)

SCALE = 4  # supersampling factor
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "src", "mobile", "assets", "branding")
DEJAVU_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
DEJAVU_REGULAR = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def diagonal_gradient(size):
    """Top-left (light) to bottom-right (dark) diagonal gradient."""
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            r, g, b = lerp(SEED, SEED_DARK, t)
            px[x, y] = (r, g, b, 255)
    return img


def draw_globe(draw, cx, cy, radius, stroke_width, color):
    bbox = [cx - radius, cy - radius, cx + radius, cy + radius]
    draw.ellipse(bbox, outline=color, width=stroke_width)
    draw.line([cx - radius, cy, cx + radius, cy], fill=color, width=stroke_width)
    meridian_bbox = [cx - radius * 0.42, cy - radius, cx + radius * 0.42, cy + radius]
    draw.ellipse(meridian_bbox, outline=color, width=stroke_width)


def make_icon(full_bleed: bool, size=1024):
    canvas = size * SCALE
    img = diagonal_gradient(canvas) if full_bleed else Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx = cy = canvas // 2
    # Full-bleed icon: globe fills most of the square (iOS/legacy Android mask
    # their own corners). Foreground layer: globe stays inside the adaptive
    # icon safe zone (~66% of the canvas) so it survives circle/squircle masks.
    radius = canvas * 0.30 if full_bleed else canvas * 0.24
    stroke = max(1, round(radius * 0.11))
    draw_globe(draw, cx, cy, radius, stroke, WHITE)

    img = img.resize((size, size), Image.LANCZOS)
    return img


def make_feature_graphic(width=1024, height=500):
    canvas_w, canvas_h = width * SCALE, height * SCALE
    img = Image.new("RGBA", (canvas_w, canvas_h))
    px = img.load()
    for y in range(canvas_h):
        for x in range(canvas_w):
            t = (x + y) / (canvas_w + canvas_h)
            r, g, b = lerp(SEED, SEED_DARK, t)
            px[x, y] = (r, g, b, 255)

    draw = ImageDraw.Draw(img)

    margin = canvas_h * 0.14
    globe_cx = canvas_h * 0.5
    globe_cy = canvas_h * 0.5
    globe_r = canvas_h * 0.28
    draw_globe(draw, globe_cx, globe_cy, globe_r, max(1, round(globe_r * 0.11)), WHITE)

    text_x = canvas_h * 1.05
    available_w = canvas_w - text_x - margin

    title = "App para Aprender Idiomas"
    subtitle = "Inglés, portugués, francés y japonés"

    title_size = round(canvas_h * 0.135)
    title_font = ImageFont.truetype(DEJAVU_BOLD, title_size)
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    while title_bbox[2] - title_bbox[0] > available_w and title_size > 10:
        title_size -= 2
        title_font = ImageFont.truetype(DEJAVU_BOLD, title_size)
        title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_h = title_bbox[3] - title_bbox[1]

    subtitle_size = round(title_size * 0.42)
    subtitle_font = ImageFont.truetype(DEJAVU_REGULAR, subtitle_size)
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    while subtitle_bbox[2] - subtitle_bbox[0] > available_w and subtitle_size > 8:
        subtitle_size -= 2
        subtitle_font = ImageFont.truetype(DEJAVU_REGULAR, subtitle_size)
        subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)

    gap = canvas_h * 0.05
    block_h = title_h + gap + (subtitle_bbox[3] - subtitle_bbox[1])
    start_y = (canvas_h - block_h) / 2

    draw.text((text_x, start_y - title_bbox[1]), title, font=title_font, fill=WHITE)
    draw.text(
        (text_x, start_y + title_h + gap - subtitle_bbox[1]),
        subtitle,
        font=subtitle_font,
        fill=(255, 255, 255, 220),
    )

    img = img.resize((width, height), Image.LANCZOS)
    return img.convert("RGB")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    icon = make_icon(full_bleed=True)
    icon.save(os.path.join(OUT_DIR, "icon_1024.png"))

    foreground = make_icon(full_bleed=False)
    foreground.save(os.path.join(OUT_DIR, "icon_foreground_1024.png"))

    feature = make_feature_graphic()
    feature.save(os.path.join(OUT_DIR, "feature_graphic_1024x500.png"))

    print(f"Wrote assets to {os.path.abspath(OUT_DIR)}")


if __name__ == "__main__":
    main()
