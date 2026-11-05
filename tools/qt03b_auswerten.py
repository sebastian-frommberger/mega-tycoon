#!/usr/bin/env python3
"""QT-03b Auswertung (Daniel): Ergebnis-Tabelle, FK-02-Messpunkte (Kaufminute, Amortisation, Schneeball), Ersetzen-Ereignis.

Eingabe: Ordner mit n20_k{K}_fk{an|aus}.csv (+ .serie.csv) vom s8_loop_bot.gd.
Aufruf:  python3 -I tools/qt03b_auswerten.py <ordner> [--n-name n20]
Ausgabe: <ordner>/tabelle_qt03b.csv (eine Zeile je k x Variante x Strategie) und <ordner>/fk_paare.csv (je Seed), Text auf stdout.
Nur Standardbibliothek. Perzentile: nearest-rank wie im Bot (ceil(p*n)-1).
"""
import csv, glob, math, os, re, sys


def wilson(k, n, z=1.96):
    if n <= 0:
        return (0.0, 0.0)
    p = k / n
    den = 1 + z * z / n
    mid = (p + z * z / (2 * n)) / den
    halb = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return (max(0.0, mid - halb) * 100, min(1.0, mid + halb) * 100)


def pct(vals, p):
    v = sorted(vals)
    if not v:
        return None
    i = min(max(math.ceil(p / 100.0 * len(v)) - 1, 0), len(v) - 1)
    return v[i]


def f(x):
    return float(x)


def laden(pfad):
    with open(pfad, newline="") as fh:
        return list(csv.DictReader(fh))


def serie_laden(pfad):
    d = {}
    with open(pfad, newline="") as fh:
        for r in csv.DictReader(fh):
            d.setdefault((r["strategie"], int(r["seed"])), {})[int(r["periode"])] = (int(r["netto_op_cent"]), int(r["netto_kasse_cent"]))
    return d


def ma3(ser, p):
    if all((q in ser) for q in (p - 2, p - 1, p)):
        return sum(ser[q][0] for q in (p - 2, p - 1, p)) / 3.0
    return None


def fmt(x, nd=1):
    return "" if x is None else (f"{x:.{nd}f}")


def main():
    ordner = sys.argv[1]
    nname = "n20"
    if "--n-name" in sys.argv:
        nname = sys.argv[sys.argv.index("--n-name") + 1]
    zeilen = []
    paare = []
    for pfad in sorted(glob.glob(os.path.join(ordner, f"{nname}_k*_fk*.csv"))):
        if pfad.endswith(".serie.csv") or pfad.endswith(".zeit.csv"):
            continue
        m = re.search(r"_k(\d+)_fk(an|aus)\.csv$", pfad)
        if not m:
            continue
        k, fk = int(m.group(1)), m.group(2)
        rows = laden(pfad)
        for strat in ("naiv", "normal", "plan"):
            rs = [r for r in rows if r["strategie"] == strat]
            n = len(rs)
            if n == 0:
                continue
            bk = sum(int(r["bankrott"]) for r in rs)
            w = wilson(bk, n)
            brmin = [f(r["bankrott_min"]) for r in rs if int(r["bankrott"]) == 1]
            z = {}
            for zid in ("e1", "e2", "e3", "e4", "e5", "e6_alle", "e6_eine", "f1", "f2_op", "f2_kasse"):
                v = [f(r["z_" + zid]) for r in rs if f(r["z_" + zid]) >= 0]
                z[zid] = (len(v), pct(v, 50))
            lue = [f(r["luecke_max_min"]) for r in rs]
            lue3 = [f(r["luecke_ohne_ev3_min"]) for r in rs]
            tief = [int(r["kasse_tief_5_20_cent"]) / 100 for r in rs if int(r["kasse_tief_5_20_cent"]) >= 0 or True]
            n5 = [int(r["netto5_op_min30_cent"]) / 100 for r in rs]
            fkk = [f(r["fk_kauf_min"]) for r in rs if f(r["fk_kauf_min"]) >= 0]
            fka = [f(r["fk_ausbau_min"]) for r in rs if f(r["fk_ausbau_min"]) >= 0]
            ers = [f(r["ersetzt_erst_min"]) for r in rs if f(r["ersetzt_erst_min"]) >= 0]
            ev8 = [f(r["ev8_erst_min"]) for r in rs if f(r["ev8_erst_min"]) >= 0]
            ev8_fenster = [x for x in ev8 if 28 <= x <= 35]
            ers_fenster = [x for x in ers if 28 <= x <= 35]
            zeilen.append({
                "k": k, "firmenkauf": fk, "strategie": strat, "n": n,
                "bankrott": bk, "bankrott_pct": round(100 * bk / n, 1), "wilson_lo": round(w[0], 1), "wilson_hi": round(w[1], 1),
                "bankrott_min_p50": fmt(pct(brmin, 50)),
                **{f"{zid}_n": z[zid][0] for zid in z}, **{f"{zid}_p50": fmt(z[zid][1]) for zid in z},
                "luecke_p50": fmt(pct(lue, 50)), "luecke_p90": fmt(pct(lue, 90)), "luecke_max": fmt(max(lue)),
                "luecke_le3_n": sum(1 for x in lue if x <= 3.0 + 1e-9),
                "luecke_ohne_ev3_p90": fmt(pct(lue3, 90)),
                "f2_op_n": z["f2_op"][0], "f2_kasse_n": z["f2_kasse"][0],
                "kasse_tief_p50_usd": fmt(pct(tief, 50), 0), "tief_unter_2000_n": sum(1 for x in tief if x < 2000),
                "tief_min_p50": fmt(pct([f(r["tief_min"]) for r in rs if f(r["tief_min"]) >= 0], 50)),
                "netto5_min30_p50_usd_min": fmt(pct(n5, 50), 0),
                "fk_gekauft_n": len(fkk), "fk_kauf_min_p50": fmt(pct(fkk, 50)), "fk_kauf_min_min": fmt(min(fkk) if fkk else None), "fk_kauf_min_max": fmt(max(fkk) if fkk else None),
                "fk_kauf_im_fenster_14_25_n": sum(1 for x in fkk if 14 <= x <= 25),
                "fk_ausbau_n": len(fka), "fk_ausbau_min_p50": fmt(pct(fka, 50)),
                "ersetzt_n_laeufe": len(ers), "ersetzt_erst_min_p50": fmt(pct(ers, 50)), "ersetzt_im_fenster_28_35_n": len(ers_fenster),
                "ev8_n": len(ev8), "ev8_erst_p50": fmt(pct(ev8, 50)), "ev8_im_fenster_28_35_n": len(ev8_fenster),
            })
        # Paare nur für Variante "an" (Vergleich gegen "aus")
        if fk == "an":
            gegen = pfad.replace("_fkan.csv", "_fkaus.csv")
            if os.path.exists(gegen) and os.path.exists(pfad + ".serie.csv") and os.path.exists(gegen + ".serie.csv"):
                s_an = serie_laden(pfad + ".serie.csv")
                s_aus = serie_laden(gegen + ".serie.csv")
                rows_aus = {(r["strategie"], int(r["seed"])): r for r in laden(gegen)}
                for r in rows:
                    if f(r["fk_kauf_min"]) < 0:
                        continue
                    key = (r["strategie"], int(r["seed"]))
                    if key not in s_aus or key not in s_an:
                        continue
                    sa, so = s_an[key], s_aus[key]
                    p0 = int(f(r["fk_kauf_min"]))            # Periode des Kaufs (Minute = Periodenindex)
                    inv = int(r["fk_preis_cent"]) + int(r["fk_ausbau_cent"])
                    # (A) kumulierte Δ Netto operativ ab Kauf >= Kauf + Ausbau
                    cum = 0
                    am_a = None
                    cum_k = 0
                    am_k = None
                    tauchte_ab = False
                    for p in range(p0, max(sa) + 1):
                        if p not in sa or p not in so:
                            break
                        cum += sa[p][0] - so[p][0]
                        cum_k += sa[p][1] - so[p][1]
                        if am_a is None and cum >= inv:
                            am_a = p - f(r["fk_kauf_min"]) + 1
                        if cum_k < 0:
                            tauchte_ab = True
                        if am_k is None and tauchte_ab and cum_k >= 0:
                            am_k = p - f(r["fk_kauf_min"]) + 1
                    # Schneeball: erste Minute nach Kauf, in der MA3(mit) >= 2 x MA3(ohne) (ohne > 0) bzw. >= 2 x Netto vor dem Kauf (vor > 0)
                    vor = ma3(sa, p0 - 1)
                    verd_ohne = None
                    verd_vor = None
                    rmax10 = None
                    for p in range(p0 + 1, max(sa) + 1):
                        if p not in sa or p not in so:
                            break
                        a, o = ma3(sa, p), ma3(so, p)
                        t = p - f(r["fk_kauf_min"])
                        if a is None or o is None:
                            continue
                        if o > 0 and verd_ohne is None and a >= 2 * o:
                            verd_ohne = t
                        if vor is not None and vor > 0 and verd_vor is None and a >= 2 * vor:
                            verd_vor = t
                        if o > 0 and t <= 10:
                            rmax10 = a / o if rmax10 is None else max(rmax10, a / o)
                    paare.append({
                        "k": k, "strategie": r["strategie"], "seed": r["seed"], "kauf_min": r["fk_kauf_min"], "ausbau_min": r["fk_ausbau_min"],
                        "invest_cent": inv, "amort_A_min": fmt(am_a), "amort_kasse_min": fmt(am_k),
                        "netto_vor_kauf_ma3_cent": fmt(vor, 0), "verdopplung_vs_ohne_min": fmt(verd_ohne), "verdopplung_vs_vor_min": fmt(verd_vor),
                        "ratio_max_10min": fmt(rmax10, 2),
                        "bankrott_an": r["bankrott"], "bankrott_aus": rows_aus[key]["bankrott"] if key in rows_aus else "",
                    })
    if not zeilen:
        print("keine Dateien gefunden in", ordner)
        return 1
    zeilen.sort(key=lambda r: (r["k"], r["firmenkauf"], ["naiv", "normal", "plan"].index(r["strategie"])))
    with open(os.path.join(ordner, "tabelle_qt03b.csv"), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(zeilen[0].keys()))
        w.writeheader()
        w.writerows(zeilen)
    if paare:
        with open(os.path.join(ordner, "fk_paare.csv"), "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(paare[0].keys()))
            w.writeheader()
            w.writerows(paare)
    for r in zeilen:
        print(f"k={r['k']:>2} fk={r['firmenkauf']:<3} {r['strategie']:<6} n={r['n']} Bankrott {r['bankrott']}/{r['n']} ({r['wilson_lo']}-{r['wilson_hi']}) Min P50 {r['bankrott_min_p50']} | "
              f"E1 {r['e1_p50']} E2 {r['e2_p50']} E3 {r['e3_p50']} E4 {r['e4_p50']} E5 {r['e5_p50']} E6a {r['e6_alle_p50']}({r['e6_alle_n']}) F1 {r['f1_p50']}({r['f1_n']}) F2 {r['f2_op_n']}/{r['f2_kasse_n']} | "
              f"Lücke P90 {r['luecke_p90']} (<=3: {r['luecke_le3_n']}) ohne3 {r['luecke_ohne_ev3_p90']} | Tief P50 {r['kasse_tief_p50_usd']}$ | N5 {r['netto5_min30_p50_usd_min']} | "
              f"FK {r['fk_gekauft_n']} @{r['fk_kauf_min_p50']} Ausbau {r['fk_ausbau_n']} | Ers {r['ersetzt_n_laeufe']} @{r['ersetzt_erst_min_p50']} ev8 {r['ev8_n']} @{r['ev8_erst_p50']}")
    # Zusammenfassung der Paare je k/Strategie
    gruppen = {}
    for p in paare:
        gruppen.setdefault((p["k"], p["strategie"]), []).append(p)
    for (k, s), ps in sorted(gruppen.items()):
        am = [float(p["amort_A_min"]) for p in ps if p["amort_A_min"] != ""]
        amk = [float(p["amort_kasse_min"]) for p in ps if p["amort_kasse_min"] != ""]
        vd = [float(p["verdopplung_vs_ohne_min"]) for p in ps if p["verdopplung_vs_ohne_min"] != ""]
        vv = [float(p["verdopplung_vs_vor_min"]) for p in ps if p["verdopplung_vs_vor_min"] != ""]
        print(f"PAARE k={k} {s}: {len(ps)} Käufe | Amortisation A erreicht {len(am)} (P50 {fmt(pct(am, 50))}, im Ziel 8-20: {sum(1 for x in am if 8 <= x <= 20)}) | "
              f"Kasse-Gleichstand {len(amk)} (P50 {fmt(pct(amk, 50))}) | Verdopplung vs ohne: {len(vd)} (P50 {fmt(pct(vd, 50))}, <10 min: {sum(1 for x in vd if x < 10)}) | "
              f"vs vor Kauf: {len(vv)} (P50 {fmt(pct(vv, 50))}, <10 min: {sum(1 for x in vv if x < 10)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
