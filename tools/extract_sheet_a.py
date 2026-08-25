"""Extract SHEET A phone frames and photo assets with Pillow."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

SRC = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_a.jpg")
OUT_REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
OUT_IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
OUT_META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_a_boxes.json")
PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "discover_globe.png",
    "connect_people.png",
    "multiply_home.png",
    "otp_security.png",
    "security_shield.png",
}
SCREEN_NAMES = [
    "church_detail",
    "start_home_1",
    "start_home_2",
    "start_home_3",
    "start_home_4",
    "applications",
    "events",
    "prayer",
    "give",
    "kca_dashboard",
    "kca_modules",
    "press",
    "profile",
]


def is_bg(pixel: tuple[int, int, int], bg: tuple[int, int, int], tol: int = 22) -> bool:
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
    scale = 2
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
            if count < 250 or bh < sh * 0.16 or bw < sw * 0.06:
                continue
            aspect = bh / max(bw, 1)
            if aspect < 1.25 or aspect > 2.8:
                continue
            boxes.append(
                (
                    minx * scale,
                    miny * scale,
                    (maxx + 1) * scale,
                    (maxy + 1) * scale,
                )
            )

    boxes.sort(key=lambda b: (b[1] // 50, b[0]))
    cleaned: list[tuple[int, int, int, int]] = []
    for box in boxes:
        if any(_overlap(box, existing) > 0.45 for existing in cleaned):
            continue
        cleaned.append(box)
    return cleaned[:13]


def trim_label(im: Image.Image, box: tuple[int, int, int, int]) -> tuple[int, int, int, int]:
    """Drop numbered caption pills that sit just under a phone frame."""
    x1, y1, x2, y2 = box
    rgb = im.convert("RGB")
    bg = rgb.getpixel((2, 2))
    w = x2 - x1
    h = y2 - y1
    px = rgb.load()
    # Walk up from the bottom; a dark gap means a caption was glued on.
    gap_rows = 0
    cut = y2
    for y in range(y2 - 1, y1 + int(h * 0.72), -1):
        dark = 0
        step = max(1, w // 40)
        samples = 0
        for x in range(x1, x2, step):
            samples += 1
            if is_bg(px[x, y], bg, 28):
                dark += 1
        if samples and dark / samples > 0.72:
            gap_rows += 1
            if gap_rows >= 2:
                cut = y
                break
        else:
            gap_rows = 0
    if cut < y2 - 6:
        return x1, y1, x2, cut
    return box


def inset(box: tuple[int, int, int, int], pct: float = 0.035) -> tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    dx = max(2, int((x2 - x1) * pct))
    dy = max(2, int((y2 - y1) * pct))
    return x1 + dx, y1 + dy, x2 - dx, y2 - dy


def crop_rel(screen: Image.Image, l: float, t: float, r: float, b: float) -> Image.Image:
    w, h = screen.size
    return screen.crop((int(w * l), int(h * t), int(w * r), int(h * b)))


def luma(p: tuple[int, int, int]) -> float:
    return 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]


def row_stats(im: Image.Image, y: int) -> tuple[float, float, float]:
    """Return mean luma, variance, and fraction of near-white pixels."""
    w, _ = im.size
    px = im.load()
    vals: list[float] = []
    white = 0
    step = max(1, w // 48)
    for x in range(0, w, step):
        p = px[x, y]
        vals.append(luma(p))
        if p[0] > 232 and p[1] > 232 and p[2] > 232:
            white += 1
    n = max(len(vals), 1)
    mean = sum(vals) / n
    var = sum((v - mean) ** 2 for v in vals) / n
    return mean, var, white / n


def find_hero_band(
    screen: Image.Image,
    start_frac: float = 0.045,
    end_frac: float = 0.55,
    min_frac: float = 0.12,
) -> tuple[float, float]:
    """Locate a photographic band near the top of a screen (below status bar)."""
    w, h = screen.size
    y0 = int(h * start_frac)
    y1 = int(h * end_frac)
    scores: list[tuple[int, float, float]] = []
    for y in range(y0, y1):
        mean, var, white = row_stats(screen, y)
        photo = var > 350 and white < 0.55
        scores.append((y, var, 1.0 if photo else 0.0))

    best_start = y0
    best_end = y0
    best_len = 0
    run_start = None
    for y, var, is_photo in scores:
        if is_photo:
            if run_start is None:
                run_start = y
        else:
            if run_start is not None:
                run_len = y - run_start
                if run_len > best_len:
                    best_len = run_len
                    best_start = run_start
                    best_end = y
                run_start = None
    if run_start is not None:
        run_len = scores[-1][0] - run_start
        if run_len > best_len:
            best_start = run_start
            best_end = scores[-1][0] + 1

    if best_end - best_start < h * min_frac:
        # Fallback: first high-variance stretch.
        return start_frac, min(start_frac + 0.28, 0.42)
    # Nudge in from chrome edges.
    top = max(0.0, (best_start - 1) / h)
    bot = min(1.0, (best_end + 1) / h)
    return top, bot


def find_square_photo(screen: Image.Image, hint_top: float, hint_bot: float) -> tuple[float, float, float, float]:
    """Tighten a roughly square photo (Give plant, Press book)."""
    w, h = screen.size
    y0 = int(h * hint_top)
    y1 = int(h * hint_bot)
    px = screen.load()
    # Find left/right content vs white side padding.
    left = 0
    right = w
    for x in range(w):
        colorful = 0
        for y in range(y0, y1, max(1, (y1 - y0) // 24)):
            p = px[x, y]
            if luma(p) < 220 and not (p[0] > 230 and p[1] > 230 and p[2] > 230):
                colorful += 1
        if colorful > 3:
            left = x
            break
    for x in range(w - 1, -1, -1):
        colorful = 0
        for y in range(y0, y1, max(1, (y1 - y0) // 24)):
            p = px[x, y]
            if luma(p) < 220 and not (p[0] > 230 and p[1] > 230 and p[2] > 230):
                colorful += 1
        if colorful > 3:
            right = x + 1
            break
    pad = max(1, int(w * 0.02))
    l = max(0.0, (left - pad) / w)
    r = min(1.0, (right + pad) / w)
    return l, hint_top, r, hint_bot


def find_circle_avatar(
    screen: Image.Image,
    search: tuple[float, float, float, float],
    min_frac: float = 0.10,
) -> tuple[float, float, float, float] | None:
    """Find a circular portrait inside a search rect (relative coords)."""
    w, h = screen.size
    x0, y0, x1, y1 = (
        int(w * search[0]),
        int(h * search[1]),
        int(w * search[2]),
        int(h * search[3]),
    )
    region = screen.crop((x0, y0, x1, y1)).convert("RGB")
    rw, rh = region.size
    if rw < 8 or rh < 8:
        return None
    px = region.load()
    # Skin / photo pixels vs white/green chrome.
    mask = [[False] * rw for _ in range(rh)]
    for y in range(rh):
        for x in range(rw):
            r, g, b = px[x, y]
            white = r > 230 and g > 230 and b > 230
            green_ui = g > r + 18 and g > b + 10 and g > 70
            gray = abs(r - g) < 12 and abs(g - b) < 12 and luma((r, g, b)) > 200
            mask[y][x] = not white and not green_ui and not gray

    best = None
    best_count = 0
    visited = [[False] * rw for _ in range(rh)]
    for y in range(rh):
        for x in range(rw):
            if not mask[y][x] or visited[y][x]:
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
                    if 0 <= nx < rw and 0 <= ny < rh and not visited[ny][nx] and mask[ny][nx]:
                        visited[ny][nx] = True
                        stack.append((nx, ny))
            bw = maxx - minx + 1
            bh = maxy - miny + 1
            if count < 20:
                continue
            aspect = bw / max(bh, 1)
            if 0.7 <= aspect <= 1.35 and bw >= rw * min_frac and bh >= rh * min_frac:
                if count > best_count:
                    best_count = count
                    pad = max(1, int(min(bw, bh) * 0.08))
                    best = (
                        (x0 + max(0, minx - pad)) / w,
                        (y0 + max(0, miny - pad)) / h,
                        (x0 + min(rw, maxx + 1 + pad)) / w,
                        (y0 + min(rh, maxy + 1 + pad)) / h,
                    )
    return best


def maybe_save(path: Path, im: Image.Image, force: bool = False) -> bool:
    if path.name in PROTECTED and path.exists() and not force:
        print(f"skip protected {path.name}")
        return False
    im.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"asset {path.name} {im.size}")
    return True


def main() -> None:
    OUT_REFS.mkdir(parents=True, exist_ok=True)
    OUT_IMAGES.mkdir(parents=True, exist_ok=True)
    im = Image.open(SRC).convert("RGB")
    print(f"source {im.size}")
    raw_boxes = find_boxes(im)
    print(f"found {len(raw_boxes)} raw screens")
    boxes = [trim_label(im, b) for b in raw_boxes]
    for i, b in enumerate(boxes):
        print(f"  box {i+1:02d} {b} size {(b[2]-b[0], b[3]-b[1])}")

    if len(boxes) != 13:
        debug = im.copy()
        draw = ImageDraw.Draw(debug)
        for b in boxes:
            draw.rectangle(b, outline=(255, 0, 0), width=2)
        debug.save(OUT_REFS / "_sheet_a_debug.png")
        raise SystemExit(f"expected 13 screens, got {len(boxes)}")

    screens: list[Image.Image] = []
    inner_boxes: list[tuple[int, int, int, int]] = []
    for i, box in enumerate(boxes):
        inner = inset(box, 0.038)
        inner_boxes.append(inner)
        screen = im.crop(inner)
        out = OUT_REFS / f"a_{i+1:02d}.png"
        screen.save(out, format="PNG", optimize=True)
        screens.append(screen)
        print(f"saved {out.name} {screen.size}  {SCREEN_NAMES[i]}")

    church, start1, start2, start3, start4, apps, events, prayer, give, kca, modules, press, profile = screens

    assets: dict[str, dict] = {}

    def record(name: str, screen_i: int, rel: tuple[float, float, float, float], img: Image.Image) -> None:
        assets[name] = {
            "screen": SCREEN_NAMES[screen_i],
            "rel": [round(v, 4) for v in rel],
            "size": list(img.size),
        }

    # --- Screen 1: church hero ---
    t, b = find_hero_band(church, 0.04, 0.50, 0.10)
    rel = (0.0, t, 1.0, b)
    crop = crop_rel(church, *rel)
    if maybe_save(OUT_IMAGES / "church_hero.png", crop):
        record("church_hero.png", 0, rel, crop)

    # --- Screen 2: living-room home church ---
    t, b = find_hero_band(start1, 0.04, 0.52, 0.10)
    rel = (0.0, t, 1.0, b)
    crop = crop_rel(start1, *rel)
    if maybe_save(OUT_IMAGES / "home_church_living.png", crop):
        record("home_church_living.png", 1, rel, crop)

    # --- Screen 7: events hero + thumbnails ---
    t, b = find_hero_band(events, 0.10, 0.48, 0.08)
    rel = (0.04, t, 0.96, b)
    crop = crop_rel(events, *rel)
    if maybe_save(OUT_IMAGES / "event_convention.png", crop):
        record("event_convention.png", 6, rel, crop)

    # Event list thumbnails sit in a column on the left of each row.
    for name, top, bot in (
        ("event_kca_graduation.png", 0.48, 0.62),
        ("event_youth_summit.png", 0.62, 0.74),
        ("event_prayer_conference.png", 0.74, 0.86),
    ):
        rel = (0.05, top, 0.28, bot)
        crop = crop_rel(events, *rel)
        if maybe_save(OUT_IMAGES / name, crop):
            record(name, 6, rel, crop)

    # --- Screen 8: prayer avatars ---
    av = find_circle_avatar(prayer, (0.02, 0.55, 0.55, 0.96), min_frac=0.08)
    if av:
        crop = crop_rel(prayer, *av)
        if maybe_save(OUT_IMAGES / "prayer_avatar.png", crop):
            record("prayer_avatar.png", 7, av, crop)
    else:
        rel = (0.06, 0.70, 0.22, 0.84)
        crop = crop_rel(prayer, *rel)
        if maybe_save(OUT_IMAGES / "prayer_avatar.png", crop):
            record("prayer_avatar.png", 7, rel, crop)

    av2 = find_circle_avatar(prayer, (0.02, 0.28, 0.40, 0.62), min_frac=0.08)
    if av2:
        crop = crop_rel(prayer, *av2)
        if maybe_save(OUT_IMAGES / "prayer_request_avatar.png", crop):
            record("prayer_request_avatar.png", 7, av2, crop)

    # --- Screen 9: give plant ---
    t, b = find_hero_band(give, 0.10, 0.55, 0.10)
    rel = find_square_photo(give, t, b)
    crop = crop_rel(give, *rel)
    if maybe_save(OUT_IMAGES / "give_plant.png", crop):
        record("give_plant.png", 8, rel, crop)

    # --- Screen 10: small KCA avatar (only if profile crop fails later) ---
    kca_av = find_circle_avatar(kca, (0.02, 0.04, 0.40, 0.28), min_frac=0.10)

    # --- Screen 12: press book cover ---
    t, b = find_hero_band(press, 0.16, 0.62, 0.12)
    rel = find_square_photo(press, t, b)
    crop = crop_rel(press, *rel)
    if maybe_save(OUT_IMAGES / "press_book_cover.png", crop):
        record("press_book_cover.png", 11, rel, crop)

    for name, left, right, top, bot in (
        ("press_power_of_prayer.png", 0.06, 0.48, 0.70, 0.90),
        ("press_winning_the_soul.png", 0.52, 0.94, 0.70, 0.90),
    ):
        rel = (left, top, right, bot)
        crop = crop_rel(press, *rel)
        if maybe_save(OUT_IMAGES / name, crop):
            record(name, 11, rel, crop)

    # --- Screen 13: large profile avatar ---
    pav = find_circle_avatar(profile, (0.20, 0.04, 0.80, 0.42), min_frac=0.18)
    if pav is None:
        pav = (0.32, 0.08, 0.68, 0.30)
    crop = crop_rel(profile, *pav)
    if maybe_save(OUT_IMAGES / "profile_avatar.png", crop):
        record("profile_avatar.png", 12, pav, crop)
    elif kca_av:
        crop = crop_rel(kca, *kca_av)
        if maybe_save(OUT_IMAGES / "profile_avatar.png", crop):
            record("profile_avatar.png", 9, kca_av, crop)

    if kca_av:
        crop = crop_rel(kca, *kca_av)
        if maybe_save(OUT_IMAGES / "kca_avatar.png", crop):
            record("kca_avatar.png", 9, kca_av, crop)

    OUT_META.write_text(
        json.dumps(
            {
                "source": str(SRC),
                "size": list(im.size),
                "notes": "SHEET A: 7 phones on top, 6 below. Inner refs exclude ~3.8% bezel.",
                "screens": [
                    {
                        "file": f"a_{i+1:02d}.png",
                        "name": SCREEN_NAMES[i],
                        "box": list(boxes[i]),
                        "inner": list(inner_boxes[i]),
                        "size": list(screens[i].size),
                    }
                    for i in range(13)
                ],
                "assets": assets,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"wrote {OUT_META}")


if __name__ == "__main__":
    main()
