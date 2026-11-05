#!/usr/bin/env python3
"""WA-08 (Stadt, S8 Block B): Ladeplatz je Betrieb und Ort. Rein geometrisch, kein Zufall -> bestehende Zufallsstroeme bleiben unberuehrt.

Regel (Design L1, UX LP-1):
  * Der Ladeplatz liegt am Wegende (Sackgasse, Grad 1). Das Gespann faehrt bis zum Wegende, die Fahrzeugmitte haelt `halt_rand` davor
    (ProtoEasing: halbe Laenge + 0,3 m Luft), das Heck steht damit `HECK_M` = Laenge + 0,3 m vor dem Wegende.
  * Datenpunkt `ladeplatz.x/z` = dieser Heck-Halt-Punkt (liegt auf dem Weg, also 0 m vom Netz; Heck-Abstand zum Ladeplatz im Sollfall 0 m).
  * Daneben, seitlich vom Heck: Kies-Hof (10 x 9 m), Rampe (3 x 2 m), Lagerhaufen (3 x 3 m, 3 Fuellstufen). Nur Daten; Modelle macht Sophie.
  * Hat der Betrieb/Ort kein passendes Wegende, entsteht ein Ladestich (Feldweg 3,5 m) von einem vorhandenen Weg. Laenge 2 x HECK_M + 1,5 m:
    ProtoSim.knoten_halt(Datenpunkt) nimmt das naechste Wegende/Kreuzungsknoten <= 40 m; der Datenpunkt (Heck) muss naeher am Wegende liegen
    als an der Einmuendung, sonst haelt das Gespann auf dem Stammweg.
Suche: alle Kandidaten (vorhandene Wegenden, Stichansaetze alle 4 m an jedem Stammweg) nach Abstand zum Ziel sortiert, erster zulaessiger gewinnt.
"""
import math

from stadt_geo import obb_ecken, obb_ueberlappt, poly_abstand, punkt_in_obb, r2
from stadt_bau import Weg, rot_zu

import os
DEBUG = bool(os.environ.get("LP_DEBUG"))
HALT_LUFT_M = 0.3            # proto_easing.gd HALT_LUFT_M
KIES = (9.0, 10.0)           # b quer, t laengs (m)
RAMPE = (3.0, 2.0)           # b laengs zum Weg, t quer
HAUFEN = (3.0, 3.0)
QUER_RAMPE = 4.0             # seitlicher Abstand Rampenmitte - Wegachse
QUER_HAUFEN = 4.4
LAENGS_RAMPE = 2.0           # Rampenmitte vor Heck (Richtung Wegende)
LAENGS_HAUFEN = 6.0
STICH_BREITE = 3.5
# Easing (proto_easing.routenlinie_bauen): Kurvenbogen-Tangente t <= 0,45 x Abstand zum naechsten Wegwechsel/Routenende. Fuer einen 90-Grad-Bogen mit
# R >= r_min Fuhrwerk (11 m) braucht der Stich >= 11/0,45 = 24,4 m, der Weg davor ebenso -> Stich >= 28 m, Abstand zu anderen Knoten >= 32 m.
STICH_LAENGE_MIN = 28.0
STICH_KNOTEN_MIN = 32.0
STICH_ZUSCHLAG = 100.0   # m Zuschlag: ein Sackgassen-Wegende mit langer Anfahrt ist fuer die Fahrzeugkinematik (proto_easing E3/E5) besser als ein kurzer 90-Grad-Stich
STICH_MARGE = 1.5            # Heck bleibt so weit vom Rand der Stammbahn weg
MAX_STEIG_PCT = 8.0
FUELLSTUFEN_GRENZEN = [0.0, 0.34, 0.67]      # Anteil Bestand/Kapazitaet: Stufe 1 ab > 0, Stufe 2 ab 0,34, Stufe 3 ab 0,67; Stufe 0 = kein Haufen
ENTFERNBAR = {"obstbaum", "laubbaum", "eiche", "nadelbaum", "busch"}     # Baeume im Ladeplatz werden entfernt, Props/Gebaeude sind Hindernisse
FLAECHEN_HINDERNIS = {"flaeche_garten", "flaeche_kirchhof", "flaeche_obstwiese", "flaeche_schlag"}


def heck_m(regelwerk):
    """Abstand Heck - Wegende (m): Fuhrwerk-Laenge (skalen.fahrzeuge_dm.fuhrwerk_2_pferde.l) + Luft."""
    l = float(regelwerk["skalen"]["fahrzeuge_dm"]["fuhrwerk_2_pferde"]["l"]) / 10.0
    return l + HALT_LUFT_M


def _norm(v):
    L = math.hypot(v[0], v[1])
    return (v[0] / L, v[1] / L)


def _ende_richtung(punkte, schritt=6.0):
    """Einheitsvektor am Ende der Polylinie (in Fahrtrichtung zum Ende) ueber etwa `schritt` m."""
    e = punkte[-1]
    for p in reversed(punkte[:-1]):
        if math.hypot(e[0] - p[0], e[1] - p[1]) >= schritt:
            return _norm((e[0] - p[0], e[1] - p[1]))
    p = punkte[0]
    return _norm((e[0] - p[0], e[1] - p[1]))


def _obb(c, d, b_quer, t_laengs):
    """OBB mit t laengs d (lokales +z = d)."""
    return obb_ecken(c[0], c[1], b_quer, t_laengs, rot_zu(d[0], d[1]))


def gestalt(E, d, s, heck):
    """Alle Footprints eines Ladeplatzes am Wegende E (Richtung d), Seite s = +-1. n = (-dz, dx) * s zeigt zur Rampenseite."""
    n = (-d[1] * s, d[0] * s)
    P = (E[0] - d[0] * heck, E[1] - d[1] * heck)

    def pos(laengs, quer):
        return (P[0] + d[0] * laengs + n[0] * quer, P[1] + d[1] * laengs + n[1] * quer)
    zu_weg = rot_zu(-n[0], -n[1])        # Fassade der Rampe/des Haufens zeigt zur Wegachse
    kies_c = (E[0] - d[0] * (KIES[1] * 0.5 - 0.5) + n[0] * 2.0, E[1] - d[1] * (KIES[1] * 0.5 - 0.5) + n[1] * 2.0)
    rc, hc = pos(LAENGS_RAMPE, QUER_RAMPE), pos(LAENGS_HAUFEN, QUER_HAUFEN)
    return dict(P=P, n=n, kies=dict(c=kies_c, rot=rot_zu(d[0], d[1]), b=KIES[0], t=KIES[1]),
                rampe=dict(c=rc, rot=zu_weg, b=RAMPE[0], t=RAMPE[1]), haufen=dict(c=hc, rot=zu_weg, b=HAUFEN[0], t=HAUFEN[1]))


def _ecken(f):
    return obb_ecken(f["c"][0], f["c"][1], f["b"], f["t"], f["rot"])


def _proben(ecken, n=3):
    pts = []
    for i in range(n + 1):
        for j in range(n + 1):
            a, b = i / n, j / n
            pts.append(((1 - a) * ((1 - b) * ecken[0][0] + b * ecken[3][0]) + a * ((1 - b) * ecken[1][0] + b * ecken[2][0]),
                        (1 - a) * ((1 - b) * ecken[0][1] + b * ecken[3][1]) + a * ((1 - b) * ecken[1][1] + b * ecken[2][1])))
    return pts


class Planer:
    def __init__(self, geo, szene, wo, regelwerk, parz_ecken):
        self.geo, self.szene, self.wo = geo, szene, wo
        self.heck = heck_m(regelwerk)
        self.hindernis = [e for (e, t, p, o) in szene.foot]
        self.hindernis += [obb_ecken(d["x"], d["z"], d["b"], d["t"], d["rot_deg"]) for d in szene.inst
                           if d["typ"] in FLAECHEN_HINDERNIS and "b" in d]
        self.hindernis += list(parz_ecken)
        self.punkt_hind = [(d["x"], d["z"]) for d in szene.inst if "b" not in d and d["typ"] not in ENTFERNBAR]
        self.neu = []

    # ---- Pruefungen
    def _gelaende_ok(self, ecken):
        g = self.geo
        for (x, z) in _proben(ecken, 3):
            if g.rinne_abstand(x, z) < 3.0 or g.see_abstand(x, z) < 10.0 or g.muehlteich_abstand(x, z) < 8.0 or g.bach_abstand(x, z) < 8.0:
                return False
            if g.steigung(x, z) > MAX_STEIG_PCT:
                return False
        return True

    def _frei(self, ecken, rand=0.5, ignoriere=()):
        for k, h in enumerate(self.hindernis):
            if k in ignoriere:
                continue
            if obb_ueberlappt(_aufblasen(ecken, rand), h):
                if DEBUG:
                    print("      hindernis", k, [(round(a), round(b)) for a, b in h])
                return False
        for q in self.punkt_hind:
            if punkt_in_obb(q, _aufblasen(ecken, 1.0)):
                if DEBUG:
                    print("      punkt", q)
                return False
        return True

    def _wege_frei(self, ecken, eigener, ausser=()):
        """Kies/Rampe/Haufen duerfen keine fremde Fahrbahn ueberdecken (eigener Weg und Stammweg des Stichs ausgenommen)."""
        for p in _proben(ecken, 4):
            for wid, w in self.wo.items():
                if wid == eigener or wid in ausser:
                    continue
                if poly_abstand(p, w.punkte)[0] < w.breite / 2.0 + 0.3:
                    return False
        return True

    def _steig_ok(self, a, b):
        n = max(2, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 3.0))
        for i in range(n + 1):
            x, z = a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n
            if self.geo.steigung(x, z) > MAX_STEIG_PCT:
                return False
        return True

    def _pruefe(self, E, d, s, eigener, ausser=(), band=None):
        f = gestalt(E, d, s, self.heck)
        ke = _ecken(f["kies"])
        for teil in ("kies", "rampe", "haufen"):
            e = _ecken(f[teil])
            g_ok, fr, wf = self._gelaende_ok(e), self._frei(e), self._wege_frei(e, eigener, ausser)
            if DEBUG and not (g_ok and fr and wf):
                print("   ladeplatz verworfen", teil, "s=%d" % s, "E=(%.1f,%.1f)" % E, "gelaende", g_ok, "frei", fr, "wege", wf)
            if not (g_ok and fr and wf):
                return None
        if band is not None and not (self._frei(band, 0.5)):
            return None
        return f

    # ---- Kandidaten
    def _wegenden(self, ids):
        """Vorhandene Sackgassen: Weg-Endpunkte, an denen kein anderer Weg anliegt (Fang 8 m)."""
        out = []
        for wid in ids:
            w = self.wo[wid]
            for ende in ("start", "ende"):
                p = w.punkte[0] if ende == "start" else w.punkte[-1]
                if any(wj != wid and poly_abstand(p, self.wo[wj].punkte)[0] < 8.0 for wj in self.wo):
                    continue
                pts = w.punkte if ende == "ende" else list(reversed(w.punkte))
                out.append((wid, p, _ende_richtung(pts)))
        return out

    def plane(self, ziel, bezug_ecken=None, max_dist=120.0, vorhandene=True, stamm_ok=None, ausser_ids=(), bevorzugt=None):
        """ziel: (x, z) Ortsmitte oder Gebaeudemitte. bezug_ecken: Footprint des Betriebs (Abstand zum Rand zaehlt).
        Rueckgabe dict(E, d, s, f, wid (Weg am Ende), stich (Weg-Objekt oder None), stamm, score)."""
        def abstand(p):
            if bezug_ecken is None:
                return math.hypot(p[0] - ziel[0], p[1] - ziel[1])
            return _rand_abstand(p, bezug_ecken)
        kand = []
        if vorhandene:
            for (wid, E, d) in self._wegenden(bevorzugt or list(self.wo.keys())):
                if wid in ausser_ids:
                    continue
                dist = abstand(E)
                if dist <= max_dist:
                    kand.append((dist, 0, wid, E, d, None))
        # Ladestiche
        for wid in (stamm_ok or list(self.wo.keys())):
            w = self.wo[wid]
            if wid in ausser_ids:
                continue
            pts = _abtasten(w.punkte, 4.0)
            for (A, t) in pts:
                if _zu_nah_an_knoten(self.wo, wid, A, STICH_KNOTEN_MIN):
                    continue
                ls = max(2.0 * self.heck + STICH_MARGE, STICH_LAENGE_MIN)      # naechster Knoten vom Datenpunkt (Heck) muss das Wegende sein, nicht die Einmuendung
                for sg in (1, -1):
                    for dw in (0.0, 20.0, -20.0):
                        a = math.atan2(t[1], t[0]) + sg * math.pi / 2.0 + math.radians(dw)
                        d = (math.cos(a), math.sin(a))
                        E = (A[0] + d[0] * ls, A[1] + d[1] * ls)
                        dist = abstand(E)
                        if dist <= max_dist:
                            kand.append((dist + STICH_ZUSCHLAG, 1, wid, E, d, A))      # Stich kostet Zuschlag gegen vorhandene Wegenden
        if DEBUG:
            print('   kandidaten', [(round(k[0]), k[1], k[2]) for k in sorted(kand, key=lambda k: k[0])[:6]])
        kand.sort(key=lambda k: (round(k[0], 3), k[1], k[2], round(k[3][0], 2), round(k[3][1], 2), round(k[4][0], 3)))
        for (score, typ, wid, E, d, A) in kand:
            for s in (1, -1):
                if typ == 0:
                    f = self._pruefe(E, d, s, wid)
                    if f is not None:
                        return dict(E=E, d=d, s=s, f=f, wid=wid, stich=None, stamm=None, score=score)
                else:
                    if not self._steig_ok(A, E):
                        continue
                    band = _obb(((A[0] + E[0]) / 2.0, (A[1] + E[1]) / 2.0), d, STICH_BREITE + 2.0, math.hypot(E[0] - A[0], E[1] - A[1]) - self.wo[wid].breite)
                    f = self._pruefe(E, d, s, None, ausser=(wid,), band=band)
                    if f is not None:
                        return dict(E=E, d=d, s=s, f=f, wid=None, stich=(A, E), stamm=wid, score=score)
        return None

    def durchgang(self, K, richtungen, wids, bezug_ecken, max_dist=40.0):
        """Ladeplatz an einem Durchgangsknoten K (Einmuendung/Wegwechsel, kein Sackgassenende). Das Gespann haelt mit der Mitte im Knoten (ProtoSim
        knoten_halt), Datenpunkt = K. Gestalt wie am Wegende: Rahmen d (Ankunftsrichtung), virtuelles Wegende E = K + HECK_M * d.
        Gewinner: naechster zulaessiger Kies-Hof zum Betrieb (Rand), Tiebreak Richtung/Seite."""
        kand = []
        for d in richtungen:
            for dd in (d, (-d[0], -d[1])):
                E = (K[0] + dd[0] * self.heck, K[1] + dd[1] * self.heck)
                for s in (1, -1):
                    f = self._pruefe(E, dd, s, None, ausser=tuple(wids))
                    if f is None:
                        continue
                    kc = f["kies"]["c"]
                    dist = _rand_abstand(kc, bezug_ecken) if bezug_ecken is not None else 0.0
                    if dist <= max_dist:
                        kand.append((round(dist, 3), round(dd[0], 3), round(dd[1], 3), s, dd, E, f))
        if not kand:
            return None
        kand.sort(key=lambda k: k[:4])
        dist, _, _, s, dd, E, f = kand[0]
        return dict(E=E, d=dd, s=s, f=f, wid=wids[0], stich=None, stamm=None, score=dist, durchgang=True, K=K)

    def vorhandenes_ende(self, wid, E, d):
        """Ladeplatz an einem bestimmten vorhandenen Wegende (Seite mit Platz)."""
        for s in (1, -1):
            f = self._pruefe(E, d, s, wid)
            if f is not None:
                return dict(E=E, d=d, s=s, f=f, wid=wid, stich=None, stamm=None, score=0.0)
        return None


def _aufblasen(ecken, m):
    cx = sum(p[0] for p in ecken) / 4.0
    cz = sum(p[1] for p in ecken) / 4.0
    out = []
    for p in ecken:
        v = _norm((p[0] - cx, p[1] - cz))
        out.append((p[0] + v[0] * m, p[1] + v[1] * m))
    return out


def _rand_abstand(p, ecken):
    if punkt_in_obb(p, ecken):
        return 0.0
    return min(poly_abstand(p, [ecken[i] for i in (k, (k + 1) % 4)])[0] for k in range(4))


def _abtasten(punkte, schritt):
    """Punkte (A, Tangente) im Abstand `schritt` entlang der Polylinie, ohne die Enden (je 18 m frei)."""
    out = []
    acc = 0.0
    L = sum(math.hypot(punkte[k + 1][0] - punkte[k][0], punkte[k + 1][1] - punkte[k][1]) for k in range(len(punkte) - 1))
    s_next = 18.0
    for k in range(len(punkte) - 1):
        a, b = punkte[k], punkte[k + 1]
        seg = math.hypot(b[0] - a[0], b[1] - a[1])
        if seg == 0:
            continue
        t = ((b[0] - a[0]) / seg, (b[1] - a[1]) / seg)
        while s_next <= acc + seg and s_next <= L - 18.0:
            u = (s_next - acc) / seg
            out.append(((a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u), t))
            s_next += schritt
        acc += seg
    return out


def _zu_nah_an_knoten(wo, wid, A, r):
    """A zu nah an Enden des Stammwegs oder an Linien/Enden anderer Wege (Kreuzungsabstand)."""
    for wj, w in wo.items():
        if wj == wid:
            for e in (w.punkte[0], w.punkte[-1]):
                if math.hypot(A[0] - e[0], A[1] - e[1]) < r:
                    return True
            continue
        if poly_abstand(A, w.punkte)[0] < r:
            return True
    return False


def ladeplatz_dict(erg, planer, wid_stamm, gueter, name_ort, boden, wegname):
    """Datensatz fuer proto_orte.json."""
    f = erg["f"]
    P, E, d = f["P"], erg["E"], erg["d"]

    def box(t, **kw):
        o = {"x": r2(t["c"][0]), "z": r2(t["c"][1]), "rot_deg": r2(((t["rot"] + 180.0) % 360.0) - 180.0), "b": r2(t["b"]), "t": r2(t["t"])}
        o.update(kw)
        return o
    stufen = [{"stufe": i + 1, "bestand_ab_anteil": FUELLSTUFEN_GRENZEN[i]} for i in range(3)]
    haufen = []
    for k, g in enumerate(gueter):
        o = box(f["haufen"])
        # mehrere Gueter: zweiter Haufen hinter dem ersten (entlang des Wegs Richtung Wegende)
        if k > 0:
            o["x"] = r2(f["haufen"]["c"][0] + d[0] * 3.6 * k)
            o["z"] = r2(f["haufen"]["c"][1] + d[1] * 3.6 * k)
        o["gut"] = g["gut"]
        o["rolle"] = g["rolle"]
        o["fuellstufen"] = {"anzahl": 3, "stufe_0": "kein Haufen (Bestand 0)", "grenzen": stufen, "bestand_bezug": g["bezug"],
                            "prefab_refs": ["platzhalter/lagerhaufen_%s_s%d" % (g["gut"], i + 1) for i in range(3)],
                            "platzhalter_rolle": "heuhaufen"}
        haufen.append(o)
    durch = bool(erg.get("durchgang"))
    K = erg.get("K")
    if durch:
        halt = {"x": r2(K[0]), "z": r2(K[1]), "art": "durchgang", "neu_gebaut": False}
        hinweis = ("Durchgangs-Ladeplatz (WA-08): Datenpunkt = Halteknoten, das Gespann haelt mit der Mitte im Knoten (Heck %.2f m davor). Ein Ladestich "
                   "(Sackgasse, 90-Grad-Abzweig) liess proto_easing_test B rot (E3 Gierrate, E5 Halt-Verzug), Begruendung in sprints/s8/umsetzung/WA-08.md. "
                   "Kies-Hof, Rampe, Lagerhaufen nur Daten, Modelle folgen (Sophie)." % ((planer.heck - HALT_LUFT_M) / 2.0))
    else:
        halt = {"x": r2(E[0]), "z": r2(E[1]), "art": "sackgasse", "neu_gebaut": erg["stich"] is not None}
        hinweis = "Datenpunkt = Heck-Halt-Punkt des Fuhrwerks am Wegende (WA-08); Kies-Hof, Rampe, Lagerhaufen nur Daten, Modelle folgen (Sophie)."
    return {"x": r2(P[0]), "z": r2(P[1]), "weg": wegname, "abstand_netz_m": 0.0,
            "halt": halt,
            "richtung_deg": r2(rot_zu(d[0], d[1])), "heck_vor_wegende_m": (None if durch else r2(planer.heck)),
            "kies_hof": box(f["kies"], boden=boden, platzhalter_rolle="flaeche_hof"),
            "rampe": box(f["rampe"], prefab_ref="platzhalter/rampe_holz"),
            "lagerhaufen": haufen,
            "hinweis": hinweis}
