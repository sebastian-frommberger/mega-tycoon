#!/usr/bin/env python3
"""QT-03b a-Bisektion (Daniel): sucht den Ertragsfaktor a (tempo_ausgleich_promille) für ein Tempo k per Intervallhalbierung.

Werkzeug, keine Kalibrierung: economy_proto.json bleibt unberührt, a kommt als --a=<Promille> an den Loop-Bot (Überschreibung im Bot:
Bonus a/1000 auf jeden Lieferertrag, siehe s8_loop_bot.gd). Tobias entscheidet, welchen Wert die Datei bekommt.

Zielfunktionen (--ziel=):
  f2min   (Standard) kleinstes a, bei dem die MEDIAN-Minute von F2 (f2_op, 5 Perioden >= Schwelle, Kredit 0) <= --wert (25) liegt.
          Nicht erreicht oder Bankrott zählt als unendlich. Ziel laut W2: Minute 25 +- 5 (Ergebnis wird gegen [wert-5, wert+5] geprüft).
          Schwelle F2 = ziele_welt.json (Platzhalter 600 $/min, OE-04 ersetzt ihn aus demselben Bot: Zirkularität, OE-01 OFFEN 2).
  netto   kleinstes a, bei dem das P50 des 5-Perioden-Netto bei Minute 30 (netto5_op_min30) >= --wert ($/min) liegt.
Annahme Monotonie: Mehr a -> mehr Ertrag -> früheres F2 / mehr Netto (im Prinzip; Bankrott-Rauschen kann Stufen erzeugen, die Tabelle zeigt es).
Intervall: [--lo 1000, --hi]; --hi Standard = k_eff x 1000 mit k_eff aus --keff (Zahl) oder k (Fallback). Klammer wird zuerst gemessen.
Abbruch: Intervall <= --tol (50 Promille) oder Schritte > --max.

Aufruf (aus dem Repo-Wurzelordner):
  python3 -I tools/qt03b_a_bisektion.py --k=4 --n=20 --keff=2.75 --out=/abs/ordner [--ziel=f2min --wert=25] [--godot=...] [--arbeit=slice]
"""
import csv, math, os, subprocess, sys, tempfile

GODOT = "/tmp/claude-0/gd/Godot_v4.7.2-stable_linux.x86_64"


def argv():
    d = {}
    for a in sys.argv[1:]:
        if a.startswith("--") and "=" in a:
            k, v = a[2:].split("=", 1)
            d[k] = v
    return d


def pct(v, p):
    v = sorted(v)
    if not v:
        return None
    return v[min(max(math.ceil(p / 100.0 * len(v)) - 1, 0), len(v) - 1)]


def messen(a, opt, log):
    k, n = opt["k"], opt["n"]
    csv_pfad = os.path.join(opt["out"], f"bisektion_k{k}_a{a}.csv")
    cmd = [opt["godot"], "--headless", "--path", opt["arbeit"], "-s", "res://tests/s8_loop_bot.gd", "--",
           f"--n={n}", "--strategie=plan", f"--tempo_k={k}", f"--a={a}", "--ohne_det", f"--csv={csv_pfad}"] + opt["extra"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=3600)
    if r.returncode != 0 or not os.path.exists(csv_pfad):
        print(r.stdout[-2000:], r.stderr[-1000:])
        raise SystemExit(f"Bot-Lauf fehlgeschlagen (a={a}, Exit {r.returncode})")
    rows = list(csv.DictReader(open(csv_pfad, newline="")))
    f2 = [float(x["z_f2_op"]) if float(x["z_f2_op"]) >= 0 else math.inf for x in rows]
    bk = sum(int(x["bankrott"]) for x in rows)
    n5 = [int(x["netto5_op_min30_cent"]) / 100 for x in rows]
    med_f2 = pct(f2, 50)
    res = {"a": a, "n": len(rows), "bankrott": bk, "f2_erreicht": sum(1 for x in f2 if x != math.inf), "f2_min_p50": med_f2,
           "f2_min_p25": pct(f2, 25), "f2_min_p75": pct(f2, 75), "netto5_min30_p50_usd": pct(n5, 50)}
    log.append(res)
    print(f"  a={a:>5} ‰  Bankrott {bk}/{len(rows)}  F2 erreicht {res['f2_erreicht']}/{len(rows)}  F2-Minute P50 {med_f2}  Netto5(Min 30) P50 {res['netto5_min30_p50_usd']:.0f} $/min", flush=True)
    return res


def erfuellt(res, opt):
    if opt["ziel"] == "f2min":
        return res["f2_min_p50"] is not None and res["f2_min_p50"] <= opt["wert"]
    return res["netto5_min30_p50_usd"] >= opt["wert"]


def main():
    a = argv()
    opt = {
        "k": int(a.get("k", "4")), "n": int(a.get("n", "20")), "ziel": a.get("ziel", "f2min"), "wert": float(a.get("wert", "25")),
        "lo": int(a.get("lo", "1000")), "tol": int(a.get("tol", "50")), "max": int(a.get("max", "8")),
        "godot": a.get("godot", GODOT), "arbeit": a.get("arbeit", os.path.join(os.getcwd(), "slice")),
        "out": a.get("out", tempfile.mkdtemp(prefix="bisektion_")), "extra": [x for x in sys.argv[1:] if x.startswith("--p_") or x.startswith("--startkapital")],
    }
    keff = float(a.get("keff", opt["k"]))
    opt["hi"] = int(a.get("hi", str(round(keff * 1000))))
    os.makedirs(opt["out"], exist_ok=True)
    print(f"a-Bisektion k={opt['k']} n={opt['n']} Ziel {opt['ziel']} {opt['wert']} Intervall [{opt['lo']}; {opt['hi']}] (k_eff {keff}) Toleranz {opt['tol']} ‰")
    log = []
    lo, hi = opt["lo"], opt["hi"]
    r_lo = messen(lo, opt, log)
    if erfuellt(r_lo, opt):
        print(f"Ziel schon bei a={lo} erfüllt: kein Ausgleich nötig (Intervall untere Grenze).")
        ergebnis = lo
    else:
        r_hi = messen(hi, opt, log)
        if not erfuellt(r_hi, opt):
            print(f"Ziel auch bei a={hi} (obere Grenze) NICHT erfüllt: Klammer leer. Entweder Obergrenze > k_eff x 1000 (holt den Exploit zurück, W2) oder Fix/Kap zuerst kalibrieren (OE-02 Folge 3).")
            ergebnis = None
        else:
            schritte = 0
            while hi - lo > opt["tol"] and schritte < opt["max"]:
                mid = (lo + hi) // 2
                r = messen(mid, opt, log)
                if erfuellt(r, opt):
                    hi = mid
                else:
                    lo = mid
                schritte += 1
            ergebnis = hi
            print(f"Intervall am Ende [{lo}; {hi}] ({hi - lo} ‰), kleinstes erfülltes a = {hi} ‰ (Schritte {schritte})")
    with open(os.path.join(opt["out"], f"bisektion_k{opt['k']}.csv"), "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(log[0].keys()))
        w.writeheader()
        w.writerows(log)
    if ergebnis is not None and opt["ziel"] == "f2min":
        res = [x for x in log if x["a"] == ergebnis][0]
        m = res["f2_min_p50"]
        print(f"Prüfung W2 (Minute {opt['wert']} +- 5): F2-Minute P50 bei a={ergebnis} = {m} -> {'im Band' if m is not None and opt['wert'] - 5 <= m <= opt['wert'] + 5 else 'AUSSERHALB'}")
    print("ERGEBNIS_A", ergebnis)
    return 0


if __name__ == "__main__":
    sys.exit(main())
