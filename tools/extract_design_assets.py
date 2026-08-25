"""Slice the Family House Connect design composite into screen refs and photo assets."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageFilter, ImageOps, ImageStat

SRC = Path(
    r"c:\wamp64\www\church\mobile\artifacts\design_source.jpg"
)
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
NAMES = [
    "01_splash",
    "02_onboarding_discover",
    "03_onboarding_connect",
    "04_onboarding_multiply",
    "05_language_location",
    "06_sign_in",
    "07_verify_phone",
    "08_two_factor",
    "09_role_selection",
    "10_module_hub",
    "11_church_dashboard",
    "12_kca_dashboard",
    "13_mission_dashboard",
]


def is_bg(pixel: tuple[int, int, int], bg: tuple[int, int, int], tol: int = 18) -> bool:
    return all(abs(pixel[i] - bg[i]) <= tol for i in range(3))


def find_boxes(im: Image.Image) -> list[tuple[int, int, int, int]]:
    w, h = im.size
    rgb = im.convert("RGB")
    bg = rgb.getpixel((2, 2))
    # Downscale for speed
    scale = 4
    small = rgb.resize((w // scale, h // scale), Image.Resampling.BOX)
    sw, sh = small.size
    pixels = small.load()
    mask = [[0] * sw for _ in range(sh)]
    for y in range(sh):
        for x in range(sw):
            mask[y][x] = 0 if is_bg(pixels[x, y], bg) else 1

    visited = [[False] * sw for _ in range(sh)]
    boxes: list[tuple[int, int, int, int]] = []
    for y in range(sh):
        for x in range(sw):
            if mask[y][x] == 0 or visited[y][x]:
                continue
            stack = [(x, y)]
            visited[y][x] = True
            minx = maxx = x
            miny = maxy = y
            count = 0
            while stack:
                cx, cy = stack.pop()
                count += 1
                minx = min(minx, cx)
                maxx = max(maxx, cx)
                miny = min(miny, cy)
                maxy = max(maxy, cy)
                for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                    if 0 <= nx < sw and 0 <= ny < sh and not visited[ny][nx] and mask[ny][nx]:
                        visited[ny][nx] = True
                        stack.append((nx, ny))
            bw = maxx - minx + 1
            bh = maxy - miny + 1
            if count < 400 or bh < sh * 0.18 or bw < sw * 0.08:
                continue
            aspect = bh / max(bw, 1)
            if aspect < 1.4 or aspect > 2.6:
                continue
            boxes.append(
                (
                    minx * scale,
                    miny * scale,
                    (maxx + 1) * scale,
                    (maxy + 1) * scale,
                )
            )

    boxes.sort(key=lambda b: (b[1] // 40, b[0]))
    # Deduplicate overlapping boxes
    cleaned: list[tuple[int, int, int, int]] = []
    for box in boxes:
        if any(_overlap(box, existing) > 0.5 for existing in cleaned):
            continue
        cleaned.append(box)
    return cleaned[:13]


def _overlap(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> float:
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    ix1, iy1 = max(ax1, bx1), max(ay1, by1)
    ix2, iy2 = min(ax2, bx2), min(ay2, by2)
    iw, ih = max(0, ix2 - ix1), max(0, iy2 - iy1)
    inter = iw * ih
    area = max((ax2 - ax1) * (ay2 - ay1), 1)
    return inter / area


def inset(box: tuple[int, int, int, int], pct: float = 0.03) -> tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    dx = int((x2 - x1) * pct)
    dy = int((y2 - y1) * pct)
    return x1 + dx, y1 + dy, x2 - dx, y2 - dy


def crop_rel(
    screen: Image.Image, l: float, t: float, r: float, b: float
) -> Image.Image:
    w, h = screen.size
    return screen.crop((int(w * l), int(h * t), int(w * r), int(h * b)))


def main() -> None:
    OUT_REFS.mkdir(parents=True, exist_ok=True)
    OUT_IMAGES.mkdir(parents=True, exist_ok=True)
    im = Image.open(SRC).convert("RGB")
    print(f"source {im.size}")
    boxes = find_boxes(im)
    print(f"found {len(boxes)} screens")
    screens: list[Image.Image] = []
    for i, box in enumerate(boxes):
        name = NAMES[i] if i < len(NAMES) else f"screen_{i+1:02d}"
        frame = im.crop(box)
        inner = im.crop(inset(box, 0.035))
        frame.save(OUT_REFS / f"{name}_frame.png")
        inner.save(OUT_REFS / f"{name}.png")
        screens.append(inner)
        print(f"saved {name} {inner.size}")

    if len(screens) < 13:
        raise SystemExit(f"expected 13 screens, got {len(screens)}")

    splash, discover, connect, multiply, language, sign_in, otp, tfa, role, hub, church, kca, mission = screens

    # Relative rects tuned against the sliced inner screens (not mostly padding/text).
    crop_rects = {
        "splash_map.png": (0.0, 0.055, 1.0, 0.26),
        "fhc_logo.png": (0.30, 0.28, 0.70, 0.44),
        "discover_globe.png": (0.05, 0.31, 0.95, 0.56),
        "connect_people.png": (0.0, 0.34, 1.0, 0.535),
        "multiply_home.png": (0.0, 0.38, 1.0, 0.70),
        "otp_security.png": (0.12, 0.30, 0.90, 0.56),
        "security_shield.png": (0.30, 0.26, 0.70, 0.46),
        "member_avatar.png": (0.04, 0.08, 0.16, 0.16),
        "church_live.png": (0.55, 0.18, 0.94, 0.36),
        "lesson_book.png": (0.65, 0.68, 0.88, 0.82),
        "nigeria_flag.png": (0.10, 0.79, 0.24, 0.86),
    }
    crop_sources = {
        "splash_map.png": 0,
        "fhc_logo.png": 0,
        "discover_globe.png": 1,
        "connect_people.png": 2,
        "multiply_home.png": 3,
        "nigeria_flag.png": 4,
        "otp_security.png": 6,
        "security_shield.png": 7,
        "church_live.png": 10,
        "member_avatar.png": 11,
        "lesson_book.png": 11,
    }
    crops = {name: crop_rel(screens[crop_sources[name]], *rect) for name, rect in crop_rects.items()}
    asset_meta = {}
    for name, crop in crops.items():
        crop = crop.convert("RGB")
        crop.save(OUT_IMAGES / name, format="PNG", optimize=True)
        src_i = crop_sources[name]
        sx1, sy1, sx2, sy2 = inset(boxes[src_i], 0.035)
        l, t, r, b = crop_rects[name]
        abs_box = (
            int(sx1 + (sx2 - sx1) * l),
            int(sy1 + (sy2 - sy1) * t),
            int(sx1 + (sx2 - sx1) * r),
            int(sy1 + (sy2 - sy1) * b),
        )
        asset_meta[name] = {
            "screen": NAMES[src_i],
            "rel": list(crop_rects[name]),
            "box": list(abs_box),
            "size": list(crop.size),
        }
        print(f"asset {name} {crop.size}")

    Path(r"c:\wamp64\www\church\mobile\artifacts\design_boxes.json").write_text(
        json.dumps(
            {
                "size": list(im.size),
                "notes": (
                    "Source is a 1024x682 ChatGPT contact sheet (7 phones on top, "
                    "6 below). Inner refs exclude a 3.5% bezel inset. Asset crops "
                    "are relative to those inner screens."
                ),
                "boxes": [list(b) for b in boxes],
                "screens": [
                    {"name": NAMES[i], "box": list(boxes[i]), "inner": list(inset(boxes[i], 0.035))}
                    for i in range(len(boxes))
                ],
                "assets": asset_meta,
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    # Full-screen refs also copied as fallback bitmaps
    for i, screen in enumerate(screens):
        screen.save(OUT_IMAGES / f"ref_{NAMES[i]}.png")


if __name__ == "__main__":
    main()
