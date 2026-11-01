#!/usr/bin/env python3
"""S-10 Akzeptanzpruefung der Slice-Karte. Aufruf: python3 -I check_s10.py [ausgabe.json]  Exit 0 = alle Kriterien erfuellt."""
import json, math, os, sys
from PIL import Image, ImageDraw
HERE = os.path.dirname(os.path.abspath(__file__)); doc = json.load(open(HERE + "/slice_map.json")); N = doc["karte"]["breite_felder"]
items = [(s["id"], "stadt", s["x_felder"], s["y_felder"]) for s in doc["staedte"]] + [(i["id"], "industrie", i["x_felder"], i["y_felder"]) for i in doc["industrien"] if i["im_slice"]]
h = N // 2; q = {"NW": 0, "NO": 0, "SW": 0, "SO": 0}
for _, _, x, y in items: q[("N" if y < h else "S") + ("W" if x < h else "O")] += 1
tot = len(items); share = {k: 100 * v / tot for k, v in q.items()}
st = [(s["id"], s["x_felder"], s["y_felder"]) for s in doc["staedte"]]
dm = min((math.hypot(a[1]-b[1], a[2]-b[2]), a[0], b[0]) for i, a in enumerate(st) for b in st[i+1:])
area = {}
for g in doc["gelaende"]:
    m = Image.new("1", (N, N), 0); ImageDraw.Draw(m).polygon([tuple(p) for p in g["polygon"]], fill=1)
    area[g["typ"]] = area.get(g["typ"], 0) + sum(m.getdata())
sh_t = {k: 100 * v / (N * N) for k, v in area.items()}
nis = [(n["von"], n["nach"], n["luftlinie_felder"]) for n in doc["nischen"]]
res = {"inhalte_gesamt": tot, "staedte": len(st), "industrien_im_slice": tot - len(st), "quadranten_anzahl": q,
       "quadranten_prozent": {k: round(v, 1) for k, v in share.items()},
       "stadtabstand_min_felder": round(dm[0], 1), "stadtabstand_min_paar": [dm[1], dm[2]], "stadtabstand_min_prozent_breite": round(100 * dm[0] / N, 1),
       "gelaende_prozent": {k: round(v, 1) for k, v in sh_t.items()}, "nischen": nis,
       "kriterien": {"quadrant_25_pm5": all(20 <= v <= 30 for v in share.values()), "stadtabstand_ge_15": 100 * dm[0] / N >= 15,
                     "region_le_40": max(list(share.values()) + list(sh_t.values())) <= 40, "nische_20_30": any(20 <= n[2] <= 30 for n in nis), "staedte_ge_4": len(st) >= 4}}
print(json.dumps(res, indent=1, ensure_ascii=False))
if len(sys.argv) > 1: json.dump(res, open(sys.argv[1], "w"), indent=1, ensure_ascii=False)
sys.exit(0 if all(res["kriterien"].values()) else 1)
