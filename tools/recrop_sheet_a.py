"""Recrop SHEET A photos using measured bands from inner screens."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

REFS = Path(r"c:\wamp64\www\church\mobile\artifacts\design_refs")
IMAGES = Path(r"c:\wamp64\www\church\mobile\assets\images")
META = Path(r"c:\wamp64\www\church\mobile\artifacts\sheet_a_boxes.json")
PROTECTED = {
    "splash_map.png",
    "fhc_logo.png",
    "discover_globe.png",
    "connect_people.png",
    "multiply_home.png",
    "otp_security.png",
    "security_shield.png",
}


def luma(p: tuple[int, int, int]) -> float:
    return 0.2126 * p[0] + 0.7152 * p[1] + 0.0722 * p[2]


def save_asset(name: str, im: Image.Image) -> None:
    if name in PROTECTED and (IMAGES / name).exists():
        print(f"skip protected {name}")
        return
    im.convert("RGB").save(IMAGES / name, format="PNG", optimize=True)
    print(f"asset {name} {im.size}")


def col_split(im: Image.Image, y0: int, y1: int, from_right: bool = True) -> int:
    """Find x where a right-side photo splits from left-side text on a dark banner."""
    w, _ = im.size
    px = im.load()
    scores = []
    for x in range(w):
        vars_ = []
        brights = 0
        n = 0
        for y in range(y0, y1, max(1, (y1 - y0) // 16)):
            p = px[min(x, w - 1), y]
            vars_.append(luma(p))
            n += 1
            # Near-white text on dark banners.
            if p[0] > 200 and p[1] > 200 and p[2] > 200:
                brights += 1
        mean = sum(vars_) / max(n, 1)
        var = sum((v - mean) ** 2 for v in vars_) / max(n, 1)
        scores.append((x, var, brights / max(n, 1), mean))

    # Walk from center toward the photo side; photo has higher chroma/variance and fewer white glyphs.
    mid = w // 2
    if from_right:
        cut = mid
        for x in range(mid, w - 4):
            var, white, mean = scores[x][1], scores[x][2], scores[x][3]
            # Text columns: high white fraction OR very dark uniform. Photo: mid mean + variance.
            if white < 0.12 and var > 400:
                cut = x
                break
        return max(mid - 4, cut - 2)
    return mid


def find_circle_box(im: Image.Image, search: tuple[int, int, int, int], min_size: int = 12) -> tuple[int, int, int, int] | None:
    x0, y0, x1, y1 = search
    region = im.crop((x0, y0, x1, y1)).convert("RGB")
    rw, rh = region.size
    px = region.load()
    mask = [[False] * rw for _ in range(rh)]
    for y in range(rh):
        for x in range(rw):
            r, g, b = px[x, y]
            solid_green = g > 70 and g > r + 22 and g > b + 12
            white = r > 225 and g > 225 and b > 225
            pale = abs(r - g) < 10 and abs(g - b) < 10 and luma((r, g, b)) > 210
            mask[y][x] = not solid_green and not white and not pale

    best = None
    best_score = 0
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
            aspect = bw / max(bh, 1)
            if count < 30 or min(bw, bh) < min_size:
                continue
            if not (0.72 <= aspect <= 1.38):
                continue
            if count > best_score:
                best_score = count
                pad = max(1, int(min(bw, bh) * 0.06))
                best = (
                    x0 + max(0, minx - pad),
                    y0 + max(0, miny - pad),
                    x0 + min(rw, maxx + 1 + pad),
                    y0 + min(rh, maxy + 1 + pad),
                )
    return best


def main() -> None:
    IMAGES.mkdir(parents=True, exist_ok=True)
    screens = [Image.open(REFS / f"a_{i:02d}.png").convert("RGB") for i in range(1, 14)]
    church, start1, _s2, _s3, _s4, _apps, events, prayer, give, kca, _mod, press, profile = screens
    assets = {}

    def rec(name: str, img: Image.Image, box: tuple[int, int, int, int], screen: str) -> None:
        crop = img.crop(box)
        save_asset(name, crop)
        assets[name] = {"screen": screen, "box": list(box), "size": list(crop.size)}

    rec("church_hero.png", church, (0, 26, church.size[0], 84), "church_detail")
    rec("home_church_living.png", start1, (3, 64, start1.size[0] - 3, 116), "start_home_1")
    rec("event_convention.png", events, (6, 54, events.size[0] - 6, 124), "events")

    # Event list thumbs: left column of each row.
    rec("event_kca_graduation.png", events, (8, 172, 36, 200), "events")
    rec("event_youth_summit.png", events, (8, 208, 36, 236), "events")
    rec("event_prayer_conference.png", events, (8, 232, 36, 260), "events")

    gy0, gy1 = 44, 100
    gx = col_split(give, gy0, gy1)
    print(f"give plant split x={gx}")
    rec("give_plant.png", give, (gx, gy0, give.size[0] - 6, gy1), "give")
    rec("give_impact_banner.png", give, (6, gy0, give.size[0] - 6, gy1), "give")

    py0, py1 = 56, 142
    px = col_split(press, py0, py1)
    print(f"press book split x={px}")
    rec("press_book_cover.png", press, (px, py0, press.size[0] - 6, py1), "press")
    rec("press_new_release_banner.png", press, (6, py0, press.size[0] - 6, py1), "press")

    rec("press_power_of_prayer.png", press, (8, 214, 84, 264), "press")
    rec("press_winning_the_soul.png", press, (88, 214, 164, 264), "press")

    pav = find_circle_box(profile, (30, 10, 116, 70), min_size=18)
    if pav is None:
        pav = (52, 16, 94, 56)
    print(f"profile avatar box={pav}")
    rec("profile_avatar.png", profile, pav, "profile")

    kav = find_circle_box(kca, (4, 18, 70, 70), min_size=12)
    if kav:
        print(f"kca avatar box={kav}")
        rec("kca_avatar.png", kca, kav, "kca_dashboard")

    # Continue-learning book on KCA dashboard (right of bottom card).
    rec("kca_lesson_book.png", kca, (98, 210, 136, 248), "kca_dashboard")

    prav = find_circle_box(prayer, (4, 220, 50, 270), min_size=8)
    if prav is None:
        prav = (8, 232, 30, 258)
    print(f"prayer avatar box={prav}")
    rec("prayer_avatar.png", prayer, prav, "prayer")
    rec("prayer_answered_church.png", prayer, (86, 228, 130, 262), "prayer")

    meta = json.loads(META.read_text(encoding="utf-8"))
    meta["assets"] = assets
    META.write_text(json.dumps(meta, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
