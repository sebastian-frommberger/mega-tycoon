#!/usr/bin/env python3
"""Wachstum (A10): Dorf Monat 0 -> Monat 12 nach den Stadt-KI-Regeln aus 05 Abschnitt 4 / 12_regelwerk_v1_1 (wachstum).
Verdichten vor Ausdehnen: 1 Luecke, 2 Upgrade, 3 Teilung (ab 1.000 EW, hier nie), 4 Vorstadt, 5 Gasse, 6 Platz.
Deterministisch: rng = PCG(hash(welt_seed, ort_id, monat)). Orte ohne Versorgung bleiben stabil (E7)."""
import copy
import math

from stadt_geo import PCG, r2
from stadt_bau import HAUS, Szene, GEBAEUDE_TYPEN

EW = {"kate": 5, "bauernhof": 8, "grosshof": 12, "handwerkerhaus": 7}
SIM_EW_START = 650          # Dorf typ. Sim-EW (05 Abschnitt 6)
RATE_BP = 180               # 180 bp/Monat bei Versorgung >= 80 % (economy wachstum)
RUHE_MONATE = 3             # Haus-Alter vor Upgrade
WOHNTYPEN = ("kate", "bauernhof", "grosshof", "handwerkerhaus")


def snapshot(ol, szene):
    geb = []
    for d in szene.inst:
        if d["ort"] == ol.id and d["typ"] in HAUS and d["typ"] in GEBAEUDE_TYPEN and d["typ"] != "stadttor":
            geb.append({"typ": d["typ"], "x": d["x"], "z": d["z"], "rot_deg": d["rot_deg"], "parzelle": d["parzelle"],
                        "ew": HAUS[d["typ"]][2]})
    return geb


def ort_ew(ol, szene):
    return sum(g["ew"] for g in snapshot(ol, szene))


def _nachbar_abstand(par, parz):
    return min(math.hypot(par["cx"] - q["cx"], par["cz"] - q["cz"]) for q in parz if q is not par)


def simuliere(ol, szene, mit_versorgung, monate=12, vorstadt_plan=None, welt_seed=7):
    """ol/szene: Kopien (werden veraendert). vorstadt_plan: Funktion(ol, rng) -> neue Parzelle (dict) oder None.
    Gibt dict mit Verlauf und Aktionen zurueck."""
    ew0 = ort_ew(ol, szene)
    umland = SIM_EW_START - ew0
    sim = float(SIM_EW_START)
    alter = {}
    for p in ol.parz:
        alter[p["id"]] = 99 if p["status"] == "besetzt" else 0
    verlauf = []
    aktionen = []
    inst_start = len(szene.inst)
    for m in range(1, monate + 1):
        ist = ort_ew(ol, szene)
        if mit_versorgung:
            sim *= 1.0 + RATE_BP / 10000.0
            soll = sim - umland
        else:
            soll = ist            # stabil auf Startgroesse, kein Schrumpfen
        defizit = soll - ist
        max_a = 1 + int(soll // 500)      # Regelwerk: max 1 + ort_ew_soll / 500 (ganzzahlig)
        n_akt = max(0, min(int(math.ceil(defizit / 8.0)) if defizit > 0 else 0, max_a))
        if mit_versorgung and n_akt == 0 and defizit > 0:
            n_akt = 1     # sichtbare Aktion jeder positiven Rate (Garantie 05 4b)
        rng = PCG(PCG.hash_seed(welt_seed, ol.id, m))
        for a in range(n_akt):
            ist = ort_ew(ol, szene)
            akt = _aktion(ol, szene, rng, m, ist, alter, vorstadt_plan)
            if akt is None:
                break
            aktionen.append(akt)
        for k in list(alter):
            alter[k] += 1
        verlauf.append({"monat": m, "sim_ew": round(sim, 1) if mit_versorgung else SIM_EW_START, "ort_soll": round(soll, 1),
                        "ort_ist": ort_ew(ol, szene), "aktionen": n_akt})
    return {"ew_start": ew0, "umland_ew": umland, "verlauf": verlauf, "aktionen": aktionen, "inst_ab": inst_start}


def _entferne_parzelle(szene, pid):
    szene.inst[:] = [d for d in szene.inst if not (d["parzelle"] == pid and (d["typ"] in GEBAEUDE_TYPEN or d["typ"] in
                     ("zaun_latte", "heuhaufen", "holzstapel", "fass") or d["typ"].startswith("flaeche_") or d["typ"] == "obstbaum"))]
    szene.foot[:] = [f for f in szene.foot if f[2] != pid]


def _aktion(ol, szene, rng, monat, ist, alter, vorstadt_plan):
    parz = ol.parz
    # 1 LUECKE: leere Parzelle, nahe am Kern zuerst
    luecken = sorted([p for p in parz if p["status"] == "luecke"], key=lambda p: ol.d_kern((p["cx"], p["cz"])))
    if luecken:
        p = luecken[0]
        _entferne_parzelle(szene, p["id"])
        typ = p["typ"] if p["typ"] in WOHNTYPEN else "kate"
        ol.besetzen(p, typ, seed_zusatz="m%d" % monat)
        alter[p["id"]] = 0
        return {"monat": monat, "regel": "luecke", "parzelle": p["id"], "typ_alt": None, "typ_neu": typ, "x": p["cx"], "z": p["cz"],
                "ew_plus": EW[typ]}
    # 2 UPGRADE (Haus-Alter >= 3 Monate)
    kand = []
    for p in parz:
        if p["status"] != "besetzt" or p.get("sonder") or alter.get(p["id"], 0) < RUHE_MONATE:
            continue
        if p["typ"] == "kate" and ist >= 300:
            kand.append((p, "handwerkerhaus", 2))
        elif p["typ"] == "bauernhof" and ist >= 250 and _nachbar_abstand(p, parz) >= 30.0:
            kand.append((p, "grosshof", 4))
    if kand:
        kand.sort(key=lambda t: ol.d_kern((t[0]["cx"], t[0]["cz"])))
        # Gewicht: naeher am Kern bevorzugt, Zufall unter den 3 naechsten
        p, neu, plus = kand[rng.randint(0, min(2, len(kand) - 1))]
        alt = p["typ"]
        _entferne_parzelle(szene, p["id"])
        ol.besetzen(p, neu, seed_zusatz="m%d" % monat)
        alter[p["id"]] = 0
        return {"monat": monat, "regel": "upgrade", "parzelle": p["id"], "typ_alt": alt, "typ_neu": neu, "x": p["cx"], "z": p["cz"],
                "ew_plus": plus}
    # 4 VORSTADT: neue Hofstelle am Ende einer Ausfallstrasse
    if vorstadt_plan is not None:
        par = vorstadt_plan(ol, rng)
        if par is not None:
            typ = par["typ"]
            ol.besetzen(par, typ, seed_zusatz="m%d" % monat)
            alter[par["id"]] = 0
            return {"monat": monat, "regel": "vorstadt", "parzelle": par["id"], "typ_alt": None, "typ_neu": typ, "x": par["cx"],
                    "z": par["cz"], "ew_plus": EW[typ]}
    return None


def kopie(ol, szene):
    """Tiefe Kopie von Ortslage und Szene fuer den Simulationslauf (Ortslage haengt an der Szene)."""
    s2 = copy.deepcopy(szene)
    ol2 = copy.copy(ol)
    ol2.szene = s2
    ol2.parz = copy.deepcopy(ol.parz)
    ol2.parz_ecken = list(ol.parz_ecken)
    ol2.rng = copy.deepcopy(ol.rng)
    return ol2, s2
