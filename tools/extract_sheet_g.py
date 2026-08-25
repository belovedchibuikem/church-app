"""Slice SHEET G into 13 church-ops screen refs and unique photo crops."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

SRC = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_g.jpg")
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
OUT_MEMBERS = OUT_IMAGES / "member_photos"
META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_g_boxes.json")

PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "multiply_home.png",
    "discover_globe.png",
    "nigeria_flag.png",
    "otp_security.png",
    "security_shield.png",
}

NAMES = [
    "g_01",  # Church Dashboard (Join Live Service)
    "g_02",  # Module Selector 6 cards
    "g_03",  # Church Module Home menu
    "g_04",  # Members List
    "g_05",  # Small Groups
    "g_06",  # Event Details Annual Convention
    "g_07",  # Announcements
    "g_08",  # Live Service
    "g_09",  # Give
    "g_10",  # Prayer
    "g_11",  # Ministries
    "g_12",  # Documents
    "g_13",  # Church Settings
]

LABELS = [
    "church_dashboard",
    "module_selector",
    "church_module_home",
    "members_list",
    "small_groups",
    "event_details_convention",
    "announcements",
    "live_service",
    "give",
    "prayer",
    "ministries",
    "documents",
    "church_settings",
]


def is_bg(pixel: tuple[int, int, int], bg: tuple[int, int, int], tol: int = 28) -> bool:
    # Navy canvas varies; near-black bezels should not glue neighboring phones.
    if max(pixel) <= 45:
        return True
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
            if count < 400 or bh < sh * 0.18 or bw < sw * 0.06:
                continue
            aspect = bh / max(bw, 1)
            # Keep fused rows (aspect ~0.3) so they can be split on gutters.
            if aspect < 0.25 or aspect > 2.8:
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
    split: list[tuple[int, int, int, int]] = []
    for box in boxes:
        split.extend(_split_wide(box, small, scale, pixels, bg, depth=0))
    split.sort(key=lambda b: (b[1] // 40, b[0]))
    cleaned: list[tuple[int, int, int, int]] = []
    for box in split:
        if any(_overlap(box, existing) > 0.5 for existing in cleaned):
            continue
        bw = box[2] - box[0]
        bh = box[3] - box[1]
        aspect = bh / max(bw, 1)
        if aspect < 1.35 or aspect > 2.8:
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
    filled.sort(key=lambda b: (b[1] // 40, b[0]))
    final: list[tuple[int, int, int, int]] = []
    for box in filled:
        if any(_overlap(box, existing) > 0.45 for existing in final):
            continue
        final.append(box)
    return final[:13]


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
        while row[i + 1][0] - x > med_w * 0.65:
            nx1 = x + max(pad, 4)
            limit = row[i + 1][0] - max(pad, 4)
            nx2 = min(nx1 + med_w, limit)
            if nx2 - nx1 < med_w * 0.55:
                break
            filled.append((nx1, y1, nx2, y2))
            x = nx2
        filled.append(row[i + 1])
    if sheet_w - filled[-1][2] > med_w * 0.7:
        nx1 = filled[-1][2] + pad
        filled.append((nx1, y1, min(sheet_w - 4, nx1 + med_w), y2))
    return filled


def _split_wide(
    box: tuple[int, int, int, int],
    small: Image.Image,
    scale: int,
    pixels,
    bg: tuple[int, int, int],
    depth: int = 0,
) -> list[tuple[int, int, int, int]]:
    x1, y1, x2, y2 = box
    bw, bh = x2 - x1, y2 - y1
    aspect = bh / max(bw, 1)
    if aspect >= 1.4 or depth > 8:
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
    inner = occ[int(len(occ) * 0.12) : int(len(occ) * 0.88)]
    if not inner:
        return [box]
    gutter_x, gutter_c = min(inner, key=lambda t: t[1])
    if gutter_c > peak * 0.62:
        return [box]
    mid = gutter_x * scale
    left = (x1, y1, mid, y2)
    right = (mid + scale, y1, x2, y2)
    if (left[2] - left[0]) < 70 or (right[2] - right[0]) < 70:
        return [box]
    return _split_wide(left, small, scale, pixels, bg, depth + 1) + _split_wide(
        right, small, scale, pixels, bg, depth + 1
    )


def inset(box: tuple[int, int, int, int], pct: float = 0.035) -> tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    dx = int((x2 - x1) * pct)
    dy = int((y2 - y1) * pct)
    return x1 + dx, y1 + dy, x2 - dx, y2 - dy


def crop_rel(screen: Image.Image, l: float, t: float, r: float, b: float) -> Image.Image:
    w, h = screen.size
    return screen.crop((int(w * l), int(h * t), int(w * r), int(h * b)))


def save_png(path: Path, im: Image.Image) -> str:
    if path.name in PROTECTED and path.exists():
        print(f"skip-protected {path.name}")
        return "skip-protected"
    path.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"saved {path.name} {im.size}")
    return "write"


def _abs_box(
    inner: tuple[int, int, int, int], rect: tuple[float, float, float, float]
) -> list[int]:
    sx1, sy1, sx2, sy2 = inner
    l, t, r, b = rect
    return [
        int(sx1 + (sx2 - sx1) * l),
        int(sy1 + (sy2 - sy1) * t),
        int(sx1 + (sx2 - sx1) * r),
        int(sy1 + (sy2 - sy1) * b),
    ]


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
        # g_08 video player only (skip LIVE SERVICE chrome).
        "live_worship.png": (7, (0.03, 0.125, 0.97, 0.355)),
        # g_06 stadium hero only (skip EVENT DETAILS app bar).
        "convention_hero.png": (5, (0.04, 0.128, 0.96, 0.348)),
        # g_04 avatar column (skip tabs / names / Add Member).
        "member_photos.png": (3, (0.07, 0.300, 0.215, 0.804)),
    }

    requested = {"live_worship.png", "convention_hero.png", "member_photos.png"}

    asset_meta: dict = {}
    for name, (src_i, rect) in crop_plan.items():
        crop = crop_rel(screens[src_i], *rect)
        dest = OUT_IMAGES / name
        action = save_png(dest, crop)
        if name in requested:
            save_png(OUT_REFS / name, crop)
        asset_meta[name] = {
            "screen": NAMES[src_i],
            "rel": list(rect),
            "box": _abs_box(inset(boxes[src_i]), rect),
            "size": list(crop.size),
            "path": str(dest),
            "action": action,
        }

    member_plan = [
        ("member_john_david.png", (0.07, 0.304, 0.215, 0.375)),
        ("member_sarah_okafor.png", (0.07, 0.407, 0.215, 0.479)),
        ("member_michael_johnson.png", (0.07, 0.514, 0.215, 0.586)),
        ("member_blessing_uche.png", (0.07, 0.621, 0.215, 0.693)),
        ("member_emeka_onyema.png", (0.07, 0.732, 0.215, 0.804)),
    ]
    refs_members = OUT_REFS / "member_photos"
    refs_members.mkdir(parents=True, exist_ok=True)
    for mname, rect in member_plan:
        thumb = crop_rel(screens[3], *rect)
        dest = OUT_MEMBERS / mname
        save_png(dest, thumb)
        save_png(refs_members / mname, thumb)
        asset_meta[f"member_photos/{mname}"] = {
            "screen": "g_04",
            "rel": list(rect),
            "box": _abs_box(inset(boxes[3]), rect),
            "size": list(thumb.size),
            "path": str(dest),
        }

    # Ministry row icons on g_11 are illustrated glyphs, not photographs.
    asset_meta["ministry_icons"] = {
        "screen": "g_11",
        "skipped": True,
        "reason": "circular illustrated glyphs, not photographic",
    }

    META.write_text(
        json.dumps(
            {
                "source": str(SRC),
                "size": list(im.size),
                "notes": (
                    "SHEET G contact sheet: 13 phones (7 top, 6 bottom) church ops. "
                    "Inner refs exclude 3.5% bezel. Unique crops: live_worship, "
                    "convention_hero, member_photos. Ministry icons skipped "
                    "(illustrated, not photographic)."
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
