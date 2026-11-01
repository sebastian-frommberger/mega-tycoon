#!/usr/bin/env python3
"""S-05 Pruefung Palette v1 (Sophie). Aufruf: python3 s05_pruefung.py   (im Ordner s05/)
Liest palette_v1.csv, rechnet
  1. Saettigung der Gelaendefarben (HSV, Grenze 35 %)
  2. Paar-Abstaende CIEDE2000 je Gruppe in 5 Modi (Normal, Deuteranopie, Protanopie, Tritanopie, Graustufen)
  3. WCAG-Kontrast der Marker gegen Gelaende / UI-Panel / Umriss
  4. Formunterschied Kreis/Achteck/Dreieck je Anzeigegroesse (Geometrie-Rechnung)
und schreibt pruefung_ergebnis.txt, pruefung_paare.csv und swatch_modi.png."""
import csv, itertools, math, colorsys
from cvd import *
from PIL import Image, ImageDraw

LIMIT = 10.0
rows = [r for r in csv.reader(open("palette_v1.csv")) if r and not r[0].startswith("#")]
pal = {r[0]: (r[1], r[2]) for r in rows}
rgb = lambda n: hex2rgb(pal[n][0])
out = []
P = out.append

P("S-05 Pruefung Palette v1 - gerechnet, NICHT an Personen geprueft")
P("Selbsttest CIEDE2000/Matrizen: %s" % selbsttest())
P("")
P("1. Saettigung Gelaende (HSV-S, Grenze 0.35)")
for n, (h, g) in pal.items():
    if g == "terrain":
        r, gg, b = [x / 255 for x in hex2rgb(h)]
        s = colorsys.rgb_to_hsv(r, gg, b)[1]
        P("   %-14s %s  S=%.2f  %s" % (n, h, s, "ok" if s <= 0.35 else "UEBER 35 %"))
P("")

P("2. Paar-Abstaende CIEDE2000, Grenze %.0f (QA-Richtwert Daniel, Annahme)" % LIMIT)
pairs_csv = [["gruppe", "farbe_a", "farbe_b"] + MODES + ["min_farbmodi", "min_alle", "kollision_nur_graustufen", "kollision_farbmodi"]]
groups = {}
for n, (h, g) in pal.items():
    if g in ("status", "netz", "gueter_entwurf"):
        groups.setdefault(g, []).append(n)
for g, names in groups.items():
    P("   Gruppe %s" % g)
    for a, b in itertools.combinations(names, 2):
        v = [delta_e(rgb(a), rgb(b), m) for m in MODES]
        farb = min(v[:4])
        alle = min(v)
        flag = ""
        if farb < LIMIT:
            flag = "KOLLISION in Farbmodi"
        elif alle < LIMIT:
            flag = "nur Graustufen < 10 (Form/Muster muss tragen)"
        P("   %-18s %-18s %s  %s" % (a, b, " ".join("%5.1f" % x for x in v), flag))
        pairs_csv.append([g, a, b] + ["%.1f" % x for x in v] + ["%.1f" % farb, "%.1f" % alle, int(farb >= LIMIT and alle < LIMIT), int(farb < LIMIT)])
P("   Spalten: " + " / ".join(MODES))
P("")
P("   Marker (Status) auf Spielernetz Signalorange - Marker liegt oft auf der Linie:")
for n in groups["status"]:
    v = [delta_e(rgb(n), rgb("spieler_orange"), m) for m in MODES]
    P("   %-18s %-18s %s" % (n, "spieler_orange", " ".join("%5.1f" % x for x in v)))
    pairs_csv.append(["marker_auf_netz", n, "spieler_orange"] + ["%.1f" % x for x in v] + ["%.1f" % min(v[:4]), "%.1f" % min(v), int(min(v[:4]) >= LIMIT and min(v) < LIMIT), int(min(v[:4]) < LIMIT)])
P("")

P("3. WCAG-Kontrast (Normalsicht; Richtwert 3:1 fuer Symbole, 4.5:1 fuer Text)")
terr = [n for n, (h, g) in pal.items() if g == "terrain"]
P("   Marker-Fuellung gegen dunklen Umriss %s und hellen Umriss %s:" % (pal["outline_dunkel"][0], pal["outline_hell"][0]))
for n in groups["status"] + ["ok_ring"]:
    P("   %-16s dunkel %.1f:1   hell %.1f:1   bg_panel %.1f:1" % (n, contrast(rgb(n), rgb("outline_dunkel")), contrast(rgb(n), rgb("outline_hell")), contrast(rgb(n), rgb("bg_panel"))))
P("   Dunkler Umriss (Karte) gegen Gelaende:")
for t in terr:
    P("   %-14s %.1f:1" % (t, contrast(rgb("outline_dunkel"), rgb(t))))
P("   Marker-Aufbau Dunkelring 2 px + heller Halo 1 px: wirksam ist der kontrastreichere Ring (>= 3:1 gefordert):")
for t in terr:
    d_, h_ = contrast(rgb("outline_dunkel"), rgb(t)), contrast(rgb("outline_hell"), rgb(t))
    P("   %-14s dunkel %.1f  hell %.1f  -> max %.1f:1  %s" % (t, d_, h_, max(d_, h_), "ok" if max(d_, h_) >= 3 else "UNTER 3:1"))
P("   Heller Umriss (UI-Panel %s) gegen Panel: %.1f:1" % (pal["bg_panel"][0], contrast(rgb("outline_hell"), rgb("bg_panel"))))
P("   Glyph im Marker: weiss #FFFFFF auf rot %.1f:1, auf blau %.1f:1; dunkel #14161A auf gelb %.1f:1" % (
    contrast((255, 255, 255), rgb("kritisch_rot")), contrast((255, 255, 255), rgb("hinweis_blau")), contrast(hex2rgb("#14161A"), rgb("warnung_gelb"))))
P("   Marker-Fuellung gegen Gelaende (ohne Umriss, zeigt warum der Umriss Pflicht ist):")
for n in groups["status"]:
    P("   %-16s " % n + "  ".join("%s %.1f" % (t[:5], contrast(rgb(n), rgb(t))) for t in terr))
P("")
P("   Kontrast nach CVD-Simulation (Marker gegen dunklen Umriss, Minimum ueber Modi)")
for n in groups["status"]:
    P("   %-16s min %.1f:1" % (n, min(contrast(rgb(n), rgb("outline_dunkel"), m) for m in MODES)))
P("")

P("4. Formunterschied (Geometrie, nicht Wahrnehmung): Achteck (Umkreis = Kreis) vs. Kreis")
dev = 1 - math.cos(math.radians(22.5))
P("   Max. radiale Abweichung Achteck/Kreis = r*(1-cos 22.5 Grad) = %.3f*r; Flaechenunterschied %.1f %%" % (dev, (1 - 2 * math.sqrt(2) / math.pi) * 100))
P("   Durchmesser px | max. Abweichung in px | Bewertung")
for d in (12, 16, 20, 24, 26, 32, 48):
    px = dev * d / 2
    P("   %14d | %21.2f | %s" % (d, px, "Form allein reicht NICHT (<1 px)" if px < 1.0 else "Form sichtbar (>=1 px), mit Glyph sicher"))
P("   Folge: Achteck vs. Kreis unter ca. 26 px Durchmesser nur mit Glyph (Balken im Achteck) unterscheidbar.")
P("   Kreis/Achteck gegen Dreieck: Ecken weit ueber 1 px ab ca. 12 px.")

P("")
P("5. Netzfarben gegen Gelaende (Linien muessen auf der Karte stehen): min. CIEDE2000 ueber Farbmodi / Graustufen")
P("   (Dunkler Linien-Saum 'Casing' = outline_dunkel 1.5 px gedacht; Kontrast des Saums gegen Gelaende siehe Punkt 3)")
for n in groups["netz"]:
    cells = []
    for t in terr:
        fm = min(delta_e(rgb(n), rgb(t), m) for m in MODES[:4])
        gs = delta_e(rgb(n), rgb(t), "Graustufen")
        cells.append("%s %.0f/%.0f%s" % (t[:5], fm, gs, "!" if min(fm, gs) < LIMIT else ""))
    P("   %-16s " % n + "  ".join(cells))
P("   ('!' = unter 10 in mindestens einem Modus ohne Saum; mit Saum traegt der Kontrast des Saums)")

open("pruefung_ergebnis.txt", "w").write("\n".join(out) + "\n")
with open("pruefung_paare.csv", "w", newline="") as f:
    csv.writer(f).writerows(pairs_csv)
print("\n".join(out))

# ---------------- Swatch-Bild: je Modus eine Zeile ----------------
def octagon(cx, cy, r):
    return [(cx + r * math.cos(math.radians(22.5 + 45 * i)), cy + r * math.sin(math.radians(22.5 + 45 * i))) for i in range(8)]

def tri(cx, cy, r):
    return [(cx, cy - r), (cx + r * 0.95, cy + r * 0.62), (cx - r * 0.95, cy + r * 0.62)]

def draw_marker(d, kind, cx, cy, r, fill, outline, glyph, w):
    if kind == "circle":
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill, outline=outline, width=w)
    elif kind == "tri":
        d.polygon(tri(cx, cy, r), fill=fill, outline=outline, width=w)
    elif kind == "oct":
        d.polygon(octagon(cx, cy, r), fill=fill, outline=outline, width=w)
    if glyph == "bar":
        d.rectangle([cx - r * 0.5, cy - r * 0.13, cx + r * 0.5, cy + r * 0.13], fill=(255, 255, 255))
    elif glyph == "bang":
        d.rectangle([cx - r * 0.09, cy - r * 0.35, cx + r * 0.09, cy + r * 0.12], fill=(20, 22, 26))
        d.rectangle([cx - r * 0.09, cy + r * 0.25, cx + r * 0.09, cy + r * 0.4], fill=(20, 22, 26))
    elif glyph == "i":
        d.rectangle([cx - r * 0.09, cy - r * 0.05, cx + r * 0.09, cy + r * 0.42], fill=(255, 255, 255))
        d.rectangle([cx - r * 0.09, cy - r * 0.42, cx + r * 0.09, cy - r * 0.25], fill=(255, 255, 255))

items = [("hinweis_blau", "circle", "i"), ("warnung_gelb", "tri", "bang"), ("kritisch_rot", "oct", "bar")]
W, H = 1180, 5 * 190 + 40
sheet = Image.new("RGB", (W, H), (255, 255, 255))
dr = ImageDraw.Draw(sheet)
tcol = [n for n in groups["netz"]]
gcol = [n for n in groups["gueter_entwurf"]]
for ri, mode in enumerate(MODES):
    y0 = 20 + ri * 190
    bg = simulate(hex2rgb(pal["gras"][0]), mode)
    dr.rectangle([0, y0, W, y0 + 180], fill=bg)
    dr.text((8, y0 + 4), mode + "   (grosse Marker 88 px mit Glyph, kleine 28 px ohne Glyph)", fill=(0, 0, 0))
    x = 20
    for n, kind, glyph in items:
        for size in (44, 14):   # gross + kleine Darstellung (28 px Durchmesser)
            f = simulate(hex2rgb(pal[n][0]), mode)
            o = simulate(hex2rgb(pal["outline_dunkel"][0]), mode)
            draw_marker(dr, kind, x + size, y0 + 70, size, f, o, glyph if size > 20 else "", 3 if size > 20 else 1)
            x += size * 2 + 14
    # Netzfarben als Linien (Spieler durchgezogen, KI gestrichelt/gepunktet)
    ly = y0 + 140
    for i, n in enumerate(tcol):
        c = simulate(hex2rgb(pal[n][0]), mode)
        xs = 90 + i * 260
        if i == 0:
            dr.line([xs, ly, xs + 230, ly], fill=c, width=9)
        elif i == 1:
            for k in range(0, 230, 40):
                dr.line([xs + k, ly, xs + k + 26, ly], fill=c, width=9)
        elif i == 2:
            for k in range(0, 230, 22):
                dr.ellipse([xs + k, ly - 5, xs + k + 10, ly + 5], fill=c)
        else:
            for k in range(0, 230, 60):
                dr.line([xs + k, ly, xs + k + 14, ly], fill=c, width=9)
                dr.line([xs + k + 24, ly, xs + k + 26, ly], fill=c, width=9)
    # Gueterfarben (Entwurf)
    gx = 720
    for i, n in enumerate(gcol):
        c = simulate(hex2rgb(pal[n][0]), mode)
        dr.rectangle([gx + i * 62, y0 + 20, gx + i * 62 + 54, y0 + 100], fill=c, outline=(20, 22, 26))
sheet.save("swatch_modi.png")
print("swatch_modi.png geschrieben")
