#!/usr/bin/env python3
"""W-06 (S7, Felix/Tobias): Validator der S7-Welt. Prueft world/data/world_s7.json + Rohdaten gegen Lenas Regeln
(rules_s7.json R1-R8, Kettenbaender, Stadtstufen), das Kartenschema (data/slice_map.schema.json) und die Erreichbarkeit
(jede Kettenstrecke baubar: Weg ueber Felder <= Steigungsgrenze Strasse, Fluss nur an Stellen <= 8 Felder; Fluss durchgehend;
keine Industrie im Fluss oder zu steil; Plateaus < 3 %).

Aufruf (aus slice/):  python3 -I tools/world_validate.py [--dir world/data] [--rules PFAD] [--schema PFAD] [--quiet]
                      python3 -I tools/world_validate.py --seeds 1..20 [--det]  (erzeugt 20 Seeds im Speicher und prueft jeden;
                                                                           --det: 2 Laeufe je Seed, Ergebnis byte-gleich)
Exit 0 = 0 Verstoesse, sonst 1 (Liste auf stdout). Lesbar fuer tests/d07_regression.sh (Abschnitt s7_validator).
Konventionen wie tools/world_gen.py: Hoehe je Feld = Mittel der 4 Eckknoten, Steigung = max |dh| zu 4 Nachbarn / 25 m (Promille).
Gelaende-Klassen werden hier NACH dem Stempeln gemessen (der Generator misst davor, Lenas Hinweis 5); die Plateaus sind klein
(Radius 3 bzw. Stadtkern), deshalb Toleranz 10 Promille auf die Untergrenze der Gebirgsfuss-Klasse.
"""
import argparse
import hashlib
import json
import math
import os
import sys
from collections import deque

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
GRID = 512
STEP = 25.0
AKTIVE_ROHSTOFFE = ("getreidefarm", "kohlemine", "erzmine")
STUFEN = ["dorf", "kleinstadt", "stadt"]


def gini(vals):
    v = sorted(x for x in vals if x > 0)
    n = len(v)
    if n <= 1:
        return 0.0
    s = sum(v)
    return sum((2 * (i + 1) - n - 1) * x for i, x in enumerate(v)) / (n * s)


def field_heights(nodes):
    return (nodes[:-1, :-1] + nodes[:-1, 1:] + nodes[1:, :-1] + nodes[1:, 1:]) * 0.25


def field_slope_pm(h):
    d = np.zeros_like(h)
    d[:, 1:] = np.maximum(d[:, 1:], np.abs(h[:, 1:] - h[:, :-1]))
    d[:, :-1] = np.maximum(d[:, :-1], np.abs(h[:, 1:] - h[:, :-1]))
    d[1:, :] = np.maximum(d[1:, :], np.abs(h[1:, :] - h[:-1, :]))
    d[:-1, :] = np.maximum(d[:-1, :], np.abs(h[1:, :] - h[:-1, :]))
    return np.rint(d / STEP * 1000.0).astype(np.int64)


def disk_kernel_n(r):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    return float((xx * xx + yy * yy <= r * r).sum())


def disk_mean(a, r):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    k = (xx * xx + yy * yy <= r * r).astype(np.float64)
    k /= k.sum()
    ap = np.pad(a, r, mode="edge")
    kk = np.zeros_like(ap)
    kk[:2 * r + 1, :2 * r + 1] = k
    kk = np.roll(np.roll(kk, -r, axis=0), -r, axis=1)
    res = np.fft.irfft2(np.fft.rfft2(ap) * np.fft.rfft2(kk), s=ap.shape)
    return res[r:r + a.shape[0], r:r + a.shape[1]]


def run_lengths(mask, axis):
    """Je Zelle die Lauflaenge der zusammenhaengenden True-Zellen entlang der Achse (0 = Spalten/vertikal, 1 = Zeilen)."""
    m = mask if axis == 1 else mask.T
    H, W = m.shape
    out = np.zeros(m.shape, dtype=np.int64)
    pad = np.zeros((H, W + 2), dtype=np.int8)
    pad[:, 1:-1] = m
    dif = np.diff(pad, axis=1)
    for y in np.flatnonzero(m.any(axis=1)):
        st = np.flatnonzero(dif[y] == 1)
        en = np.flatnonzero(dif[y] == -1)
        for s0, e0 in zip(st, en):
            out[y, s0:e0] = e0 - s0
    return out if axis == 1 else out.T


def bruecken_hoehe(h, water):
    """H2 (S7 Block D, Felix), wie world/s7_world.gd bruecken_hoehe: Wasserfeld = Brueckendeck, linear zwischen den beiden
    Uferfeldern des kuerzeren Laufs (Zeile O-W / Spalte N-S, Gleichstand O-W). Ohne zwei Ufer: hoechstes Landfeld im
    Umkreis 3 (alte Regel). Rueckgabe: Feldhoehen mit Deck auf Wasserfeldern."""
    n = h.shape[0]
    deck = [np.full(h.shape, np.nan), np.full(h.shape, np.nan)]
    run = [run_lengths(water, 1), run_lengths(water, 0)]
    for ax in (0, 1):
        W = water if ax == 0 else water.T
        H = h if ax == 0 else h.T
        D = deck[ax] if ax == 0 else deck[ax].T
        pad = np.zeros((n, n + 2), dtype=np.int8)
        pad[:, 1:-1] = W
        dif = np.diff(pad, axis=1)
        for y in np.flatnonzero(W.any(axis=1)):
            for s0, e0 in zip(np.flatnonzero(dif[y] == 1), np.flatnonzero(dif[y] == -1)):
                ln = e0 - s0
                if s0 > 0 and e0 < n:
                    a, b = H[y, s0 - 1], H[y, e0]
                    D[y, s0:e0] = a + (b - a) * (np.arange(1, ln + 1) / float(ln + 1))
    out = h.copy()
    a, b = deck
    use_a = water & ~np.isnan(a) & (np.isnan(b) | (run[0] <= run[1]))
    use_b = water & ~use_a & ~np.isnan(b)
    out[use_a] = a[use_a]
    out[use_b] = b[use_b]
    for y, x in zip(*np.nonzero(water & ~use_a & ~use_b)):
        sub = h[max(0, y - 3):y + 4, max(0, x - 3):x + 4][~water[max(0, y - 3):y + 4, max(0, x - 3):x + 4]]
        if sub.size:
            out[y, x] = sub.max()
    return out


def label4(mask):
    """4er-Zusammenhangskomponenten: Feld -> Komponente (-1 = nicht in der Maske)."""
    try:
        from scipy.ndimage import label
        lab, _ = label(mask)
        return lab.astype(np.int64) - 1
    except ImportError:
        pass
    comp = np.full(mask.shape, -1, dtype=np.int64)
    k = 0
    H, W = mask.shape
    for y0, x0 in zip(*np.nonzero(mask)):
        if comp[y0, x0] >= 0:
            continue
        q = deque([(y0, x0)])
        comp[y0, x0] = k
        while q:
            y, x = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < H and 0 <= nx < W and mask[ny, nx] and comp[ny, nx] < 0:
                    comp[ny, nx] = k
                    q.append((ny, nx))
        k += 1
    return comp


def fluss_breite_max(fl):
    """Breite des Flusses in Feldern an der ungünstigsten Stelle, gemessen als min(waagrechter, senkrechter Lauf) je Wasserfeld."""
    w = (fl & 1) == 1
    if not w.any():
        return 0
    rh = run_lengths(w, 1)
    rv = run_lengths(w, 0)
    return int(np.minimum(rh, rv)[w].max())


def dist_pt(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def inside_poly(pt, poly):
    x, y = pt
    c = False
    for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


# ---------------------------------------------------------------- Schema

def check_schema(M, schema_path):
    """jsonschema, wenn vorhanden (common.schema.json wird aus spikes/sim-core bzw. eingebettet aufgeloest); sonst Minimalpruefung."""
    errs = []
    common = {"$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "mega-tycoon/common.schema.json", "$defs": {
        "id": {"type": "string", "pattern": "^[a-z][a-z0-9_]{1,31}$"},
        "felder": {"type": "integer", "minimum": 0, "maximum": 100000},
        "mm": {"type": "integer", "minimum": 0, "maximum": 9007199254740991}}}
    try:
        import jsonschema
        from referencing import Registry, Resource
        schema = json.load(open(schema_path, encoding="utf-8"))
        reg = Registry().with_resource("common.schema.json", Resource.from_contents(common))
        reg = reg.with_resource("mega-tycoon/common.schema.json", Resource.from_contents(common))
        v = jsonschema.Draft202012Validator(schema, registry=reg)
        for e in sorted(v.iter_errors(M), key=lambda e: list(e.path)):
            errs.append("Schema %s: %s" % ("/".join(str(p) for p in e.path), e.message[:120]))
        return errs, "jsonschema"
    except ImportError:
        pass
    except Exception as e:  # referencing fehlt o. ae.: Minimalpruefung
        errs.append("Schema-Engine: %s" % str(e)[:100])
    for k in ("schema_version", "karte", "staedte", "industrien", "gelaende", "fluesse", "ketten", "nischen", "hq_optionen"):
        if k not in M:
            errs.append("Schema: %s fehlt" % k)
    for s in M.get("staedte", []):
        for k in ("id", "name", "stufe", "einwohner_anzahl", "x_felder", "y_felder"):
            if k not in s:
                errs.append("Schema staedte %s: %s fehlt" % (s.get("id"), k))
    return errs, "minimal"


# ---------------------------------------------------------------- Regeln

def validate_data(M, h16, fl, meta, rules, schema_path=None):
    """Gibt die Liste der Verstoesse (Strings) zurueck. h16: 513x513 uint16, fl: 512x512 uint8."""
    V = []
    R = rules
    if schema_path:
        se, _ = check_schema(M, schema_path)
        V += se
    nodes = h16.astype(np.float64) * meta["hoehe_skala_m"]
    h = field_heights(nodes)
    slope = field_slope_pm(h)
    water = (fl & 1) == 1
    aue = (fl & 2) == 2
    yy, xx = np.mgrid[0:GRID, 0:GRID]
    # Umfeld-Steigung (Ebene) nur ueber Landfelder (Rinne + Ufersaum ausgenommen), wie im Generator
    r12 = R["gelaende_klassen"]["ebene"]["umfeld_radius_felder"]
    r20 = R["gelaende_klassen"]["gebirgsfuss"]["umfeld_radius_felder"]
    rand = np.minimum(np.minimum(xx, GRID - 1 - xx), np.minimum(yy, GRID - 1 - yy))
    hoch = (disk_mean((h > 500.0).astype(np.float64), 40) > 0.5 / disk_kernel_n(40)) | (rand <= 56)   # Gebirgsring hinter der Kante zaehlt

    # Flussabstand je Feld (Mittellinie aus dem JSON, Segmentabstand; grob reicht fuer die Regeln)
    linie = M["fluesse"][0]["linie"]
    fd = np.full((GRID, GRID), 1e9)
    for (x1, y1), (x2, y2) in zip(linie, linie[1:]):
        dx, dy = x2 - x1, y2 - y1
        ll = dx * dx + dy * dy
        t = np.clip(((xx + 0.5 - x1 - 0.5) * dx + (yy + 0.5 - y1 - 0.5) * dy) / max(ll, 1e-9), 0, 1)
        fd = np.minimum(fd, np.hypot(xx - x1 - t * dx, yy - y1 - t * dy))
    # Wasserfelder haben Abstand 0 (die Rinne selbst)
    fd = np.where(water, 0.0, fd)
    land = (fd > 1.5) & ~water
    for i in M["industrien"]:   # Plateau + Boeschung der Industrien (<= 9,5 Felder) zaehlen nicht zum Umfeld (wie im Generator)
        land &= np.hypot(xx - i["x_felder"], yy - i["y_felder"]) > 10.5
    for c in M["staedte"]:      # Stadtkern + Boeschung (<= Radius + 14,5) ebenso (planiert)
        land &= np.hypot(xx - c["x_felder"], yy - c["y_felder"]) > R["staedte"]["stufen"][c["stufe"]]["zielradius"]["felder"] + 15.5
    # Umfeld = Kreisring 10..R ueber Landfelder (Plateau 5,5 + Boeschung bis 9,5 bleiben aussen vor; wie tools/world_gen.py)
    sl = np.where(land, slope, 0).astype(np.float64)
    lw = land.astype(np.float64)

    def ring(rmin, rmax):
        n_out, n_in = disk_kernel_n(rmax), disk_kernel_n(rmin - 1)
        num = disk_mean(sl, rmax) * n_out - disk_mean(sl, rmin - 1) * n_in
        den = disk_mean(lw, rmax) * n_out - disk_mean(lw, rmin - 1) * n_in
        # Ring fast ganz gestempelt (< 20 % Landfelder): gilt als eben (0), das Gelaende dort ist ohnehin planiert
        return np.where(den >= 0.2 * (n_out - n_in), num / np.maximum(den, 1e-6), 0.0)
    um12 = ring(10, r12)
    um20 = ring(10, r20)

    # --- Terrain
    hmin, hmax = float(h.min()), float(h.max())
    if hmax - hmin < R["karte"]["hoehenspanne_min_m"]:
        V.append("Hoehenspanne %.0f m < %d" % (hmax - hmin, R["karte"]["hoehenspanne_min_m"]))
    geb = [g for g in M["gelaende"] if g["typ"] == "gebirge"]
    if not geb:
        V.append("kein Gebirge-Polygon")
    else:
        peak = max(float(h[max(0, min(GRID - 1, p[1])), max(0, min(GRID - 1, p[0]))]) for g in geb for p in g["polygon"])
        if hmax < 800.0:
            V.append("Gebirge: hoechster Punkt nur %.0f m" % hmax)
    if not water.any():
        V.append("kein Fluss (Flussmaske leer)")
    else:
        # durchgehend: eine Komponente beruehrt zwei gegenueberliegende Kanten
        lab = label4(water)
        ok_ = False
        for k in np.unique(lab[lab >= 0]):
            m = lab == k
            if (m[0].any() and m[-1].any()) or (m[:, 0].any() and m[:, -1].any()):
                ok_ = True
                break
        if not ok_:
            V.append("Fluss nicht durchgehend (keine Komponente von Kante zu Kante)")
        bmax = fluss_breite_max(fl)
        if bmax > meta["bau"]["bruecke_max_felder"]:
            V.append("Fluss an einer Stelle %d Felder breit (> %d, nicht ueberbrueckbar)" % (bmax, meta["bau"]["bruecke_max_felder"]))
        if M["fluesse"][0]["breite_felder"] < bmax:
            V.append("fluesse.breite_felder %d < gemessen %d" % (M["fluesse"][0]["breite_felder"], bmax))
    # Huegel in der Flaeche: Anteil Felder mit 10-60 Promille ausserhalb Gebirge/Aue
    huegel = ((slope >= 10) & (slope <= 60) & (h < 400)).mean()
    if huegel < 0.10:
        V.append("Huegel in der Flaeche: nur %.0f %% der Felder mit 1-6 %% Steigung unter 400 m" % (huegel * 100))

    # --- Staedte
    st = R["staedte"]
    cities = M["staedte"]
    cnt = {s: 0 for s in STUFEN}
    for c in cities:
        cnt[c["stufe"]] = cnt.get(c["stufe"], 0) + 1
    for s in STUFEN:
        a = st["stufen"][s]["anzahl_auf_karte"]
        if not a["min"] <= cnt[s] <= a["max"]:
            V.append("Staedte Stufe %s: %d (Soll %d-%d)" % (s, cnt[s], a["min"], a["max"]))
    if not st["anzahl_gesamt"]["min"] <= len(cities) <= st["anzahl_gesamt"]["max"]:
        V.append("Staedte gesamt %d (Soll %d-%d)" % (len(cities), st["anzahl_gesamt"]["min"], st["anzahl_gesamt"]["max"]))
    margin_s = R["karte"]["randabstand_stadt"]["felder"]
    md = st["mindestabstand_zentrum"]
    radius = {}
    for c in cities:
        x, y, s = c["x_felder"], c["y_felder"], c["stufe"]
        r = st["stufen"][s]["zielradius"]["felder"]
        radius[c["id"]] = r
        ew = st["stufen"][s]["einwohner_anzahl"]
        if not ew["min"] <= c["einwohner_anzahl"] <= ew["max"]:
            V.append("Stadt %s: %d Einwohner nicht in %s-Band" % (c["id"], c["einwohner_anzahl"], s))
        if not (margin_s <= x < GRID - margin_s and margin_s <= y < GRID - margin_s):
            V.append("Stadt %s: Randabstand < %d" % (c["id"], margin_s))
        d = np.hypot(xx - x, yy - y)
        core = d <= r
        pl = st["plateau"]
        if slope[core].max() > pl["steigung_max_promille"]:
            V.append("Stadt %s: Kern-Plateau max %d Promille (> %d)" % (c["id"], slope[core].max(), pl["steigung_max_promille"]))
        if water[core].any():
            V.append("Stadt %s: Fluss im Kern" % c["id"])
        if not pl["hoehe_m"]["min"] <= h[y, x] <= pl["hoehe_m"]["max"]:
            V.append("Stadt %s: Hoehe %.0f m nicht in %d-%d" % (c["id"], h[y, x], pl["hoehe_m"]["min"], pl["hoehe_m"]["max"]))
        nearest = 1e9
        for o in cities:
            if o is c:
                continue
            dd = dist_pt((x, y), (o["x_felder"], o["y_felder"]))
            nearest = min(nearest, dd)
            if s == "dorf" or o["stufe"] == "dorf":
                mind = md["dorf_zu_jeder_stufe"]["felder"]
            elif s == "stadt" and o["stufe"] == "stadt":
                mind = md["stadt_stadt"]["felder"]
            elif s == "kleinstadt" and o["stufe"] == "kleinstadt":
                mind = md["kleinstadt_kleinstadt"]["felder"]
            else:
                mind = md["stadt_kleinstadt"]["felder"]
            if dd < mind and c["id"] < o["id"]:
                V.append("Staedte %s-%s: Abstand %.0f < %d" % (c["id"], o["id"], dd, mind))
        if len(cities) > 1 and nearest > st["nachbarstadt_max"]["felder"]:
            V.append("Stadt %s: naechste Stadt %.0f > %d" % (c["id"], nearest, st["nachbarstadt_max"]["felder"]))

    # --- Industrien
    it = R["industrie_typen"]
    inds = M["industrien"]
    by_id = {i["id"]: i for i in inds}
    cby = {c["id"]: c for c in cities}
    tcount = {}
    for i in inds:
        tcount[i["typ"]] = tcount.get(i["typ"], 0) + 1
    for typ, rule in it.items():
        n = tcount.get(typ, 0)
        if rule["aktiv"] and not rule["anzahl"]["min"] <= n <= rule["anzahl"]["max"]:
            V.append("Typ %s: %d Instanzen (Soll %d-%d)" % (typ, n, rule["anzahl"]["min"], rule["anzahl"]["max"]))
        if not rule["aktiv"] and n > 0:
            V.append("Typ %s inaktiv, aber %d Instanzen" % (typ, n))
    if len(inds) < R["industrie_anzahl_gesamt_min"]:
        V.append("Industrien gesamt %d < %d" % (len(inds), R["industrie_anzahl_gesamt_min"]))
    margin_i = R["karte"]["randabstand_industrie"]["felder"]
    plat = R["industrie_plateau"]
    puffer = R["abstand_stadt_regeln"]["puffer_felder"]
    r7 = R["r7_abstand_gleicher_typ"]
    gk = R["gelaende_klassen"]
    geb_polys = [g["polygon"] for g in M["gelaende"] if g["typ"] == "gebirge"]
    werk_je_stadt = {}
    aue_farmen = 0
    for i in inds:
        x, y, typ = i["x_felder"], i["y_felder"], i["typ"]
        rule = it.get(typ)
        if rule is None:
            V.append("%s: unbekannter Typ %s" % (i["id"], typ))
            continue
        if not (margin_i <= x < GRID - margin_i and margin_i <= y < GRID - margin_i):
            V.append("%s: Randabstand < %d" % (i["id"], margin_i))
        d = np.hypot(xx - x, yy - y)
        core = d <= plat["kern_radius_felder"]
        if water[core].any():
            V.append("%s: Fluss im Plateau" % i["id"])
        if slope[core].max() > plat["steigung_max_promille"]:
            V.append("%s: Plateau max %d Promille (> %d)" % (i["id"], slope[core].max(), plat["steigung_max_promille"]))
        hm = rule["hoehe_m"]
        if not hm["min"] <= h[y, x] <= hm["max"]:
            V.append("%s: Hoehe %.0f m nicht in %d-%d" % (i["id"], h[y, x], hm["min"], hm["max"]))
        # Gelaende-Klasse (eine von)
        klassen_ok = []
        ge = rule["gelaende"]
        for k in ge["mindestens_eine_von"]:
            if k == "ebene":
                e = gk["ebene"]
                klassen_ok.append(um12[y, x] < e["umfeld_steigung_max_promille"] + 1 and e["hoehe_m"]["min"] <= h[y, x] <= e["hoehe_m"]["max"])
            elif k == "aue":
                a = gk["aue"]
                klassen_ok.append(aue[y, x] or (a["fluss_abstand_felder"]["min"] <= fd[y, x] <= a["fluss_abstand_felder"]["max"] and um12[y, x] < 31))
            elif k == "gebirgsfuss":
                g = gk["gebirgsfuss"]
                klassen_ok.append(g["umfeld_steigung_promille"]["min"] <= um20[y, x] <= g["umfeld_steigung_promille"]["max"]
                                  and g["hoehe_m"]["min"] <= h[y, x] <= g["hoehe_m"]["max"] and hoch[y, x])
            elif k == "flussnaehe":
                klassen_ok.append(fd[y, x] <= gk["flussnaehe"]["fluss_abstand_felder"]["max"])
            elif k == "stadtrand":
                ok = False
                for c in cities:
                    dc = dist_pt((x, y), (c["x_felder"], c["y_felder"]))
                    aus = st["stufen"][c["stufe"]]["ausfransung"]["felder_max"]
                    ok |= radius[c["id"]] <= dc <= radius[c["id"]] + aus
                klassen_ok.append(ok)
            elif k == "waldrand":
                klassen_ok.append(True)
        if not any(klassen_ok):
            V.append("%s: Gelaende-Klasse %s nicht erfuellt (um12 %.0f, um20 %.0f, h %.0f, fd %.1f, hoch %s, aue %s)" % (
                i["id"], "/".join(ge["mindestens_eine_von"]), um12[y, x], um20[y, x], h[y, x], fd[y, x], bool(hoch[y, x]), bool(aue[y, x])))
        if ge.get("umfeld_steigung_max_promille") is not None and um12[y, x] >= ge["umfeld_steigung_max_promille"] + 1 and "gebirgsfuss" not in ge["mindestens_eine_von"]:
            V.append("%s: Umfeld-Steigung %.0f >= %d Promille" % (i["id"], um12[y, x], ge["umfeld_steigung_max_promille"]))
        for pname in ge.get("nicht_im_gelaende_polygon", []):
            for g in M["gelaende"]:
                if g["typ"] == pname and inside_poly((x, y), g["polygon"]):
                    V.append("%s: liegt im Polygon %s" % (i["id"], g["id"]))
        if typ == "getreidefarm":
            if fd[y, x] < rule["fluss_abstand_min"]["felder"]:
                V.append("%s: Flussabstand %.1f < %d" % (i["id"], fd[y, x], rule["fluss_abstand_min"]["felder"]))
            aue_farmen += bool(aue[y, x])
        # Staedte-Abstaende
        ab = rule["abstand_naechste_stadt"]
        nearest, nearest_ks = 1e9, (None, 1e9)
        for c in cities:
            dc = dist_pt((x, y), (c["x_felder"], c["y_felder"]))
            mind = max(ab["felder_min"], radius[c["id"]] + puffer)
            if dc < mind:
                V.append("%s: Abstand zu %s %.0f < %d" % (i["id"], c["id"], dc, mind))
            nearest = min(nearest, dc)
            if c["stufe"] != "dorf" and dc < nearest_ks[1]:
                nearest_ks = (c, dc)
        if nearest > ab["felder_max"]:
            V.append("%s: naechste Stadt %.0f > %d" % (i["id"], nearest, ab["felder_max"]))
        if typ == "werkzeugfabrik":
            c, dc = nearest_ks
            if c is None or not ab["felder_min"] <= dc <= ab["felder_max"]:
                V.append("%s: naechste Stadt >= Kleinstadt nicht in %d-%d" % (i["id"], ab["felder_min"], ab["felder_max"]))
            else:
                werk_je_stadt[c["id"]] = werk_je_stadt.get(c["id"], 0) + 1
        # R7 + Mindestabstand
        same_200 = 0
        for j in inds:
            if j is i:
                continue
            dj = dist_pt((x, y), (j["x_felder"], j["y_felder"]))
            if dj < plat["mindestabstand_beliebige_industrien"]["felder"]:
                if i["id"] < j["id"]:
                    V.append("%s-%s: Abstand %.0f < %d" % (i["id"], j["id"], dj, plat["mindestabstand_beliebige_industrien"]["felder"]))
            if j["typ"] == typ:
                if dj < r7["mindestabstand"]["felder"] and i["id"] < j["id"]:
                    V.append("R7 %s-%s: gleicher Typ %.0f < %d" % (i["id"], j["id"], dj, r7["mindestabstand"]["felder"]))
                if dj <= r7["cluster"]["radius"]["felder"]:
                    same_200 += 1
        if same_200 + 1 > r7["cluster"]["max_gleicher_typ"]:
            V.append("R7 %s: %d gleiche Typen in %d Feldern" % (i["id"], same_200 + 1, r7["cluster"]["radius"]["felder"]))
        # Kohle-Erz-Band
        if typ in ("kohlemine", "erzmine"):
            other = "erzmine" if typ == "kohlemine" else "kohlemine"
            key = "abstand_zu_erzmine" if typ == "kohlemine" else "abstand_zu_kohlemine"
            band = rule[key]
            if not any(band["felder_min"] <= dist_pt((x, y), (j["x_felder"], j["y_felder"])) <= band["felder_max"] for j in inds if j["typ"] == other):
                V.append("%s: keine %s in %d-%d" % (i["id"], other, band["felder_min"], band["felder_max"]))
    for cid, n in werk_je_stadt.items():
        if n > it["werkzeugfabrik"]["max_je_stadt"]:
            V.append("R5 %s: %d Werkzeugfabriken" % (cid, n))
    nf = tcount.get("getreidefarm", 0)
    if nf and aue_farmen * 1000 < it["getreidefarm"]["gelaende"]["anteil_aue_min_promille"] * nf:
        V.append("R1: nur %d von %d Farmen in der Aue" % (aue_farmen, nf))

    # --- Ketten-Baender
    bands = {b["id"]: b for b in R["ketten_baender"]}

    def pos(i):
        return (i["x_felder"], i["y_felder"])

    def has_in_band(src, dst_typ, band):
        return any(band["felder_min"] <= dist_pt(pos(src), pos(j)) <= band["felder_max"] for j in inds if j["typ"] == dst_typ)
    for i in inds:
        t = i["typ"]
        if t == "muehle":
            if not has_in_band(i, "getreidefarm", bands["K1a"]["luftlinie"]):
                V.append("K1a %s: keine Farm im Nahband" % i["id"])
            b = bands["K1b"]["luftlinie"]
            if not any(b["felder_min"] <= dist_pt(pos(i), (c["x_felder"], c["y_felder"])) <= b["felder_max"] for c in cities):
                V.append("K1b %s: keine Stadt in %d-%d" % (i["id"], b["felder_min"], b["felder_max"]))
        elif t == "getreidefarm":
            b = bands["K1a"]
            lo, hi = b["luftlinie"]["felder_min"], b["optional_fern"]["felder_max"]
            if not any(lo <= dist_pt(pos(i), pos(j)) <= hi for j in inds if j["typ"] == "muehle"):
                V.append("K1a %s: keine Muehle in %d-%d" % (i["id"], lo, hi))
        elif t == "kohlemine":
            if not has_in_band(i, "kraftwerk", bands["K2a"]["luftlinie"]):
                V.append("K2a %s: kein Kraftwerk im Band" % i["id"])
            if not has_in_band(i, "stahlwerk", bands["K3b"]["luftlinie"]):
                V.append("K3b %s: kein Stahlwerk im Band" % i["id"])
        elif t == "kraftwerk":
            if not has_in_band(i, "stahlwerk", bands["K2b"]["luftlinie"]):
                V.append("K2b %s: kein Stahlwerk im Energie-Radius-Band" % i["id"])
        elif t == "erzmine":
            if not has_in_band(i, "stahlwerk", bands["K3a"]["luftlinie"]):
                V.append("K3a %s: kein Stahlwerk im Band" % i["id"])
        elif t == "stahlwerk":
            if not has_in_band(i, "werkzeugfabrik", bands["K3c"]["luftlinie"]):
                V.append("K3c %s: keine Werkzeugfabrik im Band" % i["id"])
            if not has_in_band(i, "kohlemine", bands["K3b"]["luftlinie"]) or not has_in_band(i, "erzmine", bands["K3a"]["luftlinie"]):
                V.append("K3 %s: Kohle oder Erz fehlt im Band" % i["id"])
        elif t == "werkzeugfabrik":
            b = bands["K3d"]["luftlinie"]
            if not any(b["felder_min"] <= dist_pt(pos(i), (c["x_felder"], c["y_felder"])) <= b["felder_max"] for c in cities):
                V.append("K3d %s: keine Stadt in %d-%d" % (i["id"], b["felder_min"], b["felder_max"]))
    # ketten.strecken: IDs, Luftlinien stimmen, jede Industrie kommt vor
    ids = set(by_id) | set(cby)
    in_strecke = set()
    for ch in M["ketten"]:
        for s in ch["strecken"]:
            if s["von"] not in ids or s["nach"] not in ids:
                V.append("Kette %s: %s/%s unbekannt" % (ch["id"], s["von"], s["nach"]))
                continue
            a = by_id.get(s["von"]) or cby.get(s["von"])
            b = by_id.get(s["nach"]) or cby.get(s["nach"])
            llf = int(math.floor(dist_pt(pos(a), pos(b)) + 0.5))
            if llf != s["luftlinie_felder"]:
                V.append("Kette %s %s->%s: luftlinie_felder %d, gemessen %d" % (ch["id"], s["von"], s["nach"], s["luftlinie_felder"], llf))
            in_strecke.add(s["von"])
            in_strecke.add(s["nach"])
    for i in inds:
        if i["id"] not in in_strecke:
            V.append("%s: in keiner Kettenstrecke" % i["id"])
    # Nische 25
    if not M["nischen"]:
        V.append("Nische 25: kein Eintrag")
    for n in M["nischen"]:
        a = by_id.get(n["von"])
        b = by_id.get(n["nach"])
        if a is None or b is None:
            V.append("Nische %s->%s: unbekannt" % (n["von"], n["nach"]))
            continue
        llf = int(math.floor(dist_pt(pos(a), pos(b)) + 0.5))
        if n["soll_felder"] != 25 or abs(llf - 25) > 1 or llf != n["luftlinie_felder"]:
            V.append("Nische %s->%s: %d Felder (Soll 25 +-1)" % (n["von"], n["nach"], llf))

    # --- R8 je Stadt
    r8 = R["r8_zulieferer"]
    for c in cities:
        t240, t80 = {}, set()
        for i in inds:
            d = dist_pt((c["x_felder"], c["y_felder"]), pos(i))
            if d <= r8["nahversorgung"]["radius"]["felder"]:
                t240[i["typ"]] = t240.get(i["typ"], 0) + 1
            if d <= r8["anti_spezialisierung"]["radius"]["felder"]:
                t80.add(i["typ"])
        if len(t240) < r8["nahversorgung"]["min_verschiedene_typen"]:
            V.append("R8 %s: nur %d Typen in %d" % (c["id"], len(t240), r8["nahversorgung"]["radius"]["felder"]))
        if len(t80) > r8["anti_spezialisierung"]["max_verschiedene_typen"]:
            V.append("R8 %s: %d Typen in %d (max %d)" % (c["id"], len(t80), r8["anti_spezialisierung"]["radius"]["felder"], r8["anti_spezialisierung"]["max_verschiedene_typen"]))
        g = gini(list(t240.values()))
        if g * 1000 >= r8["gini"]["max_promille"]:
            V.append("R8 %s: Gini %.2f >= %.2f" % (c["id"], g, r8["gini"]["max_promille"] / 1000))

    # --- HQ-Optionen (PO: >= 3 Staedte mit Rohstoff im Radius)
    hq_cities = {hq["stadt"] for hq in M["hq_optionen"]}
    for c in cities:
        if c["id"] not in hq_cities:
            V.append("HQ: Stadt %s ohne hq_option" % c["id"])
    n_roh = 0
    for hq in M["hq_optionen"]:
        c = cby.get(hq["stadt"])
        if c is None:
            V.append("HQ: Stadt %s unbekannt" % hq["stadt"])
            continue
        soll = sorted(i["id"] for i in inds if dist_pt((c["x_felder"], c["y_felder"]), pos(i)) <= hq["radius_felder"])
        if sorted(hq["industrien_im_radius"]) != soll:
            V.append("HQ %s: industrien_im_radius %s != %s" % (hq["stadt"], hq["industrien_im_radius"], soll))
        if any(by_id[i]["typ"] in AKTIVE_ROHSTOFFE for i in soll):
            n_roh += 1
        if hq["startkette"] != "keine" and hq["startkette"] not in {k["id"] for k in M["ketten"]}:
            V.append("HQ %s: startkette %s unbekannt" % (hq["stadt"], hq["startkette"]))
    if n_roh < 3:
        V.append("HQ: nur %d Staedte mit Rohstoff im HQ-Radius (PO: >= 3)" % n_roh)

    # --- Erreichbarkeit: Strasse (Steigung <= Grenze), Wasser nur an Stellen mit Lauf <= 8 (waagrecht oder senkrecht)
    smax = meta["bau"]["steigung_max_promille_strasse"]
    bmax_f = meta["bau"]["bruecke_max_felder"]
    rh = run_lengths(water, 1)
    rv = run_lengths(water, 0)
    # H2: dieselbe Regel wie das Spiel (s7_world.bruecken_hoehe): Wasserfeld traegt das Brueckendeck, Steigung je Richtung
    # ueber Land + Deck. Land: max zu 4 Nachbarn; Wasser: Lauf <= Brueckengrenze UND Rampe/Deck in Laufrichtung <= Grenze.
    hm = bruecken_hoehe(h, water)
    sh = np.zeros_like(hm)
    sv = np.zeros_like(hm)
    dx = np.abs(np.diff(hm, axis=1))
    dy = np.abs(np.diff(hm, axis=0))
    sh[:, 1:] = np.maximum(sh[:, 1:], dx)
    sh[:, :-1] = np.maximum(sh[:, :-1], dx)
    sv[1:, :] = np.maximum(sv[1:, :], dy)
    sv[:-1, :] = np.maximum(sv[:-1, :], dy)
    sh = np.rint(sh / STEP * 1000.0)
    sv = np.rint(sv / STEP * 1000.0)
    passable = (np.maximum(sh, sv) <= smax) & ~water
    passable |= water & (((rh <= bmax_f) & (sh <= smax)) | ((rv <= bmax_f) & (sv <= smax)))
    # Gebaeudefelder sind baubar (werden eben gestempelt), Stadtkerne ebenfalls
    for i in inds:
        passable[max(0, i["y_felder"] - 2):i["y_felder"] + 3, max(0, i["x_felder"] - 2):i["x_felder"] + 3] = True
    comp = label4(passable)
    for ch in M["ketten"]:
        for s in ch["strecken"]:
            a = by_id.get(s["von"]) or cby.get(s["von"])
            b = by_id.get(s["nach"]) or cby.get(s["nach"])
            if a is None or b is None:
                continue
            ca, cb = comp[a["y_felder"], a["x_felder"]], comp[b["y_felder"], b["x_felder"]]
            if ca < 0 or cb < 0 or ca != cb:
                V.append("Erreichbarkeit %s: %s -> %s nicht per Strasse (<= %d Promille, Bruecke <= %d) verbunden" % (ch["id"], s["von"], s["nach"], smax, bmax_f))
    # alle Staedte untereinander
    cc = [comp[c["y_felder"], c["x_felder"]] for c in cities]
    if len(set(cc)) > 1:
        V.append("Erreichbarkeit: Staedte in %d getrennten Gebieten" % len(set(cc)))
    return V


# ---------------------------------------------------------------- Dateien

def load_dir(d):
    meta = json.load(open(os.path.join(d, "world_s7_meta.json"), encoding="utf-8"))
    M = json.load(open(os.path.join(d, "world_s7.json"), encoding="utf-8"))
    n = meta["knoten"]
    h16 = np.frombuffer(open(os.path.join(d, "hoehe_s7.r16"), "rb").read(), dtype="<u2").reshape(n, n)
    fl = np.frombuffer(open(os.path.join(d, "fluss_s7.u8"), "rb").read(), dtype=np.uint8).reshape(meta["felder"], meta["felder"])
    return M, h16, fl, meta


def check_files(d, meta):
    errs = []
    for name, md5 in meta.get("md5", {}).items():
        p = os.path.join(d, name)
        if not os.path.exists(p):
            errs.append("Datei fehlt: %s" % name)
        elif hashlib.md5(open(p, "rb").read()).hexdigest() != md5:
            errs.append("md5 %s stimmt nicht mit world_s7_meta.json ueberein" % name)
    nb = meta["rand"]["knoten"]
    p = os.path.join(d, "rand_s7.r16")
    if os.path.exists(p) and os.path.getsize(p) != nb * nb * 2:
        errs.append("rand_s7.r16: Groesse %d != %d" % (os.path.getsize(p), nb * nb * 2))
    vs = os.path.join(d, "hq_vorschau_s7.json")
    if not os.path.exists(vs):
        errs.append("hq_vorschau_s7.json fehlt")
    else:
        v = json.load(open(vs, encoding="utf-8"))
        M = json.load(open(os.path.join(d, "world_s7.json"), encoding="utf-8"))
        for c in M["staedte"]:
            if c["id"] not in v.get("staedte", {}):
                errs.append("hq_vorschau_s7.json: %s fehlt" % c["id"])
        md5 = hashlib.md5(open(os.path.join(d, "world_s7.json"), "rb").read()).hexdigest()
        if md5 not in v.get("quelle", ""):
            errs.append("hq_vorschau_s7.json: md5 der Karte stimmt nicht (%s)" % md5)
    return errs


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dir", default=os.path.join(HERE, "..", "world", "data"))
    ap.add_argument("--rules", default=None)
    ap.add_argument("--schema", default=os.path.join(HERE, "..", "data", "slice_map.schema.json"))
    ap.add_argument("--seeds", default=None, help="A..B: Seeds im Speicher erzeugen und pruefen (+ Determinismus)")
    ap.add_argument("--det", action="store_true", help="mit --seeds: jeden Seed zweimal erzeugen und vergleichen")
    ap.add_argument("--quiet", action="store_true")
    a = ap.parse_args()
    rules_path = a.rules or os.path.join(a.dir, "rules_s7.json")
    rules = json.load(open(rules_path, encoding="utf-8"))
    schema = os.path.abspath(a.schema) if os.path.exists(a.schema) else None
    if a.seeds:
        import world_gen as WG
        lo, hi = (int(v) for v in a.seeds.split(".."))
        bad = 0
        for s in range(lo, hi + 1):
            try:
                r1 = WG.generate(s, rules, verbose=False)
                r2 = WG.generate(s, rules, verbose=False) if a.det else r1
            except WG.LayoutFail as e:
                print("SEED %d UNLOESBAR: %s" % (s, e))
                bad += 1
                continue
            det = (r1["nodes16"].tobytes() == r2["nodes16"].tobytes() and r1["fluss"].tobytes() == r2["fluss"].tobytes()
                   and json.dumps(r1["map"], sort_keys=True) == json.dumps(r2["map"], sort_keys=True)
                   and r1["border16"].tobytes() == r2["border16"].tobytes())
            viol = validate_data(r1["map"], r1["nodes16"], r1["fluss"], r1["meta"], rules, schema)
            m = r1["meta"]
            print("SEED %d: %s, deterministisch %s, %d Staedte, %d Industrien, Hoehe %.0f-%.0f m, Fluss <= %d Felder, Variante %d/Versuch %d" % (
                s, "OK" if not viol else "%d VERSTOESSE" % len(viol), ("ja" if det else "NEIN") if a.det else "-", len(r1["map"]["staedte"]),
                len(r1["map"]["industrien"]), m["hoehe_min_m"], m["hoehe_max_m"], m["fluss"]["breite_max_felder"], m["terrain_variante"], m["layout_versuch"]))
            for v in viol:
                print("   -", v)
            if viol or not det:
                bad += 1
        print("Seeds %d..%d: %d von %d fehlerhaft" % (lo, hi, bad, hi - lo + 1))
        return 1 if bad else 0
    M, h16, fl, meta = load_dir(a.dir)
    errs = check_files(a.dir, meta)
    errs += validate_data(M, h16, fl, meta, rules, schema)
    if not a.quiet:
        print("world_validate %s: %d Staedte, %d Industrien, Seed %s" % (os.path.abspath(a.dir), len(M["staedte"]), len(M["industrien"]), meta.get("seed")))
        for e in errs:
            print("  VERSTOSS", e)
    print("VALIDIERUNG", "OK (0 Verstoesse)" if not errs else "FEHLER (%d Verstoesse)" % len(errs))
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main())
