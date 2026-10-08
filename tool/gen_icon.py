"""Gera o icone do app e a arte de destaque da Google Play (requer Pillow).

Uso:  python tool/gen_icon.py
Saida: assets/icon/icon.png, assets/icon/icon_foreground.png, store/feature_graphic.png
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
FONT = os.path.join(ROOT, "assets", "fonts", "LilitaOne-Regular.ttf")

GREEN = (0, 156, 59)
YELLOW = (255, 223, 0)
BLUE = (0, 39, 118)
ORANGE = (255, 140, 0)
NAVY = (31, 42, 68)
SKIN = (241, 194, 125)
MONEY = (46, 160, 67)


def money_bag(d, cx, cy, r):
    # saco
    d.ellipse([cx - r, cy - r * 0.8, cx + r, cy + r * 1.1], fill=(170, 120, 60), outline=(90, 60, 25), width=int(r * 0.08))
    d.polygon([(cx - r * 0.35, cy - r * 0.75), (cx + r * 0.35, cy - r * 0.75), (cx + r * 0.55, cy - r * 1.25),
               (cx - r * 0.55, cy - r * 1.25)], fill=(170, 120, 60), outline=(90, 60, 25))
    d.rectangle([cx - r * 0.42, cy - r * 0.85, cx + r * 0.42, cy - r * 0.7], fill=(200, 40, 40))
    f = ImageFont.truetype(FONT, int(r * 0.9))
    d.text((cx, cy + r * 0.18), "R$", font=f, fill=YELLOW, anchor="mm", stroke_width=int(r * 0.06), stroke_fill=(90, 60, 25))


def orange(d, cx, cy, r):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=ORANGE, outline=(170, 80, 0), width=max(2, int(r * 0.08)))
    d.ellipse([cx - r * 0.55, cy - r * 0.6, cx - r * 0.15, cy - r * 0.25], fill=(255, 190, 90))
    d.ellipse([cx - r * 0.1, cy - r * 1.35, cx + r * 0.7, cy - r * 0.85], fill=(60, 160, 60))


def politician_head(d, cx, cy, r):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=SKIN, outline=(120, 80, 40), width=int(r * 0.06))
    # cabelo lateral grisalho
    d.chord([cx - r, cy - r * 0.6, cx - r * 0.55, cy + r * 0.4], 90, 270, fill=(150, 150, 150))
    d.chord([cx + r * 0.55, cy - r * 0.6, cx + r, cy + r * 0.4], 270, 90, fill=(150, 150, 150))
    # oculos escuros
    d.rounded_rectangle([cx - r * 0.75, cy - r * 0.25, cx - r * 0.08, cy + r * 0.15], radius=int(r * 0.12), fill=(20, 20, 20))
    d.rounded_rectangle([cx + r * 0.08, cy - r * 0.25, cx + r * 0.75, cy + r * 0.15], radius=int(r * 0.12), fill=(20, 20, 20))
    d.line([cx - r * 0.1, cy - r * 0.15, cx + r * 0.1, cy - r * 0.15], fill=(20, 20, 20), width=int(r * 0.08))
    # bigode e sorriso
    d.ellipse([cx - r * 0.45, cy + r * 0.25, cx + r * 0.45, cy + r * 0.5], fill=(90, 90, 90))
    d.arc([cx - r * 0.4, cy + r * 0.2, cx + r * 0.4, cy + r * 0.75], 20, 160, fill=(120, 30, 30), width=int(r * 0.08))


def icon(size=1024, foreground_only=False):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size
    if not foreground_only:
        d.rectangle([0, 0, s, s], fill=GREEN)
        d.polygon([(s / 2, s * 0.08), (s * 0.94, s / 2), (s / 2, s * 0.92), (s * 0.06, s / 2)], fill=YELLOW)
        d.ellipse([s * 0.24, s * 0.24, s * 0.76, s * 0.76], fill=BLUE)
    k = 0.72 if foreground_only else 1.0  # area segura do icone adaptativo
    c = s / 2

    def S(v):
        return c + (v - c) * k

    # terno
    d.pieslice([S(s * 0.22), S(s * 0.62), S(s * 0.78), S(s * 1.15)], 180, 360, fill=NAVY)
    d.polygon([(S(s * 0.45), S(s * 0.66)), (S(s * 0.55), S(s * 0.66)), (S(s * 0.5), S(s * 0.86))], fill=(255, 255, 255))
    d.polygon([(S(s * 0.48), S(s * 0.68)), (S(s * 0.52), S(s * 0.68)), (S(s * 0.53), S(s * 0.84)), (S(s * 0.5), S(s * 0.88)),
               (S(s * 0.47), S(s * 0.84))], fill=(210, 30, 40))
    politician_head(d, S(s * 0.5), S(s * 0.47), s * 0.2 * k)
    money_bag(d, S(s * 0.8), S(s * 0.72), s * 0.13 * k)
    orange(d, S(s * 0.2), S(s * 0.74), s * 0.09 * k)
    return img


def feature_graphic():
    w, h = 1024, 500
    img = Image.new("RGB", (w, h), (120, 190, 255))
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        d.line([(0, y), (w, y)], fill=(int(90 + 120 * t), int(160 + 60 * t), 255))
    # congresso estilizado
    sil = (70, 110, 160)
    d.rectangle([600, 210, 630, 380], fill=sil)
    d.rectangle([645, 210, 675, 380], fill=sil)
    d.rectangle([630, 250, 645, 262], fill=sil)
    d.rectangle([470, 370, 830, 395], fill=sil)
    d.chord([490, 290, 610, 372], 0, 180, fill=sil)
    d.pieslice([710, 330, 810, 430], 180, 360, fill=sil)
    d.rectangle([0, 395, w, h], fill=(90, 90, 100))
    d.rectangle([0, 395, w, 410], fill=(170, 170, 175))
    for x in range(0, w, 90):
        d.rectangle([x, 450, x + 50, 458], fill=(240, 220, 80))
    big = ImageFont.truetype(FONT, 150)
    small = ImageFont.truetype(FONT, 40)
    d.text((40, 60), "MAMATA", font=big, fill=YELLOW, stroke_width=10, stroke_fill=(20, 30, 60))
    d.text((48, 235), "Fuja da Verdade até a Reeleição!", font=small, fill=(255, 255, 255), stroke_width=4,
           stroke_fill=(20, 30, 60))
    ic = icon(330, foreground_only=True)
    img.paste(ic, (690, 70), ic)
    return img


if __name__ == "__main__":
    os.makedirs(os.path.join(ROOT, "assets", "icon"), exist_ok=True)
    os.makedirs(os.path.join(ROOT, "store"), exist_ok=True)
    icon().save(os.path.join(ROOT, "assets", "icon", "icon.png"))
    icon(foreground_only=True).save(os.path.join(ROOT, "assets", "icon", "icon_foreground.png"))
    icon(512).convert("RGB").save(os.path.join(ROOT, "store", "icon_512.png"))
    feature_graphic().save(os.path.join(ROOT, "store", "feature_graphic.png"))
    print("ok")
