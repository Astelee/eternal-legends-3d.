#!/usr/bin/env python3
"""Gera os assets em Pixel Art da tela de login (assets/ui/login/*.png).

Uso (na raiz do projeto):  python3 tools/gen_login_assets.py
Requer: Pillow. Todos os desenhos sao feitos em resolucao logica pequena e
ampliados com NEAREST, para manter os pixels nitidos.
"""
import math
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "ui", "login")
os.makedirs(OUT, exist_ok=True)


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def lerp(c1, c2, t):
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(4))


def save(img, name, scale):
    img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    img.save(os.path.join(OUT, name + ".png"))


INK = hexc("#14101a")

# ------------------------------------------------------------------ moldura
def make_frame():
    n, m = 24, 9
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    outl, g1, g2, g3, g4 = hexc("#140d08"), hexc("#f6e3a1"), hexc("#d4a94a"), hexc("#9a7430"), hexc("#5a4018")
    for y in range(n):
        for x in range(n):
            d = min(x, y, n - 1 - x, n - 1 - y)
            c = None
            if d == 0:
                c = outl
            elif d == 1:
                c = g1
            elif d == 2:
                c = g2
            elif d == 3:
                c = g3
            elif d == 4:
                c = outl
            elif d == 5:
                c = g4
            # placas de canto com gema azul
            lx = x if x < m else (n - 1 - x if x >= n - m else None)
            ly = y if y < m else (n - 1 - y if y >= n - m else None)
            if lx is not None and ly is not None:
                if lx == 8 or ly == 8:
                    c = outl
                elif lx == 0 or ly == 0:
                    c = outl
                elif lx == 1 or ly == 1:
                    c = g1
                else:
                    c = g2 if (lx + ly) < 8 else g3
                if max(abs(lx - 4), abs(ly - 4)) == 2 and lx >= 2 and ly >= 2:
                    c = hexc("#2a1a0a")
                if max(abs(lx - 4), abs(ly - 4)) <= 1:
                    c = hexc("#4a86d8")
                    if lx == 3 and ly == 3:
                        c = hexc("#d5ecff")
                    if lx == 5 and ly == 5:
                        c = hexc("#1f3f80")
            if c is not None:
                px[x, y] = c
    save(img, "frame", 2)


# ------------------------------------------------------------------ botoes
def make_button(name, top, bot, hi, shade, outl, inset=False, rim=None):
    n = 16
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    for y in range(n):
        for x in range(n):
            if (x, y) in ((0, 0), (n - 1, 0), (0, n - 1), (n - 1, n - 1)):
                continue
            d = min(x, y, n - 1 - x, n - 1 - y)
            if d == 0:
                c = outl
            else:
                t = (y - 1) / (n - 3)
                body = lerp(top, bot, t)
                light = (y == 1 or x == 1)
                dark = (y == n - 2 or x == n - 2)
                if rim is not None and d == 1:
                    c = rim
                elif rim is not None and d == 2:
                    c = (hi if not inset else shade) if (y == 2 or x == 2) else ((shade if not inset else hi) if (y == n - 3 or x == n - 3) else body)
                elif rim is None and d == 1:
                    if light:
                        c = hi if not inset else shade
                    elif dark:
                        c = shade if not inset else hi
                    else:
                        c = body
                else:
                    c = body
            px[x, y] = c
    save(img, name, 2)


def make_buttons():
    o = hexc("#2a1608")
    make_button("btn_gold_normal", hexc("#f7dc7c"), hexc("#c8942e"), hexc("#fff3b8"), hexc("#8c5f1c"), o)
    make_button("btn_gold_hover", hexc("#ffeaa0"), hexc("#e0ae44"), hexc("#fffbd8"), hexc("#a8751f"), o)
    make_button("btn_gold_pressed", hexc("#b27d24"), hexc("#9c6a1c"), hexc("#d9a53e"), hexc("#6a4510"), o, inset=True)
    make_button("btn_gold_disabled", hexc("#6b6358"), hexc("#4e463c"), hexc("#7d7569"), hexc("#3a342c"), hexc("#1c1812"))
    wo = hexc("#1a0e06")
    rim = hexc("#c49a42")
    make_button("btn_wood_normal", hexc("#7d4c28"), hexc("#5a3319"), hexc("#a56b3c"), hexc("#3a200e"), wo, rim=rim)
    make_button("btn_wood_hover", hexc("#98613a"), hexc("#6e4424"), hexc("#c08350"), hexc("#46280f"), wo, rim=hexc("#f2dc94"))
    make_button("btn_wood_pressed", hexc("#4a2a14"), hexc("#3e2310"), hexc("#6a3f20"), hexc("#2a160a"), wo, inset=True, rim=hexc("#9a7430"))


# ------------------------------------------------------------------ campos
def make_field(name, border, glow=None):
    n = 16
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    for y in range(n):
        for x in range(n):
            if (x, y) in ((0, 0), (n - 1, 0), (0, n - 1), (n - 1, n - 1)):
                continue
            d = min(x, y, n - 1 - x, n - 1 - y)
            if d == 0:
                c = hexc("#08050c")
            elif d == 1:
                c = border
            elif d == 2 and glow is not None:
                c = glow
            elif y == 2 or (y == 3 and d >= 2):
                c = hexc("#07040a", 240)
            else:
                c = hexc("#100b18", 238)
            px[x, y] = c
    save(img, name, 2)


def make_fields():
    make_field("field_normal", hexc("#7a5c28"))
    make_field("field_focus", hexc("#e2bb55"), hexc("#2b4a8a"))
    make_field("field_error", hexc("#d0504a"), hexc("#5a1c1c"))


# ------------------------------------------------------------------ caixa de selecao
def make_checks():
    n = 11
    for on in (False, True):
        img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
        px = img.load()
        for y in range(n):
            for x in range(n):
                if (x, y) in ((0, 0), (n - 1, 0), (0, n - 1), (n - 1, n - 1)):
                    continue
                d = min(x, y, n - 1 - x, n - 1 - y)
                if d == 0:
                    c = hexc("#08050c")
                elif d == 1:
                    c = hexc("#d4a94a") if on else hexc("#8a6a2c")
                elif y == 2:
                    c = hexc("#07040a")
                else:
                    c = hexc("#1a1226") if not on else hexc("#142a1c")
                px[x, y] = c
        if on:
            pts = [(2, 5), (3, 6), (4, 7), (5, 6), (6, 5), (7, 4), (8, 3)]
            for (x, y) in pts:
                px[x, y] = hexc("#9be8a6")
                if y + 1 < n - 2:
                    px[x, y + 1] = hexc("#4fb868")
        save(img, "check_on" if on else "check_off", 2)


# ------------------------------------------------------------------ icones
ICONS = {
    "user": [
        "....####....", "...######...", "...######...", "...######...", "....####....", ".....##.....",
        "..########..", ".##########.", "############", "############", "############", "............"],
    "lock": [
        "...######...", "..##....##..", "..##....##..", "..##....##..", ".##########.", ".##########.",
        ".####..####.", ".###....###.", ".####..####.", ".##########.", ".##########.", "............"],
    "mail": [
        "............", "............", "############", "##.######.##", "###.####.###", "####.##.####",
        "#####..#####", "############", "############", "############", "............", "............"],
    "eye": [
        "............", "............", "...######...", ".##......##.", "##..####..##", "#..######..#",
        "##..####..##", ".##......##.", "...######...", "............", "............", "............"],
    "check": [
        "............", "..........##", ".........###", "........###.", "##.....###..", "###...###...",
        ".###.###....", "..#####.....", "...###......", "....#.......", "............", "............"],
    "close": [
        "............", ".##......##.", "..##....##..", "...##..##...", "....####....", ".....##.....",
        ".....##.....", "....####....", "...##..##...", "..##....##..", ".##......##.", "............"],
    "star": [
        "............", ".....##.....", ".....##.....", "....####....", "############", ".##########.",
        "...######...", "..########..", "..###..###..", ".###....###.", "............", "............"],
    "gear": [
        "....#..#....", "..#.####.#..", "..########..", ".####..####.", "..###..###..", "####....####",
        "####....####", "..###..###..", ".####..####.", "..########..", "..#.####.#..", "....#..#...."],
    "bug": [
        "..#......#..", "...#....#...", "....####....", "...######...", "##.######.##", "...######...",
        "##.######.##", "...######...", "##.######.##", "....####....", "............", "............"],
    "alert": [
        "............", ".....##.....", "....####....", "....#..#....", "...##..##...", "...##..##...",
        "..###..###..", "..########..", ".####..####.", ".##########.", "............", "............"],
    "sparkle": [
        ".....##.....", ".....##.....", "....####....", "...######...", "############", "############",
        "...######...", "....####....", ".....##.....", ".....##.....", "............", "............"],
    "chevron_down": [
        "............", "............", "##........##", ".##......##.", "..##....##..", "...##..##...",
        "....####....", ".....##.....", "............", "............", "............", "............"],
}


def make_icon(name, rows, flip=None, rot=None):
    size, pad = 12, 1
    img = Image.new("RGBA", (size + 2 * pad, size + 2 * pad), (0, 0, 0, 0))
    px = img.load()
    filled = set()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                filled.add((x + pad, y + pad))
    for (x, y) in filled:
        px[x, y] = (255, 255, 255, 255)
    w = size + 2 * pad
    for y in range(w):
        for x in range(w):
            if (x, y) in filled:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) in filled:
                    px[x, y] = INK
                    break
    if flip == "v":
        img = img.transpose(Image.FLIP_TOP_BOTTOM)
    if rot:
        img = img.rotate(rot)
    save(img, "icon_" + name, 2)


def make_eye_off():
    rows = [list(r) for r in ICONS["eye"]]
    for i in range(9):
        x, y = 1 + i, 1 + i
        rows[y][x] = "#"
        if x + 1 < 12:
            rows[y][x + 1] = "#"
    make_icon("eye_off", ["".join(r) for r in rows])


def make_icons():
    for k, v in ICONS.items():
        make_icon(k, v)
    make_eye_off()
    make_icon("chevron_up", ICONS["chevron_down"], flip="v")
    make_icon("chevron_right", ICONS["chevron_down"], rot=90)


def make_spinner():
    n = 14
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    px = img.load()
    c = (n - 1) / 2.0
    for y in range(n):
        for x in range(n):
            r = math.hypot(x - c, y - c)
            ang = (math.degrees(math.atan2(y - c, x - c)) + 360) % 360
            if 4.0 <= r <= 6.2 and not (0 <= ang < 80):
                px[x, y] = (255, 255, 255, 255)
    save(img, "spinner", 2)


# ------------------------------------------------------------------ detalhes
def make_diamond():
    rows = ["...#...", "..###..", ".#####.", "#######", ".#####.", "..###..", "...#..."]
    img = Image.new("RGBA", (9, 9), (0, 0, 0, 0))
    px = img.load()
    filled = set()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == "#":
                filled.add((x + 1, y + 1))
    for (x, y) in filled:
        px[x, y] = hexc("#f2dc94") if (x + y) < 9 else hexc("#d4a94a")
    for y in range(9):
        for x in range(9):
            if (x, y) in filled:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) in filled:
                    px[x, y] = hexc("#2a1608")
                    break
    save(img, "diamond", 2)


def make_shine():
    w, h = 12, 20
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    for y in range(h):
        center = 9 - y * 0.35
        for x in range(w):
            dist = abs(x - center)
            if dist < 1.6:
                px[x, y] = (255, 255, 255, 150)
            elif dist < 3.2:
                px[x, y] = (255, 255, 255, 60)
    save(img, "shine", 2)


# ------------------------------------------------------------------ logotipo
GLYPHS = {
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "N": ["10001", "11001", "10101", "10101", "10011", "10001", "10001"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
    "G": ["01110", "10001", "10000", "10111", "10001", "10001", "01110"],
    "D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
    "S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
}


def make_logo():
    cell = 3
    pad = 8
    text_w = 7 * 5 * cell + 6 * 2 * cell
    line_h = 7 * cell
    gap = 6
    orn_h = 10
    w = text_w + pad * 2
    h = pad + line_h + gap + line_h + 4 + orn_h + pad
    mask = set()
    line_tops = []

    def put_line(text, y0):
        line_tops.append(y0)
        x = pad
        for ch in text:
            g = GLYPHS[ch]
            for gy, row in enumerate(g):
                for gx, v in enumerate(row):
                    if v == "1":
                        for dy in range(cell):
                            for dx in range(cell):
                                mask.add((x + gx * cell + dx, y0 + gy * cell + dy))
            x += 7 * cell

    put_line("ETERNAL", pad)
    put_line("LEGENDS", pad + line_h + gap)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()

    def dilate(src, r):
        out = set()
        for (x, y) in src:
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    out.add((x + dx, y + dy))
        return out

    ornament = set()
    oy = pad + line_h + gap + line_h + 4 + orn_h // 2
    for x in range(pad + 6, pad + text_w - 6):
        ornament.add((x, oy))
        ornament.add((x, oy + 1))
    cx = pad + text_w // 2
    for k in range(-4, 5):
        half = 4 - abs(k)
        for j in range(-half, half + 1):
            ornament.add((cx + j, oy + k))
    full = mask | ornament
    shadow = dilate({(x + 2, y + 3) for (x, y) in full}, 2)
    for (x, y) in shadow:
        if 0 <= x < w and 0 <= y < h:
            px[x, y] = (8, 4, 20, 150)
    outline2 = dilate(full, 2)
    for (x, y) in outline2:
        if 0 <= x < w and 0 <= y < h:
            px[x, y] = hexc("#2a1409")
    outline1 = dilate(full, 1)
    for (x, y) in outline1:
        if 0 <= x < w and 0 <= y < h:
            px[x, y] = hexc("#120a05")
    for (x, y) in full:
        if not (0 <= x < w and 0 <= y < h):
            continue
        if (x, y) in ornament and (x, y) not in mask:
            c = hexc("#e8c25a")
        else:
            top = line_tops[0] if y < pad + line_h + gap // 2 else line_tops[1]
            t = (y - top) / float(line_h)
            if t < 0.45:
                c = lerp(hexc("#fff4b8"), hexc("#f4c94f"), t / 0.45)
            elif t < 0.55:
                c = hexc("#e0a838")
            else:
                c = lerp(hexc("#d28f2a"), hexc("#9a5a16"), (t - 0.55) / 0.45)
            if (x, y - 1) not in full:
                c = hexc("#fffbe0")
            elif (x, y + 1) not in full:
                c = hexc("#7a4510")
            elif (x - 1, y) not in full:
                c = lerp(c, hexc("#ffeeaa"), 0.5)
        px[x, y] = c
    # brilhos magicos
    for (sx, sy) in ((w - 14, 5), (pad + 40, h - 8), (10, pad + line_h + 6)):
        for d in range(-2, 3):
            if 0 <= sx + d < w and 0 <= sy < h:
                px[sx + d, sy] = hexc("#d5ecff")
            if 0 <= sy + d < h and 0 <= sx < w:
                px[sx, sy + d] = hexc("#d5ecff")
    save(img, "logo", 3)


if __name__ == "__main__":
    make_frame()
    make_buttons()
    make_fields()
    make_checks()
    make_icons()
    make_spinner()
    make_diamond()
    make_shine()
    make_logo()
    print("assets gerados em", OUT)