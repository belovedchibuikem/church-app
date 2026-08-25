"""Slice SHEET D into 13 screen refs and unique photo crops."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

SRC = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_d.jpg")
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_d_boxes.json")

NAMES = [
    "d_01",  # Press Library
    "d_02",  # Give
    "d_03",  # Prayer
    "d_04",  # Events
    "d_05",  # Messages
    "d_06",  # My Home Church
    "d_07",  # Start Church Progress
    "d_08",  # Crusade Detail
    "d_09",  # Souls Follow-up
    "d_10",  # KCA Module Content
    "d_11",  # My Assignments
    "d_12",  # Mentor Chat
    "d_13",  # Notifications
]

LABELS = [
    "press_library",
    "give",
    "prayer",
    "events",
    "messages",
    "my_home_church",
    "start_church_progress",
    "crusade_detail",
    "souls_followup",
    "kca_module_content",
    "my_assignments",
    "mentor_chat",
    "notifications",
]

PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "multiply_home.png",
    "discover_globe.png",
    "nigeria_flag.png",
    "otp_security.png",
    "security_shield.png",
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
            if count < 400 or bh < sh * 0.18 or bw < sw * 0.08:
                continue
            aspect = bh / max(bw, 1)
            # Keep fused pairs (aspect ~1.0) so they can be split on gutters.
            if aspect < 0.9 or aspect > 2.6:
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
        split.extend(_split_wide(box, small, scale, pixels, bg))
    split.sort(key=lambda b: (b[1] // 40, b[0]))
    cleaned: list[tuple[int, int, int, int]] = []
    for box in split:
        if any(_overlap(box, existing) > 0.5 for existing in cleaned):
            continue
        bw = box[2] - box[0]
        bh = box[3] - box[1]
        aspect = bh / max(bw, 1)
        if aspect < 1.4 or aspect > 2.6:
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
                "size": list(content.size),
            }
        )

    # Unique crops relative to inner screens (tuned after visual inspection).
    # Names are new; never overwrite splash/onboarding protected files.
    # Give (d_02), Start Church Progress (d_07), Assignments (d_11), and
    # Notifications (d_13) have no unique photographs.
    crop_plan = {
        # d_01 Press Library: 3D Kingdom Leadership book on the right of the card
        "press_kingdom_leadership.png": (0, (0.58, 0.210, 0.96, 0.455)),
        # d_03 Prayer: green verse hero card + answered-prayer portrait
        "prayer_hero.png": (2, (0.05, 0.205, 0.95, 0.395)),
        "prayer_answered_avatar.png": (2, (0.08, 0.825, 0.24, 0.900)),
        # d_04 Events
        "convention_crowd.png": (3, (0.04, 0.200, 0.96, 0.400)),
        "event_kca_training.png": (3, (0.04, 0.575, 0.22, 0.655)),
        "event_youth_thumb.png": (3, (0.04, 0.695, 0.22, 0.775)),
        "event_prayer_thumb.png": (3, (0.04, 0.800, 0.22, 0.870)),
        # d_05 Messages
        "message_avatars.png": (4, (0.04, 0.220, 0.22, 0.790)),
        "mentor_john.png": (4, (0.05, 0.225, 0.21, 0.305)),
        "message_group.png": (4, (0.05, 0.345, 0.21, 0.425)),
        "mission_team_avatar.png": (4, (0.05, 0.585, 0.21, 0.665)),
        # d_06 My Home Church
        "home_church_grace.png": (5, (0.07, 0.135, 0.28, 0.230)),
        "home_church_meeting.png": (5, (0.05, 0.845, 0.20, 0.905)),
        # d_08 Crusade Detail: night crowd photo only
        "crusade_crowd.png": (7, (0.03, 0.110, 0.97, 0.255)),
        # d_09 Souls Follow-up
        "souls_avatar.png": (8, (0.05, 0.155, 0.20, 0.270)),
        # d_10 KCA Module Content: video teacher
        "kca_teacher.png": (9, (0.04, 0.185, 0.96, 0.425)),
    }

    asset_meta = {}
    for name, (src_i, rect) in crop_plan.items():
        if name in PROTECTED:
            print(f"skip protected {name}")
            continue
        dest = OUT_IMAGES / name
        if dest.name in PROTECTED and dest.exists():
            print(f"skip protected existing {name}")
            continue
        crop = crop_rel(screens[src_i], *rect)
        save_png(dest, crop)
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
                    "SHEET D contact sheet: 13 phones (7 top, 6 bottom). "
                    "Inner refs exclude 3.5% bezel. Unique photo crops use new "
                    "names and do not overwrite splash/onboarding assets. "
                    "Give, Start Church Progress, Assignments, and Notifications "
                    "have no unique photographs."
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
