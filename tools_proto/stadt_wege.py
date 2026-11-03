#!/usr/bin/env python3
"""Wegenetz der Prototyp-Welt (Stadt-Rolle, Welle 1). Alles deterministisch (A*, Spline, keine Zufallszahlen)."""
import math

from stadt_geo import (astar, catmull_rom, min_radius, poly_laenge, resample, vereinfachen, r2, poly_abstand)

# feste Ankerpunkte (lokale Meter) - Begruendung in der Doku
BRUECKE_X = 1290.0            # gerade Strecke des Flusses x 1112-1312, Rinne 75 m (3 Felder), Achse N-S
BRUECKE_S = (BRUECKE_X, 650.0)   # Suedwiderlager = Ende der Suedrampe
BRUECKE_N = (BRUECKE_X, 525.0)   # Nordwiderlager
BRUECKE_LAENGE = 125.0        # 5 Brueckenfelder: ceil(75/25)=3 + 1 Rampe je Seite = 5 -> 125 m
RINNE_BREITE = 75.0
KREUZUNG_DORF = (1625.0, 730.0)


def _sperre_chaussee(geo):
    def sperre(x, z):
        th = 55.0
        if abs(x - BRUECKE_X) < 90 and 470 < z < 706:
            th = 20.0
        if geo.rinne_abstand(x, z) < th:
            return True
        if geo.see_abstand(x, z) < 50:
            return True
        if geo.muehlteich_abstand(x, z) < 30:
            return True
        return False
    return sperre


def _zusatz_chaussee(geo):
    def zus(x, z):
        c = 0.0
        if geo.in_aue(x, z):
            c += 0.25
        d = geo.rinne_abstand(x, z)
        if d < 130:
            c += 0.45 * (130 - d) / 130
        return c
    return zus


def glatt(punkte, schritt=6.0, pro_seg=10):
    return resample(catmull_rom(punkte, pro_seg), schritt)


def route(geo, start, ziel, sperre, zusatz, tol=22.0, schritt=6.0, max_steig=0.12):
    """A* -> vereinfachen -> Catmull-Rom -> abtasten. Gibt (polylinie, kontrollpunkte)."""
    pfad = astar(geo, start, ziel, sperre, zusatz, max_steig=max_steig)
    if pfad is None:
        raise RuntimeError("Kein Weg %s -> %s" % (start, ziel))
    kp = vereinfachen(pfad, tol)
    return glatt(kp, schritt), kp


def steigungsprofil(geo, poly, schritt=5.0, bruecken=()):
    """Liefert (max_prozent, mittel_prozent, laenge) ueber die Polylinie; bruecken = Liste von (idx_von, idx_bis) auf der
    abgetasteten Polylinie, die ausgenommen werden."""
    pts = resample(poly, schritt)
    mx = 0.0
    sm = 0.0
    n = 0
    for k in range(len(pts) - 1):
        a, b = pts[k], pts[k + 1]
        mx_mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        skip = False
        for (z0, z1, x0, x1) in bruecken:
            if x0 - 1 <= mx_mid[0] <= x1 + 1 and z0 - 1 <= mx_mid[1] <= z1 + 1:
                skip = True
        if skip:
            continue
        d = math.hypot(b[0] - a[0], b[1] - a[1])
        s = abs(geo.hoehe(*b) - geo.hoehe(*a)) / d * 100.0
        mx = max(mx, s)
        sm += s
        n += 1
    return mx, (sm / n if n else 0.0), poly_laenge(poly)
