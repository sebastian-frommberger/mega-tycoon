#!/usr/bin/env python3
"""U-01b: Ergaenzungs-Icons im Stil von Kenney Game Icons (weisse Silhouette, 100x100, transparent).
Kenney Game Icons enthaelt kein Geld, Lkw, Zug, Fabrik, Lizenz, Stadt-Skyline, Lager, Strasse, Gleis,
Weizen, Spitzhacke, Uhr. Diese werden hier gezeichnet (4x supersampling, dann verkleinert).
Aufruf: python3 -I ui/tools/make_icons.py <ausgabeordner>
"""
import sys, os, math
from PIL import Image, ImageDraw, ImageFont

S = 400  # Zeichenflaeche, Ausgabe 100
OUT = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else "."
W = (255, 255, 255, 255)
T = (0, 0, 0, 0)
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def canvas():
    im = Image.new("RGBA", (S, S), T)
    return im, ImageDraw.Draw(im)


def save(im, name):
    im = im.resize((100, 100), Image.LANCZOS)
    im.save(os.path.join(OUT, "c_%s.png" % name))


def geld():
    im, d = canvas()
    d.ellipse((40, 40, 360, 360), fill=W)
    d.ellipse((78, 78, 322, 322), fill=T)
    d.ellipse((98, 98, 302, 302), fill=W)
    f = ImageFont.truetype(BOLD, 200)
    d.text((200, 205), "$", font=f, fill=T, anchor="mm")
    save(im, "geld")


def wheel(d, cx, cy, r):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=W)
    d.ellipse((cx - r * 0.42, cy - r * 0.42, cx + r * 0.42, cy + r * 0.42), fill=T)


def lkw():
    im, d = canvas()
    d.rounded_rectangle((30, 90, 250, 270), 18, fill=W)          # Ladeflaeche
    d.rounded_rectangle((262, 140, 372, 270), 22, fill=W)        # Kabine
    d.rounded_rectangle((285, 160, 350, 205), 8, fill=T)         # Fenster
    # Radkaesten freistellen, dann Raeder
    for cx in (100, 310):
        d.ellipse((cx - 56, 250 - 56 + 30, cx + 56, 250 + 56 + 30), fill=T)
        wheel(d, cx, 280, 44)
    save(im, "lkw")


def zug():
    im, d = canvas()
    d.rounded_rectangle((40, 150, 300, 270), 20, fill=W)         # Kessel
    d.rounded_rectangle((230, 80, 360, 270), 18, fill=W)          # Fuehrerhaus
    d.rounded_rectangle((255, 105, 335, 160), 8, fill=T)          # Fenster
    d.rectangle((80, 95, 125, 150), fill=W)                       # Schlot
    d.rounded_rectangle((68, 80, 137, 104), 8, fill=W)
    d.polygon([(40, 270), (10, 320), (60, 300)], fill=W)          # Schienenraeumer
    for cx in (110, 200, 300):
        d.ellipse((cx - 50, 290 - 50, cx + 50, 290 + 50), fill=T)
        wheel(d, cx, 300, 38)
    save(im, "zug")


def lizenz():
    im, d = canvas()
    d.rounded_rectangle((60, 30, 300, 360), 26, fill=W)
    for i, y in enumerate((90, 140, 190)):
        d.rounded_rectangle((100, y, 260 if i < 2 else 200, y + 22), 11, fill=T)
    # Siegel mit Band
    d.ellipse((205, 215, 375, 385), fill=T)
    d.polygon([(250, 320), (225, 395), (260, 375), (285, 395), (290, 330)], fill=W)
    d.polygon([(330, 320), (355, 395), (320, 375), (295, 395), (290, 330)], fill=W)
    d.ellipse((222, 232, 358, 368), fill=W)
    d.ellipse((258, 268, 322, 332), fill=T)
    save(im, "lizenz")


def fabrik():
    im, d = canvas()
    d.rectangle((30, 200, 370, 350), fill=W)
    # Sheddach (Saegezahn)
    for x in (30, 130, 230):
        d.polygon([(x, 200), (x + 100, 120), (x + 100, 200)], fill=W)
    d.rectangle((300, 50, 345, 200), fill=W)                       # Schornstein
    for x in (70, 170, 260):
        d.rounded_rectangle((x, 245, x + 50, 300), 6, fill=T)      # Fenster
    save(im, "fabrik")


def stadt():
    im, d = canvas()
    d.rectangle((40, 170, 150, 360), fill=W)
    d.polygon([(30, 175), (95, 110), (160, 175)], fill=W)
    d.rectangle((160, 60, 260, 360), fill=W)
    d.rectangle((270, 140, 365, 360), fill=W)
    for x, y0, y1 in ((70, 200, 340), (185, 90, 340), (295, 170, 340)):
        for y in range(y0, y1, 55):
            d.rectangle((x, y, x + 22, y + 26), fill=T)
            if x == 185:
                d.rectangle((x + 30, y, x + 52, y + 26), fill=T)
    save(im, "stadt")


def lager():
    im, d = canvas()
    d.polygon([(30, 150), (200, 50), (370, 150), (370, 360), (30, 360)], fill=W)
    d.rectangle((110, 190, 290, 360), fill=T)
    for y in (215, 260, 305):
        d.rectangle((125, y, 275, y + 26), fill=W)
    save(im, "lager")


def strasse():
    im, d = canvas()
    d.polygon([(150, 30), (250, 30), (380, 370), (20, 370)], fill=W)
    for y0, y1, w0, w1 in ((50, 110, 8, 12), (150, 220, 14, 18), (270, 350, 20, 26)):
        d.polygon([(200 - w0, y0), (200 + w0, y0), (200 + w1, y1), (200 - w1, y1)], fill=T)
    save(im, "strasse")


def gleis():
    im, d = canvas()
    for y in range(50, 360, 62):
        d.rounded_rectangle((60, y, 340, y + 30), 8, fill=W)        # Schwellen
    d.rectangle((110, 20, 140, 380), fill=W)
    d.rectangle((260, 20, 290, 380), fill=W)
    # Luecke zwischen Schiene und Schwelle andeuten
    for x in (100, 150, 250, 300):
        d.rectangle((x, 20, x + 4, 380), fill=T)
    save(im, "gleis")


def weizen():
    im, d = canvas()
    d.rounded_rectangle((188, 120, 212, 380), 12, fill=W)
    for i in range(4):
        y = 90 + i * 62
        for side in (-1, 1):
            cx = 200 + side * 52
            box = (cx - 42, y - 26, cx + 42, y + 26)
            g = Image.new("RGBA", (S, S), T)
            gd = ImageDraw.Draw(g)
            gd.ellipse(box, fill=W)
            g = g.rotate(side * 35, center=(cx, y))
            im.alpha_composite(g)
    d.ellipse((168, 20, 232, 110), fill=W)
    save(im, "weizen")


def spitzhacke():
    im, d = canvas()
    g = Image.new("RGBA", (S, S), T)
    gd = ImageDraw.Draw(g)
    gd.rounded_rectangle((182, 90, 218, 390), 18, fill=W)           # Stiel
    gd.chord((40, 40, 360, 260), 200, 340, fill=W)                  # Kopf (Bogen)
    gd.chord((70, 75, 330, 260), 200, 340, fill=T)
    gd.rounded_rectangle((160, 60, 240, 130), 16, fill=W)           # Auge
    g = g.rotate(-35, center=(200, 200), resample=Image.BICUBIC)
    im.alpha_composite(g)
    save(im, "spitzhacke")


def uhr():
    im, d = canvas()
    d.ellipse((30, 30, 370, 370), fill=W)
    d.ellipse((70, 70, 330, 330), fill=T)
    d.rounded_rectangle((185, 100, 215, 215), 15, fill=W)
    d.line((200, 200, 275, 250), fill=W, width=30)
    d.ellipse((180, 180, 220, 220), fill=W)
    save(im, "uhr")


# ---- W-05 S7 (Mira, Sprint 7 Block C): Industrie-Icons fuer die Weltmarker (world/industry_markers.gd)
def muehle():
    im, d = canvas()
    d.polygon([(165, 190), (235, 190), (270, 385), (130, 385)], fill=W)       # Turm
    d.rounded_rectangle((182, 310, 218, 385), 10, fill=T)                       # Tuer
    cx, cy = 200, 165
    for k in range(4):                                                          # 4 Fluegel, diagonal
        a = math.radians(45 + 90 * k)
        ux, uy = math.cos(a), math.sin(a)
        vx, vy = -uy, ux
        p = lambda r, w: (cx + ux * r + vx * w, cy + uy * r + vy * w)
        d.polygon([p(10, -14), p(165, -14), p(165, 14), p(10, 14)], fill=W)     # Rute
        d.polygon([p(55, 14), p(165, 14), p(165, 62), p(55, 62)], fill=W)       # Blatt
    d.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), fill=W)
    save(im, "muehle")


def blitz():
    im, d = canvas()
    d.polygon([(235, 20), (90, 230), (190, 230), (150, 380), (310, 160), (210, 160), (260, 20)], fill=W)
    save(im, "blitz")


def axt():
    im, d = canvas()
    g = Image.new("RGBA", (S, S), T)
    gd = ImageDraw.Draw(g)
    gd.rounded_rectangle((220, 40, 256, 390), 16, fill=W)                       # Stiel
    gd.polygon([(226, 70), (120, 40), (70, 60), (60, 150), (70, 240), (120, 260), (226, 200)], fill=W)   # Blatt links
    gd.ellipse((40, 40, 110, 260), fill=W)                                      # Schneide rund
    g = g.rotate(-20, center=(200, 200), resample=Image.BICUBIC)
    im.alpha_composite(g)
    save(im, "axt")


def stahl():
    im, d = canvas()
    d.rectangle((60, 60, 340, 120), fill=W)                                     # Doppel-T-Traeger
    d.rectangle((170, 120, 230, 280), fill=W)
    d.rectangle((60, 280, 340, 340), fill=W)
    save(im, "stahl")


def werkzeug():
    im, d = canvas()
    g = Image.new("RGBA", (S, S), T)
    gd = ImageDraw.Draw(g)
    gd.rounded_rectangle((175, 130, 225, 380), 22, fill=W)                      # Griff
    gd.ellipse((110, 20, 290, 200), fill=W)                                     # Maulschluessel-Kopf
    gd.rectangle((170, 10, 230, 110), fill=T)                                   # Maul
    g = g.rotate(-40, center=(200, 200), resample=Image.BICUBIC)
    im.alpha_composite(g)
    save(im, "werkzeug")


def erz():
    im, d = canvas()
    d.polygon([(200, 30), (330, 130), (290, 360), (110, 360), (70, 130)], fill=W)   # Erzbrocken
    d.line([(200, 30), (200, 200), (110, 360)], fill=T, width=18)
    d.line([(200, 200), (330, 130)], fill=T, width=18)
    d.line([(200, 200), (290, 360)], fill=T, width=14)
    save(im, "erz")


S7_ICONS = (muehle, blitz, axt, stahl, werkzeug, erz)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    if "--nur-s7" in sys.argv:          # W-05: nur die neuen Industrie-Icons, Bestand bleibt bytegleich
        for f in S7_ICONS:
            f()
        print("ok s7", len(S7_ICONS))
        sys.exit(0)
    for f in (geld, lkw, zug, lizenz, fabrik, stadt, lager, strasse, gleis, weizen, spitzhacke, uhr):
        f()
    print("ok", len(os.listdir(OUT)))
