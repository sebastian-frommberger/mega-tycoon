#!/usr/bin/env python3
"""Design Sprint Welt (TEAM-02): Kennzahlen und Bilder fuer Relief-Varianten aus tools/world_gen.py --relief.
Aufruf (aus ws_c/):  python3 -I tools_ds/relief_kennzahlen.py _out <bilder_dir> s7 ds_gebirge ds_v2
Liest je Variante _out/<v>/{hoehe_s7.r16,fluss_s7.u8,world_s7_meta.json,world_s7.json}. Schreibt _out/kennzahlen.json und PNGs.
"""
import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "slice", "tools"))
import world_validate as WV  # noqa: E402

G = 512
STEP = 25.0


def load(d):
    meta = json.load(open(os.path.join(d, "world_s7_meta.json")))
    M = json.load(open(os.path.join(d, "world_s7.json")))
    n = meta["knoten"]
    h16 = np.fromfile(os.path.join(d, "hoehe_s7.r16"), dtype="<u2").reshape(n, n)
    fl = np.fromfile(os.path.join(d, "fluss_s7.u8"), dtype=np.uint8).reshape(G, G)
    return meta, M, h16.astype(np.float64) * meta["hoehe_skala_m"], fl


def kennzahlen(meta, M, nodes, fl):
    h = WV.field_heights(nodes)
    slope = WV.field_slope_pm(h)                      # Promille, Sim-Konvention
    water = (fl & 1) == 1
    aue = (fl & 2) == 2
    land = ~water
    K = {"hoehe_min_m": round(float(h.min()), 1), "hoehe_max_m": round(float(h.max()), 1)}
    # Neigungsklassen (Promille) ueber Landfelder
    edges = [0, 20, 60, 150, 300, 600, 10000]
    names = ["<2%", "2-6%", "6-15%", "15-30%", "30-60%", ">60%"]
    s = slope[land]
    K["neigung_anteil_pct"] = {nm: round(float(((s >= a) & (s < b)).mean() * 100), 1) for nm, a, b in zip(names, edges, edges[1:])}
    geb = land & (h > 400)
    K["gebirge_felder_pct"] = round(float(geb.mean() * 100), 1)
    sg = slope[geb]
    K["gebirge_neigung_median_pm"] = int(np.median(sg)) if sg.size else 0
    K["gebirge_neigung_p90_pm"] = int(np.percentile(sg, 90)) if sg.size else 0
    # Kleinteiligkeit: Hochpass (h - Gauss sigma 4 Felder = 100 m) im Gebirge, Std in m
    hp = h - nd.gaussian_filter(h, 4.0)
    K["gebirge_kleinform_std_m"] = round(float(hp[geb].std()), 2) if sg.size else 0
    # Hochpunkte: lokale Maxima (Fenster 9 x 9 Felder = 225 m) ueber 400 m, und "markante" mit >= 60 m Ueberhoehung im 1-km-Umfeld
    mx = nd.maximum_filter(h, size=9)
    peaks = (h == mx) & (h > 400)
    K["hochpunkte_225m"] = int(peaks.sum())
    mn = nd.minimum_filter(h, size=41)
    K["hochpunkte_markant"] = int((peaks & (nd.maximum_filter(h, size=41) == h) & (h - mn > 150)).sum())
    # Ruecken/Taeler: Anzahl Vorzeichenwechsel der Kruemmung entlang Zeilen im Gebirge je km (Mass fuer "Faltigkeit")
    lap = nd.laplace(nd.gaussian_filter(h, 1.0))
    sc = (np.sign(lap[:, 1:]) != np.sign(lap[:, :-1])) & geb[:, 1:]
    K["gebirge_kruemmungswechsel_je_km"] = round(float(sc.sum() / max(geb[:, 1:].sum(), 1) * 40), 2)
    # Reliefstufen nach lokaler Spanne (max-min im Radius 20 Felder = 500 m) und Hoehe
    rng = nd.maximum_filter(h, size=41) - nd.minimum_filter(h, size=41)
    st = np.full(h.shape, 0)
    st[(rng >= 25)] = 1
    st[(rng >= 90) | (h > 350)] = 2
    st[(rng >= 280) | (h > 700)] = 3
    rand = np.minimum(np.minimum(*np.mgrid[0:G, 0:G]), np.minimum(G - 1 - np.mgrid[0:G, 0:G][0], G - 1 - np.mgrid[0:G, 0:G][1]))
    inner = rand > 40
    K["reliefstufen_pct_innen"] = {nm: round(float(((st == i) & inner).sum() / inner.sum() * 100), 1)
                                   for i, nm in enumerate(["ebene", "huegelland", "mittelgebirge", "gebirge"])}
    K["huegel_validator_pct"] = round(float(((slope >= 10) & (slope <= 60) & (h < 400)).mean() * 100), 1)
    # Fluss: Breite (Felder) quer zur Achse, Aue, Brueckenquerung
    ax = meta["fluss"]["achse"]
    W = water if ax == "we" else water.T       # Spalten = Querschnitte
    wid = W.sum(axis=0)
    wid = wid[wid > 0]
    K["fluss_achse"] = ax
    K["fluss_querschnitt_felder"] = {"min": int(wid.min()), "median": float(np.median(wid)), "max": int(wid.max())}
    K["fluss_wasserfelder"] = int(water.sum())
    K["aue_felder_pct"] = round(float(aue.mean() * 100), 1)
    # Querbarkeit: je Querschnitt (Spalte bei W-O-Fluss) gerade Querung moeglich? Regel wie Validator (Lauf <= 8, Rampe <= 200)
    smax = meta["bau"]["steigung_max_promille_strasse"]
    bmax = meta["bau"]["bruecke_max_felder"]
    hm = WV.bruecken_hoehe(h, water)
    HM = hm if ax == "we" else hm.T
    ok = 0
    tot = 0
    for x in range(G):
        col = W[:, x]
        if not col.any():
            continue
        tot += 1
        ys = np.flatnonzero(col)
        # Laeufe in der Spalte
        runs = np.split(ys, np.flatnonzero(np.diff(ys) > 1) + 1)
        good = True
        for r in runs:
            a, b = r[0] - 1, r[-1] + 1
            if len(r) > bmax or a < 0 or b >= G:
                good = False
                break
            seg = HM[a:b + 1, x]
            if np.abs(np.diff(seg)).max() / STEP * 1000 > smax:
                good = False
                break
            # Rampe an den Ufern (Nachbarfelder in Laufrichtung)
            if a - 1 >= 0 and abs(HM[a, x] - HM[a - 1, x]) / STEP * 1000 > smax:
                good = False
            if b + 1 < G and abs(HM[b + 1, x] - HM[b, x]) / STEP * 1000 > smax:
                good = False
        ok += good
    K["querschnitte_gerade_querbar_pct"] = round(ok / max(tot, 1) * 100, 1)
    K["staedte"] = len(M["staedte"])
    K["industrien"] = len(M["industrien"])
    return K, h, slope, st


def hillshade(h, az=315.0, alt=40.0, z=1.0):
    gy, gx = np.gradient(h * z, STEP)
    slope = np.pi / 2 - np.arctan(np.hypot(gx, gy))
    aspect = np.arctan2(-gx, gy)
    a, b = np.radians(az), np.radians(alt)
    return np.clip(np.sin(b) * np.sin(slope) + np.cos(b) * np.cos(slope) * np.cos(a - aspect), 0, 1)


def hyps(h):
    stops = [(0, (96, 128, 80)), (150, (115, 148, 92)), (300, (140, 150, 96)), (500, (128, 115, 97)), (800, (150, 140, 130)), (1100, (242, 242, 247))]
    out = np.zeros(h.shape + (3,))
    for i in range(3):
        out[..., i] = np.interp(h, [s[0] for s in stops], [s[1][i] for s in stops])
    return out


def bild(h, fl, path, crop=None, scale=1):
    hs = hillshade(h, z=1.6)
    rgb = hyps(h) * (0.45 + 0.75 * hs[..., None])
    if fl is not None:
        w = (fl & 1) == 1
        rgb[w] = (64, 110, 170)
    if crop:
        y0, x0, n = crop
        rgb = rgb[y0:y0 + n, x0:x0 + n]
    im = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8))
    if scale != 1:
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST if scale > 2 else Image.BILINEAR)
    im.save(path)


def main():
    out, bdir = sys.argv[1], sys.argv[2]
    vs = sys.argv[3:]
    os.makedirs(bdir, exist_ok=True)
    res = {}
    data = {}
    for v in vs:
        meta, M, nodes, fl = load(os.path.join(out, v))
        K, h, slope, st = kennzahlen(meta, M, nodes, fl)
        res[v] = K
        data[v] = (h, fl, M)
        bild(h, fl, os.path.join(bdir, "08_relief_%s_karte.png" % v))
        print(v, json.dumps(K, ensure_ascii=False))
    # Ausschnitt Massiv: hoechster Punkt der s7-Variante, 160 x 160 Felder (4 km), gleiche Stelle fuer alle
    # Ausschnitt: gleiche Stelle fuer alle Varianten
    crops = {}
    for v in vs:
        h0 = data[v][0]
        inner = np.pad(np.ones((G - 160, G - 160)), 80)
        href = data[vs[0]][0]     # gleiche Stelle fuer alle: hoechster Innenpunkt der ersten Variante (Massive liegen gleich)
        y, x = np.unravel_index(np.argmax(np.where(inner > 0, href, 0)), href.shape)
        y0, x0 = int(np.clip(y - 80, 0, G - 160)), int(np.clip(x - 80, 0, G - 160))
        crops[v] = {"x0": x0, "y0": y0, "n": 160}
        bild(h0, data[v][1], os.path.join(bdir, "08_relief_%s_massiv.png" % v), crop=(y0, x0, 160), scale=3)
        # lokale Reliefspanne (500 m) als Graubild: zeigt Ebene/Huegelland-Kontrast
        rng = nd.maximum_filter(h0, size=41) - nd.minimum_filter(h0, size=41)
        Image.fromarray(np.clip(rng / 120.0 * 255, 0, 255).astype(np.uint8)).save(os.path.join(bdir, "08_relief_%s_spanne.png" % v))
        lr = rng[80:-80, 80:-80]
        lr = lr[(h0[80:-80, 80:-80] < 350)]
        res[v]["flachland_spanne500m_p10_p50_p90_m"] = [round(float(np.percentile(lr, q)), 1) for q in (10, 50, 90)]
    # Vorher/Nachher nebeneinander (Karte + Massiv)
    ims = [Image.open(os.path.join(bdir, "08_relief_%s_karte.png" % v)) for v in vs]
    W = sum(i.width for i in ims) + 8 * (len(ims) - 1)
    sheet = Image.new("RGB", (W, ims[0].height), (30, 30, 30))
    xo = 0
    for i in ims:
        sheet.paste(i, (xo, 0))
        xo += i.width + 8
    sheet.save(os.path.join(bdir, "08_relief_vergleich_karte.png"))
    ims = [Image.open(os.path.join(bdir, "08_relief_%s_massiv.png" % v)) for v in vs]
    W = sum(i.width for i in ims) + 8 * (len(ims) - 1)
    sheet = Image.new("RGB", (W, ims[0].height), (30, 30, 30))
    xo = 0
    for i in ims:
        sheet.paste(i, (xo, 0))
        xo += i.width + 8
    sheet.save(os.path.join(bdir, "08_relief_vergleich_massiv.png"))
    res["_massiv_ausschnitt_felder"] = crops
    print({v: res[v]["flachland_spanne500m_p10_p50_p90_m"] for v in vs})
    json.dump(res, open(os.path.join(out, "kennzahlen.json"), "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
