"""Refine SHEET A photo crops and restore the truncated Press frame."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

SHEET = Path(r"c:\wamp64\www\church\mobile\artifacts\sheets\sheet_a.jpg")
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


def rel_crop(im: Image.Image, l: float, t: float, r: float, b: float) -> Image.Image:
    w, h = im.size
    box = (
        max(0, int(round(w * l))),
        max(0, int(round(h * t))),
        min(w, int(round(w * r))),
        min(h, int(round(h * b))),
    )
    return im.crop(box)


def save_asset(name: str, im: Image.Image) -> None:
    if name in PROTECTED and (IMAGES / name).exists():
        print(f"skip protected {name}")
        return
    path = IMAGES / name
    im.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"asset {name} {im.size}")


def row_report(im: Image.Image, label: str, step: int = 4) -> None:
    w, h = im.size
    px = im.load()
    print(f"\n=== {label} {im.size} ===")
    for y in range(0, h, step):
        vals = []
        white = 0
        green = 0
        n = 0
        for x in range(0, w, max(1, w // 32)):
            p = px[x, y]
            vals.append(luma(p))
            n += 1
            if p[0] > 230 and p[1] > 230 and p[2] > 230:
                white += 1
            if p[1] > p[0] + 15 and p[1] > p[2] + 8 and p[1] > 60:
                green += 1
        mean = sum(vals) / max(n, 1)
        var = sum((v - mean) ** 2 for v in vals) / max(n, 1)
        print(
            f"y={y:3d} ({y/h:.3f}) mean={mean:6.1f} var={var:8.0f} "
            f"white={white/n:.2f} green={green/n:.2f}"
        )


def find_circle(im: Image.Image, search: tuple[float, float, float, float]) -> tuple[int, int, int, int] | None:
    w, h = im.size
    x0 = int(w * search[0])
    y0 = int(h * search[1])
    x1 = int(w * search[2])
    y1 = int(h * search[3])
    region = im.crop((x0, y0, x1, y1)).convert("RGB")
    rw, rh = region.size
    px = region.load()
    mask = [[False] * rw for _ in range(rh)]
    for y in range(rh):
        for x in range(rw):
            r, g, b = px[x, y]
            # Skin / hair / clothing photo vs solid green header / white body.
            solid_green = g > 70 and g > r + 25 and g > b + 15 and abs(r - b) < 40
            white = r > 225 and g > 225 and b > 225
            pale_gray = abs(r - g) < 10 and abs(g - b) < 10 and luma((r, g, b)) > 205
            mask[y][x] = not solid_green and not white and not pale_gray

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
            if count < 40 or bw < 12 or bh < 12:
                continue
            if not (0.75 <= aspect <= 1.35):
                continue
            score = count
            if score > best_score:
                best_score = score
                pad = max(1, int(min(bw, bh) * 0.04))
                best = (
                    x0 + max(0, minx - pad),
                    y0 + max(0, miny - pad),
                    x0 + min(rw, maxx + 1 + pad),
                    y0 + min(rh, maxy + 1 + pad),
                )
    return best


def main() -> None:
    meta = json.loads(META.read_text(encoding="utf-8"))
    sheet = Image.open(SHEET).convert("RGB")

    # Restore Press frame to the same bottom as neighboring row-2 phones.
    press_screen = meta["screens"][11]
    box = press_screen["box"]
    neighbors_y2 = max(meta["screens"][i]["box"][3] for i in (9, 10, 12))
    if box[3] < neighbors_y2 - 8:
        box[3] = neighbors_y2
        dx = max(2, int((box[2] - box[0]) * 0.038))
        dy = max(2, int((box[3] - box[1]) * 0.038))
        inner = [box[0] + dx, box[1] + dy, box[2] - dx, box[3] - dy]
        press_screen["box"] = box
        press_screen["inner"] = inner
        press_im = sheet.crop(tuple(inner))
        press_im.save(REFS / "a_12.png", format="PNG", optimize=True)
        press_screen["size"] = list(press_im.size)
        print(f"restored a_12.png {press_im.size} inner={inner}")
    else:
        press_im = Image.open(REFS / "a_12.png").convert("RGB")

    screens = [Image.open(REFS / f"a_{i:02d}.png").convert("RGB") for i in range(1, 14)]
    screens[11] = press_im

    church, start1, start2, start3, start4, apps, events, prayer, give, kca, modules, press, profile = screens

    row_report(church, "church")
    row_report(start1, "start1")
    row_report(events, "events")
    row_report(give, "give")
    row_report(press, "press")
    row_report(profile, "profile", step=6)
    row_report(prayer, "prayer", step=6)

    META.write_text(json.dumps(meta, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
