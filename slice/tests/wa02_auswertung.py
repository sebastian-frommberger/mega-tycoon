#!/usr/bin/env python3
"""WA-02 (TA): Auswertung zu wa02_bodenmetrik.gd. Teil 2 des Messskripts.

    python3 wa02_auswertung.py <aufnahme_dir> [--selbsttest]

Liest <aufnahme_dir>/meta.json, img/*.png, hang_daten.f32 und schreibt dorthin:
    bodenmetrik.csv          eine Zeile je Standort: Frametime, Treppen-, Detail-, Kachelmetrik
    hang_leuchtdichte.csv    Leuchtdichte-Differenz Sonnen- gegen Schattenhang (Baseline fuer WA-03b)
    bild_hashes.csv          SHA-256 je Bild (Wiederholbarkeit)
Benoetigt: numpy, scipy, Pillow.

Definitionen (aus ux_art.md BT-1; Annahmen sind mit [Annahme] markiert und in WA-02.md begruendet):
  Treppenmetrik   Anteil der Kantenpixel, deren Kantenrichtung 0 oder 90 Grad +-5 Grad zur Weltachse liegt, im senkrechten
                  Ortho-Shot (1 px = 1 m, Modelle/Baeume/Wege aus). Isotrope Erwartung 10/90 = 11,1 %.
                  [Annahme] Kante = Gradient der Chromatizitaet (r,g)/(r+g+b) nach Gauss sigma 1,5 px > 0,010. Chromatizitaet statt
                  Helligkeit, weil Klassengrenzen die Farbe wechseln, Rauschen/Tupfen/Streifen nur die Helligkeit.
                  Wasser-Inneres (Wellen) ist ausgenommen (Maske, 6 px erodiert); die Ufer-Teilmetrik zaehlt nur Kanten
                  im Ring +-6 px um die Wassermaske.
  Kachelmetrik    hoechster Nebenpeak der 2D-Autokorrelation der Leuchtdichte (Hochpass sigma 6 px, Hann) im groessten
                  quadratischen Block gueltiger Wiesenfenster (bis 256 px), ausserhalb der Hauptkeule (zusammenhaengendes Gebiet
                  ACF > 0 um den Ursprung, +2 px), Lag bis +-N/2.
  Detail          mittlere Leuchtdichte-Streuung in gueltigen 64x64-Fenstern (Wiese, >= 16 m vom Klassenrand, kein Wasser):
                  std/mean der linearen Leuchtdichte nach Abzug einer Ebene (Fit).  Zusatz: ohne Ebenenabzug.
  Hang            D = (mean L_sonne - mean L_schatten) / mean(beide); nur Wiese (>= 16 m vom Klassenrand), Neigung 5-15 %
                  (Zentraldifferenz +-25 m), Hangrichtung cos >= 0,7 zur Sonne bzw. <= -0,7; L = Rec.709 aus linearem sRGB.
"""
import csv
import hashlib
import json
import math
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

T_KANTE = 0.010          # [Annahme] Schwelle Chromatizitaetsgradient je px
SIGMA_KANTE = 1.5
WASSER_ERODIERT_PX = 6
FENSTER = 64


def srgb_lin(a8):
    a = a8.astype(np.float64) / 255.0
    return np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)


def lade(pfad):
    return srgb_lin(np.asarray(Image.open(pfad).convert("RGB")))


def lum(lin):
    return 0.2126 * lin[..., 0] + 0.7152 * lin[..., 1] + 0.0722 * lin[..., 2]


# ------------------------------------------------------------------ Treppenmetrik

def treppen(lin, t=T_KANTE):
    """Gibt (anteil_achsparallel, n_kanten, anteil_ufer, n_ufer) zurueck."""
    s = lin.sum(axis=2) + 1e-4
    chroma = np.stack([lin[..., 0] / s, lin[..., 1] / s], axis=2)
    cs = ndi.gaussian_filter(chroma, sigma=(SIGMA_KANTE, SIGMA_KANTE, 0))
    gy0, gx0 = np.gradient(cs[..., 0])
    gy1, gx1 = np.gradient(cs[..., 1])
    jxx = gx0 * gx0 + gx1 * gx1
    jyy = gy0 * gy0 + gy1 * gy1
    jxy = gx0 * gy0 + gx1 * gy1
    lam = 0.5 * (jxx + jyy) + np.sqrt((0.5 * (jxx - jyy)) ** 2 + jxy ** 2)
    mag = np.sqrt(lam)
    theta = 0.5 * np.arctan2(2.0 * jxy, jxx - jyy)          # Richtung des staerksten Gradienten (Bildachsen = Weltachsen)
    deg = np.degrees(theta)
    abw = np.abs(((deg + 45.0) % 90.0) - 45.0)               # Abstand zur naechsten Achse (0/90)
    wasser = lin[..., 2] > lin[..., 0] * 1.25
    wasser_in = ndi.binary_erosion(wasser, iterations=WASSER_ERODIERT_PX)
    ring = ndi.binary_dilation(wasser, iterations=WASSER_ERODIERT_PX) & ~wasser_in
    kante = (mag > t) & ~wasser_in
    n = int(kante.sum())
    anteil = float((abw[kante] <= 5.0).mean()) if n else float("nan")
    uf = kante & ring
    nu = int(uf.sum())
    anteil_u = float((abw[uf] <= 5.0).mean()) if nu else float("nan")
    return anteil, n, anteil_u, nu


# ------------------------------------------------------------------ Detail / Kachel

def fenster_maske(fenster, nx, ny):
    m = np.zeros((ny, nx), bool)
    for wx, wy in fenster:
        m[wy, wx] = True
    return m


def detail(lum_img, fenster):
    """(cv_detrend_mittel, cv_roh_mittel, n)"""
    cvs, raws = [], []
    yy, xx = np.mgrid[0:FENSTER, 0:FENSTER]
    a = np.stack([xx.ravel(), yy.ravel(), np.ones(FENSTER * FENSTER)], axis=1)
    for wx, wy in fenster:
        w = lum_img[wy * FENSTER:(wy + 1) * FENSTER, wx * FENSTER:(wx + 1) * FENSTER]
        if w.shape != (FENSTER, FENSTER):
            continue
        mu = w.mean()
        if mu <= 1e-6:
            continue
        v = w.ravel()
        coef, *_ = np.linalg.lstsq(a, v, rcond=None)
        res = v - a @ coef
        cvs.append(res.std() / mu)
        raws.append(v.std() / mu)
    if not cvs:
        return float("nan"), float("nan"), 0
    return float(np.mean(cvs)), float(np.mean(raws)), len(cvs)


def groesster_block(m, kmax=4):
    """Bester quadratischer Block gueltiger Fenster (Kantenlaenge <= kmax Fenster), bevorzugt grosse, dann bildmittig."""
    ny, nx = m.shape
    for k in range(kmax, 1, -1):
        best = None
        for y in range(0, ny - k + 1):
            for x in range(0, nx - k + 1):
                if m[y:y + k, x:x + k].all():
                    d = (x + k / 2 - nx / 2) ** 2 + (y + k / 2 - ny / 2) ** 2
                    if best is None or d < best[0]:
                        best = (d, x, y)
        if best is not None:
            return k, best[1], best[2]
    return 0, 0, 0


def kachel(lum_img, fenster, nx, ny):
    """(nebenpeak, block_px). nan wenn kein Block >= 128 px."""
    k, x0, y0 = groesster_block(fenster_maske(fenster, nx, ny))
    if k < 2:
        return float("nan"), 0
    n = k * FENSTER
    w = lum_img[y0 * FENSTER:y0 * FENSTER + n, x0 * FENSTER:x0 * FENSTER + n].astype(np.float64)
    return acf_nebenpeak(w), n


def acf_nebenpeak(w):
    n = w.shape[0]
    hp = w - ndi.gaussian_filter(w, 6.0, mode="reflect")
    han = np.outer(np.hanning(n), np.hanning(n))
    x = (hp - (hp * han).sum() / han.sum()) * han
    f = np.fft.rfft2(x, s=(2 * n, 2 * n))
    ac = np.fft.irfft2(f * np.conj(f), s=(2 * n, 2 * n))
    ac = np.fft.fftshift(ac)
    if ac.max() <= 0:
        return float("nan")
    c = ac.shape[0] // 2
    ac = ac / ac[c, c]
    lobe = ndi.label(ac > 0)[0]
    haupt = lobe == lobe[c, c]
    haupt = ndi.binary_dilation(haupt, iterations=2)
    h = n // 2
    box = ac[c - h:c + h + 1, c - h:c + h + 1].copy()
    hm = haupt[c - h:c + h + 1, c - h:c + h + 1]
    box[hm] = -1.0
    return float(box.max())


# ------------------------------------------------------------------ Hang

def hang(out, meta):
    h = meta["hang"]
    nx, ny, sp = h["nx"], h["ny"], h["stich_px"]
    daten = np.fromfile(os.path.join(out, "hang_daten.f32"), dtype="<f4").reshape(ny, nx, 3)
    lin = lade(os.path.join(out, "img", "ortho_hang.png"))
    lin = lin[:ny * sp, :nx * sp]
    L = lum(lin)
    up = lambda a: np.repeat(np.repeat(a, sp, axis=0), sp, axis=1)
    innen = up(daten[..., 0]) > 0.5
    hx = up(daten[..., 1])
    hz = up(daten[..., 2])
    slope = np.hypot(hx, hz) * 100.0
    nxz = np.stack([-hx, -hz], axis=-1)                        # Richtung, in die der Hang zeigt (bergab)
    nn = np.linalg.norm(nxz, axis=-1) + 1e-12
    d = meta["sonne_laufrichtung"]
    zur_sonne = np.array([-d[0], -d[2]])
    zur_sonne = zur_sonne / np.linalg.norm(zur_sonne)
    cosa = (nxz[..., 0] * zur_sonne[0] + nxz[..., 1] * zur_sonne[1]) / nn
    rows = []

    def messe(name, lo, hi):
        band = innen & (slope >= lo) & (slope <= hi)
        sonne = band & (cosa >= 0.7)
        schat = band & (cosa <= -0.7)
        ns, nh = int(sonne.sum()), int(schat.sum())
        ls = float(L[sonne].mean()) if ns else float("nan")
        lh = float(L[schat].mean()) if nh else float("nan")
        dd = (ls - lh) / ((ls + lh) / 2.0) if ns and nh else float("nan")
        rows.append([name, f"{lo:g}-{hi:g} %", ns, nh, ls, lh, dd])
        return dd

    d_main = messe("D_hang_5_15", 5, 15)
    messe("D_hang_5_10", 5, 10)
    messe("D_hang_10_15", 10, 15)
    messe("D_hang_3_5", 3, 5)
    # Nebenmessungen
    flach = innen & (slope < 2.0)
    l_flach = float(L[flach].mean()) if flach.any() else float("nan")
    wiese = innen
    geclippt = float((lin[wiese].max(axis=1) >= 254.5 / 255.0).mean()) if wiese.any() else float("nan")
    schwarz = float((L[wiese] < 0.05 * l_flach).mean()) if wiese.any() else float("nan")
    # Regression L = a + b * cos(Einfall) auf Wiese-Pixeln mit Neigung 3-15 % (Verhaeltnis Sonne/Umgebung gemessen)
    sel = innen & (slope >= 0.0) & (slope <= 15.0)
    nrm = np.stack([-hx[sel], np.ones(sel.sum()), -hz[sel]], axis=1)
    nrm = nrm / np.linalg.norm(nrm, axis=1, keepdims=True)
    ld = np.array([d[0], d[1], d[2]])
    cosi = np.clip(nrm @ (-ld), 0.0, 1.0)
    A = np.stack([np.ones_like(cosi), cosi], axis=1)
    coef, *_ = np.linalg.lstsq(A, L[sel], rcond=None)
    # Fit-Qualitaet und D aus dem Fit fuer ein idealisiertes Hangpaar (Hang s zur Sonne gegen s von der Sonne weg)
    pred = A @ coef
    ss_res = float(((L[sel] - pred) ** 2).sum())
    ss_tot = float(((L[sel] - L[sel].mean()) ** 2).sum())
    elev = math.asin(max(-1.0, min(1.0, -d[1])))                # Sonnenhoehe ueber dem Horizont (rad)
    for sp_ in (5, 10, 15):
        al = math.atan(sp_ / 100.0)
        lt = coef[0] + coef[1] * math.sin(elev + al)
        la = coef[0] + coef[1] * max(0.0, math.sin(elev - al))
        rows.append([f"D_fit_{sp_}pct", f"{sp_} % (Fit)", int(sel.sum()), int(sel.sum()), lt, la, (lt - la) / ((lt + la) / 2.0)])
    bm = float(slope[innen & (slope >= 5) & (slope <= 15)].mean()) if (innen & (slope >= 5) & (slope <= 15)).any() else float("nan")
    if bm == bm:
        al = math.atan(bm / 100.0)
        lt = coef[0] + coef[1] * math.sin(elev + al)
        la = coef[0] + coef[1] * max(0.0, math.sin(elev - al))
        rows.append(["D_fit_bandmittel", f"{bm:.1f} % (mittlere Neigung im Band 5-15 %)", int(sel.sum()), int(sel.sum()), lt, la,
                     (lt - la) / ((lt + la) / 2.0)])
    # Hangrichtungen im Band 5-15 % (8 Sektoren, Grad von der Sonnenrichtung: 0 = Hang zeigt zur Sonne)
    band = innen & (slope >= 5) & (slope <= 15)
    rel = np.degrees(np.arctan2(nxz[..., 1], nxz[..., 0]) - math.atan2(zur_sonne[1], zur_sonne[0]))
    rel = (rel + 180.0) % 360.0 - 180.0
    sekt = np.histogram(rel[band], bins=np.arange(-180, 181, 45))[0]
    # Direkte Pruefung des Fits: mittlere Leuchtdichte je Hangneigung zur Sonne t (positiv = Hang zeigt zur Sonne, in %), Wiese, Neigung <= 20 %
    tneig = (-hx * zur_sonne[0] - hz * zur_sonne[1]) * 100.0
    mm_ = innen & (slope <= 20.0)
    kanten = [-20, -15, -12, -9, -6, -3, -1, 1, 3, 5, 8, 12, 20]
    for lo, hi in zip(kanten[:-1], kanten[1:]):
        k = mm_ & (tneig >= lo) & (tneig < hi)
        rows.append([f"Lbin_t_{lo}_{hi}", f"t {lo}..{hi} % zur Sonne", int(k.sum()), "", float(L[k].mean()) if k.any() else float("nan"),
                     float("nan"), float("nan")])
    neben = {
        "fit_r2": 1.0 - ss_res / ss_tot if ss_tot else float("nan"),
        "sonnenhoehe_grad": math.degrees(elev),
        "band_5_15_hangrichtung_sektoren_45grad_ab_-180_relativ_zur_sonne": [int(v) for v in sekt],
        "L_flach_wiese_slope_lt2": l_flach,
        "n_wiese_pixel": int(wiese.sum()),
        "n_flach_pixel": int(flach.sum()),
        "anteil_geclippt_wiese": geclippt,
        "anteil_schwarz_lt5pct_wiese": schwarz,
        "fit_a_umgebung": float(coef[0]),
        "fit_b_sonne": float(coef[1]),
        "fit_b_zu_a": float(coef[1] / coef[0]) if coef[0] else float("nan"),
        "sonne_laufrichtung": d,
        "n_fit_pixel": int(sel.sum()),
    }
    return d_main, rows, neben


# ------------------------------------------------------------------ Selbsttest

def selbsttest():
    rng = np.random.default_rng(1)
    res = {}
    # a) isotrope Kanten: viele Kreise in zwei Chromatizitaeten
    img = np.zeros((900, 1600, 3)) + np.array([0.20, 0.40, 0.15])
    yy, xx = np.mgrid[0:900, 0:1600]
    for _ in range(60):
        cx, cy, r = rng.uniform(100, 1500), rng.uniform(100, 800), rng.uniform(25, 90)
        img[(xx - cx) ** 2 + (yy - cy) ** 2 < r * r] = np.array([0.50, 0.35, 0.10])
    res["kreise_isotrop_erwartet_0.111"] = treppen(img)[0]
    # b) achsparallele Kanten (25-m-Raster)
    g = ((xx // 25 + yy // 25) % 2).astype(float)[..., None]
    img2 = g * np.array([0.5, 0.35, 0.1]) + (1 - g) * np.array([0.2, 0.4, 0.15])
    res["raster_erwartet_1.0"] = treppen(img2)[0]
    # c) Kachelmetrik: Rauschen vs. 32-px-gekachelte Textur
    ru = rng.random((256, 256))
    res["acf_weisses_rauschen"] = acf_nebenpeak(ru)
    kachel_t = np.tile(rng.random((32, 32)), (8, 8))
    res["acf_gekachelt_32px"] = acf_nebenpeak(kachel_t)
    # d) Quantisierungsboden der Detailmetrik: glatte Flaeche (Leuchtdichte 0,28 linear, leichter Verlauf), 8-bit sRGB
    yy, xx = np.mgrid[0:900, 0:1600]
    glatt = 0.28 * (1.0 + 0.02 * np.sin(xx / 300.0) * np.cos(yy / 200.0))
    s8 = np.where(glatt <= 0.0031308, glatt * 12.92, 1.055 * glatt ** (1 / 2.4) - 0.055)
    q = np.round(s8 * 255.0) / 255.0
    lin = srgb_lin(np.round(q * 255.0))
    fen = [[x, y] for x in range(20) for y in range(10)]
    res["detail_cv_quantisierungsboden"] = detail(lin, fen)[0]
    return res


# ------------------------------------------------------------------ Hauptprogramm

def main():
    out = sys.argv[1]
    if "--selbsttest" in sys.argv:
        for k, v in selbsttest().items():
            print(f"SELBSTTEST {k}: {v:.3f}")
        return
    meta = json.load(open(os.path.join(out, "meta.json")))
    W, H = meta["fenster_px"]
    nx, ny = W // FENSTER, H // FENSTER
    zeilen = []
    pooled = [0, 0.0, 0, 0.0]
    for st in meta["stellen"]:
        sid = st["id"]
        ft = st["frametime"]
        lin = lade(os.path.join(out, "img", f"ortho_{sid}.png"))
        a, n, au, nu = treppen(lin)
        pooled[0] += n
        pooled[1] += a * n if n else 0.0
        pooled[2] += nu
        pooled[3] += au * nu if nu else 0.0
        z = {"standort": sid, "art": "stelle", "abstand_m": round(st["abstand"], 1),
             "frametime_median_ms": round(ft["ms_median"], 1), "frametime_p90_ms": round(ft["ms_p90"], 1),
             "cpu_ms_je_frame": round(ft.get("cpu_ms_je_frame", -1.0), 1),
             "live_dreiecke": ft["live_dreiecke"], "live_dc": ft["live_dc"],
             "treppe_anteil": round(a, 4) if n else "", "treppe_kantenpixel": n,
             "treppe_ufer_anteil": round(au, 4) if nu else "", "treppe_ufer_kantenpixel": nu,
             "detail_cv": "", "detail_cv_roh": "", "detail_fenster": "", "kachel_nebenpeak": "", "kachel_block_px": ""}
        if sid == "p1_uebersicht":
            L = lum(lade(os.path.join(out, "img", f"persp_{sid}.png")))
            cv, raw, nf = detail(L, st["fenster"])
            z.update({"detail_cv": round(cv, 5), "detail_cv_roh": round(raw, 5), "detail_fenster": nf})
        zeilen.append(z)
    for st in meta["wiesen"]:
        sid = st["id"]
        L = lum(lade(os.path.join(out, "img", f"persp_{sid}.png")))
        cv, raw, nf = detail(L, st["fenster"])
        kp, kb = kachel(L, st["fenster"], nx, ny)
        zeilen.append({"standort": sid, "art": "wiese", "abstand_m": round(st["abstand"], 1),
                       "frametime_median_ms": "", "frametime_p90_ms": "", "cpu_ms_je_frame": "", "live_dreiecke": "", "live_dc": "",
                       "treppe_anteil": "", "treppe_kantenpixel": "", "treppe_ufer_anteil": "", "treppe_ufer_kantenpixel": "",
                       "detail_cv": round(cv, 5), "detail_cv_roh": round(raw, 5), "detail_fenster": nf,
                       "kachel_nebenpeak": round(kp, 4) if kb else "", "kachel_block_px": kb})
    zeilen.append({"standort": "ALLE_STELLEN", "art": "summe", "abstand_m": "", "frametime_median_ms": "", "frametime_p90_ms": "", "cpu_ms_je_frame": "",
                   "live_dreiecke": "", "live_dc": "",
                   "treppe_anteil": round(pooled[1] / pooled[0], 4) if pooled[0] else "", "treppe_kantenpixel": pooled[0],
                   "treppe_ufer_anteil": round(pooled[3] / pooled[2], 4) if pooled[2] else "", "treppe_ufer_kantenpixel": pooled[2],
                   "detail_cv": "", "detail_cv_roh": "", "detail_fenster": "", "kachel_nebenpeak": "", "kachel_block_px": ""})
    felder = list(zeilen[0].keys())
    with open(os.path.join(out, "bodenmetrik.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=felder)
        w.writeheader()
        w.writerows(zeilen)
    d_main, hrows, neben = hang(out, meta)
    with open(os.path.join(out, "hang_leuchtdichte.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["messung", "neigung", "n_sonne_px", "n_schatten_px", "L_sonne", "L_schatten", "D"])
        for r in hrows:
            w.writerow([r[0], r[1], r[2], r[3], f"{r[4]:.5f}", f"{r[5]:.5f}", f"{r[6]:.5f}"])
        for k, v in neben.items():
            w.writerow([k, "", "", "", "", "", v if not isinstance(v, float) else f"{v:.5f}"])
        w.writerow(["sonne_rot_grad", "", "", "", "", "", json.dumps(meta["sonne_rot_grad"])])
        w.writerow(["sonne_energie", "", "", "", "", "", meta["sonne_energie"]])
        w.writerow(["umgebung_energie", "", "", "", "", "", meta["umgebung_energie"]])
    with open(os.path.join(out, "bild_hashes.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["bild", "sha256_pixel"])
        for fn in sorted(os.listdir(os.path.join(out, "img"))):
            px = np.asarray(Image.open(os.path.join(out, "img", fn)).convert("RGB"))
            w.writerow([fn, hashlib.sha256(px.tobytes()).hexdigest()[:16]])
    for z in zeilen:
        print(" | ".join(f"{k}={v}" for k, v in z.items() if v != ""))
    for r in hrows:
        print(f"HANG {r[0]} {r[1]} n_sonne={r[2]} n_schatten={r[3]} L_s={r[4]:.4f} L_h={r[5]:.4f} D={r[6]*100:.2f} %")
    print("HANG neben", json.dumps(neben))


if __name__ == "__main__":
    main()
