#!/usr/bin/env python3
"""Export der Stadt-Rolle: proto_orte.json, proto_instanzen.json, proto_wege.json, proto_vorher_nachher.json.
Alles deterministisch (gerundet, feste Reihenfolge)."""
import json
import math
import os

from stadt_geo import (obb_ecken, poly_abstand, poly_laenge, resample, min_radius, r2, SEE_MITTE, SEE_R, SEE_PEGEL,
                       MUEHLTEICH_MITTE, MUEHLTEICH_R)
from stadt_bau import HAUS, rot_zu
from stadt_wege import (BRUECKE_LAENGE, BRUECKE_N, BRUECKE_S, BRUECKE_X, RINNE_BREITE, steigungsprofil)

WEG_REIHENFOLGE = ["chaussee", "hauptstrasse", "dorfstrasse_sued", "dorfstrasse_nord", "gasse_kirch", "bachgasse", "marktstrasse",
                   "gasse_lindenfurt", "muehlweg", "gutsweg", "hasenwinkelweg", "weiler_ast1", "weiler_ast2", "ostweg", "fischerpfad", "hofweg_hasenwinkel"]


def schreibe_json(pfad, daten, zeilenweise=False):
    os.makedirs(os.path.dirname(pfad), exist_ok=True)
    if zeilenweise and isinstance(daten, list):
        txt = "[\n" + ",\n".join(json.dumps(d, ensure_ascii=False, separators=(",", ":")) for d in daten) + "\n]\n"
    else:
        txt = json.dumps(daten, ensure_ascii=False, indent=1) + "\n"
    with open(pfad, "w", encoding="utf-8") as f:
        f.write(txt)


# ---------------------------------------------------------------- Vorstadt-Plan (Wachstum, Regel 4)
def vorstadt_funktion(pw, wege_ids, mitte, r_min=0.0, r_max=265.0, schritt=12.5):
    """Liefert vorstadt_plan(ol, rng): naechster freier Slot (Kernabstand + Rauschen) entlang der Ausfallstrassen."""
    from stadt_bau import PARZ

    def plan(ol, rng):
        slots = []
        for wid in wege_ids:
            p = pw[wid]
            for seite in (1, -1):
                s = 6.0
                while s <= p.L - 4.0:
                    P, t = p.an(s)
                    d = math.hypot(P[0] - mitte[0], P[1] - mitte[1])
                    if r_min <= d <= r_max:
                        slots.append((d + rng.uniform(-12.0, 12.0), p, seite, s))
                    s += schritt
        slots.sort(key=lambda t: t[0])
        typen = ("kate", "bauernhof") if rng.random() < 0.55 else ("bauernhof", "kate")
        for (key, p, seite, s) in slots:
            for typ in typen:
                W, T = PARZ[typ]
                P, eu, ev, ecken = ol.rahmen(p, seite, s, W, T, None)
                ctr = (sum(c[0] for c in ecken) / 4, sum(c[1] for c in ecken) / 4)
                if math.hypot(ctr[0] - mitte[0], ctr[1] - mitte[1]) > r_max:
                    continue
                ok, aue = ol.frei(ecken, p.weg, aue_max=0.7, front=ol.front_ecken(P, ev, eu, W, T))
                if not ok:
                    continue
                return ol.eintragen(typ, P, eu, ev, W, T, ecken, p.weg, seite, s)
        return None
    return plan


# ---------------------------------------------------------------- Kreuzungen
def station_auf(poly, p):
    """Bogenlaenge s (m) des naechsten Punkts auf poly zu p und Abstand."""
    d, i, t = poly_abstand(p, poly)
    s = 0.0
    for k in range(i):
        s += math.hypot(poly[k + 1][0] - poly[k][0], poly[k + 1][1] - poly[k][1])
    seg = math.hypot(poly[i + 1][0] - poly[i][0], poly[i + 1][1] - poly[i][1])
    return s + t * seg, d


def kreuzungen_finden(wo, K):
    knoten = []

    def nah(p):
        for k in knoten:
            if math.hypot(k["x"] - p[0], k["z"] - p[1]) < 14.0:
                return k
        return None
    knoten.append({"id": "k_erlenbach", "typ": "kreuzung4", "x": r2(K[0]), "z": r2(K[1]), "wege": ["chaussee", "hauptstrasse", "dorfstrasse_sued", "dorfstrasse_nord"],
                   "hinweis": "Hauptkreuzung Erlenbach (Chaussee Dorf-Markt, Hauptstrasse, Kirchstrasse, Bachstrasse), Knotenstueck 4-armig"})
    for wid in WEG_REIHENFOLGE:
        w = wo[wid]
        for ende, p in (("start", w.punkte[0]), ("ende", w.punkte[-1])):
            if math.hypot(p[0] - K[0], p[1] - K[1]) < 8.0:
                continue
            partner = []
            for oid in WEG_REIHENFOLGE:
                if oid == wid:
                    continue
                o = wo[oid]
                d, i, t = poly_abstand(p, o.punkte)
                if d < 8.0:
                    partner.append(oid)
            if not partner:
                continue
            k = nah(p)
            if k is None:
                k = {"id": "k%02d" % len(knoten), "typ": "t_einmuendung", "x": r2(p[0]), "z": r2(p[1]), "wege": []}
                knoten.append(k)
            for q in [wid] + partner:
                if q not in k["wege"]:
                    k["wege"].append(q)
    for k in knoten:
        k["wege"] = sorted(k["wege"], key=WEG_REIHENFOLGE.index)
    return knoten


# ---------------------------------------------------------------- Bruecken
def bruecken_daten(geo, chaussee_pts, bachbruecke):
    sN = station_auf(chaussee_pts, BRUECKE_N)
    sS = station_auf(chaussee_pts, BRUECKE_S)
    v = (BRUECKE_N[0] - BRUECKE_S[0], BRUECKE_N[1] - BRUECKE_S[1])
    rot_r = rot_zu(*v)
    fluss = dict(
        id="steinbogenbruecke_rotach", typ="steinbogen", name="Rotachbrücke",
        von=[r2(BRUECKE_S[0]), r2(BRUECKE_S[1])], bis=[r2(BRUECKE_N[0]), r2(BRUECKE_N[1])], rot_deg=r2(rot_r),
        s_von_m=r2(sS[0]), s_bis_m=r2(sN[0]), laenge_m=BRUECKE_LAENGE, rinne_breite_m=RINNE_BREITE,
        brueckenfelder=5, formel="ceil(75/25)=3 + 1 Rampe je Seite=5", boegen=5, bogen_m=15.0, rampe_m=25.0, breite_m=7.0,
        hoehe_widerlager_m=[r2(geo.hoehe(*BRUECKE_S)), r2(geo.hoehe(*BRUECKE_N))], wasserspiegel_m=36.4,
        hinweis="5 Boegen a 15 m ueber die Rinne (75 m), je 25 m Rampe an beiden Ufern; Fahrbahn waagerecht bis sanft gewoelbt, "
                "Pfeiler im Fluss; Chaussee-Band laeuft ueber das Bruecken-Mesh (kein Strassenband-Schnitt)")
    pb = bachbruecke
    i = min(range(len(chaussee_pts)), key=lambda k: math.hypot(chaussee_pts[k][0] - pb[0], chaussee_pts[k][1] - pb[1]))
    a = chaussee_pts[max(0, i - 2)]
    b = chaussee_pts[min(len(chaussee_pts) - 1, i + 2)]
    rot_b = rot_zu(b[0] - a[0], b[1] - a[1])
    dv = (math.sin(math.radians(rot_b)), math.cos(math.radians(rot_b)))
    bach = dict(
        id="bachbruecke_erlenbach", typ="bachbruecke_stein", name="Bachbrücke", mitte=[r2(pb[0]), r2(pb[1])], rot_deg=r2(rot_b),
        von=[r2(pb[0] - 12.0 * dv[0]), r2(pb[1] - 12.0 * dv[1])], bis=[r2(pb[0] + 12.0 * dv[0]), r2(pb[1] + 12.0 * dv[1])],
        s_m=r2(station_auf(chaussee_pts, pb)[0]), spann_m=8.0, laenge_m=24.0, breite_m=6.0, brueckenfelder=0,
        hinweis="Bach im Feld, kein Brueckenfeld (Regelwerk 12 bruecke.bach); Asset Nature bridge_stoneRound, Spann 8 m ueber 5 m Bachbett; "
                "Rinne +-12 m, Rampen im Gelaende")
    return [fluss, bach]


# ---------------------------------------------------------------- Wege exportieren
def wege_export(geo, wo, knoten, bruecken, allee_abs, chaussee_pts):
    out = []
    ausnahmen = ((BRUECKE_N[1] - 8, BRUECKE_S[1] + 8, BRUECKE_X - 8, BRUECKE_X + 8),)
    for wid in WEG_REIHENFOLGE:
        w = wo[wid]
        pts = [[r2(p[0]), r2(p[1])] for p in w.punkte]
        ex = ausnahmen if wid == "chaussee" else ()
        mx, mt, L = steigungsprofil(geo, pts, 10.0, bruecken=ex)
        d = {"id": wid, "typ": w.typ, "name": w.name, "breite_m": w.breite, "punkte": pts, "laenge_m": r2(L),
             "max_steigung_pct": r2(float(mx)), "mittel_steigung_pct": r2(float(mt))}
        if wid == "chaussee":
            d["trasse_m"] = 11.0
            d["bruecken"] = bruecken
            d["allee"] = allee_abs
            d["min_radius_m"] = r2(float(min_radius(resample(pts, 6.0), 4)))
        d["knoten"] = [k["id"] for k in knoten if wid in k["wege"]]
        out.append(d)
    return out


def allee_abschnitte(chaussee_pts, abs_s, abstand_m=7.0, takt_m=12.0):
    """Allee-Abschnitte (Bogenlaenge von-bis) mit Teilpolylinie."""
    pts = resample(chaussee_pts, 1.0)
    res = []
    for (s0, s1) in abs_s:
        i0, i1 = int(s0), min(len(pts) - 1, int(s1))
        sub = [[r2(p[0]), r2(p[1])] for p in pts[i0:i1 + 1:6]]
        if sub[-1] != [r2(pts[i1][0]), r2(pts[i1][1])]:
            sub.append([r2(pts[i1][0]), r2(pts[i1][1])])
        res.append({"s_von_m": r2(s0), "s_bis_m": r2(s1), "laenge_m": r2(s1 - s0), "seiten": 2, "achsabstand_m": abstand_m,
                    "takt_m": takt_m, "baumarten": ["laubbaum", "eiche"], "punkte": sub})
    return res


# ---------------------------------------------------------------- Instanzen exportieren
def instanz_export(d):
    o = {"typ": d["typ"], "x": d["x"], "z": d["z"], "rot_deg": d["rot_deg"], "parzelle": d["parzelle"]}
    for k in sorted(d):
        if k not in o:
            o[k] = d[k]
    return o


def ort_ew(szene, ort):
    return sum(HAUS[d["typ"]][2] for d in szene.inst if d["ort"] == ort and d["typ"] in HAUS)


def ort_zaehlung(szene, ort):
    n = {}
    for d in szene.inst:
        if d["ort"] == ort and d["typ"] in HAUS and d["typ"] != "stadttor":
            n[d["typ"]] = n.get(d["typ"], 0) + 1
    return dict(sorted(n.items()))


def parzellen_export(ol):
    out = []
    for p in ol.parz:
        out.append({"id": p["id"], "typ": p["typ"], "status": p["status"], "x": p["cx"], "z": p["cz"], "rot_deg": p["rot_deg"], "b": p["b"], "t": p["t"],
                    "weg": p["weg"]})
    return out


def kreis_um(punkte, mitte, zuschlag=12.0):
    return max(math.hypot(p[0] - mitte[0], p[1] - mitte[1]) for p in punkte) + zuschlag


def runde5(v):
    return float(int(math.ceil(v / 5.0) * 5))


def kreis_p90(zentren, mitte, zuschlag=12.5):
    """Ortsradius: 90-Perzentil der Hofstellen-Abstaende zur Ortsmitte + halbe Parzelle (Ausreisser zaehlen nicht)."""
    d = sorted(math.hypot(p[0] - mitte[0], p[1] - mitte[1]) for p in zentren)
    k = min(len(d) - 1, int(math.ceil(0.9 * len(d))) - 1)
    return d[k] + zuschlag
