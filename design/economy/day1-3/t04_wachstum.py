#!/usr/bin/env python3
"""T-04 Saettigung und Stadtwachstum -- Modellrechnung (deterministisch, kein Zufall).

Regeln aus city.md / tobias.md:
  W = 0,6 x Waren + 0,25 x Personen + 0,15 x Arbeitsplaetze
  Wachstum je Spielmonat (1 min): W >= 80 %: +2 % | 50-80 %: +0,5 % | 30-50 %: 0 % | < 30 %: -0,5 %
  Stufen: Dorf < 1.000 | Kleinstadt < 5.000 | Stadt < 20.000
  Stufen-Tor: bei 95 % der naechsten Schwelle bleibt die Stadt stehen, bis die neue Kategorie >= 25 % versorgt ist.
  Warenkorb: Dorf Nahrung | Kleinstadt + Bau | Stadt + Werkzeug; Bedarf je Kategorie = Einwohner / 100 E/min
  F_saett: bis 100 % 1,0 | 100->150 % linear auf 0,4 | darueber 0,1
ANNAHMEN (nicht aus den Konzepten): Start-Einwohner 800 (Dorf, Spec: "800 -> 1.000"); Warenversorgung G = Mittel der
Kategorie-Versorgungsgrade (min(Angebot/Bedarf,1)); Personen P und Arbeitsplaetze J als Konstanten je Spielertyp;
Wachstum wirkt multiplikativ je Monat und Einwohner werden nicht gerundet; Zeit = erste volle Minute mit Einwohner >= Schwelle.
Lauf: python3 t04_wachstum.py
"""
import csv, math, os

OUT = os.path.dirname(os.path.abspath(__file__))
THR = [("Dorf", 1000), ("Kleinstadt", 5000), ("Stadt", 20000)]
START = 800.0
TARGET = {"Dorf>Kleinstadt": 12.0, "Kleinstadt>Stadt": 80.0}


def rate_main(W):
    if W >= 0.8: return 0.02
    if W >= 0.5: return 0.005
    if W >= 0.3: return 0.0
    return -0.005


def W_main(G, P, J):
    return 0.6 * G + 0.25 * P + 0.15 * J


def make_variant_b(r0, bonus):
    """Variante B 'Personen nur als Bonus': Band wird nur von G bestimmt; P/J geben einen Zuschlag auf die Rate
    (X = 0,625 P + 0,375 J = Gewichtsverhaeltnis 0,25 : 0,15)."""
    def rate(G, P, J):
        X = 0.625 * P + 0.375 * J
        if G >= 0.8: base = r0
        elif G >= 0.5: base = 0.25 * r0
        elif G >= 0.3: base = 0.0
        else: base = -0.25 * r0
        return base * (1 + bonus * X) if base > 0 else base
    return rate


def f_saett(s):
    if s <= 1.0: return 1.0
    if s <= 1.5: return 1.0 - 0.6 * (s - 1.0) / 0.5
    return 0.1


def simulate(P_fn, rate_fn, scen, horizon=500, gate_wait=0, ramp=0, lag=0, start=START, stop_at=None, record=True):
    """scen: dict G (konstant 1.0 wenn 'G_track'), P, J. gate_wait: Minuten, die nach Erreichen von 95 % der Schwelle
    vergehen, bis die neue Kategorie >= 25 % versorgt ist (0 = Spieler hat vorgebaut). ramp: Minuten, in denen die neue
    Kategorie nach dem Tor von 25 % auf 100 % waechst (0 = sofort 100 %). lag: Versorgung folgt dem Bedarf um lag Minuten verzoegert."""
    pop = start
    stage = 0                        # Index in THR: Dorf = 0 (Ziel Kleinstadt), ...
    while stage < len(THR) - 1 and pop >= THR[stage][1]:
        stage += 1
    rows = []
    reach = {}
    gate_since = None
    stage_start = 0
    new_cat_since = None             # Minute, ab der die neue Kategorie >= 25 % versorgt ist
    hist = [pop]
    for t in range(0, horizon + 1):
        name, thr = THR[stage]
        ncat = stage + 1
        # Kategorie-Versorgung: bestehende Kategorien folgen dem Bedarf mit Verzoegerung lag
        base_ratio = 1.0
        if lag > 0 and t >= lag:
            base_ratio = min(1.0, hist[t - lag] / hist[t]) if hist[t] > 0 else 1.0
        elif lag > 0:
            base_ratio = min(1.0, hist[0] / hist[t])
        # neue Kategorie (nur wenn stage >= 1: Bau bzw. Werkzeug sind seit Stufenwechsel aktiv)
        cats = [base_ratio] * ncat
        gate = False
        # Tor: bei >= 95 % der naechsten Schwelle pruefen, ob die naechste Kategorie schon >= 25 % versorgt ist
        next_cat_ok = True
        if pop >= 0.95 * thr:
            if gate_since is None:
                gate_since = t
            next_cat_ok = (t - gate_since) >= gate_wait
            gate = not next_cat_ok
        # neue Kategorie des aktuellen Stufen-Levels: ab Stufenwechsel Anlaufkurve 25 % -> 100 % ueber ramp
        if stage >= 1 and new_cat_since is not None:
            age = t - new_cat_since
            cats[-1] = 1.0 if ramp <= 0 else min(1.0, 0.25 + 0.75 * age / ramp)
        G = sum(cats) / len(cats)
        r = rate_fn(G, scen["P"], scen["J"])
        rec = dict(min=t, stufe=name, einwohner=round(pop, 1), G=round(G, 3), P=scen["P"], J=scen["J"],
                   W=round(W_main(G, scen["P"], scen["J"]), 3), rate=r, tor=int(gate),
                   bedarf_je_kategorie=round(pop / 100.0, 1))
        if record:
            rows.append(rec)
        if not gate:
            pop *= (1 + r)
        hist.append(pop)
        if pop >= thr and stage < len(THR) - 1 and (name + ">" + THR[stage + 1][0]) not in reach:
            reach[name + ">" + THR[stage + 1][0]] = (t + 1) - stage_start   # Dauer der Stufe in vollen Minuten
            stage_start = t + 1
            stage += 1
            gate_since = None
            new_cat_since = t + 1
        if stop_at and stage >= stop_at:
            break
    return rows, reach


def time_to(P_fn, rate_fn, scen, **kw):
    """Gibt (min Dorf>Klein, min Klein>Stadt) zurueck; None wenn > Horizont."""
    rows, reach = simulate(P_fn, rate_fn, scen, horizon=kw.pop("horizon", 700), record=False, **kw)
    return reach.get("Dorf>Kleinstadt"), reach.get("Kleinstadt>Stadt")


def dev(x, tgt):
    return None if x is None else round(100.0 * (x - tgt) / tgt, 1)


SCEN = {
    "S0 Hoechstversorgung (G=1, P=1, J=1)": dict(G=1.0, P=1.0, J=1.0),
    "S1 gut abgedeckt (G=1, P=0,7, J=0,6)": dict(G=1.0, P=0.7, J=0.6),
    "S2 nur Gueter (G=1, P=0, J=0)": dict(G=1.0, P=0.0, J=0.0),
    "S3 Gueter + Bus Zentrum (G=1, P=0,4, J=0,2)": dict(G=1.0, P=0.4, J=0.2),
    "S4 Personenspieler (G=0,5, P=1, J=1)": dict(G=0.5, P=1.0, J=1.0),
}


# Szenarien mit festem G: simulate() bildet G aus den Kategorien (Standard 1.0). Fuer G < 1 (S4) ueberschreiben wir
# per Wrapper: G_fix multipliziert die Versorgung.
def run_fixed_G(rate_fn, sc, **kw):
    G_fix = sc["G"]
    def wrapped(G, P, J):
        return rate_fn(G * G_fix, P, J)
    return time_to(None, wrapped, sc, **kw)


def main():
    rows = []
    rate_W = lambda G, P, J: rate_main(W_main(G, P, J))
    # ---------------- A) Hauptvariante: Zielzeiten je Spielertyp
    for name, sc in SCEN.items():
        a, b = run_fixed_G(rate_W, sc)
        rows.append(dict(Variante="A: W = 0,6/0,25/0,15", Szenario=name, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12),
                         Klein_Stadt_min=b, Abw_80_pct=dev(b, 80),
                         Ziele_im_Rahmen_15pct=("ja" if (a and b and abs(dev(a, 12)) <= 15 and abs(dev(b, 80)) <= 15) else "nein")))
    write_csv("t04_ergebnis_variante_A.csv", rows)
    # A-stetig: Rate linear zwischen W=0,5 (+0,5 %) und W=0,8 (+2 %) statt Stufen -- nur zur Einordnung des Klippeneffekts
    def rate_stetig(G, P, J):
        W = W_main(G, P, J)
        if W >= 0.8: return 0.02
        if W >= 0.5: return 0.005 + 0.015 * (W - 0.5) / 0.3
        if W >= 0.3: return 0.0
        return -0.005
    for name, sc in SCEN.items():
        a, b = run_fixed_G(rate_stetig, sc)
        rows.append(dict(Variante="A-stetig: W wie A, Rate linear 0,5-0,8", Szenario=name, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12),
                         Klein_Stadt_min=b, Abw_80_pct=dev(b, 80),
                         Ziele_im_Rahmen_15pct=("ja" if (a and b and abs(dev(a, 12)) <= 15 and abs(dev(b, 80)) <= 15) else "nein")))

    # ---------------- B) Variante 'Personen nur als Bonus': Kalibrierung (r0, bonus) per Raster
    best = None
    grid = []
    for r0 in [x / 1000 for x in range(14, 26)]:
        for bonus in [x / 100 for x in range(0, 61, 5)]:
            rfn = make_variant_b(r0, bonus)
            ok = True; maxdev = 0.0
            for name in ("S0 Hoechstversorgung (G=1, P=1, J=1)", "S1 gut abgedeckt (G=1, P=0,7, J=0,6)", "S2 nur Gueter (G=1, P=0, J=0)"):
                a, b = run_fixed_G(rfn, SCEN[name])
                if a is None or b is None:
                    ok = False; break
                maxdev = max(maxdev, abs(dev(a, 12)), abs(dev(b, 80)))
            if ok:
                grid.append(dict(r0=r0, bonus=bonus, max_abw_pct=round(maxdev, 1), alle_drei_Spielertypen_im_Rahmen=int(maxdev <= 15)))
                # Auswahl: groesster Bonus (staerkster Personen-Anreiz), bei dem Gueterspieler, 'gut abgedeckt' und Vollversorgung
                # ALLE innerhalb 15 % der Zielzeiten liegen; Gleichstand -> kleinste maximale Abweichung
                if maxdev <= 15:
                    key = (bonus, -maxdev)
                    if best is None or key > best[3]:
                        best = (maxdev, r0, bonus, key)
    write_csv("t04_kalibrierung_variante_B.csv", sorted(grid, key=lambda g: (g["max_abw_pct"], -g["bonus"])))
    maxdev, r0, bonus, _ = best
    rfn = make_variant_b(r0, bonus)
    for name, sc in SCEN.items():
        a, b = run_fixed_G(rfn, sc)
        rows_b = dict(Variante=f"B: Personen als Bonus (r0={r0:.3f}, Bonus +{int(bonus*100)} %)", Szenario=name, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12),
                      Klein_Stadt_min=b, Abw_80_pct=dev(b, 80),
                      Ziele_im_Rahmen_15pct=("ja" if (a and b and abs(dev(a, 12)) <= 15 and abs(dev(b, 80)) <= 15) else "nein"))
        rows.append(rows_b)
    # B mit Standardwerten 2 % und +25 % (ungeeicht), zur Einordnung
    rfn_u = make_variant_b(0.02, 0.25)
    for name, sc in SCEN.items():
        a, b = run_fixed_G(rfn_u, sc)
        rows.append(dict(Variante="B0: Personen als Bonus, ungeeicht (r0=0,020, Bonus +25 %)", Szenario=name, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12),
                         Klein_Stadt_min=b, Abw_80_pct=dev(b, 80),
                         Ziele_im_Rahmen_15pct=("ja" if (a and b and abs(dev(a, 12)) <= 15 and abs(dev(b, 80)) <= 15) else "nein")))
    write_csv("t04_ergebnis_alle_varianten.csv", rows)

    # ---------------- C) Zeitreihen (Minutenwerte) fuer Diagramme
    for tag, sc_name, rfn_use, kw in (
        ("A_S0_hoechstversorgung", "S0 Hoechstversorgung (G=1, P=1, J=1)", rate_W, {}),
        ("A_S1_gut_abgedeckt", "S1 gut abgedeckt (G=1, P=0,7, J=0,6)", rate_W, {}),
        ("A_S2_nur_gueter", "S2 nur Gueter (G=1, P=0, J=0)", rate_W, {}),
        ("B_S2_nur_gueter", "S2 nur Gueter (G=1, P=0, J=0)", rfn, {}),
        ("B_S1_gut_abgedeckt", "S1 gut abgedeckt (G=1, P=0,7, J=0,6)", rfn, {}),
    ):
        sc = SCEN[sc_name]
        horizon = 340 if tag.startswith("A_S2") else 140
        rws, reach = simulate(None, rfn_use, sc, horizon=horizon, **kw)
        write_csv(f"t04_zeitreihe_{tag}.csv", rws)

    # ---------------- D) Stufen-Tor-Empfindlichkeit und Versorgungs-Anlauf (Variante A, S0 bzw. S1)
    tor = []
    for tag, sn in (("S0", "S0 Hoechstversorgung (G=1, P=1, J=1)"), ("S1", "S1 gut abgedeckt (G=1, P=0,7, J=0,6)")):
        for gw in (0, 1, 2, 3, 5, 8):
            a, b = run_fixed_G(rate_W, SCEN[sn], gate_wait=gw)
            tor.append(dict(Szenario=tag, Variante="Tor-Wartezeit je Tor (min)", Wert=gw, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12), Klein_Stadt_min=b, Abw_80_pct=dev(b, 80)))
        for rp in (0, 3, 6, 10, 15):
            a, b = run_fixed_G(rate_W, SCEN[sn], ramp=rp)
            tor.append(dict(Szenario=tag, Variante="Anlauf neue Kategorie 25->100 % in (min)", Wert=rp, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12), Klein_Stadt_min=b, Abw_80_pct=dev(b, 80)))
        for lg in (0, 2, 4, 8):
            a, b = run_fixed_G(rate_W, SCEN[sn], lag=lg)
            tor.append(dict(Szenario=tag, Variante="Versorgung hinkt Bedarf um (min)", Wert=lg, Dorf_Klein_min=a, Abw_12_pct=dev(a, 12), Klein_Stadt_min=b, Abw_80_pct=dev(b, 80)))
    write_csv("t04_tor_und_anlauf.csv", tor)

    # ---------------- E) Wachstumslandkarte: P x J bei G = 1 und G = 0,9 (Variante A und B)
    land = []
    for G in (1.0, 0.9):
        for P in [x / 10 for x in range(0, 11, 2)]:
            for J in [x / 10 for x in range(0, 11, 2)]:
                W = W_main(G, P, J)
                a, b = run_fixed_G(rate_W, dict(G=G, P=P, J=J))
                a2, b2 = run_fixed_G(rfn, dict(G=G, P=P, J=J))
                land.append(dict(G=G, P=P, J=J, W=round(W, 3), rate_A_pct=rate_main(W) * 100, Dorf_Klein_A=a, Klein_Stadt_A=b,
                                 rate_B_pct=round(rfn(G, P, J) * 100, 3), Dorf_Klein_B=a2, Klein_Stadt_B=b2))
    write_csv("t04_wachstumslandkarte.csv", land)

    # ---------------- G) Startpunkte der Archetypen (hq.md): Zeit bis zur naechsten Stufe bei W >= 80 % (Variante A S0) bzw. Variante B
    st = []
    for arch, pop0 in (("Agrar (Dorf)", 900), ("Bergbau (Kleinstadt)", 2500), ("Hafen (Kleinstadt)", 3200), ("Handel (Stadt)", 12000)):
        sc = SCEN["S0 Hoechstversorgung (G=1, P=1, J=1)"]
        rowsx, reach = simulate(None, lambda G, P, J: rate_main(W_main(G, P, J)), sc, horizon=400, start=float(pop0))
        rowsb, reachb = simulate(None, lambda G, P, J: rfn(G, P, J), SCEN["S2 nur Gueter (G=1, P=0, J=0)"], horizon=400, start=float(pop0))
        nxt = [k for k in reach.keys()][:1]
        st.append(dict(Archetyp=arch, Start_Einwohner=pop0, Naechste_Stufe_A_Hoechstversorgung=(nxt[0] + ": " + str(reach[nxt[0]]) + " min") if nxt else "-",
                       Naechste_Stufe_B_nur_Gueter=(list(reachb.keys())[0] + ": " + str(list(reachb.values())[0]) + " min") if reachb else "-"))
    write_csv("t04_startpunkte_archetypen.csv", st)

    # ---------------- F) Saettigung: Ertrag vs Versorgungsgrad
    sat = []
    for s in [x / 20 for x in range(0, 61)]:
        f = f_saett(s)
        sat.append(dict(Versorgung_pct=int(s * 100), F_saett=round(f, 3), Ertrag_rel_zum_Bedarf=round(s * f, 3)))
    write_csv("t04_saettigung_kurve.csv", sat)
    s_star = max(sat, key=lambda r: r["Ertrag_rel_zum_Bedarf"])
    return rows, best, tor, s_star


def write_csv(name, rows):
    with open(os.path.join(OUT, name), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()), delimiter=";")
        w.writeheader()
        for r in rows:
            w.writerow(r)


if __name__ == "__main__":
    rows, best, tor, s_star = main()
    for r in rows:
        print(r)
    print("Kalibrierung B:", best)
    print("Tor/Anlauf:")
    for r in tor:
        print(r)
    print("Saettigung Optimum:", s_star)
