#!/usr/bin/env python3
"""S-08: rechnet WCAG-Kontrast (Verhaeltnis der relativen Luminanz, sRGB) fuer Marker/Status/Ghost gegen Gras/Stadt/Wasser.
Aufruf: python3 -I compute_palette_s08.py  -> palette_s08.json + palette_s08_tabelle.md, Exit 0 wenn 100 % >= 3:1.
Hintergruende = Albedo-Farben aus prototype/main.gd (Gras Z.209, Wasser Z.387, Stadt Z.465-490, Berge Z.400, Baeume Z.417).
Annahme: unshaded Material (Token = gerenderte Farbe). Nicht in der Engine nachgemessen."""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
def b(c): return tuple(round(v * 255) for v in c)
def lighten(c, a): return tuple(v + (1 - v) * a for v in c)
BG = {  # name: (rgb, gruppe, pflicht)
 "gras": (b((0.45, 0.58, 0.36)), "gras", True),
 "wasser": (b((0.25, 0.5, 0.8)), "wasser", True),
 "wasser_hell": (b(lighten((0.25, 0.5, 0.8), 0.06)), "wasser", True),
 "stadt_strasse": (b((0.3, 0.3, 0.32)), "stadt", True),
 "stadt_haus_hell": (b((0.82, 0.78, 0.7)), "stadt", True),
 "stadt_haus_ziegel": (b((0.7, 0.45, 0.38)), "stadt", True),
 "stadt_hochhaus": (b((0.6, 0.66, 0.75)), "stadt", True),
 "wald_baum": (b((0.13, 0.38, 0.16)), "zusatz", False),
 "berg_stein": (b((0.5, 0.45, 0.38)), "zusatz", False),
 "berg_schnee": (b((0.95, 0.95, 0.97)), "zusatz", False),
}
SAUM = (15, 23, 32)
TOK = {  # name: (fill rgb, alpha)
 "marker": ((255, 194, 26), 1.0),
 "status_ok": ((72, 224, 138), 0.9),
 "status_warn": ((255, 166, 64), 0.9),
 "status_bad": ((255, 152, 138), 0.92),
 "ghost": ((255, 255, 255), 0.75),
}
def lin(v): v /= 255; return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
def L(c): return 0.2126 * lin(c[0]) + 0.7152 * lin(c[1]) + 0.0722 * lin(c[2])
def cr(a, c): x, y = sorted((L(a), L(c)), reverse=True); return (x + 0.05) / (y + 0.05)
def blend(f, a, bg): return tuple(round(a * f[i] + (1 - a) * bg[i]) for i in range(3))
rows = []; ok = 0
for t, (f, a) in TOK.items():
    for n, (bg, grp, pf) in BG.items():
        fb = blend(f, a, bg); c_fill = cr(fb, bg); c_saum = cr(SAUM, bg); c_in = cr(fb, SAUM); eff = max(c_fill, c_saum)
        p = eff >= 3 and c_in >= 3
        rows.append({"token": t, "hintergrund": n, "pflicht": pf, "fill_gemischt_rgb": list(fb), "fill_vs_bg": round(c_fill, 2), "saum_vs_bg": round(c_saum, 2), "fill_vs_saum": round(c_in, 2), "wirksam": round(eff, 2), "bestanden": p})
        ok += p
pf_rows = [r for r in rows if r["pflicht"]]
res = {"stand": "S-08", "regel": "Marker/Ghost bestanden, wenn max(Fuellung, Saum) >= 3:1 gegen den Hintergrund UND Fuellung >= 3:1 gegen Saum (Kontur immer erkennbar). Verhaeltnis (L1+0.05)/(L2+0.05), WCAG 2.x.",
 "saum": {"hex": "#%02X%02X%02X" % SAUM, "rgb": list(SAUM), "godot": [round(v / 255, 3) for v in SAUM], "alpha": 1.0, "breite_min_px": 2},
 "tokens": {t: {"hex": "#%02X%02X%02X" % f, "rgb": list(f), "godot": [round(v / 255, 3) for v in f], "alpha": a} for t, (f, a) in TOK.items()},
 "drei_farbtokens": {"marker": ["marker"], "status": ["status_ok", "status_warn", "status_bad"], "ghost": ["ghost"]},
 "ghost": {"fuellung": "weiss", "saum": "dunkel (saum)", "begruendung": "B-04: weiss allein auf Gras zu schwach; Saum liefert die Kontur"},
 "redundanz": "Status zusaetzlich ueber Form/Schraffur (bad und warn schraffiert wie im Prototyp), nicht nur Farbe",
 "hintergruende": {n: {"rgb": list(v[0]), "gruppe": v[1], "pflicht": v[2]} for n, v in BG.items()},
 "ergebnis": {"kombinationen_pflicht": len(pf_rows), "bestanden_pflicht": sum(r["bestanden"] for r in pf_rows), "kombinationen_gesamt": len(rows), "bestanden_gesamt": ok,
              "min_wirksam_pflicht": min(r["wirksam"] for r in pf_rows), "min_wirksam_gesamt": min(r["wirksam"] for r in rows)},
 "zeilen": rows}
json.dump(res, open(HERE + "/palette_s08.json", "w"), indent=1, ensure_ascii=False)
with open(HERE + "/palette_s08_tabelle.md", "w") as m:
    m.write("| Token | Hex | Alpha | min Kontrast (Pflicht-HG) | schwaechster HG | Fuellung/Saum |\n|---|---|---|---|---|---|\n")
    for t, (f, a) in TOK.items():
        rr = [r for r in pf_rows if r["token"] == t]; w = min(rr, key=lambda r: r["wirksam"])
        m.write("| %s | #%02X%02X%02X | %.2f | %.2f | %s | %.2f |\n" % (t, *f, a, w["wirksam"], w["hintergrund"], rr[0]["fill_vs_saum"]))
    m.write("| saum | #%02X%02X%02X | 1.00 | (nur Kontur) | | |\n" % SAUM)
print(json.dumps(res["ergebnis"])); print(open(HERE + "/palette_s08_tabelle.md").read())
for r in rows:
    if not r["bestanden"]: print("FAIL", r["token"], r["hintergrund"], r["wirksam"], r["fill_vs_saum"])
import sys; sys.exit(0 if res["ergebnis"]["bestanden_gesamt"] == len(rows) else 1)
