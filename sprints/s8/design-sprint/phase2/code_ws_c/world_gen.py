#!/usr/bin/env python3
"""W-06 (S7, Felix): Kartengenerator der S7-Welt. Seed + Lenas Regeln (world/data/rules_s7.json) -> Heightmap, Flussmaske,
world/data/world_s7.json (altes Kartenschema data/slice_map.schema.json) und world/data/hq_vorschau_s7.json.

Aufruf (aus slice/):   python3 -I tools/world_gen.py [--seed N] [--out DIR] [--rules PFAD] [--dry] [--quiet]
                       python3 -I tools/world_gen.py --sweep A..B     (nur Statistik, nichts schreiben)
Default-Seed: DEFAULT_SEED (7; Auswahl und Sweep 1..20 in sprints/s7/block-b/felix.md). Suite: tests/s7_validator.sh.

Ausgabe (DIR, Default world/data/):
  hoehe_s7.r16       513 x 513 uint16 little-endian, Hoehe in 0,05 m (Stuetzpunkte = Feldecken, 1 Feld = 25 m)
  rand_s7.r16        279 x 279 uint16 LE, Landschaftsrand 7,5 km je Seite, Raster 100 m (= 4 Felder), gleiche Skala;
                     Knoten 75..203 decken die spielbare Flaeche, die Randknoten stimmen mit hoehe_s7 ueberein
  fluss_s7.u8        512 x 512 uint8 je Feld: Bit 1 = Rinne (Wasser), Bit 2 = Aue
  world_s7_meta.json Masse, Skalen, Wasserspiegel, Bau-Konstanten (Steigungsgrenzen, Kostenfaktor), Seed, md5 der Rohdaten
  world_s7.json      Karte im Slice-Schema (Staedte, Industrien, Gelaende-Polygone, Fluss, Ketten, Nischen, HQ-Optionen)
  hq_vorschau_s7.json  Vorschau-Karten je Stadt (Format wie data/hq_vorschau.json, Modellrechnung wie tools/hq_vorschau_gen.py)

Determinismus: gleicher Seed -> byte-gleiche Dateien (numpy PCG64, feste Reihenfolge, keine Zeitstempel, keine Floats im JSON).
Sim-Konvention: Hoehe je Feld = Mittel der 4 Eckknoten; Steigung je Feld = max |dh| zu den 4 Nachbarfeldern / 25 m (Promille).
Der Validator (tools/world_validate.py) rechnet aus denselben Rohdateien; der Generator ruft ihn vor dem Schreiben auf und
wechselt bei Verstoss zum naechsten Versuch im selben Seed-Strom (Lenas erzeugung_hinweis).
"""
import argparse
import hashlib
import json
import math
import os
import sys
import zlib
import struct

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import world_validate as WV  # noqa: E402

DEFAULT_SEED = 7
GRID = 512
N = GRID + 1                 # Stuetzpunkte innen
STEP = 25.0                  # m je Feld
L = GRID * STEP              # 12800 m
B = 7500.0                   # Rand je Seite [m]
OSTEP = 100.0                # Raster Rand [m]
NB = int((L + 2 * B) / OSTEP) + 1   # 279
INNER0 = int(B / OSTEP)      # 75: erster Randknoten auf der spielbaren Kante
H_SCALE = 0.05               # m je uint16-Einheit
MAX_VERSUCHE_LAYOUT = 40     # Platzierungsversuche je Terrain
MAX_VERSUCHE_TERRAIN = 6     # Terrain-Varianten je Seed
STAMP_PUFFER = 12            # Industrie >= Stadtradius + 12 (Regel: + 6): Industrie-Boeschung (bis 9,5) bleibt ausserhalb des Stadtkerns

# Bau-Konstanten der Sim (einzige Quelle; world/s7_world.gd liest sie aus world_s7_meta.json)
BAU = {
    "steigung_max_promille_strasse": 200,   # Sperre "zu steil" Strasse (Aylin B11)
    "steigung_max_promille_gleis": 120,     # Sperre "zu steil" Gleis
    "kosten_promille_je_steigungs_promille": 15,   # Faktor = 1000 + 15 x Steigung[Promille]  (10 % -> x2,5)
    "bruecke_max_felder": 8,
}

STUFEN_ = ["stadt", "kleinstadt", "dorf"]
STADT_NAMEN = ["Mittelfurt", "Kohlberg", "Seehafen", "Lindach", "Weidenau", "Eichwald", "Steinbach", "Haberau",
               "Altenbruck", "Wiesental", "Rotheim", "Birkenau", "Hochstetten"]
FLUSS_NAMEN = ["Linde", "Ache", "Wiese", "Elz", "Dreisam", "Kinzig", "Murg"]
NAME = {"getreidefarm": "Farm", "muehle": "Mühle", "kohlemine": "Kohle", "erzmine": "Erzmine", "kraftwerk": "Kraftwerk",
        "stahlwerk": "Stahlwerk", "werkzeugfabrik": "Werkzeugfabrik"}
KURZ = dict(NAME, erzmine="Erz", stahlwerk="Stahl")
ID_PREFIX = {"getreidefarm": "farm", "muehle": "muehle", "kohlemine": "kohle", "erzmine": "erz", "kraftwerk": "kraftwerk",
             "stahlwerk": "stahl", "werkzeugfabrik": "werkzeug"}
RICHTUNG = ["östlich", "südöstlich", "südlich", "südwestlich", "westlich", "nordwestlich", "nördlich", "nordöstlich"]


# ---------------------------------------------------------------- Rauschen (Perlin 2D, numpy, seedbar)

def _perm(seed):
    r = np.random.Generator(np.random.PCG64(seed))
    p = r.permutation(256).astype(np.int64)
    return np.concatenate([p, p])


_GRAD = np.array([[1, 1], [-1, 1], [1, -1], [-1, -1], [1, 0], [-1, 0], [0, 1], [0, -1]], dtype=np.float64) / math.sqrt(2)
_GRAD[4:] *= math.sqrt(2)


def perlin(x, y, seed):
    """Perlin-Rauschen in [-1, 1] (etwa), x/y in Rasterzellen."""
    p = _perm(seed)
    xi = np.floor(x).astype(np.int64)
    yi = np.floor(y).astype(np.int64)
    xf = x - xi
    yf = y - yi
    xi &= 255
    yi &= 255
    u = xf * xf * xf * (xf * (xf * 6 - 15) + 10)
    v = yf * yf * yf * (yf * (yf * 6 - 15) + 10)

    def g(ix, iy, dx, dy):
        h = p[p[ix] + iy] & 7
        return _GRAD[h, 0] * dx + _GRAD[h, 1] * dy

    n00 = g(xi, yi, xf, yf)
    n10 = g(xi + 1, yi, xf - 1, yf)
    n01 = g(xi, yi + 1, xf, yf - 1)
    n11 = g(xi + 1, yi + 1, xf - 1, yf - 1)
    a = n00 + u * (n10 - n00)
    b = n01 + u * (n11 - n01)
    return (a + v * (b - a)) * 1.414


def fbm(x, y, seed, wavelength, octaves, gain=0.5, lac=2.0, ridged=False):
    out = np.zeros_like(x)
    amp = 1.0
    f = 1.0 / wavelength
    norm = 0.0
    for o in range(octaves):
        n = perlin(x * f + 13.7 * o, y * f + 7.1 * o, seed + 101 * o)
        if ridged:
            n = 1.0 - np.abs(n)
        out += amp * n
        norm += amp
        amp *= gain
        f *= lac
    return out / norm


def grat(x, y, seed, wavelength, octaves, gain, modus):
    """Gebirgs-Gratfeld in [0, 1]. "oktave" = S7 (ridged je Oktave), "summe" = 1 - |fbm| (Design Sprint)."""
    if modus == "oktave":
        return fbm(x, y, seed, wavelength, octaves, gain=gain, ridged=True)
    # um 31 Grad gedreht, damit Gitterlinien des Perlin-Rauschens nicht achsparallel zur Karte liegen
    c, s_ = 0.857, 0.515
    xr, yr = c * x - s_ * y, s_ * x + c * y
    return 1.0 - np.abs(fbm(xr, yr, seed, wavelength, octaves, gain=gain)) * 1.6


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


# ---------------------------------------------------------------- Relief-Profile (Design Sprint Welt, TEAM-02, 02.11.2026)
# "s7" = Stand S7 (byte-gleich zu world/data). "ds_gebirge" = nur Gebirge beruhigt. "ds_v2" = Gebirge + Reliefzonen + Fluss.
# Herleitung und Kennzahlen: designsprint/phase2/08_landschaft.md. Auswahl per --relief NAME (Default s7).
RELIEF = {
    "s7": {
        "m1_wl": 1900.0, "m1_okt": 5, "m1_gain": 0.5, "m1_exp": 1.6,
        "m2_wl": 1500.0, "m2_okt": 4, "m2_gain": 0.5, "m2_exp": 1.5,
        "rand_wl": 2400.0, "rand_okt": 5, "rand_gain": 0.5,
        "detail_amp": 1.5,
        "zonen": False, "fluss_v2": False, "tal_innen": 300.0, "tal_aussen": 3000.0,
    },
}
RELIEF["s7"]["grat"] = "oktave"      # S7: jede Oktave einzeln gefaltet (1 - |n|) -> viele kurze Grate, "zerknittert"
# Gebirge beruhigt: Grat aus der SUMME gefaltet (1 - |fbm|) -> wenige lange Gebirgszuege, glatte Flanken;
# 4 statt 5 Oktaven, Gain 0,5 -> 0,42 (Kleinform-Anteil der 4. Oktave 6,3 % -> 2,7 %), Grundwelle 1,9 -> 2,6 km
RELIEF["ds_gebirge"] = dict(RELIEF["s7"], grat="summe", m1_wl=2600.0, m1_okt=4, m1_gain=0.42, m1_exp=1.35,
                            m2_wl=2000.0, m2_okt=4, m2_gain=0.42, m2_exp=1.3,
                            rand_wl=3000.0, rand_okt=4, rand_gain=0.42)
RELIEF["ds_v2"] = dict(RELIEF["ds_gebirge"], detail_amp=1.0, zonen=True, fluss_v2=True,
                       # Reliefzonen: Maske aus fbm(7000 m); Ebene 6 m, Huegelland 34 m Amplitude, Kuppen fbm(1100 m) bis 9 m
                       zonen_wl=6000.0, ebene_amp=4.0, huegel_amp=42.0, kuppen_wl=900.0, kuppen_amp=14.0,
                       # Fluss: halbe Breite 30..34 m + 16 m Zuwachs (Breite 60..100 m), Maeander-Welle ~ 12 x Breite
                       # Talzone: Aue flach bis 700 m (Aue = 5-20 x Flussbreite), Uebergang bis 2 km (S7: 300 m / 3 km -> halbe Karte war Talboden; 1,4 km scheitert an Lenas Lage-Regeln Muehle/Kleinstadt)
                       tal_innen=700.0, tal_aussen=2000.0,
                       fl_b0=(30.0, 34.0), fl_bzu=16.0, fl_bsin=3.0, fl_a3=(90.0, 140.0), fl_l3=(170.0, 230.0))
PROFIL = RELIEF["s7"]


# ---------------------------------------------------------------- Terrain

class Terrain:
    """Hoehenfunktion in Metern ueber Weltkoordinaten (x nach Ost, y nach Sued, Meter), inkl. Rand."""

    def __init__(self, seed, variant, rules):
        self.seed = seed
        self.rng = np.random.Generator(np.random.PCG64([seed, variant]))
        r = self.rng
        self.sv = seed * 1000 + variant
        # Fluss: Achse (ns: laeuft N->S, we: W->E), Lage u0 in einer Haelfte, Maeander
        self.axis = "ns" if r.random() < 0.5 else "we"
        self.flow_sign = 1 if r.random() < 0.5 else -1          # +1: Pegel faellt mit t
        side = r.random() < 0.5
        self.u0 = r.uniform(2600.0, 4600.0) if side else r.uniform(L - 4600.0, L - 2600.0)
        # Fluss darf schraeg laufen: Querlage wandert ueber die Kartenlaenge um bis zu 6 km (laengerer Fluss, mehr Aue)
        self.u_drift = float(np.clip(self.u0 + r.uniform(-6000.0, 6000.0), 2200.0, L - 2200.0)) - self.u0
        self.a1, self.l1, self.p1 = r.uniform(600.0, 950.0), r.uniform(2100.0, 2900.0), r.uniform(0, 6.28)
        self.a2, self.l2, self.p2 = r.uniform(220.0, 400.0), r.uniform(700.0, 1000.0), r.uniform(0, 6.28)
        self.lv0 = r.uniform(58.0, 70.0)
        self.breite0 = r.uniform(16.0, 22.0)   # halbe Rinnenbreite [m] am Einlauf
        # Design-Sprint-Profil: eigene Zufallsquelle, damit der S7-Strom (Fluss/Massive) unveraendert bleibt
        self.P = PROFIL
        self.a3, self.l3, self.p3 = 0.0, 1.0, 0.0
        self._kd = None
        if self.P["fluss_v2"]:
            r2 = np.random.Generator(np.random.PCG64([seed, variant, 991]))
            self.breite0 = r2.uniform(*self.P["fl_b0"])
            self.a3, self.l3, self.p3 = r2.uniform(*self.P["fl_a3"]), r2.uniform(*self.P["fl_l3"]), r2.uniform(0, 6.28)
        # Massiv 1 (gross) auf der Gegenseite des Flusses, Massiv 2 (klein) irgendwo weit genug weg
        best = None
        for _ in range(300):
            mx = r.uniform(2800.0, L - 2800.0)
            my = r.uniform(2800.0, L - 2800.0)
            dr = float(self.river_dist(mx, my))
            if best is None or dr > best[0]:
                best = (dr, mx, my)
            if dr > 4300.0:
                break
        _, mx, my = best
        self.m1 = (mx, my, r.uniform(3300.0, 4000.0))
        self.m1h = r.uniform(820.0, 900.0)
        self.m2 = None
        for _ in range(300):
            x2, y2 = r.uniform(2200.0, L - 2200.0), r.uniform(2200.0, L - 2200.0)
            if self.river_dist(x2, y2) > 2600.0 and math.hypot(x2 - mx, y2 - my) > self.m1[2] + 3200.0:
                self.m2 = (x2, y2, r.uniform(2000.0, 2600.0))
                break
        self.hills_amp = r.uniform(20.0, 26.0)
        self.base = r.uniform(118.0, 130.0)

    # --- Fluss: t = Koordinate entlang der Achse, u = quer
    def _tu(self, x, y):
        return (y, x) if self.axis == "ns" else (x, y)

    def river_u(self, t):
        u = self.u0 + self.u_drift * (t / L) + self.a1 * np.sin(t / self.l1 + self.p1) + self.a2 * np.sin(t / self.l2 + self.p2)
        if self.a3 > 0:
            # Maeander: Amplitude schwankt 25..100 % (gestreckte und schlingernde Abschnitte), Phase wandert (keine Sinus-Schlange)
            amp = 0.625 + 0.375 * np.sin(t / (self.l3 * 7.3) + 1.1)
            u = u + self.a3 * amp * np.sin(t / self.l3 + self.p3 + 1.4 * np.sin(t / (self.l3 * 4.1)))
        return u

    def river_du(self, t):
        return (self.u_drift / L + self.a1 / self.l1 * np.cos(t / self.l1 + self.p1) + self.a2 / self.l2 * np.cos(t / self.l2 + self.p2)
                + self.a3 / self.l3 * np.cos(t / self.l3 + self.p3))

    def river_dist(self, x, y):
        if self.a3 > 0:
            # Design Sprint: exakter Abstand zur Mittellinie (KD-Baum, Stuetzpunkte alle 4 m); die S7-Naeherung
            # |u - u(t)| / sqrt(1 + u'^2) erzeugt bei engen Maeandern Querstreifen im Talboden
            if self._kd is None:
                from scipy.spatial import cKDTree
                ts = np.arange(-B - 3000.0, L + B + 3000.0, 4.0)
                us = self.river_u(ts)
                pts = np.stack([us, ts], 1) if self.axis == "ns" else np.stack([ts, us], 1)
                self._kd = cKDTree(pts)
            xa, ya = np.broadcast_arrays(np.asarray(x, dtype=np.float64), np.asarray(y, dtype=np.float64))
            d, _ = self._kd.query(np.stack([xa.ravel(), ya.ravel()], 1))
            return d.reshape(xa.shape) if xa.ndim else float(d[0])
        t, u = self._tu(x, y)
        du = self.river_du(t)
        return np.abs(u - self.river_u(t)) / np.sqrt(1.0 + du * du)

    def river_level(self, x, y):
        t, _ = self._tu(x, y)
        if self.flow_sign > 0:
            return self.lv0 - (t + B) * 0.0014
        return self.lv0 - (L + B - t) * 0.0014

    def river_halfwidth(self, x, y):
        t, _ = self._tu(x, y)
        prog = (t + B) / (L + 2 * B) if self.flow_sign > 0 else (L + B - t) / (L + 2 * B)
        if self.P["fluss_v2"]:
            return self.breite0 + self.P["fl_bzu"] * prog + self.P["fl_bsin"] * np.sin(t / 530.0 + 2.0)
        return self.breite0 + 14.0 * prog + 4.0 * np.sin(t / 530.0 + 2.0)

    def river_points(self, step_m=100.0):
        """Mittellinie als Feldkoordinaten (x, y) innerhalb der Karte, fuer das JSON (fluesse.linie)."""
        ts = np.arange(0.0, L + 1.0, step_m)
        us = self.river_u(ts)
        pts = []
        for t, u in zip(ts, us):
            x, y = (u, t) if self.axis == "ns" else (t, u)
            pts.append((x / STEP, y / STEP))
        return pts

    # --- Hoehe
    def height(self, x, y):
        s = self.sv
        P = self.P
        if P["zonen"]:
            # Reliefzonen: z = 0 Ebene, 1 Huegelland (grossraeumig, ~7 km), Kuppen nur im Huegelland
            z = smoothstep(-0.15, 0.25, fbm(x, y, s + 7, P["zonen_wl"], 2, gain=0.4))
            amp = P["ebene_amp"] + (P["huegel_amp"] - P["ebene_amp"]) * z
            h = (self.base + fbm(x, y, s + 1, 3200.0, 3, gain=0.45) * amp
                 + fbm(x, y, s + 8, P["kuppen_wl"], 2, gain=0.4) * P["kuppen_amp"] * z
                 + fbm(x, y, s + 2, 420.0, 2) * P["detail_amp"])
        else:
            h = self.base + fbm(x, y, s + 1, 3200.0, 3, gain=0.45) * self.hills_amp + fbm(x, y, s + 2, 420.0, 2) * P["detail_amp"]
        # Massiv 1
        mx, my, R = self.m1
        d = np.hypot(x - mx, y - my)
        m = 1.0 - smoothstep(0.3 * R, 1.0 * R, d)
        rr = grat(x, y, s + 3, P["m1_wl"], P["m1_okt"], P["m1_gain"], P["grat"])
        h = h + m * (150.0 + np.power(np.clip(rr, 0, 1), P["m1_exp"]) * self.m1h)
        # Massiv 2 (klein)
        if self.m2 is not None:
            x2, y2, R2 = self.m2
            d2 = np.hypot(x - x2, y - y2)
            m2 = 1.0 - smoothstep(0.2 * R2, 1.05 * R2, d2)
            rr2 = grat(x, y, s + 4, P["m2_wl"], P["m2_okt"], P["m2_gain"], P["grat"])
            h = h + m2 * (110.0 + np.power(np.clip(rr2, 0, 1), P["m2_exp"]) * 460.0)
        # Gebirgsring am Rand (beginnt 1,2 km innerhalb der Kante sanft, 300 m aussen deutlich)
        ox = np.maximum(0.0, np.maximum(-x, x - L))
        oy = np.maximum(0.0, np.maximum(-y, y - L))
        o = np.sqrt(ox * ox + oy * oy)
        inner = np.minimum(np.minimum(x, L - x), np.minimum(y, L - y))   # Abstand zur Kante innen (>0 innen)
        o = np.where(o > 0, o, -inner)
        rr3 = grat(x, y, s + 5, P["rand_wl"], P["rand_okt"], P["rand_gain"], P["grat"])
        # Vorgebirge: Anstieg 1,4 km bis 0,2 km innerhalb der Kante (Gebirgsfuss fuer Bergbau an allen Seiten, TF2-artiger Rahmen)
        rim = smoothstep(-1400.0, -200.0, o)
        h = h + rim * (110.0 + np.power(np.clip(rr3, 0, 1), 1.4) * 170.0)
        mb = smoothstep(0.0, 4800.0, o)
        h = h + mb * (200.0 + np.power(np.clip(rr3, 0, 1), 1.4) * 1150.0)
        # Flusstal: Aue flach, Rinne gegraben
        dr = self.river_dist(x, y)
        lv = self.river_level(x, y)
        bank = lv + 3.0 + dr * 0.008
        h = bank + (h - bank) * smoothstep(P["tal_innen"], P["tal_aussen"], dr)
        h = np.maximum(h, lv + 1.5)
        w = self.river_halfwidth(x, y)
        c = 1.0 - smoothstep(w, w + 22.0, dr)
        h = h + (lv - 3.5 - h) * c
        return h

    def is_water(self, x, y):
        return self.river_dist(x, y) < self.river_halfwidth(x, y)


# ---------------------------------------------------------------- Feldgroessen

_KFFT = {}


def disk_kernel_n(r):
    yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
    return float((xx * xx + yy * yy <= r * r).sum())


def _kernel_fft(r, shape):
    key = (r, shape)
    if key not in _KFFT:
        yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
        k = (xx * xx + yy * yy <= r * r).astype(np.float64)
        k /= k.sum()
        kk = np.zeros(shape)
        kk[:2 * r + 1, :2 * r + 1] = k
        kk = np.roll(np.roll(kk, -r, axis=0), -r, axis=1)
        _KFFT[key] = np.fft.rfft2(kk)
    return _KFFT[key]


def disk_mean(a, r, edge=True):
    """Mittelwert ueber die Kreisscheibe (Radius r Felder); FFT-Faltung auf 1024er (bzw. 512er) Raster (Rand gespiegelt oder 0)."""
    S = 1024 if a.shape[0] > 256 else 512
    pad = r
    ap = np.zeros((S, S))
    H, W = a.shape
    if edge:
        ap[:H + 2 * pad, :W + 2 * pad] = np.pad(a, pad, mode="edge")
        off = pad
    else:
        ap[:H, :W] = a
        off = 0
    res = np.fft.irfft2(np.fft.rfft2(ap) * _kernel_fft(r, (S, S)), s=(S, S))
    return res[off:off + H, off:off + W]


def land_mean(sl, lw, r):
    """Mittel der Steigung ueber Landfelder im Kreis (sl = Steigung x Land, lw = Land 0/1)."""
    return disk_mean(sl, r) / np.maximum(disk_mean(lw, r), 1e-6)


def land_ring_mean(sl, lw, rmin, rmax):
    """Mittel der Steigung ueber Landfelder im Kreisring rmin..rmax."""
    n_out, n_in = disk_kernel_n(rmax), disk_kernel_n(rmin - 1)
    num = disk_mean(sl, rmax) * n_out - disk_mean(sl, rmin - 1) * n_in
    den = disk_mean(lw, rmax) * n_out - disk_mean(lw, rmin - 1) * n_in
    return num / np.maximum(den, 1e-6)


def ring_mean(a, rmin, rmax):
    """Mittelwert ueber den Kreisring rmin..rmax (ohne den Kern)."""
    n_out, n_in = disk_kernel_n(rmax), disk_kernel_n(rmin - 1)
    return (disk_mean(a, rmax) * n_out - disk_mean(a, rmin - 1) * n_in) / (n_out - n_in)


def ring_kernel(rmin, rmax):
    yy, xx = np.mgrid[-rmax:rmax + 1, -rmax:rmax + 1]
    d2 = xx * xx + yy * yy
    return ((d2 <= rmax * rmax) & (d2 > (rmin - 1) * (rmin - 1))).astype(np.float64)


def conv_full(a, k):
    from scipy.signal import fftconvolve
    return fftconvolve(a, k, mode="full")


def conv_same(a, k):
    """Summe ueber den Kern um jedes Feld (Rand = 0)."""
    from scipy.signal import fftconvolve
    return fftconvolve(a, k, mode="same")


def field_heights(nodes):
    """Hoehe je Feld = Mittel der 4 Ecken (Sim-Konvention)."""
    return (nodes[:-1, :-1] + nodes[:-1, 1:] + nodes[1:, :-1] + nodes[1:, 1:]) * 0.25


def field_slope_pm(h):
    """Steigung je Feld in Promille: max |dh| zu den 4 Nachbarfeldern / 25 m."""
    d = np.zeros_like(h)
    d[:, 1:] = np.maximum(d[:, 1:], np.abs(h[:, 1:] - h[:, :-1]))
    d[:, :-1] = np.maximum(d[:, :-1], np.abs(h[:, 1:] - h[:, :-1]))
    d[1:, :] = np.maximum(d[1:, :], np.abs(h[1:, :] - h[:-1, :]))
    d[:-1, :] = np.maximum(d[:-1, :], np.abs(h[1:, :] - h[:-1, :]))
    return np.rint(d / STEP * 1000.0).astype(np.int64)


def quantize(h_m):
    return np.clip(np.rint(h_m / H_SCALE), 0, 65535).astype(np.uint16)


# ---------------------------------------------------------------- Layout (Staedte + Industrien)

_yy, _xx = np.mgrid[-(GRID - 1):GRID, -(GRID - 1):GRID]
_DTAB = np.hypot(_xx, _yy)          # (2 GRID - 1)^2 Abstaende, dist_arr schneidet daraus aus
del _yy, _xx


class LayoutFail(Exception):
    pass


class Layout:
    def __init__(self, terr, rules, rng, verbose=False):
        self.t = terr
        self.R = rules
        self.rng = rng
        self.verbose = verbose
        self.cities = []      # dict(id, name, stufe, pop, x, y, radius)
        self.inds = []        # dict(id, typ, x, y, kette, revier)
        yy, xx = np.mgrid[0:GRID, 0:GRID]
        self._dcache = {}
        self.X = xx.astype(np.float64)
        self.Y = yy.astype(np.float64)
        self.margin = max(rules["karte"]["randabstand_industrie"]["felder"], rules["karte"]["randabstand_stadt"]["felder"])
        self.inside = (xx >= self.margin) & (xx < GRID - self.margin) & (yy >= self.margin) & (yy < GRID - self.margin)

    # --- Terrainklassen auf dem (ungestempelten) Feldraster
    def classify(self, nodes_m, water, fluss_dist_f, lv_f):
        R = self.R
        h = field_heights(nodes_m)
        self.h = h
        self.water = water
        self.fd = fluss_dist_f
        self.lv = lv_f
        self.slope = field_slope_pm(h)
        gk = R["gelaende_klassen"]
        # Umfeld-Steigung nur ueber Landfelder: Rinne und Ufersaum (Flussabstand <= 1,5 Felder) zaehlen nicht mit,
        # sonst waere kein Feld in Flussnaehe je "Ebene" (die gegrabene Rinne ist per Definition steil).
        land = (fluss_dist_f > 1.5) & ~water
        sl = np.where(land, self.slope, 0.0).astype(np.float64)
        lw = land.astype(np.float64)
        # Umfeld = Kreisring 10..R (Felder) ueber Landfelder ohne Plateau+Boeschung der Industrien (<= 9,5) und ohne
        # Stadtkern+Boeschung (<= Radius + 14,5): gestempelte Flaechen sind planiert. Gleiche Maske im Validator.
        self.r12 = gk["ebene"]["umfeld_radius_felder"]
        self.r20 = gk["gebirgsfuss"]["umfeld_radius_felder"]
        self.K12 = ring_kernel(10, self.r12)
        self.K20 = ring_kernel(10, self.r20)
        self.sl0 = np.where(land, self.slope, 0).astype(np.float64)
        self.base = {"n12": conv_same(self.sl0, self.K12), "d12": conv_same(land.astype(np.float64), self.K12),
                     "n20": conv_same(self.sl0, self.K20), "d20": conv_same(land.astype(np.float64), self.K20)}
        self.um9 = land_mean(sl, lw, 9)
        self.um18 = land_mean(sl, lw, 18)
        self.um32 = land_mean(sl, lw, 32)
        f = gk["flussnaehe"]["fluss_abstand_felder"]["max"]
        # Muehle am Fluss: Plateau (Radius 3) plus Ufer/Rinne (<= 2,5 Felder) frei -> Flussabstand 6,5..max-0,4 (Validator misst an der Polylinie)
        self.flussnaehe = (fluss_dist_f <= f - 0.4) & (fluss_dist_f >= 6.5) & ~water
        # Industrie-Plateau (Radius 3) darf kein Wasser enthalten: Flussabstand > 4,5 Felder
        self.trocken = fluss_dist_f > 4.5
        # Gebirgsfuss braucht Hoehe > 500 m im Umkreis 40 Felder (Lena) oder den Gebirgsring hinter der Kante (wie Validator)
        yy, xx = np.mgrid[0:GRID, 0:GRID]
        rand = np.minimum(np.minimum(xx, GRID - 1 - xx), np.minimum(yy, GRID - 1 - yy))
        self.hoch = (disk_mean((h > 500.0).astype(np.float64), 40) > 0.5 / disk_kernel_n(40)) | (rand <= 56)
        # Erreichbarkeit vor dem Stempeln wie im Validator (Strasse <= Grenze, Fluss an Stellen <= 8 Feldern): nur die groesste
        # zusammenhaengende Flaeche ist Bauland fuer Staedte und Industrien (keine Insel hinter Steilhaengen)
        bmax = BAU["bruecke_max_felder"]
        passable = (self.slope <= BAU["steigung_max_promille_strasse"]) & ~water
        passable |= water & ((WV.run_lengths(water, 1) <= bmax) | (WV.run_lengths(water, 0) <= bmax))
        comp = WV.label4(passable)
        cnt = np.bincount(comp[comp >= 0].ravel())
        self.inside &= comp == int(np.argmax(cnt))
        self.land0 = land
        self.aue0 = None
        self._applied = None
        self.refresh_um()
        self.aue0 = self.aue.copy()     # Aue vor dem Stempeln (Lena, Hinweis 5) -> Flussmaske Bit 2
        self.stats = {"ebene": int((self.ebene & self.inside).sum()), "aue": int((self.aue & self.inside).sum()),
                      "gebirgsfuss": int((self.fuss & self.inside).sum()), "flussnaehe": int((self.flussnaehe & self.inside).sum())}

    def _exclude(self, x, y, r):
        """Feld-Kreis (Radius r um Feld x,y) aus der Landmaske nehmen und die Ringsummen lokal nachfuehren."""
        R = int(math.ceil(r))
        x0, x1, y0, y1 = max(0, x - R), min(GRID, x + R + 1), max(0, y - R), min(GRID, y + R + 1)
        d = np.hypot(self.X[y0:y1, x0:x1] - x, self.Y[y0:y1, x0:x1] - y)
        rem = (d <= r) & self.land[y0:y1, x0:x1]
        if not rem.any():
            return
        self.land[y0:y1, x0:x1] &= ~rem
        rs = np.where(rem, self.slope[y0:y1, x0:x1], 0).astype(np.float64)
        rl = rem.astype(np.float64)
        for key, K in (("12", self.K12), ("20", self.K20)):
            k = K.shape[0] // 2
            dn = conv_full(rs, K)
            dd = conv_full(rl, K)
            # Ausgabe-Fenster (voll) beginnt bei (y0-k, x0-k); auf das Raster zuschneiden
            oy0, ox0 = y0 - k, x0 - k
            sy0, sx0 = max(0, -oy0), max(0, -ox0)
            ty0, tx0 = max(0, oy0), max(0, ox0)
            ty1, tx1 = min(GRID, oy0 + dn.shape[0]), min(GRID, ox0 + dn.shape[1])
            self.n[key][ty0:ty1, tx0:tx1] -= dn[sy0:sy0 + ty1 - ty0, sx0:sx0 + tx1 - tx0]
            self.d[key][ty0:ty1, tx0:tx1] -= dd[sy0:sy0 + ty1 - ty0, sx0:sx0 + tx1 - tx0]

    def refresh_um(self):
        """Umfeld-Steigungen (Ring 10..12 / 10..20) ueber Landfelder ohne gestempelte Flaechen der schon gesetzten Industrien und
        Staedte, damit der Validator (misst nach dem Stempeln, gleiche Maske) dieselben Werte sieht. Inkrementell."""
        jobs = [("i", i["x"], i["y"], 10.5) for i in self.inds] + [("c", c["x"], c["y"], c["radius"] + 15.5) for c in self.cities]
        if self._applied is not None and self._applied == jobs:
            return
        if self._applied is None or self._applied != jobs[:len(self._applied)] or \
                [j for j in self._applied if j not in jobs]:
            self.land = self.land0.copy()
            self.n = {"12": self.base["n12"].copy(), "20": self.base["n20"].copy()}
            self.d = {"12": self.base["d12"].copy(), "20": self.base["d20"].copy()}
            self._applied = []
        for j in jobs:
            if j not in self._applied:
                self._exclude(j[1], j[2], j[3])
                self._applied.append(j)
        self._applied = list(jobs)
        gk = self.R["gelaende_klassen"]
        n12, n20 = float(self.K12.sum()), float(self.K20.sum())
        self.um12 = np.where(self.d["12"] >= 0.2 * n12, self.n["12"] / np.maximum(self.d["12"], 1e-6), 0.0)
        self.um20 = np.where(self.d["20"] >= 0.2 * n20, self.n["20"] / np.maximum(self.d["20"], 1e-6), 0.0)
        e = gk["ebene"]
        self.ebene = (self.um12 < e["umfeld_steigung_max_promille"] - 8) & (self.h >= e["hoehe_m"]["min"]) & (self.h <= e["hoehe_m"]["max"]) & ~self.water
        a = gk["aue"]
        self.aue = self.ebene & (self.fd >= a["fluss_abstand_felder"]["min"] + 0.5) & (self.fd <= a["fluss_abstand_felder"]["max"] - 0.5) \
            & (self.h - self.lv <= a["hoehe_ueber_fluss_max_m"])
        g = gk["gebirgsfuss"]
        self.fuss = (self.um20 >= g["umfeld_steigung_promille"]["min"]) & (self.um20 <= g["umfeld_steigung_promille"]["max"]) \
            & (self.h >= g["hoehe_m"]["min"]) & (self.h <= g["hoehe_m"]["max"]) & self.hoch & ~self.water
        # Puffer: spaeter gesetzte Staedte/Industrien nehmen gestempelte (flache) Flaechen aus dem Umfeld, das hebt den Mittelwert
        self.fuss_streng = self.fuss & (self.um20 >= g["umfeld_steigung_promille"]["min"] + 10) & (self.um20 <= g["umfeld_steigung_promille"]["max"] - 25)

    def um_lokal(self, x, y, rmax, extra):
        """Umfeld-Steigung (Ring 10..rmax) an (x, y) wie im Validator: Landfelder ohne gestempelte Flaechen, zusaetzlich ohne
        die Plateaus (Radius 10,5) der Punkte in extra (noch nicht gesetzte Industrien desselben Reviers)."""
        x0, x1, y0, y1 = max(0, x - rmax), min(GRID, x + rmax + 1), max(0, y - rmax), min(GRID, y + rmax + 1)
        d = np.hypot(self.X[y0:y1, x0:x1] - x, self.Y[y0:y1, x0:x1] - y)
        ring = (d <= rmax) & (d > 9.0) & self.land[y0:y1, x0:x1]
        for (ex, ey) in extra:
            ring &= np.hypot(self.X[y0:y1, x0:x1] - ex, self.Y[y0:y1, x0:x1] - ey) > 10.5
        n_ring = float(((d <= rmax) & (d > 9.0)).sum())
        k = float(ring.sum())
        if k < 0.2 * n_ring:
            return 0.0
        return float(self.slope[y0:y1, x0:x1][ring].sum()) / k

    def revier_ok(self, pts):
        """Gelaende-Klassen der 4 Revier-Industrien mit allen 4 Plateaus ausgenommen (so misst der Validator)."""
        g = self.R["gelaende_klassen"]["gebirgsfuss"]["umfeld_steigung_promille"]
        e = self.R["gelaende_klassen"]["ebene"]["umfeld_steigung_max_promille"]
        allp = [(p["x"], p["y"]) for p in pts.values()]
        for typ, p in pts.items():
            if typ in ("kohlemine", "erzmine"):
                u = self.um_lokal(p["x"], p["y"], self.r20, allp)
                if not g["min"] + 5 <= u <= g["max"] - 12:
                    return False
            else:
                if self.um_lokal(p["x"], p["y"], self.r12, allp) >= e - 5:
                    return False
        return True

    # --- Hilfen
    def dist_arr(self, x, y):
        """Abstand jedes Feldes zu (x, y) als Ausschnitt einer festen Abstandstabelle (keine Rechnung je Aufruf)."""
        x, y = int(x), int(y)
        return _DTAB[GRID - 1 - y:2 * GRID - 1 - y, GRID - 1 - x:2 * GRID - 1 - x]

    def dist(self, a, b):
        return math.hypot(a["x"] - b["x"], a["y"] - b["y"])

    def pick(self, mask, prefer=None):
        idx = np.flatnonzero(mask)
        if idx.size == 0:
            return None
        if prefer is not None:
            pidx = np.flatnonzero(mask & prefer)
            if pidx.size > 0:
                idx = pidx
        i = int(idx[self.rng.integers(idx.size)])
        return i % GRID, i // GRID

    def city_radius(self, stufe):
        return self.R["staedte"]["stufen"][stufe]["zielradius"]["felder"]

    def nearest_city(self, x, y, min_stufe=None):
        best, bd = None, 1e9
        order = ["dorf", "kleinstadt", "stadt"]
        for c in self.cities:
            if min_stufe and order.index(c["stufe"]) < order.index(min_stufe):
                continue
            d = math.hypot(c["x"] - x, c["y"] - y)
            if d < bd:
                best, bd = c, d
        return best, bd

    def city_mask(self, typ_rule, with_max=True):
        """Abstand zu jeder Stadt >= max(typ.min, radius+6); naechste Stadt <= typ.max (with_max; in der Revier-Phase sind die
        Kleinstaedte noch nicht gesetzt, sie kommen im Ring 55-95 ums Stahlwerk und erfuellen das Maximum dann)."""
        ab = typ_rule["abstand_naechste_stadt"]
        puffer = max(self.R["abstand_stadt_regeln"]["puffer_felder"], STAMP_PUFFER)
        ok = np.ones((GRID, GRID), dtype=bool)
        near = np.full((GRID, GRID), 1e9)
        for c in self.cities:
            d = self.dist_arr(c["x"], c["y"])
            ok &= d >= max(ab["felder_min"], c["radius"] + puffer)
            near = np.minimum(near, d)
        if with_max and self.cities:
            ok &= near <= ab["felder_max"]
        return ok

    def ind_mask(self, typ):
        """Mindestabstand 12 zu allen, >= 160 zum gleichen Typ, Cluster: kein gleicher Typ bekommt 2 Nachbarn in 200."""
        R = self.R
        mind = max(22, R["industrie_plateau"]["mindestabstand_beliebige_industrien"]["felder"])   # >= 22: Boeschung (9,5) ausserhalb des Umfeld-Rings (<= 12) des Nachbarn
        r7 = R["r7_abstand_gleicher_typ"]
        ok = np.ones((GRID, GRID), dtype=bool)
        same = [i for i in self.inds if i["typ"] == typ]
        for i in self.inds:
            d = self.dist_arr(i["x"], i["y"])
            ok &= d >= mind
            if i["typ"] == typ:
                ok &= d >= r7["mindestabstand"]["felder"]
        cr = r7["cluster"]["radius"]["felder"]
        cmax = r7["cluster"]["max_gleicher_typ"]
        # Kandidat c: Nachbarn gleichen Typs in cr muessen < cmax bleiben, und kein Nachbar darf dadurch >= cmax Nachbarn bekommen
        cnt = np.zeros((GRID, GRID))
        for i in same:
            d = self.dist_arr(i["x"], i["y"])
            within = d <= cr
            cnt += within
            n_i = sum(1 for j in same if j is not i and math.hypot(i["x"] - j["x"], i["y"] - j["y"]) <= cr)
            if n_i >= cmax - 1:
                ok &= ~within
        ok &= cnt <= cmax - 1
        return ok

    def hoehe_mask(self, rule):
        hm = rule["hoehe_m"]
        return (self.h >= hm["min"]) & (self.h <= hm["max"])

    def add_ind(self, typ, x, y, kette, revier):
        n = sum(1 for i in self.inds if i["typ"] == typ) + 1
        d = {"id": "%s_%d" % (ID_PREFIX[typ], n), "typ": typ, "x": int(x), "y": int(y), "kette": kette, "revier": revier}
        self.inds.append(d)
        return d

    # --- Staedte
    def r8_block(self, typ):
        """R8 Anti-Spezialisierung: Felder, auf denen `typ` einer Stadt den 6. Typ in 80 Feldern braechte, sind gesperrt."""
        r8 = self.R["r8_zulieferer"]["anti_spezialisierung"]
        ok = np.ones((GRID, GRID), dtype=bool)
        for c in self.cities:
            typen = {i["typ"] for i in self.inds if math.hypot(i["x"] - c["x"], i["y"] - c["y"]) <= r8["radius"]["felder"]}
            if typ not in typen and len(typen) >= r8["max_verschiedene_typen"]:
                ok &= self.dist_arr(c["x"], c["y"]) > r8["radius"]["felder"]
        return ok

    def city_plan(self):
        R = self.R["staedte"]
        st = R["stufen"]
        rng = self.rng
        n = {s: int(rng.integers(st[s]["anzahl_auf_karte"]["min"], st[s]["anzahl_auf_karte"]["max"] + 1)) for s in STUFEN_}
        while sum(n.values()) > R["anzahl_gesamt"]["max"]:
            for s in ("dorf", "kleinstadt", "stadt"):
                if n[s] > st[s]["anzahl_auf_karte"]["min"]:
                    n[s] -= 1
                    break
        return n

    def city_base_mask(self, stufe):
        """Zulaessige Stadtzentren nur nach Gelaende und Abstaenden zu Staedten/Industrien (ohne Anker, ohne R8)."""
        R = self.R["staedte"]
        r = self.city_radius(stufe)
        um = {"dorf": self.um9, "kleinstadt": self.um18, "stadt": self.um32}[stufe]
        plat = R["plateau"]
        md = R["mindestabstand_zentrum"]
        mask = self.inside & (um < plat["steigung_max_promille"] * 2.2) & (self.h >= plat["hoehe_m"]["min"]) \
            & (self.h <= plat["hoehe_m"]["max"]) & (self.fd > r + 3) & ~self.water
        near = np.full((GRID, GRID), 1e9)
        for c in self.cities:
            d = self.dist_arr(c["x"], c["y"])
            if stufe == "dorf" or c["stufe"] == "dorf":
                mind = md["dorf_zu_jeder_stufe"]["felder"]
            elif stufe == "stadt" and c["stufe"] == "stadt":
                mind = md["stadt_stadt"]["felder"]
            elif stufe == "kleinstadt" and c["stufe"] == "kleinstadt":
                mind = md["kleinstadt_kleinstadt"]["felder"]
            else:
                mind = md["stadt_kleinstadt"]["felder"]
            mask &= d >= mind
            near = np.minimum(near, d)
        if self.cities:
            mask &= near <= R["nachbarstadt_max"]["felder"]
        return mask

    def place_city(self, stufe, name, anchor=None, prefer_extra=None, anchor_mask=None, free_mask=False):
        """Eine Stadt setzen. anchor = (x, y, rmin, rmax): Zentrum im Ring um einen Punkt (Revier-Kleinstadt)."""
        self.refresh_um()
        R = self.R["staedte"]
        st = R["stufen"]
        r = self.city_radius(stufe)
        um = {"dorf": self.um9, "kleinstadt": self.um18, "stadt": self.um32}[stufe]
        plat = R["plateau"]
        md = R["mindestabstand_zentrum"]
        puffer = max(self.R["abstand_stadt_regeln"]["puffer_felder"], STAMP_PUFFER)
        it = self.R["industrie_typen"]
        mask = self.inside & (um < plat["steigung_max_promille"] * 2.2) & (self.h >= plat["hoehe_m"]["min"]) \
            & (self.h <= plat["hoehe_m"]["max"]) & (self.fd > r + 3) & ~self.water
        dbg = [("gelaende", int(mask.sum()))]
        near = np.full((GRID, GRID), 1e9)
        for c in self.cities:
            d = self.dist_arr(c["x"], c["y"])
            if stufe == "dorf" or c["stufe"] == "dorf":
                mind = md["dorf_zu_jeder_stufe"]["felder"]
            elif stufe == "stadt" and c["stufe"] == "stadt":
                mind = md["stadt_stadt"]["felder"]
            elif stufe == "kleinstadt" and c["stufe"] == "kleinstadt":
                mind = md["kleinstadt_kleinstadt"]["felder"]
            else:
                mind = md["stadt_kleinstadt"]["felder"]
            mask &= d >= mind
            near = np.minimum(near, d)
        if self.cities:
            mask &= near <= R["nachbarstadt_max"]["felder"]
        dbg.append(("staedte", int(mask.sum())))
        for i in self.inds:
            ab = it[i["typ"]]["abstand_naechste_stadt"]
            mask &= self.dist_arr(i["x"], i["y"]) >= max(ab["felder_min"], r + puffer)
        dbg.append(("industrien", int(mask.sum())))
        if free_mask and anchor_mask is not None:
            mask &= anchor_mask
        if anchor is not None:
            da = self.dist_arr(anchor[0], anchor[1])
            mask &= (da >= anchor[2]) & (da <= anchor[3])
            dbg.append(("anker", int(mask.sum())))
            if anchor_mask is not None:
                mask &= anchor_mask
            dbg.append(("werkplatz", int(mask.sum())))
        # R8 Anti-Spezialisierung: hoechstens 5 verschiedene Typen in 80 Feldern um die neue Stadt
        r8 = self.R["r8_zulieferer"]["anti_spezialisierung"]
        typen = sorted({i["typ"] for i in self.inds})
        if len(typen) > r8["max_verschiedene_typen"]:
            cnt = np.zeros((GRID, GRID))
            for t in typen:
                m = np.zeros((GRID, GRID), dtype=bool)
                for i in self.inds:
                    if i["typ"] == t:
                        m |= self.dist_arr(i["x"], i["y"]) <= r8["radius"]["felder"]
                cnt += m
            mask &= cnt <= r8["max_verschiedene_typen"]
        prefer = (um < plat["steigung_max_promille"] * 1.2) & (self.fd > r + 6)
        if prefer_extra is not None:
            prefer &= prefer_extra
        p = self.pick(mask, prefer)
        if p is None:
            if self.verbose:
                print("    Stadt %s: %s, r8 %d" % (stufe, ", ".join("%s %d" % d for d in dbg), int(mask.sum())))
            raise LayoutFail("Stadt %s (%s): kein Platz" % (name, stufe))
        ew = st[stufe]["einwohner_anzahl"]
        pop = int(min(ew["max"], max(ew["min"], round(int(self.rng.integers(ew["min"], ew["max"] + 1)) / 50.0) * 50)))
        c = {"id": name.lower().replace("ö", "oe").replace("ü", "ue").replace("ä", "ae"), "name": name,
             "stufe": stufe, "pop": pop, "x": int(p[0]), "y": int(p[1]), "radius": r}
        self.cities.append(c)
        return c

    def annulus_count(self, mask, rmin, rmax):
        """Anzahl mask-Felder im Kreisring rmin..rmax um jedes Feld, auf 2x2-Bloecken gerechnet (FFT 512er, Naeherung x4)."""
        m = mask.reshape(GRID // 2, 2, GRID // 2, 2).any(axis=(1, 3)).astype(np.float64)
        r1, r0 = max(1, rmax // 2), max(0, (rmin - 1) // 2)
        outer = disk_mean(m, r1, edge=False) * disk_kernel_n(r1)
        inner = disk_mean(m, r0, edge=False) * disk_kernel_n(r0) if r0 >= 1 else 0.0
        c = (outer - inner) * 4.0
        return np.repeat(np.repeat(c, 2, axis=0), 2, axis=1)

    # --- Reviere (ohne Werkzeugfabrik; die kommt nach den Kleinstaedten)
    def place_revier(self, k, nische):
        self.refresh_um()
        R = self.R
        it = R["industrie_typen"]
        bands = {b["id"]: b for b in R["ketten_baender"]}
        kr, er, sr, kw = it["kohlemine"], it["erzmine"], it["stahlwerk"], it["kraftwerk"]
        k3b, k3a, k2a, k2b = (bands[x]["luftlinie"] for x in ("K3b", "K3a", "K2a", "K2b"))
        wr = it["werkzeugfabrik"]
        k3c = bands["K3c"]["luftlinie"]
        werk_pre = self.inside & self.ebene & ~self.water & self.trocken & self.hoehe_mask(wr) & self.city_mask(wr, False)
        eb_s = self.inside & self.ebene & (self.um12 < sr["gelaende"]["umfeld_steigung_max_promille"] - 8) & ~self.water & self.trocken \
            & self.hoehe_mask(sr) & self.city_mask(sr, False) & self.ind_mask("stahlwerk") \
            & (self.annulus_count(werk_pre, k3c["felder_min"] + 1, k3c["felder_max"] - 1) > 2)
        # Stahlwerk so zur Stadt, dass die Werkzeugfabrik eine Stadt >= Kleinstadt in 30-80 bekommt: entweder die Stadt selbst
        # (Stahl-Stadt <= 105) oder Platz fuer eine Revier-Kleinstadt im Ring 55-95 (Stadt-Kleinstadt >= 140 -> Stahl-Stadt >= 165)
        nah = np.zeros((GRID, GRID), dtype=bool)
        for c in self.cities:
            if c["stufe"] != "dorf":
                nah |= self.dist_arr(c["x"], c["y"]) <= 105
        ks_ok = self.city_base_mask("kleinstadt")
        eb_s &= nah | (self.annulus_count(ks_ok, 56, 94) > 0.5)
        eb_k = self.inside & self.ebene & (self.um12 < kw["gelaende"]["umfeld_steigung_max_promille"] - 8) & ~self.water & self.trocken \
            & self.hoehe_mask(kw) & self.city_mask(kw, False) & self.ind_mask("kraftwerk")
        fuss_e = self.inside & self.fuss_streng & self.trocken & self.hoehe_mask(er) & self.city_mask(er, False) & self.ind_mask("erzmine")
        kohle_base = self.inside & self.fuss_streng & self.trocken & self.hoehe_mask(kr) & self.city_mask(kr, False) & self.ind_mask("kohlemine")
        # Vorfilter (Ring-Zaehlung, 2x2-Naeherung): Erz-, Kraftwerk- und Stahl-Kandidaten in den Baendern vorhanden
        ab_e = kr["abstand_zu_erzmine"]
        kohle_base &= (self.annulus_count(fuss_e, ab_e["felder_min"], ab_e["felder_max"]) > 0.5) \
            & (self.annulus_count(eb_k, k2a["felder_min"] + 1, k2a["felder_max"] - 1) > 0.5) \
            & (self.annulus_count(eb_s, k3b["felder_min"] + 1, k3b["felder_max"] - 1) > 0.5)
        # Verteilung: moeglichst weit weg von den bisherigen Revieren (R7-Cluster), bevorzugt am Vorgebirge/Rand
        prev = [i for i in self.inds if i["typ"] == "kohlemine"]
        kidx = np.flatnonzero(kohle_base)
        if kidx.size == 0:
            raise LayoutFail("Revier %d: keine Kohle" % k)
        self.rng.shuffle(kidx)
        if prev:
            far = np.full((GRID, GRID), 1e9)
            for i in prev:
                far = np.minimum(far, self.dist_arr(i["x"], i["y"]))
            fern = far.flat[kidx] >= 230
            kidx = np.concatenate([kidx[fern][:40], kidx[~fern]])   # erst weit entfernte Kandidaten, dann alle
        found = None
        self.dbg = {"kand": int(kidx.size), "erz": 0, "kw": 0, "stahl": 0, "pair": 0}
        for ki in kidx[:200]:
            kohle = {"x": int(ki % GRID), "y": int(ki // GRID)}
            dk = self.dist_arr(kohle["x"], kohle["y"])
            erz_ok = fuss_e & (dk >= er["abstand_zu_kohlemine"]["felder_min"]) & (dk <= er["abstand_zu_kohlemine"]["felder_max"])
            if not erz_ok.any():
                self.dbg["erz"] += 1
                continue
            kw_ok = eb_k & (dk >= k2a["felder_min"]) & (dk <= k2a["felder_max"])
            if not kw_ok.any():
                self.dbg["kw"] += 1
                continue
            smask = eb_s & (dk >= k3b["felder_min"]) & (dk <= k3b["felder_max"])
            sidx = np.flatnonzero(smask)
            if sidx.size == 0:
                self.dbg["stahl"] += 1
                continue
            self.dbg["pair"] += 1
            if nische:
                pref = np.flatnonzero(smask & (dk >= 24) & (dk <= 26))
                if pref.size:
                    sidx = pref
            self.rng.shuffle(sidx)
            for si in sidx[:8]:
                stahl = {"x": int(si % GRID), "y": int(si // GRID)}
                ds = self.dist_arr(stahl["x"], stahl["y"])
                m_e = erz_ok & (ds >= k3a["felder_min"]) & (ds <= k3a["felder_max"])
                m_k = kw_ok & (ds >= k2b["felder_min"]) & (ds <= k2b["felder_max"])
                if not (m_e.any() and m_k.any()):
                    continue
                p = self.pick(m_e)
                erz = {"x": p[0], "y": p[1]}
                p = self.pick(m_k & (self.dist_arr(erz["x"], erz["y"]) >= 22))
                if p is None:
                    continue
                cand = {"kohlemine": kohle, "erzmine": erz, "stahlwerk": stahl, "kraftwerk": {"x": p[0], "y": p[1]}}
                if not self.revier_ok(cand):
                    continue
                # Platz fuer die Werkzeugfabrik (30-42 vom Stahlwerk, eben, >= 22 von allen Industrien inkl. dieser 4)
                wm = werk_pre & (ds >= k3c["felder_min"] + 1) & (ds <= k3c["felder_max"] - 1) & self.ind_mask("werkzeugfabrik")
                for q in cand.values():
                    wm &= self.dist_arr(q["x"], q["y"]) >= 22
                if wm.sum() < 4:
                    continue
                found = (kohle, erz, stahl, {"x": p[0], "y": p[1]})
                break
            if found:
                break
        if not found:
            raise LayoutFail("Revier %d: keine Kohle mit Stahl/Erz/Kraftwerk im Band" % k)
        kohle, erz, stahl, kraft = found
        rv = "r%d" % (k + 1)
        self.add_ind("kohlemine", kohle["x"], kohle["y"], "k2k3", rv)
        self.add_ind("erzmine", erz["x"], erz["y"], "k3", rv)
        self.add_ind("stahlwerk", stahl["x"], stahl["y"], "k3", rv)
        self.add_ind("kraftwerk", kraft["x"], kraft["y"], "k2", rv)

    def place_werkzeug(self, rv):
        """Werkzeugfabrik des Reviers rv: Ebene/Stadtrand, 30-42 vom Stahlwerk, naechste Stadt >= Kleinstadt 30-80, max 1 je Stadt."""
        self.refresh_um()
        R = self.R
        wr = R["industrie_typen"]["werkzeugfabrik"]
        k3c = {b["id"]: b for b in R["ketten_baender"]}["K3c"]["luftlinie"]
        stahl = next(i for i in self.inds if i["revier"] == rv and i["typ"] == "stahlwerk")
        belegt = {i["stadt"] for i in self.inds if i["typ"] == "werkzeugfabrik"}
        puffer = max(R["abstand_stadt_regeln"]["puffer_felder"], STAMP_PUFFER)
        ab = wr["abstand_naechste_stadt"]
        near_ks = np.full((GRID, GRID), 1e9)       # naechste Kleinstadt/Stadt (alle, fuer "naechste")
        near_frei = np.full((GRID, GRID), 1e9)     # naechste noch unbelegte
        ok_city = np.ones((GRID, GRID), dtype=bool)
        stadtrand = np.zeros((GRID, GRID), dtype=bool)
        for c in self.cities:
            dc = self.dist_arr(c["x"], c["y"])
            ok_city &= dc >= max(ab["felder_min"], c["radius"] + puffer)
            if c["stufe"] != "dorf":
                near_ks = np.minimum(near_ks, dc)
                if c["id"] not in belegt:
                    near_frei = np.minimum(near_frei, dc)
            aus = R["staedte"]["stufen"][c["stufe"]]["ausfransung"]["felder_max"]
            stadtrand |= (dc >= c["radius"]) & (dc <= c["radius"] + aus)
        ds = self.dist_arr(stahl["x"], stahl["y"])
        mask = self.inside & (self.um12 < wr["gelaende"]["umfeld_steigung_max_promille"] - 8) & (self.ebene | stadtrand) \
            & ~self.water & self.trocken & self.hoehe_mask(wr) & ok_city & (near_ks <= ab["felder_max"]) & (near_frei <= near_ks + 0.01) \
            & self.ind_mask("werkzeugfabrik") & self.r8_block("werkzeugfabrik") & (ds >= k3c["felder_min"]) & (ds <= k3c["felder_max"])
        p = self.pick(mask)
        if p is None:
            if self.verbose:
                band = (ds >= k3c["felder_min"]) & (ds <= k3c["felder_max"])
                steps = [("band", band), ("gel", (self.um12 < wr["gelaende"]["umfeld_steigung_max_promille"] - 8) & (self.ebene | stadtrand)),
                         ("trocken", ~self.water & self.trocken & self.hoehe_mask(wr)), ("city", ok_city), ("near", near_ks <= ab["felder_max"]),
                         ("frei", near_frei <= near_ks + 0.01), ("ind", self.ind_mask("werkzeugfabrik")), ("r8", self.r8_block("werkzeugfabrik"))]
                m_ = self.inside.copy()
                out = []
                for nm_, st_ in steps:
                    m_ &= st_
                    out.append("%s %d" % (nm_, int(m_.sum())))
                print("    Werkzeug %s: %s" % (rv, ", ".join(out)))
            raise LayoutFail("Revier %s: keine Werkzeugfabrik" % rv)
        w = self.add_ind("werkzeugfabrik", p[0], p[1], "k3", rv)
        c, _ = self.nearest_city(p[0], p[1], "kleinstadt")
        w["stadt"] = c["id"]

    # --- Agrarpaare
    def place_agrar(self, k, nische, aue_pflicht):
        self.refresh_um()
        R = self.R
        it = R["industrie_typen"]
        bands = {b["id"]: b for b in R["ketten_baender"]}
        mr = it["muehle"]
        puffer = max(R["abstand_stadt_regeln"]["puffer_felder"], STAMP_PUFFER)
        stadtrand = np.zeros((GRID, GRID), dtype=bool)
        hq_r = {"dorf": 55, "kleinstadt": 50, "stadt": 45}
        hq_frei = np.zeros((GRID, GRID), dtype=bool)   # HQ-Radius von Staedten ohne Rohstoff (PO: >= 3 Staedte mit Rohstoff)
        for c in self.cities:
            dc = self.dist_arr(c["x"], c["y"])
            aus = R["staedte"]["stufen"][c["stufe"]]["ausfransung"]["felder_max"]
            stadtrand |= (dc >= c["radius"] + puffer) & (dc <= c["radius"] + aus)
            if not any(i["typ"] in ("getreidefarm", "kohlemine", "erzmine") and math.hypot(i["x"] - c["x"], i["y"] - c["y"]) <= hq_r[c["stufe"]] for i in self.inds):
                hq_frei |= dc <= hq_r[c["stufe"]]
        fr = it["getreidefarm"]
        k1a = bands["K1a"]["luftlinie"]
        gel = self.aue if aue_pflicht else (self.ebene | self.aue)
        farm_base = self.inside & gel & (self.um12 < fr["gelaende"]["umfeld_steigung_max_promille"] - 8) & ~self.water \
            & (self.fd >= fr["fluss_abstand_min"]["felder"] + 0.6) & self.hoehe_mask(fr) & self.city_mask(fr, False) & self.ind_mask("getreidefarm") \
            & self.r8_block("getreidefarm")
        mmask = self.inside & (self.um12 < mr["gelaende"]["umfeld_steigung_max_promille"] - 8) & (self.flussnaehe | stadtrand) \
            & ~self.water & self.trocken & self.hoehe_mask(mr) & self.city_mask(mr, False) & self.ind_mask("muehle") & self.r8_block("muehle")
        mmask &= self.annulus_count(farm_base, k1a["felder_min"] + 1, k1a["felder_max"] - 1) > 0.5
        midx = np.flatnonzero(mmask)
        if midx.size == 0:
            raise LayoutFail("Agrar %d: keine Muehle" % k)
        self.rng.shuffle(midx)
        # Muehle bevorzugt weit weg von anderen Muehlen (R7-Cluster) und am Fluss; Farm bevorzugt im HQ-Radius einer Stadt ohne Rohstoff
        prev = [i for i in self.inds if i["typ"] == "muehle"]
        far = np.full((GRID, GRID), 1e9)
        for i in prev:
            far = np.minimum(far, self.dist_arr(i["x"], i["y"]))
        if prev:
            order = sorted(midx[:120], key=lambda i: (0 if far.flat[i] >= 230 else 1, 0 if self.flussnaehe.flat[i] else 1))
        else:
            # erste Muehle an ein Flussende (nahe Kartenrand), damit 2-3 weitere mit >= 200 Feldern Abstand Platz haben
            rand = np.minimum(np.minimum(self.X, GRID - 1 - self.X), np.minimum(self.Y, GRID - 1 - self.Y))
            order = sorted(midx[:200], key=lambda i: (0 if self.flussnaehe.flat[i] else 1, rand.flat[i]))
        for mi in order:
            muehle = {"x": int(mi % GRID), "y": int(mi // GRID)}
            dm = self.dist_arr(muehle["x"], muehle["y"])
            self.inds.append({"id": "tmp", "typ": "muehle", "x": muehle["x"], "y": muehle["y"], "kette": "k1", "revier": "tmp"})
            fmask = farm_base & (dm >= k1a["felder_min"]) & (dm <= k1a["felder_max"]) & self.r8_block("getreidefarm")
            self.inds.pop()
            if not fmask.any():
                continue
            prefer = fmask & hq_frei
            if nische:
                pn = fmask & (dm >= 24) & (dm <= 26)
                if pn.any():
                    prefer = pn & hq_frei if (pn & hq_frei).any() else pn
            p = self.pick(fmask, prefer)
            farm = {"x": p[0], "y": p[1]}
            ag = "a%d" % (k + 1)
            self.add_ind("muehle", muehle["x"], muehle["y"], "k1", ag)
            f = self.add_ind("getreidefarm", farm["x"], farm["y"], "k1", ag)
            f["aue"] = bool(self.aue[farm["y"], farm["x"]])
            return
        raise LayoutFail("Agrar %d: keine Farm zu einer Muehle" % k)

    def place_all(self):
        R = self.R
        it = R["industrie_typen"]
        rng = self.rng
        n = self.city_plan()
        names = list(STADT_NAMEN)
        rng.shuffle(names)
        ni = 0
        for _ in range(n["stadt"]):
            self.place_city("stadt", names[ni])
            ni += 1
        n_rev = min(int(rng.integers(it["kohlemine"]["anzahl"]["min"], it["kohlemine"]["anzahl"]["max"] + 1)), 4, n["kleinstadt"])
        n_min = it["kohlemine"]["anzahl"]["min"]
        for k in range(n_rev):
            try:
                self.place_revier(k, nische=(k == 0))
            except LayoutFail:
                if k < n_min:
                    raise
                n_rev = k          # 3 Reviere reichen (Lena: je Typ 3-6)
                break
        # Kleinstaedte: je Revier eine im Ring 55-95 um das Stahlwerk (Kraftwerk <= 120 von der Stadt) (Werkzeugfabrik 30-42 vom Stahl, 30-80 von der Stadt)
        for k in range(n["kleinstadt"]):
            anchor = None
            prefer = None
            anchor_mask = None
            if k < n_rev:
                rv = "r%d" % (k + 1)
                try:
                    self.place_werkzeug(rv)    # Stadt/Kleinstadt in 30-80 schon da (z. B. die Stadt): Kleinstadt frei setzen
                    werk_da = True
                except LayoutFail:
                    werk_da = False
            if k < n_rev and not werk_da:
                st = next(i for i in self.inds if i["revier"] == rv and i["typ"] == "stahlwerk")
                mines = [i for i in self.inds if i["revier"] == rv and i["typ"] in ("kohlemine", "erzmine")]
                d_other = min([math.hypot(c["x"] - st["x"], c["y"] - st["y"]) for c in self.cities if c["stufe"] != "dorf"] + [1e9])
                anchor = (st["x"], st["y"], 55, 95.0)   # Werkzeugfabrik 30-42 vom Stahl + 30-80 von dieser Stadt (place_werkzeug prueft "naechste")
                prefer = np.zeros((GRID, GRID), dtype=bool)
                for m in mines:
                    prefer |= self.dist_arr(m["x"], m["y"]) <= 50
                # Stadt nur dort, wo 30-80 entfernt ein Werkzeugfabrik-Platz (30-42 vom Stahlwerk, Ebene, Hoehe) liegt
                wr = it["werkzeugfabrik"]
                k3c = {b["id"]: b for b in R["ketten_baender"]}["K3c"]["luftlinie"]
                ds = self.dist_arr(st["x"], st["y"])
                werk_pre = self.inside & (self.um12 < wr["gelaende"]["umfeld_steigung_max_promille"] - 8) & ~self.water & self.trocken \
                    & self.hoehe_mask(wr) & self.ind_mask("werkzeugfabrik") & (ds >= k3c["felder_min"]) & (ds <= k3c["felder_max"])
                ab = wr["abstand_naechste_stadt"]
                anchor_mask = self.annulus_count(werk_pre, ab["felder_min"] + 2, ab["felder_max"] - 2) > 0.5
                prefer &= anchor_mask
            if anchor is None:
                # freie Kleinstadt: darf keiner Werkzeugfabrik naeher kommen als deren Stadt (R5 "naechste Stadt")
                extra = np.ones((GRID, GRID), dtype=bool)
                for w in (i for i in self.inds if i["typ"] == "werkzeugfabrik"):
                    c = next(c for c in self.cities if c["id"] == w["stadt"])
                    extra &= self.dist_arr(w["x"], w["y"]) > math.hypot(w["x"] - c["x"], w["y"] - c["y"]) + 1.0
                try:
                    self.place_city("kleinstadt", names[ni], None, prefer, extra, free_mask=True)
                except LayoutFail:
                    n_ks = sum(1 for c in self.cities if c["stufe"] == "kleinstadt")
                    if n_ks < R["staedte"]["stufen"]["kleinstadt"]["anzahl_auf_karte"]["min"]:
                        raise
                    continue          # Lena: 3-4 Kleinstaedte; die vierte entfaellt, wenn kein Platz ist
            else:
                # Revier-Kleinstadt + Werkzeugfabrik zusammen; scheitert die Fabrik, naechster Stadtplatz (bis 6x)
                for versuch in range(6):
                    self.place_city("kleinstadt", names[ni], anchor, prefer, anchor_mask)
                    try:
                        self.place_werkzeug("r%d" % (k + 1))
                        break
                    except LayoutFail:
                        self.cities.pop()
                        if versuch == 5:
                            raise
            ni += 1
        n_agr = min(int(rng.integers(it["muehle"]["anzahl"]["min"], it["muehle"]["anzahl"]["max"] + 1)), 4)
        for k in range(n_agr):
            try:
                self.place_agrar(k, nische=(k == 0), aue_pflicht=(k < 2))
            except LayoutFail:
                if k < it["muehle"]["anzahl"]["min"]:
                    raise
                n_agr = k
                break
        # Doerfer: je Agrarpaar ohne Stadt in 40-80 um die Muehle ein Dorf im Ring (bevorzugt mit der Farm im HQ-Radius 55)
        ab_m = it["muehle"]["abstand_naechste_stadt"]
        nd = 0
        for k in range(n_agr):
            if nd >= n["dorf"]:
                break
            ag = "a%d" % (k + 1)
            mu = next(i for i in self.inds if i["revier"] == ag and i["typ"] == "muehle")
            fa = next(i for i in self.inds if i["revier"] == ag and i["typ"] == "getreidefarm")
            if any(ab_m["felder_min"] <= math.hypot(c["x"] - mu["x"], c["y"] - mu["y"]) <= ab_m["felder_max"] for c in self.cities):
                continue
            prefer = self.dist_arr(fa["x"], fa["y"]) <= 55
            try:
                self.place_city("dorf", names[ni], (mu["x"], mu["y"], ab_m["felder_min"], ab_m["felder_max"]), prefer)
            except LayoutFail:
                raise LayoutFail("Agrar %d: kein Dorf 40-80 um die Muehle" % k)
            ni += 1
            nd += 1
        while nd < n["dorf"]:
            self.place_city("dorf", names[ni])
            ni += 1
            nd += 1
        self.check_r8_hq()

    def check_r8_hq(self):
        """R8 + PO-Entscheid (>= 3 Staedte mit Rohstoff im HQ-Radius) vor dem Stempeln; alles andere prueft der Validator."""
        R = self.R["r8_zulieferer"]
        hq_r = {"dorf": 55, "kleinstadt": 50, "stadt": 45}
        n_roh = 0
        for c in self.cities:
            typen240 = {}
            typen80 = set()
            roh = False
            for i in self.inds:
                d = math.hypot(i["x"] - c["x"], i["y"] - c["y"])
                if d <= R["nahversorgung"]["radius"]["felder"]:
                    typen240[i["typ"]] = typen240.get(i["typ"], 0) + 1
                if d <= R["anti_spezialisierung"]["radius"]["felder"]:
                    typen80.add(i["typ"])
                if d <= hq_r[c["stufe"]] and i["typ"] in ("getreidefarm", "kohlemine", "erzmine"):
                    roh = True
            if len(typen240) < R["nahversorgung"]["min_verschiedene_typen"]:
                raise LayoutFail("R8 Nahversorgung %s" % c["id"])
            if len(typen80) > R["anti_spezialisierung"]["max_verschiedene_typen"]:
                raise LayoutFail("R8 Anti-Spezialisierung %s" % c["id"])
            if WV.gini(list(typen240.values())) * 1000 >= R["gini"]["max_promille"]:
                raise LayoutFail("R8 Gini %s" % c["id"])
            n_roh += roh
        if n_roh < 3:
            raise LayoutFail("HQ: nur %d Staedte mit Rohstoff im Radius" % n_roh)


# ---------------------------------------------------------------- Stempeln + Ausgabe

def stamp(nodes, layout, rules, terr):
    """Plateaus: Stadtkern (Stufenradius) und Industrie (Radius 3) eben, Uebergangsring; danach Rinne neu graben."""
    N_ = nodes.shape[0]
    yy, xx = np.mgrid[0:N_, 0:N_]
    xx = xx.astype(np.float64)   # Knoten k liegt bei Feldkoordinate k (Ecke); Feldmitte = x + 0.5
    yy = yy.astype(np.float64)
    h = nodes.copy()
    jobs = []
    for c in layout.cities:
        jobs.append((c["x"] + 0.5, c["y"] + 0.5, c["radius"] + 2.5, 12.0))   # Boeschung <= 12 Felder (Validator rechnet damit)
    pr = rules["industrie_plateau"]["kern_radius_felder"]
    for i in layout.inds:
        jobs.append((i["x"] + 0.5, i["y"] + 0.5, pr + 2.5, 4.0))   # Boeschung 4 Felder (bis 9,5): Umfeld-Ring 10..R bleibt unberuehrt
    for (cx, cy, r_in, ring_max) in jobs:
        d = np.hypot(xx - cx, yy - cy)
        core = d <= r_in
        level = float(np.median(h[core])) if core.any() else float(h[int(cy), int(cx)])
        rand = (d > r_in) & (d <= r_in + 2.0)
        delta = float(np.abs(h[rand] - level).max()) if rand.any() else 0.0
        # Uebergangsring so breit, dass die Boeschung im Mittel <= 4 % bleibt (Strasse/Gleis bleiben baubar)
        r_out = r_in + float(np.clip(delta / (0.04 * STEP), 4.0, ring_max))
        w = 1.0 - smoothstep(r_in, r_out, d)
        h = h + (level - h) * w
    # Rinne/Ufer neu graben (Knotenkoordinaten in Metern)
    xm = xx * STEP
    ym = yy * STEP
    dr = terr.river_dist(xm, ym)
    w = terr.river_halfwidth(xm, ym)
    near = dr < w + 15.0
    if near.any():
        h[near] = terr.height(xm[near], ym[near])
    return h


def write_r16(path, arr16):
    with open(path, "wb") as f:
        f.write(arr16.astype("<u2").tobytes())


def write_png_gray(path, img8):
    """8-bit Graustufen-PNG (nur zur Ansicht), ohne Abhaengigkeiten."""
    hgt, wid = img8.shape
    raw = b"".join(b"\x00" + img8[y].tobytes() for y in range(hgt))

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", wid, hgt, 8, 0, 0, 0, 0)) \
        + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def gebirge_polygon(hf, terr, schwelle=450.0):
    """Polygon ums Massiv 1: 16 Strahlen vom Zentrum, je Strahl der aeusserste Punkt mit h > schwelle (Felder)."""
    cx, cy, R = terr.m1
    cx /= STEP
    cy /= STEP
    poly = []
    for k in range(16):
        a = 2 * math.pi * k / 16
        best = 6.0
        for r in np.arange(4.0, R / STEP * 1.3, 1.0):
            x = int(cx + math.cos(a) * r)
            y = int(cy + math.sin(a) * r)
            if 0 <= x < GRID and 0 <= y < GRID and hf[y, x] > schwelle:
                best = r
        poly.append([int(max(0, min(GRID - 1, cx + math.cos(a) * best))), int(max(0, min(GRID - 1, cy + math.sin(a) * best)))])
    return poly


def wald_polygone(layout, rng, n=6):
    """Wald-Achtecke auf huegeligem, nicht zu steilem Gelaende abseits von Staedten/Industrien."""
    out = []
    h = layout.h
    mask = layout.inside & (layout.um12 >= 25) & (layout.um12 <= 120) & (h >= 130) & (h <= 480) & ~layout.water
    for c in layout.cities:
        mask &= layout.dist_arr(c["x"], c["y"]) >= c["radius"] + 30
    for i in layout.inds:
        mask &= layout.dist_arr(i["x"], i["y"]) >= 14
    for k in range(n):
        p = layout.pick(mask)
        if p is None:
            break
        r = int(rng.integers(9, 16))
        poly = []
        for j in range(8):
            a = 2 * math.pi * j / 8
            rr = r * (0.75 + 0.5 * rng.random())
            poly.append([int(max(0, min(GRID - 1, p[0] + math.cos(a) * rr))), int(max(0, min(GRID - 1, p[1] + math.sin(a) * rr)))])
        out.append({"id": "wald_%d" % (k + 1), "typ": "wald", "polygon": poly})
        mask &= layout.dist_arr(p[0], p[1]) >= 2.5 * r
    return out


def r0(x):
    return int(math.floor(x + 0.5))


def build_map_json(layout, terr, rules, seed, gebirge_poly, waelder, fluss_breite_max):
    it = rules["industrie_typen"]
    staedte = [{"id": c["id"], "name": c["name"], "stufe": c["stufe"], "einwohner_anzahl": c["pop"], "x_felder": c["x"], "y_felder": c["y"]}
               for c in layout.cities]
    industrien = []
    for i in layout.inds:
        rule = it[i["typ"]]
        d = {"id": i["id"], "typ": i["typ"], "x_felder": i["x"], "y_felder": i["y"], "stufe": 1, "rolle": rule["rolle"], "im_slice": True,
             "eingang_gueter": list(rule.get("eingang", [])), "ausgang_gueter": list(rule.get("ausgang", []))}
        if rule.get("ausgang_art"):
            d["ausgang_art"] = rule["ausgang_art"]
        d["kette"] = i["kette"]
        industrien.append(d)
    by = {i["id"]: i for i in layout.inds}

    def ll(a, b):
        return r0(math.hypot(a["x"] - b["x"], a["y"] - b["y"]))

    def nearest_city_for(i, min_stufe=None):
        c, _ = layout.nearest_city(i["x"], i["y"], min_stufe)
        return c
    # Ketten
    k1 = {"id": "k1", "name": "Getreide - Muehle - Mehl - Stadt", "im_slice": True, "gueter": ["getreide", "mehl"], "strecken": []}
    k2 = {"id": "k2", "name": "Kohle - Kraftwerk (Energie-Radius 25)", "im_slice": True, "gueter": ["kohle"], "strecken": []}
    k3 = {"id": "k3", "name": "Erz + Kohle - Stahlwerk - Stahl - Werkzeugfabrik", "im_slice": True,
          "gueter": ["erz", "kohle", "stahl", "werkzeug"], "strecken": []}
    nischen = []
    for g in sorted({i["revier"] for i in layout.inds if i["revier"].startswith("a")}):
        mu = next(i for i in layout.inds if i["revier"] == g and i["typ"] == "muehle")
        for f in (i for i in layout.inds if i["revier"] == g and i["typ"] == "getreidefarm"):
            k1["strecken"].append({"von": f["id"], "nach": mu["id"], "luftlinie_felder": ll(f, mu)})
            if 24 <= ll(f, mu) <= 26:
                nischen.append({"von": f["id"], "nach": mu["id"], "luftlinie_felder": ll(f, mu), "soll_felder": 25,
                                "hinweis": "Farm -> Muehle: Lkw-Sammeln (<25) und Zug (ab 25) beide vertretbar (L-08 truck_zug_cross_fields)"})
        c = nearest_city_for(mu)
        k1["strecken"].append({"von": mu["id"], "nach": c["id"], "luftlinie_felder": ll(mu, c)})
    for g in sorted({i["revier"] for i in layout.inds if i["revier"].startswith("r")}):
        rv = {i["typ"]: i for i in layout.inds if i["revier"] == g}
        ko, er, st, kw, we = rv["kohlemine"], rv["erzmine"], rv["stahlwerk"], rv["kraftwerk"], rv["werkzeugfabrik"]
        k2["strecken"].append({"von": ko["id"], "nach": kw["id"], "luftlinie_felder": ll(ko, kw)})
        k2["strecken"].append({"von": kw["id"], "nach": st["id"], "luftlinie_felder": ll(kw, st), "hinweis": "Energie-Radius 25 (L-08 power_radius)"})
        k3["strecken"].append({"von": er["id"], "nach": st["id"], "luftlinie_felder": ll(er, st)})
        k3["strecken"].append({"von": ko["id"], "nach": st["id"], "luftlinie_felder": ll(ko, st)})
        if 24 <= ll(ko, st) <= 26:
            nischen.append({"von": ko["id"], "nach": st["id"], "luftlinie_felder": ll(ko, st), "soll_felder": 25,
                            "hinweis": "Kohle -> Stahlwerk: Lkw-Sammeln (<25) und Zug (ab 25) beide vertretbar (L-08 truck_zug_cross_fields)"})
        k3["strecken"].append({"von": st["id"], "nach": we["id"], "luftlinie_felder": ll(st, we)})
        c = layout.cities[[x["id"] for x in layout.cities].index(we["stadt"])]
        k3["strecken"].append({"von": we["id"], "nach": c["id"], "luftlinie_felder": ll(we, c)})
    # HQ-Optionen je Stadt
    hq_r = {"dorf": 55, "kleinstadt": 50, "stadt": 45}
    hq = []
    for c in layout.cities:
        r = hq_r[c["stufe"]]
        im_r = sorted(i["id"] for i in layout.inds if math.hypot(i["x"] - c["x"], i["y"] - c["y"]) <= r)
        typen = {by[i]["typ"] for i in im_r}
        if typen & {"kohlemine", "erzmine"}:
            arch, kette = "bergbau", "k3"
        elif typen & {"getreidefarm", "muehle"}:
            arch, kette = "agrar", "k1"
        elif typen:
            arch, kette = "handelsknoten", by[im_r[0]]["kette"].replace("k2k3", "k2")
        else:
            arch, kette = "handelsknoten", "keine"
        hq.append({"archetyp": arch, "stadt": c["id"], "im_slice": True, "radius_felder": r, "startkette": kette,
                   "industrien_im_radius": im_r, "bau_quelle": "keine"})
    fl_pts = [[r0(x), r0(y)] for x, y in terr.river_points()]
    fl_pts = [p for p in fl_pts if 0 <= p[0] < GRID and 0 <= p[1] < GRID]
    fl_name = FLUSS_NAMEN[seed % len(FLUSS_NAMEN)]
    gel = [{"id": "gebirge_1", "typ": "gebirge", "polygon": gebirge_poly}] + waelder
    return {
        "schema_version": 1,
        "status": {"stand": "entwurf", "stichtag": "2027-02-05", "version": "S7-W06 seed %d" % seed,
                   "hinweis": "Erzeugt von tools/world_gen.py (Seed %d) nach rules_s7.json; Karten-Freeze Ende Tag 7 (W-05). Aenderungen nur ueber den Generator." % seed},
        "karte": {"breite_felder": GRID, "hoehe_felder": GRID, "feld_mm": 1000, "ursprung": "oben_links", "x_achse": "ost", "y_achse": "sued",
                  "hinweis": "S7: 1 Feld = 25 m Darstellung (m_pro_feld), Sim in Feldern (feld_mm 1000). Hoehe je Feld aus world/data/hoehe_s7.r16, Fluss aus fluss_s7.u8 (siehe world_s7_meta.json)."},
        "staedte": staedte,
        "industrien": industrien,
        "gelaende": gel,
        "fluesse": [{"id": "fluss_1", "name": fl_name, "breite_felder": int(fluss_breite_max), "linie": fl_pts}],
        "ketten": [k1, k2, k3],
        "nischen": nischen,
        "hq_optionen": hq,
    }


# ---------------------------------------------------------------- HQ-Vorschau (Modellrechnung wie tools/hq_vorschau_gen.py, generisch)

def de(n):
    return f"{n:,}".replace(",", ".")


def zahl(x, nd=2):
    return f"{x:.{nd}f}".replace(".", ",")


def rdiv(z, n):
    q, r = divmod(abs(z), n)
    q += 1 if 2 * r >= n else 0
    return q if z >= 0 else -q


def build_vorschau(M, E, md5):
    RADIUS = {"dorf": E["hq"]["hq_radius_village_felder"], "kleinstadt": E["hq"]["hq_radius_town_felder"], "stadt": E["hq"]["hq_radius_city_felder"]}
    STUFE = {"dorf": "Dorf", "kleinstadt": "Kleinstadt", "stadt": "Stadt"}
    RABATT = E["lizenz"]["licence_discount_in_radius_promille"] / 1000
    AUFSCHLAG = E["lizenz"]["licence_surcharge_per_field_promille"] / 1000
    FELD_MM = M["karte"]["feld_mm"]
    IND = {i["id"]: i for i in M["industrien"] if i["typ"] != "holzfaeller"}
    LIZ_TYP = {i["id"] for i in E["industrien"] if i.get("ausgang_gut_id")}
    LIZ = {k for k, v in IND.items() if v["typ"] in LIZ_TYP}
    CITY = {s["id"]: s for s in M["staedte"]}
    FLUSS = M["fluesse"][0]["linie"]
    KETTE = {"k1": "Kette 1 Getreide, Mehl", "k2": "Kette 2 Kohle, Kraftwerk", "k3": "Kette 3 Erz, Kohle, Stahl, Werkzeug"}
    max_pop = max(x["einwohner_anzahl"] for x in M["staedte"])

    def dist(c, i):
        return math.hypot(i["x_felder"] - c["x_felder"], i["y_felder"] - c["y_felder"])

    def felder_spiel(c, i):
        dx, dy = (int(i["x_felder"]) - int(c["x_felder"])) * FELD_MM, (int(i["y_felder"]) - int(c["y_felder"])) * FELD_MM
        return rdiv(math.isqrt(dx * dx + dy * dy), FELD_MM)

    def inside(pt, poly):
        x, y = pt
        c = False
        for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]):
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
                c = not c
        return c

    def seg_dist(p, a, b):
        dx, dy = b[0] - a[0], b[1] - a[1]
        t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy)))
        return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)

    def kreuzt_fluss(a, b):
        def ccw(p, q, r):
            return (r[1] - p[1]) * (q[0] - p[0]) - (q[1] - p[1]) * (r[0] - p[0])
        for p, q in zip(FLUSS, FLUSS[1:]):
            if ccw(a, p, q) * ccw(b, p, q) < 0 and ccw(a, b, p) * ccw(a, b, q) < 0:
                return True
        return False

    def gelaende_anteile(c, r):
        n = 0
        cnt, sx, sy = {}, 0.0, 0.0
        for ix in range(-2 * r, 2 * r + 1):
            for iy in range(-2 * r, 2 * r + 1):
                x, y = ix / 2, iy / 2
                if x * x + y * y > r * r:
                    continue
                n += 1
                pt = (c["x_felder"] + x, c["y_felder"] + y)
                if not (0 <= pt[0] < GRID and 0 <= pt[1] < GRID):
                    continue
                for g in M["gelaende"]:
                    if inside(pt, g["polygon"]):
                        cnt[g["typ"]] = cnt.get(g["typ"], 0) + 1
                        if g["typ"] == "gebirge":
                            sx += x
                            sy += y
        anteil = {k: 100.0 * v / n for k, v in cnt.items()}
        ang = math.atan2(sy / cnt["gebirge"], sx / cnt["gebirge"]) if cnt.get("gebirge") else None
        return anteil, ang

    def kette_text(c, ids, label, extra=""):
        t = {}
        for i in ids:
            t.setdefault(IND[i]["typ"], []).append(r0(dist(c, IND[i])))
        teile = []
        for typ in ("getreidefarm", "muehle", "kohlemine", "erzmine", "kraftwerk", "stahlwerk", "werkzeugfabrik"):
            if typ in t:
                v = sorted(t[typ])
                teile.append(KURZ[typ] + " " + (" und ".join(str(x) for x in v) if len(v) <= 2 else ", ".join(str(x) for x in v)))
        return label + ": " + ", ".join(teile) + " Felder" + extra

    def absatz_text(c, kette_id, ids):
        """Absatzziel der Kette: naechste Stadt zur Muehle (k1) bzw. zur Werkzeugfabrik des Reviers (k3)."""
        for ch in M["ketten"]:
            if ch["id"] != kette_id:
                continue
            for s in ch["strecken"]:
                if s["von"] in ids and s["nach"] in CITY:
                    z = CITY[s["nach"]]
                    if z["id"] == c["id"]:
                        return ". Absatz: die Stadt selbst."
                    return ". Absatz %s %d Felder." % (z["name"], r0(dist(c, z)))
        return ""

    def bauen(sid):
        c = CITY[sid]
        stufe = c["stufe"]
        r = RADIUS[stufe]
        d = {i: dist(c, IND[i]) for i in IND}
        im_r = {i for i, v in d.items() if v <= r}
        nachfrage = c["einwohner_anzahl"] / 100 * E["saettigung"]["demand_per_100_inhabitants_einheiten_pro_periode"] * E["saettigung"]["demand_mult_promille_je_stufe"][stufe] / 1000
        dl = {i: felder_spiel(c, IND[i]) for i in LIZ}
        nl = min(dl, key=lambda i: (dl[i], i))
        if dl[nl] <= r:
            liz = f"Lizenzfaktor x{zahl(1 - RABATT)} ({NAME[IND[nl]['typ']]}, im Radius)"
        else:
            liz = f"Lizenzfaktor x{zahl(1 + AUFSCHLAG * (dl[nl] - r))} ({NAME[IND[nl]['typ']]}, {dl[nl]} Felder)"
        ketten = []
        kk = {"k1": set(), "k2": set(), "k3": set()}
        for i in im_r:
            k = IND[i]["kette"]
            if k == "k2k3":
                kk["k2"].add(i)
            else:
                kk[k].add(i)
        for k in ("k1", "k2", "k3"):
            if kk[k]:
                ids = kk[k]
                extra = absatz_text(c, k, ids) if k in ("k1", "k3") else ""
                if k == "k1" and extra and "Stadt selbst" not in extra and max(d[i] for i in ids) > r - 3:
                    extra = " (am Ringrand)" + extra
                ketten.append(kette_text(c, ids, KETTE[k], extra))
        hinweis = ""
        wagnis = not (im_r & LIZ)
        if wagnis:
            ids = {}
            for i in sorted(LIZ, key=lambda i: (d[i], i)):
                ids.setdefault(IND[i]["typ"], i)
            top = sorted(ids.values(), key=lambda i: (d[i], i))[:3]
            ketten.append("Nächste Lizenzen: " + ", ".join(f"{NAME[IND[i]['typ']]} {r0(d[i])}" for i in top) + " Felder.")
            hinweis = "Kette nur über Fernlizenzen erreichbar. Wagnis-Standort."
        anteil, ang = gelaende_anteile(c, r)
        fl = min(seg_dist((c["x_felder"], c["y_felder"]), FLUSS[i], FLUSS[i + 1]) for i in range(len(FLUSS) - 1))
        teile = []
        if fl <= 120:
            t = f"Fluss {r0(fl)} Felder entfernt"
            quer = [(i, a) for i in im_r for a in im_r if IND[i]["typ"] == "getreidefarm" and IND[a]["typ"] == "muehle"
                    and kreuzt_fluss((IND[i]["x_felder"], IND[i]["y_felder"]), (IND[a]["x_felder"], IND[a]["y_felder"]))]
            if quer:
                t += ", liegt zwischen Farm und Mühle: Brücke nötig"
            teile.append(t)
        if anteil.get("gebirge"):
            teile.append(f"Gebirge {RICHTUNG[int(((ang + math.pi / 8) % (2 * math.pi)) // (math.pi / 4))]}, {r0(anteil['gebirge'])} % des Radius: Bau am Hang teurer")
        if anteil.get("wald", 0) >= 3.0:
            teile.append(f"Wald {r0(anteil['wald'])} %")
        if fl > 120 and not anteil.get("gebirge"):
            teile.append("kein Fluss und kein Gebirge im Radius")
        out = {"radius": f"Radius {r} Felder", "wagnis": wagnis, "ketten": ketten,
               "groesse": f"{STUFE[stufe]}, {de(c['einwohner_anzahl'])} Einwohner, Nachfrage {r0(nachfrage)} E/min" + (" (größter Absatz)" if c["einwohner_anzahl"] == max_pop else ""),
               "lizenzfaktor": liz, "gelaende": "; ".join(teile), "hinweis": hinweis}
        # max. 6 Zeilen (hq_placement MAX_ROWS): Ketten kuerzen
        while 4 + len(out["ketten"]) - 1 + (1 if out["hinweis"] else 0) > 6 and len(out["ketten"]) > 1:
            out["ketten"].pop()
        return out
    return {"quelle": "W-06 Felix (Modellrechnung wie T-14b/S6 B-1), erzeugt aus world_s7.json md5 %s und economy_slice.json durch tools/world_gen.py" % md5,
            "staedte": {s["id"]: bauen(s["id"]) for s in M["staedte"]}}


# ---------------------------------------------------------------- Hauptlauf

def generate(seed, rules, verbose=True):
    """Erzeugt die Welt zu einem Seed. Gibt dict mit Arrays und JSONs zurueck; wirft LayoutFail, wenn alle Versuche scheitern."""
    log = (lambda *a: print(*a)) if verbose else (lambda *a: None)
    xs = np.arange(N) * STEP
    xm, ym = np.meshgrid(xs, xs)
    xb = -B + np.arange(NB) * OSTEP
    xbm, ybm = np.meshgrid(xb, xb)
    fx = (np.arange(GRID) + 0.5) * STEP
    fxm, fym = np.meshgrid(fx, fx)
    for variant in range(MAX_VERSUCHE_TERRAIN):
        terr = Terrain(seed, variant, rules)
        nodes = terr.height(xm, ym)
        water = terr.is_water(fxm, fym)
        fd = terr.river_dist(fxm, fym) / STEP
        lv = terr.river_level(fxm, fym)
        rng = np.random.Generator(np.random.PCG64([seed, variant, 77]))
        lay = Layout(terr, rules, rng, verbose)
        lay.classify(nodes, water, fd, lv)
        log("Seed %d Terrain-Variante %d: Fluss %s, Massiv (%d,%d) R %d m, Klassen %s" % (
            seed, variant, terr.axis, terr.m1[0], terr.m1[1], terr.m1[2], lay.stats))
        for attempt in range(MAX_VERSUCHE_LAYOUT):
            lay.cities, lay.inds = [], []
            try:
                lay.place_all()
            except LayoutFail as e:
                log("  Versuch %d: %s" % (attempt, e))
                continue
            # Stempeln, Rohdaten, Validator
            nodes2 = stamp(nodes, lay, rules, terr)
            h16 = quantize(nodes2)
            border = terr.height(xbm, ybm)
            # Randknoten auf der spielbaren Kante mit den (gestempelten) Innenknoten gleichsetzen
            b16 = quantize(border)
            b16[INNER0:INNER0 + 129, INNER0:INNER0 + 129] = h16[::4, ::4]
            fl = np.zeros((GRID, GRID), dtype=np.uint8)
            fl[water] |= 1
            fl[lay.aue0 & ~water] |= 2
            hf = field_heights(h16.astype(np.float64) * H_SCALE)
            gp = gebirge_polygon(hf, terr)
            waelder = wald_polygone(lay, rng)
            breite = WV.fluss_breite_max(fl)
            M = build_map_json(lay, terr, rules, seed, gp, waelder, min(breite, 16))
            meta = {
                "seed": seed, "terrain_variante": variant, "layout_versuch": attempt,
                "felder": GRID, "m_pro_feld": STEP, "knoten": N, "hoehe_skala_m": H_SCALE,
                "rand": {"knoten": NB, "raster_m": OSTEP, "ursprung_m": -B, "innen_ab_knoten": INNER0, "breite_m": B},
                "hoehe_min_m": float(round(hf.min(), 2)), "hoehe_max_m": float(round(hf.max(), 2)),
                "fluss": {"achse": terr.axis, "pegel_einlauf_m": round(terr.lv0, 2), "gefaelle_promille": 1.4, "breite_max_felder": int(breite),
                          "maske_bits": {"rinne": 1, "aue": 2}},
                "bau": dict(BAU),
                "md5": {},
            }
            res = {"nodes16": h16, "border16": b16, "fluss": fl, "map": M, "meta": meta, "hf": hf, "terr": terr, "layout": lay}
            viol = WV.validate_data(M, h16, fl, meta, rules)
            if viol:
                log("  Versuch %d: Validator %d Verstoesse: %s" % (attempt, len(viol), "; ".join(viol[:4])))
                continue
            log("  Versuch %d OK: %d Staedte, %d Industrien, Hoehe %.0f-%.0f m, Fluss max %d Felder" % (
                attempt, len(M["staedte"]), len(M["industrien"]), hf.min(), hf.max(), breite))
            return res
    raise LayoutFail("Seed %d: keine gueltige Karte in %d Terrain-Varianten" % (seed, MAX_VERSUCHE_TERRAIN))


def write_all(res, out_dir, eco_path, shots_dir=None):
    os.makedirs(out_dir, exist_ok=True)
    p_h = os.path.join(out_dir, "hoehe_s7.r16")
    p_b = os.path.join(out_dir, "rand_s7.r16")
    p_f = os.path.join(out_dir, "fluss_s7.u8")
    write_r16(p_h, res["nodes16"])
    write_r16(p_b, res["border16"])
    with open(p_f, "wb") as f:
        f.write(res["fluss"].tobytes())
    meta = res["meta"]
    meta["md5"] = {k: hashlib.md5(open(p, "rb").read()).hexdigest() for k, p in (("hoehe_s7.r16", p_h), ("rand_s7.r16", p_b), ("fluss_s7.u8", p_f))}
    with open(os.path.join(out_dir, "world_s7_meta.json"), "w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=1, sort_keys=True)
        f.write("\n")
    p_map = os.path.join(out_dir, "world_s7.json")
    with open(p_map, "w", encoding="utf-8") as f:
        json.dump(res["map"], f, ensure_ascii=False, indent=1)
        f.write("\n")
    md5 = hashlib.md5(open(p_map, "rb").read()).hexdigest()
    E = json.load(open(eco_path, encoding="utf-8"))
    vs = build_vorschau(res["map"], E, md5)
    with open(os.path.join(out_dir, "hq_vorschau_s7.json"), "w", encoding="utf-8") as f:
        json.dump(vs, f, ensure_ascii=False, indent=2)
        f.write("\n")
    if shots_dir:
        os.makedirs(shots_dir, exist_ok=True)
        hf = res["hf"]
        img = np.clip(hf / 1500.0 * 255.0, 0, 255).astype(np.uint8)
        img[res["fluss"] & 1 == 1] = 0
        for c in res["map"]["staedte"]:
            img[max(0, c["y_felder"] - 3):c["y_felder"] + 4, max(0, c["x_felder"] - 3):c["x_felder"] + 4] = 255
        for i in res["map"]["industrien"]:
            img[max(0, i["y_felder"] - 1):i["y_felder"] + 2, max(0, i["x_felder"] - 1):i["x_felder"] + 2] = 255
        write_png_gray(os.path.join(shots_dir, "world_gen_seed%d_hoehe.png" % meta["seed"]), img)
        bb = np.clip(res["border16"].astype(np.float64) * H_SCALE / 1800.0 * 255.0, 0, 255).astype(np.uint8)
        write_png_gray(os.path.join(shots_dir, "world_gen_seed%d_rand.png" % meta["seed"]), bb)
    return meta["md5"], md5


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED)
    ap.add_argument("--out", default=os.path.join(HERE, "..", "world", "data"))
    ap.add_argument("--rules", default=os.path.join(HERE, "..", "world", "data", "rules_s7.json"))
    ap.add_argument("--eco", default=os.path.join(HERE, "..", "data", "economy_slice.json"))
    ap.add_argument("--shots", default=None, help="Ordner fuer Vorschau-PNGs (optional)")
    ap.add_argument("--sweep", default=None, help="A..B: Seeds durchprobieren, nur Statistik")
    ap.add_argument("--dry", action="store_true", help="nichts schreiben")
    ap.add_argument("--quiet", action="store_true")
    ap.add_argument("--relief", default="s7", choices=sorted(RELIEF), help="Relief-Profil (Design Sprint Welt)")
    a = ap.parse_args()
    global PROFIL
    PROFIL = RELIEF[a.relief]
    rules = json.load(open(a.rules, encoding="utf-8"))
    if a.sweep:
        lo, hi = (int(v) for v in a.sweep.split(".."))
        ok = []
        for s in range(lo, hi + 1):
            try:
                r = generate(s, rules, verbose=not a.quiet)
                m = r["meta"]
                print("SEED %d OK  variante %d versuch %d  staedte %d industrien %d  hoehe %.0f-%.0f m fluss<=%d" % (
                    s, m["terrain_variante"], m["layout_versuch"], len(r["map"]["staedte"]), len(r["map"]["industrien"]),
                    m["hoehe_min_m"], m["hoehe_max_m"], m["fluss"]["breite_max_felder"]))
                ok.append(s)
            except LayoutFail as e:
                print("SEED %d FAIL %s" % (s, e))
        print("Sweep %d..%d: %d/%d Seeds gueltig: %s" % (lo, hi, len(ok), hi - lo + 1, ok))
        return 0
    res = generate(a.seed, rules, verbose=not a.quiet)
    if a.dry:
        return 0
    md5s, mmd5 = write_all(res, os.path.abspath(a.out), a.eco, a.shots)
    print("geschrieben nach %s: world_s7.json md5 %s, %s" % (os.path.abspath(a.out), mmd5, md5s))
    return 0


if __name__ == "__main__":
    sys.exit(main())
