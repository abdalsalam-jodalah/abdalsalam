# tool/generate_app_icon.py — renders the app icon and writes every platform's icon assets.
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

PROJECT_ROOT = Path(__file__).resolve().parent.parent
MASTER_SIZE = 1024
SUPERSAMPLE = 4

BACKGROUND_TOP = (24, 28, 58)
BACKGROUND_BOTTOM = (10, 13, 30)
ADAPTIVE_BACKGROUND_HEX = "#0F1226"

TILE_COLORS = {
    "top_left": ((167, 139, 250), (124, 58, 237)),
    "top_right": ((96, 165, 250), (37, 99, 235)),
    "bottom_left": ((52, 211, 153), (5, 150, 105)),
    "bottom_right": ((251, 146, 60), (234, 88, 12)),
}

EMBLEM_RADIUS_RATIO = 0.31
TILE_GAP_RATIO = 0.035
TILE_INNER_CORNER_RATIO = 0.07
TILE_EDGE_SOFTENING_RATIO = 0.012
MASK_THRESHOLD = 128
LEGACY_CORNER_RATIO = 0.22
MACOS_CONTENT_RATIO = 0.80
MACOS_CORNER_RATIO = 0.225
ADAPTIVE_EMBLEM_SCALE = 1.0
MASKABLE_EMBLEM_SCALE = 0.92

ANDROID_LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
ANDROID_ADAPTIVE_SIZES = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}
MACOS_SIZES = (16, 32, 64, 128, 256, 512, 1024)
WEB_SIZES = (192, 512)
WINDOWS_ICO_SIZES = (16, 24, 32, 48, 64, 128, 256)
IOS_FILENAME_PATTERN = "Icon-App-{base}x{base}@{scale}x.png"

ADAPTIVE_ICON_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""
ADAPTIVE_BACKGROUND_XML = f"""<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">{ADAPTIVE_BACKGROUND_HEX}</color>
</resources>
"""


def build_background(size):
    gradient = Image.new("RGB", (1, size))
    for row in range(size):
        blend = row / (size - 1)
        gradient.putpixel(
            (0, row),
            tuple(
                round(top + (bottom - top) * blend)
                for top, bottom in zip(BACKGROUND_TOP, BACKGROUND_BOTTOM)
            ),
        )
    return gradient.resize((size, size)).convert("RGBA")


def build_diagonal_gradient(size, start, end):
    vertical = Image.linear_gradient("L").resize((size, size))
    horizontal = vertical.transpose(Image.TRANSPOSE)
    blend = ImageChops.add(vertical, horizontal, scale=2)
    return Image.composite(
        Image.new("RGB", (size, size), end),
        Image.new("RGB", (size, size), start),
        blend,
    ).convert("RGBA")


def build_tile_mask(size, quadrant, radius, gap, inner_corner):
    center = size / 2
    half_gap = gap / 2
    left, right = (center + half_gap, center + radius) if "right" in quadrant else (center - radius, center - half_gap)
    top, bottom = (center + half_gap, center + radius) if "bottom" in quadrant else (center - radius, center - half_gap)

    tile = Image.new("L", (size, size), 0)
    ImageDraw.Draw(tile).rounded_rectangle(
        (left, top, right, bottom), radius=inner_corner, fill=255
    )
    disc = Image.new("L", (size, size), 0)
    ImageDraw.Draw(disc).ellipse(
        (center - radius, center - radius, center + radius, center + radius), fill=255
    )
    shaped = ImageChops.multiply(tile, disc)
    softened = shaped.filter(ImageFilter.GaussianBlur(size * TILE_EDGE_SOFTENING_RATIO))
    return softened.point(lambda value: 255 if value >= MASK_THRESHOLD else 0)


def build_emblem(size, scale=1.0):
    radius = size * EMBLEM_RADIUS_RATIO * scale
    gap = size * TILE_GAP_RATIO * scale
    inner_corner = size * TILE_INNER_CORNER_RATIO * scale
    emblem = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for quadrant, (start, end) in TILE_COLORS.items():
        mask = build_tile_mask(size, quadrant, radius, gap, inner_corner)
        emblem.paste(build_diagonal_gradient(size, start, end), (0, 0), mask)
    return emblem


def build_rounded_mask(size, corner_ratio):
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=size * corner_ratio, fill=255
    )
    return mask


def render_full_bleed(size, emblem_scale=1.0):
    canvas = size * SUPERSAMPLE
    icon = build_background(canvas)
    icon.alpha_composite(build_emblem(canvas, emblem_scale))
    return icon.resize((size, size), Image.LANCZOS)


def render_foreground(size):
    canvas = size * SUPERSAMPLE
    emblem = build_emblem(canvas, ADAPTIVE_EMBLEM_SCALE)
    return emblem.resize((size, size), Image.LANCZOS)


def render_rounded(size, corner_ratio):
    icon = render_full_bleed(size)
    icon.putalpha(build_rounded_mask(size * SUPERSAMPLE, corner_ratio).resize((size, size), Image.LANCZOS))
    return icon


def render_macos(size):
    content = round(size * MACOS_CONTENT_RATIO)
    tile = render_rounded(content, MACOS_CORNER_RATIO)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = (size - content) // 2
    canvas.alpha_composite(tile, (offset, offset))
    return canvas


def write_png(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def write_ios():
    target = PROJECT_ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for existing in target.glob("Icon-App-*.png"):
        stem = existing.stem.removeprefix("Icon-App-")
        base_text, scale_text = stem.split("@")
        pixels = round(float(base_text.split("x")[0]) * int(scale_text.removesuffix("x")))
        write_png(render_full_bleed(pixels).convert("RGB"), existing)


def write_android():
    resources = PROJECT_ROOT / "android/app/src/main/res"
    for density, pixels in ANDROID_LEGACY_SIZES.items():
        write_png(render_rounded(pixels, LEGACY_CORNER_RATIO), resources / density / "ic_launcher.png")
    for density, pixels in ANDROID_ADAPTIVE_SIZES.items():
        write_png(render_foreground(pixels), resources / density / "ic_launcher_foreground.png")
    adaptive_directory = resources / "mipmap-anydpi-v26"
    adaptive_directory.mkdir(parents=True, exist_ok=True)
    (adaptive_directory / "ic_launcher.xml").write_text(ADAPTIVE_ICON_XML)
    (resources / "values/ic_launcher_background.xml").write_text(ADAPTIVE_BACKGROUND_XML)


def write_macos():
    target = PROJECT_ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for pixels in MACOS_SIZES:
        write_png(render_macos(pixels), target / f"app_icon_{pixels}.png")


def write_web():
    target = PROJECT_ROOT / "web"
    for pixels in WEB_SIZES:
        write_png(render_full_bleed(pixels).convert("RGB"), target / f"icons/Icon-{pixels}.png")
        write_png(
            render_full_bleed(pixels, MASKABLE_EMBLEM_SCALE).convert("RGB"),
            target / f"icons/Icon-maskable-{pixels}.png",
        )
    write_png(render_rounded(32, LEGACY_CORNER_RATIO), target / "favicon.png")


def write_windows():
    target = PROJECT_ROOT / "windows/runner/resources/app_icon.ico"
    render_rounded(256, LEGACY_CORNER_RATIO).save(
        target, format="ICO", sizes=[(pixels, pixels) for pixels in WINDOWS_ICO_SIZES]
    )


def write_preview(path):
    sheet = Image.new("RGBA", (1600, 720), (236, 238, 244, 255))
    sheet.alpha_composite(render_rounded(640, LEGACY_CORNER_RATIO), (40, 40))
    sheet.alpha_composite(render_macos(512), (720, 20))
    for index, pixels in enumerate((120, 60, 40)):
        sheet.alpha_composite(render_rounded(pixels, LEGACY_CORNER_RATIO), (1260, 40 + index * 200))
    sheet.save(path)


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "--preview":
        write_preview(Path(sys.argv[2]))
        return
    write_ios()
    write_android()
    write_macos()
    write_web()
    write_windows()


if __name__ == "__main__":
    main()
