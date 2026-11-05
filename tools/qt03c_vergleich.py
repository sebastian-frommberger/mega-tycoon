#!/usr/bin/env python3
"""QT-03c (Daniel): Abgleich zweier Bot-CSV (alt = Emulation im Bot, neu = echter a-Haken in der Welt).
Aufruf: python3 -I tools/qt03c_vergleich.py <alt.csv> <neu.csv> [--strategie=plan]
Ausgabe: je Spalte Anzahl abweichender Zeilen (gleicher Seed/Strategie), Kennzahlen Bankrott/Lücke/Netto je Seite, erste Abweichungen.
Nur gemeinsame Spalten werden verglichen (bonus_cent entfällt neu). Keine Kalibrierung."""
import csv, sys, math

def lies(p, strat=None):
    rows = list(csv.DictReader(open(p, newline="", encoding="utf-8")))
    return [r for r in rows if strat is None or r["strategie"] == strat]

def pct(v, p):
    v = sorted(v)
    return v[min(max(math.ceil(p / 100 * len(v)) - 1, 0), len(v) - 1)] if v else None

def kenn(rows):
    n = len(rows)
    bk = sum(int(r["bankrott"]) for r in rows)
    lue = [float(r["luecke_max_min"]) for r in rows]
    n5 = [int(r["netto5_op_min30_cent"]) / 100 for r in rows]
    return f"n={n} Bankrott {bk}/{n}  Lücke P90 {pct(lue,90)}  Netto5(30) P50 {pct(n5,50)} $/min"

def main():
    arg = [a for a in sys.argv[1:] if not a.startswith("--")]
    strat = None
    for a in sys.argv[1:]:
        if a.startswith("--strategie="):
            strat = a.split("=", 1)[1]
    alt, neu = lies(arg[0], strat), lies(arg[1], strat)
    print("alt :", kenn(alt)); print("neu :", kenn(neu))
    ka = {(r["strategie"], r["seed"]): r for r in alt}
    kn = {(r["strategie"], r["seed"]): r for r in neu}
    gem = [k for k in ka if k in kn]
    spalten = [c for c in alt[0].keys() if c in neu[0].keys()]
    print(f"gemeinsame Zeilen {len(gem)} von alt {len(ka)} / neu {len(kn)}, gemeinsame Spalten {len(spalten)}")
    abw = {}
    erste = []
    for k in gem:
        for c in spalten:
            if ka[k][c] != kn[k][c]:
                abw[c] = abw.get(c, 0) + 1
                if len(erste) < 8:
                    erste.append((k, c, ka[k][c], kn[k][c]))
    zeilen_abw = len({k for k in gem if any(ka[k][c] != kn[k][c] for c in spalten)})
    print(f"Zeilen mit mindestens einer Abweichung: {zeilen_abw}/{len(gem)}")
    for c, n in sorted(abw.items(), key=lambda x: -x[1]):
        print(f"  {c}: {n}")
    for e in erste:
        print("  Bsp.", e)

main()
