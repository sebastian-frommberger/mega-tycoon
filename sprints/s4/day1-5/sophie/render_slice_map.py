#!/usr/bin/env python3
"""Rendert slice_map.json nach slice_map.png (Pillow, 2 px je Feld)."""
import json, os, math
from PIL import Image, ImageDraw, ImageFont
HERE = os.path.dirname(os.path.abspath(__file__)); doc = json.load(open(HERE + "/slice_map.json"))
S = int(os.environ.get('S', 2)); N = 512; W = N * S; PAD = 0; LEG = 330 if S == 2 else 0
CROP = os.environ.get('CROP'); OUT = os.environ.get('OUT', 'slice_map.png')
img = Image.new("RGB", (W + LEG, W), (236, 233, 222)); dr = ImageDraw.Draw(img)
def F(sz, b=False):
    for p in ("/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if b else ""),):
        if os.path.exists(p): return ImageFont.truetype(p, sz)
    return ImageFont.load_default()
f12, f14, f16b = F(12), F(14), F(16, True)
def P(x, y): return (x * S, y * S)
col = {"meer": (150, 190, 215), "gebirge": (160, 150, 140), "wald": (120, 160, 110)}
dr.rectangle([0, 0, W, W], fill=(226, 232, 205))
for g in doc["gelaende"]:
    dr.polygon([P(*q) for q in g["polygon"]], fill=col[g["typ"]], outline=(90, 90, 90))
for fl in doc["fluesse"]:
    pts = [P(*q) for q in fl["linie"]]; dr.line(pts, fill=(60, 120, 190), width=fl["breite_felder"] * S + 2, joint="curve")
for i in range(0, N + 1, 64):
    dr.line([P(i, 0), P(i, N)], fill=(190, 190, 180), width=1); dr.line([P(0, i), P(N, i)], fill=(190, 190, 180), width=1)
    dr.text((i * S + 3, 2), str(i), font=f12, fill=(80, 80, 80)); dr.text((3, i * S + 2), str(i), font=f12, fill=(80, 80, 80))
pos = {s["id"]: (s["x_felder"], s["y_felder"]) for s in doc["staedte"]}; pos.update({i["id"]: (i["x_felder"], i["y_felder"]) for i in doc["industrien"]})
kc = {"k1": (200, 140, 20), "k2": (150, 60, 160), "k3": (30, 30, 30), "hafen": (110, 110, 110)}
for k in doc["ketten"]:
    c = kc[k["id"]]
    for s in k["strecken"]:
        a, b = P(*pos[s["von"]]), P(*pos[s["nach"]])
        if k["im_slice"] is False:
            n = 18
            for t in range(0, n, 2):
                dr.line([(a[0] + (b[0]-a[0]) * t / n, a[1] + (b[1]-a[1]) * t / n), (a[0] + (b[0]-a[0]) * (t+1) / n, a[1] + (b[1]-a[1]) * (t+1) / n)], fill=c, width=2)
        else: dr.line([a, b], fill=c, width=3)
        m = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2); t = str(s["luftlinie_felder"])
        dr.rectangle([m[0] - 9, m[1] - 8, m[0] + 9, m[1] + 8], fill=(255, 255, 255), outline=c); dr.text((m[0] - 8, m[1] - 8), t, font=f12, fill=(0, 0, 0))
for n in doc["nischen"]:
    a, b = P(*pos[n["von"]]), P(*pos[n["nach"]]); dr.line([a, b], fill=(220, 40, 40), width=1)
sym = {"getreidefarm": "G", "muehle": "M", "kohlemine": "K", "erzmine": "E", "kraftwerk": "P", "stahlwerk": "S", "werkzeugfabrik": "W", "holzfaeller": "H", "saegewerk": "Sg"}
for i in doc["industrien"]:
    x, y = P(i["x_felder"], i["y_felder"]); r = 9
    fill = (250, 250, 250) if i["im_slice"] else (210, 210, 210)
    if i["rolle"] == "rohstoff" or i["rolle"] == "bau_quelle": dr.polygon([(x, y - r - 1), (x + r + 1, y + r), (x - r - 1, y + r)], fill=fill, outline=(0, 0, 0))
    else: dr.rectangle([x - r, y - r, x + r, y + r], fill=fill, outline=(0, 0, 0), width=2)
    dr.text((x - 5 * len(sym[i["typ"]]) // 1, y - 6 + (3 if i["rolle"] in ("rohstoff", "bau_quelle") else 0)), sym[i["typ"]], font=f12, fill=(0, 0, 0))
hqs = {h["stadt"]: h["archetyp"] for h in doc["hq_optionen"]}; hq_slice = {h["stadt"]: h["im_slice"] for h in doc["hq_optionen"]}
rad = {"dorf": 7, "kleinstadt": 10, "stadt": 14, "metropole": 18}
for s in doc["staedte"]:
    x, y = P(s["x_felder"], s["y_felder"]); r = rad[s["stufe"]]
    dr.ellipse([x - r, y - r, x + r, y + r], fill=(235, 90, 70), outline=(0, 0, 0), width=2)
    lab = "%s (%s, %d)" % (s["name"], s["stufe"], s["einwohner_anzahl"]); tx = x + r + 4 if x < W - 230 else x - r - 4 - 8 * len(lab) * 0.78
    dr.text((tx, y - 22), lab, font=f14, fill=(0, 0, 0), stroke_width=2, stroke_fill=(255, 255, 255))
    if s["id"] in hqs:
        dr.text((x + r + 4, y - 6), "HQ " + hqs[s["id"]] + ("" if hq_slice[s["id"]] else " (nicht im Slice)"), font=f12, fill=(120, 0, 0), stroke_width=2, stroke_fill=(255, 255, 255))
        # Einflussradius gestrichelt
        rr = [h for h in doc["hq_optionen"] if h["stadt"] == s["id"]][0]["radius_felder"] * S
        for a in range(0, 360, 6):
            a1, a2 = math.radians(a), math.radians(a + 3)
            dr.line([(x + rr * math.cos(a1), y + rr * math.sin(a1)), (x + rr * math.cos(a2), y + rr * math.sin(a2))], fill=(120, 0, 0), width=1)
for q in (256,):
    for t in range(0, W, 16):
        dr.line([(q*S, t), (q*S, t+8)], fill=(40, 40, 160), width=2); dr.line([(t, q*S), (t+8, q*S)], fill=(40, 40, 160), width=2)
lx = W + 14; y = 14
if S != 2: lx = 10**6
dr.text((lx, y), "Slice-Karte 512 x 512 Felder", font=f16b, fill=(0, 0, 0)); y += 22
dr.text((lx, y), "1 Feld = 10 m, S-10, eingefroren 15.12.", font=f12, fill=(60, 60, 60)); y += 26
for txt, c, d in [("K1 Getreide-Muehle-Stadt", kc["k1"], 0), ("K2 Kohle-Kraftwerk", kc["k2"], 0), ("K3 Erz+Kohle-Stahl-Werkzeug", kc["k3"], 0)]:
    dr.line([(lx, y + 7), (lx + 34, y + 7)], fill=c, width=3); dr.text((lx + 42, y), txt, font=f12, fill=(0, 0, 0)); y += 20
dr.line([(lx, y + 7), (lx + 34, y + 7)], fill=(220, 40, 40), width=1); dr.text((lx + 42, y), "Lkw/Zug-Nische (~25 Felder)", font=f12, fill=(0, 0, 0)); y += 20
dr.text((lx, y), "Zahl im Kasten = Luftlinie in Feldern", font=f12, fill=(0, 0, 0)); y += 28
for txt in ["Kreis rot: Stadt (Groesse = Stufe)", "Quadrat: Verarbeiter/Abnehmer", "Dreieck: Rohstoff/Bau-Quelle (Holz)", "rot gestrichelt: HQ-Einflussradius", "G Farm  M Muehle  K Kohle  E Erz", "P Kraftwerk  S Stahl  W Werkzeug", "H Holzfaeller (Bau-Quelle)", "Hafen/Handel-HQ: nicht im Slice", "Quadrantengrenzen bei 256 (gestrichelt)"]:
    dr.text((lx, y), txt, font=f12, fill=(0, 0, 0)); y += 18
y += 10
for g, c in col.items():
    dr.rectangle([lx, y, lx + 20, y + 12], fill=c, outline=(80, 80, 80)); dr.text((lx + 28, y - 1), g, font=f12, fill=(0, 0, 0)); y += 20
dr.rectangle([lx, y, lx + 20, y + 12], fill=(60, 120, 190)); dr.text((lx + 28, y - 1), "Fluss", font=f12, fill=(0, 0, 0))
if CROP:
    x0, y0, x1, y1 = [int(v) * S for v in CROP.split(",")]; img = img.crop((x0, y0, x1, y1))
img.save(HERE + "/" + OUT); print("ok", OUT, img.size)
