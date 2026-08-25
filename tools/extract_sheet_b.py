"""Slice Family House Connect SHEET B (screens 13-25) into refs and photo crops."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

SRC = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_b.jpg")
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
OUT_META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_b_boxes.json")

NAMES = [
    "b_01",  # 13 dark modules
    "b_02",  # 14 church admin dash
    "b_03",  # 15 mission dash
    "b_04",  # 16 KCA modules
    "b_05",  # 17 KCA module content
    "b_06",  # 18 book detail
    "b_07",  # 19 events
    "b_08",  # 20 prayer form
    "b_09",  # 21 live fellowship
    "b_10",  # 22 give
    "b_11",  # 23 notifications
    "b_12",  # 24 profile
    "b_13",  # 25 settings
]

LABELS = [
    "dark_modules",
    "church_admin_dash",
    "mission_dash",
    "kca_modules",
    "kca_module_content",
    "book_detail",
    "events",
    "prayer_form",
    "live_fellowship",
    "give",
    "notifications",
    "profile",
    "settings",
]

PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "discover_globe.png",
    "connect_people.png",
    "multiply_home.png",
    "otp_security.png",
    "security_shield.png",
    "member_avatar.png",
    "church_live.png",
    "lesson_book.png",
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


def _median(vals: list[int]) -> int:
    s = sorted(vals)
    return s[len(s) // 2]


def _fill_row_gaps(
    row: list[tuple[int, int, int, int]], sheet_w: int
) -> list[tuple[int, int, int, int]]:
    if len(row) < 2:
        return row
    row = sorted(row, key=lambda b: b[0])
    widths = [b[2] - b[0] for b in row]
    heights = [b[3] - b[1] for b in row]
    med_w = _median(widths)
    med_h = _median(heights)
    y1 = _median([b[1] for b in row])
    y2 = y1 + med_h
    gaps = [row[i + 1][0] - row[i][2] for i in range(len(row) - 1)]
    pos_gaps = [g for g in gaps if 0 < g < med_w]
    pad = _median(pos_gaps) if pos_gaps else 8

    filled: list[tuple[int, int, int, int]] = []
    if row[0][0] > med_w * 0.55:
        nx2 = row[0][0] - pad
        nx1 = max(4, nx2 - med_w)
        filled.append((nx1, y1, nx2, y2))
    filled.append(row[0])
    for i in range(len(row) - 1):
        x = filled[-1][2]
        while row[i + 1][0] - x > med_w * 0.7:
            nx1 = x + pad
            nx2 = nx1 + med_w
            if nx2 > row[i + 1][0] - 4:
                break
            filled.append((nx1, y1, nx2, y2))
            x = nx2
        filled.append(row[i + 1])
    if sheet_w - filled[-1][2] > med_w * 0.7:
        nx1 = filled[-1][2] + pad
        filled.append((nx1, y1, min(sheet_w - 4, nx1 + med_w), y2))
    return filled


def find_boxes(im: Image.Image) -> list[tuple[int, int, int, int]]:
    w, h = im.size
    rgb = im.convert("RGB")
    bg = rgb.getpixel((2, 2))
    scale = 4
    small = rgb.resize((w // scale, h // scale), Image.Resampling.BOX)
    sw, sh = small.size
    pixels = small.load()
    mask = [[0] * sw for _ in range(sh)]
    for y in range(sh):
        for x in range(sw):
            mask[y][x] = 0 if is_bg(pixels[x, y], bg, tol=18) else 1

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
    cleaned: list[tuple[int, int, int, int]] = []
    for box in boxes:
        if any(_overlap(box, existing) > 0.5 for existing in cleaned):
            continue
        cleaned.append(box)

    rows: list[list[tuple[int, int, int, int]]] = []
    for box in cleaned:
        placed = False
        for row in rows:
            if abs(box[1] - row[0][1]) < 50:
                row.append(box)
                placed = True
                break
        if not placed:
            rows.append([box])
    filled: list[tuple[int, int, int, int]] = []
    for row in rows:
        filled.extend(_fill_row_gaps(row, w))
    print(f"detected {len(cleaned)} light frames; filling dark-frame gaps")
    filled.sort(key=lambda b: (b[1] // 40, b[0]))
    final: list[tuple[int, int, int, int]] = []
    for box in filled:
        if any(_overlap(box, existing) > 0.45 for existing in final):
            continue
        final.append(box)
    return final[:13]


def inset(box: tuple[int, int, int, int], pct: float = 0.035) -> tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    dx = int((x2 - x1) * pct)
    dy = int((y2 - y1) * pct)
    return x1 + dx, y1 + dy, x2 - dx, y2 - dy


def crop_rel(screen: Image.Image, l: float, t: float, r: float, b: float) -> Image.Image:
    w, h = screen.size
    return screen.crop((int(w * l), int(h * t), int(w * r), int(h * b)))


OWNED = {
    "church_building.png",
    "book_walking_purpose.png",
    "convention_2025.png",
    "live_fellowship.png",
    "give_seedling.png",
    "profile_chibuikem.png",
    "mission_lagos_thumb.png",
    "event_graduation_thumb.png",
}


def should_write(path: Path, new_im: Image.Image) -> str:
    """Return 'write', 'skip-protected', or 'skip-existing-better'."""
    if path.name in PROTECTED and path.exists():
        return "skip-protected"
    # Sheet-B owned names may be rewritten by this slicer after crop tuning.
    if path.name in OWNED:
        return "write"
    if path.exists():
        try:
            old = Image.open(path)
            old_area = old.size[0] * old.size[1]
            new_area = new_im.size[0] * new_im.size[1]
            if old_area >= new_area:
                return "skip-existing-better"
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
        print(f"  box {i+1:02d} {box} w={box[2]-box[0]} h={box[3]-box[1]}")

    screens: list[Image.Image] = []
    inners: list[tuple[int, int, int, int]] = []
    for i, box in enumerate(boxes):
        name = NAMES[i] if i < len(NAMES) else f"b_{i+1:02d}"
        inner_box = inset(box, 0.035)
        inner = im.crop(inner_box)
        inner.save(OUT_REFS / f"{name}.png", format="PNG", optimize=True)
        screens.append(inner)
        inners.append(inner_box)
        print(f"saved {name} {inner.size}")

    if len(screens) < 13:
        raise SystemExit(f"expected 13 screens, got {len(screens)}")

    # Relative rects tuned against inner screen content (visual pass).
    crop_rects = {
        "church_building.png": (0.0, 0.095, 1.0, 0.285),
        "book_walking_purpose.png": (0.0, 0.09, 0.50, 0.50),
        "convention_2025.png": (0.04, 0.175, 0.96, 0.385),
        "live_fellowship.png": (0.0, 0.05, 1.0, 0.38),
        "give_seedling.png": (0.05, 0.145, 0.95, 0.34),
        "profile_chibuikem.png": (0.36, 0.085, 0.64, 0.22),
        "mission_lagos_thumb.png": (0.05, 0.55, 0.22, 0.66),
        "event_graduation_thumb.png": (0.05, 0.43, 0.22, 0.54),
    }
    crop_sources = {
        "church_building.png": 1,
        "book_walking_purpose.png": 5,
        "convention_2025.png": 6,
        "live_fellowship.png": 8,
        "give_seedling.png": 9,
        "profile_chibuikem.png": 11,
        "mission_lagos_thumb.png": 2,
        "event_graduation_thumb.png": 6,
    }

    asset_meta = {}
    for name, rect in crop_rects.items():
        crop = crop_rel(screens[crop_sources[name]], *rect).convert("RGB")
        dest = OUT_IMAGES / name
        action = should_write(dest, crop)
        if action == "write":
            crop.save(dest, format="PNG", optimize=True)
            print(f"asset {name} {crop.size} wrote")
        else:
            print(f"asset {name} {crop.size} {action}")
        src_i = crop_sources[name]
        sx1, sy1, sx2, sy2 = inners[src_i]
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
            "action": action,
        }

    OUT_META.write_text(
        json.dumps(
            {
                "size": list(im.size),
                "notes": (
                    "Sheet B is a 1024x682 ChatGPT contact sheet, screens 13-25 "
                    "(6 phones on top, 7 below) on a navy canvas. Inner refs "
                    "exclude a 3.5% bezel inset. Asset crops are relative to "
                    "those inner screens."
                ),
                "boxes": [list(b) for b in boxes],
                "screens": [
                    {
                        "name": NAMES[i],
                        "label": LABELS[i],
                        "box": list(boxes[i]),
                        "inner": list(inners[i]),
                    }
                    for i in range(len(boxes))
                ],
                "assets": asset_meta,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"wrote {OUT_META}")


if __name__ == "__main__":
    main()
