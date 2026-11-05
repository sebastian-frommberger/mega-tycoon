#!/usr/bin/env python3
"""Validator der Stadt-Rolle (Phase 4 Welle 1). Liest proto_orte/instanzen/wege/vorher_nachher.json und prueft gegen das Gelaende
(ds_v2, gleiche Funktionen wie der Generator) und das Regelwerk. Tabellenausgabe; Exit-Code 1 bei hartem FAIL.

Aufruf: python3 tools_proto/stadt_validate.py [--dir slice/world/data/proto] [--src DIR]"""
import argparse
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from stadt_geo import (Gelaende, MUEHLTEICH_MITTE, MUEHLTEICH_R, OUT_DIR, SRC_DEFAULT, clark_evans, min_radius, obb_ecken, obb_ueberlappt,
                       poly_abstand, resample, punkt_in_obb)

HAUS_TYPEN = {"kate", "bauernhof", "grosshof", "handwerkerhaus", "buergerhaus", "mietshaus", "kirche_dorf", "kirche_stadt", "kapelle",
              "pfarrhaus", "gasthaus", "schmiede", "schule", "rathaus", "speicher", "stadttor", "bahnhof", "nebengebaeude"}
ROLLEN = {"laubbaum", "eiche", "nadelbaum", "obstbaum", "busch", "zaun_latte", "heuhaufen", "holzstapel", "fass", "amboss", "passant", "brunnen",
          "ruderboot", "wassermuehle_rad", "laterne"}
ERWEITERUNG = {"wassermuehle", "gutshof", "fischerhuette", "netzgestell", "steg"}   # nicht in haustypen/Rollen, in der Doku begruendet
OHNE_GELAENDE = {"steg", "ruderboot"}            # stehen absichtlich am/im Wasser
WEG_SOLL = {"chaussee": 5.0, "dorfstrasse": 8.0, "gasse": 8.0, "feldweg": 10.0}
DORFTEICH = (1512.0, 818.0, 12.5)


class Tabelle:
    def __init__(self):
        self.zeilen = []
        self.fehler = 0

    def add(self, name, soll, ist, ok, art="HART"):
        if not ok and art == "HART":
            self.fehler += 1
        self.zeilen.append((name, str(soll), str(ist), "OK" if ok else ("FAIL" if art == "HART" else "WARN"), art))

    def info(self, name, ist):
        self.zeilen.append((name, "-", str(ist), "INFO", "INFO"))

    def drucken(self):
        w = [max(len(z[i]) for z in self.zeilen + [("Pruefung", "Soll", "Ist", "Ergebnis", "")]) for i in range(4)]
        w = [min(x, 70) for x in w]
        def zeile(z):
            return " | ".join(z[i][:w[i]].ljust(w[i]) for i in range(4))
        print(zeile(("Pruefung", "Soll", "Ist", "Ergebnis", "")))
        print("-+-".join("-" * x for x in w))
        for z in self.zeilen:
            print(zeile(z))


def footprint_punkte(d):
    e = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
    pts = list(e)
    for i in range(4):
        a, b = e[i], e[(i + 1) % 4]
        pts.append(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2))
    pts.append((d["x"], d["z"]))
    return e, pts


def gelaendefehler(geo, d, bach_min):
    """Gibt Liste Verstoesse eines Gebaeudes zurueck (Rinne, See, Teiche, Hang, Bach)."""
    e, pts = footprint_punkte(d)
    v = set()
    for (x, z) in pts:
        if geo.rinne_abstand(x, z) < 0.5:
            v.add("rinne")
        if geo.see_abstand(x, z) < 0.5:
            v.add("see")
        if geo.muehlteich_abstand(x, z) < 0.5 or math.hypot(x - DORFTEICH[0], z - DORFTEICH[1]) < DORFTEICH[2] + 0.5:
            v.add("teich")
        if bach_min is not None and geo.bach_abstand(x, z) < bach_min:
            v.add("bach")
        if geo.steigung(x, z) > 6.0:
            v.add("hang")
    return v


def ueberlappungen(gebs):
    """Paarweise OBB-Ueberlappung (SAT, Beruehrung zaehlt nicht) mit einfachem Raster."""
    zellen = {}
    ecken = []
    for i, d in enumerate(gebs):
        e = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
        ecken.append(e)
        for cx in {int(c[0] // 40) for c in e}:
            for cz in {int(c[1] // 40) for c in e}:
                zellen.setdefault((cx, cz), []).append(i)
    paare = set()
    for lst in zellen.values():
        for a in range(len(lst)):
            for b in range(a + 1, len(lst)):
                i, j = lst[a], lst[b]
                if (i, j) in paare:
                    continue
                if obb_ueberlappt(ecken[i], ecken[j], -0.2):
                    paare.add((i, j))
    return sorted(paare)


def richtungswechsel(poly):
    m = 0.0
    for k in range(1, len(poly) - 1):
        a = math.atan2(poly[k][1] - poly[k - 1][1], poly[k][0] - poly[k - 1][0])
        b = math.atan2(poly[k + 1][1] - poly[k][1], poly[k + 1][0] - poly[k][0])
        d = abs((math.degrees(b - a) + 180.0) % 360.0 - 180.0)
        m = max(m, d)
    return m


KLASSEN_SIM = {  # Regelwerk ortsklassen (slice/world/data/proto/regelwerk.json): ort_ew, umland_ew, sim_ew
    "dorf": ((150, 350), (250, 550), (400, 900)),
    "kleinstadt": ((2000, 4000), (400, 700), (2400, 4700)),
}
NACHFRAGE_MULT = {"dorf": 2.0, "kleinstadt": 1.0}   # economy_slice.json saettigung.demand_mult_promille_je_stufe / 1000; 1 Einheit je 100 EW und Periode (Min.)


LADEPLATZ_NETZ_MAX = 8.0        # WA-08: Datenpunkt <= 8 m vom Wegnetz
LADEPLATZ_HECK_MAX = 3.0        # WA-08: Gespann-Heck <= 3 m vom Ladeplatz
HALT_LUFT_M = 0.3               # proto_easing.gd HALT_LUFT_M


def _ende_tangente(punkte, schritt=6.0):
    e = punkte[-1]
    for p in reversed(punkte[:-1]):
        if math.hypot(e[0] - p[0], e[1] - p[1]) >= schritt:
            L = math.hypot(e[0] - p[0], e[1] - p[1])
            return ((e[0] - p[0]) / L, (e[1] - p[1]) / L)
    return (1.0, 0.0)


def heck_punkt(wege_by_id, lpd, heck):
    """Heck-Halt-Punkt des Fuhrwerks am Wegende des Ladeplatzes (aus den Wegdaten, nicht aus dem Ladeplatz-Datensatz)."""
    w = [tuple(p) for p in wege_by_id[lpd["weg"]]["punkte"]]
    E = w[-1] if math.hypot(w[-1][0] - lpd["halt"]["x"], w[-1][1] - lpd["halt"]["z"]) < math.hypot(w[0][0] - lpd["halt"]["x"], w[0][1] - lpd["halt"]["z"]) else w[0]
    pts = w if E == w[-1] else list(reversed(w))
    t = _ende_tangente(pts)
    return (E[0] - t[0] * heck, E[1] - t[1] * heck), E


def pruefe_ladeplaetze(T, orte_j, wege, geo, inst=(), regelwerk_pfad=None):
    """WA-08: Ladeplatz je Betrieb und Sim-Ort. Datenpunkt <= 8 m vom Netz, Halt = Sackgassen-Wegende (Gespann-Heck <= 3 m) oder Durchgangsknoten,
    Kies/Rampe/Haufen frei von Gebaeuden und Gewaesser, 3 Fuellstufen. Die Pruefung nutzt nur die ausgelieferten JSON-Daten."""
    rwp = regelwerk_pfad or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "slice", "world", "data", "proto", "regelwerk.json")
    rw = json.load(open(rwp, encoding="utf-8"))
    heck = float(rw["skalen"]["fahrzeuge_dm"]["fuhrwerk_2_pferde"]["l"]) / 10.0 + HALT_LUFT_M
    wby = {w["id"]: w for w in wege}
    polys = [[tuple(p) for p in w["punkte"]] for w in wege]
    kreuz = [(k["x"], k["z"]) for k in orte_j["_meta"]["kreuzungen"]]
    enden = []
    for w in wege:
        for p in (w["punkte"][0], w["punkte"][-1]):
            enden.append(tuple(p))
    sites = [(i["id"], i, (i["x"], i["z"])) for i in orte_j["industrie"]]
    sites += [(o["id"], o, (o["x"], o["z"])) for o in orte_j["orte"] if o.get("sim_knoten")]
    haupt = HAUS_TYPEN | {"gutshof", "wassermuehle", "fischerhuette"}
    gebs = [(obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"]), d["typ"]) for d in inst if d["typ"] in haupt and "b" in d]
    for sid, o, mitte in sites:
        lp = o.get("ladeplatz")
        if not lp:
            T.add("Ladeplatz %s: Datenpunkt vorhanden" % sid, "ja", "fehlt", False)
            continue
        P = (lp["x"], lp["z"])
        dmin = min(poly_abstand(P, pl)[0] for pl in polys)
        T.add("Ladeplatz %s: <= 8 m vom Wegnetz" % sid, "<= %.0f m" % LADEPLATZ_NETZ_MAX, "%.1f m (Weg %s)" % (dmin, lp["weg"]), dmin <= LADEPLATZ_NETZ_MAX)
        if lp["halt"]["art"] == "durchgang":
            # Durchgangsknoten (Muendung Muehlweg/Gutsweg): Gespann haelt mit der Mitte im Knoten; Heck-Regel (Sackgasse) entfaellt, stattdessen Datenpunkt = Knoten
            E = (lp["halt"]["x"], lp["halt"]["z"])
            dk = math.hypot(E[0] - P[0], E[1] - P[1])
            T.add("Ladeplatz %s: Durchgangshalt, Datenpunkt = Halteknoten (<= 0,5 m)" % sid, "<= 0.5 m", "%.2f m" % dk, dk <= 0.5)
            kn_ok = any(math.hypot(q[0] - E[0], q[1] - E[1]) < 0.5 for q in kreuz)
            T.add("Ladeplatz %s: Halteknoten ist Wegkreuzung/Einmuendung (orte._meta.kreuzungen)" % sid, "ja", "ja" if kn_ok else "nein", kn_ok)
            kand = [(math.hypot(q[0] - P[0], q[1] - P[1]), q) for q in enden + kreuz if math.hypot(q[0] - P[0], q[1] - P[1]) <= 40.0]
            kand.sort()
            nah = kand[0][1] if kand else None
            T.add("Ladeplatz %s: naechster Halteknoten (<= 40 m) = Halt" % sid, "Halt", "%.1f m" % kand[0][0] if nah and math.hypot(nah[0] - E[0], nah[1] - E[1]) < 1.0 else "anderer Knoten",
                  bool(nah) and math.hypot(nah[0] - E[0], nah[1] - E[1]) < 1.0)
        else:
            hp, E = heck_punkt(wby, lp, heck)
            dh = math.hypot(hp[0] - P[0], hp[1] - P[1])
            T.add("Ladeplatz %s: Gespann-Heck (Wegende - %.1f m) <= 3 m vom Ladeplatz" % (sid, heck), "<= %.0f m" % LADEPLATZ_HECK_MAX, "%.2f m" % dh, dh <= LADEPLATZ_HECK_MAX)
            # Halt ist Sackgasse: nur dieser Weg endet dort, kein anderer Weg im Fang von 8 m
            fremd = [w["id"] for w in wege if w["id"] != lp["weg"] and poly_abstand(E, [tuple(p) for p in w["punkte"]])[0] < 8.0]
            T.add("Ladeplatz %s: Halt = Sackgassen-Wegende" % sid, "Grad 1", "kein fremder Weg ausser %s" % (fremd or "-") if fremd else "Grad 1", not fremd)
            # Halteknoten-Nachbau (ProtoSim.knoten_halt): naechster Wegende/Kreuzungsknoten <= 40 m vom Datenpunkt muss der Halt sein
            kand = [(math.hypot(q[0] - P[0], q[1] - P[1]), q) for q in enden + kreuz if math.hypot(q[0] - P[0], q[1] - P[1]) <= 40.0]
            kand.sort()
            nah = kand[0][1] if kand else None
            T.add("Ladeplatz %s: naechster Halteknoten (<= 40 m) = Halt" % sid, "Halt", "%.1f m" % kand[0][0] if nah and math.hypot(nah[0] - E[0], nah[1] - E[1]) < 1.0 else "anderer Knoten",
                  bool(nah) and math.hypot(nah[0] - E[0], nah[1] - E[1]) < 1.0)
        if "r_m" in o:
            dm = math.hypot(E[0] - mitte[0], E[1] - mitte[1])
            T.add("Ladeplatz %s: Halt <= r_m (%d m) von der Ortsmitte" % (sid, o["r_m"]), "<= r_m", "%.0f m" % dm, dm <= o["r_m"])
        else:
            T.info("Ladeplatz %s: Halt vom Betrieb (Mitte)" % sid, "%.0f m" % math.hypot(E[0] - mitte[0], E[1] - mitte[1]))
        # Flaechen: Kies-Hof, Rampe, Haufen
        flaechen = [("kies_hof", lp["kies_hof"])] + [("rampe", lp["rampe"])] + [("haufen", h) for h in lp["lagerhaufen"]]
        ueber, gel = [], []
        for name, f in flaechen:
            e = obb_ecken(f["x"], f["z"], f["b"], f["t"], f["rot_deg"])
            for (ge, gt) in gebs:
                if obb_ueberlappt(e, ge):
                    ueber.append("%s x %s" % (name, gt))
            for k in range(5):
                for m in range(5):
                    a, b = k / 4.0, m / 4.0
                    x = (1 - a) * ((1 - b) * e[0][0] + b * e[3][0]) + a * ((1 - b) * e[1][0] + b * e[2][0])
                    z = (1 - a) * ((1 - b) * e[0][1] + b * e[3][1]) + a * ((1 - b) * e[1][1] + b * e[2][1])
                    if geo.rinne_abstand(x, z) < 3.0 or geo.see_abstand(x, z) < 10.0 or geo.muehlteich_abstand(x, z) < 8.0 or geo.bach_abstand(x, z) < 8.0:
                        gel.append(name)
                        break
                else:
                    continue
                break
        T.add("Ladeplatz %s: Kies-Hof/Rampe/Haufen ohne Gebaeude-Ueberlappung" % sid, 0, ueber or 0, not ueber)
        T.add("Ladeplatz %s: Kies-Hof/Rampe/Haufen nicht in Rinne/See/Teich/Bach" % sid, 0, gel or 0, not gel)
        ok_st = all(len(h["fuellstufen"]["grenzen"]) == 3 and len(h["fuellstufen"]["prefab_refs"]) == 3 and
                    [g["bestand_ab_anteil"] for g in h["fuellstufen"]["grenzen"]] == sorted(g["bestand_ab_anteil"] for g in h["fuellstufen"]["grenzen"])
                    for h in lp["lagerhaufen"]) and len(lp["lagerhaufen"]) >= 1
        T.add("Ladeplatz %s: Lagerhaufen mit 3 Fuellstufen (aufsteigende Grenzen, 3 Prefab-Refs)" % sid, "3", ", ".join("%s:%d" % (h["gut"], len(h["fuellstufen"]["grenzen"])) for h in lp["lagerhaufen"]), ok_st)


def pruefe_welt_daten(T, orte_j, wege, geo, inst=()):
    """WA-07: Farm 2, Ladeplatz-Datenpunkt, sim_ew je Ort (Klassenband, Nachfrage)."""
    ind = orte_j["industrie"]
    mu = [i for i in ind if i["typ"] == "wassermuehle"][0]
    farmen = [i for i in ind if i["typ"] == "getreidefarm"]
    T.add("Getreidefarmen (Kuppenhof + Farm 2)", ">= 2", len(farmen), len(farmen) >= 2)
    for f in farmen[1:]:
        fl = math.hypot(f["x"] - mu["x"], f["z"] - mu["z"]) / 25.0
        T.add("Farm %s: Felder von der Muehle (Luftlinie)" % f["id"], "35..50", "%.1f" % fl, 35.0 <= fl <= 50.0)
    for f in farmen:
        T.add("Farm %s: Mittelpunkt Ebene/Aue (nicht Rinne/See, Hang <= 3 %%)" % f["id"], "ja",
              "rinne %.0f m, see %.0f m, Hang %.1f %%" % (geo.rinne_abstand(f["x"], f["z"]), geo.see_abstand(f["x"], f["z"]), geo.steigung(f["x"], f["z"])),
              geo.rinne_abstand(f["x"], f["z"]) > 0.5 and geo.see_abstand(f["x"], f["z"]) > 0.5 and geo.steigung(f["x"], f["z"]) <= 3.0)
    pruefe_ladeplaetze(T, orte_j, wege, geo, inst)
    for o in orte_j["orte"]:
        if not o.get("sim_knoten"):
            T.add("Ort %s: Weiler/ohne Sim-Knoten (kein sim_ew)" % o["id"], "klasse weiler", o["klasse"], o["klasse"] == "weiler" and "sim_ew" not in o)
            continue
        kl = o["sim_stufe"]
        (e_lo, e_hi), (u_lo, u_hi), (s_lo, s_hi) = KLASSEN_SIM[kl]
        ew_ort, ew_um, sim = o["ew_ort"], o["ew_umland"], o["sim_ew"]
        T.add("Ort %s (%s): Ort-EW im Klassenband" % (o["id"], kl), "%d..%d" % (e_lo, e_hi), ew_ort, e_lo <= ew_ort <= e_hi)
        T.add("Ort %s: Umland-EW im Klassenband" % o["id"], "%d..%d" % (u_lo, u_hi), ew_um, u_lo <= ew_um <= u_hi)
        T.add("Ort %s: sim_ew = Ort + Umland, im Band" % o["id"], "%d..%d" % (s_lo, s_hi), "%d (%d + %d)" % (sim, ew_ort, ew_um), ew_ort + ew_um == sim and s_lo <= sim <= s_hi)
        nach = sim * NACHFRAGE_MULT[kl] / 100.0
        soll = {"erlenbach": (10.0, 2.0), "lindenfurt": (24.0, 3.0)}.get(o["id"])
        if soll:
            T.add("Ort %s: Nachfrage E/min (berechnet aus sim_ew)" % o["id"], "%.0f +- %.0f" % soll, "%.1f" % nach, abs(nach - soll[0]) <= soll[1])


# ---------------------------------------------------------------- WA-09: Platzierungsregeln (PL-1)
# Regeln 1-4 aus sprints/s8/refinement/ux_art.md "Level-Design-Regeln (neu)"; Messart gemessen an proto_*.json + ausgelieferten Hoehenrastern.
WINKEL_MAX = 10.0                      # Regel 1: Traufe oder Giebel +-10 Grad zur Bezugslinie (mod 90)
BAULINIE = {"erlenbach": (3.0, 15.0), "hasenwinkel": (3.0, 15.0), "lindenfurt": (0.0, 3.0)}    # Regel 2: Dorf 3-15 m, Kleinstadt 0-3 m
ZUFAHRT_BETRIEB_MAX = 12.0             # Regel 3: Weg bis ins Tor: Abstand Wegrand - Gebaeuderand <= 12 m (Betrieb)
ZUFAHRT_HOF_MAX = 15.0                 # Regel 3: Hofstelle im Dorf: Wegrand - Gebaeuderand <= 15 m (Obergrenze der Baulinie)
FUNDAMENT_MAX = 0.5                    # Regel 4: Hoehenspreizung im Footprint, Raster 5 m
HAUPTGEBAEUDE = (HAUS_TYPEN - {"nebengebaeude", "stadttor"}) | {"gutshof", "wassermuehle", "fischerhuette"}
WASSER_BEZUG = {"wassermuehle", "fischerhuette"}
BETRIEBE = {"gutshof", "wassermuehle"}
HOFSTELLEN = {"bauernhof", "grosshof"}
REGELN = ("bezugslinie", "baulinie", "zufahrt", "fundament")


class Hoehe:
    """Hoehenmodell wie im Spiel (proto_meta.json fein.regel): Feinraster 5 m in Feldern mit Maske 1, sonst Grobraster 25 m; Dreiecksteilung (a,b,c)/(b,d,c)."""

    def __init__(self, dir_):
        import numpy as np
        meta = json.load(open(os.path.join(dir_, "proto_meta.json"), encoding="utf-8"))
        self.skala = float(meta["hoehe_skala_m"])
        fw, fh = meta["felder"]
        self.fw, self.fh = fw, fh
        self.m_feld = float(meta["fenster"]["m_pro_feld"])
        self.x0 = -1000.0
        self.z0 = -1000.0
        self.grob = np.fromfile(os.path.join(dir_, "proto_hoehe.r16"), dtype="<u2").reshape(fh + 1, fw + 1).astype(float) * self.skala
        kn = meta["fein"]["knoten"]
        self.fein = np.fromfile(os.path.join(dir_, meta["fein"]["datei"]), dtype="<u2").reshape(kn[1], kn[0]).astype(float) * self.skala
        self.maske = np.fromfile(os.path.join(dir_, meta["fein"]["maske"]), dtype="u1").reshape(fh, fw)
        self.m_fein = float(meta["fein"]["m_pro_knoten"])

    @staticmethod
    def _tri(g, fx, fz, i, j):
        """Hoehe im Quad (i,j) mit lokalen Koordinaten fx,fz in [0,1]; a=(0,0) b=(1,0) c=(0,1) d=(1,1), Diagonale b-c."""
        a, b, c, d = g[j, i], g[j, i + 1], g[j + 1, i], g[j + 1, i + 1]
        if fx + fz <= 1.0:
            return a + (b - a) * fx + (c - a) * fz
        return d + (b - d) * (1.0 - fz) + (c - d) * (1.0 - fx)

    def hoehe(self, x, z):
        u = (x - self.x0) / self.m_feld
        v = (z - self.z0) / self.m_feld
        fi = min(max(int(math.floor(u)), 0), self.fw - 1)
        fj = min(max(int(math.floor(v)), 0), self.fh - 1)
        if self.maske[fj, fi] == 1:
            u = (x - self.x0) / self.m_fein
            v = (z - self.z0) / self.m_fein
            i = min(max(int(math.floor(u)), 0), self.fein.shape[1] - 2)
            j = min(max(int(math.floor(v)), 0), self.fein.shape[0] - 2)
            return float(self._tri(self.fein, u - i, v - j, i, j))
        i = min(max(int(math.floor(u)), 0), self.grob.shape[1] - 2)
        j = min(max(int(math.floor(v)), 0), self.grob.shape[0] - 2)
        return float(self._tri(self.grob, u - i, v - j, i, j))


def kreis_poly(cx, cz, r, n=72):
    return [(cx + r * math.cos(2 * math.pi * k / n), cz + r * math.sin(2 * math.pi * k / n)) for k in range(n + 1)]


def winkel_abw(rot_deg, p, q):
    """Kleinste Abweichung (Grad, mod 90) zwischen lokaler x-Achse des Gebaeudes (Traufe/Fassade) und der Geraden p-q."""
    r = math.radians(rot_deg)
    ab = math.degrees(math.atan2(-math.sin(r), math.cos(r)))
    ar = math.degrees(math.atan2(q[1] - p[1], q[0] - p[0]))
    d = (ab - ar) % 90.0
    return min(d, 90.0 - d)


def randpunkte(d):
    e = obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"])
    pts = list(e)
    for i in range(4):
        a, b = e[i], e[(i + 1) % 4]
        for f in (0.25, 0.5, 0.75):
            pts.append((a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f))
    return pts


def bezuege(wege, inst, dir_):
    """Liste (art, id, polylinie, halbe_breite) aller Bezugslinien: Wege, Platzkanten, Wasser (Bach, Binsensee, Muehlteich)."""
    wl = [("weg", w["id"], [tuple(p) for p in w["punkte"]], w["breite_m"] / 2.0) for w in wege]
    pl = []
    for x in inst:
        if x["typ"] == "flaeche_marktplatz":
            e = obb_ecken(x["x"], x["z"], x["b"], x["t"], x["rot_deg"])
            for i in range(4):
                pl.append(("platz", "marktplatz_%d" % i, [e[i], e[(i + 1) % 4]], 0.0))
    ws = []
    bach = json.load(open(os.path.join(dir_, "proto_bach.json"), encoding="utf-8"))
    ws.append(("wasser", "bach", [(p[0], p[1]) for p in bach["punkte"]], 0.0))
    see = json.load(open(os.path.join(dir_, "proto_see.json"), encoding="utf-8"))
    for k in ("see", "muehlteich"):
        sd = see.get(k)
        if sd:
            mx = sd.get("mitte_m") or [sd.get("x"), sd.get("z")]
            ws.append(("wasser", k, kreis_poly(mx[0], mx[1], sd.get("radius_m") or sd.get("r_m")), 0.0))
    return wl, pl, ws


def messe_platzierung(orte_j, inst, wege, dir_):
    """Misst die vier Regeln je Hauptgebaeude. Rueckgabe {regel: [dict(key, typ, ort, x, z, wert, text)]} der Verstoesse und die Anzahl geprueft."""
    wl, pl, ws = bezuege(wege, inst, dir_)
    hm = Hoehe(dir_)
    par = {}
    for oid, lst in orte_j["parzellen"].items():
        for p in lst:
            par[p["id"]] = p
    wd = {w["id"]: w for w in wege}
    verst = {r: [] for r in REGELN}
    geprueft = {r: 0 for r in REGELN}
    gebs = [x for x in inst if x["typ"] in HAUPTGEBAEUDE and "b" in x]
    for x in gebs:
        key = "%s|%.2f|%.2f" % (x["typ"], x["x"], x["z"])
        ort = x["ort"]
        mitte = (x["x"], x["z"])
        rp = randpunkte(x)
        # --- Bezugslinie: naechste Linie (Wasser nur fuer Muehle/Fischerhuette, dort statt Weg/Platz)
        kand = ws if x["typ"] in WASSER_BEZUG else wl + pl
        best = None
        for (art, bid, poly, hb) in kand:
            d, k, t = poly_abstand(mitte, poly)
            if best is None or d < best[0]:
                best = (d, art, bid, poly, hb, k)
        d, art, bid, poly, hb, k = best
        abw = winkel_abw(x["rot_deg"], poly[k], poly[k + 1])
        geprueft["bezugslinie"] += 1
        if abw > WINKEL_MAX:
            verst["bezugslinie"].append(dict(key=key, typ=x["typ"], ort=ort, x=x["x"], z=x["z"], wert=round(abw, 1),
                                             text="Winkel %.1f Grad zu %s %s (Soll <= %.0f)" % (abw, art, bid, WINKEL_MAX)))
        # --- Baulinie: Abstand Gebaeuderand - Bezugskante (Wegrand bzw. Platzkante), nur Wohn-/Gemeinbauten, nicht Betriebe
        if x["typ"] not in (BETRIEBE | WASSER_BEZUG) and ort in BAULINIE:
            lo, hi = BAULINIE[ort]
            gap = min(poly_abstand(p, poly)[0] for p in rp) - hb
            geprueft["baulinie"] += 1
            if not (lo - 0.5 <= gap <= hi + 0.5):
                verst["baulinie"].append(dict(key=key, typ=x["typ"], ort=ort, x=x["x"], z=x["z"], wert=round(gap, 1),
                                              text="Abstand %.1f m zu %s %s (Soll %.0f..%.0f)" % (gap, art, bid, lo, hi)))
        # --- Zufahrt: Betriebe bis ans Tor, Hofstellen mit erreichbarem Weg
        if x["typ"] in BETRIEBE:
            gaps = [(min(poly_abstand(p, [tuple(q) for q in w["punkte"]])[0] for p in rp) - w["breite_m"] / 2.0, w["id"]) for w in wege]
            gap, wid = min(gaps)
            geprueft["zufahrt"] += 1
            if gap > ZUFAHRT_BETRIEB_MAX:
                verst["zufahrt"].append(dict(key=key, typ=x["typ"], ort=ort, x=x["x"], z=x["z"], wert=round(gap, 1),
                                             text="naechster Wegrand (%s) %.1f m vom Gebaeuderand (Soll <= %.0f)" % (wid, gap, ZUFAHRT_BETRIEB_MAX)))
        elif x["typ"] in HOFSTELLEN:
            p = par.get(x["parzelle"])
            wid = p.get("weg") if p else None
            geprueft["zufahrt"] += 1
            if not wid or wid not in wd:
                verst["zufahrt"].append(dict(key=key, typ=x["typ"], ort=ort, x=x["x"], z=x["z"], wert=-1, text="Parzelle ohne gueltigen Zufahrtsweg (%s)" % wid))
            else:
                w = wd[wid]
                gap = min(poly_abstand(p_, [tuple(q) for q in w["punkte"]])[0] for p_ in rp) - w["breite_m"] / 2.0
                if gap > ZUFAHRT_HOF_MAX:
                    verst["zufahrt"].append(dict(key=key, typ=x["typ"], ort=ort, x=x["x"], z=x["z"], wert=round(gap, 1),
                                                 text="Weg %s %.1f m vom Hofrand (Soll <= %.0f)" % (wid, gap, ZUFAHRT_HOF_MAX)))
        # --- Fundament: Hoehenspreizung der 5-m-Rasterpunkte im Footprint plus Ecken
        e = obb_ecken(x["x"], x["z"], x["b"], x["t"], x["rot_deg"])
        xs, zs = [c[0] for c in e], [c[1] for c in e]
        hs = [hm.hoehe(c[0], c[1]) for c in e]
        gx0, gx1 = int(math.floor(min(xs) / 5.0)), int(math.ceil(max(xs) / 5.0))
        gz0, gz1 = int(math.floor(min(zs) / 5.0)), int(math.ceil(max(zs) / 5.0))
        for gi in range(gx0, gx1 + 1):
            for gj in range(gz0, gz1 + 1):
                if punkt_in_obb((gi * 5.0, gj * 5.0), e):
                    hs.append(hm.hoehe(gi * 5.0, gj * 5.0))
        spr = max(hs) - min(hs)
        geprueft["fundament"] += 1
        if spr > FUNDAMENT_MAX:
            verst["fundament"].append(dict(key=key, typ=x["typ"], ort=ort, x=x["x"], z=x["z"], wert=round(spr, 2),
                                           text="Hoehenspreizung %.2f m im Footprint (Soll <= %.1f)" % (spr, FUNDAMENT_MAX)))
    return verst, geprueft


def pruefe_platzierung(T, orte_j, inst, wege, dir_, strikt=False, baseline=None, liste=None):
    """WA-09: vier Platzierungsregeln. Verstoesse in der Baseline (bekannt, Fix ist WA-10) zaehlen als WARN, neue als FAIL;
    mit strikt=True ist jeder Verstoss FAIL (Ziel von WA-10)."""
    verst, geprueft = messe_platzierung(orte_j, inst, wege, dir_)
    namen = {"bezugslinie": "Bezugslinie: Traufe/Giebel +-10 Grad", "baulinie": "Baulinie: Dorf 3-15 m, Kleinstadt 0-3 m",
             "zufahrt": "Zufahrt: Betrieb <= 12 m / Hofstelle mit Weg <= 15 m", "fundament": "Fundament: Hoehe im Footprint <= 0,5 m (5-m-Raster)"}
    for r in REGELN:
        v = verst[r]
        bk = set((baseline or {}).get(r, []))
        neu = [d for d in v if d["key"] not in bk]
        art = "HART" if (neu or (strikt and v)) else "WARN"
        T.add("Platzierung %s" % namen[r], "0 Verstoesse (%d geprueft)" % geprueft[r],
              "%d, davon Baseline %d, neu %d" % (len(v), len(v) - len(neu), len(neu)), not v, art)
    if liste is not None:
        liste.update(verst)
    return verst, geprueft


# ---------------------------------------------------------------- WA-11 (PL-3): Allee wirkt natuerlich
ALLEE_CV_MIN = 0.15            # Variationskoeffizient der Baumabstaende (Std/Mittel) je Seite, gepoolt
ALLEE_WECHSEL_MAX = 0.60       # Anteil strikter Artwechsel zwischen aufeinanderfolgenden Baeumen derselben Seite
ALLEE_LAUF_MAX_M = 40.0        # Abstaende darueber sind Abschnittsgrenzen/Gelaendeluecken, keine Allee-Takte
ALLEE_REGEL_MAX_M = 16.5       # Takt 12 +- 3 m plus Versatz (max ~15,3 m); eine Luecke bringt >= 18 m: Abstaende darueber im Lauf zaehlen als Luecke


def allee_messung(inst, chaussee_pts):
    """Misst die Allee-Baeume (parzelle == allee) je Seite der Chaussee. Rueckgabe dict mit Abstaenden, Artwechsel, Luecken, Groessen."""
    pts = resample([tuple(p) for p in chaussee_pts], 1.0)
    baeume = [x for x in inst if x["parzelle"] == "allee"]
    seiten = {1: [], -1: []}
    for b in baeume:
        d, k, t = poly_abstand((b["x"], b["z"]), pts)
        px, pz = pts[k][0] + (pts[k + 1][0] - pts[k][0]) * t, pts[k][1] + (pts[k + 1][1] - pts[k][1]) * t
        tx, tz = pts[k + 1][0] - pts[k][0], pts[k + 1][1] - pts[k][1]
        seite = 1 if (tx * (b["z"] - pz) - tz * (b["x"] - px)) > 0 else -1
        seiten[seite].append((k + t, b))
    abst, wechsel, paare, luecken_fehlend, laeufe = [], 0, 0, 0, 0
    for sd, lst in seiten.items():
        lst.sort(key=lambda q: q[0])
        for (s0, a), (s1, b) in zip(lst, lst[1:]):
            d = math.hypot(b["x"] - a["x"], b["z"] - a["z"])
            if d > ALLEE_LAUF_MAX_M:
                laeufe += 1
                continue
            abst.append(d)
            paare += 1
            wechsel += 1 if a["typ"] != b["typ"] else 0
            if d > ALLEE_REGEL_MAX_M:
                luecken_fehlend += max(1, int(round(d / 12.0)) - 1)
    n = len(abst)
    mittel = sum(abst) / n if n else 0.0
    sd_ = math.sqrt(sum((v - mittel) ** 2 for v in abst) / n) if n else 0.0
    regel = [v for v in abst if v <= ALLEE_REGEL_MAX_M]
    m2 = sum(regel) / len(regel) if regel else 0.0
    cv2 = math.sqrt(sum((v - m2) ** 2 for v in regel) / len(regel)) / m2 if regel and m2 else 0.0
    skalen = [b.get("skala", 1.0) for b in baeume]
    arten = {}
    for b in baeume:
        arten[b["typ"]] = arten.get(b["typ"], 0) + 1
    return dict(n=len(baeume), paare=paare, mittel=mittel, cv=(sd_ / mittel if mittel else 0.0), cv_ohne_luecken=cv2,
                wechsel=(wechsel / paare if paare else 1.0), luecken_pct=(100.0 * luecken_fehlend / (luecken_fehlend + len(abst) + 1e-9) if abst else 0.0),
                skala_min=min(skalen) if skalen else 1.0, skala_max=max(skalen) if skalen else 1.0, arten=arten,
                seiten={sd: len(l) for sd, l in seiten.items()}, regel_mittel=m2, regel_min=min(regel) if regel else 0.0, regel_max=max(regel) if regel else 0.0)


def pruefe_allee(T, inst, wege):
    ch = [w for w in wege if w["id"] == "chaussee"][0]
    m = allee_messung(inst, ch["punkte"])
    T.add("Allee: Variationskoeffizient der Baumabstaende", ">= %.2f" % ALLEE_CV_MIN, "%.3f (Mittel %.1f m, n=%d Abstaende)" % (m["cv"], m["mittel"], m["paare"]), m["cv"] >= ALLEE_CV_MIN)
    T.add("Allee: Anteil strikter Artwechsel", "< %.0f %%" % (ALLEE_WECHSEL_MAX * 100), "%.0f %% %s" % (m["wechsel"] * 100, m["arten"]), m["wechsel"] < ALLEE_WECHSEL_MAX)
    T.add("Allee: regulaerer Takt (Mittel, Min..Max ohne Luecken)", "Mittel 12 +- 1,5 m, Abstaende >= 7,5 m", "%.1f m, %.1f..%.1f m" % (m["regel_mittel"], m["regel_min"], m["regel_max"]),
          10.5 <= m["regel_mittel"] <= 13.5 and m["regel_min"] >= 7.5, "WARN")
    T.add("Allee: Luecken (fehlende Baeume, aus Abstaenden > %.1f m)" % ALLEE_REGEL_MAX_M, "10..15 %", "%.1f %%" % m["luecken_pct"], 10.0 <= m["luecken_pct"] <= 15.0, "WARN")
    T.add("Allee: Groessen-Streuung (skala)", "0.85..1.15 (+-15 %)", "%.2f..%.2f" % (m["skala_min"], m["skala_max"]),
          0.85 - 1e-9 <= m["skala_min"] and m["skala_max"] <= 1.15 + 1e-9 and m["skala_max"] - m["skala_min"] > 0.1, "WARN")
    T.info("Allee: CV ohne Luecken / Seiten (+1 / -1)", "%.3f / %s" % (m["cv_ohne_luecken"], m["seiten"]))
    return m


def pruefen(dir_, src, strikt=False, baseline=None, liste=None):
    geo = Gelaende(src)
    T = Tabelle()
    orte_j = json.load(open(os.path.join(dir_, "proto_orte.json"), encoding="utf-8"))
    inst = json.load(open(os.path.join(dir_, "proto_instanzen.json"), encoding="utf-8"))
    wege = json.load(open(os.path.join(dir_, "proto_wege.json"), encoding="utf-8"))
    vn = json.load(open(os.path.join(dir_, "proto_vorher_nachher.json"), encoding="utf-8"))
    orte = {o["id"]: o for o in orte_j["orte"]}
    ab = orte_j["_meta"]["abstaende"]

    # ---- Format
    fehl = [d for d in inst if not all(k in d for k in ("typ", "x", "z", "rot_deg", "parzelle"))]
    T.add("Instanzen: Pflichtfelder typ,x,z,rot_deg,parzelle", "alle", "%d fehlen" % len(fehl), not fehl)
    bekannt = HAUS_TYPEN | ROLLEN | ERWEITERUNG
    unbek = sorted({d["typ"] for d in inst if d["typ"] not in bekannt and not d["typ"].startswith("flaeche_")})
    T.add("Instanz-Typen in haustypen/Rollen (+ dokumentierte Erweiterung)", "keine unbekannten", unbek or "ok", not unbek)
    ext = sorted({d["typ"] for d in inst if d["typ"] in ERWEITERUNG} | {d["typ"] for d in inst if d["typ"].startswith("flaeche_")})
    T.info("Erweiterungstypen (Doku)", ", ".join(ext))
    ausserhalb = [d for d in inst if not (-1000 <= d["x"] <= 3000 and -1000 <= d["z"] <= 2600)]
    T.add("Instanzen im Fenster -1000..3000 / -1000..2600", 0, len(ausserhalb), not ausserhalb)
    ausser_kern = [d for d in inst if not (0 <= d["x"] <= 2000 and 0 <= d["z"] <= 1600) and d["parzelle"] != "allee"]
    T.add("Gebaeude/Flaechen im Kern 2000 x 1600", 0, len(ausser_kern), not ausser_kern, "WARN")

    # ---- Orte, Anzahlen
    d = orte["erlenbach"]
    T.add("Dorf Wohnhaeuser", "30..40 (Soll ~35)", d["wohnhaeuser_n"], 30 <= d["wohnhaeuser_n"] <= 40)
    T.add("Dorf EW", "220..280 (~250)", d["ew"], 220 <= d["ew"] <= 280)
    z = d["gebaeude"]
    T.add("Dorf Kirche/Gasthaus/Schmiede", "1/1/1", "%s/%s/%s" % (z.get("kirche_dorf", 0), z.get("gasthaus", 0), z.get("schmiede", 0)),
          z.get("kirche_dorf", 0) == 1 and z.get("gasthaus", 0) == 1 and z.get("schmiede", 0) == 1)
    T.add("Dorf Luecken (10-20 % der Parzellen)", "4..9", d["luecken_n"], 4 <= d["luecken_n"] <= 9)
    w = orte["hasenwinkel"]
    T.add("Weiler Hoefe", 6, w["gebaeude"].get("bauernhof", 0), w["gebaeude"].get("bauernhof", 0) == 6 and w["gebaeude_n"] == 6)
    m = orte["lindenfurt"]
    T.add("Kleinstadt-Ausschnitt Gebaeude", "36..44 (~40)", m["gebaeude_n"], 36 <= m["gebaeude_n"] <= 44)
    zm = m["gebaeude"]
    T.add("Kleinstadt Stadtkirche/Rathaus/Tor", "1/1/1", "%s/%s/%s" % (zm.get("kirche_stadt", 0), zm.get("rathaus", 0), sum(1 for x in inst if x["typ"] == "stadttor")),
          zm.get("kirche_stadt", 0) == 1 and zm.get("rathaus", 0) == 1 and sum(1 for x in inst if x["typ"] == "stadttor") == 1)
    mp = [x for x in inst if x["typ"] == "flaeche_marktplatz"]
    T.add("Marktplatz 60 x 80 m", "80 x 60", ("%s x %s" % (mp[0]["b"], mp[0]["t"])) if mp else "fehlt", bool(mp) and mp[0]["b"] == 80.0 and mp[0]["t"] == 60.0)
    n_farm = len([f for f in orte_j["industrie"] if f["typ"] == "getreidefarm"])
    T.add("Gutshof Vierseithof 40 x 40 (je Farm einer)", "%dx" % n_farm, [(x["b"], x["t"]) for x in inst if x["typ"] == "gutshof"],
          len([x for x in inst if x["typ"] == "gutshof" and x["b"] == 40.0]) == n_farm)
    T.add("Wassermuehle am Bach/Muehlteich", "1x", sum(1 for x in inst if x["typ"] == "wassermuehle"), sum(1 for x in inst if x["typ"] == "wassermuehle") == 1)
    mu = [x for x in inst if x["typ"] == "wassermuehle"][0]
    T.add("Muehle: Bachabstand (Achse) / Teichabstand", "<= 30 m / <= 150 m", "%.0f / %.0f" % (geo.bach_abstand(mu["x"], mu["z"]),
          math.hypot(mu["x"] - MUEHLTEICH_MITTE[0], mu["z"] - MUEHLTEICH_MITTE[1]) - MUEHLTEICH_R),
          geo.bach_abstand(mu["x"], mu["z"]) <= 30 and math.hypot(mu["x"] - MUEHLTEICH_MITTE[0], mu["z"] - MUEHLTEICH_MITTE[1]) - MUEHLTEICH_R <= 150)

    # ---- Abstaende
    T.add("Abstand Dorf-Weiler (Mitte-Mitte)", "0.6..1.0 km (~0.8)", "%.2f km" % (ab["dorf_weiler_m"] / 1000.0), 600 <= ab["dorf_weiler_m"] <= 1000)
    T.add("Abstand Dorf-Kleinstadt (Mitte-Mitte)", ">= 1.6 km (2.5 im Kern nicht erreichbar)", "%.2f km" % (ab["dorf_kleinstadt_m"] / 1000.0), ab["dorf_kleinstadt_m"] >= 1600)
    T.add("Abstand Dorf-Gutshof", "0.5..0.8 km (~0.6)", "%.2f km" % (ab["dorf_gut_m"] / 1000.0), 500 <= ab["dorf_gut_m"] <= 800)

    # ---- Gelaende je Gebaeude
    geb = [x for x in inst if x["typ"] in HAUS_TYPEN | ERWEITERUNG and "b" in x and x["typ"] not in OHNE_GELAENDE]
    viol = {}
    for x in geb:
        bach_min = None if x["typ"] in ("wassermuehle", "fischerhuette", "stadttor") else 15.0
        v = gelaendefehler(geo, x, bach_min)
        if x["typ"] == "stadttor":
            v.discard("hang")
        for k in v:
            viol.setdefault(k, []).append("%s@%.0f,%.0f" % (x["typ"], x["x"], x["z"]))
    for k, bez in (("rinne", "in der Rinne"), ("see", "im See"), ("teich", "in einem Teich"), ("hang", "Hang > 6 %"), ("bach", "Bachabstand < 15 m")):
        T.add("Gebaeude %s" % bez, 0, "%d %s" % (len(viol.get(k, [])), viol.get(k, [])[:3]), not viol.get(k))
    wasser = [x for x in inst if x["typ"] not in OHNE_GELAENDE and not x["typ"].startswith("flaeche_") and x["parzelle"] != "allee" and
              (geo.rinne_abstand(x["x"], x["z"]) < 0.5 or geo.see_abstand(x["x"], x["z"]) < 0.5 or geo.muehlteich_abstand(x["x"], x["z"]) < 0.5 or
               math.hypot(x["x"] - DORFTEICH[0], x["z"] - DORFTEICH[1]) < DORFTEICH[2])]
    T.add("Instanz-Mittelpunkte im Wasser/Rinne (ohne Steg, Boot)", 0, len(wasser), not wasser)
    allee_falsch = [x for x in inst if x["parzelle"] == "allee" and (geo.rinne_abstand(x["x"], x["z"]) < 8 or geo.see_abstand(x["x"], x["z"]) < 12)]
    T.add("Allee-Baeume im Wasser/Rinnenrand", 0, len(allee_falsch), not allee_falsch)
    aue = {}
    for oid, oi in orte.items():
        pz = orte_j["parzellen"][oid]
        n_aue = sum(1 for p in pz if geo.in_aue(p["x"], p["z"]))
        aue[oid] = "%d/%d" % (n_aue, len(pz))
    T.info("Parzellen mit Mittelpunkt in der Aue (weiche Regel, Aue = 35 % des Kerns)", aue)

    # ---- Ueberlappung
    gebs = [x for x in inst if x["typ"] in HAUS_TYPEN | ERWEITERUNG and "b" in x and x["typ"] not in OHNE_GELAENDE]
    paare = ueberlappungen(gebs)
    T.add("Gebaeude-Ueberlappungen (inkl. Nebengebaeude)", 0, "%d %s" % (len(paare), [(gebs[i]["typ"], gebs[j]["typ"], gebs[i]["x"], gebs[i]["z"]) for i, j in paare[:3]]), not paare)

    # ---- Hofstellen = 1 Feld
    par = {oid: {p["id"]: p for p in orte_j["parzellen"][oid]} for oid in orte_j["parzellen"]}
    gross = [p for oid in ("erlenbach", "hasenwinkel") for p in par[oid].values() if p["typ"] in ("bauernhof", "grosshof", "kate", "handwerkerhaus") and (p["b"] > 25.01 or p["t"] > 25.01)]
    T.add("Hofstelle/Parzelle <= 1 Feld (25 x 25 m)", 0, len(gross), not gross)
    raus = []
    for x in inst:
        if x["typ"] in ("zaun_latte", "nebengebaeude", "obstbaum", "heuhaufen", "holzstapel", "fass", "amboss") or x["typ"] in HAUS_TYPEN:
            p = None
            for oid in ("erlenbach", "hasenwinkel"):
                p = par[oid].get(x["parzelle"]) or p
            if p is None or p["typ"] == "kirche_dorf" or p["typ"] in ("gasthaus", "schmiede"):
                continue
            e = obb_ecken(p["x"], p["z"], p["b"] + 3.0, p["t"] + 3.0, p["rot_deg"])
            if not punkt_in_obb((x["x"], x["z"]), e):
                raus.append((x["typ"], x["parzelle"]))
    T.add("Hofstellen-Instanzen innerhalb ihrer Parzelle (+1,5 m)", 0, "%d %s" % (len(raus), raus[:3]), not raus)

    # ---- Wege
    wd = {w["id"]: w for w in wege}
    for w in wege:
        pts = [tuple(p) for p in w["punkte"]]
        L = w["laenge_m"]
        soll = WEG_SOLL[w["typ"]]
        T.add("Weg %s: max Steigung (10 m)" % w["id"], "<= %.0f %%" % soll, "%.2f %% (L %.0f m)" % (w["max_steigung_pct"], L), w["max_steigung_pct"] <= soll)
    ch = [tuple(p) for p in wd["chaussee"]["punkte"]]
    T.add("Chaussee min. Kruemmungsradius", ">= 50 m", "%.0f m" % wd["chaussee"]["min_radius_m"], wd["chaussee"]["min_radius_m"] >= 50.0)
    zz = {}
    for w in wege:
        zz[w["id"]] = richtungswechsel(resample([tuple(p) for p in w["punkte"]], 6.0))
    schlimm = {k: round(v, 1) for k, v in zz.items() if v > 30.0}
    T.add("Wege glatt (max Richtungswechsel je 6 m)", "<= 30 Grad", schlimm or "max %.1f" % max(zz.values()), not schlimm)
    br = wd["chaussee"]["bruecken"]
    brk = [(b["von"], b["bis"]) for b in br if b["typ"] == "steinbogen"][0]
    inwasser = []
    for w in wege:
        for (x, z) in resample([tuple(p) for p in w["punkte"]], 5.0):
            if abs(x - brk[0][0]) < 10 and brk[1][1] - 5 <= z <= brk[0][1] + 5:
                continue
            if w["id"] == "chaussee" and math.hypot(x - br[1]["mitte"][0], z - br[1]["mitte"][1]) < 14:
                continue
            if geo.rinne_abstand(x, z) < 0.5 and not (geo.bach_abstand(x, z) < 14 and w["id"] == "chaussee"):
                inwasser.append((w["id"], round(x), round(z)))
            elif geo.see_abstand(x, z) < 5 or geo.muehlteich_abstand(x, z) < 3:
                inwasser.append((w["id"], round(x), round(z)))
    T.add("Wegpunkte in Rinne/See/Teich (ausser Bruecken)", 0, "%d %s" % (len(inwasser), inwasser[:3]), not inwasser)
    T.add("Steinbogenbruecke Rotach: Felder/Boegen/Laenge", "5 / 5 / 125 m", "%s / %s / %s m" % (br[0]["brueckenfelder"], br[0]["boegen"], br[0]["laenge_m"]),
          br[0]["brueckenfelder"] == 5 and br[0]["boegen"] == 5 and br[0]["laenge_m"] == 125.0)
    # Gebaeude vs Wege
    wegfehl = []
    for x in geb:
        if x["typ"] in ("stadttor",):
            continue
        e, pts = footprint_punkte(x)
        for ww in wege:
            lim = ww["breite_m"] / 2.0 - 0.2
            if any(poly_abstand(p, [tuple(q) for q in ww["punkte"]])[0] < lim for p in pts):
                wegfehl.append((x["typ"], ww["id"], round(x["x"]), round(x["z"])))
                break
    T.add("Gebaeude auf Wegen (Footprint-Proben)", 0, "%d %s" % (len(wegfehl), wegfehl[:3]), not wegfehl)
    # Zusammenhang Wegenetz ueber Knoten
    kn = orte_j["_meta"]["kreuzungen"]
    uf = {w["id"]: w["id"] for w in wege}
    def find(a):
        while uf[a] != a:
            uf[a] = uf[uf[a]]
            a = uf[a]
        return a
    for k in kn:
        for a in k["wege"][1:]:
            uf[find(a)] = find(k["wege"][0])
    komp = {find(w["id"]) for w in wege}
    T.add("Wegenetz zusammenhaengend (Kreuzungen/Einmuendungen)", "1 Komponente", "%d, %d Knoten" % (len(komp), len(kn)), len(komp) == 1)
    pruefe_welt_daten(T, orte_j, wege, geo, inst)
    pruefe_platzierung(T, orte_j, inst, wege, dir_, strikt, baseline, liste)
    pruefe_allee(T, inst, wege)
    al = wd["chaussee"]["allee"]
    T.info("Allee: Abschnitte / Baeume / Laenge", "%d / %d / %.0f m" % (len(al), sum(1 for x in inst if x["parzelle"] == "allee"), sum(a["laenge_m"] for a in al)))
    # Chaussee Dorf-Kreuzung
    k0 = [k for k in kn if k["typ"] == "kreuzung4"]
    T.add("Kreuzung im Dorf (4-armig an Chaussee)", "1", len(k0), len(k0) == 1 and "chaussee" in k0[0]["wege"])

    # ---- Clark-Evans (nur Dorf: gemischt Haufendorf; Weiler n=6 und Markt geschlossene Zeilen nicht aussagekraeftig)
    ce = clark_evans([(p["x"], p["z"]) for p in orte_j["parzellen"]["erlenbach"] if p["status"] == "besetzt"])
    T.add("Clark-Evans Dorf (Hofstellen, n=%d)" % len([1 for p in orte_j["parzellen"]["erlenbach"] if p["status"] == "besetzt"]),
          "0.8..1.8 (kein Schachbrett > 2, keine Klumpung < 0.6)", "%.2f" % ce if ce else "n/a", ce is not None and 0.8 <= ce <= 1.8)
    T.info("Clark-Evans Weiler / Kleinstadt", "n/a (n=6 zu klein / geschlossene Zeilen)")

    # ---- Wachstum
    o12 = vn["monat12_ohne_versorgung"]
    m12 = vn["monat12_mit_versorgung"]
    T.add("Wachstum ohne Versorgung: stabil", "0 Aktionen, EW gleich", "%d Aktionen, EW %d -> %d" % (o12["aktionen_n"], vn["monat0"]["ew"], o12["ew"]),
          o12["aktionen_n"] == 0 and o12["ew"] == vn["monat0"]["ew"])
    T.add("Wachstum mit Versorgung: jeden Monat >= 1 Aktion", "12 Monate", sorted({a["monat"] for a in m12["aktionen"]}) == list(range(1, 13)) and "12 Monate" or "Luecke",
          sorted({a["monat"] for a in m12["aktionen"]}) == list(range(1, 13)))
    luecke_zuerst = [a["regel"] for a in m12["aktionen"]]
    erst_andere = luecke_zuerst.index("upgrade") if "upgrade" in luecke_zuerst else len(luecke_zuerst)
    T.add("Verdichten vor Ausdehnen: Luecken, dann Upgrade, dann Vorstadt", "keine Vorstadt vor offener Luecke",
          "Luecken %d, Upgrades %d, Vorstadt %d" % (luecke_zuerst.count("luecke"), luecke_zuerst.count("upgrade"), luecke_zuerst.count("vorstadt")),
          ("vorstadt" not in luecke_zuerst or m12["luecken_offen"] == []) and "luecke" not in luecke_zuerst[erst_andere:])
    # Monat-12-Szene pruefen
    ersetze = set(m12["ersetze_parzellen"])
    szene12 = [x for x in inst if x["ort"] == "erlenbach" and x["parzelle"] not in ersetze] + m12["neue_instanzen"]
    g12 = [x for x in szene12 if x["typ"] in HAUS_TYPEN and "b" in x]
    p12 = ueberlappungen(g12)
    T.add("Monat 12: Ueberlappungen", 0, len(p12), not p12)
    v12 = {}
    for x in g12:
        for k in gelaendefehler(geo, x, 15.0):
            v12.setdefault(k, 0)
            v12[k] += 1
    T.add("Monat 12: Gelaende (Rinne/See/Teich/Hang/Bach)", 0, v12 or 0, not v12)
    w12 = []
    for x in g12:
        e, pts = footprint_punkte(x)
        for ww in wege:
            lim = ww["breite_m"] / 2.0 - 0.2
            if any(poly_abstand(p, [tuple(q) for q in ww["punkte"]])[0] < lim for p in pts):
                w12.append(x["typ"])
                break
    T.add("Monat 12: Gebaeude auf Wegen", 0, len(w12), not w12)
    T.add("Monat 12: EW-Zuwachs = Summe ew_plus", "gleich", "%d vs %d" % (m12["ew"] - vn["monat0"]["ew"], sum(a["ew_plus"] for a in m12["aktionen"])),
          m12["ew"] - vn["monat0"]["ew"] == sum(a["ew_plus"] for a in m12["aktionen"]))
    # Budget (Information)
    n_geb = len(gebs)
    n_tri = n_geb * 600 + sum(1 for x in inst if x["typ"] in ("laubbaum", "eiche", "obstbaum")) * 300
    T.info("Instanzen gesamt / Gebaeude / Baeume", "%d / %d / %d" % (len(inst), n_geb, sum(1 for x in inst if x["typ"] in ("laubbaum", "eiche", "obstbaum"))))
    T.info("Dreiecke Orte grob (600 je Gebaeude, 300 je Baum)", "~%.2f M" % (n_tri / 1e6))
    return T


BASELINE_WA09 = os.path.join(os.path.dirname(os.path.abspath(__file__)), "stadt_baseline_wa09.json")


def liste_text(verst):
    z = []
    for r in REGELN:
        z.append("== %s: %d Verstoesse" % (r, len(verst[r])))
        for d in sorted(verst[r], key=lambda q: (q["ort"], q["typ"], q["x"], q["z"])):
            z.append("  %-9s %-15s @%8.1f,%8.1f  %s" % (d["ort"], d["typ"], d["x"], d["z"], d["text"]))
    return "\n".join(z)


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=OUT_DIR)
    ap.add_argument("--src", default=SRC_DEFAULT)
    ap.add_argument("--strikt", action="store_true", help="WA-09-Verstoesse (auch Baseline) zaehlen als FAIL (Ziel von WA-10)")
    ap.add_argument("--baseline", default=BASELINE_WA09, help="JSON mit bekannten WA-09-Verstoessen (Schluessel typ|x|z je Regel)")
    ap.add_argument("--baseline-schreiben", action="store_true", help="aktuelle WA-09-Verstoesse als Baseline nach --baseline schreiben")
    ap.add_argument("--liste", default="", help="WA-09-Verstoesse als Textliste in diese Datei schreiben (immer auch auf stdout, wenn '-')")
    a = ap.parse_args()
    bl = None
    if os.path.exists(a.baseline) and not a.baseline_schreiben:
        bl = json.load(open(a.baseline, encoding="utf-8")).get("regeln", {})
    verst = {}
    T = pruefen(a.dir, a.src, a.strikt, bl, verst)
    if a.baseline_schreiben:
        json.dump({"zweck": "WA-09 Baseline: bekannte Platzierungs-Verstoesse (Stand vor WA-10). Neue Verstoesse ausserhalb dieser Liste sind FAIL.",
                   "regeln": {r: sorted(d["key"] for d in verst[r]) for r in REGELN}},
                  open(a.baseline, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
        print("Baseline geschrieben:", a.baseline, {r: len(verst[r]) for r in REGELN})
    if a.liste:
        txt = liste_text(verst)
        if a.liste == "-":
            print(txt)
        else:
            open(a.liste, "w", encoding="utf-8").write(txt + "\n")
    T.drucken()
    n_ok = sum(1 for z in T.zeilen if z[3] == "OK")
    n_w = sum(1 for z in T.zeilen if z[3] == "WARN")
    print("\nErgebnis: %d OK, %d WARN, %d FAIL" % (n_ok, n_w, T.fehler))
    sys.exit(1 if T.fehler else 0)
