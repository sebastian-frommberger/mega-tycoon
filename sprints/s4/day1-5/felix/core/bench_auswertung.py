#!/usr/bin/env python3
"""F-05 Auswertung: liest bench_results.csv, schreibt bench_summary.csv (je Konfiguration).
Kennzahlen je Konfiguration: Median der Laufmediane, Min/Max der Laufmediane, Streuung in %,
schlechtester p95, Median des Frame-Werts, gleiche Prüfsumme über alle Läufe (Gültigkeit).
Aufruf: python3 -I bench_auswertung.py bench_results.csv bench_summary.csv"""
import csv
import statistics
import sys

src, dst = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(src, newline="")))
cfgs = []
for r in rows:
    if r["config"] not in cfgs:
        cfgs.append(r["config"])
out = []
for c in cfgs:
    rs = [r for r in rows if r["config"] == c]
    med = [float(r["median_ms"]) for r in rs]
    p95 = [float(r["p95_ms"]) for r in rs]
    fr = [float(r["frame_median_ms"]) for r in rs]
    frp = [float(r["frame_p95_ms"]) for r in rs]
    sums = {r["checksum"] for r in rs}
    mm = statistics.median(med)
    out.append({
        "config": c, "vehicles": rs[0]["vehicles"], "speed": rs[0]["speed"], "runs": len(rs),
        "median_of_medians_ms": f"{mm:.3f}", "min_median_ms": f"{min(med):.3f}", "max_median_ms": f"{max(med):.3f}",
        "spread_pct": f"{100 * (max(med) - min(med)) / mm:.1f}",
        "worst_p95_ms": f"{max(p95):.3f}",
        "frame_median_ms": f"{statistics.median(fr):.3f}", "worst_frame_p95_ms": f"{max(frp):.3f}",
        "vs_4ms": "ueber" if mm > 4 else "unter",
        "p95_vs_6ms": "ueber" if max(p95) > 6 else "unter",
        "checksum_identical": "ja" if len(sums) == 1 else "nein",
        "build": rs[0]["build"], "cpu": rs[0]["cpu"], "ticks_per_run": rs[0]["ticks_measured"],
    })
with open(dst, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
    w.writeheader()
    w.writerows(out)
for o in out:
    print(o)
