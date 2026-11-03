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


def pruefen(dir_, src):
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
    T.add("Gutshof Vierseithof 40 x 40", "1x", [(x["b"], x["t"]) for x in inst if x["typ"] == "gutshof"], len([x for x in inst if x["typ"] == "gutshof" and x["b"] == 40.0]) == 1)
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


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", default=OUT_DIR)
    ap.add_argument("--src", default=SRC_DEFAULT)
    a = ap.parse_args()
    T = pruefen(a.dir, a.src)
    T.drucken()
    n_ok = sum(1 for z in T.zeilen if z[3] == "OK")
    n_w = sum(1 for z in T.zeilen if z[3] == "WARN")
    print("\nErgebnis: %d OK, %d WARN, %d FAIL" % (n_ok, n_w, T.fehler))
    sys.exit(1 if T.fehler else 0)
