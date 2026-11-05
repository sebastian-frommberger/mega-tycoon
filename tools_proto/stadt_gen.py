#!/usr/bin/env python3
"""Stadt-/Level-Designer, Phase 4 Welle 1: Orte, Instanzlisten, Wege, Wachstum fuer die Prototyp-Welt.

Deterministisch (Seed 7, PCG32, keine Mengenordnung, gerundete Ausgabe) -> md5-stabil.
Aufruf:  python3 tools_proto/stadt_gen.py [--src DIR] [--out DIR] [--bilder] [--md5]
Schreibt in slice/world/data/proto/: proto_orte.json, proto_instanzen.json, proto_wege.json, proto_vorher_nachher.json
(und Bilder nach _out/bilder/, wenn --bilder).
"""
import argparse
import hashlib
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from stadt_geo import (obb_ueberlappt, astar, BACH_PUNKTE, BILD_DIR, Gelaende, KERN_B, KERN_T, MUEHLE_VORSCHLAG, MUEHLTEICH_MITTE, MUEHLTEICH_R,
                       OUT_DIR, PCG, ROOT, SEE_MITTE, SEE_PEGEL, SEE_R, SRC_DEFAULT, clark_evans, konvexe_huelle,
                       flaeche, min_radius, obb_ecken, poly_abstand, punkt_in_obb, poly_laenge, resample, r2, vereinfachen)
from stadt_bau import HAUS, NEBEN, PARZ, Szene, Weg, baue_hofstelle, gelaende_ok, rot_zu, weg_frei
from stadt_dorf import Ortslage, Parzelle, Punktweg
import stadt_ladeplatz as lp
from stadt_wege import (BRUECKE_LAENGE, BRUECKE_N, BRUECKE_S, BRUECKE_X, KREUZUNG_DORF, RINNE_BREITE, _sperre_chaussee,
                        _zusatz_chaussee, glatt, route, steigungsprofil)

WELT_SEED = 7
VERSION = "stadt_gen 1.0 (Phase 4 Welle 1)"

# ---------------------------------------------------------------- Ortsdaten (Namen erfunden, 1820, deutsch)
DORF = dict(id="erlenbach", name="Erlenbach", klasse="dorf", form="haufendorf")
WEILER = dict(id="hasenwinkel", name="Hasenwinkel", klasse="weiler", form="weiler")
STADT = dict(id="lindenfurt", name="Lindenfurt", klasse="kleinstadt", form="mauerkern_markt_ausschnitt")
GUT = dict(id="gut_kuppenhof", name="Gut Kuppenhof")
GUT2 = dict(id="hof_hasenwinkel", name="Hof Hasenwinkel")     # WA-07: Farm 2, 35-50 Felder (Luftlinie) von der Muehle
MUEHLE = dict(id="erlenmuehle", name="Erlenmühle")
SEE_NAME = "Binsensee"
FLUSS_NAME = "Rotach"
BACH_NAME = "Erlenbach"

# Lagepunkte (lokale Meter), Begruendung in der Doku
K = KREUZUNG_DORF                      # Hauptkreuzung Erlenbach
GUT_POS = (1935.0, 1355.0)             # Kuppe (Plateau 61 m), Vierseithof
WEILER_POS = (790.0, 858.0)            # Strip B west, 190 m vom Seeufer
MARKT_MITTE = (96.0, 138.0)            # Mitte Marktplatz, NW-Kernrand, Nordufer
DORFTEICH = (1512.0, 818.0, 12.5)      # am Bach, Bachgasse
# WA-07: Sim-EW je Ort = Ort-EW + Umland-EW (Regelwerk ortsklassen: Dorf Umland 250-550, Kleinstadt Ort 2.000-4.000, Umland 400-700).
# Erlenbach: Ort 244 (Bestand) + Umland 256 = 500 (-> 10 E/min); Lindenfurt: Ort 2000 + Umland 400 = 2400 (-> 24 E/min). Weiler: kein Sim-Knoten.
SIM_EW = {"erlenbach": {"sim_knoten": True, "sim_stufe": "dorf", "sim_ew": 500},
          "lindenfurt": {"sim_knoten": True, "sim_stufe": "kleinstadt", "sim_ew": 2400, "ew_ort": 2000, "ew_umland": 400, "ew_ausschnitt": 387},
          "hasenwinkel": {"sim_knoten": False}}
HOF_SCHLAG_ABSTAND = 5.0               # WA-10: Schlag mindestens so weit vom Hofrand (m)
FARM2_FELDER = (36.0, 48.0)            # WA-07: Soll 35-50 Felder (Luftlinie Muehle - Farm 2), je 1 Feld Reserve zum Rand
FARM2_KANDIDATEN = [(x, z) for z in range(700, 781, 10) for x in range(640, 761, 10)]   # nordwestlich des Weilers, Ebene
FISCHER_WINKEL_DEG = -47.0             # Fischerhuette am NO-Ufer


def md5_datei(pfad):
    h = hashlib.md5()
    with open(pfad, "rb") as f:
        h.update(f.read())
    return h.hexdigest()


# ---------------------------------------------------------------- Wege
FILLET_R = 55.0
D_TOR = 200.0   # Abstand Tor - Marktmitte (m)


def tor_position():
    # Tor 175 m suedoestlich des Marktplatz-Mittelpunkts entlang der Streifenachse (31 Grad unter Ost)
    a = math.radians(31.0)
    return (MARKT_MITTE[0] + D_TOR * math.cos(a), MARKT_MITTE[1] + D_TOR * math.sin(a))


def weg_dict(wid, typ, punkte, breite, name, **extra):
    d = {"id": wid, "typ": typ, "name": name, "breite_m": breite, "punkte": [[r2(p[0]), r2(p[1])] for p in punkte]}
    d.update(extra)
    return d


def wege_bauen(geo):
    """Liefert dict id -> Weg-Dict (Rohform, noch ohne Allee) und Hilfsdaten."""
    sperre = _sperre_chaussee(geo)
    zus = _zusatz_chaussee(geo)
    TOR = tor_position()
    # --- Chaussee Erlenbach (K) -> Bruecke -> Lindenfurt (Tor)
    arc = [(BRUECKE_X + FILLET_R + FILLET_R * math.cos(math.radians(p)), 650.0 + FILLET_R * math.sin(math.radians(p)))
           for p in range(90, 181, 15)]
    kp = [K, (1520, 737), (1462, 728), (1410, 714), (1365, 706)] + arc
    kp += [(BRUECKE_X, 625), (BRUECKE_X, 587.5), (BRUECKE_X, 550), (BRUECKE_X, 525), (BRUECKE_X, 490), (BRUECKE_X, 462),
           (1283, 432), (1262, 404), (1228, 380), (1185, 364)]
    dd = (math.cos(math.radians(31.0)), math.sin(math.radians(31.0)))
    anf = (TOR[0] + 100.0 * dd[0], TOR[1] + 100.0 * dd[1])
    p_n, kp_n = route(geo, (1185.0, 364.0), anf, sperre, zus, tol=25.0)
    kp += kp_n[1:] + [(TOR[0] + 60.0 * dd[0], TOR[1] + 60.0 * dd[1]), (TOR[0] + 25.0 * dd[0], TOR[1] + 25.0 * dd[1]), TOR]
    chaussee = glatt(kp, 6.0, 12)
    chaussee[0] = K
    chaussee[-1] = TOR
    w = {}
    w["chaussee"] = dict(id="chaussee", typ="chaussee", name="Chaussee Erlenbach - Lindenfurt", breite_m=6.0, trasse_m=11.0,
                         punkte=chaussee)
    return w, TOR


def dorfwege(geo):
    """Dorfstrassen, Gassen (Haufendorf Erlenbach) aus handgesetzten Kontrollpunkten, geglaettet."""
    d = {}
    d["hauptstrasse"] = ("dorfstrasse", 6.0, "Hauptstra\u00dfe",
                         glatt([K, (1690, 712), (1760, 684), (1830, 648), (1892, 606)], 4.0, 12))
    d["dorfstrasse_sued"] = ("dorfstrasse", 6.0, "Kirchstra\u00dfe", glatt([K, (1629, 772), (1626, 815), (1620, 856)], 4.0, 12))
    d["dorfstrasse_nord"] = ("dorfstrasse", 6.0, "Bachstra\u00dfe", glatt([K, (1634, 692), (1646, 654)], 4.0, 12))
    d["gasse_kirch"] = ("gasse", 5.0, "Kirchgasse", glatt([(1692, 711), (1714, 746), (1696, 786), (1656, 806), (1627, 812)], 4.0, 12))
    d["bachgasse"] = ("gasse", 5.0, "Bachgasse", glatt([(1520, 735), (1522, 772), (1526, 812)], 4.0, 12))
    return d


# ---------------------------------------------------------------- Quoten
class Quoten:
    """Verbleibende Haus-Anzahl je Typ; Vorschlag nach Lage (Naehe zum Kern) gewichtet."""

    def __init__(self, rest, r):
        self.rest = dict(rest)
        self.r = r

    def __call__(self, dk, rng, bestaetigt=None):
        if bestaetigt is not None:
            if self.rest.get(bestaetigt, 0) <= 0:
                return None
            self.rest[bestaetigt] -= 1
            return bestaetigt
        items = []
        f = 0.5 if dk is None else min(1.0, dk / self.r)
        gew = {"bauernhof": 0.5, "kate": 0.25 + 0.3 * f, "handwerkerhaus": 0.25 * (1.0 - f) + 0.02}
        for t, n in self.rest.items():
            if n > 0:
                items.append((t, gew.get(t, 0.3) * n))
        if not items:
            return None
        return rng.weighted(items)

    def leer(self):
        return all(v <= 0 for v in self.rest.values())


def kandidaten_sonder(ol, pws, typ, bedingung, sort_key, seiten=(1, -1), schritt=5.0, abstand_achse=None, aue_max=0.0):
    W, T = PARZ[typ]
    out = []
    for pw in pws:
        s = 0.0
        while s <= pw.L - W:
            for seite in seiten:
                P, eu, ev, ecken = ol.rahmen(pw, seite, s, W, T, abstand_achse)
                ctr = (sum(p[0] for p in ecken) / 4, sum(p[1] for p in ecken) / 4)
                if not bedingung(ctr, pw, seite, s):
                    continue
                ok, aue = ol.frei(ecken, pw.weg, aue_max=aue_max)
                if ok:
                    out.append((sort_key(ctr, pw, seite, s), pw, seite, s, P, eu, ev, ecken))
            s += schritt
    out.sort(key=lambda t: t[0])
    return out


def dorf_bauen(geo, szene, weglisten):
    """Haufendorf Erlenbach. weglisten: dict id -> Weg (alle Wege der Welt als Hindernis)."""
    alle = list(weglisten.values())
    mitte = (1655.0, 722.0)
    ol = Ortslage(szene, geo, DORF["id"], K, 170.0, alle, "form", WELT_SEED)
    pw = {k: Punktweg(v) for k, v in weglisten.items()}
    rng = ol.rng
    # --- Sonderbauten: Kirche auf dem hoechsten Punkt im Umkreis 60 m um die Kreuzung, Gasthaus an der Kreuzung,
    #     Schmiede am Ortseingang West (Bachbruecke)
    ws = [pw["hauptstrasse"], pw["dorfstrasse_sued"], pw["dorfstrasse_nord"], pw["gasse_kirch"]]
    kir = kandidaten_sonder(ol, ws, "kirche_dorf",
                            lambda c, p, se, s: ol.d_kern(c) <= 62.0 and ol.d_kern(c) >= 28.0,
                            lambda c, p, se, s: -geo.hoehe(*c))
    if not kir:
        raise RuntimeError("keine Kirchenlage")
    _, p_, se_, s_, P, eu, ev, ecken = kir[0]
    par = ol.eintragen("kirche_dorf", P, eu, ev, 37.5, 37.5, ecken, p_.weg, se_, s_, status="besetzt", sonder=True)
    ol.besetzen(par)
    gast = kandidaten_sonder(ol, [pw["chaussee"], pw["hauptstrasse"], pw["dorfstrasse_sued"], pw["dorfstrasse_nord"]], "gasthaus",
                             lambda c, p, se, s: ol.d_kern(c) <= 45.0 and (p.weg.id != "chaussee" or s > p.L - 45.0),
                             lambda c, p, se, s: ol.d_kern(c))
    if not gast:
        raise RuntimeError("keine Gasthauslage")
    _, p_, se_, s_, P, eu, ev, ecken = gast[0]
    par = ol.eintragen("gasthaus", P, eu, ev, 25.0, 35.0, ecken, p_.weg, se_, s_, status="besetzt", sonder=True)
    ol.besetzen(par)
    ch = pw["chaussee"]
    schm = kandidaten_sonder(ol, [ch], "schmiede",
                             lambda c, p, se, s: 1470.0 <= c[0] <= 1535.0 and se == 1,
                             lambda c, p, se, s: abs(c[0] - 1500.0), seiten=(1, -1))
    if not schm:
        schm = kandidaten_sonder(ol, [ch], "schmiede", lambda c, p, se, s: 1470.0 <= c[0] <= 1550.0, lambda c, p, se, s: abs(c[0] - 1500.0))
    _, p_, se_, s_, P, eu, ev, ecken = schm[0]
    par = ol.eintragen("schmiede", P, eu, ev, 15.0, 20.0, ecken, p_.weg, se_, s_, status="besetzt", sonder=True)
    ol.besetzen(par)
    # --- Hofstellen entlang der Wege: nach Kernabstand sortiert (kompakt), Annahme p = 1 - (d/r)^2 (05 Abschnitt 3a)
    # Parzellen insgesamt 42: 35 Wohnhaeuser + 7 Luecken. Typen je Quote (Kate 15, Hof 24, Handwerker 3 inkl. Luecken)
    q = Quoten({"kate": 18, "bauernhof": 26, "handwerkerhaus": 4}, 170.0)
    cd = Punktweg(Weg("chaussee", "chaussee", alle_ch_dorf(weglisten["chaussee"].punkte), 6.0))
    pw["chaussee_dorf"] = cd
    for durchgang in range(5):
        akz = lambda dk, d=durchgang: min(1.0, max(0.04, 1.0 - (dk / 195.0) ** 2) + 0.3 * d)
        plan = []
        for wid in ("hauptstrasse", "dorfstrasse_sued", "dorfstrasse_nord", "gasse_kirch", "chaussee_dorf"):
            p = pw[wid]
            for seite in (1, -1):
                plan.append((p, seite, 6.0, p.L - 4.0, None))
        ol.fuellen(plan, q, akz, max_abstand=((1672.0, 712.0), 207.0), aue_max=0.0 if durchgang < 2 else (0.35 if durchgang < 4 else 0.7), rauschen=14.0, max_n=max(0, 42 - (len(ol.parz) - 3)))
        if q.leer() or len(ol.parz) - 3 >= 42:
            break
    return ol, q, pw


def alle_ch_dorf(punkte):
    """Chaussee von K bis 125 m westlich (Bach und Ortseingang), als eigene Polylinie fuer die Parzellenreihen."""
    out = []
    L = 0.0
    for k in range(len(punkte)):
        out.append(punkte[k])
        if k > 0:
            L += math.hypot(punkte[k][0] - punkte[k - 1][0], punkte[k][1] - punkte[k - 1][1])
        if L > 140.0:
            break
    return out


def vorschau(geo, szene, ol_list, name, xl, zl, wege_dicts=None, groesse=(14, 9)):
    import matplotlib.pyplot as plt
    from stadt_bilder import zeichne, speichern
    fig, ax = plt.subplots(figsize=groesse)
    zeichne(ax, geo, szene, xl, zl, beschriftung=False)
    for o in ol_list:
        for p in o.parz:
            ec = obb_ecken(p["cx"], p["cz"], p["b"], p["t"], p["rot_deg"])
            ax.add_patch(__import__("matplotlib.patches", fromlist=["Polygon"]).Polygon(ec, closed=True, fc="none",
                         ec="#00aa88" if p["status"] == "besetzt" else "#dd2222", lw=0.5, zorder=9))
    return speichern(fig, name)



# ---------------------------------------------------------------- Feldwege (A*) und Hilfen
def wackeln(punkte, rng, amp=8.0, abstand=70.0):
    """Setzt zwischen Anfang und Ende seitlich versetzte Zwischenpunkte (deterministisch), damit Feldwege nicht schnurgerade sind."""
    out = [punkte[0]]
    for k in range(len(punkte) - 1):
        a, b = punkte[k], punkte[k + 1]
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = int(L // abstand)
        if n >= 1:
            nx, nz = -(b[1] - a[1]) / L, (b[0] - a[0]) / L
            for i in range(1, n + 1):
                t = i / (n + 1.0)
                off = rng.uniform(-amp, amp)
                out.append((a[0] + (b[0] - a[0]) * t + nx * off, a[1] + (b[1] - a[1]) * t + nz * off))
        out.append(b)
    return out


def feldweg_route(geo, a, b, rng, max_steig=0.09, amp=7.0, tol=14.0, sperre=None, schritt=5.0):
    def sp(x, z):
        if geo.rinne_abstand(x, z) < 45 or geo.see_abstand(x, z) < 35 or geo.muehlteich_abstand(x, z) < 12 or geo.bach_abstand(x, z) < 9:
            return True
        return bool(sperre and sperre(x, z))
    zus = lambda x, z: 0.2 if geo.in_aue(x, z) else 0.0
    p = astar(geo, a, b, sp, zus, max_steig=max_steig)
    if p is None:
        raise RuntimeError("Kein Feldweg %s -> %s" % (a, b))
    kp = vereinfachen(p, tol)
    kp = wackeln(kp, rng, amp)
    return glatt(kp, schritt, 10)


# ---------------------------------------------------------------- Weiler Hasenwinkel: 6 Hoefe
def weiler_bauen(geo, szene, wege, rng_w):
    """6 Hofstellen (Bauernhoefe 25x25) an einer Y-foermigen Gasse am Ende des Feldwegs."""
    zufahrt = wege["hasenwinkelweg"]
    pz = Punktweg(zufahrt)
    ende = pz.pts[-1]
    # Stichweg im Weiler: zwei Aeste vom Wegende
    a1 = glatt([ende, (ende[0] - 28, ende[1] + 8), (ende[0] - 62, ende[1] + 18)], 4.0, 10)
    a2 = glatt([(ende[0] - 26, ende[1] + 7), (ende[0] - 40, ende[1] - 24), (ende[0] - 46, ende[1] - 52)], 4.0, 10)
    w_a1 = Weg("weiler_ast1", "feldweg", a1, 3.5, "Hasenwinkel Ast 1")
    w_a2 = Weg("weiler_ast2", "feldweg", a2, 3.5, "Hasenwinkel Ast 2")
    alle = list(wege.values()) + [w_a1, w_a2]
    ol = Ortslage(szene, geo, WEILER["id"], (ende[0] - 25, ende[1]), 70.0, alle, "form", WELT_SEED)
    q = Quoten({"bauernhof": 6}, 70.0)
    pw1, pw2 = Punktweg(w_a1), Punktweg(w_a2)
    pwz = Punktweg(Weg(zufahrt.id, "feldweg", zufahrt.punkte[-30:], 3.5))
    plan = []
    for p in (pwz, pw1, pw2):
        for seite in (1, -1):
            plan.append((p, seite, 2.0, p.L - 2.0, 3.0))
    for durchgang in range(4):
        ol.fuellen(plan, q, lambda dk, d=durchgang: 0.7 + 0.1 * d, aue_max=0.0 if durchgang < 2 else 0.5, rauschen=10.0, max_n=6 - len(ol.parz))
        if len(ol.parz) >= 6:
            break
    return ol, [w_a1, w_a2]


# ---------------------------------------------------------------- Gutshof, Muehle, See-Nutzung
def gut_bauen(geo, szene, zufahrt_richtung):
    """Vierseithof 40x40 auf der Kuppe, Fassade zur Zufahrt; drei Schlaege (Gewann 200x125) auf dem Plateau."""
    x, z = GUT_POS
    rot = rot_zu(zufahrt_richtung[0], zufahrt_richtung[1])
    pid = "gut_p01"
    szene.add("gutshof", x, z, rot, pid, GUT["id"], b=40.0, t=40.0)
    # Hofflaeche, Obstgarten
    szene.add("flaeche_hof", x, z, rot, pid, GUT["id"], b=30.0, t=30.0)
    ex = (math.cos(math.radians(rot)), -math.sin(math.radians(rot)))
    ez = (math.sin(math.radians(rot)), math.cos(math.radians(rot)))
    gx, gz = x - ex[0] * 38 - ez[0] * 6, z - ex[1] * 38 - ez[1] * 6
    szene.add("flaeche_obstwiese", gx, gz, rot, pid, GUT["id"], b=26.0, t=34.0)
    rng = PCG(PCG.hash_seed(WELT_SEED, GUT["id"], "belebung"))
    for i in range(6):
        szene.add("obstbaum", gx + rng.uniform(-10, 10), gz + rng.uniform(-14, 14), rng.uniform(-180, 180), pid, GUT["id"])
    for i in range(3):
        px, pz = x + ex[0] * rng.uniform(-8, 8) + ez[0] * (14 + i * 2), z + ex[1] * rng.uniform(-8, 8) + ez[1] * (14 + i * 2)
        szene.add("heuhaufen", px, pz, rng.uniform(-180, 180), pid, GUT["id"])
    szene.add("holzstapel", x + ez[0] * 23 + ex[0] * 10, z + ez[1] * 23 + ex[1] * 10, rot, pid, GUT["id"])
    # Schlaege: 200 x 125 m, Plateau 61 m, Mittelpunkte so, dass Neigung <= 6 % in der Mitte und Ecken
    cand = [(-135.0, 5.0, 0.0), (0.0, 95.0, 90.0), (130.0, 25.0, 0.0), (-20.0, -95.0, 90.0)]
    n = 0
    for (dx, dz, r_) in cand:
        sx, sz = x + dx, z + dz
        ok = True
        for (cx_, cz_) in obb_ecken(sx, sz, 200.0 if r_ == 0 else 125.0, 125.0 if r_ == 0 else 200.0, 0.0):
            if geo.steigung(cx_, cz_) > 8.0:
                ok = False
        if ok and n < 3:
            szene.add("flaeche_schlag", sx, sz, 0.0, pid, GUT["id"], b=200.0 if r_ == 0 else 125.0, t=125.0 if r_ == 0 else 200.0)
            n += 1
    return n


def farm2_bauen(geo, szene, wo):
    """WA-07: Farm 2 'Hof Hasenwinkel' (Vierseithof 40x40) nordwestlich des Weilers, Zufahrt als Feldweg vom Ende von weiler_ast2.
    Eigener Zufallsstrom und Aufruf nach allen anderen Bauten -> aendert keine bestehende Ausgabe."""
    rng = PCG(PCG.hash_seed(WELT_SEED, GUT2["id"], "farm2"))
    start = wo["weiler_ast2"].punkte[-1]
    mx, mz = MUEHLE_POS
    best = None
    for (hx, hz) in FARM2_KANDIDATEN:
        felder = math.hypot(hx - mx, hz - mz) / 25.0
        if not (FARM2_FELDER[0] <= felder <= FARM2_FELDER[1]):
            continue
        ok, aue = gelaende_ok(geo, obb_ecken(hx, hz, 56.0, 56.0, 0.0), (hx, hz), max_steig=3.0)
        if not ok or aue > 0.0:
            continue
        if any(math.hypot(hx - sum(c[0] for c in e) / 4.0, hz - sum(c[1] for c in e) / 4.0) < 55.0 for (e, t, p, o) in szene.foot):
            continue
        best = (hx, hz)
        break
    if best is None:
        raise RuntimeError("Farm 2: kein Standort")
    hx, hz = best
    L = math.hypot(start[0] - hx, start[1] - hz)
    tor = (hx + (start[0] - hx) / L * 30.0, hz + (start[1] - hz) / L * 30.0)
    route_pts = feldweg_route(geo, start, tor, rng, max_steig=0.085, amp=3.0, tol=14.0)
    wo["hofweg_hasenwinkel"] = Weg("hofweg_hasenwinkel", "feldweg", route_pts, 3.5, "Hofweg Hasenwinkel")
    p_end, p_vor = route_pts[-1], route_pts[-6]
    rot = rot_zu(p_vor[0] - hx, p_vor[1] - hz)
    pid = "hof_p01"
    szene.add("gutshof", hx, hz, rot, pid, GUT2["id"], b=40.0, t=40.0)
    szene.add("flaeche_hof", hx, hz, rot, pid, GUT2["id"], b=30.0, t=30.0)
    ex = (math.cos(math.radians(rot)), -math.sin(math.radians(rot)))
    ez = (math.sin(math.radians(rot)), math.cos(math.radians(rot)))
    for i in range(3):
        szene.add("heuhaufen", hx + ex[0] * rng.uniform(-8, 8) + ez[0] * (14 + i * 2), hz + ex[1] * rng.uniform(-8, 8) + ez[1] * (14 + i * 2),
                  rng.uniform(-180, 180), pid, GUT2["id"])
    szene.add("holzstapel", hx + ez[0] * 23 + ex[0] * 10, hz + ez[1] * 23 + ex[1] * 10, rot, pid, GUT2["id"])
    n = 0
    schlaege = []
    for (dx, dz, r_) in ((-135.0, -40.0, 0.0), (10.0, -140.0, 90.0), (-20.0, 140.0, 90.0), (140.0, -30.0, 0.0)):     # WA-10: dz 110 -> 140 bzw. 100 -> 140 (Schlag lag 10-20 m auf dem Hof)
        sx, sz = hx + dx, hz + dz
        b_, t_ = (200.0, 125.0) if r_ == 0 else (125.0, 200.0)
        ecken = obb_ecken(sx, sz, b_, t_, 0.0)
        if obb_ueberlappt(ecken, obb_ecken(hx, hz, 40.0 + 2 * HOF_SCHLAG_ABSTAND, 40.0 + 2 * HOF_SCHLAG_ABSTAND, rot)):      # WA-10: kein Schlag auf dem eigenen Hof
            continue
        if n >= 2 or any(geo.steigung(c[0], c[1]) > 8.0 or geo.rinne_abstand(c[0], c[1]) < 30 or geo.see_abstand(c[0], c[1]) < 30 for c in ecken):
            continue
        # Schlag darf kein Gebaeude (auch nicht die Weilerhoefe) und keinen Weg ausser dem Hofweg ueberdecken
        if any(punkt_in_obb(c, ecken) for (e, t, p, o) in szene.foot if o != GUT2["id"] for c in e):
            continue
        if any(punkt_in_obb(q, ecken) for k, w in wo.items() if k != "hofweg_hasenwinkel" for q in w.punkte):
            continue
        szene.add("flaeche_schlag", sx, sz, 0.0, pid, GUT2["id"], b=b_, t=t_)
        schlaege.append({"x": r2(sx), "z": r2(sz), "b": r2(b_), "t": r2(t_)})
        n += 1
    return dict(x=hx, z=hz, rot=rot, tor=p_end, schlaege=schlaege)


def muehle_bauen(geo, szene):
    pid = "muehle_p01"
    mx, mz = MUEHLE_POS
    szene.add("wassermuehle", mx, mz, 180.0, pid, MUEHLE["id"], b=12.0, t=12.0)
    # Wasserrad (Rolle wassermuehle_rad, Durchmesser 5 m) an der Westflanke zum Bach
    szene.add("wassermuehle_rad", mx - 6.8, mz, 90.0, pid, MUEHLE["id"])
    szene.add("flaeche_hof", mx + 3.0, mz - 10.0, 0.0, pid, MUEHLE["id"], b=14.0, t=10.0)
    szene.add("holzstapel", mx + 9.0, mz + 3.0, 20.0, pid, MUEHLE["id"])
    szene.add("fass", mx + 7.5, mz - 8.5, 0.0, pid, MUEHLE["id"])


def see_bauen(geo, szene, rng):
    """Fischerhuette mit Netzgestell, Steg, Ruderboot am Steg, Boot auf der Schleife; liefert Daten fuer proto_orte.json."""
    th = math.radians(FISCHER_WINKEL_DEG)
    u = (math.cos(th), math.sin(th))
    pt = (SEE_MITTE[0] + 250 * u[0], SEE_MITTE[1] + 250 * u[1])
    r = geo.see_reff(*pt)
    pid = "fischer_p01"
    hx, hz = SEE_MITTE[0] + (r + 22.0) * u[0], SEE_MITTE[1] + (r + 22.0) * u[1]
    rot_h = rot_zu(-u[0], -u[1])
    szene.add("fischerhuette", hx, hz, rot_h, pid, "binsensee", b=8.0, t=6.0)
    ex = (math.cos(math.radians(rot_h)), -math.sin(math.radians(rot_h)))
    szene.add("netzgestell", hx + ex[0] * 7.5 + (-u[0]) * 2.0, hz + ex[1] * 7.5 + (-u[1]) * 2.0, rot_h + 90, pid, "binsensee", b=4.0, t=1.5)
    szene.add("flaeche_hof", hx + u[0] * 0.0, hz + u[1] * 0.0, rot_h, pid, "binsensee", b=14.0, t=12.0)
    szene.add("holzstapel", hx - ex[0] * 6.5, hz - ex[1] * 6.5, rot_h, pid, "binsensee")
    # Steg 25 x 2 m: Wurzel 4 m ausserhalb der Uferlinie, Ende 21 m im Wasser (Laenge entlang des Strahls)
    sx, sz = SEE_MITTE[0] + (r + 4.0 - 12.5) * u[0], SEE_MITTE[1] + (r + 4.0 - 12.5) * u[1]
    rot_s = -FISCHER_WINKEL_DEG
    szene.add("steg", sx, sz, rot_s, pid, "binsensee", b=25.0, t=2.0)
    bx, bz = SEE_MITTE[0] + (r - 20.0) * u[0] - u[1] * 2.6 * -1.0, SEE_MITTE[1] + (r - 20.0) * u[1] + u[0] * 2.6 * -1.0
    szene.add("ruderboot", bx, bz, rot_s + 4.0, pid, "binsensee", b=4.5, t=1.4)
    pfad_start = (hx, hz)
    return dict(huette=[r2(hx), r2(hz)], steg_wurzel=[r2(SEE_MITTE[0] + (r + 4.0) * u[0]), r2(SEE_MITTE[1] + (r + 4.0) * u[1])],
                steg_ende=[r2(SEE_MITTE[0] + (r - 21.0) * u[0]), r2(SEE_MITTE[1] + (r - 21.0) * u[1])],
                boot_am_steg=[r2(bx), r2(bz)], uferwinkel_deg=FISCHER_WINKEL_DEG, ufer_radius_m=r2(r),
                boot_schleife=dict(mitte=[r2(SEE_MITTE[0] - 9.0), r2(SEE_MITTE[1] + 6.0)], radius_m=33.0, umlauf_s=90.0,      # WA-12: Seeradius 75 m (vorher 250 m: 110 m / 300 s, gleiche Bootsgeschwindigkeit 2,3 m/s)
                                   hinweis="Kulissen-Animation, keine Sim; Boot 4,5 m, Kreisbahn im Uhrzeigersinn"),
                pfad_start=[r2(hx), r2(hz)])


BACHBRUECKE = (1462.5, 728.1)   # Chaussee kreuzt den Bach (Schnittpunkt mit Vorgabe-Polylinie)
MUEHLE_POS = (1617.0, 1090.0)  # 17 m ostlich der Bachachse (Rinne +-12 m), TA-Vorschlag war (1600,5; 1088) = auf der Achse


# ---------------------------------------------------------------- Kleinstadt Lindenfurt: Markt-Ausschnitt
STADT_PARZ = {  # Front, Tiefe (m): 8-12 m Front (05 Abschnitt 3e), geschlossene Zeilen
    "buergerhaus": (12.4, 24.0),
    "handwerkerhaus": (10.0, 22.0),
    "rathaus": (18.0, 24.0),
    "gasthaus": (16.0, 26.0),
    "speicher": (22.0, 22.0),
}


MARKTSTRASSE_RA = 4.5       # WA-10 Baulinie Kleinstadt 0-3 m: Achsabstand der Parzellenkante (Strasse 6 m = Wegrand bei 3,0 m, Luecke 1,5 m); vorher 7,5 (Luecke 4,5 m)


def markt_rahmen():
    a = math.radians(31.0)
    d = (math.cos(a), math.sin(a))                    # Tor liegt bei Mitte + 175 d
    ex = (-d[0], -d[1])                               # Richtung Tor -> Markt
    ey = (-ex[1], ex[0])                              # rechts der Fahrtrichtung
    return ex, ey


def mw(Mc, ex, ey, u, v):
    return (Mc[0] + ex[0] * u + ey[0] * v, Mc[1] + ex[1] * u + ey[1] * v)


def stadtparzelle(szene, ol, par, typ, rng):
    """Haus in geschlossener Zeile: Fassade an der Strassenkante, Hinterhof mit Schuppen/Garten."""
    P, eu, ev = par["P"], par["eu"], par["ev"]
    W, T = par["b"], par["t"]
    fassade = (-ev[0], -ev[1])
    rot0 = rot_zu(*fassade)
    hb, ht, _ = HAUS[typ]
    jr = rng.uniform(-1.5, 1.5)
    x, z = P[0] + ev[0] * (0.4 + ht / 2.0) + eu[0] * rng.uniform(-0.15, 0.15), P[1] + ev[1] * (0.4 + ht / 2.0) + eu[1] * rng.uniform(-0.15, 0.15)
    szene.add(typ, x, z, rot0 + jr, par["id"], ol.id, b=hb, t=ht)
    # Hinterhof
    v0 = 0.4 + ht + 1.0
    if T - v0 > 4.0:
        xc, zc = P[0] + ev[0] * (v0 + (T - v0) / 2.0), P[1] + ev[1] * (v0 + (T - v0) / 2.0)
        szene.add("flaeche_hof" if rng.random() < 0.6 else "flaeche_garten", xc, zc, rot_zu(*fassade), par["id"], ol.id, b=W - 1.0, t=T - v0 - 0.5)
        if rng.random() < 0.45 and T - v0 > 7.0:
            sx, sz = P[0] + ev[0] * (T - 3.0) + eu[0] * rng.uniform(-W / 2 + 4, W / 2 - 4), P[1] + ev[1] * (T - 3.0) + eu[1] * rng.uniform(-W / 2 + 4, W / 2 - 4)
            szene.add("nebengebaeude", sx, sz, rot0 + rng.uniform(-3, 3), par["id"], ol.id, b=6.0, t=4.0, variante="schuppen_6x4")
        if rng.random() < 0.25:
            szene.add("obstbaum", P[0] + ev[0] * (T - 7.0) + eu[0] * rng.uniform(-3, 3), P[1] + ev[1] * (T - 7.0) + eu[1] * rng.uniform(-3, 3),
                      rng.uniform(-180, 180), par["id"], ol.id)
    par["typ"] = typ
    par["status"] = "besetzt"


def reihe_geschlossen(szene, ol, pw, seite, s0, s1, ra, wahl, rng, tiefe_max=None, aue_max=1.0, max_n=None):
    s = s0
    n = 0
    while s < s1 - 6.0:
        if max_n is not None and n >= max_n:
            break
        typ = wahl(s, rng)
        gesetzt = False
        for versuch in (typ, "handwerkerhaus"):
            W, T = STADT_PARZ[versuch]
            if s + W > s1 + 1.0:
                continue
            P, eu, ev, ecken = ol.rahmen(pw, seite, s, W, T, ra)
            ok, aue = ol.frei(ecken, pw.weg, aue_max=aue_max, front=ol.front_ecken(P, ev, eu, W, T), rand=-0.3)
            if ok:
                par = ol.eintragen(versuch, P, eu, ev, W, T, ecken, pw.weg, seite, s, stadt=True)
                stadtparzelle(szene, ol, par, versuch, PCG(PCG.hash_seed(WELT_SEED, ol.id, par["id"])))
                s += W + 0.3
                n += 1
                gesetzt = True
                break
        if not gesetzt:
            s += 3.0
    return n


def markt_bauen(geo, szene, wege, TOR):
    ex, ey = markt_rahmen()
    Mc = MARKT_MITTE
    rng = PCG(PCG.hash_seed(WELT_SEED, STADT["id"], "form"))
    # --- Wege: Marktstrasse Tor -> Markt (u -175 .. -40), Gasse hinter der Suedseite
    ms = [mw(Mc, ex, ey, u, 0.0) for u in (-200.0, -160.0, -120.0, -80.0, -40.0)]
    ms = glatt([(ms[0][0], ms[0][1])] + [(p[0] + ey[0] * dv, p[1] + ey[1] * dv) for p, dv in zip(ms[1:-1], (2.2, -1.8, 1.5))] + [ms[-1]], 5.0, 10)
    w_ms = Weg("marktstrasse", "dorfstrasse", ms, 6.0, "Marktstra\u00dfe")
    gp = [mw(Mc, ex, ey, u, v) for (u, v) in ((-130.0, 3.0), (-126.0, 28.0), (-112.0, 52.0), (-80.0, 66.0), (-34.0, 69.0), (10.0, 66.0), (42.0, 60.0))]
    w_g = Weg("gasse_lindenfurt", "gasse", glatt(gp, 4.0, 10), 5.0, "Hintergasse")
    # Markt-Raender (keine Strassen, Breite 0), nur fuer Zeilen
    def rand_weg(wid, u0, v0, u1, v1):
        return Weg(wid, "platz", resample([mw(Mc, ex, ey, u0, v0), mw(Mc, ex, ey, u1, v1)], 2.0), 0.0, wid)
    r_n = rand_weg("markt_n", -40, -30, 40, -30)     # Zeile nach Norden (links), seite -1
    r_s = rand_weg("markt_s", -40, 30, 40, 30)       # nach Sueden (rechts), seite +1
    r_f = rand_weg("markt_f", 40, -30, 40, 30)       # Westseite (u=+40), nach +ex = links, seite -1
    r_o1 = rand_weg("markt_o1", -40, -30, -40, -9)   # Ostseite nordlich der Strassenoeffnung, nach -ex = rechts, seite +1
    r_o2 = rand_weg("markt_o2", -40, 9, -40, 30)
    alle = list(wege.values()) + [w_ms, w_g]
    ol = Ortslage(szene, geo, STADT["id"], Mc, 130.0, alle, "form", WELT_SEED)
    pw = {w.id: Punktweg(w, 1.0) for w in (w_ms, w_g, r_n, r_s, r_f, r_o1, r_o2)}
    # Markt-Platz
    rot_x = math.degrees(math.atan2(-ex[1], ex[0]))
    szene.add("flaeche_marktplatz", Mc[0], Mc[1], rot_x, "markt_p00", STADT["id"], b=80.0, t=60.0)
    szene.add("brunnen", Mc[0] + ex[0] * 4.0, Mc[1] + ex[1] * 4.0, 0.0, "markt_p00", STADT["id"])
    ps = PCG(PCG.hash_seed(WELT_SEED, STADT["id"], "passanten"))
    for i in range(10):
        u, v = ps.uniform(-34, 34), ps.uniform(-24, 24)
        x, z = mw(Mc, ex, ey, u, v)
        szene.add("passant", x, z, ps.uniform(-180, 180), "markt_p00", STADT["id"])
    # Stadtkirche (35x15, Turm 45-55) an der Westseite des Marktes, Fassade zum Markt; Kirchplatz dahinter
    kc = mw(Mc, ex, ey, 40.0 + 1.0 + 7.5, 0.0)
    rot_k = rot_zu(-ex[0], -ex[1])
    kirche_ecken = obb_ecken(kc[0], kc[1], 35.0, 15.0, rot_k)
    ok, _ = gelaende_ok(geo, kirche_ecken)
    if not ok:
        raise RuntimeError("Stadtkirche steht nicht gueltig")
    pk = szene.pid(STADT["id"])
    szene.add("kirche_stadt", kc[0], kc[1], rot_k, pk, STADT["id"], b=35.0, t=15.0)
    kx, kz = mw(Mc, ex, ey, 40.0 + 1.0 + 15.0 + 7.0, 0.0)
    szene.add("flaeche_kirchhof", kx, kz, rot_k, pk, STADT["id"], b=44.0, t=14.0)
    ol.parz.append(Parzelle(id=pk, ort=STADT["id"], typ="kirche_stadt", status="besetzt", cx=r2(kc[0]), cz=r2(kc[1]), b=44.0, t=24.0,
                            rot_deg=r2(rot_k), weg=None, seite=0, s=0.0, P=(0, 0), eu=(0, 0), ev=(0, 0), sonder=True))
    ol.parz_ecken.append(obb_ecken(*mw(Mc, ex, ey, 40.0 + 12.0, 0.0), 44.0, 24.0, rot_k))
    # Rathaus Suedseite Mitte, Gasthaus Ostseite Nord, Speicher an der Marktstrasse nahe Tor
    def sonder(rp, seite, s_mitte, typ, ra=0.3):
        W, T = STADT_PARZ[typ]
        P, eu, ev, ecken = ol.rahmen(rp, seite, s_mitte - W / 2.0, W, T, ra)
        ok, aue = ol.frei(ecken, rp.weg, front=ol.front_ecken(P, ev, eu, W, T), aue_max=1.0, rand=-0.3)
        if ok:
            par = ol.eintragen(typ, P, eu, ev, W, T, ecken, rp.weg, seite, s_mitte - W / 2.0, stadt=True, sonder=True)
            stadtparzelle(szene, ol, par, typ, PCG(PCG.hash_seed(WELT_SEED, ol.id, par["id"])))
        return ok
    sonder(pw["markt_s"], 1, 38.0, "rathaus")
    sonder(pw["markt_o1"], 1, 12.0, "gasthaus")
    sonder(pw["marktstrasse"], -1, 28.0, "speicher", MARKTSTRASSE_RA)
    wahl = lambda s, r: "buergerhaus" if r.random() < 0.7 else "handwerkerhaus"
    reihe_geschlossen(szene, ol, pw["markt_n"], -1, 0.0, 80.0, 0.3, wahl, rng)
    reihe_geschlossen(szene, ol, pw["markt_s"], 1, 0.0, 80.0, 0.3, wahl, rng)
    reihe_geschlossen(szene, ol, pw["markt_f"], -1, 0.0, 60.0, 0.3, wahl, rng)
    reihe_geschlossen(szene, ol, pw["markt_o1"], 1, 0.0, 21.0, 0.3, wahl, rng)
    reihe_geschlossen(szene, ol, pw["markt_o2"], 1, 0.0, 21.0, 0.3, wahl, rng)
    pm = pw["marktstrasse"]
    reihe_geschlossen(szene, ol, pm, -1, 24.0, pm.L - 14.0, MARKTSTRASSE_RA, wahl, rng)
    reihe_geschlossen(szene, ol, pm, 1, 24.0, pm.L - 14.0, MARKTSTRASSE_RA, wahl, rng)
    pg = pw["gasse_lindenfurt"]
    reihe_geschlossen(szene, ol, pg, -1, 10.0, pg.L - 4.0, 3.0, wahl, rng)
    reihe_geschlossen(szene, ol, pg, 1, 40.0, pg.L - 4.0, 3.0, wahl, rng, max_n=4)
    # Tor und Mauer (Bogen um den Markt, Radius 175 m)
    rot_t = rot_zu(-ex[0], -ex[1])
    szene.add("stadttor", TOR[0], TOR[1], rot_t, "tor_p01", STADT["id"], b=8.0, t=8.0)
    mauer = mauer_bauen(geo, Mc, TOR)
    return ol, [w_ms, w_g], mauer


def mauer_bauen(geo, Mc, TOR):
    R = D_TOR
    a0 = math.atan2(TOR[1] - Mc[1], TOR[0] - Mc[0])
    stuecke = []
    for seite in (-1, 1):
        pts = []
        for k in range(0, 60):
            ph = math.radians(2.0 + 0.5 * k) * seite
            x, z = Mc[0] + R * math.cos(a0 + ph), Mc[1] + R * math.sin(a0 + ph)
            if geo.rinne_abstand(x, z) < 38 or geo.steigung(x, z) > 9.0 or geo.in_aue(x, z) and False:
                break
            pts.append((x, z))
        stuecke.append(pts)
    out = []
    # 70 % erhalten: auf der Nordseite eine Bresche von 14 m
    for k, pts in enumerate(stuecke):
        if len(pts) < 3:
            continue
        if k == 0 and len(pts) > 24:
            out.append([[r2(x), r2(z)] for x, z in pts[:14]])
            out.append([[r2(x), r2(z)] for x, z in pts[20:]])
        else:
            out.append([[r2(x), r2(z)] for x, z in pts])
    return out


# ---------------------------------------------------------------- Dorf: Luecken bestimmen und Haeuser bauen
def dorf_besetzen(geo, szene, ol, anzahl_luecken=7):
    """Waehlt Luecken (10-20 % der Parzellen: 5 Kate-Parzellen + 2 Hofstellen), Rest wird besetzt."""
    rng = PCG(PCG.hash_seed(WELT_SEED, ol.id, "luecken"))
    wohn = [p for p in ol.parz if not p.get("sonder")]
    kand = [p for p in wohn if 35.0 <= ol.d_kern((p["cx"], p["cz"])) <= 150.0]
    kates = [p for p in kand if p["typ"] == "kate"]
    hoefe = [p for p in kand if p["typ"] == "bauernhof"]
    rng.shuffle(kates)
    rng.shuffle(hoefe)
    luecken = []
    # raeumlich verteilt: je gewaehlter Luecke 45 m Mindestabstand zu den anderen
    def zu_nah(p):
        return any(math.hypot(p["cx"] - q["cx"], p["cz"] - q["cz"]) < 45.0 for q in luecken)
    for kandidaten, n in ((kates, 5), (hoefe, 2)):
        c = 0
        for p in kandidaten:
            if c >= n:
                break
            if not zu_nah(p):
                luecken.append(p)
                c += 1
    for p in wohn:
        if p in luecken:
            p["status"] = "luecke"
            # Obstwiese + Zaun-Andeutung auf der leeren Parzelle
            szene.add("flaeche_obstwiese", p["cx"], p["cz"], p["rot_deg"], p["id"], ol.id, b=p["b"] - 1.0, t=p["t"] - 1.0)
            r_ = PCG(PCG.hash_seed(WELT_SEED, ol.id, p["id"], "luecke"))
            for i in range(2 if p["typ"] == "kate" else 3):
                dx, dz = r_.uniform(-p["b"] / 2 + 3, p["b"] / 2 - 3), r_.uniform(-p["t"] / 2 + 3, p["t"] / 2 - 3)
                eu, ev = p["eu"], p["ev"]
                szene.add("obstbaum", p["cx"] + eu[0] * dx + ev[0] * dz, p["cz"] + eu[1] * dx + ev[1] * dz, r_.uniform(-180, 180), p["id"], ol.id)
        else:
            ol.besetzen(p)
    return luecken


# WA-11 (PL-3): Allee nach UX-Regel 5 - Takt 12 +- 3 m, 10-15 % Luecken, Arten gewichtet zufaellig (kein Wechsel), Groesse +-15 %,
# Versatz +-1,5 m, abschnittsweise einseitig. Alles aus dem Zufallsstrom "allee" (Seed 7) -> deterministisch.
ALLEE_TAKT = (9.0, 15.0)
ALLEE_LUECKE = 0.125                       # Ziel-Anteil fehlender Baeume (Regelung ueber Fehlbestand, bleibt im Band 10-15 %)
ALLEE_ARTEN = (("laubbaum", 0.58), ("eiche", 0.42))
ALLEE_SKALA = (0.85, 1.15)
ALLEE_VERSATZ = 1.5


def allee_bauen(geo, szene, chaussee, bruecken, ausschluss, andere_wege=()):
    """Chaussee-Allee, 7,0 m von der Achse. Nicht auf der Bruecke, nicht im Ort (ausschluss = Liste (x, z, r)), nicht an Wasser/Hang.
    Jede Seite laeuft mit eigenem, unregelmaessigem Takt; einseitige Abschnitte und Luecken brechen die Spiegelung."""
    pts = resample(chaussee, 1.0)
    rng = PCG(PCG.hash_seed(WELT_SEED, "allee"))
    L = poly_laenge(pts)

    def frei(p):
        for (bx0, bz0, bx1, bz1) in bruecken:
            if bx0 - 18 <= p[0] <= bx1 + 18 and bz0 - 18 <= p[1] <= bz1 + 18:
                return False
        for (ax, az, ar) in ausschluss:
            if math.hypot(p[0] - ax, p[1] - az) < ar:
                return False
        return True

    # Abschnitte (wie bisher auf dem 12-m-Raster, damit proto_wege.json["allee"] unveraendert bleibt)
    abschnitte = []
    aktiv = None
    s = 6.0
    while s < L - 6.0:
        p = pts[min(int(s), len(pts) - 2)]
        if frei(p):
            if aktiv is None:
                aktiv = s
        elif aktiv is not None:
            abschnitte.append((aktiv, s))
            aktiv = None
        s += 12.0
    if aktiv is not None:
        abschnitte.append((aktiv, L))
    # einseitige Strecken: ca. 70-130 m lang, alle 250-500 m, Seite zufaellig
    einseitig = []
    c = rng.uniform(80.0, 220.0)
    while c < L:
        ln = rng.uniform(70.0, 130.0)
        einseitig.append((c, c + ln, 1 if rng.random() < 0.5 else -1))
        c += ln + rng.uniform(180.0, 360.0)
    arten = [a for a, w in ALLEE_ARTEN]
    gew = [w for a, w in ALLEE_ARTEN]
    n = 0
    positionen = 0
    fehlend = 0
    for sd in (-1, 1):
        s = 6.0 + rng.uniform(0.0, 6.0)
        while s < L - 6.0:
            i = min(int(s), len(pts) - 2)
            p, q = pts[i], pts[i + 1]
            dx, dz = q[0] - p[0], q[1] - p[1]
            d = math.hypot(dx, dz) or 1.0
            nx, nz = -dz / d, dx / d
            schritt = rng.uniform(*ALLEE_TAKT)
            if not frei(p) or any(a0 <= s <= a1 and sd_ == sd for (a0, a1, sd_) in einseitig):
                s += schritt
                continue
            positionen += 1
            luecke = rng.random() < min(0.35, max(0.0, ALLEE_LUECKE + (ALLEE_LUECKE * positionen - fehlend) * 0.04))
            versatz = rng.uniform(-ALLEE_VERSATZ, ALLEE_VERSATZ)
            x, z = p[0] + nx * (7.0 + versatz) * sd, p[1] + nz * (7.0 + versatz) * sd
            typ = rng.weighted(list(zip(arten, gew)))
            skala = rng.uniform(*ALLEE_SKALA)
            drehung = rng.uniform(-180, 180)
            if luecke:
                fehlend += 1
                s += schritt
                continue
            if geo.rinne_abstand(x, z) < 8 or geo.see_abstand(x, z) < 12 or geo.bach_abstand(x, z) < 6 or geo.steigung(x, z) > 12:
                s += schritt
                continue
            if any(poly_abstand((x, z), w.punkte)[0] < w.breite / 2.0 + 3.0 for w in andere_wege):
                s += schritt
                continue
            if any(math.hypot(x - f[0][0][0], z - f[0][0][1]) < 60.0 and (punkt_in_obb((x, z), f[0]) or poly_abstand((x, z), list(f[0]) + [f[0][0]])[0] < 3.0) for f in szene.foot):
                s += schritt
                continue
            szene.add(typ, x, z, drehung, "allee", "chaussee", rolle="allee", skala=r2(skala))
            n += 1
            s += schritt
    return n, abschnitte


def dorf_belebung(geo, szene, ol):
    """Brunnen an der Kreuzung, Passanten, Etter-Obstbaeume am Ortsrand."""
    rng = PCG(PCG.hash_seed(WELT_SEED, ol.id, "belebung"))
    szene.add("brunnen", K[0] + 5.5, K[1] + 4.5, 0.0, "erlenbach_p00", ol.id)
    for i in range(6):
        a = rng.uniform(0, 2 * math.pi)
        d = rng.uniform(6, 40)
        szene.add("passant", K[0] + d * math.cos(a), K[1] + d * math.sin(a), rng.uniform(-180, 180), "erlenbach_p00", ol.id)
    # Etter: Obstbaeume 20-50 m ausserhalb der Parzellen
    eck = [obb_ecken(p["cx"], p["cz"], p["b"], p["t"], p["rot_deg"]) for p in ol.parz]
    cx = sum(p["cx"] for p in ol.parz) / len(ol.parz)
    cz = sum(p["cz"] for p in ol.parz) / len(ol.parz)
    n = 0
    versuche = 0
    while n < 26 and versuche < 600:
        versuche += 1
        a = rng.uniform(0, 2 * math.pi)
        d = rng.uniform(120, 230)
        x, z = cx + d * math.cos(a), cz + d * math.sin(a)
        dmin = min(math.hypot(x - p["cx"], z - p["cz"]) for p in ol.parz)
        if dmin < 20 or dmin > 55:
            continue
        if geo.rinne_abstand(x, z) < 40 or geo.see_abstand(x, z) < 40 or geo.bach_abstand(x, z) < 18 or geo.steigung(x, z) > 6:
            continue
        if any(poly_abstand((x, z), w["punkte"])[0] < 6 for w in szene.wege):
            continue
        szene.add("obstbaum", x, z, rng.uniform(-180, 180), "erlenbach_etter", ol.id)
        n += 1


# ---------------------------------------------------------------- Zusammenbau
def bauen(src=SRC_DEFAULT):
    geo = Gelaende(src)
    szene = Szene()
    # --- Wege
    chaussee_roh, TOR = wege_bauen(geo)
    wo = {}
    wegdicts = {}
    for k, v in chaussee_roh.items():
        wo[k] = Weg(k, v["typ"], v["punkte"], v["breite_m"], v["name"])
    for k, (typ, br, name, pts) in dorfwege(geo).items():
        wo[k] = Weg(k, typ, pts, br, name)
    rng_f = PCG(PCG.hash_seed(WELT_SEED, "feldwege"))
    # Feldwege
    wo["muehlweg"] = Weg("muehlweg", "feldweg", feldweg_route(geo, (1620.0, 856.0), (MUEHLE_POS[0] - 2.0, MUEHLE_POS[1] - 16.0), rng_f), 3.5, "M\u00fchlweg")
    wo["gutsweg"] = Weg("gutsweg", "feldweg", feldweg_route(geo, wo["muehlweg"].punkte[-1], (GUT_POS[0] - 30.0, GUT_POS[1] - 24.0), rng_f, max_steig=0.085, amp=5.0, tol=22.0), 3.5, "Gutsweg")
    ch_pts = chaussee_roh["chaussee"]["punkte"]
    abz = ch_pts[min(range(len(ch_pts)), key=lambda i: abs(ch_pts[i][0] - 1362) + abs(ch_pts[i][1] - 706))]
    wo["hasenwinkelweg"] = Weg("hasenwinkelweg", "feldweg", feldweg_route(geo, abz, WEILER_POS, rng_f, amp=9.0, tol=30.0), 3.5, "Hasenwinkelweg")
    wo["ostweg"] = Weg("ostweg", "feldweg", feldweg_route(geo, wo["hauptstrasse"].punkte[-1], (2005.0, 545.0), rng_f, amp=8.0), 3.5, "Ostweg")
    # --- Dorf Erlenbach
    ol_d, q, pwd = dorf_bauen(geo, szene, wo)
    luecken = dorf_besetzen(geo, szene, ol_d)
    dorf_belebung(geo, szene, ol_d)
    # --- Weiler
    ol_w, w_weiler = weiler_bauen(geo, szene, wo, rng_f)
    for w in w_weiler:
        wo[w.id] = w
    for p in ol_w.parz:
        ol_w.besetzen(p)
    # --- Gutshof, Muehle, See-Nutzung
    gp = wo["gutsweg"].punkte[-1]
    gp0 = wo["gutsweg"].punkte[-6]
    n_schlag = gut_bauen(geo, szene, (gp0[0] - GUT_POS[0], gp0[1] - GUT_POS[1]) if False else (-(gp[0] - gp0[0]) * -1.0, -(gp[1] - gp0[1]) * -1.0) if False else (gp0[0] - GUT_POS[0], gp0[1] - GUT_POS[1]))
    muehle_bauen(geo, szene)
    see = see_bauen(geo, szene, rng_f)
    hut = see["pfad_start"]
    a_ch = ch_pts[min(range(len(ch_pts)), key=lambda i: abs(ch_pts[i][0] - 1418) + abs(ch_pts[i][1] - 716))]
    uh = (math.cos(math.radians(FISCHER_WINKEL_DEG)), math.sin(math.radians(FISCHER_WINKEL_DEG)))
    fp = glatt([(hut[0] + uh[0] * 10.0, hut[1] + uh[1] * 10.0), (hut[0] + 6.0, hut[1] - 42.0), (hut[0] + 14.0, hut[1] - 78.0), (a_ch[0] + 3.0, a_ch[1] + 4.0)], 5.0, 10)
    wo["fischerpfad"] = Weg("fischerpfad", "feldweg", fp, 3.5, "Fischerpfad")
    # --- Markt-Ausschnitt
    ol_m, w_markt, mauer = markt_bauen(geo, szene, wo, TOR)
    for w in w_markt:
        wo[w.id] = w
    # Etter-Obstbaeume nachtraeglich von allen Wegen freihalten (Fischerpfad/Markt entstehen erst spaeter)
    szene.inst[:] = [d for d in szene.inst if not (d["parzelle"] == "erlenbach_etter" and
                     any(poly_abstand((d["x"], d["z"]), w.punkte)[0] < w.breite / 2.0 + 2.0 for w in wo.values()))]
    # Allee: Chaussee ausserhalb Dorf (150 m um K), Bruecken, Tor
    br_boxen = [(BRUECKE_S[0], BRUECKE_N[1], BRUECKE_S[0], BRUECKE_S[1]), (BACHBRUECKE[0], BACHBRUECKE[1], BACHBRUECKE[0], BACHBRUECKE[1])]
    anderes = [w for k, w in wo.items() if k != "chaussee"]
    n_allee, allee_abs = allee_bauen(geo, szene, wo["chaussee"].punkte, br_boxen, [(K[0], K[1], 150.0), (TOR[0], TOR[1], 30.0)], anderes)
    n_bezug = bezug_ausrichten(szene, wo)     # WA-10 Bezugslinie, rein geometrisch
    farm2 = farm2_bauen(geo, szene, wo)       # WA-07, bewusst zuletzt: bestehende Instanzen/Wege/Zufallsstroeme bleiben bitgleich
    ladeplaetze = ladeplaetze_bauen(geo, szene, wo, ol_d, ol_w, ol_m)     # WA-08, rein geometrisch (kein Zufallsstrom)
    return geo, szene, wo, TOR, chaussee_roh, dict(farm2=farm2, allee=(n_allee, allee_abs), dorf=ol_d, weiler=ol_w, markt=ol_m, see=see, luecken=luecken, mauer=mauer, n_schlag=n_schlag,
                                                   ladeplaetze=ladeplaetze)


def steigung_entschaerfen(geo, punkte, ziel_pct, rng, schritt=5.0, iterationen=3000):
    """WA-10: lokale Umlegung eines Wegabschnitts, dessen Steigung (5-m-Raster) ueber ziel_pct liegt. Kontrollpunkte alle 6 Abtastpunkte,
    Zufallssuche (eigener Strom) minimiert max. Steigung + Knickwinkel + Laenge. Liefert die Punkte unveraendert, wenn nichts zu tun ist."""
    def prof(q):
        r = resample(q, schritt)
        return [abs(geo.hoehe(*r[k + 1]) - geo.hoehe(*r[k])) / math.hypot(r[k + 1][0] - r[k][0], r[k + 1][1] - r[k][1]) * 100.0 for k in range(len(r) - 1)]
    r = resample(punkte, schritt)
    s = prof(punkte)
    bad = [k for k, v in enumerate(s) if v > ziel_pct]
    if not bad:
        return punkte
    i0, i1 = max(0, bad[0] - 16), min(len(r) - 1, bad[-1] + 16)
    ctrl = [r[i0]] + [r[i] for i in range(i0 + 6, i1 - 5, 6)] + [r[i1]]

    def zielwert(c):
        q = glatt(c, schritt, 8)
        rr = resample(q, schritt)
        knick = 0.0
        for k in range(1, len(rr) - 1):
            a1 = math.atan2(rr[k][1] - rr[k - 1][1], rr[k][0] - rr[k - 1][0])
            a2 = math.atan2(rr[k + 1][1] - rr[k][1], rr[k + 1][0] - rr[k][0])
            knick = max(knick, abs((math.degrees(a2 - a1) + 180.0) % 360.0 - 180.0))
        m = max(prof(q))
        return m + max(0.0, knick - KNICK_MAX) * 0.5 + 0.0005 * poly_laenge(q), m
    best = zielwert(ctrl)
    for _ in range(iterationen):
        k = 1 + int(rng.random() * (len(ctrl) - 2))
        c = list(ctrl)
        c[k] = (c[k][0] + rng.uniform(-6.0, 6.0), c[k][1] + rng.uniform(-6.0, 6.0))
        o = zielwert(c)
        if o[0] < best[0]:
            ctrl, best = c, o
    neu = glatt(ctrl, schritt, 8)
    return [tuple(map(float, q)) for q in r[:i0]] + [tuple(map(float, q)) for q in neu] + [tuple(map(float, q)) for q in r[i1 + 1:]]


BEZUG_AUSLOESER_GRAD = 8.0     # WA-10: Haupthaus mit mehr als so viel Abweichung zur naechsten Wegtangente wird nachgedreht
BEZUG_KORR_MAX_GRAD = 6.0      # ... um hoechstens so viel (Gebaeude bleibt in seiner Parzelle)


def _winkel_abw(rot_deg, p, q):
    r = math.radians(rot_deg)
    ab = math.degrees(math.atan2(-math.sin(r), math.cos(r)))
    ar = math.degrees(math.atan2(q[1] - p[1], q[0] - p[0]))
    d = (ab - ar) % 90.0
    return min(d, 90.0 - d)


def bezug_ausrichten(szene, wo):
    """WA-10 Bezugslinie (Traufe/Giebel +-10 Grad zur naechsten Wegtangente): an gekruemmten Wegen (Gasse Kirch) weicht die Parzellenachse von der Tangente
    am naechsten Wegpunkt ab. Haupthaeuser darueber werden um die Abweichung (max. BEZUG_KORR_MAX_GRAD) nachgedreht, sofern der gedrehte Footprint
    kein anderes Gebaeude beruehrt. Rein geometrisch, kein Zufallsstrom."""
    haupt = set(HAUS) - {"nebengebaeude", "stadttor"}
    n = 0
    for d in szene.inst:
        if d["typ"] not in haupt or "b" not in d or d["ort"] not in ("erlenbach", "hasenwinkel", "lindenfurt"):
            continue
        best = None
        for w in wo.values():
            dist, k, _ = poly_abstand((d["x"], d["z"]), w.punkte)
            if best is None or dist < best[0]:
                best = (dist, w, k)
        _, w, k = best
        abw = _winkel_abw(d["rot_deg"], w.punkte[k], w.punkte[k + 1])
        if abw <= BEZUG_AUSLOESER_GRAD:
            continue
        c = min(abw, BEZUG_KORR_MAX_GRAD)
        for rot_neu in sorted((d["rot_deg"] + c, d["rot_deg"] - c), key=lambda r: _winkel_abw(r, w.punkte[k], w.punkte[k + 1])):
            if _winkel_abw(rot_neu, w.punkte[k], w.punkte[k + 1]) >= abw:
                continue
            e_neu = obb_ecken(d["x"], d["z"], d["b"], d["t"], rot_neu)
            e_alt = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
            andere = [f for f in szene.foot if not (f[1] == d["typ"] and f[2] == d["parzelle"] and abs(sum(q[0] for q in f[0]) / 4.0 - d["x"]) < 0.01)]
            if any(obb_ueberlappt(e_neu, f[0]) for f in andere):
                continue
            for i, f in enumerate(szene.foot):
                if f[1] == d["typ"] and f[2] == d["parzelle"] and abs(sum(q[0] for q in f[0]) / 4.0 - d["x"]) < 0.01:
                    szene.foot[i] = (e_neu, f[1], f[2], f[3])
            d["rot_deg"] = r2(((rot_neu + 180.0) % 360.0) - 180.0)
            n += 1
            break
    return n


# ---------------------------------------------------------------- WA-08 Ladeplaetze
LADEGUETER = {
    "gut_kuppenhof": [dict(gut="getreide", rolle="heuhaufen", bezug="Station-Lagerbestand getreide / Ausgangspuffer")],
    "hof_hasenwinkel": [dict(gut="getreide", rolle="heuhaufen", bezug="Station-Lagerbestand getreide / Ausgangspuffer")],
    "erlenmuehle": [dict(gut="getreide", rolle="heuhaufen", bezug="Eingangspuffer getreide / Puffergroesse"),
                    dict(gut="mehl", rolle="heuhaufen", bezug="Ausgangsbestand mehl / Puffergroesse")],
    "erlenbach": [dict(gut="mehl", rolle="heuhaufen", bezug="zuletzt abgeladene Menge mehl / Nachfrage je Periode")],
    "lindenfurt": [dict(gut="mehl", rolle="heuhaufen", bezug="zuletzt abgeladene Menge mehl / Nachfrage je Periode")],
}
KNICK_MAX = 12.0
GUTSWEG_ZIEL_STEIG = 9.0     # WA-10: Steigung (5-m-Raster) im Gutsweg hoechstens so hoch (vorher 10,1 %, Wert im 10-m-Raster schwankte 9,99 .. 10,17 je nach Abtastphase)
GUTSWEG_TORABSTAND = 7.0     # WA-10: Wegende des Gutswegs endet so weit vor dem Hofrand (Zufahrt <= 12 m)


def _hof_ecken(szene, ort):
    d = [d for d in szene.inst if d["typ"] in ("gutshof", "wassermuehle") and d["ort"] == ort][0]
    return d, obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])


def ladeplaetze_bauen(geo, szene, wo, ol_d, ol_w, ol_m):
    """Ladeplatz je Betrieb und je Sim-Ort; Gutsweg bis ans Hoftor verlaengert (WA-10 Zufahrt). Liefert dict id -> Ergebnis."""
    import json as _json
    import stadt_out as so
    rw = _json.load(open(os.path.join(ROOT, "slice", "world", "data", "proto", "regelwerk.json"), encoding="utf-8"))
    parz_ecken = list(ol_d.parz_ecken) + list(ol_w.parz_ecken) + list(ol_m.parz_ecken)
    # --- Gutsweg bis ans Hoftor (WA-10): die letzten ~45 m laufen in Achse der Hoffassade (lokales +z) auf das Tor zu, Wegende 7 m vor dem Hofrand
    gd, ge = _hof_ecken(szene, GUT["id"])
    gw = wo["gutsweg"]
    r_ = math.radians(gd["rot_deg"])
    ez = (math.sin(r_), math.cos(r_))                    # Fassade zeigt zur Zufahrt
    a_ = (-ez[0], -ez[1])                                # Fahrtrichtung am Tor
    G = (gd["x"] + ez[0] * (20.0 + GUTSWEG_TORABSTAND), gd["z"] + ez[1] * (20.0 + GUTSWEG_TORABSTAND))
    gw.punkte = steigung_entschaerfen(geo, gw.punkte, GUTSWEG_ZIEL_STEIG, PCG(PCG.hash_seed(WELT_SEED, "gutsweg", "steigung")))
    keep = list(gw.punkte)
    L_ab = 0.0
    while len(keep) > 3 and L_ab < 45.0:
        L_ab += math.hypot(keep[-1][0] - keep[-2][0], keep[-1][1] - keep[-2][1])
        keep.pop()
    tail = glatt(keep[-3:] + [(G[0] - a_[0] * 14.0, G[1] - a_[1] * 14.0), G], 5.0, 8)
    gw.punkte = keep[:-3] + [tuple(map(float, q)) for q in tail]
    pl = lp.Planer(geo, szene, wo, rw, parz_ecken)
    erg = {}
    # --- Betriebe an vorhandenen Wegenden
    for oid, wid in ((GUT["id"], "gutsweg"), (GUT2["id"], "hofweg_hasenwinkel")):
        w = wo[wid]
        erg[oid] = (pl.vorhandenes_ende(wid, w.punkte[-1], lp._ende_richtung(w.punkte)), wid)
    # --- Muehle: Ladestich (vorhandene Wege enden nicht an der Muehle)
    md, me = _hof_ecken(szene, MUEHLE["id"])
    # Der Ladestich (Sackgasse im 90-Grad-Abzweig) liess proto_easing_test Teil B rot (E3/E5, siehe WA-08.md). Die Muehle bekommt deshalb einen Durchgangs-Ladeplatz
    # am Knoten Muehlweg/Gutsweg (Halt wie bisher im Knoten, Gespann steht mit der Mitte dort).
    kn = wo["muehlweg"].punkte[-1]
    r_mw = lp._ende_richtung(wo["muehlweg"].punkte)
    r_gw = lp._ende_richtung(list(reversed(wo["gutsweg"].punkte)))
    erg[MUEHLE["id"]] = (pl.durchgang(kn, [r_gw, r_mw], ("muehlweg", "gutsweg"), me, max_dist=60.0), "gutsweg")
    # --- Orte
    ctr = lambda ol: (sum(p["cx"] for p in ol.parz) / len(ol.parz), sum(p["cz"] for p in ol.parz) / len(ol.parz))
    w = wo["marktstrasse"]
    erg["lindenfurt"] = (pl.vorhandenes_ende("marktstrasse", w.punkte[-1], lp._ende_richtung(w.punkte)), "marktstrasse")
    if erg["lindenfurt"][0] is None:
        erg["lindenfurt"] = (pl.plane(MARKT_MITTE, max_dist=120.0), None)
    erg["erlenbach"] = (pl.plane(ctr(ol_d), max_dist=150.0, stamm_ok=[k for k in wo if k not in ("chaussee",)] + ["chaussee"]), None)
    namen = {GUT["id"]: GUT["name"], GUT2["id"]: GUT2["name"], MUEHLE["id"]: MUEHLE["name"], "lindenfurt": STADT["name"], "erlenbach": DORF["name"]}
    out = {}
    for oid in ("gut_kuppenhof", "hof_hasenwinkel", "erlenmuehle", "erlenbach", "lindenfurt"):
        e, wid = erg[oid]
        if e is None:
            raise RuntimeError("Ladeplatz: kein Platz fuer %s" % oid)
        if wid is None and e.get("wid"):
            wid = e["wid"]
        if e["stich"] is not None:
            A, E = e["stich"]
            stamm = wo[e["stamm"]]
            mitte = ((A[0] + E[0]) / 2.0, (A[1] + E[1]) / 2.0)
            wid = "ladestich_" + oid
            wo[wid] = Weg(wid, "feldweg", [A, mitte, E], lp.STICH_BREITE, "Ladestich " + namen[oid])
            if wid not in so.WEG_REIHENFOLGE:
                so.WEG_REIHENFOLGE.append(wid)
        kies = lp._ecken(e["f"]["kies"])
        band = lp._aufblasen(lp.obb_ecken(*e["f"]["P"], 4.0, 4.0, 0.0), 0.0)
        # Baeume im Ladeplatz weg
        n0 = len(szene.inst)
        szene.inst[:] = [d for d in szene.inst if not (d["typ"] in lp.ENTFERNBAR and "b" not in d and punkt_in_obb((d["x"], d["z"]), lp._aufblasen(kies, 1.5)))]
        boden = "pflaster" if oid == "lindenfurt" else "kies"
        dct = lp.ladeplatz_dict(e, pl, None, LADEGUETER[oid], namen[oid], boden, wid)
        dct["baeume_entfernt_n"] = n0 - len(szene.inst)
        out[oid] = dct
    return out


# ---------------------------------------------------------------- Wachstum (A10)
def wachstum_rechnen(geo, szene, wo, ol_d, monate=12):
    from stadt_wachstum import kopie, simuliere
    from stadt_out import vorstadt_funktion
    pw = {"hauptstrasse": Punktweg(wo["hauptstrasse"]), "dorfstrasse_sued": Punktweg(wo["dorfstrasse_sued"]),
          "dorfstrasse_nord": Punktweg(wo["dorfstrasse_nord"]),
          "chaussee_dorf": Punktweg(Weg("chaussee", "chaussee", alle_ch_dorf(wo["chaussee"].punkte), 6.0))}
    vp = vorstadt_funktion(pw, ["hauptstrasse", "dorfstrasse_sued", "chaussee_dorf", "dorfstrasse_nord"], (1672.0, 712.0))
    res = {}
    for name, mit in (("ohne_versorgung", False), ("mit_versorgung", True)):
        ol2, s2 = kopie(ol_d, szene)
        r = simuliere(ol2, s2, mit, monate, vp, WELT_SEED)
        res[name] = (ol2, s2, r)
    return res


def vorher_nachher(szene, ol_d, wach):
    from stadt_out import instanz_export, ort_ew, ort_zaehlung
    o0 = [d for d in szene.inst if d["ort"] == ol_d.id]
    dat = {"_zweck": "Wachstum Erlenbach Monat 0 -> Monat 12 nach Stadt-KI (12_regelwerk_v1_1 wachstum): Luecke, Upgrade, Teilung, Vorstadt, "
                     "Gasse, Platz; verdichten vor ausdehnen. Monat 0 = Instanzen aus proto_instanzen.json (ort erlenbach).",
           "ort": ol_d.id, "welt_seed": WELT_SEED,
           "annahmen": {"sim_ew_start": 650, "umland_ew": 650 - ort_ew(szene, ol_d.id), "rate_pro_monat": 0.018,
                        "rate_quelle": "Annahme 180 bp/Monat bei Versorgung >= 80 % (economy wachstum.band nicht gelesen, Konstante RATE_BP)",
                        "ew_je_aktion": 8, "max_aktionen_je_monat": "1 + ort_ew_soll // 500", "haus_ruhe_monate": 3,
                        "gewicht_haltestelle": "entfaellt (keine Spielerhaltestelle im Prototyp)"},
           "monat0": {"ew": ort_ew(szene, ol_d.id), "gebaeude": ort_zaehlung(szene, ol_d.id),
                      "luecken": [p["id"] for p in ol_d.parz if p["status"] == "luecke"], "instanzen_n": len(o0)}}
    for name in ("ohne_versorgung", "mit_versorgung"):
        ol2, s2, r = wach[name]
        neu0 = {p["id"]: p for p in ol_d.parz}
        geaendert = []
        for a in r["aktionen"]:
            if a["parzelle"] not in geaendert:
                geaendert.append(a["parzelle"])
        entf = [instanz_export(d) for d in o0 if d["parzelle"] in geaendert]
        neu = [instanz_export(d) for d in s2.inst if d["ort"] == ol_d.id and d["parzelle"] in geaendert]
        dat["monat12_" + name] = {
            "ew": ort_ew(s2, ol_d.id), "gebaeude": ort_zaehlung(s2, ol_d.id), "aktionen_n": len(r["aktionen"]),
            "aktionen": [{k: (r2(v) if isinstance(v, float) else v) for k, v in a.items()} for a in r["aktionen"]],
            "verlauf": r["verlauf"], "ersetze_parzellen": geaendert, "entfernte_instanzen": entf, "neue_instanzen": neu,
            "neue_parzellen": [{"id": p["id"], "typ": p["typ"], "x": p["cx"], "z": p["cz"], "rot_deg": p["rot_deg"]} for p in ol2.parz if p["id"] not in neu0],
            "luecken_offen": [p["id"] for p in ol2.parz if p["status"] == "luecke"]}
    return dat


# ---------------------------------------------------------------- Gesamtausgabe
def erzeuge(out_dir=OUT_DIR, bilder=True, src=SRC_DEFAULT, still=False):
    import stadt_out as so
    geo, szene, wo, TOR, cr, ex = bauen(src)
    ol_d, ol_w, ol_m = ex["dorf"], ex["weiler"], ex["markt"]
    ch = wo["chaussee"].punkte
    knoten = so.kreuzungen_finden(wo, K)
    bruecken = so.bruecken_daten(geo, ch, BACHBRUECKE)
    n_allee, allee_s = ex["allee"]
    allee = so.allee_abschnitte(ch, allee_s)
    wege = so.wege_export(geo, wo, knoten, bruecken, allee, ch)
    wach = wachstum_rechnen(geo, szene, wo, ol_d)
    vn = vorher_nachher(szene, ol_d, wach)
    # --- Orte
    def zentrum(ol):
        return (sum(p["cx"] for p in ol.parz) / len(ol.parz), sum(p["cz"] for p in ol.parz) / len(ol.parz))
    orte = []
    cd = zentrum(ol_d)
    ctr_ecken = [c for p in ol_d.parz for c in obb_ecken(p["cx"], p["cz"], p["b"], p["t"], p["rot_deg"])]
    cw = zentrum(ol_w)
    wohn = ("kate", "bauernhof", "grosshof", "handwerkerhaus", "buergerhaus")
    for ol, d, mitte, r_m, extra in (
            (ol_d, DORF, cd, so.runde5(so.kreis_p90([(p["cx"], p["cz"]) for p in ol_d.parz], cd)),
             {"kreuzung": [r2(K[0]), r2(K[1])], "r_max_m": so.runde5(so.kreis_um(ctr_ecken, cd, 3.0))}),
            (ol_w, WEILER, cw, so.runde5(so.kreis_p90([(p["cx"], p["cz"]) for p in ol_w.parz], cw)),
             {"r_max_m": so.runde5(so.kreis_um([c for p in ol_w.parz for c in obb_ecken(p["cx"], p["cz"], p["b"], p["t"], p["rot_deg"])], cw, 3.0))}),
            (ol_m, STADT, MARKT_MITTE, D_TOR, {"tor": [r2(TOR[0]), r2(TOR[1])]})):
        z = so.ort_zaehlung(szene, d["id"])
        o = {"id": d["id"], "name": d["name"], "klasse": d["klasse"], "ew": so.ort_ew(szene, d["id"]), "x": r2(mitte[0]), "z": r2(mitte[1]),
             "r_m": r_m, "form": d["form"], "gebaeude": z, "wohnhaeuser_n": sum(v for k, v in z.items() if k in wohn),
             "gebaeude_n": sum(z.values()), "parzellen_n": len(ol.parz), "luecken_n": sum(1 for p in ol.parz if p["status"] == "luecke")}
        o.update(extra)
        o.update(SIM_EW.get(d["id"], {}))
        if d["id"] in ex["ladeplaetze"]:
            o["ladeplatz"] = ex["ladeplaetze"][d["id"]]
        if d["id"] == "erlenbach":
            o["ew_ort"] = o["ew"]
            o["ew_umland"] = SIM_EW["erlenbach"]["sim_ew"] - o["ew"]
        if d["id"] == "hasenwinkel":
            o["ew_ort"] = o["ew"]
        if d["id"] == "lindenfurt":
            o["hinweis"] = ("Ausschnitt: Markt (60x80 m Platz), Stadtkirche, 1 Tor, 1 Gasse, Mauerbogen R 200 m (70 % erhalten); die Stadt setzt sich "
                            "ausserhalb des Kerns nach Westen fort. ew = Summe der Gebaeude im Ausschnitt (387, unveraendert, damit Schilder/Tooltip stabil "
                            "bleiben); ew_ort = 2000 ist der Ort gesamt im Klassenband Kleinstadt (2.000-4.000), ew_umland 400 (Band 400-700), "
                            "sim_ew = ew_ort + ew_umland = 2400 (WA-07).")
        orte.append(o)
    def abst(a, b):
        return r2(math.hypot(a[0] - b[0], a[1] - b[1]))
    od = {o["id"]: (o["x"], o["z"]) for o in orte}
    gutp = [d for d in szene.inst if d["typ"] == "gutshof" and d["ort"] == GUT["id"]][0]
    mu = [d for d in szene.inst if d["typ"] == "wassermuehle"][0]
    schlaege = [{"x": d["x"], "z": d["z"], "b": d["b"], "t": d["t"]} for d in szene.inst if d["typ"] == "flaeche_schlag" and d["ort"] == GUT["id"]]
    f2p = [d for d in szene.inst if d["typ"] == "gutshof" and d["ort"] == GUT2["id"]][0]
    f2_schlaege = ex["farm2"]["schlaege"]
    LP = ex["ladeplaetze"]
    industrie = [
        {"id": GUT["id"], "name": GUT["name"], "typ": "getreidefarm", "x": gutp["x"], "z": gutp["z"], "rot_deg": gutp["rot_deg"],
         "hofform": "vierseithof_40x40", "schlaege": schlaege, "abstand_dorf_m": abst((gutp["x"], gutp["z"]), K),
         "abstand_muehle_m": abst((gutp["x"], gutp["z"]), (mu["x"], mu["z"])), "zufahrt": "gutsweg", "ladeplatz": LP[GUT["id"]]},
        {"id": MUEHLE["id"], "name": MUEHLE["name"], "typ": "wassermuehle", "x": mu["x"], "z": mu["z"], "rot_deg": mu["rot_deg"],
         "muehlteich": {"x": MUEHLTEICH_MITTE[0], "z": MUEHLTEICH_MITTE[1], "r_m": MUEHLTEICH_R},
         "abstand_dorf_m": abst((mu["x"], mu["z"]), K), "zufahrt": "muehlweg",
         "abweichung": "17 m oestlich der Bach-Achse (TA-Vorschlag lag auf der Achse, Rinne +-12 m)", "ladeplatz": LP[MUEHLE["id"]]},
        {"id": GUT2["id"], "name": GUT2["name"], "typ": "getreidefarm", "x": f2p["x"], "z": f2p["z"], "rot_deg": f2p["rot_deg"],
         "hofform": "vierseithof_40x40", "schlaege": f2_schlaege, "lage": "ebene", "abstand_dorf_m": abst((f2p["x"], f2p["z"]), K),
         "abstand_muehle_m": abst((f2p["x"], f2p["z"]), (mu["x"], mu["z"])),
         "abstand_muehle_felder": r2(math.hypot(f2p["x"] - mu["x"], f2p["z"] - mu["z"]) / 25.0), "zufahrt": "hofweg_hasenwinkel",
         "ladeplatz": LP[GUT2["id"]]}]
    gewaesser = [
        {"id": "binsensee", "typ": "see", "name": SEE_NAME, "x": SEE_MITTE[0], "z": SEE_MITTE[1], "r_m": SEE_R, "pegel_m": SEE_PEGEL, "quelle": "Vorgabe"},
        {"id": "rotach", "typ": "fluss", "name": FLUSS_NAME, "quelle": "Vorgabe/ds_v2"},
        {"id": "erlenbach", "typ": "bach", "name": BACH_NAME, "quelle": "Vorgabe (TA proto_bach.json)"},
        {"id": "muehlteich", "typ": "teich", "name": "M\u00fchlteich", "x": MUEHLTEICH_MITTE[0], "z": MUEHLTEICH_MITTE[1], "r_m": MUEHLTEICH_R, "quelle": "Vorgabe"},
        {"id": "dorfteich", "typ": "teich", "name": "Dorfteich", "x": DORFTEICH[0], "z": DORFTEICH[1], "r_m": DORFTEICH[2], "gelaende_hoehe_m": r2(geo.hoehe(DORFTEICH[0], DORFTEICH[1])), "quelle": "Stadt-Vorschlag",
         "hinweis": "am Ende der Bachgasse, ohne Zufluss; TA: kleine Senke 0,6 m, Wasserflaeche (Platzhalter der TA lag an anderer Stelle)"}]
    abstaende = {"dorf_weiler_m": abst(od["erlenbach"], od["hasenwinkel"]), "dorf_kleinstadt_m": abst(od["erlenbach"], od["lindenfurt"]),
                 "dorf_kleinstadt_kreuzung_m": abst(K, MARKT_MITTE), "dorf_gut_m": industrie[0]["abstand_dorf_m"],
                 "dorf_muehle_m": industrie[1]["abstand_dorf_m"], "muehle_farm2_m": industrie[2]["abstand_muehle_m"], "weiler_kleinstadt_m": abst(od["hasenwinkel"], od["lindenfurt"])}
    meta = {"erzeugt_von": VERSION, "welt_seed": WELT_SEED, "koordinaten": "lokal m, Ursprung NW-Ecke Kern, +x Ost, +z Sued",
            "rot_deg": "Godot rotation_degrees.y; lokales +z (Fassade) zeigt auf (sin rot, cos rot) in (x, z)",
            "abstaende": abstaende, "see_nutzung": ex["see"], "mauer": ex["mauer"], "kreuzungen": knoten,
            "allee_baeume_n": n_allee}
    proto = os.path.join(out_dir)
    ohne_flaeche = [so.instanz_export(d) for d in szene.inst]
    daten = {"proto_orte.json": dict(_meta=meta, orte=orte, industrie=industrie, gewaesser=gewaesser,
                                     parzellen={o["id"]: so.parzellen_export(ol) for o, ol in zip(orte, (ol_d, ol_w, ol_m))}),
             "proto_wege.json": wege, "proto_instanzen.json": ohne_flaeche, "proto_vorher_nachher.json": vn}
    for name, dat in daten.items():
        so.schreibe_json(os.path.join(proto, name), dat, zeilenweise=(name == "proto_instanzen.json"))
    if not still:
        print("Orte:", [(o["id"], o["ew"], o["gebaeude_n"], o["r_m"]) for o in orte])
        print("Abstaende:", abstaende)
        print("Wege:", [(w["id"], round(w["laenge_m"]), w["max_steigung_pct"]) for w in wege])
        print("Instanzen:", len(ohne_flaeche), "Allee", n_allee, "Kreuzungen", len(knoten))
        for n in ("ohne_versorgung", "mit_versorgung"):
            m = vn["monat12_" + n]
            print(n, "EW", vn["monat0"]["ew"], "->", m["ew"], "Aktionen", m["aktionen_n"], [a["regel"] for a in m["aktionen"]])
    if bilder:
        from stadt_bilder import bilder_erzeugen
        szene.mauer = ex["mauer"]
        bilder_erzeugen(geo, szene, wo, bruecken, orte, industrie, wach, ol_d, ol_m, TOR)
    return {n: os.path.join(proto, n) for n in daten}


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=SRC_DEFAULT)
    ap.add_argument("--out", default=OUT_DIR)
    ap.add_argument("--bilder", action="store_true")
    ap.add_argument("--md5", action="store_true", help="zweimal erzeugen und md5 vergleichen")
    a = ap.parse_args()
    pf = erzeuge(a.out, a.bilder, a.src)
    sums = {n: md5_datei(p) for n, p in pf.items()}
    for n, h in sums.items():
        print("md5", n, h)
    if a.md5:
        import tempfile
        tmp = tempfile.mkdtemp(prefix="stadt_md5_")
        pf2 = erzeuge(tmp, False, a.src, still=True)
        ok = True
        for n, p in pf2.items():
            same = md5_datei(p) == sums[n]
            ok &= same
            print("md5 zweiter Lauf", n, "gleich" if same else "UNGLEICH")
        sys.exit(0 if ok else 2)
