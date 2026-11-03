#!/usr/bin/env python3
"""Hofstellen-Parzellen entlang von Wegen (Haufendorf, Weiler). Parzellenraster 12,5 m, Jitter, Ausrichtung zur Strasse."""
import math

from stadt_geo import PCG, obb_ecken, obb_ueberlappt, poly_abstand, poly_laenge, resample, r2
from stadt_bau import (PARZ, HAUS, Weg, baue_hofstelle, gelaende_ok, rot_zu, weg_frei)


class Punktweg:
    """Abgetastete Polylinie mit Stationen und Tangenten."""

    def __init__(self, weg, schritt=2.0):
        self.weg = weg
        self.pts = resample(weg.punkte, schritt)
        self.schritt = schritt
        self.L = poly_laenge(self.pts)

    def an(self, s):
        s = max(0.0, min(self.L, s))
        i = min(int(s / self.schritt), len(self.pts) - 2)
        t = (s - i * self.schritt) / self.schritt
        p = (self.pts[i][0] + t * (self.pts[i + 1][0] - self.pts[i][0]), self.pts[i][1] + t * (self.pts[i + 1][1] - self.pts[i][1]))
        a = self.pts[max(0, int((s - 4.0) / self.schritt))]
        b = self.pts[min(len(self.pts) - 1, int((s + 4.0) / self.schritt) + 1)]
        dx, dz = b[0] - a[0], b[1] - a[1]
        n = math.hypot(dx, dz) or 1.0
        return p, (dx / n, dz / n)


class Parzelle(dict):
    pass


class Ortslage:
    """Haelt Wege, Parzellen und Footprints einer Ortslage; bietet Platzierung entlang eines Wegs."""

    def __init__(self, szene, geo, ort_id, mitte, r_ort, alle_wege, seed_tag, welt_seed=7):
        self.szene = szene
        self.geo = geo
        self.id = ort_id
        self.mitte = mitte
        self.r = r_ort
        self.wege = alle_wege          # Liste Weg (auch fremde, als Hindernis)
        self.parz = []                 # Parzellen (dict)
        self.seed_tag = seed_tag
        self.welt_seed = welt_seed
        self.rng = PCG(PCG.hash_seed(welt_seed, ort_id, seed_tag))
        self.parz_ecken = []

    # ---- Rahmen einer Parzelle an Station s des Wegs
    def rahmen(self, pw, seite, s, W, T, abstand_achse=None, mittig=True):
        sc = s + (W / 2.0 if mittig else 0.0)
        p, t = pw.an(sc)
        n = (-seite * t[1], seite * t[0])       # seite=+1: rechts der Fahrtrichtung
        ra = abstand_achse if abstand_achse is not None else pw.weg.breite / 2.0 + 0.5
        P = (p[0] + n[0] * ra, p[1] + n[1] * ra)   # Mitte der Vorderkante
        eu = t
        ev = n
        cx, cz = P[0] + ev[0] * T / 2.0, P[1] + ev[1] * T / 2.0
        rot = rot_zu(ev[0], ev[1])                  # lokales z = ev -> Ecken symmetrisch
        ecken = obb_ecken(cx, cz, W, T, rot)
        return P, eu, ev, ecken

    def frei(self, ecken, weg, rand=-1.0, aue_max=0.0, front=None, **kw):
        """Hart: Wasser/Hang/Wege/Ueberlappung fuer die ganze Parzelle. Weich: Aue-Anteil nur im Hausbereich (front-Ecken)."""
        ok, _ = gelaende_ok(self.geo, ecken, **kw)
        if not ok:
            return False, 1.0
        aue = 0.0
        if front is not None:
            _, aue = gelaende_ok(self.geo, front, **dict(kw, ausnahme=("rinne", "see", "teich", "bach", "hang")))
        else:
            aue = _ if False else gelaende_ok(self.geo, ecken, **kw)[1]
        if aue > aue_max:
            return False, aue
        if not weg_frei(ecken, self.wege, eigener=weg):
            return False, aue
        for e in self.parz_ecken:
            if obb_ueberlappt(ecken, e, rand):
                return False, aue
        for (e, typ, pid, ort) in self.szene.foot:
            if obb_ueberlappt(ecken, e, rand):
                return False, aue
        return True, aue

    def front_ecken(self, P, ev, eu, W, T, tiefe=17.0):
        t = min(T, tiefe)
        cx, cz = P[0] + ev[0] * t / 2.0, P[1] + ev[1] * t / 2.0
        return obb_ecken(cx, cz, W, t, rot_zu(ev[0], ev[1]))

    def d_kern(self, p):
        return math.hypot(p[0] - self.mitte[0], p[1] - self.mitte[1])

    def eintragen(self, typ, P, eu, ev, W, T, ecken, weg, seite, s, status="besetzt", **kw):
        pid = self.szene.pid(self.id)
        cx = sum(p[0] for p in ecken) / 4.0
        cz = sum(p[1] for p in ecken) / 4.0
        par = Parzelle(id=pid, ort=self.id, typ=typ, status=status, cx=r2(cx), cz=r2(cz), b=W, t=T,
                       rot_deg=r2(rot_zu(ev[0], ev[1])), weg=weg.id if weg else None, seite=seite, s=r2(s),
                       P=(r2(P[0]), r2(P[1])), eu=(round(eu[0], 5), round(eu[1], 5)), ev=(round(ev[0], 5), round(ev[1], 5)))
        par.update(kw)
        self.parz.append(par)
        self.parz_ecken.append(ecken)
        return par

    def besetzen(self, par, typ=None, seed_zusatz=""):
        """Baut Haus + Belebung auf einer (leeren) Parzelle. Deterministisch je Parzelle (und Monat bei Wachstum)."""
        typ = typ or par["typ"]
        rng = PCG(PCG.hash_seed(self.welt_seed, self.id, par["id"], typ, seed_zusatz))
        P, eu, ev = par["P"], par["eu"], par["ev"]
        erz = baue_hofstelle(self.szene, self.id, par["id"], typ, P, eu, ev, par["b"], par["t"], rng)
        par["typ"] = typ
        par["status"] = "besetzt"
        return erz

    # ---- Slots entlang mehrerer Wege, nach Kernabstand sortiert (kompakter Ort, Haufen statt Zeile)
    def fuellen(self, plan, typ_fn, p_akzept_fn, aue_max=0.0, schritt=12.5, rauschen=22.0, max_n=None, s_rand=6.0, max_abstand=None):
        """plan = [(Punktweg, seite, s_min, s_max, abstand_achse)]. Sortiert alle Stationen nach d_kern + Rauschen und
        belegt sie der Reihe nach. Gibt Anzahl neuer Parzellen zurueck."""
        rng = self.rng
        slots = []
        for (pw, seite, s0, s1, ra) in plan:
            s = s0
            while s <= s1:
                P, t = pw.an(s)
                dk = self.d_kern(P)
                slots.append((dk + rng.uniform(-rauschen, rauschen), pw, seite, s, ra, s1))
                s += schritt
        slots.sort(key=lambda t: t[0])
        n_neu = 0
        for (key, pw, seite, s, ra, s1) in slots:
            if max_n is not None and n_neu >= max_n:
                break
            typ = typ_fn(None, rng)
            if typ is None:
                break
            W, T = PARZ[typ]
            if s + W > s1 + s_rand:
                continue
            P, eu, ev, ecken = self.rahmen(pw, seite, s, W, T, ra)
            ctr = (sum(p[0] for p in ecken) / 4, sum(p[1] for p in ecken) / 4)
            dk = self.d_kern(ctr)
            if max_abstand is not None and math.hypot(ctr[0] - max_abstand[0][0], ctr[1] - max_abstand[0][1]) > max_abstand[1]:
                continue
            if rng.random() > p_akzept_fn(dk):
                continue
            ok, aue = self.frei(ecken, pw.weg, aue_max=aue_max, front=self.front_ecken(P, ev, eu, W, T))
            if not ok:
                continue
            typ_ok = typ_fn(dk, rng, bestaetigt=typ)
            if typ_ok is None:
                break
            self.eintragen(typ_ok, P, eu, ev, W, T, ecken, pw.weg, seite, s)
            n_neu += 1
        return n_neu
