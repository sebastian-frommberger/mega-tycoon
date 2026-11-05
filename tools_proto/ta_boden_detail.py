#!/usr/bin/env python3
"""WA-04 (S8, TA): prozedurale Detailtextur fuer den Gelaende-Shader (proto_terrain.gdshader).

Keine Fremdquelle, kein Download: alles aus Rauschen mit festem Seed (numpy), periodisch per FFT-Filter
(kachelbar ohne Naht). Lizenz: prozedural, eigene Erzeugung, keine Fremdlizenz.

Ausgabe: slice/world/data/proto/proto_detail.png, 512 x 512, RGBA8, lineare Daten (kein sRGB), Mittel je Kanal 0,5.
  R  Gras grob   (Buschel/Horste 6-25 px)        -> Shader Massstab A (ca. 7,3 m je Kachel, 1,4 cm/px)
  G  Erde grob   (Schollen 8-40 px + Kiesel)     -> Massstab A
  B  Gras fein   (Halme 2-6 px)                  -> Massstab B (ca. 2,9 m je Kachel, gedreht)
  A  Erde fein   (Krume 2-8 px)                  -> Massstab B
Aufruf:  python3 -I tools_proto/ta_boden_detail.py [--ziel slice/world/data/proto] [--n 512] [--seed 4041]
"""
import argparse
import os

import numpy as np
from PIL import Image


def band(n, rng, lam_min, lam_max, steil=2.0):
    """Periodisches Bandpass-Rauschen: Wellenlaengen lam_min..lam_max (px), weiche Flanken."""
    w = rng.standard_normal((n, n))
    f = np.fft.fft2(w)
    k = np.sqrt(np.fft.fftfreq(n)[:, None] ** 2 + np.fft.fftfreq(n)[None, :] ** 2)
    k[0, 0] = 1e-9
    lam = 1.0 / k
    filt = 1.0 / (1.0 + (lam_min / lam) ** (2 * steil)) * 1.0 / (1.0 + (lam / lam_max) ** (2 * steil))
    filt[0, 0] = 0.0
    r = np.real(np.fft.ifft2(f * filt))
    return (r - r.mean()) / (r.std() + 1e-12)


def norm(x, std=0.17):
    x = (x - x.mean()) / (x.std() + 1e-12)
    return np.clip(0.5 + x * std, 0.0, 1.0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ziel", default=os.path.join(os.path.dirname(__file__), "..", "slice", "world", "data", "proto"))
    ap.add_argument("--n", type=int, default=512)
    ap.add_argument("--seed", type=int, default=4041)
    a = ap.parse_args()
    n = a.n
    rng = np.random.default_rng(a.seed)
    # Gras grob: Horste (weiche Kleckse) + etwas Feinanteil; leicht schief (helle Halmspitzen seltener als Schatten)
    horst = band(n, rng, 6, 25)
    gras_r = np.tanh(horst * 1.2) + 0.35 * band(n, rng, 2, 6)
    # Erde grob: Schollen (Schwellwert-Kanten weich) + seltene helle Kiesel
    scholle = band(n, rng, 8, 40)
    kiesel = band(n, rng, 2, 4)
    erde_g = np.tanh(scholle * 1.5) + 0.6 * np.clip(kiesel - 1.6, 0, None) * 2.0 + 0.25 * band(n, rng, 2, 8)
    # Gras fein: Halme, leicht gerichtet (Streckung in einer Achse, Shader dreht die Kachel)
    halm = band(n, rng, 2, 6)
    halm = 0.7 * halm + 0.3 * np.roll(halm, 1, axis=0) + 0.3 * np.roll(halm, -1, axis=0)
    gras_b = halm + 0.4 * band(n, rng, 6, 20)
    # Erde fein: Krume
    erde_a = band(n, rng, 2, 8) + 0.5 * band(n, rng, 8, 30)
    kan = [norm(gras_r), norm(erde_g), norm(gras_b), norm(erde_a)]
    img = np.stack([np.round(c * 255.0).astype(np.uint8) for c in kan], axis=-1)
    os.makedirs(a.ziel, exist_ok=True)
    p = os.path.join(a.ziel, "proto_detail.png")
    Image.fromarray(img, "RGBA").save(p, optimize=True)
    m = img.reshape(-1, 4).mean(0) / 255.0
    s = img.reshape(-1, 4).std(0) / 255.0
    print("proto_detail.png", img.shape, "Mittel", np.round(m, 3), "Std", np.round(s, 3), "->", os.path.abspath(p))


if __name__ == "__main__":
    main()
