#!/usr/bin/env python3
"""S-09: erzeugt slice_map.json (Festkomma, F-09-Konvention), prueft Geometrie + Kettenabstaende, rendert slice_map.png.
Aufruf: python3 -I build_slice_map.py   (Ausgabe in das Skriptverzeichnis)"""
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
F09 = "/tmp/claude-0/gd/sprint2/day4-6/tobias/f09"
N = 512
goods_ids = {g["id"] for g in json.load(open(F09 + "/data/goods.json"))["gueter"]}
consts = json.load(open(F09 + "/data/economy_constants.json"))

# ---------------- Daten (Felder, x = Ost, y = Sued, Ursprung oben links) ----------------
staedte = [
    ("haberau", "Haberau", "dorf", 900, 225, 310),
    ("kohlberg", "Kohlberg", "kleinstadt", 2500, 148, 214),
    ("mittelfurt", "Mittelfurt", "stadt", 12000, 203, 252),
    ("seehafen", "Seehafen", "kleinstadt", 3200, 310, 438),
    ("eichwald", "Eichwald", "dorf", 600, 300, 215),
    ("weidenau", "Weidenau", "dorf", 700, 92, 262),
]
# id, typ, x, y, kette (None = keine), im_slice, rolle
ind = [
    ("farm_1", "getreidefarm", 244, 296, "k1", True, "rohstoff"),
    ("farm_2", "getreidefarm", 240, 311, "k1", True, "rohstoff"),
    ("muehle_1", "muehle", 230, 286, "k1", True, "verarbeiter"),
    ("kohle_1", "kohlemine", 177, 181, "k2k3", True, "rohstoff"),
    ("erz_1", "erzmine", 146, 184, "k3", True, "rohstoff"),
    ("kraftwerk_1", "kraftwerk", 184, 200, "k2", True, "verarbeiter"),
    ("stahl_1", "stahlwerk", 160, 200, "k3", True, "verarbeiter"),
    ("werkzeug_1", "werkzeugfabrik", 182, 235, "k3", True, "abnehmer"),
    ("holz_hafen", "holzfaeller", 336, 398, "hafen", False, "rohstoff"),
    ("saege_hafen", "saegewerk", 326, 410, "hafen", False, "verarbeiter"),
    ("holz_agrar", "holzfaeller", 264, 302, None, False, "bau_quelle"),
    ("holz_berg", "holzfaeller", 110, 232, None, False, "bau_quelle"),
    ("holz_handel", "holzfaeller", 172, 272, None, False, "bau_quelle"),
]
typ_io = {  # Ein-/Ausgaben (Gueter-IDs gegen goods.json geprueft); kraftwerk -> energie (kein Gut)
    "getreidefarm": ([], ["getreide"]), "muehle": (["getreide"], ["mehl"]),
    "kohlemine": ([], ["kohle"]), "erzmine": ([], ["erz"]),
    "kraftwerk": (["kohle"], []), "stahlwerk": (["erz", "kohle"], ["stahl"]),
    "werkzeugfabrik": (["stahl"], ["werkzeug"]), "holzfaeller": ([], ["holz"]), "saegewerk": (["holz"], ["bretter"]),
}
gelaende = [
    ("gebirge_nw", "gebirge", [(30, 60), (80, 20), (260, 25), (268, 110), (236, 150), (200, 170), (185, 192), (150, 196), (120, 188), (70, 150), (40, 110)]),
    ("gebirge_ost", "gebirge", [(430, 60), (500, 50), (505, 140), (450, 150)]),
    ("wald_hafen", "wald", [(324, 384), (360, 380), (366, 412), (336, 418)]),
    ("wald_agrar", "wald", [(255, 288), (278, 288), (280, 316), (256, 318)]),
    ("wald_berg", "wald", [(96, 222), (126, 222), (126, 246), (96, 246)]),
    ("wald_handel", "wald", [(160, 262), (188, 262), (188, 288), (160, 288)]),
    ("wald_eichwald", "wald", [(316, 200), (346, 196), (352, 228), (320, 236)]),
    ("meer_sued", "meer", [(0, 470), (70, 458), (140, 474), (210, 462), (262, 440), (296, 444), (318, 448), (352, 462), (400, 450), (450, 440), (511, 432), (511, 511), (0, 511)]),
]
fluesse = [("fluss_1", "Mittelfurter Fluss", 3, [(226, 150), (222, 200), (210, 240), (206, 262), (220, 285), (238, 320), (262, 370), (290, 410), (306, 444)])]
ketten = [
    ("k1", "Getreide - Muehle - Mehl - Stadt", True, ["farm_1", "farm_2"], "muehle_1", "mittelfurt", ["getreide", "mehl"]),
    ("k2", "Kohle - Kraftwerk (Energie-Radius 25)", True, ["kohle_1"], "kraftwerk_1", None, ["kohle"]),
    ("k3", "Erz + Kohle - Stahlwerk - Stahl - Werkzeugfabrik", True, ["erz_1", "kohle_1"], "stahl_1", "werkzeug_1", ["erz", "kohle", "stahl", "werkzeug"]),
    ("hafen", "Holz - Saegewerk - Bretter (nicht im Slice)", False, ["holz_hafen"], "saege_hafen", "seehafen", ["holz", "bretter"]),
]
radius = {"dorf": 55, "kleinstadt": 50, "stadt": 45}   # L-08 hq_radius_*
hq = [("agrar", "haberau", "k1"), ("bergbau", "kohlberg", "k3"), ("handelsknoten", "mittelfurt", "k3"), ("hafen", "seehafen", "hafen")]
hq_im_slice = {"agrar": True, "bergbau": True, "handelsknoten": False, "hafen": False}

# ---------------- Geometrie ----------------
def pip(p, poly):
    x, y = p; c = False
    for i in range(len(poly)):
        x1, y1 = poly[i]; x2, y2 = poly[(i + 1) % len(poly)]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1: c = not c
    return c
def d(a, b): return math.hypot(a[0] - b[0], a[1] - b[1])
def seg_d(p, a, b):
    ax, ay = a; bx, by = b; px, py = p
    t = max(0, min(1, ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / ((bx - ax) ** 2 + (by - ay) ** 2)))
    return d(p, (ax + t * (bx - ax), ay + t * (by - ay)))
def poly_dist(p, poly): return 0 if pip(p, poly) else min(seg_d(p, poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly)))
def river_dist(p, r): return min(seg_d(p, r[i], r[i + 1]) for i in range(len(r) - 1))
def rd(x): return int(x + 0.5)

pos = {c[0]: (c[4], c[5]) for c in staedte}; pos.update({i[0]: (i[2], i[3]) for i in ind})
poly = {g[0]: (g[1], g[2]) for g in gelaende}
errs = []; info = []

# ---------------- JSON ----------------
doc = {
    "schema_version": 1,
    "karte": {"breite_felder": N, "hoehe_felder": N, "feld_mm": consts["raum"]["feld_mm"], "ursprung": "oben_links", "x_achse": "ost", "y_achse": "sued",
              "hinweis": "ANNAHME: 512 x 512 Felder (1 Feld = 10 m Szene, feld_mm aus economy_constants). Spielbarer Kern liegt bei x 90-340, y 150-440; Rest ist Rahmen (Gebirge, Meer) und Ausbaureserve."},
    "staedte": [{"id": i, "name": n, "stufe": s, "einwohner_anzahl": e, "x_felder": x, "y_felder": y} for i, n, s, e, x, y in staedte],
    "industrien": [], "gelaende": [], "fluesse": [], "ketten": [], "nischen": [], "hq_optionen": [],
}
for i, t, x, y, k, sl, ro in ind:
    ein, aus = typ_io[t]
    for g in ein + aus:
        if g not in goods_ids: errs.append(f"{i}: Gut {g} nicht in goods.json")
    e = {"id": i, "typ": t, "x_felder": x, "y_felder": y, "stufe": 1, "rolle": ro, "im_slice": sl,
         "eingang_gueter": ein, "ausgang_gueter": aus}
    if t == "kraftwerk": e["ausgang_art"] = "energie"
    if k: e["kette"] = k
    doc["industrien"].append(e)
for i, t, p in gelaende:
    doc["gelaende"].append({"id": i, "typ": t, "polygon": [list(q) for q in p]})
for i, n, b, p in fluesse:
    doc["fluesse"].append({"id": i, "name": n, "breite_felder": b, "linie": [list(q) for q in p]})
for kid, name, sl, quellen, verarb, abn, gl in ketten:
    for g in gl:
        if g not in goods_ids: errs.append(f"kette {kid}: Gut {g} fehlt")
    strecken = []
    for q in quellen:
        strecken.append({"von": q, "nach": verarb, "luftlinie_felder": rd(d(pos[q], pos[verarb]))})
    if abn: strecken.append({"von": verarb, "nach": abn, "luftlinie_felder": rd(d(pos[verarb], pos[abn]))})
    if kid == "k3": strecken.append({"von": "werkzeug_1", "nach": "mittelfurt", "luftlinie_felder": rd(d(pos["werkzeug_1"], pos["mittelfurt"]))})
    if kid == "k2": strecken.append({"von": "kraftwerk_1", "nach": "stahl_1", "luftlinie_felder": rd(d(pos["kraftwerk_1"], pos["stahl_1"])), "hinweis": "Energie-Radius 25 (L-08 power_radius)"})
    doc["ketten"].append({"id": kid, "name": name, "im_slice": sl, "gueter": gl, "strecken": strecken})
for a, b, kommentar in [("kohle_1", "stahl_1", "Kohle -> Stahlwerk"), ("farm_2", "muehle_1", "Farm 2 -> Muehle")]:
    doc["nischen"].append({"von": a, "nach": b, "luftlinie_felder": rd(d(pos[a], pos[b])), "soll_felder": 25, "hinweis": kommentar + ": Lkw-Sammeln (<25) und Zug (ab 25) beide vertretbar (L-08 truck_zug_cross_fields)"})
st_by = {c[0]: c for c in staedte}
for arch, cid, kid in hq:
    c = st_by[cid]; r = radius[c[2]]
    inr = sorted(i for i in pos if i in {x[0] for x in ind} and d(pos[cid], pos[i]) <= r)
    bau = [i[0] for i in ind if i[1] == "holzfaeller" and d(pos[cid], (i[2], i[3])) <= r]
    if not bau: errs.append(f"HQ {arch}: keine Bau-Rohstoffquelle im Radius (D13)")
    doc["hq_optionen"].append({"archetyp": arch, "stadt": cid, "im_slice": hq_im_slice[arch], "radius_felder": r,
        "startkapital_cent": consts["startkapital_cent"][arch], "startkette": kid, "industrien_im_radius": inr, "bau_quelle": bau[0] if bau else ""})

# ---------------- Pruefungen ----------------
for k, v in pos.items():
    if not (4 <= v[0] <= N - 5 and 4 <= v[1] <= N - 5): errs.append(f"{k} ausserhalb Karte/Rand")
keys = list(pos)
for a in range(len(keys)):
    for b in range(a + 1, len(keys)):
        dd = d(pos[keys[a]], pos[keys[b]])
        if dd < 8: errs.append(f"Abstand {keys[a]}-{keys[b]} = {dd:.1f} < 8")
for k, v in pos.items():
    for g, (t, p) in poly.items():
        inside = pip(v, p)
        if t == "meer" and (inside): errs.append(f"{k} im Meer")
        if t == "gebirge" and inside and k not in ("erz_1", "kohle_1"): errs.append(f"{k} im Gebirge")
        if t == "wald" and inside and not (k.startswith("holz_")): errs.append(f"{k} im Wald {g}")
    if river_dist(v, fluesse[0][3]) < 3 and k != "x": errs.append(f"{k} auf dem Fluss")
for m in ("erz_1", "kohle_1"):
    if not pip(pos[m], poly["gebirge_nw"][1]): errs.append(f"{m} nicht im Gebirge")
for h in ("holz_hafen", "holz_agrar", "holz_berg", "holz_handel"):
    if not any(pip(pos[h], p) for t, p in poly.values() if t == "wald"): errs.append(f"{h} nicht im Wald")
if poly_dist(pos["seehafen"], poly["meer_sued"][1]) > 10: errs.append("Seehafen nicht an der Kueste (<=10)")
if river_dist(pos["mittelfurt"], fluesse[0][3]) > 8: errs.append("Mittelfurt nicht am Fluss")
if river_dist(pos["haberau"], fluesse[0][3]) > 10: errs.append("Haberau nicht am Fluss")
if poly_dist(pos["kohlberg"], poly["gebirge_nw"][1]) > 25: errs.append("Kohlberg nicht am Gebirgsrand")
if abs(d(pos["kohle_1"], pos["stahl_1"]) - 25) > 3: errs.append("Nische Kohle-Stahl nicht ~25")
if d(pos["kraftwerk_1"], pos["stahl_1"]) > 25: errs.append("Kraftwerk ausserhalb 25 Felder von Stahlwerk")
if d(pos["erz_1"], pos["stahl_1"]) > 25: errs.append("Erz-Stahl > 25 (Lkw-Strecke)")
for g, (t, p) in poly.items():
    if any(not (0 <= x < N and 0 <= y < N) for x, y in p): errs.append(f"Polygon {g} ausserhalb")
for k, v in pos.items(): info.append(k)
json.dump(doc, open(HERE + "/slice_map.json", "w"), indent=1, ensure_ascii=False)
print("GEOMETRIE_FEHLER", len(errs)); [print(" -", e) for e in errs]
for s in doc["ketten"]: print(s["id"], [(x["von"], x["nach"], x["luftlinie_felder"]) for x in s["strecken"]])
for h in doc["hq_optionen"]: print("HQ", h["archetyp"], h["stadt"], h["radius_felder"], h["industrien_im_radius"], "bau:", h["bau_quelle"])
for n in doc["nischen"]: print("Nische", n["von"], n["nach"], n["luftlinie_felder"])
sys.exit(1 if errs else 0)
