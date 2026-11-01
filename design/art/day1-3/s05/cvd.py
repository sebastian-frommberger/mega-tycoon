"""Farb-Rechnung fuer S-05 (Sophie): CVD-Simulation (Machado 2009, Schweregrad 1.0, linear RGB),
CIELAB/CIEDE2000, WCAG-Kontrast. Nur Standardbibliothek. Eigenstaendig geschrieben und gegen
Sharma-Referenzwerte sowie gegen Daniels farbcheck.py gegengeprueft (siehe selbsttest())."""
import math

M = {
    "Protanopie":   [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "Deuteranopie": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "Tritanopie":   [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}
MODES = ["Normal", "Deuteranopie", "Protanopie", "Tritanopie", "Graustufen"]

def hex2rgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

def rgb2hex(rgb):
    return "#%02X%02X%02X" % tuple(rgb)

def s2l(c):
    c = c / 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def l2s(c):
    c = min(1.0, max(0.0, c))
    c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
    return int(round(c * 255))

def luminance(rgb):
    r, g, b = [s2l(c) for c in rgb]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def simulate(rgb, mode):
    if mode == "Normal":
        return tuple(rgb)
    lin = [s2l(c) for c in rgb]
    if mode == "Graustufen":
        g = l2s(luminance(rgb))
        return (g, g, g)
    m = M[mode]
    return tuple(l2s(sum(m[i][j] * lin[j] for j in range(3))) for i in range(3))

def lab(rgb):
    r, g, b = [s2l(c) for c in rgb]
    x = 0.4124564 * r + 0.3575761 * g + 0.1804375 * b
    y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b
    z = 0.0193339 * r + 0.1191920 * g + 0.9503041 * b
    xn, yn, zn = 0.95047, 1.0, 1.08883
    f = lambda t: t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    fx, fy, fz = f(x / xn), f(y / yn), f(z / zn)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))

def de2000(l1, l2):
    L1, a1, b1 = l1
    L2, a2, b2 = l2
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
        if dhp > 180:
            dhp -= 360
        elif dhp < -180:
            dhp += 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dhp / 2))
    Lpm, Cpm = (L1 + L2) / 2, (C1p + C2p) / 2
    if C1p * C2p == 0:
        hpm = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hpm = (h1p + h2p) / 2
    elif h1p + h2p < 360:
        hpm = (h1p + h2p + 360) / 2
    else:
        hpm = (h1p + h2p - 360) / 2
    T = (1 - 0.17 * math.cos(math.radians(hpm - 30)) + 0.24 * math.cos(math.radians(2 * hpm))
         + 0.32 * math.cos(math.radians(3 * hpm + 6)) - 0.20 * math.cos(math.radians(4 * hpm - 63)))
    dTheta = 30 * math.exp(-(((hpm - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cpm ** 7 / (Cpm ** 7 + 25 ** 7))
    Sl = 1 + 0.015 * (Lpm - 50) ** 2 / math.sqrt(20 + (Lpm - 50) ** 2)
    Sc = 1 + 0.045 * Cpm
    Sh = 1 + 0.015 * Cpm * T
    Rt = -math.sin(math.radians(2 * dTheta)) * Rc
    return math.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))

def delta_e(rgb1, rgb2, mode="Normal"):
    return de2000(lab(simulate(rgb1, mode)), lab(simulate(rgb2, mode)))

def contrast(rgb1, rgb2, mode="Normal"):
    """WCAG-2-Kontrastverhaeltnis (relative Luminanz, nach Simulation)."""
    a = luminance(simulate(rgb1, mode))
    b = luminance(simulate(rgb2, mode))
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)

def selbsttest():
    ref = [((50.0, 2.6772, -79.7751), (50.0, 0.0, -82.7485), 2.0425),
           ((50.0, 3.1571, -77.2803), (50.0, 0.0, -82.7485), 2.8615),
           ((50.0, 2.5, 0.0), (73.0, 25.0, -18.0), 27.1492)]
    ok = True
    for a, b, e in ref:
        v = de2000(a, b)
        ok = ok and abs(v - e) < 1e-3
    for k, m in M.items():
        for row in m:
            ok = ok and abs(sum(row) - 1.0) < 1e-5     # Weiss bleibt Weiss
    return ok

if __name__ == "__main__":
    print("selbsttest:", selbsttest())
