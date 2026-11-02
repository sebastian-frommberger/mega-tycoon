#!/usr/bin/env python3
"""W-05 S7 (Mira, Sprint 7 Block C): Industrie-Plaketten fuer die Weltmarker (world/industry_markers.gd).
Je Typ aus world/data/industrie_signal_s7.json drei PNGs (128 px, 4x supersampling):
  <typ>_ja.png    Lizenz aktiv: runde gruene Plakette (status_ok) mit Haken unten rechts
  <typ>_nein.png  ohne Lizenz: eckige graue Plakette mit Schloss unten rechts
  <typ>_frei.png  keine Lizenz noetig: ohne Plakette
Scheibe = Fuellfarbe der Signalflaeche mit dunklem Saum (S-08), Icon-Silhouette aus ui/icons.json (Tinte auf hellen,
Creme auf dunklen Fuellungen). Status also ueber Form (Kreis/Quadrat) UND Farbe (gruen/grau) UND Symbol (Haken/Schloss).
Aufruf (aus slice/): python3 -I ui/tools/make_industry_plates.py
"""
import json, os, sys
from PIL import Image, ImageDraw

ROOT = sys.argv[1] if len(sys.argv) > 1 else "."
SIG = json.load(open(os.path.join(ROOT, "world/data/industrie_signal_s7.json"), encoding="utf-8"))
ICONS = json.load(open(os.path.join(ROOT, "ui/icons.json"), encoding="utf-8"))
PAL = json.load(open(os.path.join(ROOT, "data/palette_s08.json"), encoding="utf-8"))
ICON_DIR = os.path.join(ROOT, "ui/assets/icons")
OUT = os.path.join(ROOT, "ui/assets/industry")
S = 512
SAUM = tuple(PAL["saum"]["rgb"]) + (255,)
OK = tuple(PAL["tokens"]["status_ok"]["rgb"]) + (255,)
GRAU = (196, 192, 184, 255)
CREME = tuple(SIG["saum"]["hell"]) + (255,)


def lum(c):
    def f(v):
        v /= 255.0
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2])


def tinted(name, size, color):
    src = Image.open(os.path.join(ICON_DIR, ICONS["icons"][name]["datei"])).convert("RGBA").resize((size, size), Image.LANCZOS)
    col = Image.new("RGBA", src.size, color)
    col.putalpha(src.getchannel("A"))
    return col


def plate(typ, cfg, status):
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    fill = tuple(cfg["fuellung"]) + (255,)
    d.ellipse((6, 6, S - 6, S - 6), fill=SAUM)
    if cfg["saum"] == "hell":
        d.ellipse((24, 24, S - 24, S - 24), fill=CREME)
        d.ellipse((40, 40, S - 40, S - 40), fill=fill)
    else:
        d.ellipse((30, 30, S - 30, S - 30), fill=fill)
    ink = SAUM if lum(cfg["fuellung"]) > 0.18 else CREME
    ic = tinted(cfg["icon"], 300, ink)
    im.alpha_composite(ic, ((S - 300) // 2 - 14, (S - 300) // 2 - 14))
    if status == "ja":
        cx, cy, r = 392, 392, 112
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=SAUM)
        d.ellipse((cx - r + 18, cy - r + 18, cx + r - 18, cy + r - 18), fill=OK)
        im.alpha_composite(tinted("ok", 140, SAUM), (cx - 70, cy - 70))
    elif status == "nein":
        x0, y0, w = 286, 286, 214
        d.rounded_rectangle((x0, y0, x0 + w, y0 + w), 18, fill=SAUM)
        d.rounded_rectangle((x0 + 18, y0 + 18, x0 + w - 18, y0 + w - 18), 8, fill=GRAU)
        im.alpha_composite(tinted("gesperrt", 140, SAUM), (x0 + (w - 140) // 2, y0 + (w - 140) // 2))
    return im.resize((128, 128), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    n = 0
    for typ, cfg in SIG["typen"].items():
        for st in ("ja", "nein", "frei"):
            plate(typ, cfg, st).save(os.path.join(OUT, "%s_%s.png" % (typ, st)))
            n += 1
    print("ok", n)
