#!/usr/bin/env python3
"""Design Sprint Welt (TEAM-02): Boden-/Biom-Regeln als Vorschau (Draufsicht 512² mit Schummerung).
Aufruf (aus ws_c/):  python3 -I tools_ds/boden_vorschau.py _out/<variante> <bilder_dir> <tag>
Schreibt <tag>_boden_vorher.png (S7-Shaderlogik: Gras/Aue/Fels/Schnee), <tag>_boden_nachher.png (Regeln 08_landschaft.md (b)),
<tag>_boden_legende.png und gibt Flaechenanteile + Kontrast gegen Marker (S-08) aus. Regeln hier = Referenz fuer den Shader.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "slice", "tools"))
sys.path.insert(0, HERE)
import world_validate as WV  # noqa: E402
from relief_kennzahlen import load, hillshade  # noqa: E402

G = 512
# Palette (Hex, sRGB). Kenney-Flachfarben, auf S-08 (gras #73945C) heruntergemischt, damit Marker/Ghost >= 3:1 bleiben
PAL = {
    "wiese":      "#73945C",   # S-08 gras (Bestand)
    "auenboden":  "#7D9959",   # terrain.gdshader c_aue (Bestand), feucht-gelbgruen
    "sumpf":      "#5F7352",   # dunkles Oliv, leicht blaustichig
    "acker_hell": "#C2A866",   # Getreide/Stoppel (Kenney crops_wheat gedaempft)
    "acker_dunkel": "#8F7350", # umgebrochen (Kenney dirtDark #B56845 gedaempft)
    "heide":      "#8C8462",   # Heide/Magerrasen, oliv-braun
    "waldboden":  "#55734A",   # unter Baeumen, dunkler als Wiese (Kenney leafsDark gedaempft)
    "schotter":   "#A39D90",   # Hangschutt, Kiesbank
    "fels":       "#807361",   # S-08 berg_stein (Bestand)
    "schnee":     "#F2F2F7",   # S-08 berg_schnee (Bestand)
    "ufer":       "#6B7054",   # terrain.gdshader c_ufer (Bestand)
    "wasser":     "#345F7E",   # water.gdshader c_tief
}
ORDER = ["wiese", "auenboden", "sumpf", "acker_hell", "acker_dunkel", "heide", "waldboden", "schotter", "fels", "schnee", "ufer", "wasser"]


def rgb(h):
    return np.array([int(h[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float64)


def lum(c):
    c = c / 255.0
    c = np.where(c <= 0.03928, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def kontrast(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def hash2(ix, iy, s):
    v = np.sin(ix * 127.1 + iy * 311.7 + s * 74.7) * 43758.5453
    return v - np.floor(v)


def vnoise(x, y, s):
    ix, iy = np.floor(x), np.floor(y)
    fx, fy = x - ix, y - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy, s), hash2(ix + 1, iy, s)
    c, d = hash2(ix, iy + 1, s), hash2(ix + 1, iy + 1, s)
    return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fy


def klassen(h, slope, fl, M):
    """Bodenklasse je Feld nach Hoehe h [m], Steigung slope [Promille], Feuchte, Siedlungsnaehe. Rueckgabe: Index in ORDER."""
    yy, xx = np.mgrid[0:G, 0:G].astype(np.float64)
    water = (fl & 1) == 1
    aue = (fl & 2) == 2
    dw = nd.distance_transform_edt(~water) * 25.0                     # m zum Wasser
    rel = nd.uniform_filter(h, 41) - h                                 # Mulde (+) / Kuppe (-) gegen 1 km Umfeld
    n1 = vnoise(xx / 9.0, yy / 9.0, 1) * 0.6 + vnoise(xx / 3.0, yy / 3.0, 2) * 0.4
    feuchte = np.clip(1.0 - dw / 1500.0, 0, 1) * 0.6 + np.clip(rel / 20.0, -0.3, 0.3) + (n1 - 0.5) * 0.4
    # Siedlungsnaehe: Abstand zum naechsten Stadtzentrum in m, Ackerguertel 1,5-4 Radien
    ds = np.full(h.shape, 1e9)
    rad = np.zeros(h.shape)
    for c in M["staedte"]:
        d = np.hypot(xx - c["x_felder"], yy - c["y_felder"]) * 25.0
        r = {"dorf": 225.0, "kleinstadt": 450.0, "stadt": 800.0}.get(c["stufe"], 300.0)
        m = d < ds
        ds = np.where(m, d, ds)
        rad = np.where(m, r, rad)
    k = np.zeros(h.shape, dtype=np.int64)            # 0 wiese
    K = {n: i for i, n in enumerate(ORDER)}
    # Auenboden: Aue-Maske oder flach am Fluss
    k[(aue | ((dw < 500) & (slope < 25))) & ~water] = K["auenboden"]
    # Sumpf: sehr flach, sehr feucht, in der Aue, fleckig (~10-15 % der Aue)
    k[(k == K["auenboden"]) & (slope < 12) & (feuchte > 0.62) & (n1 > 0.55)] = K["sumpf"]
    # Acker: Guertel um Siedlungen (bis 4 Radien bzw. max 1,6 km), Steigung < 6 %, nicht nass; Gewann-Bloecke 200 x 125 m
    bx, by = np.floor((xx * 0.8 + yy * 0.6) / 8.0), np.floor((-xx * 0.6 + yy * 0.8) / 5.0)
    blk = hash2(bx, by, 5)
    # Guertel nicht kreisrund: Abstand mit grobem Rauschen (+-500 m) verbiegen, damit keine Ringe entstehen
    dsn = ds + (vnoise(xx / 14.0, yy / 14.0, 3) - 0.5) * 1000.0
    p_acker = np.clip(1.0 - (dsn - rad) / np.minimum(rad * 3.0, 1600.0), 0, 1) * 0.85
    acker = (ds > rad * 0.9) & (slope < 60) & (feuchte < 0.6) & (blk < p_acker) & ~water & (h < 450)
    k[acker] = np.where(hash2(bx, by, 9)[acker] < 0.55, K["acker_hell"], K["acker_dunkel"])
    # Heide: trocken, maessig hoch, flach bis maessig steil, siedlungsfern
    k[(feuchte < 0.12) & (h > 180) & (h < 520) & (slope < 150) & (ds > 1200) & (n1 > 0.45) & ~acker] = K["heide"]
    # Waldboden: Hang 12-60 % oder Bergwald 380-900 m, siedlungsfern; plus Wald-Polygone
    wald = ((slope >= 120) & (slope < 600) & (h < 900)) | ((h >= 380) & (h < 900) & (slope >= 50))
    wald &= (ds > rad + 300) & (n1 > 0.38)
    for g in M["gelaende"]:
        if g["typ"] == "wald":
            from matplotlib.path import Path
            P = Path(np.array(g["polygon"], dtype=np.float64))
            inside = P.contains_points(np.stack([xx.ravel() + 0.5, yy.ravel() + 0.5], 1)).reshape(h.shape)
            wald |= inside
    k[wald & ~acker & ~water] = K["waldboden"]
    # Schotter: Hangschutt unter Fels (35-60 %, > 550 m)
    k[(slope >= 350) & (slope < 600) & (h > 550)] = K["schotter"]
    # Fels: > 60 % oder hoch und steil
    k[(slope >= 600) | ((h > 850) & (slope > 250))] = K["fels"]
    # Schnee: nur Gipfellagen > 1000 m, nicht steil (Annahme: Schneelinie 1000 statt 780 m)
    k[(h > 1000) & (slope < 550)] = K["schnee"]
    # Ufer: Saum 1 Feld am Wasser, Wasser
    ufer = nd.binary_dilation(water) & ~water
    k[ufer & (k != K["fels"])] = K["ufer"]
    k[water] = K["wasser"]
    return k


def vorher(h, slope, fl):
    """Nachbau der S7-Shaderlogik (terrain.gdshader) je Feld: Gras/Aue/Fels/Schnee/Wasser."""
    K = {n: i for i, n in enumerate(ORDER)}
    k = np.full(h.shape, K["wiese"])
    k[(fl & 2) == 2] = K["auenboden"]
    hang = 1.0 - np.cos(np.arctan(slope / 1000.0))
    k[(hang > 0.5) | ((h > 450) & (hang > 0.1))] = K["fels"]
    k[(h > 800) & (hang < 0.45)] = K["schnee"]
    k[(fl & 1) == 1] = K["wasser"]
    return k


def render(k, h, path, crop=None, scale=1):
    cols = np.stack([rgb(PAL[n]) for n in ORDER])
    img = cols[k]
    # Acker-Streifen (Gewann-Fluren) andeuten: jede 2. Zeile im Block leicht heller
    hs = hillshade(h, z=1.4)
    img = img * (0.62 + 0.5 * hs[..., None])
    if crop:
        y0, x0, n = crop
        img = img[y0:y0 + n, x0:x0 + n]
    im = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
    im.save(path)


def main():
    d, bdir, tag = sys.argv[1], sys.argv[2], sys.argv[3]
    meta, M, nodes, fl = load(d)
    h = WV.field_heights(nodes)
    slope = WV.field_slope_pm(h)
    k = klassen(h, slope, fl, M)
    k0 = vorher(h, slope, fl)
    render(k0, h, os.path.join(bdir, "%s_boden_vorher.png" % tag))
    render(k, h, os.path.join(bdir, "%s_boden_nachher.png" % tag))
    # Ausschnitt um die groesste Stadt (Ackerguertel sichtbar), 3 x vergroessert
    c = max(M["staedte"], key=lambda c: c["einwohner_anzahl"])
    y0, x0 = int(np.clip(c["y_felder"] - 80, 0, G - 160)), int(np.clip(c["x_felder"] - 80, 0, G - 160))
    render(k0, h, os.path.join(bdir, "%s_boden_vorher_stadt.png" % tag), crop=(y0, x0, 160), scale=3)
    render(k, h, os.path.join(bdir, "%s_boden_nachher_stadt.png" % tag), crop=(y0, x0, 160), scale=3)
    for a, b, o in (("vorher", "nachher", "vergleich"), ("vorher_stadt", "nachher_stadt", "vergleich_stadt")):
        A = Image.open(os.path.join(bdir, "%s_boden_%s.png" % (tag, a)))
        B = Image.open(os.path.join(bdir, "%s_boden_%s.png" % (tag, b)))
        S = Image.new("RGB", (A.width * 2 + 8, A.height), (30, 30, 30))
        S.paste(A, (0, 0))
        S.paste(B, (A.width + 8, 0))
        S.save(os.path.join(bdir, "%s_boden_%s.png" % (tag, o)))
    # Legende + Kontrast
    saum, marker = rgb("#0F1720"), rgb("#FFC21A")
    L = Image.new("RGB", (560, 26 * len(ORDER) + 8), (250, 250, 250))
    dr = ImageDraw.Draw(L)
    rows = {}
    for i, n in enumerate(ORDER):
        c = rgb(PAL[n])
        ks, km = kontrast(c, saum), kontrast(c, marker)
        anteil = float((k == i).mean() * 100)
        rows[n] = {"hex": PAL[n], "anteil_pct": round(anteil, 1), "anteil_vorher_pct": round(float((k0 == i).mean() * 100), 1),
                   "kontrast_saum": round(ks, 2), "kontrast_marker": round(km, 2), "ok_3zu1": bool(max(ks, km) >= 3.0)}
        dr.rectangle([8, 6 + i * 26, 48, 26 + i * 26], fill=tuple(int(v) for v in c), outline=(40, 40, 40))
        dr.text((58, 10 + i * 26), "%-13s %s  %5.1f %%   Saum %.1f:1  Marker %.1f:1" % (n, PAL[n], anteil, ks, km), fill=(20, 20, 20))
    L.save(os.path.join(bdir, "%s_boden_legende.png" % tag))
    json.dump(rows, open(os.path.join(d, "boden_anteile.json"), "w"), ensure_ascii=False, indent=1)
    for n, r in rows.items():
        print(n, r)


if __name__ == "__main__":
    main()
