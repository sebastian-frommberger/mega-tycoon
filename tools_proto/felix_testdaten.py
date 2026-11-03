#!/usr/bin/env python3
"""Felix, Phase 4 Welle 1: kleine Testdaten fuer die Prototyp-Szene, solange TA/Stadt noch nicht geliefert haben.

Schreibt nach slice/proto/testdaten/ (NICHT in den Vertragsordner slice/world/data/proto/):
  proto_orte.json, proto_instanzen.json, proto_wege.json   Format laut VERTRAG.md (Stadt-Rolle)
  proto_fluss.u8 (160x144, Bits 1 Rinne / 2 Aue)          Ausschnitt aus ws_c/_out/ds_v2/fluss_s7.u8 (nur Lesen)
  proto_see.json, proto_bach.json                          aus p4/shared/ausschnitt_vorgabe.json
Deterministisch (Seed 7, keine Zeitstempel). Koordinaten lokal in Metern, Ursprung NW-Ecke Kern, +x Ost, +z Sued.
Aufruf: python3 -I tools_proto/felix_testdaten.py   (aus der Repo-Wurzel der Arbeitskopie)
"""
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, "slice", "proto", "testdaten")
VORGABE = "/tmp/claude-0/gd/designsprint/p4/shared/ausschnitt_vorgabe.json"
WS_C = "/tmp/claude-0/gd/designsprint/ws_c/_out/ds_v2/fluss_s7.u8"

rng = random.Random(7)


def dump(name, obj):
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)
        f.write("\n")


def fluss_ausschnitt(v):
    fe = v["fenster"]
    r0 = fe["kern_zeile0"] - fe["rand_felder"]
    c0 = fe["kern_spalte0"] - fe["rand_felder"]
    w, h = fe["gesamt_felder"]
    src = open(WS_C, "rb").read()
    out = bytearray(w * h)
    for r in range(h):
        for c in range(w):
            out[r * w + c] = src[(r0 + r) * 512 + (c0 + c)]
    open(os.path.join(OUT, "proto_fluss.u8"), "wb").write(bytes(out))
    return w, h, out


# --- Wege (Annahme Felix: Markt noerdlich des Flusses, Dorf suedlich am See, Weiler am Bach)
CHAUSSEE_A = [[-400, -50], [200, 150], [600, 230], [900, 260], [1400, 250], [1800, 150], [2200, -200]]
CHAUSSEE_B = [[900, 260], [880, 450], [860, 620], [820, 820], [720, 1000], [650, 1300], [600, 1800], [600, 2200]]
# Dorfstrasse als Feldmitten-Treppe (25-m-Raster wie die Sim), damit die Glaettung "Treppe -> Diagonale" geprueft wird
def treppe(a, b, n):
    pts = [list(a)]
    x, z = a
    dx = (b[0] - a[0]) / n
    dz = (b[1] - a[1]) / n
    for _ in range(n):
        x += dx
        pts.append([round(x, 1), round(z, 1)])
        z += dz
        pts.append([round(x, 1), round(z, 1)])
    return pts

def feldtreppe(a, schritte):
    """Feldmitten-Pfad wie die Sim (A*, nur waagrecht/senkrecht, 25 m): O = Ost, S = Sued."""
    pts = [list(a)]
    x, z = a
    for c in schritte:
        if c == "O":
            x += 25.0
        else:
            z += 25.0
        pts.append([x, z])
    return pts

DORF = (700.0, 1060.0)
WEGE = [
    {"typ": "chaussee", "punkte": CHAUSSEE_A, "breite_m": 11.0},
    {"typ": "chaussee", "punkte": CHAUSSEE_B, "breite_m": 11.0},
    {"typ": "dorfstrasse", "punkte": [[720, 1000], [612.5, 1037.5], [562.5, 1112.5], [537.5, 1187.5]], "breite_m": 6.0},
    {"typ": "dorfstrasse", "punkte": feldtreppe((720, 1000), "OSOOSOOSO"), "breite_m": 6.0},
    {"typ": "feldweg", "punkte": [[870, 1075], [930, 1050], [985, 1030]], "breite_m": 3.5},
    {"typ": "gasse", "punkte": [[900, 260], [960, 205], [1030, 175]], "breite_m": 5.0},
    {"typ": "dorfstrasse", "punkte": [[1400, 250], [1520, 700], [1600, 1100], [1700, 1350]], "breite_m": 6.0},
]

ORTE = [
    {"id": "markt", "name": "Lindach", "klasse": "kleinstadt", "ew": 2400, "x": 930.0, "z": 230.0, "r_m": 220},
    {"id": "dorf", "name": "Haberau", "klasse": "dorf", "ew": 250, "x": DORF[0], "z": DORF[1], "r_m": 160},
    {"id": "weiler", "name": "Bachhof", "klasse": "weiler", "ew": 40, "x": 1700.0, "z": 1360.0, "r_m": 70},
]


def entlang(punkte, abstand, versatz, typen, parzelle, start=10.0, ende=10.0):
    """Haeuser beidseits einer Polylinie, Giebel zur Strasse (rot_deg = Godot-Y-Drehung)."""
    out = []
    for i in range(len(punkte) - 1):
        a, b = punkte[i], punkte[i + 1]
        dx, dz = b[0] - a[0], b[1] - a[1]
        L = math.hypot(dx, dz)
        if L < 1:
            continue
        ux, uz = dx / L, dz / L
        nx, nz = uz, -ux
        s = start
        while s < L - ende:
            for side in (-1, 1):
                if rng.random() < 0.18:
                    continue
                t = rng.choice(typen)
                o = versatz + rng.uniform(-1.5, 2.5)
                x = a[0] + ux * s + nx * o * side
                z = a[1] + uz * s + nz * o * side
                rot = math.degrees(math.atan2(ux, uz)) + rng.choice([0, 90])
                out.append({"typ": t, "x": round(x, 2), "z": round(z, 2), "rot_deg": round(rot, 1), "parzelle": "%s_%d" % (parzelle, len(out))})
            s += abstand * rng.uniform(0.85, 1.25)
    return out


def instanzen(fluss, w, h):
    inst = []
    # Dorf ~ 250 EW: Hoefe, Katen, Handwerker entlang der Dorfstrassen und der Chaussee
    inst += entlang(WEGE[2]["punkte"], 32, 16, ["bauernhof", "bauernhof", "kate", "handwerkerhaus"], "dorf_w")
    inst += entlang([[720, 1000], [870, 1075]], 30, 15, ["bauernhof", "kate", "grosshof", "handwerkerhaus"], "dorf_o")
    inst += entlang([[820, 820], [720, 1000], [650, 1300]], 34, 17, ["bauernhof", "kate", "handwerkerhaus"], "dorf_c", 60, 60)
    inst += [
        {"typ": "kirche_dorf", "x": 690.0, "z": 1080.0, "rot_deg": 90.0, "parzelle": "dorf_kirche"},
        {"typ": "gasthaus", "x": 742.0, "z": 1018.0, "rot_deg": 20.0, "parzelle": "dorf_gast"},
        {"typ": "schmiede", "x": 840.0, "z": 800.0, "rot_deg": 15.0, "parzelle": "dorf_schmiede"},
        {"typ": "scheune", "x": 600.0, "z": 1010.0, "rot_deg": 70.0, "parzelle": "dorf_scheune"},
        {"typ": "pfarrhaus", "x": 668.0, "z": 1105.0, "rot_deg": 90.0, "parzelle": "dorf_pfarr"},
    ]
    # Markt-Ausschnitt: Markt 60x80 frei, Rand aus Buergerhaeusern, Stadtkirche, Rathaus, 1 Tor, 1 Gasse
    mx, mz = 930.0, 230.0
    for i in range(6):
        inst.append({"typ": "buergerhaus", "x": mx - 25 + i * 10.5, "z": mz - 50, "rot_deg": 0.0, "parzelle": "markt_n%d" % i})
        inst.append({"typ": "buergerhaus", "x": mx - 25 + i * 10.5, "z": mz + 50, "rot_deg": 180.0, "parzelle": "markt_s%d" % i})
    for i in range(6):
        inst.append({"typ": "buergerhaus", "x": mx - 40, "z": mz - 30 + i * 12, "rot_deg": 90.0, "parzelle": "markt_w%d" % i})
        if i != 2:
            inst.append({"typ": "handwerkerhaus", "x": mx + 40, "z": mz - 30 + i * 12, "rot_deg": -90.0, "parzelle": "markt_o%d" % i})
    inst += [
        {"typ": "kirche_stadt", "x": mx + 10, "z": mz - 85, "rot_deg": 90.0, "parzelle": "markt_kirche"},
        {"typ": "rathaus", "x": mx, "z": mz, "rot_deg": 0.0, "parzelle": "markt_rathaus"},
        {"typ": "stadttor", "x": 880.0, "z": 455.0, "rot_deg": 0.0, "parzelle": "markt_tor"},
        {"typ": "speicher", "x": 990.0, "z": 300.0, "rot_deg": 10.0, "parzelle": "markt_speicher"},
        {"typ": "brunnen", "x": mx - 15, "z": mz + 15, "rot_deg": 0.0, "parzelle": "markt_brunnen"},
    ]
    inst += entlang(WEGE[5]["punkte"], 11, 9, ["handwerkerhaus", "buergerhaus"], "gasse", 15, 5)
    inst += entlang([[600, 230], [830, 255]], 14, 12, ["handwerkerhaus", "buergerhaus", "kate"], "markt_w", 5, 5)
    # Weiler
    inst += entlang([[1600, 1100], [1700, 1350]], 45, 18, ["bauernhof", "kate"], "weiler")
    inst.append({"typ": "kapelle", "x": 1690.0, "z": 1390.0, "rot_deg": 20.0, "parzelle": "weiler_kapelle"})
    # Industrie: Gutshof, Wassermuehle am Bach
    inst += [
        {"typ": "gutshof", "x": 300.0, "z": 1250.0, "rot_deg": 10.0, "parzelle": "gutshof"},
        {"typ": "wassermuehle", "x": 1490.0, "z": 760.0, "rot_deg": 0.0, "parzelle": "muehle"},
    ]
    # See-Nutzung (M14): Steg 25 x 2 am Westufer, Fischerhuette, Ruderboot
    sx = 1212.5 - 250.0
    inst += [
        {"typ": "steg", "x": sx + 10.0, "z": 1012.5, "rot_deg": 90.0, "parzelle": "see_steg"},
        {"typ": "fischerhuette", "x": sx - 14.0, "z": 1030.0, "rot_deg": 90.0, "parzelle": "see_fischer"},
        {"typ": "ruderboot", "x": sx + 18.0, "z": 1016.5, "rot_deg": 0.0, "parzelle": "see_boot"},
    ]
    # Messobjekte (statisch): Fuhrwerk, Postkutsche, Lok + Tender + 2 Wagen am Dorfrand
    inst += [
        {"typ": "fuhrwerk_2_pferde", "x": 770.0, "z": 905.0, "rot_deg": 28.0, "parzelle": "mess"},
        {"typ": "postkutsche_4_pferde", "x": 893.0, "z": 330.0, "rot_deg": 5.0, "parzelle": "mess"},
        {"typ": "dampflok", "x": 300.0, "z": 1400.0, "rot_deg": 0.0, "parzelle": "mess_zug"},
        {"typ": "tender", "x": 300.0, "z": 1406.0, "rot_deg": 0.0, "parzelle": "mess_zug"},
        {"typ": "personenwagen", "x": 300.0, "z": 1413.0, "rot_deg": 0.0, "parzelle": "mess_zug"},
        {"typ": "gueterwagen", "x": 300.0, "z": 1421.0, "rot_deg": 0.0, "parzelle": "mess_zug"},
    ]
    # Baeume: Ufergehoelz am See, Obst im Dorf, Laubwald-Inseln (nicht im Wasser)
    def nass(x, z):
        c = int((x + 1000) // 25)
        r = int((z + 1000) // 25)
        if 0 <= c < w and 0 <= r < h:
            return fluss[r * w + c] & 1
        return 0
    for k in range(70):
        a = rng.uniform(0, 2 * math.pi)
        rr = 250 + rng.uniform(8, 35)
        x, z = 1212.5 + math.cos(a) * rr, 1012.5 + math.sin(a) * rr
        if abs(z - 1012.5) < 20 and x < 1100:
            continue
        inst.append({"typ": rng.choice(["laubbaum", "eiche"]), "x": round(x, 1), "z": round(z, 1), "rot_deg": round(rng.uniform(0, 360), 1), "parzelle": "ufer"})
    for k in range(40):
        x, z = DORF[0] + rng.uniform(-150, 150), DORF[1] + rng.uniform(-120, 160)
        inst.append({"typ": "obstbaum", "x": round(x, 1), "z": round(z, 1), "rot_deg": 0.0, "parzelle": "streuobst"})
    for cx, cz in [(150, 700), (2300, 1200), (1900, 600), (-300, 1500)]:
        for k in range(60):
            x, z = cx + rng.gauss(0, 70), cz + rng.gauss(0, 50)
            if nass(x, z):
                continue
            inst.append({"typ": rng.choice(["laubbaum", "laubbaum", "eiche", "nadelbaum"]), "x": round(x, 1), "z": round(z, 1), "rot_deg": round(rng.uniform(0, 360), 1), "parzelle": "wald"})
    return inst


def main():
    os.makedirs(OUT, exist_ok=True)
    v = json.load(open(VORGABE, encoding="utf-8"))
    w, h, fluss = fluss_ausschnitt(v)
    dump("proto_orte.json", {"orte": ORTE, "_quelle": "Felix-Testdaten (Platzhalter bis Stadt liefert)"})
    dump("proto_wege.json", WEGE)
    dump("proto_instanzen.json", instanzen(fluss, w, h))
    dump("proto_see.json", dict(v["see"], _quelle="ausschnitt_vorgabe.json"))
    dump("proto_bach.json", {"polyline_m": v["bach_polyline_m"], "_quelle": "ausschnitt_vorgabe.json"})
    print("Testdaten geschrieben nach", OUT)


if __name__ == "__main__":
    sys.exit(main())
