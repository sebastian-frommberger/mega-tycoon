#!/usr/bin/env python3
"""Phase 4 Welle 2 (Aylin): Ergaenzungs-Icons fuer die Prototyp-Schilder, Stil wie ui/tools/make_icons.py
(weisse Silhouette 100x100, transparent, 4x Supersampling; im Spiel per modulate eingefaerbt).
Kenney Game Icons und c_*.png kennen kein Mehl, Fleisch, Kettenglied, Dorf, Person.
Aufruf (Repo-Wurzel): python3 -I tools_proto/aylin_icons.py slice/proto/proto_icons
Deterministisch (keine Zufallswerte)."""
import os
import sys
from PIL import Image, ImageDraw

S = 400
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
W = (255, 255, 255, 255)
T = (0, 0, 0, 0)


def canvas():
    im = Image.new("RGBA", (S, S), T)
    return im, ImageDraw.Draw(im)


def save(im, name):
    im.resize((100, 100), Image.LANCZOS).save(os.path.join(OUT, "p_%s.png" % name))


def mehl():
    """Mehlsack: Sack mit gebundenem Hals, Band als Ausschnitt, kleine Aehre als Ausschnitt auf dem Bauch."""
    im, d = canvas()
    d.rounded_rectangle((90, 130, 310, 370), radius=60, fill=W)            # Bauch
    d.polygon([(150, 140), (250, 140), (276, 70), (124, 70)], fill=W)       # Hals mit Zipfeln
    d.ellipse((104, 40, 160, 100), fill=W)
    d.ellipse((240, 40, 296, 100), fill=W)
    d.rectangle((140, 128, 260, 150), fill=T)                               # Band
    # Aehre (Ausschnitt): Halm + 3 Koernerpaare
    d.line((200, 330, 200, 205), fill=T, width=12)
    for i, y in enumerate((210, 245, 280)):
        d.ellipse((166, y, 198, y + 34), fill=T)
        d.ellipse((202, y, 234, y + 34), fill=T)
    d.ellipse((188, 176, 212, 214), fill=T)
    save(im, "mehl")


def fleisch():
    """Keule: Tropfenform (Fleisch), dicker Knochen mit Doppelknubbel, heller Glanzbogen als Ausschnitt."""
    im, d = canvas()
    d.ellipse((30, 40, 270, 280), fill=W)
    d.polygon([(190, 220), (240, 160), (320, 240), (260, 290)], fill=W)           # Uebergang Fleisch -> Knochen
    d.line((230, 230, 330, 330), fill=W, width=54)                               # Knochen
    d.ellipse((300, 330, 372, 402), fill=W)
    d.ellipse((335, 295, 407, 367), fill=W)
    d.arc((70, 80, 220, 230), 190, 280, fill=T, width=20)                        # Glanzbogen
    save(im, "fleisch")


def kette():
    """Zwei ineinandergreifende Glieder (Lieferkette)."""
    im, d = canvas()
    d.rounded_rectangle((20, 120, 230, 280), radius=80, fill=W)
    d.rounded_rectangle((60, 160, 190, 240), radius=40, fill=T)
    d2 = Image.new("RGBA", (S, S), T)
    e = ImageDraw.Draw(d2)
    e.rounded_rectangle((170, 120, 380, 280), radius=80, fill=W)
    e.rounded_rectangle((210, 160, 340, 240), radius=40, fill=T)
    im.alpha_composite(d2)
    # Ueberkreuzung: linkes Glied ueber das rechte, wo sie sich schneiden
    cut = Image.new("RGBA", (S, S), T)
    c = ImageDraw.Draw(cut)
    c.rounded_rectangle((20, 120, 230, 280), radius=80, outline=W, width=40)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rectangle((170, 100, 230, 150), fill=255)
    im.paste(cut, (0, 0), Image.composite(cut.getchannel("A"), Image.new("L", (S, S), 0), mask))
    save(im, "kette")


def dorf():
    """Haus mit Satteldach und kleinem Kirchturm."""
    im, d = canvas()
    d.rectangle((60, 210, 250, 360), fill=W)
    d.polygon([(40, 220), (155, 110), (270, 220)], fill=W)
    d.rectangle((90, 270, 130, 360), fill=T)                                # Tuer
    d.rectangle((170, 255, 215, 300), fill=T)                               # Fenster
    d.rectangle((270, 150, 340, 360), fill=W)                               # Turm
    d.polygon([(260, 150), (305, 70), (350, 150)], fill=W)
    d.rectangle((296, 20, 314, 80), fill=W)                                 # Kreuz
    d.rectangle((282, 36, 328, 52), fill=W)
    d.rectangle((292, 190, 318, 230), fill=T)
    save(im, "dorf")


def person():
    im, d = canvas()
    d.ellipse((130, 40, 270, 180), fill=W)
    d.rounded_rectangle((60, 205, 340, 380), radius=90, fill=W)
    d.rectangle((60, 300, 340, 380), fill=W)
    save(im, "person")


def pfeil_rechts():
    """Pfeil nach rechts im Stil von k_arrowUp/k_arrowDown (Trend 'bleibt gleich')."""
    im, d = canvas()
    d.rounded_rectangle((40, 160, 250, 240), radius=24, fill=W)
    d.polygon([(230, 80), (370, 200), (230, 320)], fill=W)
    save(im, "pfeil_rechts")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for f in (mehl, fleisch, kette, dorf, person, pfeil_rechts):
        f()
    print("Icons nach", OUT)
