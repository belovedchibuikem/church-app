"""Slice SHEET E into 13 screen refs and unique photo crops."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

SRC = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_e.jpg")
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_e_boxes.json")

NAMES = [
    "e_01",  # Discover Churches (globe hero)
    "e_02",  # Church Detail
    "e_03",  # Live Service
    "e_04",  # Give
    "e_05",  # Sermons library
    "e_06",  # Prayer
    "e_07",  # Groups
    "e_08",  # Events
    "e_09",  # Notifications
    "e_10",  # Profile
    "e_11",  # Bible
    "e_12",  # Giving History
    "e_13",  # Settings
]

LABELS = [
    "discover_churches",
    "church_detail",
    "live_service",
    "give",
    "sermons_library",
    "prayer",
    "groups",
    "events",
    "notifications",
    "profile",
    "bible",
    "giving_history",
    "settings",
]

PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "multiply_home.png",
    "discover_globe.png",
    "nigeria_flag.png",
}


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


def _luma(pixel: tuple[int, int, int]) -> float:
    return (pixel[0] * 299 + pixel[1] * 587 + pixel[2] * 114) / 1000.0


def _runs(occ: list[int], thr: float, min_len: int) -> list[tuple[int, int]]:
    runs: list[tuple[int, int]] = []
    start: int | None = None
    for i, v in enumerate(occ):
        if v >= thr:
            if start is None:
                start = i
        elif start is not None:
            if i - start >= min_len:
                runs.append((start, i))
            start = None
    if start is not None and len(occ) - start >= min_len:
        runs.append((start, len(occ)))
    return runs


def _fit_runs(runs: list[tuple[int, int]], expect: int) -> list[tuple[int, int]]:
    runs = list(runs)
    while len(runs) > expect:
        # Merge the closest pair.
        gaps = [(runs[i + 1][0] - runs[i][1], i) for i in range(len(runs) - 1)]
        _, i = min(gaps)
        runs[i] = (runs[i][0], runs[i + 1][1])
        del runs[i + 1]
    while len(runs) < expect and runs:
        widths = [(r[1] - r[0], i) for i, r in enumerate(runs)]
        _, i = max(widths)
        a, b = runs[i]
        mid = (a + b) // 2
        runs[i : i + 1] = [(a, mid), (mid, b)]
    return runs[:expect]


def find_boxes(im: Image.Image) -> list[tuple[int, int, int, int]]:
    """Detect 7+6 phones. Brightness mask isolates light UI from navy canvas."""
    w, h = im.size
    rgb = im.convert("RGB")
    bg = rgb.getpixel((2, 2))
    bg_l = _luma(bg)
    scale = 2
    small = rgb.resize((w // scale, h // scale), Image.Resampling.BOX)
    sw, sh = small.size
    pixels = small.load()
    mask = [[0] * sw for _ in range(sh)]
    for y in range(sh):
        for x in range(sw):
            p = pixels[x, y]
            # Light UI, photos, and green heroes — not the navy gutters/canvas.
            if _luma(p) > bg_l + 22 or (not is_bg(p, bg, tol=14) and _luma(p) > 28):
                mask[y][x] = 1

    row_occ = [sum(mask[y]) for y in range(sh)]
    row_thr = max(max(row_occ) * 0.16 if row_occ else 0, sw * 0.08)
    bands = _fit_runs(_runs(row_occ, row_thr, min_len=max(20, sh // 8)), 2)
    if len(bands) < 2:
        print("no row bands; falling back to 7+6 grid")
        return _grid_7_6(w, h)[:13]

    boxes: list[tuple[int, int, int, int]] = []
    expects = (7, 6)
    for band, expect in zip(bands, expects):
        y1, y2 = band
        col_occ = [sum(mask[y][x] for y in range(y1, y2)) for x in range(sw)]
        col_thr = max(max(col_occ) * 0.18 if col_occ else 0, (y2 - y1) * 0.12)
        cols = _fit_runs(_runs(col_occ, col_thr, min_len=max(10, sw // 20)), expect)
        for x1, x2 in cols:
            # Expand slightly so dark bezels stay inside the crop.
            pad_x = max(1, int((x2 - x1) * 0.04))
            pad_y = max(2, int((y2 - y1) * 0.04))
            bx1 = max(0, x1 - pad_x) * scale
            by1 = max(0, y1 - pad_y) * scale
            bx2 = min(sw, x2 + pad_x) * scale
            by2 = min(sh, y2 + pad_y) * scale
            boxes.append((bx1, by1, bx2, by2))

    if len(boxes) < 13:
        print(f"occupancy found {len(boxes)}; falling back to 7+6 grid")
        boxes = _grid_7_6(w, h)

    boxes.sort(key=lambda b: (b[1] // 40, b[0]))
    cleaned: list[tuple[int, int, int, int]] = []
    for box in boxes:
        if any(_overlap(box, existing) > 0.5 for existing in cleaned):
            continue
        bw = box[2] - box[0]
        bh = box[3] - box[1]
        aspect = bh / max(bw, 1)
        if aspect < 1.4 or aspect > 2.8:
            continue
        cleaned.append(box)
    return cleaned[:13]


def _grid_7_6(w: int, h: int) -> list[tuple[int, int, int, int]]:
    mx, my = 6, 6
    gap = 6
    top_h = int(h * 0.455)
    bot_y = int(h * 0.505)
    bot_h = int(h * 0.445)
    boxes: list[tuple[int, int, int, int]] = []
    tw = (w - 2 * mx - 6 * gap) // 7
    for i in range(7):
        x1 = mx + i * (tw + gap)
        boxes.append((x1, my, min(w - 2, x1 + tw), my + top_h))
    bw = (w - 2 * mx - 5 * gap) // 6
    extra = (w - 2 * mx - 6 * bw - 5 * gap) // 2
    for i in range(6):
        x1 = mx + extra + i * (bw + gap)
        boxes.append((x1, bot_y, min(w - 2, x1 + bw), min(h - 8, bot_y + bot_h)))
    return boxes


def inset(box: tuple[int, int, int, int], pct: float = 0.035) -> tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    dx = int((x2 - x1) * pct)
    dy = int((y2 - y1) * pct)
    return x1 + dx, y1 + dy, x2 - dx, y2 - dy


def crop_rel(screen: Image.Image, l: float, t: float, r: float, b: float) -> Image.Image:
    w, h = screen.size
    return screen.crop((int(w * l), int(h * t), int(w * r), int(h * b)))


def save_png(path: Path, im: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"saved {path.name} {im.size}")


def should_write(path: Path, new_im: Image.Image) -> str:
    if path.name in PROTECTED and path.exists():
        return "skip-protected"
    if path.name == "profile_chibuikem.png" and path.exists():
        try:
            old = Image.open(path)
            ow, oh = old.size
            aspect = ow / max(oh, 1)
            # Keep an existing tight square-ish headshot.
            if 0.8 <= aspect <= 1.25 and min(ow, oh) >= 28:
                return "skip-existing-good"
        except OSError:
            pass
    return "write"


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
        "discover_hero_globe.png": (0, (0.62, 0.162, 0.98, 0.358)),
        "church_grace_hero.png": (1, (0.03, 0.085, 0.97, 0.305)),
        "live_pastor.png": (2, (0.0, 0.04, 1.0, 0.40)),
        "sermon_faith_mountains.png": (4, (0.03, 0.228, 0.97, 0.475)),
        "bible_votd.png": (10, (0.03, 0.175, 0.97, 0.42)),
        "giving_summary.png": (11, (0.03, 0.115, 0.97, 0.285)),
        "profile_chibuikem.png": (9, (0.385, 0.148, 0.615, 0.265)),
    }

    asset_meta = {}
    for name, (src_i, rect) in crop_plan.items():
        crop = crop_rel(screens[src_i], *rect)
        dest = OUT_IMAGES / name
        action = should_write(dest, crop)
        if action == "write":
            save_png(dest, crop)
            save_png(OUT_REFS / name, crop)
        else:
            print(f"asset {name} {crop.size} {action}")
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
            "action": action,
        }

    # Circular group avatars from the Groups list (4 visible rows).
    group_rect = (0.035, 0.175, 0.28, 0.82)
    group_strip = crop_rel(screens[6], *group_rect)
    save_png(OUT_IMAGES / "group_avatars.png", group_strip)
    save_png(OUT_REFS / "group_avatars.png", group_strip)
    sx1, sy1, sx2, sy2 = inset(boxes[6])
    l, t, r, b = group_rect
    abs_strip = (
        int(sx1 + (sx2 - sx1) * l),
        int(sy1 + (sy2 - sy1) * t),
        int(sx1 + (sx2 - sx1) * r),
        int(sy1 + (sy2 - sy1) * b),
    )
    asset_meta["group_avatars.png"] = {
        "screen": "e_07",
        "rel": list(group_rect),
        "box": list(abs_strip),
        "size": list(group_strip.size),
        "path": str(OUT_IMAGES / "group_avatars.png"),
        "action": "write",
    }

    avatar_names = [
        "group_avatar_young_adults.png",
        "group_avatar_women_of_grace.png",
        "group_avatar_men_of_valor.png",
        "group_avatar_bible_study.png",
    ]
    gw, gh = group_strip.size
    row_h = gh / len(avatar_names)
    side = min(gw, int(row_h * 0.92))
    for i, aname in enumerate(avatar_names):
        y0 = int(i * row_h + (row_h - side) / 2)
        x0 = max(0, (gw - side) // 2)
        piece = group_strip.crop((x0, y0, x0 + side, y0 + side))
        dest = OUT_IMAGES / aname
        save_png(dest, piece)
        save_png(OUT_REFS / aname, piece)
        asset_meta[aname] = {
            "screen": "e_07",
            "size": list(piece.size),
            "path": str(dest),
            "action": "write",
        }

    META.write_text(
        json.dumps(
            {
                "source": str(SRC),
                "size": list(im.size),
                "notes": (
                    "SHEET E contact sheet: 13 phones (7 top, 6 bottom). "
                    "Inner refs exclude 3.5% bezel. Unique crops: discover_hero_globe, "
                    "church_grace_hero, live_pastor, sermon_faith_mountains, group_avatars, "
                    "bible_votd, giving_summary; profile_chibuikem only if not already good. "
                    "Does not overwrite splash_map, fhc_logo, multiply_home, discover_globe, nigeria_flag."
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
