#!/usr/bin/env python3
"""WA-05 (S8, TA): Ufer-Distanzfeld von Fluss und Seen/Teichen im 5-m-Raster (Integration M7, BT-3).

Das Flusswasser ist eine Ebene auf Pegelhoehe ueber dem 25-m-Dreiecksgelaende; die sichtbare Uferlinie ist die Hoehenlinie
eines stueckweise linearen Gelaendes und verlaeuft deshalb in 25-m-Treppen. Hier wird die Wassertiefe D = Pegel - Hoehe
auf einem 1-m-Raster aus denselben Daten wie im Spiel berechnet (proto_hoehe.r16, proto_fein.r16, Pegel je Spalte),
geglaettet (Gauss sigma_m), an einer kleinen Tiefe geschnitten (glatte Uferlinie knapp innerhalb der Treppen-Uferlinie)
und als vorzeichenbehafteter Abstand (m, + = Land) auf die 801 x 721 Feinknoten (5 m) abgetastet.

Ausgabe: slice/world/data/proto/proto_ufer_sdf.png, L8, 801 x 721; Wert = clamp((d + 32) * 4, 0, 255), d in m (0,25 m Stufen).
Fluss (Rinne + 2 Felder Ring wie proto_wasser.gd fluss_mesh) und stehende Gewaesser (Bereich wie steh_mesh); Bach nicht.
Keine Fremddaten: prozedural, eigene Erzeugung, keine Fremdlizenz.
Aufruf: python3 -I tools_proto/ta_ufer_sdf.py [--daten slice/world/data/proto] [--sigma 9] [--schnitt 0.4]
"""
import argparse
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

M = 25.0
FM = 5.0
SKALA = 0.05


def tri(H, gx, gy):
    ny, nx = H.shape
    x0 = np.clip(np.floor(gx).astype(np.int64), 0, nx - 2)
    y0 = np.clip(np.floor(gy).astype(np.int64), 0, ny - 2)
    u = np.clip(gx - x0, 0, 1)
    v = np.clip(gy - y0, 0, 1)
    a, b, c, d = H[y0, x0], H[y0, x0 + 1], H[y0 + 1, x0], H[y0 + 1, x0 + 1]
    lo = a + (b - a) * u + (c - a) * v
    hi = d + (c - d) * (1 - u) + (b - d) * (1 - v)
    return np.where(u + v <= 1.0, lo, hi)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--daten", default=os.path.join(os.path.dirname(__file__), "..", "slice", "world", "data", "proto"))
    ap.add_argument("--sigma", type=float, default=9.0, help="Glaettung der Tiefe (m)")
    ap.add_argument("--sigma_see", type=float, default=2.5, help="Glaettung Seen/Teiche (m); deren Ufer ist schon glatt")
    ap.add_argument("--schnitt_see", type=float, default=0.03, help="Tiefe (m) der glatten Uferlinie an Seen (flacher Schelf)")
    ap.add_argument("--schnitt", type=float, default=0.4, help="Tiefe (m) der glatten Uferlinie")
    ap.add_argument("--ziel", default=None, help="Ausgabeordner (Standard = --daten)")
    ap.add_argument("--auswertung", action="store_true")
    a = ap.parse_args()
    d = a.daten
    meta = json.load(open(os.path.join(d, "proto_meta.json")))
    gw, gh = meta["felder"]
    ox, oz = meta["ursprung_knoten0_m"]
    fnx, fny = meta["fein"]["knoten"]
    H = np.frombuffer(open(os.path.join(d, "proto_hoehe.r16"), "rb").read(), "<u2").reshape(gh + 1, gw + 1) * SKALA
    F = np.frombuffer(open(os.path.join(d, "proto_fein.r16"), "rb").read(), "<u2").reshape(fny, fnx) * SKALA
    fmask = np.frombuffer(open(os.path.join(d, "proto_fein_maske.u8"), "rb").read(), np.uint8).reshape(gh, gw)
    fluss = np.frombuffer(open(os.path.join(d, "proto_fluss.u8"), "rb").read(), np.uint8).reshape(gh, gw)
    pegel = np.array(meta["fluss_pegel_spalte_m"], float)

    def pegel_at(x):
        g = np.clip((x - ox) / M - 0.5, 0.0, gw - 1.0)
        i = np.minimum(g.astype(np.int64), gw - 2)
        return pegel[i] + (pegel[i + 1] - pegel[i]) * (g - i)

    # Wassermaske wie fluss_mesh: Rinne + 2 Ringe (8er-Nachbarschaft), Feld sichtbar wenn ein Eckknoten < 1 m ueber Pegel
    rinne = (fluss & 1) != 0
    ring = ndi.binary_dilation(rinne, structure=np.ones((3, 3)), iterations=2)
    kx = ox + np.arange(gw + 1) * M
    pk = pegel_at(kx)[None, :] - H                              # Pegel - Hoehe je Grobknoten
    ecke = pk > -1.0
    sicht = ecke[:-1, :-1] | ecke[:-1, 1:] | ecke[1:, :-1] | ecke[1:, 1:]
    feld_wasser = ring & sicht
    # Pegel der Wasserflaeche: Knotenwerte, linear in x (Mesh-Ebene)
    # 1-m-Raster ueber die ganze Karte
    xs = ox + np.arange(int(gw * M)) + 0.5
    zs = oz + np.arange(int(gh * M)) + 0.5
    X, Z = np.meshgrid(xs, zs)
    gx, gz = (X - ox) / M, (Z - oz) / M
    cx = np.clip(gx.astype(np.int64), 0, gw - 1)
    cz = np.clip(gz.astype(np.int64), 0, gh - 1)
    h = tri(H, gx, gz)
    fm = fmask[cz, cx] != 0
    if fm.any():
        h[fm] = tri(F, (X[fm] - ox) / FM, (Z[fm] - oz) / FM)
    ux = np.clip(gx - np.floor(gx), 0, 1)
    pk0 = pegel_at(ox + np.floor(gx) * M)
    pk1 = pegel_at(ox + (np.floor(gx) + 1) * M)
    pw = pk0 + (pk1 - pk0) * ux
    D = np.where(feld_wasser[cz, cx], pw - h, -5.0)
    DS = np.full_like(D, -5.0)
    # stehende Gewaesser (steh_mesh: Feinzelle nass und Zellmitte <= Uferradius + 5 m); Tiefe = Pegel - Hoehe
    seej = json.load(open(os.path.join(d, "proto_see.json")))
    for k in ("see", "muehlteich", "dorfteich"):
        g = seej.get(k)
        if not isinstance(g, dict):
            continue
        c = np.array(g["mitte_m"], float)
        th = np.arctan2(Z - c[1], X - c[0])
        st, ph = float(g.get("ufer_rauschen", 0.0)), float(g.get("rausch_phase", 0.0))
        kk = np.sin(3 * th + 0.7 + ph) * 0.035 + np.sin(5 * th + 2.1 + ph * 1.3) * 0.025 + np.sin(8 * th + 4.0 + ph * 0.4) * 0.012
        re = float(g["radius_m"]) * (1.0 + kk * st / 0.07) if st > 0 else float(g["radius_m"])
        bereich = np.hypot(X - c[0], Z - c[1]) <= re + FM
        DS = np.where(bereich, np.maximum(DS, float(g["pegel_m"]) - h), DS)
    D = np.clip(D, -5.0, 5.0)
    DS = np.clip(DS, -5.0, 5.0)
    geo = (D > 0.0) | (DS > 0.0)                                # sichtbares Wasser heute (Treppen-Uferlinie)
    # Fluss stark glaetten (25-m-Raster), Seen/Teiche schwach (5-m-Raster, sonst verschwindet der Dorfteich r = 12,5 m)
    glatt = (ndi.gaussian_filter(D, a.sigma) > a.schnitt) | (ndi.gaussian_filter(DS, a.sigma_see) > a.schnitt_see)
    for k in ("see", "muehlteich", "dorfteich"):
        g = seej.get(k)
        if isinstance(g, dict):
            c = np.array(g["mitte_m"], float)
            r = np.hypot(X - c[0], Z - c[1]) <= float(g["radius_m"]) * 1.3
            print(f"  {k}: Wasser heute {int((geo & r).sum())} m2, glatt {int((glatt & r).sum())} m2")
    # Abstandsfeld (m), + = Land
    sdf = ndi.distance_transform_edt(~glatt) - ndi.distance_transform_edt(glatt)
    # auf Feinknoten (x = ox + 5 i) abtasten: Knoten liegt zwischen 1-m-Pixeln -> Mittel der 2x2 Nachbarn
    sx = np.clip((np.arange(fnx) * FM).astype(np.int64), 1, sdf.shape[1] - 1)
    sz = np.clip((np.arange(fny) * FM).astype(np.int64), 1, sdf.shape[0] - 1)
    S = 0.25 * (sdf[np.ix_(sz, sx)] + sdf[np.ix_(sz - 1, sx)] + sdf[np.ix_(sz, sx - 1)] + sdf[np.ix_(sz - 1, sx - 1)])
    v = np.clip(np.round((S + 32.0) * 4.0), 0, 255).astype(np.uint8)
    p = os.path.join(a.ziel or d, "proto_ufer_sdf.png")
    Image.fromarray(v, "L").save(p, optimize=True)
    # Kennzahlen: wie viel der glatten Wasserflaeche liegt heute auf Land (dort bleibt die Treppe sichtbar)
    aussen = glatt & ~geo
    innen = geo & ~glatt
    print(f"proto_ufer_sdf.png {v.shape[1]}x{v.shape[0]} -> {os.path.abspath(p)}")
    print(f"Wasser heute {geo.sum()} m2, glatt {glatt.sum()} m2, glatt aber Land {aussen.sum()} m2 "
          f"({aussen.sum() / max(glatt.sum(), 1):.4f}), Wasser heute aber glatt Land {innen.sum()} m2 "
          f"({innen.sum() / max(geo.sum(), 1):.4f})")
    if a.auswertung:
        # mittlere Verschiebung der Uferlinie nach innen
        dg = ndi.distance_transform_edt(geo)
        rand = glatt & ~ndi.binary_erosion(glatt)
        print(f"glatte Uferlinie: Abstand zur Treppen-Uferlinie innen Median {np.median(dg[rand]):.2f} m, "
              f"P95 {np.percentile(dg[rand], 95):.2f} m, Anteil auf Land {(~geo[rand]).mean():.4f}")


if __name__ == "__main__":
    main()
