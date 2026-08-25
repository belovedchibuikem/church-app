"""Slice SHEET F into 13 screen refs and unique photo crops."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

SRC = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_f.jpg")
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_f_boxes.json")

PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "multiply_home.png",
    "discover_globe.png",
    "nigeria_flag.png",
    "otp_security.png",
}

NAMES = [
    "f_01",  # 14 Press Library (Kingdom Leadership)
    "f_02",  # 15 Give
    "f_03",  # 16 Prayer Personal/Church/Global
    "f_04",  # 17 Events
    "f_05",  # 18 Messages
    "f_06",  # 19 My Home Church
    "f_07",  # 20 Start a Church Progress step 2/5
    "f_08",  # 21 Crusade Detail Abuja
    "f_09",  # 22 Souls Follow-up
    "f_10",  # 23 KCA Leadership & Influence module 8
    "f_11",  # 24 My Assignments
    "f_12",  # 25 Mentor Chat Pastor John
    "f_13",  # 26 Notifications
]

LABELS = [
    "press_library",
    "give",
    "prayer",
    "events",
    "messages",
    "my_home_church",
    "start_church_progress",
    "crusade_detail_abuja",
    "souls_followup",
    "kca_leadership_module_8",
    "my_assignments",
    "mentor_chat_pastor_john",
    "notifications",
]


def is_bg(pixel: tuple[int, int, int], bg: tuple[int, int, int], tol: int = 18) -> bool:
    return all(abs(pixel[i] - bg[i]) <= tol for i in range(3))


def _overlap(a: tuple[int, int, int, int], b: tuple[int, int, int, int]) -> float:
    ax1, ay1, ax2, ay2 = a
    bx1, by1, bx2, by2 = b
    ix1, iy1 = max(ax1, bx1), max(ay1, by1)
    ix2, iy2 = min(ax2, bx2), min(ay2, by2)
    iw, ih = max(0, ix2 - ix1), max(0, iy2 - iy1)
    inter = iw * ih
    area = max((ax2 - ax1) * (ay2 - ay1), 1)
    return inter / area


def find_boxes(im: Image.Image) -> list[tuple[int, int, int, int]]:
    """Detect phone frames via occupancy bands (handles fused pairs + wide last phones)."""
    w, h = im.size
    rgb = im.convert("RGB")
    bg = rgb.getpixel((2, 2))
    scale = 4
    small = rgb.resize((w // scale, h // scale), Image.Resampling.BOX)
    sw, sh = small.size
    pixels = small.load()

    row_occ = [
        sum(0 if is_bg(pixels[x, y], bg) else 1 for x in range(sw)) for y in range(sh)
    ]
    bands: list[tuple[int, int]] = []
    in_band = False
    start = 0
    thresh = sw * 0.40
    for y, count in enumerate(row_occ):
        if count > thresh:
            if not in_band:
                start = y
                in_band = True
        elif in_band:
            if y - start > sh * 0.18:
                bands.append((start, y))
            in_band = False
    if in_band and sh - start > sh * 0.18:
        bands.append((start, sh))

    boxes: list[tuple[int, int, int, int]] = []
    for y1, y2 in bands:
        cols = [
            sum(0 if is_bg(pixels[x, y], bg) else 1 for y in range(y1, y2))
            for x in range(sw)
        ]
        peak = max(cols) or 1
        runs: list[tuple[int, int]] = []
        in_run = False
        rx = 0
        for x, count in enumerate(cols):
            if count > peak * 0.25:
                if not in_run:
                    rx = x
                    in_run = True
            elif in_run:
                runs.append((rx, x))
                in_run = False
        if in_run:
            runs.append((rx, sw))

        widths = [r[1] - r[0] for r in runs]
        min_w = min(widths) if widths else 1
        split_runs: list[tuple[int, int]] = []
        for x1, x2 in runs:
            # Fused pairs are ~2x the narrowest phone; trailing phones are only ~1.4x.
            # Split at the geometric midpoint — occupancy gutters fail when a dark
            # hero (Abuja crusade night photo) matches the navy canvas.
            if (x2 - x1) > min_w * 1.7:
                mid = (x1 + x2) // 2
                split_runs.append((x1, mid))
                split_runs.append((mid + 1, x2))
            else:
                split_runs.append((x1, x2))

        for x1, x2 in split_runs:
            boxes.append((x1 * scale, y1 * scale, x2 * scale, y2 * scale))

    boxes.sort(key=lambda b: (b[1] // 40, b[0]))
    cleaned: list[tuple[int, int, int, int]] = []
    for box in boxes:
        if any(_overlap(box, existing) > 0.5 for existing in cleaned):
            continue
        bw = box[2] - box[0]
        bh = box[3] - box[1]
        aspect = bh / max(bw, 1)
        if aspect < 0.98 or aspect > 2.6:
            continue
        cleaned.append(box)
    return cleaned[:13]


def _split_wide(
    box: tuple[int, int, int, int],
    small: Image.Image,
    scale: int,
    pixels,
    bg: tuple[int, int, int],
) -> list[tuple[int, int, int, int]]:
    x1, y1, x2, y2 = box
    bw, bh = x2 - x1, y2 - y1
    aspect = bh / max(bw, 1)
    if aspect >= 1.4:
        return [box]
    sx1, sy1 = x1 // scale, y1 // scale
    sx2, sy2 = max(x2 // scale, sx1 + 1), max(y2 // scale, sy1 + 1)
    occ: list[tuple[int, int]] = []
    for x in range(sx1, sx2):
        count = sum(0 if is_bg(pixels[x, y], bg) else 1 for y in range(sy1, sy2))
        occ.append((x, count))
    if not occ:
        return [box]
    peak = max(c for _, c in occ) or 1
    inner = occ[int(len(occ) * 0.18) : int(len(occ) * 0.82)]
    if not inner:
        return [box]
    gutter_x, gutter_c = min(inner, key=lambda t: t[1])
    if gutter_c > peak * 0.55:
        return [box]
    mid = gutter_x * scale
    left = (x1, y1, mid, y2)
    right = (mid + scale, y1, x2, y2)
    if (left[2] - left[0]) < 80 or (right[2] - right[0]) < 80:
        return [box]
    return [left, right]


def inset(box: tuple[int, int, int, int], pct: float = 0.035) -> tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    dx = int((x2 - x1) * pct)
    dy = int((y2 - y1) * pct)
    return x1 + dx, y1 + dy, x2 - dx, y2 - dy


def crop_rel(screen: Image.Image, l: float, t: float, r: float, b: float) -> Image.Image:
    w, h = screen.size
    return screen.crop((int(w * l), int(h * t), int(w * r), int(h * b)))


def save_png(path: Path, im: Image.Image) -> None:
    if path.name in PROTECTED and path.exists():
        print(f"skip-protected {path.name}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"saved {path.name} {im.size}")


def main() -> None:
    OUT_REFS.mkdir(parents=True, exist_ok=True)
    OUT_IMAGES.mkdir(parents=True, exist_ok=True)
    im = Image.open(SRC).convert("RGB")
    print(f"source {im.size}")
    boxes = find_boxes(im)
    print(f"found {len(boxes)} screens")
    for i, box in enumerate(boxes):
        print(f"  box {i+1:02d} {box} {box[2]-box[0]}x{box[3]-box[1]}")

    if len(boxes) < 13:
        raise SystemExit(f"expected 13 screens, got {len(boxes)}")

    screens: list[Image.Image] = []
    screen_meta = []
    for i, box in enumerate(boxes):
        name = NAMES[i]
        inner = inset(box)
        frame = im.crop(box)
        content = im.crop(inner)
        save_png(OUT_REFS / f"{name}_frame.png", frame)
        save_png(OUT_REFS / f"{name}.png", content)
        screens.append(content)
        screen_meta.append(
            {
                "name": name,
                "label": LABELS[i],
                "box": list(box),
                "inner": list(inner),
            }
        )

    # Unique crops relative to inner screens (tuned after visual inspection).
    crop_plan = {
        # Press Library featured banner: 3D book on the right.
        "book_kingdom_leadership.png": (0, (0.56, 0.195, 0.98, 0.455)),
        # My Home Church card: building thumbnail only.
        "grace_home_church.png": (5, (0.035, 0.105, 0.30, 0.265)),
        # Crusade detail hero photo (exclude title below).
        "abuja_crusade.png": (7, (0.03, 0.085, 0.97, 0.295)),
        # Mentor chat header: circular avatar only (exclude name/status).
        "pastor_john_avatar.png": (11, (0.105, 0.038, 0.215, 0.158)),
    }

    asset_meta = {}
    for name, (src_i, rect) in crop_plan.items():
        crop = crop_rel(screens[src_i], *rect)
        dest = OUT_IMAGES / name
        save_png(dest, crop)
        save_png(OUT_REFS / name, crop)
        sx1, sy1, sx2, sy2 = inset(boxes[src_i])
        l, t, r, b = rect
        abs_box = (
            int(sx1 + (sx2 - sx1) * l),
            int(sy1 + (sy2 - sy1) * t),
            int(sx1 + (sx2 - sx1) * r),
            int(sy1 + (sy2 - sy1) * b),
        )
        asset_meta[name] = {
            "screen": NAMES[src_i],
            "rel": list(rect),
            "box": list(abs_box),
            "size": list(crop.size),
            "path": str(dest),
        }

    META.write_text(
        json.dumps(
            {
                "source": str(SRC),
                "size": list(im.size),
                "notes": (
                    "SHEET F contact sheet: 13 phones numbered 14-26 "
                    "(7 top, 6 bottom). Inner refs exclude 3.5% bezel. "
                    "Unique crops: book_kingdom_leadership, grace_home_church, "
                    "abuja_crusade, pastor_john_avatar."
                ),
                "screens": screen_meta,
                "assets": asset_meta,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"wrote {META}")


if __name__ == "__main__":
    main()
