"""Generate launcher icons and native splash images from the church logo."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "app_logo.jpg"


def square_canvas(src: Image.Image, size: int, pad_ratio: float = 0.0) -> Image.Image:
    """Center the logo on a white square, optionally inset for adaptive-icon safe zone."""
    src = src.convert("RGB")
    side = max(src.size)
    base = Image.new("RGB", (side, side), (255, 255, 255))
    base.paste(src, ((side - src.width) // 2, (side - src.height) // 2))
    if pad_ratio > 0:
        inner = int(side * (1.0 - pad_ratio))
        padded = Image.new("RGB", (side, side), (255, 255, 255))
        resized = base.resize((inner, inner), Image.Resampling.LANCZOS)
        padded.paste(resized, ((side - inner) // 2, (side - inner) // 2))
        base = padded
    return base.resize((size, size), Image.Resampling.LANCZOS)


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def main() -> None:
    src = Image.open(SRC)
    master = square_canvas(src, 1024, pad_ratio=0.04)
    save_png(master, ROOT / "assets" / "images" / "app_logo.png")

    android_res = ROOT / "android" / "app" / "src" / "main" / "res"
    mipmaps = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    foregrounds = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    for folder, size in mipmaps.items():
        icon = square_canvas(src, size, pad_ratio=0.06)
        save_png(icon, android_res / folder / "ic_launcher.png")
        save_png(icon, android_res / folder / "ic_launcher_round.png")
    for folder, size in foregrounds.items():
        fg = square_canvas(src, size, pad_ratio=0.18)
        save_png(fg, android_res / folder / "ic_launcher_foreground.png")

    splash = square_canvas(src, 384, pad_ratio=0.04)
    save_png(splash, android_res / "drawable" / "splash_logo.png")
    save_png(splash, android_res / "drawable-v21" / "splash_logo.png")

    (android_res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (android_res / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
""",
        encoding="utf-8",
    )
    (android_res / "mipmap-anydpi-v26" / "ic_launcher_round.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
""",
        encoding="utf-8",
    )
    colors = android_res / "values" / "colors.xml"
    colors.parent.mkdir(parents=True, exist_ok=True)
    colors.write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
    <color name="splash_background">#FFFFFF</color>
</resources>
""",
        encoding="utf-8",
    )

    ios_icon = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-50x50@1x.png": 50,
        "Icon-App-50x50@2x.png": 100,
        "Icon-App-57x57@1x.png": 57,
        "Icon-App-57x57@2x.png": 114,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-72x72@1x.png": 72,
        "Icon-App-72x72@2x.png": 144,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in ios_sizes.items():
        save_png(square_canvas(src, size, pad_ratio=0.04), ios_icon / name)

    launch = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    save_png(square_canvas(src, 168, pad_ratio=0.0), launch / "LaunchImage.png")
    save_png(square_canvas(src, 336, pad_ratio=0.0), launch / "LaunchImage@2x.png")
    save_png(square_canvas(src, 504, pad_ratio=0.0), launch / "LaunchImage@3x.png")
    print("Generated launcher icons and splash images.")


if __name__ == "__main__":
    main()
