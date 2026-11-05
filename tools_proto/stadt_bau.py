#!/usr/bin/env python3
"""Bausteine fuer Ortslagen: Szene (Instanzen, Footprints), Parzellen entlang Wegen, Hofstellen mit Belebung.
Gemeinsam genutzt von Dorf, Weiler, Markt-Ausschnitt und Wachstum (stadt_wachstum.py)."""
import math

from stadt_geo import (PCG, obb_ecken, obb_ueberlappt, poly_abstand, poly_laenge, resample, r2)

# ---------------------------------------------------------------- Regelwerk-Daten (12_regelwerk_v1_1.json haustypen/skalen)
HAUS = {
    # typ: (b = Fassadenbreite, t = Tiefe, EW)
    "kate": (8.0, 6.0, 5),
    "bauernhof": (12.0, 9.0, 8),
    "grosshof": (12.0, 9.0, 12),
    "handwerkerhaus": (9.0, 12.0, 7),
    "buergerhaus": (12.0, 14.0, 14),
    "kirche_dorf": (20.0, 10.0, 0),
    "kirche_stadt": (35.0, 15.0, 0),
    "gasthaus": (14.0, 12.0, 7),
    "schmiede": (9.0, 7.0, 5),
    "rathaus": (16.0, 12.0, 2),
    "speicher": (20.0, 12.0, 0),
    "stadttor": (8.0, 8.0, 0),
    "gutshof": (40.0, 40.0, 0),
    "wassermuehle": (12.0, 12.0, 0),
    "fischerhuette": (8.0, 6.0, 4),
}
NEBEN = {
    "scheune_18x10": (18.0, 10.0),
    "stall_12x8": (12.0, 8.0),
    "schuppen_6x4": (6.0, 4.0),
}
# Parzellen (Breite entlang Weg, Tiefe) in m
PARZ = {
    "kate": (12.5, 25.0),
    "handwerkerhaus": (12.5, 25.0),
    "bauernhof": (25.0, 25.0),
    "grosshof": (37.5, 37.5),
    "gasthaus": (25.0, 35.0),
    "schmiede": (15.0, 20.0),
    "kirche_dorf": (37.5, 37.5),
}
BAULINIE_MIN_M = 3.2     # WA-10: Dorf-Baulinie 3..15 m (Validator, Toleranz 0,5 m): Haupthaus mindestens so weit vom Wegrand
JR_MAX_GRAD = 4.0         # WA-10: Drehung des Haupthauses gegen die Parzelle (Bezugslinie +-10 Grad inkl. Wegkruemmung)
KIRCHE_V_FRONT = 6.0     # WA-10: Vorderkante Dorfkirche 6 m hinter der Parzellen-Vorderkante
HAUPTHAUS = ("kate", "bauernhof", "grosshof", "handwerkerhaus", "gasthaus", "schmiede")
GEBAEUDE_TYPEN = set(HAUS) | {"nebengebaeude"}


def rot_zu(vx, vz):
    """Godot rotation_degrees.y, so dass die lokale +z-Achse (Fassade) auf den Weltvektor (vx, vz) zeigt."""
    return math.degrees(math.atan2(vx, vz))


class Szene:
    def __init__(self):
        self.inst = []
        self.foot = []        # (ecken, typ, id, ort)
        self.parz = {}        # ort -> [parzelle dict]
        self.wege = []        # Dicts (siehe stadt_gen)
        self.orte = []
        self.zaehler = {}

    def pid(self, ort):
        n = self.zaehler.get(ort, 0) + 1
        self.zaehler[ort] = n
        return "%s_p%02d" % (ort, n)

    def add(self, typ, x, z, rot, parz, ort, b=None, t=None, **extra):
        d = {"typ": typ, "x": r2(x), "z": r2(z), "rot_deg": r2(((rot + 180.0) % 360.0) - 180.0), "parzelle": parz, "ort": ort}
        if b is not None:
            d["b"] = r2(b)
        if t is not None:
            d["t"] = r2(t)
        for k, v in extra.items():
            d[k] = v
        self.inst.append(d)
        if typ in GEBAEUDE_TYPEN and b is not None:
            self.foot.append((obb_ecken(x, z, b, t, rot), typ, parz, ort))
        return d


# ---------------------------------------------------------------- Gelaendepruefung
def gelaende_ok(geo, ecken, mitte=None, bach_frei=20.0, rinne_frei=55.0, see_frei=45.0, teich_frei=15.0,
                max_steig=6.0, ausnahme=()):
    """Prueft Ecken, Kantenmitten und Mitte eines Footprints. Rueckgabe (ok, in_aue_anteil)."""
    pts = list(ecken)
    for i in range(4):
        a, b = ecken[i], ecken[(i + 1) % 4]
        pts.append(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2))
    if mitte is None:
        mitte = (sum(p[0] for p in ecken) / 4, sum(p[1] for p in ecken) / 4)
    pts.append(mitte)
    n_aue = 0
    for (x, z) in pts:
        if "rinne" not in ausnahme and geo.rinne_abstand(x, z) < rinne_frei:
            return False, 1.0
        if "see" not in ausnahme and geo.see_abstand(x, z) < see_frei:
            return False, 1.0
        if "teich" not in ausnahme and geo.muehlteich_abstand(x, z) < teich_frei:
            return False, 1.0
        if "bach" not in ausnahme and geo.bach_abstand(x, z) < bach_frei:
            return False, 1.0
        if "hang" not in ausnahme and geo.steigung(x, z) > max_steig:
            return False, 1.0
        if geo.in_aue(x, z):
            n_aue += 1
    return True, n_aue / float(len(pts))


# ---------------------------------------------------------------- Wege als Hindernis / Bezug
class Weg:
    def __init__(self, wid, typ, punkte, breite, name=""):
        self.id = wid
        self.typ = typ
        self.punkte = [tuple(map(float, p)) for p in punkte]
        self.breite = breite
        self.name = name

    def laenge(self):
        return poly_laenge(self.punkte)


def probenpunkte(ecken):
    """5x5-Raster innerhalb des Rechtecks (Ecken in Reihenfolge) + Rand."""
    p0, p1, p2, p3 = ecken
    out = []
    for i in range(5):
        for j in range(5):
            a, b = i / 4.0, j / 4.0
            x = (1 - a) * ((1 - b) * p0[0] + b * p3[0]) + a * ((1 - b) * p1[0] + b * p2[0])
            z = (1 - a) * ((1 - b) * p0[1] + b * p3[1]) + a * ((1 - b) * p1[1] + b * p2[1])
            out.append((x, z))
    return out


def weg_frei(ecken, wege, eigener=None, eigen_abstand=3.0, fremd_zuschlag=1.0):
    for p in probenpunkte(ecken):
        for w in wege:
            d = poly_abstand(p, w.punkte)[0]
            lim = ((w.breite / 2.0 - 0.2) if (eigener is not None and w.id == eigener.id) else w.breite / 2.0 + fremd_zuschlag)
            if d < lim:
                return False
    return True


# ---------------------------------------------------------------- Hofstellen
def lokal_zu_welt(P, eu, ev, u, v):
    return (P[0] + eu[0] * u + ev[0] * v, P[1] + eu[1] * u + ev[1] * v)


def baue_hofstelle(szene, ort, pid, typ, P, eu, ev, W, T, rng, ohne_haus=False, extra_ew=None, zaun_max=20, zaun_min=6):
    """Platziert Haus + Nebengebaeude + Flaechen + Zaun + Baeume einer Hofstelle.
    Parzellenrahmen: P = Mitte der Strassenseite (Vorderkante), eu = Richtung entlang des Wegs, ev = Richtung ins Grundstueck,
    u in [-W/2, W/2], v in [0, T]. Gibt Liste der erzeugten Gebaeude-Instanzen zurueck."""
    fassade = (-ev[0], -ev[1])
    rot0 = rot_zu(*fassade)
    erz = []

    def haus(typ_, u, v, jit=True, extra_rot=0.0, b=None, t=None, **kw):
        hb, ht, _ = HAUS[typ_] if typ_ in HAUS else (b, t, 0)
        ju = rng.uniform(-2.0, 2.0) if jit else 0.0
        jv = rng.uniform(-1.0, 1.0) if jit else 0.0
        jr = rng.uniform(-8.0, 8.0) if jit else 0.0
        # WA-10 Baulinie/Bezugslinie: Haupthaus mindestens BAULINIE_MIN_M hinter der Wegkante (Parzellen-Vorderkante liegt 0,5 m vom Wegrand,
        # die Drehung hebt die vordere Ecke um (b/2) sin(jr)) und Drehung gegen die Parzelle auf JR_MAX_GRAD begrenzt. Zufallszahlen unveraendert gezogen.
        if typ_ in HAUPTHAUS:
            jr = max(-JR_MAX_GRAD, min(JR_MAX_GRAD, jr))
            vmin = ht / 2.0 + BAULINIE_MIN_M - 0.5 + (hb / 2.0) * math.sin(math.radians(abs(jr)))
            v = max(v, vmin - jv) if jit else max(v, vmin)
        x, z = lokal_zu_welt(P, eu, ev, u + ju, v + jv)
        if fremd(obb_ecken(x, z, hb, ht, rot0 + jr + extra_rot)):
            ju = jv = jr = 0.0
            if typ_ in HAUPTHAUS:
                v = max(v, ht / 2.0 + BAULINIE_MIN_M - 0.5)
            x, z = lokal_zu_welt(P, eu, ev, u, v)
        d = szene.add(typ_, x, z, rot0 + jr + extra_rot, pid, ort, b=hb, t=ht, **kw)
        erz.append(d)
        return d

    def fremd(e):
        """Kollision mit Gebaeuden anderer Parzellen (z. B. Scheune ragt in den Nachbarhof)."""
        cx = sum(c[0] for c in e) / 4.0
        cz = sum(c[1] for c in e) / 4.0
        return any(f[2] != pid and abs(f[0][0][0] - cx) < 60.0 and abs(f[0][0][1] - cz) < 60.0 and obb_ueberlappt(e, f[0], 0.3) for f in szene.foot)

    def neben(var, u, v, quer=False, p=1.0, jit=True):
        if rng.random() > p:
            return None
        b, t = NEBEN[var]
        ju = rng.uniform(-1.0, 1.0) if jit else 0.0
        jr = rng.uniform(-6.0, 6.0) if jit else 0.0
        vorhanden = [obb_ecken(o["x"], o["z"], o["b"], o["t"], o["rot_deg"]) for o in erz if "b" in o]
        # Kollisionsfrei: erst mit Jitter, dann ohne; sonst weglassen (Haus 0,3 m Abstand, nie ueberlappend)
        for (ju_, jr_) in ((ju, jr), (0.0, 0.0)):
            x, z = lokal_zu_welt(P, eu, ev, u + ju_, v)
            rot_ = rot0 + (90.0 if quer else 0.0) + jr_
            e = obb_ecken(x, z, b, t, rot_)
            if not any(obb_ueberlappt(e, o, 0.3) for o in vorhanden) and not fremd(e):
                d = szene.add("nebengebaeude", x, z, rot_, pid, ort, b=b, t=t, variante=var)
                erz.append(d)
                return d
        return None

    def flaeche(art, u0, u1, v0, v1):
        uc, vc = (u0 + u1) / 2.0, (v0 + v1) / 2.0
        x, z = lokal_zu_welt(P, eu, ev, uc, vc)
        szene.add("flaeche_" + art, x, z, rot0, pid, ort, b=u1 - u0, t=v1 - v0)

    def baum(typ_, u, v, **kw):
        x, z = lokal_zu_welt(P, eu, ev, u + rng.uniform(-1, 1), v + rng.uniform(-1, 1))
        szene.add(typ_, x, z, rng.uniform(-180, 180), pid, ort, **kw)

    def prop(typ_, u, v, rot_extra=0.0):
        x, z = lokal_zu_welt(P, eu, ev, u, v)
        szene.add(typ_, x, z, rot0 + rot_extra + rng.uniform(-20, 20), pid, ort)

    h = None
    hw, hh = W / 2.0, T
    if typ == "bauernhof" or typ == "grosshof":
        links = rng.random() < 0.5
        s = -1.0 if links else 1.0
        # Wohnstallhaus vorn auf einer Seite, Scheune seitlich laengs, Garten hinter dem Haus
        if not ohne_haus:
            sb = rng.uniform(3.0, 4.5)
            h = haus(typ, s * (hw - 6.8), sb + 4.5)
            neben("scheune_18x10", -s * (hw - 5.6), 4.2 + 9.0, quer=True)
            neben("schuppen_6x4", s * (hw - 4.5), T - 3.2, p=0.55)
        # Hoflehm zwischen Haus und Scheune, Garten hinter dem Haus
        uh0, uh1 = (-hw + 0.5, -hw + 13.0) if not links else (hw - 13.0, hw - 0.5)
        flaeche("garten", uh0, uh1, 13.5, T - 0.5)
        flaeche("hof", -hw + 0.5, hw - 0.5, 0.5, 13.0)
        baum("obstbaum", (uh0 + uh1) / 2.0 + rng.uniform(-2, 2), T - 5.0)
        if rng.random() < 0.55:
            baum("obstbaum", (uh0 + uh1) / 2.0 + rng.uniform(-3, 3), 17.0 + rng.uniform(0, 2))
        if rng.random() < 0.35:
            baum("obstbaum", rng.uniform(-hw + 2, hw - 2), T - 2.0)
        if rng.random() < 0.55:
            prop("heuhaufen", -s * (hw - 5.0), T - 5.0)
        if rng.random() < 0.6:
            prop("holzstapel", s * (hw - 2.2), 6.0)
    elif typ == "kate":
        if not ohne_haus:
            h = haus(typ, rng.uniform(-1.5, 1.5), rng.uniform(3.0, 4.5) + 3.0)
            neben("schuppen_6x4", rng.uniform(-1.0, 1.0), T - 3.2, p=0.6)
        flaeche("garten", -hw + 0.5, hw - 0.5, 10.5, T - 6.0)
        flaeche("hof", -hw + 0.5, hw - 0.5, 0.5, 10.5)
        baum("obstbaum", rng.uniform(-2, 2), 14.5)
        if rng.random() < 0.4:
            baum("obstbaum", rng.uniform(-2.5, 2.5), T - 3.0)
        if rng.random() < 0.4:
            prop("holzstapel", hw - 1.8, 4.0)
    elif typ == "handwerkerhaus":
        if not ohne_haus:
            h = haus(typ, rng.uniform(-1.0, 1.0), rng.uniform(2.5, 3.5) + 6.0)
            neben("schuppen_6x4", rng.uniform(-1.0, 1.0), T - 2.8, p=0.4)
        flaeche("garten", -hw + 0.5, hw - 0.5, 16.0, T - 0.5)
        flaeche("hof", -hw + 0.5, hw - 0.5, 0.5, 3.0)
        baum("obstbaum", rng.uniform(-2, 2), 19.0)
        if rng.random() < 0.5:
            prop("fass", hw - 1.5, 4.0)
    elif typ == "gasthaus":
        h = haus(typ, 0.0, 3.5 + 6.0)
        neben("stall_12x8", -3.0, T - 6.0, quer=False)
        flaeche("hof", -hw + 0.5, hw - 0.5, 0.5, 4.0)
        flaeche("garten", -hw + 0.5, hw - 0.5, 18.0, T - 0.5)
        baum("laubbaum", hw - 3.0, 5.0)
        prop("fass", -hw + 2.0, 5.0)
        prop("fass", -hw + 3.0, 6.5)
    elif typ == "schmiede":
        h = haus(typ, 0.0, 3.0 + 3.5)
        flaeche("hof", -hw + 0.5, hw - 0.5, 0.5, T - 0.5)
        prop("amboss", hw - 3.0, 12.0)
        prop("holzstapel", -hw + 2.0, 13.0)
        prop("fass", hw - 2.0, 4.5)
    elif typ == "kirche_dorf":
        h = haus(typ, 0.0, HAUS[typ][1] / 2.0 + KIRCHE_V_FRONT, jit=False)      # WA-10: Dorfkirche 3-15 m hinter dem Wegrand (vorher Parzellenmitte, 16,3 m)
        flaeche("kirchhof", -hw + 0.5, hw - 0.5, 0.5, T - 0.5)
        baum("laubbaum", -hw + 4.0, 5.0)
        baum("laubbaum", hw - 4.0, 5.0)
        baum("laubbaum", -hw + 4.0, T - 5.0)
    if h is not None:
        erz.remove(h)
        erz.insert(0, h)

    # Zaun: 3-m-Segmente (typ zaun_latte), vorn mit Tor-Luecke, seitlich bis 2/3 der Tiefe, Gesamtzahl 6-20
    if typ in ("bauernhof", "grosshof", "kate", "handwerkerhaus"):
        kand = []
        n_front = int(W // 3.0)
        for i in range(n_front):
            u = -W / 2.0 + 1.5 + i * 3.0 + (W - n_front * 3.0) / 2.0
            if abs(u) < 2.6 and typ in ("kate", "handwerkerhaus"):
                continue
            kand.append((u, 0.0, 0.0))
        nside = int((T * 0.66) // 3.0)
        for sdir in (-1.0, 1.0):
            for i in range(nside):
                kand.append((sdir * (hw - 0.2), 1.5 + i * 3.0 + 3.0, 90.0))
        rng.shuffle(kand)
        n = max(zaun_min, min(zaun_max, int(len(kand) * rng.uniform(0.45, 0.75))))
        for (u, v, rr) in kand[:n]:
            x, z = lokal_zu_welt(P, eu, ev, u, v)
            szene.add("zaun_latte", x, z, rot0 + rr, pid, ort)
    return erz
