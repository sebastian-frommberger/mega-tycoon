#!/usr/bin/env python3
"""Gemeinsame Geometrie fuer die Stadt-Rolle (Phase 4, Welle 1): Gelaende, Masken, Zufall, Geometrie.

Alle Koordinaten lokal in Metern, Ursprung = NW-Ecke des Kerns, +x Ost, +z Sued.
Hoehen kommen direkt aus ws_c/_out/ds_v2 (hoehe_s7.r16 513x513 Knoten x 0,05 m, fluss_s7.u8 512x512).
Nur numpy + Standardbibliothek (scipy wird nicht gebraucht), damit der Generator ueberall laeuft.
"""
import heapq
import json
import math
import os

import numpy as np

# ---------------------------------------------------------------- Pfade
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)  # Arbeitskopie (Repo-Wurzel)
SRC_DEFAULT = "/tmp/claude-0/gd/designsprint/ws_c/_out/ds_v2"
VORGABE_DEFAULT = "/tmp/claude-0/gd/designsprint/p4/shared/ausschnitt_vorgabe.json"
OUT_DIR = os.path.join(ROOT, "slice", "world", "data", "proto")
BILD_DIR = os.path.join(ROOT, "_out", "bilder")

# ---------------------------------------------------------------- Fenster (Vorgabe, fest)
M_FELD = 25.0
KERN_Z0, KERN_S0 = 332, 160
RAND = 40
ROW0, COL0 = KERN_Z0 - RAND, KERN_S0 - RAND  # 292, 120 (Knoten/Felder des Gesamtfensters)
NX, NZ = 160, 144  # Felder
X_MIN, Z_MIN = -1000.0, -1000.0
KERN_B, KERN_T = 2000.0, 1600.0

# ---------------------------------------------------------------- Konstanten Wasser (Vorgabe + TA-Stand 03.11. 06:40)
SEE_MITTE = (1212.5, 1012.5)
SEE_R = 75.0     # WA-12: Binsensee auf Teichgroesse (Aequivalentdurchmesser 143,7 m <= 150 m, Kartentyp Flusstal); vorher 250 m (494 m)
SEE_PEGEL = 44.8
SEE_UFER_RAUSCHEN = 0.07  # TA proto_see.json: r_eff = r * (1 + (...)*staerke/0.07)
SEE_PHASE = 0.0
SEE_BOESCHUNG = 40.0
MUEHLTEICH_MITTE = (1612.5, 1150.0)  # TA-Vorschlag, hier uebernommen
MUEHLTEICH_R = 45.0
MUEHLE_VORSCHLAG = (1600.5, 1088.0)
BACH_SAUM = 17.5  # TA: Gehoelzsaum 2,5-17,5 m je Seite
BACH_PUNKTE = [(1662.5, 1487.5), (1662.5, 1412.5), (1662.5, 1337.5), (1612.5, 1262.5), (1612.5, 1187.5),
               (1612.5, 1112.5), (1562.5, 1037.5), (1487.5, 962.5), (1462.5, 887.5), (1462.5, 812.5),
               (1462.5, 737.5), (1462.5, 662.5), (1462.5, 587.5)]


# ---------------------------------------------------------------- Zufall: PCG32 (plattform- und versionsstabil)
class PCG:
    """PCG32 (XSH-RR). Alles ueber ganze Zahlen, damit md5-stabil auf jeder Python-Version."""
    MULT = 6364136223846793005
    MASK = (1 << 64) - 1

    def __init__(self, seed, seq=54):
        self.state = 0
        self.inc = ((seq << 1) | 1) & self.MASK
        self._next()
        self.state = (self.state + (seed & self.MASK)) & self.MASK
        self._next()

    @staticmethod
    def hash_seed(*teile):
        """FNV-1a ueber die Textform der Teile (stabil, unabhaengig von hash())."""
        h = 0xcbf29ce484222325
        for t in teile:
            for b in str(t).encode("utf-8") + b"\x1f":
                h ^= b
                h = (h * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
        return h

    def _next(self):
        old = self.state
        self.state = (old * self.MULT + self.inc) & self.MASK
        xs = (((old >> 18) ^ old) >> 27) & 0xFFFFFFFF
        rot = old >> 59
        return ((xs >> rot) | (xs << ((-rot) & 31))) & 0xFFFFFFFF

    def u32(self):
        return self._next()

    def random(self):
        return self._next() / 4294967296.0

    def uniform(self, a, b):
        return a + (b - a) * self.random()

    def randint(self, a, b):
        """inklusive a..b"""
        return a + int(self.random() * (b - a + 1))

    def choice(self, seq):
        return seq[int(self.random() * len(seq))]

    def weighted(self, items):
        """items = [(wert, gewicht)]"""
        tot = sum(w for _, w in items)
        r = self.random() * tot
        acc = 0.0
        for v, w in items:
            acc += w
            if r < acc:
                return v
        return items[-1][0]

    def shuffle(self, lst):
        for i in range(len(lst) - 1, 0, -1):
            j = int(self.random() * (i + 1))
            lst[i], lst[j] = lst[j], lst[i]
        return lst

    def normal(self):
        u1 = max(self.random(), 1e-12)
        u2 = self.random()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(2 * math.pi * u2)


# ---------------------------------------------------------------- Gelaende
class Gelaende:
    def __init__(self, src=SRC_DEFAULT):
        h = np.fromfile(os.path.join(src, "hoehe_s7.r16"), dtype="<u2").reshape(513, 513) * 0.05
        f = np.fromfile(os.path.join(src, "fluss_s7.u8"), dtype="u1").reshape(512, 512)
        self.H = np.ascontiguousarray(h[ROW0:ROW0 + NZ + 1, COL0:COL0 + NX + 1]).astype(np.float64)  # 145 x 161 Knoten
        self.F = np.ascontiguousarray(f[ROW0:ROW0 + NZ, COL0:COL0 + NX])  # 144 x 160 Felder
        self.rinne = (self.F & 1) > 0
        self.aue = (self.F & 2) > 0
        self._rinne_dist = None
        self._bach = np.array(BACH_PUNKTE, dtype=np.float64)

    # ---- Hoehe (bilinear ueber die Knoten, wie die Szene)
    def hoehe(self, x, z):
        u = (x - X_MIN) / M_FELD
        v = (z - Z_MIN) / M_FELD
        j = int(min(max(math.floor(u), 0), NX - 1))
        i = int(min(max(math.floor(v), 0), NZ - 1))
        a = min(max(u - j, 0.0), 1.0)
        b = min(max(v - i, 0.0), 1.0)
        H = self.H
        return (H[i, j] * (1 - a) * (1 - b) + H[i, j + 1] * a * (1 - b) +
                H[i + 1, j] * (1 - a) * b + H[i + 1, j + 1] * a * b)

    def steigung(self, x, z, d=8.0):
        """Betrag des Gefaelles in Prozent (zentrale Differenz ueber +-d m)."""
        gx = (self.hoehe(x + d, z) - self.hoehe(x - d, z)) / (2 * d)
        gz = (self.hoehe(x, z + d) - self.hoehe(x, z - d)) / (2 * d)
        return 100.0 * math.hypot(gx, gz)

    def feld(self, x, z):
        j = int(math.floor((x - X_MIN) / M_FELD))
        i = int(math.floor((z - Z_MIN) / M_FELD))
        return min(max(i, 0), NZ - 1), min(max(j, 0), NX - 1)

    def in_rinne(self, x, z):
        i, j = self.feld(x, z)
        return bool(self.rinne[i, j])

    def in_aue(self, x, z):
        i, j = self.feld(x, z)
        return bool(self.aue[i, j])

    def rinne_abstand(self, x, z):
        """Abstand zur naechsten Rinnenzelle (Mitte-zu-Mitte minus halbes Feld), Meter. 0 in der Rinne."""
        if self._rinne_dist is None:
            self._rinne_dist = _edt(~self.rinne) * M_FELD
        i, j = self.feld(x, z)
        return max(0.0, float(self._rinne_dist[i, j]) - 0.5 * M_FELD)

    # ---- Wasser
    def see_reff(self, x, z):
        t = math.atan2(z - SEE_MITTE[1], x - SEE_MITTE[0])
        s = SEE_PHASE
        k = SEE_UFER_RAUSCHEN / 0.07
        return SEE_R * (1 + (math.sin(3 * t + 0.7 + s) * 0.035 + math.sin(5 * t + 2.1 + 1.3 * s) * 0.025 +
                             math.sin(8 * t + 4.0 + 0.4 * s) * 0.012) * k)

    def see_abstand(self, x, z):
        """Abstand zur Uferlinie des Sees (negativ = im Wasser)."""
        return math.hypot(x - SEE_MITTE[0], z - SEE_MITTE[1]) - self.see_reff(x, z)

    def muehlteich_abstand(self, x, z):
        return math.hypot(x - MUEHLTEICH_MITTE[0], z - MUEHLTEICH_MITTE[1]) - MUEHLTEICH_R

    def bach_abstand(self, x, z):
        return poly_abstand((x, z), self._bach)[0]


def _edt(mask):
    """Euklidische Distanztransformation (exakt, Felzenszwalb) fuer boolsche Maske: Abstand zum naechsten False."""
    INF = 1e20
    h, w = mask.shape
    f = np.where(mask, INF, 0.0)
    # Spalten
    d = np.empty_like(f)
    for j in range(w):
        d[:, j] = _edt1(f[:, j])
    out = np.empty_like(f)
    for i in range(h):
        out[i, :] = _edt1(d[i, :])
    return np.sqrt(out)


def _edt1(f):
    n = len(f)
    INF = 1e30
    v = [0] * n
    z = [0.0] * (n + 1)
    k = 0
    z[0] = -INF
    z[1] = INF
    for q in range(1, n):
        while True:
            s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2.0 * q - 2.0 * v[k])
            if s <= z[k]:
                k -= 1
            else:
                break
        k += 1
        v[k] = q
        z[k] = s
        z[k + 1] = INF
    d = np.zeros(n)
    k = 0
    for q in range(n):
        while z[k + 1] < q:
            k += 1
        d[q] = (q - v[k]) ** 2 + f[v[k]]
    return d


# ---------------------------------------------------------------- Geometrie
def poly_abstand(p, poly):
    """(Abstand, Index, t) von Punkt p zur Polylinie poly (N x 2)."""
    px, pz = p
    best = (1e18, 0, 0.0)
    for k in range(len(poly) - 1):
        x1, z1 = poly[k]
        x2, z2 = poly[k + 1]
        dx, dz = x2 - x1, z2 - z1
        L = dx * dx + dz * dz
        t = 0.0 if L == 0 else max(0.0, min(1.0, ((px - x1) * dx + (pz - z1) * dz) / L))
        d = math.hypot(px - (x1 + t * dx), pz - (z1 + t * dz))
        if d < best[0]:
            best = (d, k, t)
    return best


def poly_laenge(poly):
    return float(sum(math.hypot(poly[k + 1][0] - poly[k][0], poly[k + 1][1] - poly[k][1]) for k in range(len(poly) - 1)))


def resample(poly, schritt):
    """Polylinie gleichmaessig abtasten (Start und Ende bleiben)."""
    poly = [tuple(map(float, p)) for p in poly]
    L = poly_laenge(poly)
    if L == 0:
        return poly
    n = max(1, int(round(L / schritt)))
    ziel = [L * i / n for i in range(n + 1)]
    out = []
    acc = 0.0
    k = 0
    for s in ziel:
        while k < len(poly) - 2 and acc + math.hypot(poly[k + 1][0] - poly[k][0], poly[k + 1][1] - poly[k][1]) < s - 1e-9:
            acc += math.hypot(poly[k + 1][0] - poly[k][0], poly[k + 1][1] - poly[k][1])
            k += 1
        seg = math.hypot(poly[k + 1][0] - poly[k][0], poly[k + 1][1] - poly[k][1])
        t = 0.0 if seg == 0 else (s - acc) / seg
        t = max(0.0, min(1.0, t))
        out.append((poly[k][0] + t * (poly[k + 1][0] - poly[k][0]), poly[k][1] + t * (poly[k + 1][1] - poly[k][1])))
    return out


def catmull_rom(punkte, pro_segment=12, alpha=0.5):
    """Zentripetaler Catmull-Rom-Spline durch die Kontrollpunkte (offene Kurve)."""
    P = [tuple(map(float, p)) for p in punkte]
    if len(P) < 3:
        return P
    ext = [(2 * P[0][0] - P[1][0], 2 * P[0][1] - P[1][1])] + P + [(2 * P[-1][0] - P[-2][0], 2 * P[-1][1] - P[-2][1])]
    out = []
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        t0 = 0.0
        t1 = t0 + max(math.hypot(p1[0] - p0[0], p1[1] - p0[1]), 1e-6) ** alpha
        t2 = t1 + max(math.hypot(p2[0] - p1[0], p2[1] - p1[1]), 1e-6) ** alpha
        t3 = t2 + max(math.hypot(p3[0] - p2[0], p3[1] - p2[1]), 1e-6) ** alpha
        for s in range(pro_segment):
            t = t1 + (t2 - t1) * s / pro_segment
            def lerp(a, b, ta, tb):
                w = (t - ta) / (tb - ta)
                return (a[0] * (1 - w) + b[0] * w, a[1] * (1 - w) + b[1] * w)
            a1 = lerp(p0, p1, t0, t1)
            a2 = lerp(p1, p2, t1, t2)
            a3 = lerp(p2, p3, t2, t3)
            b1 = lerp(a1, a2, t0, t2)
            b2 = lerp(a2, a3, t1, t3)
            out.append(lerp(b1, b2, t1, t2))
    out.append(P[-1])
    return out


def min_radius(poly, fenster=3):
    """Kleinster Kruemmungsradius (m) entlang einer (gleichmaessig abgetasteten) Polylinie ueber Dreierpunkte
    im Abstand 'fenster' Schritte."""
    r_min = 1e9
    for i in range(fenster, len(poly) - fenster):
        a, b, c = poly[i - fenster], poly[i], poly[i + fenster]
        ab = math.hypot(b[0] - a[0], b[1] - a[1])
        bc = math.hypot(c[0] - b[0], c[1] - b[1])
        ca = math.hypot(a[0] - c[0], a[1] - c[1])
        area2 = abs((b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]))
        if area2 < 1e-9:
            continue
        r = ab * bc * ca / (2.0 * area2)
        r_min = min(r_min, r)
    return r_min


def obb_ecken(cx, cz, b, t, rot_deg):
    """Ecken eines Rechtecks (Breite b entlang lokal x, Tiefe t entlang lokal z), Godot-Konvention:
    lokales +z (Fassade) zeigt auf (sin rot, cos rot) in (x, z); lokales +x auf (cos rot, -sin rot)."""
    r = math.radians(rot_deg)
    ex = (math.cos(r), -math.sin(r))
    ez = (math.sin(r), math.cos(r))
    out = []
    for sx, sz in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        out.append((cx + ex[0] * sx * b / 2 + ez[0] * sz * t / 2, cz + ex[1] * sx * b / 2 + ez[1] * sz * t / 2))
    return out


def obb_ueberlappt(a, b, rand=0.0):
    """Trennachsentest zweier konvexer Vierecke (Eckenlisten). rand > 0 verlangt einen Mindestabstand (Naeherung)."""
    for poly in (a, b):
        for i in range(len(poly)):
            x1, z1 = poly[i]
            x2, z2 = poly[(i + 1) % len(poly)]
            nx, nz = -(z2 - z1), (x2 - x1)
            n = math.hypot(nx, nz)
            if n == 0:
                continue
            nx, nz = nx / n, nz / n
            pa = [nx * x + nz * z for x, z in a]
            pb = [nx * x + nz * z for x, z in b]
            if max(pa) + rand <= min(pb) or max(pb) + rand <= min(pa):
                return False
    return True


def punkt_in_obb(p, ecken):
    x, z = p
    s = 0
    for i in range(4):
        x1, z1 = ecken[i]
        x2, z2 = ecken[(i + 1) % 4]
        c = (x2 - x1) * (z - z1) - (z2 - z1) * (x - x1)
        if c > 0:
            s |= 1
        elif c < 0:
            s |= 2
    return s != 3


def konvexe_huelle(punkte):
    pts = sorted(set((round(x, 6), round(z, 6)) for x, z in punkte))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo = []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    up = []
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0:
            up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]


def flaeche(poly):
    s = 0.0
    for i in range(len(poly)):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % len(poly)]
        s += x1 * z2 - x2 * z1
    return abs(s) / 2.0


def clark_evans(punkte, A=None):
    """Nearest-Neighbour-Index R (Clark/Evans): 1 = Zufall, <1 geklumpt, >2 Raster. A = Flaeche (Standard: konvexe Huelle)."""
    n = len(punkte)
    if n < 4:
        return None
    if A is None:
        A = flaeche(konvexe_huelle(punkte))
    if A <= 0:
        return None
    nn = []
    for i, p in enumerate(punkte):
        d = min(math.hypot(p[0] - q[0], p[1] - q[1]) for j, q in enumerate(punkte) if j != i)
        nn.append(d)
    return (sum(nn) / n) / (0.5 / math.sqrt(n / A))


# ---------------------------------------------------------------- Wegesuche (A* auf 12,5-m-Raster, Kosten wie 05 §3)
def astar(geo, start, ziel, sperre, zusatz=None, raster=12.5, steig_gewicht=8.0, dreh_kosten=3.0, max_steig=0.12,
          grenzen=(-200.0, -200.0, 2200.0, 1800.0)):
    """Kosten je Schritt (in Rastereinheiten) = 1 + steig_gewicht*Steigung + dreh_kosten*Richtungswechsel + zusatz.
    sperre(x,z)->bool: gesperrt. zusatz(x,z)->float. Gibt Polylinie (Liste von (x,z)) zurueck oder None."""
    x0, z0, x1, z1 = grenzen
    nxg = int((x1 - x0) / raster) + 1
    nzg = int((z1 - z0) / raster) + 1

    def zu_zelle(p):
        return int(round((p[0] - x0) / raster)), int(round((p[1] - z0) / raster))

    def zu_welt(c):
        return x0 + c[0] * raster, z0 + c[1] * raster
    dirs = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]
    sc, zc = zu_zelle(start), zu_zelle(ziel)
    hz = lambda c: math.hypot(c[0] - zc[0], c[1] - zc[1])
    offen = [(hz(sc), 0.0, sc, -1)]
    g = {(sc, -1): 0.0}
    vor = {}
    cache_s = {}
    gefunden = None
    n_exp = 0
    while offen:
        f, gc, c, dprev = heapq.heappop(offen)
        if g.get((c, dprev), 1e18) < gc - 1e-9:
            continue
        if c == zc:
            gefunden = (c, dprev)
            break
        n_exp += 1
        if n_exp > 600000:
            break
        for di, (dx, dz) in enumerate(dirs):
            n = (c[0] + dx, c[1] + dz)
            if n[0] < 0 or n[1] < 0 or n[0] >= nxg or n[1] >= nzg:
                continue
            w = zu_welt(n)
            if n != zc and sperre(w[0], w[1]):
                continue
            wc = zu_welt(c)
            sl = abs(geo.hoehe(w[0], w[1]) - geo.hoehe(wc[0], wc[1])) / (raster * math.hypot(dx, dz))
            if sl > max_steig:
                continue
            kost = math.hypot(dx, dz) * (1.0 + steig_gewicht * sl)
            if dprev >= 0 and di != dprev:
                diff = min((di - dprev) % 8, (dprev - di) % 8)
                kost += dreh_kosten * 0.5 * diff
            if zusatz:
                kost += zusatz(w[0], w[1]) * math.hypot(dx, dz)
            ng = gc + kost
            key = (n, di)
            if ng < g.get(key, 1e18) - 1e-9:
                g[key] = ng
                vor[key] = (c, dprev)
                heapq.heappush(offen, (ng + hz(n), ng, n, di))
    if gefunden is None:
        return None
    pfad = []
    key = gefunden
    while key[0] != sc or key[1] != -1:
        pfad.append(zu_welt(key[0]))
        key = vor[key]
    pfad.append(zu_welt(sc))
    pfad.reverse()
    pfad[0] = tuple(start)
    pfad[-1] = tuple(ziel)
    return pfad


def vereinfachen(poly, tol):
    """Ramer-Douglas-Peucker."""
    if len(poly) < 3:
        return list(poly)
    a, b = poly[0], poly[-1]
    dmax, idx = 0.0, 0
    for i in range(1, len(poly) - 1):
        d = poly_abstand(poly[i], [a, b])[0]
        if d > dmax:
            dmax, idx = d, i
    if dmax > tol:
        l = vereinfachen(poly[:idx + 1], tol)
        r = vereinfachen(poly[idx:], tol)
        return l[:-1] + r
    return [a, b]


def r2(v):
    return round(float(v), 2)
