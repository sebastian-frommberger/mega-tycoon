#!/usr/bin/env python3
"""Phase 4, Welle 1 (TA, TEAM-02): Ausschnitt-Export ds_v2 -> Prototyp-Format (VERTRAG.md).

Aufruf (aus der Repo-Wurzel der Arbeitskopie):
    python3 -I tools_proto/ta_export.py [--quelle <ds_v2-Ordner>] [--vorgabe <ausschnitt_vorgabe.json>]
                                        [--ziel slice/world/data/proto] [--orte <proto_orte.json>] [--nur-boden]

Schreibt nach --ziel:
  proto_hoehe.r16        161x145 Knoten, uint16 LE x 0,05 m (25-m-Raster, inkl. Stempel See/Teiche/Bachrinne)
  proto_fein.r16         801x721 Knoten, uint16 LE x 0,05 m (5-m-Raster; gilt nur in Feldern mit proto_fein_maske = 1)
  proto_fein_maske.u8    160x144, 1 = Feld wird im 5-m-Raster gebaut (See, Teiche, Bachrinne)
  proto_fluss.u8         160x144 Bits: 1 Rinne, 2 Aue (wie Quelle), 4 stehendes Wasser (See/Teich), 8 Bach, 16 Gehoelzsaum
  proto_boden.png        160x144 RGBA: RGB = Palette 08_landschaft (sRGB), A = Klasse * 20 + 10
  proto_acker_maske.u8   160x144: 0 kein Acker, 1 Acker hell, 2 Acker dunkel (neu berechenbar mit --orte ... --nur-boden)
  proto_bach.json, proto_see.json, proto_meta.json (md5 aller Dateien)
Deterministisch: keine Zufallszahlen, nur Hash-Rauschen aus Feldkoordinaten. Gleiche Eingabe -> gleiche md5.
"""
import argparse
import hashlib
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEF_QUELLE = "/tmp/claude-0/gd/designsprint/ws_c/_out/ds_v2"
DEF_VORGABE = "/tmp/claude-0/gd/designsprint/p4/shared/ausschnitt_vorgabe.json"
DEF_ZIEL = os.path.join(ROOT, "slice", "world", "data", "proto")

M = 25.0                 # m je Feld
FM = 5.0                 # m je Feinknoten
SUB = int(M / FM)        # 5 Feinzellen je Feld
SKALA = 0.05             # m je uint16-Schritt
RINNE_TIEFE = 3.5        # world_gen.py: Rinnensohle = Pegel - 3,5 m

# Bodenklassen (Reihenfolge = Index, Palette = 08_landschaft (b) / boden_vorschau.py)
KLASSEN = [
    ("wiese", "#73945C"), ("auenboden", "#7D9959"), ("sumpf", "#5F7352"), ("acker_hell", "#C2A866"),
    ("acker_dunkel", "#8F7350"), ("heide", "#8C8462"), ("waldboden", "#55734A"), ("schotter", "#A39D90"),
    ("fels", "#807361"), ("schnee", "#F2F2F7"), ("ufer", "#6B7054"), ("wasser", "#345F7E"),
]
K = {n: i for i, (n, _) in enumerate(KLASSEN)}

# Teiche: Standorte (Annahmen TA, siehe ta_welle1.md)
MUEHLTEICH = {"mitte_m": [1612.5, 1150.0], "radius_m": 45.0, "tiefe_m": 2.5, "boeschung_m": 15.0, "rand_min_m": 0.5}
DORFTEICH = {"mitte_m": [1512.0, 818.0], "radius_m": 12.5, "tiefe_m": 1.2, "boeschung_m": 6.0, "rand_min_m": 0.3}   # W2: Stadt-Vorschlag (proto_orte.json gewaesser)
# W2: S7-Plateaus (Ring glaetten, Plateau bleibt): Name, Plateauhoehe (m), Ringbreite aussen (Knoten), Glaettung sigma (Knoten),
# Rundung der Plateaukante innen (Knoten). Haberau-Stadtplateau 118 m am Suedrand, Industrie-Plateau farm_2 61 m (Gut Kuppenhof)
PLATEAUS = [("haberau_118", 118.0, 7.0, 2.6, 2.5), ("farm2_61", 61.0, 4.0, 1.5, 2.0)]
MAX_DH = 4.0            # m Aenderung je Glaettungsschritt (keine Rinnen zuschuetten)
SCHUTZ = [((1612.5, 1150.0), 110.0), ((1212.5, 1012.5), 330.0)]   # Muehlteich, See: Gelaende unveraendert
DORF_PLATZHALTER = {"id": "dorf_platzhalter", "name": "Dorf (Platzhalter TA)", "klasse": "dorf", "x": 1400.0, "z": 1350.0, "r_m": 150.0}
BACH_BREITE = 5.0
BACH_RINNE_TIEFE = 1.2
BACH_RINNE_HALB = 12.0
BACH_WASSER_UEBER_SOHLE = 0.35
SAUM = (2.5, 17.5)       # Gehoelzsaum 15 m je Seite ab Wasserkante


def md5f(p):
    return hashlib.md5(open(p, "rb").read()).hexdigest()


def hash2(ix, iy, s):
    v = np.sin(ix * 127.1 + iy * 311.7 + s * 74.7) * 43758.5453
    return v - np.floor(v)


def vnoise(x, y, s):
    ix, iy = np.floor(x), np.floor(y)
    fx, fy = x - ix, y - iy
    fx, fy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
    a, b = hash2(ix, iy, s), hash2(ix + 1, iy, s)
    c, d = hash2(ix, iy + 1, s), hash2(ix + 1, iy + 1, s)
    return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fy


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def tri_interp(H, gx, gy):
    """Hoehe im Dreiecksraster (Teilung wie terrain_s7.gd: (a,b,c),(b,d,c), Diagonale b-c). gx, gy in Knoten-Einheiten."""
    ny, nx = H.shape
    x0 = np.clip(np.floor(gx).astype(np.int64), 0, nx - 2)
    y0 = np.clip(np.floor(gy).astype(np.int64), 0, ny - 2)
    u = np.clip(gx - x0, 0, 1)
    v = np.clip(gy - y0, 0, 1)
    a = H[y0, x0]
    b = H[y0, x0 + 1]
    c = H[y0 + 1, x0]
    d = H[y0 + 1, x0 + 1]
    lo = a + (b - a) * u + (c - a) * v
    hi = d + (c - d) * (1 - u) + (b - d) * (1 - v)
    return np.where(u + v <= 1.0, lo, hi)


class Welt:
    def __init__(self, quelle, vorgabe):
        self.v = json.load(open(vorgabe))
        fe = self.v["fenster"]
        self.r0 = fe["kern_zeile0"] - fe["rand_felder"]
        self.c0 = fe["kern_spalte0"] - fe["rand_felder"]
        self.gw, self.gh = fe["gesamt_felder"]          # 160, 144
        self.rand = fe["rand_felder"]
        self.ox = -self.rand * M                        # Weltkoordinate von Knoten 0 (x und z)
        self.oz = -self.rand * M
        meta = json.load(open(os.path.join(quelle, "world_s7_meta.json")))
        n = meta["knoten"]
        h = np.fromfile(os.path.join(quelle, "hoehe_s7.r16"), dtype="<u2").reshape(n, n)
        f = np.fromfile(os.path.join(quelle, "fluss_s7.u8"), dtype=np.uint8).reshape(n - 1, n - 1)
        self.H0 = h[self.r0:self.r0 + self.gh + 1, self.c0:self.c0 + self.gw + 1].astype(np.float64) * SKALA
        self.plateau_info = self.plateaus_glaetten()
        self.F0 = f[self.r0:self.r0 + self.gh, self.c0:self.c0 + self.gw].copy()
        self.quelle_md5 = {k: md5f(os.path.join(quelle, k)) for k in ("hoehe_s7.r16", "fluss_s7.u8", "world_s7_meta.json")}
        assert self.quelle_md5["hoehe_s7.r16"] == meta["md5"]["hoehe_s7.r16"], "Quelle passt nicht zur Meta"
        # Feinraster: Grundlinie = Dreiecksinterpolation des Grobrasters (exakt dieselbe Flaeche)
        self.fnx, self.fny = self.gw * SUB + 1, self.gh * SUB + 1
        J, I = np.mgrid[0:self.fny, 0:self.fnx].astype(np.float64)
        self.fx = self.ox + I * FM              # Weltkoordinaten der Feinknoten
        self.fz = self.oz + J * FM
        self.Fb = tri_interp(self.H0, I / SUB, J / SUB)
        self.Fb = np.round(self.Fb / SKALA) * SKALA
        self.F = self.Fb.copy()

    # ---------------------------------------------------------------- S7-Plateaus (W2)
    def plateaus_glaetten(self):
        """Ringboeschung der S7-Plateaus weich ausrunden (Gauss-Mischung im Ring), Plateauflaeche bleibt; Muehlteich/See geschuetzt.
        Plateau = zusammenhaengende Knoten mit Hoehe = Plateauhoehe +- 0,06 m (>= 30 Knoten)."""
        H = self.H0
        ny, nx = H.shape
        J, I = np.mgrid[0:ny, 0:nx].astype(np.float64)
        wx, wz = self.ox + I * M, self.oz + J * M
        schutz = np.ones(H.shape)
        for (cx, cz), r in SCHUTZ:
            schutz *= smoothstep(r, r + 60.0, np.hypot(wx - cx, wz - cz))
        info = {}
        alle_kerne = np.zeros(H.shape, bool)
        kerne = {}
        for name, lv, B, sig, rin in PLATEAUS:
            # Plateau = flache Knoten nahe der Plateauhoehe (S7 setzt sie auf +-0,1 m genau, Toleranz 0,3 m)
            flach = np.abs(H - nd.median_filter(H, size=3, mode="nearest")) < 0.12
            core = (np.abs(H - lv) < 0.3) & flach
            lab, n = nd.label(core)
            if n == 0:
                continue
            sizes = nd.sum(core, lab, range(1, n + 1))
            big = np.isin(lab, 1 + np.where(np.asarray(sizes) >= 30)[0])
            kerne[name] = big
            alle_kerne |= nd.binary_opening(big, structure=np.ones((5, 5), bool))   # nur breite Plateauflaechen schuetzen
        vorher = self._steil(H)
        for name, lv, B, sig, rin in PLATEAUS:
            if name not in kerne:
                continue
            big = kerne[name]
            fremd = alle_kerne & ~big
            d_out = nd.distance_transform_edt(~big)
            d_in = nd.distance_transform_edt(big)
            breit = nd.binary_opening(big, structure=np.ones((5, 5), bool))     # schmale Plateauteile (Rinnen) nicht runden
            w = np.where(big, np.where(breit, smoothstep(rin, 0.0, d_in) * 0.8, 0.0), smoothstep(B, 0.5, d_out))
            w *= schutz
            w[fremd] = 0.0                       # anderes Plateau (Gutshof auf 61 m) nicht anheben
            for _ in range(2):
                Hs = nd.gaussian_filter(H, sig, mode="nearest")
                H = H + np.clip((Hs - H) * w, -MAX_DH, MAX_DH)
            info[name] = {"plateau_knoten": int(big.sum()), "ring_knoten": int(((w > 0.05) & ~big).sum()),
                          "max_aenderung_m": round(float(np.abs(H - self.H0).max()), 2)}
        H = np.round(H / SKALA) * SKALA
        nachher = self._steil(H)
        info["kern_anteil_ueber_30pct"] = {"vorher": vorher[0], "nachher": nachher[0]}
        info["kern_max_neigung_pct"] = {"vorher": vorher[1], "nachher": nachher[1]}
        self.H0 = H
        return info

    def _steil(self, H):
        r = self.rand
        k = H[r:r + 65, r:r + 81]
        gx = np.abs(np.diff(k, axis=1))[:-1, :] / M
        gz = np.abs(np.diff(k, axis=0))[:, :-1] / M
        g = np.hypot(gx, gz)
        return round(float((g > 0.30).mean() * 100.0), 2), round(float(g.max() * 100.0), 1)

    # ---------------------------------------------------------------- Stempel
    def ufer_radius(self, cx, cz, r, staerke, s):
        th = np.arctan2(self.fz - cz, self.fx - cx)
        if staerke <= 0:
            return np.full(th.shape, r)
        k = (np.sin(3 * th + 0.7 + s) * 0.035 + np.sin(5 * th + 2.1 + s * 1.3) * 0.025 + np.sin(8 * th + 4.0 + s * 0.4) * 0.012)
        return r * (1.0 + k * staerke / 0.07)

    def stempel_gewaesser(self, cx, cz, r, pegel, tiefe, boeschung, rand_min, rauschen, s, schelf):
        """Senke + Uferboeschung in das Feinraster. Uferlinie = r_eff(theta), dort Gelaende = Pegel."""
        d = np.hypot(self.fx - cx, self.fz - cz)
        re = self.ufer_radius(cx, cz, r, rauschen, s)
        orig = self.F.copy()
        innen = d < re
        bowl = pegel - tiefe * smoothstep(0.0, schelf, re - d)
        hi = np.maximum(orig, pegel + rand_min)
        ring1 = (d >= re) & (d < re + boeschung)
        ring2 = (d >= re + boeschung) & (d < re + 2.5 * boeschung)
        t1 = smoothstep(re, re + boeschung, d)
        t2 = smoothstep(re + boeschung, re + 2.5 * boeschung, d)
        F = self.F
        F[innen] = bowl[innen]
        F[ring1] = (pegel + (hi - pegel) * t1)[ring1]
        F[ring2] = (hi + (orig - hi) * t2)[ring2]
        # ring2 nie unter Pegel absenken, wenn das Original darueber lag
        return float(np.pi * r * r)

    def pegel_aus_rand(self, cx, cz, r, b, abzug):
        d = np.hypot(self.fx - cx, self.fz - cz)
        ring = (d >= r) & (d < r + b)
        return float(np.round((self.Fb[ring].min() - abzug) / SKALA) * SKALA)

    # ---------------------------------------------------------------- Bach
    def bach_linie(self):
        P = np.array(self.v["bach_polyline_m"], dtype=np.float64)
        # Chaikin-Glaettung (3 Durchgaenge), Endpunkte fest
        for _ in range(3):
            Q = [P[0]]
            for i in range(len(P) - 1):
                a, b = P[i], P[i + 1]
                Q.append(a * 0.75 + b * 0.25)
                Q.append(a * 0.25 + b * 0.75)
            Q.append(P[-1])
            P = np.array(Q)
        # gleichmaessig auf ~5 m neu abtasten
        seg = np.hypot(*np.diff(P, axis=0).T)
        s = np.concatenate([[0], np.cumsum(seg)])
        L = s[-1]
        n = int(math.ceil(L / 5.0))
        ss = np.linspace(0, L, n + 1)
        X = np.interp(ss, s, P[:, 0])
        Z = np.interp(ss, s, P[:, 1])
        # Muendung: Linie bis in die Flussmitte verlaengern (letzter Punkt liegt am Ufer)
        return np.stack([X, Z], 1), ss

    def bach_abstand(self, pts, px, pz):
        """Abstand (m) zur Bachlinie und gebrochener Punktindex des Fusspunktes (i + t)."""
        best = np.full(px.shape, 1e9)
        bidx = np.zeros(px.shape, dtype=np.float64)
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            ab = b - a
            ll = max(float(ab @ ab), 1e-9)
            t = np.clip(((px - a[0]) * ab[0] + (pz - a[1]) * ab[1]) / ll, 0, 1)
            dx = px - (a[0] + ab[0] * t)
            dz = pz - (a[1] + ab[1] * t)
            dd = np.hypot(dx, dz)
            m = dd < best
            best = np.where(m, dd, best)
            bidx = np.where(m, i + t, bidx)
        return best, bidx

    # ---------------------------------------------------------------- Fluss
    def fluss_pegel_spalten(self):
        """Pegel je Feldspalte (der Fluss quert jede Spalte genau einmal, W-O-Achse)."""
        w = (self.F0 & 1) > 0
        peg = np.full(self.gw, np.nan)
        zmit = np.full(self.gw, np.nan)
        for c in range(self.gw):
            rows = np.where(w[:, c])[0]
            if len(rows) == 0:
                continue
            assert rows.max() - rows.min() + 1 == len(rows), "Fluss quert Spalte %d mehrfach" % c
            r0, r1 = max(rows.min() - 1, 0), min(rows.max() + 2, self.gh)
            peg[c] = self.H0[r0:r1 + 1, max(c - 1, 0):c + 3].min() + RINNE_TIEFE
            zmit[c] = self.oz + (rows.mean() + 0.5) * M
        ok = ~np.isnan(peg)
        idx = np.arange(self.gw)
        peg = np.interp(idx, idx[ok], peg[ok])
        zmit = np.interp(idx, idx[ok], zmit[ok])
        # glaetten (gleitendes Mittel 7) und monoton (fliesst nach Westen: Pegel steigt mit der Spalte)
        k = np.ones(7) / 7
        pp = np.convolve(np.pad(peg, 3, mode="edge"), k, mode="valid")
        pp = np.maximum.accumulate(pp)
        return np.round(pp, 2), zmit


def neigung_promille(H):
    """Neigung je Feld (Promille) aus den 4 Eckknoten."""
    a, b, c, d = H[:-1, :-1], H[:-1, 1:], H[1:, :-1], H[1:, 1:]
    gx = ((b - a) + (d - c)) * 0.5 / M
    gz = ((c - a) + (d - b)) * 0.5 / M
    return np.hypot(gx, gz) * 1000.0


def acker_maske(welt, orte, slope, aue, wasser, feuchte):
    gh, gw = welt.gh, welt.gw
    yy, xx = np.mgrid[0:gh, 0:gw].astype(np.float64)
    wx = welt.ox + (xx + 0.5) * M
    wz = welt.oz + (yy + 0.5) * M
    ds = np.full((gh, gw), 1e9)
    rad = np.zeros((gh, gw))
    for o in orte:
        d = np.hypot(wx - o["x"], wz - o["z"])
        r = float(o.get("r_m", 150.0))
        m = d < ds
        ds = np.where(m, d, ds)
        rad = np.where(m, r, rad)
    gx, gy = xx + welt.c0, yy + welt.r0                    # Quellkoordinaten fuer Rauschen (stabil)
    bx = np.floor((gx * 0.8 + gy * 0.6) / 8.0)
    by = np.floor((-gx * 0.6 + gy * 0.8) / 5.0)
    blk = hash2(bx, by, 5)
    dsn = ds + (vnoise(gx / 14.0, gy / 14.0, 3) - 0.5) * 500.0
    p = np.clip(1.0 - (dsn - rad) / np.maximum(np.minimum(rad * 3.0, 1600.0), 650.0), 0, 1) * 0.95
    acker = (ds > rad * 0.85) & (slope < 60) & (feuchte < 0.8) & (blk < p) & ~wasser & ~aue
    out = np.zeros((gh, gw), dtype=np.uint8)
    out[acker] = np.where(hash2(bx, by, 9)[acker] < 0.55, 1, 2)
    return out, ds, rad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--quelle", default=DEF_QUELLE)
    ap.add_argument("--vorgabe", default=DEF_VORGABE)
    ap.add_argument("--ziel", default=DEF_ZIEL)
    ap.add_argument("--orte", default="", help="proto_orte.json der Stadt-Rolle (Ackerguertel an echten Orten)")
    ap.add_argument("--nur-boden", action="store_true", help="nur Acker-Maske + Bodenkarte neu (Hoehen unveraendert)")
    a = ap.parse_args()
    os.makedirs(a.ziel, exist_ok=True)
    W = Welt(a.quelle, a.vorgabe)
    v = W.v
    kz = {}

    # ---------------- Fluss
    peg_sp, zmit = W.fluss_pegel_spalten()

    # ---------------- See (Vorgabe)
    see = dict(v["see"])
    sx, sz = see["mitte_m"]
    sr, sp = float(see["radius_m"]), float(see["pegel_m"])
    see_par = {"mitte_m": [sx, sz], "radius_m": sr, "pegel_m": sp, "tiefe_m": 4.0, "boeschung_m": 40.0, "rand_min_m": 0.8,
               "ufer_rauschen": 0.07, "rausch_phase": 0.0, "schelf_m": 70.0}
    W.stempel_gewaesser(sx, sz, sr, sp, 4.0, 40.0, 0.8, 0.07, 0.0, 70.0)

    # ---------------- Teiche (W2: Dorfteich aus proto_orte.json gewaesser, falls vorhanden)
    if a.orte and os.path.exists(a.orte):
        for g in json.load(open(a.orte)).get("gewaesser", []):
            if g.get("id") == "dorfteich" and "x" in g:
                DORFTEICH["mitte_m"] = [float(g["x"]), float(g["z"])]
                DORFTEICH["radius_m"] = float(g.get("r_m", DORFTEICH["radius_m"]))
    teiche = {}
    for name, T, s in (("muehlteich", MUEHLTEICH, 1.7), ("dorfteich", DORFTEICH, 3.1)):
        cx, cz = T["mitte_m"]
        r = T["radius_m"]
        pg = W.pegel_aus_rand(cx, cz, r, T["boeschung_m"], 0.3)
        schelf = min(70.0, r * 0.6)
        W.stempel_gewaesser(cx, cz, r, pg, T["tiefe_m"], T["boeschung_m"], T["rand_min_m"], 0.05, s, schelf)
        teiche[name] = dict(T, pegel_m=pg, ufer_rauschen=0.05, rausch_phase=s, schelf_m=schelf)

    # ---------------- Bach: Sohle entlang der Linie (monoton fallend Richtung Muendung), Rinne ins Feinraster
    pts, ss = W.bach_linie()
    # Sohle aus dem URSPRUENGLICHEN Gelaende (vor See-/Teichstempel), Teichstrecke ueberbrueckt
    gcen = tri_interp(W.Fb, (pts[:, 0] - W.ox) / FM, (pts[:, 1] - W.oz) / FM)
    mt = teiche["muehlteich"]
    d_mt = np.hypot(pts[:, 0] - mt["mitte_m"][0], pts[:, 1] - mt["mitte_m"][1])
    im_teich = d_mt < mt["radius_m"] * 0.97
    zone = d_mt < mt["radius_m"] * 1.06 + 8.0
    ii = np.arange(len(pts))
    gcen = np.where(zone, np.interp(ii, ii[~zone], gcen[~zone]), gcen)
    sohle = np.minimum.accumulate(gcen - BACH_RINNE_TIEFE)      # Quelle (Sued) -> Muendung (Nord), monoton fallend
    col_m = int(np.clip((pts[-1, 0] - W.ox) / M, 0, W.gw - 1))
    sohle = np.maximum(sohle, peg_sp[col_m] - 0.5)              # Muendung nicht unter Flusspegel - 0,5
    sohle = np.convolve(np.pad(sohle, 2, mode="edge"), np.ones(5) / 5, mode="valid")
    sohle = np.minimum.accumulate(sohle)
    # Stauwurzel: die letzten 80 m vor dem Muehlteich auf Teichhoehe (Bach speist den Teich)
    erst = int(np.argmax(im_teich)) if im_teich.any() else len(pts)
    stau = (ii < erst) & (d_mt < mt["radius_m"] + 80.0)
    sohle = np.where(stau, np.maximum(sohle, mt["pegel_m"] - BACH_WASSER_UEBER_SOHLE + 0.02), sohle)
    # am See: Sohle nicht unter Seepegel + 0,3 (Bach laeuft 30 m neben dem See, hoeher als der See)
    d_see_p = np.hypot(pts[:, 0] - sx, pts[:, 1] - sz)
    sohle = np.where(d_see_p < sr * 1.3, np.maximum(sohle, sp + 0.3), sohle)
    wasser_y = sohle + BACH_WASSER_UEBER_SOHLE
    wasser_y[im_teich] = mt["pegel_m"]                         # im Muehlteich: Band ausgelassen
    dist, bidx = W.bach_abstand(pts, W.fx, W.fz)
    near = dist < BACH_RINNE_HALB + 1.0
    d_mt_f = np.hypot(W.fx - mt["mitte_m"][0], W.fz - mt["mitte_m"][1])
    near &= d_mt_f > mt["radius_m"] + 2.0                # im Teich keine Rinne (Teich gilt)
    rinne = np.interp(bidx, np.arange(len(sohle)), sohle) + BACH_RINNE_TIEFE * smoothstep(0.0, 10.0, dist)
    # nicht unter den Seepegel graben (Bach laeuft 30 m neben dem See)
    d_see = np.hypot(W.fx - sx, W.fz - sz)
    rinne = np.where(d_see < sr * 1.3, np.maximum(rinne, sp + 0.3), rinne)
    # am Muehlteich-Ufer (bis 7 m ausserhalb der Uferlinie) nicht unter den Teichpegel: Absturz erst hinter dem Damm
    rinne = np.where(d_mt_f < mt["radius_m"] * 1.06 + 7.0, np.maximum(rinne, mt["pegel_m"] + 0.05), rinne)
    W.F[near] = np.minimum(W.F[near], rinne[near])
    W.F = np.round(W.F / SKALA) * SKALA

    # ---------------- Feinmaske, Grobhoehen
    diff = np.abs(W.F - W.Fb) > 0.01
    cell = np.zeros((W.gh, W.gw), dtype=bool)
    # Feld (cx, cy) umfasst Feinknoten [cx*5 .. cx*5+5]
    for oy in range(SUB + 1):
        for ox in range(SUB + 1):
            cell |= diff[oy:oy + W.gh * SUB:SUB, ox:ox + W.gw * SUB:SUB][:W.gh, :W.gw]
    fein = nd.binary_dilation(cell, structure=np.ones((3, 3), bool))
    H = W.F[::SUB, ::SUB].copy()
    assert H.shape == W.H0.shape
    # Kontrolle: am Rand der Feinmaske unveraendert
    rand_knoten = np.zeros(H.shape, bool)
    fe_k = np.zeros(H.shape, bool)
    fe_k[:-1, :-1] |= fein
    fe_k[1:, :-1] |= fein
    fe_k[:-1, 1:] |= fein
    fe_k[1:, 1:] |= fein
    out_k = np.zeros(H.shape, bool)
    nf = ~fein
    out_k[:-1, :-1] |= nf
    out_k[1:, :-1] |= nf
    out_k[:-1, 1:] |= nf
    out_k[1:, 1:] |= nf
    rand_knoten = fe_k & out_k
    assert np.abs(H[rand_knoten] - W.H0[rand_knoten]).max() < 1e-6, "Feinmaske-Rand veraendert"

    # ---------------- Wasser- und Zonenbits
    fl = W.F0.copy()
    yy, xx = np.mgrid[0:W.gh, 0:W.gw].astype(np.float64)
    cxw = W.ox + (xx + 0.5) * M
    czw = W.oz + (yy + 0.5) * M
    # stehendes Wasser: Feld, dessen Feinknoten mehrheitlich unter dem Pegel liegen
    steh = np.zeros((W.gh, W.gw), bool)
    gewaesser = [(sx, sz, sr * 1.1, sp)] + [(t["mitte_m"][0], t["mitte_m"][1], t["radius_m"] * 1.1, t["pegel_m"]) for t in teiche.values()]
    for gx_, gz_, rr, pg in gewaesser:
        nass = (W.F < pg) & (np.hypot(W.fx - gx_, W.fz - gz_) < rr)
        cnt = np.zeros((W.gh, W.gw))
        for oy in range(SUB):
            for ox in range(SUB):
                cnt += nass[oy:oy + W.gh * SUB:SUB, ox:ox + W.gw * SUB:SUB][:W.gh, :W.gw]
        steh |= cnt >= (SUB * SUB) * 0.5
    fl[steh] |= 4
    dcell, _ = W.bach_abstand(pts, cxw, czw)
    fl[dcell < 12.5 + BACH_BREITE * 0.5] |= 8
    fl[(dcell < 12.5 + SAUM[1]) & ~steh] |= 16

    # ---------------- Boden
    slope = neigung_promille(H)
    wasser = ((fl & 1) > 0) | steh
    aue = (fl & 2) > 0
    dw = nd.distance_transform_edt(~((W.F0 & 1) > 0)) * M
    hc = (H[:-1, :-1] + H[:-1, 1:] + H[1:, :-1] + H[1:, 1:]) * 0.25
    gx, gy = xx + W.c0, yy + W.r0
    rel = nd.uniform_filter(hc, 41, mode="nearest") - hc
    n1 = vnoise(gx / 9.0, gy / 9.0, 1) * 0.6 + vnoise(gx / 3.0, gy / 3.0, 2) * 0.4
    feuchte = np.clip(1.0 - dw / 1500.0, 0, 1) * 0.6 + np.clip(rel / 20.0, -0.3, 0.3) + (n1 - 0.5) * 0.4
    orte = [DORF_PLATZHALTER]
    orte_quelle = "Platzhalter TA (Dorf bei x 1400, z 1350, r 150 m)"
    if a.orte and os.path.exists(a.orte):
        oj = json.load(open(a.orte))
        orte = [dict(o, r_m=o.get("r_m", 150.0)) for o in oj.get("orte", [])]
        orte_quelle = os.path.relpath(a.orte, ROOT)
    # Auenboden = echte Flussaue (< 500 m, flach). Bit 2 der Quelle ist Lenas Muehlen-Band (300-1.500 m Flussabstand),
    # keine Ueberflutungsaue -> nur als Info, nicht als Bodenklasse (Abweichung von 08, Doku)
    auen = (dw < 500) & (slope < 25) & ~wasser
    acker, ds, rad = acker_maske(W, orte, slope, (dw < 300), wasser, feuchte)
    k = np.zeros((W.gh, W.gw), dtype=np.int64)
    k[auen] = K["auenboden"]
    k[auen & (slope < 12) & (feuchte > 0.62) & (n1 > 0.55)] = K["sumpf"]
    k[acker == 1] = K["acker_hell"]
    k[acker == 2] = K["acker_dunkel"]
    # Heide: Regel 08 verlangt 180-520 m (hier max. ~150 m) -> gelockert auf trockene Kuppen > 85 m (Abweichung, Doku)
    heide = (feuchte < 0.15) & (hc > 85) & (slope < 150) & (ds > 1200) & (n1 > 0.45) & (acker == 0) & ~auen
    k[heide] = K["heide"]
    # Wald-Wiesen-Mosaik (TF3-Referenz): Flecken 100-800 m aus 2 Rauschlagen + Hangbonus, Ziel ~32 % Wald ausserhalb der Aue
    p = vnoise(gx / 16.0, gy / 16.0, 11) * 0.62 + vnoise(gx / 5.0, gy / 5.0, 12) * 0.38
    p = p + np.clip((slope - 60.0) / 300.0, 0, 0.35)
    frei = (~wasser) & (acker == 0) & (ds > rad + 250) & (slope < 600)
    nah_fluss = dw < 250
    frei_land = frei & ~nah_fluss
    thr = np.quantile(p[frei_land], 1.0 - 0.38)
    wald = frei_land & (p > thr)
    # Auwald-Flecken direkt am Fluss: 12 % des 250-m-Streifens
    thr_a = np.quantile(p[frei & nah_fluss], 0.85) if (frei & nah_fluss).any() else 9
    wald |= frei & nah_fluss & (p > thr_a)
    # Feldgehoelze: 1-2 Felder, ~5 je km2 auf freier Wiese
    fg = (hash2(gx, gy, 21) < 5.0 / 1600.0 * 1.0) & frei_land & ~wald
    fg = nd.binary_dilation(fg, structure=np.array([[0, 0, 0], [0, 1, 1], [0, 1, 0]], bool)) & frei_land
    wald |= fg
    wald = nd.binary_opening(wald, structure=np.ones((1, 1), bool)) | fg
    k[wald] = K["waldboden"]
    k[slope >= 600] = K["fels"]
    k[(slope >= 350) & (slope < 600) & (hc > 550)] = K["schotter"]
    ufer = nd.binary_dilation((W.F0 & 1) > 0) & ~wasser      # nur Fluss; See/Teich-Saum macht der Shader (Hoehe ueber Pegel)
    k[ufer & (k != K["fels"])] = K["ufer"]
    k[wasser] = K["wasser"]
    pal = np.array([[int(h[i:i + 2], 16) for i in (1, 3, 5)] for _, h in KLASSEN], dtype=np.uint8)
    rgba = np.zeros((W.gh, W.gw, 4), dtype=np.uint8)
    rgba[..., :3] = pal[k]
    rgba[..., 3] = (k * 20 + 10).astype(np.uint8)

    def schreib(name, data):
        p_ = os.path.join(a.ziel, name)
        with open(p_, "wb") as fh:
            fh.write(data)
        return p_

    Image.fromarray(rgba, "RGBA").save(os.path.join(a.ziel, "proto_boden.png"), optimize=False, compress_level=6)
    schreib("proto_acker_maske.u8", acker.tobytes())
    if a.nur_boden:
        meta_p = os.path.join(a.ziel, "proto_meta.json")
        meta = json.load(open(meta_p))
        meta["md5"]["proto_boden.png"] = md5f(os.path.join(a.ziel, "proto_boden.png"))
        meta["md5"]["proto_acker_maske.u8"] = md5f(os.path.join(a.ziel, "proto_acker_maske.u8"))
        meta["boden"]["orte_quelle"] = orte_quelle
        json.dump(meta, open(meta_p, "w"), ensure_ascii=False, indent=1, sort_keys=True)
        print("nur Boden neu:", orte_quelle)
        return

    schreib("proto_hoehe.r16", np.round(H / SKALA).astype("<u2").tobytes())
    schreib("proto_fein.r16", np.round(W.F / SKALA).astype("<u2").tobytes())
    schreib("proto_fein_maske.u8", fein.astype(np.uint8).tobytes())
    schreib("proto_fluss.u8", fl.astype(np.uint8).tobytes())

    # ---------------- Kennzahlen
    kern = np.zeros((W.gh, W.gw), bool)
    kern[W.rand:W.rand + v["fenster"]["kern_felder"][1], W.rand:W.rand + v["fenster"]["kern_felder"][0]] = True
    land_k = kern & ~wasser
    bins = [0, 20, 60, 150, 300, 600, 1e9]
    lab = ["<2%", "2-6%", "6-15%", "15-30%", "30-60%", ">60%"]
    hist = np.histogram(slope[land_k], bins=bins)[0]
    kz["neigung_kern_landfelder_pct"] = {l: round(float(c) * 100.0 / land_k.sum(), 1) for l, c in zip(lab, hist)}
    kz["neigung_kern_median_promille"] = round(float(np.median(slope[land_k])), 1)
    kz["hoehe_kern_m"] = [round(float(H[W.rand:W.rand + 65, W.rand:W.rand + 81].min()), 2), round(float(H[W.rand:W.rand + 65, W.rand:W.rand + 81].max()), 2)]
    kz["hoehe_gesamt_m"] = [round(float(H.min()), 2), round(float(H.max()), 2)]
    # Flussbreite: je Feldspalte Strecke unter Pegel (Feinabtastung 1 m) x cos(Laufrichtung)
    breiten = []
    for c in range(W.gw):
        x = W.ox + (c + 0.5) * M
        z = np.arange(zmit[c] - 150, zmit[c] + 150, 1.0)
        hz = tri_interp(H, np.full(z.shape, (x - W.ox) / M), (z - W.oz) / M)
        nass = hz < peg_sp[c]
        if not nass.any():
            continue
        # zusammenhaengendes Stueck um die Mitte
        lbl, _ = nd.label(nass)
        mid = lbl[len(z) // 2] if lbl[len(z) // 2] > 0 else np.bincount(lbl[lbl > 0]).argmax()
        L = float((lbl == mid).sum())
        c0_, c1_ = max(c - 3, 0), min(c + 3, W.gw - 1)
        dzdx = (zmit[c1_] - zmit[c0_]) / ((c1_ - c0_) * M)
        breiten.append((c, L * math.cos(math.atan(dzdx))))
    bk = [b for c, b in breiten if W.rand <= c < W.rand + 80]
    ba = [b for c, b in breiten]
    kz["flussbreite_m"] = {"kern_min": round(min(bk), 1), "kern_median": round(float(np.median(bk)), 1), "kern_max": round(max(bk), 1),
                           "gesamt_min": round(min(ba), 1), "gesamt_median": round(float(np.median(ba)), 1), "gesamt_max": round(max(ba), 1),
                           "methode": "Strecke Gelaende < Pegel quer zur Spalte (1 m Abtastung im Dreiecksraster) x cos(Laufrichtung)"}
    # Wasserflaechen
    def flaeche_unter(pg, cx, cz, rr):
        mfe = (np.hypot(W.fx - cx, W.fz - cz) < rr)
        # je Feinzelle: Mittel der 4 Ecken unter Pegel -> Anteil (Naeherung 5-m-Raster)
        nass = (W.F < pg) & mfe
        return float(nass.sum()) * FM * FM
    kz["see_flaeche_m2"] = round(flaeche_unter(sp, sx, sz, sr * 1.3))
    kz["see_durchmesser_aequivalent_m"] = round(2 * math.sqrt(kz["see_flaeche_m2"] / math.pi), 1)
    for n_, t in teiche.items():
        kz[n_ + "_flaeche_m2"] = round(flaeche_unter(t["pegel_m"], t["mitte_m"][0], t["mitte_m"][1], t["radius_m"] * 1.3))
    # Fluss: Feldspalten x Breite
    kz["fluss_flaeche_m2"] = round(float(sum(b for c, b in breiten) * M))
    kz["fluss_pegel_m"] = {"west": float(peg_sp[0]), "kern_mitte": float(peg_sp[W.rand + 40]), "ost": float(peg_sp[-1]),
                           "rinnensohle_kern_mitte": round(float(peg_sp[W.rand + 40] - RINNE_TIEFE), 2)}
    kz["fein_felder"] = int(fein.sum())
    kz["bach_laenge_m"] = round(float(ss[-1]), 1)
    kz["bach_gefaelle_promille"] = round(float((wasser_y[0] - wasser_y[-1]) / ss[-1] * 1000.0), 1)
    anteile = {n: round(float((k == i).mean() * 100), 1) for i, (n, _) in enumerate(KLASSEN)}
    anteile_kern = {n: round(float((k[kern] == i).mean() * 100), 1) for i, (n, _) in enumerate(KLASSEN)}
    kz["boden_anteile_gesamt_pct"] = anteile
    kz["boden_anteile_kern_pct"] = anteile_kern

    # ---------------- JSON
    bach = {
        "_zweck": "Bach (Vorgabe-Polylinie, Chaikin-geglaettet, 5-m-Abtastung). Punkte laufen Quelle (Sued) -> Muendung (Nord, Fluss).",
        "breite_m": BACH_BREITE, "tiefe_mitte_m": 0.8, "fliess_ms": 0.6,
        "rinne": {"tiefe_m": BACH_RINNE_TIEFE, "halbbreite_m": BACH_RINNE_HALB, "wasser_ueber_sohle_m": BACH_WASSER_UEBER_SOHLE},
        "gehoelzsaum_m": {"von": SAUM[0], "bis": SAUM[1], "baeume_je_10m_je_seite": 1, "fluss_bit": 16},
        "laenge_m": kz["bach_laenge_m"],
        "punkte": [[round(float(x), 2), round(float(z), 2), round(float(y), 2), int(t)] for (x, z), y, t in zip(pts, wasser_y, im_teich)],
        "punkte_format": "[x_m, z_m, wasserspiegel_m, im_muehlteich 0/1]",
        "vorgabe_polylinie_m": v["bach_polyline_m"],
    }
    mt_x, mt_z = teiche["muehlteich"]["mitte_m"]
    seej = {
        "_zweck": "Stehende Gewaesser als Stempel im 5-m-Feinraster (proto_fein.r16). Uferlinie = radius_m x (1 + Rauschen(theta)), Gelaende dort = Pegel.",
        "see": dict(see_par, flaeche_m2=kz["see_flaeche_m2"], durchmesser_aequivalent_m=kz["see_durchmesser_aequivalent_m"], quelle="ausschnitt_vorgabe.json"),
        "muehlteich": dict(teiche["muehlteich"], flaeche_m2=kz["muehlteich_flaeche_m2"], muehle_vorschlag_m=[mt_x - 12.0, mt_z - 62.0],
                           damm="Nordufer (bachabwaerts), Boeschung >= Pegel + 0,5 m; Bach laeuft durch den Teich",
                           quelle="TA-Annahme: flachster Bachabschnitt (Gefaelle ~1 %), 600 m vom Fluss"),
        "dorfteich": dict(teiche["dorfteich"], flaeche_m2=kz["dorfteich_flaeche_m2"],
                          quelle="W2: Stadt-Vorschlag (proto_orte.json gewaesser.dorfteich, Ende der Bachgasse)"),
        "rauschen_formel": "r_eff = r * (1 + (sin(3t+0.7+s)*0.035 + sin(5t+2.1+1.3s)*0.025 + sin(8t+4.0+0.4s)*0.012) * staerke/0.07), t = atan2(z-cz, x-cx)",
    }
    json.dump(bach, open(os.path.join(a.ziel, "proto_bach.json"), "w"), ensure_ascii=False, indent=1)
    json.dump(seej, open(os.path.join(a.ziel, "proto_see.json"), "w"), ensure_ascii=False, indent=1)
    files = ["proto_hoehe.r16", "proto_fein.r16", "proto_fein_maske.u8", "proto_fluss.u8", "proto_boden.png", "proto_acker_maske.u8",
             "proto_bach.json", "proto_see.json"]
    meta = {
        "_zweck": "Prototyp-Welt Phase 4 (Design Sprint Welt), Ausschnitt aus ds_v2 Seed 7. Erzeugt von tools_proto/ta_export.py (deterministisch).",
        "fenster": v["fenster"],
        "koordinaten": "lokal in Metern, Ursprung = NW-Ecke des Kerns, +x Ost, +z Sued, y = Hoehe ueber NN (m)",
        "knoten": [W.gw + 1, W.gh + 1], "felder": [W.gw, W.gh], "m_pro_feld": M, "ursprung_knoten0_m": [W.ox, W.oz],
        "hoehe_skala_m": SKALA, "hoehe_format": "uint16 little endian, Zeilen = z (Nord -> Sued), Spalten = x",
        "dreiecksteilung": "je Quad (a=(x,z), b=(x+1,z), c=(x,z+1), d=(x+1,z+1)): (a,b,c) und (b,d,c); Diagonale b-c",
        "fein": {"datei": "proto_fein.r16", "knoten": [W.fnx, W.fny], "m_pro_knoten": FM, "maske": "proto_fein_maske.u8",
                 "regel": "hoehe_at nutzt das Feinraster in Feldern mit Maske 1, sonst das Grobraster; Grobknoten = Feinknoten [5i, 5j]"},
        "fluss_bits": {"1": "Rinne (Quelle)", "2": "Aue (Quelle)", "4": "stehendes Wasser (See/Teich)", "8": "Bach-Feld", "16": "Gehoelzsaum Bach"},
        "fluss_pegel_spalte_m": [float(x) for x in peg_sp],
        "fluss_pegel_regel": "Pegel je Feldspalte = tiefster Knoten um die Rinne + 3,5 m, gleitend 7 Spalten, monoton (Fluss fliesst nach Westen)",
        "boden": {"klassen": [{"id": i, "name": n, "hex": h} for i, (n, h) in enumerate(KLASSEN)],
                  "png": "RGB = Klassenfarbe (sRGB), A = id * 20 + 10", "acker_maske": "0 kein, 1 hell, 2 dunkel",
                  "orte_quelle": orte_quelle},
        "quelle_md5": W.quelle_md5,
        "plateaus_w2": W.plateau_info,
        "kennzahlen": kz,
        "md5": {f: md5f(os.path.join(a.ziel, f)) for f in files},
    }
    json.dump(meta, open(os.path.join(a.ziel, "proto_meta.json"), "w"), ensure_ascii=False, indent=1, sort_keys=True)
    print(json.dumps(kz, ensure_ascii=False, indent=1))
    print(json.dumps(meta["md5"], indent=1))


if __name__ == "__main__":
    main()
