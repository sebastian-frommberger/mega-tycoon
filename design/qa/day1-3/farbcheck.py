#!/usr/bin/env python3
"""Farbsehschwaeche-Pruefung fuer S-05 (Daniel Richter, QA).

Verwendung (Python 3, nur Standardbibliothek; PIL/numpy nur fuer --image):
  python3 -I farbcheck.py pairs  paletten.csv [--limit 10]
  python3 -I farbcheck.py image  screenshot.png ausgabeordner

paletten.csv: eine Zeile je Farbe: name,#RRGGBB[,gruppe]
  Verglichen werden alle Paare INNERHALB einer Gruppe (z. B. status, gueter, schweregrad,
  ghost). Ohne Gruppenspalte gilt alles als eine Gruppe.

Simulation: Machado, Oliveira, Fernandes (2009), Schweregrad 1.0 (volle Dichromasie),
Matrizen im linearen RGB. Graustufen: relative Luminanz (Rec. 709). Abstand: CIEDE2000 (D65).
Grenzwert --limit 10 ist eine QA-ANNAHME (nicht aus der Literatur als Norm), mit Sophie abzustimmen.
Das Skript ersetzt keine Pruefung der FORM (Kreis/Dreieck/Achteck): die geschieht visuell in
den Graustufen-Screenshots der Checkliste.
"""
import csv, math, sys, itertools

M = {
    "Protanopie":   [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "Deuteranopie": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "Tritanopie":   [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}

def s2l(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def l2s(c):
    c = min(1.0, max(0.0, c))
    c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
    return round(c * 255)

def hex2rgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def simulate(rgb, mode):
    lin = [s2l(c) for c in rgb]
    if mode == "Normal":
        return tuple(rgb)
    if mode == "Graustufen":
        y = 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
        g = l2s(y)
        return (g, g, g)
    m = M[mode]
    out = [sum(m[i][j] * lin[j] for j in range(3)) for i in range(3)]
    return tuple(l2s(v) for v in out)

def rgb2lab(rgb):
    r, g, b = [s2l(c) for c in rgb]
    x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    xn, yn, zn = 0.95047, 1.0, 1.08883
    def f(t):
        return t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    fx, fy, fz = f(x / xn), f(y / yn), f(z / zn)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))

def de2000(l1, l2):
    L1, a1, b1 = l1; L2, a2, b2 = l2
    C1, C2 = math.hypot(a1, b1), math.hypot(a2, b2)
    Cm = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(Cm ** 7 / (Cm ** 7 + 25 ** 7)))
    a1p, a2p = (1 + G) * a1, (1 + G) * a2
    C1p, C2p = math.hypot(a1p, b1), math.hypot(a2p, b2)
    h1p = math.degrees(math.atan2(b1, a1p)) % 360 if C1p else 0.0
    h2p = math.degrees(math.atan2(b2, a2p)) % 360 if C2p else 0.0
    dLp, dCp = L2 - L1, C2p - C1p
    if C1p * C2p == 0:
        dhp = 0.0
    else:
        dhp = h2p - h1p
        if dhp > 180: dhp -= 360
        elif dhp < -180: dhp += 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp / 2))
    Lpm, Cpm = (L1 + L2) / 2, (C1p + C2p) / 2
    if C1p * C2p == 0:
        hpm = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hpm = (h1p + h2p) / 2
    else:
        hpm = (h1p + h2p + 360) / 2 if h1p + h2p < 360 else (h1p + h2p - 360) / 2
    T = (1 - 0.17 * math.cos(math.radians(hpm - 30)) + 0.24 * math.cos(math.radians(2 * hpm))
         + 0.32 * math.cos(math.radians(3 * hpm + 6)) - 0.20 * math.cos(math.radians(4 * hpm - 63)))
    dth = 30 * math.exp(-(((hpm - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cpm ** 7 / (Cpm ** 7 + 25 ** 7))
    Sl = 1 + 0.015 * (Lpm - 50) ** 2 / math.sqrt(20 + (Lpm - 50) ** 2)
    Sc, Sh = 1 + 0.045 * Cpm, 1 + 0.015 * Cpm * T
    Rt = -math.sin(math.radians(2 * dth)) * Rc
    return math.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))

MODES = ["Normal", "Protanopie", "Deuteranopie", "Tritanopie", "Graustufen"]

def cmd_pairs(path, limit):
    groups = {}
    with open(path, newline="", encoding="utf-8") as f:
        for row in csv.reader(f):
            if not row or row[0].startswith("#"):
                continue
            name, hx = row[0].strip(), row[1].strip()
            grp = row[2].strip() if len(row) > 2 else "alle"
            groups.setdefault(grp, []).append((name, hx))
    collisions = 0
    print("gruppe;farbe_a;farbe_b;modus;dE2000;ergebnis (Grenze %.1f)" % limit)
    for grp, items in groups.items():
        for (na, ha), (nb, hb) in itertools.combinations(items, 2):
            for mode in MODES:
                la = rgb2lab(simulate(hex2rgb(ha), mode)); lb = rgb2lab(simulate(hex2rgb(hb), mode))
                d = de2000(la, lb)
                ok = d >= limit
                collisions += 0 if ok else 1
                print("%s;%s;%s;%s;%.1f;%s" % (grp, na, nb, mode, d, "ok" if ok else "KOLLISION"))
    print("# Kollisionen gesamt: %d" % collisions)
    return 1 if collisions else 0

def cmd_image(src, outdir):
    import os
    import numpy as np
    from PIL import Image
    os.makedirs(outdir, exist_ok=True)
    img = np.asarray(Image.open(src).convert("RGB")).astype(np.float64) / 255.0
    lin = np.where(img <= 0.04045, img / 12.92, ((img + 0.055) / 1.055) ** 2.4)
    base = os.path.splitext(os.path.basename(src))[0]
    def save(arr_lin, name):
        a = np.clip(arr_lin, 0, 1)
        s = np.where(a <= 0.0031308, 12.92 * a, 1.055 * a ** (1 / 2.4) - 0.055)
        Image.fromarray((s * 255 + 0.5).astype(np.uint8)).save(os.path.join(outdir, "%s_%s.png" % (base, name)))
    for mode, m in M.items():
        save(lin @ np.array(m).T, mode.lower())
    y = lin @ np.array([0.2126, 0.7152, 0.0722])
    save(np.stack([y, y, y], axis=-1), "graustufen")
    print("geschrieben nach", outdir)
    return 0

if __name__ == "__main__":
    a = sys.argv[1:]
    if len(a) >= 2 and a[0] == "pairs":
        lim = float(a[a.index("--limit") + 1]) if "--limit" in a else 10.0
        sys.exit(cmd_pairs(a[1], lim))
    if len(a) == 3 and a[0] == "image":
        sys.exit(cmd_image(a[1], a[2]))
    print(__doc__); sys.exit(2)
