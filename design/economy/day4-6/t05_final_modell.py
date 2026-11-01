#!/usr/bin/env python3
"""T-05 FINAL (Tag 4, 19.11.) -- Gegenrechnung mit Lenas HQ-Startwerten, Kohle-Zufluss im Bergbau,
Kreditrahmen ab Minute 0 (D1) und einmaligem Kaufrabatt (D1).

Nachfolger von day1-3/tobias/t05_modell.py (unveraendert gelassen). Deterministisch, kein Zufall.
MODELLRECHNUNG, keine Spielerdaten. Jede Setzung ist mit ANNAHME markiert.
Lauf: python3 t05_final_modell.py  -> schreibt t05_final_*.csv neben das Skript.

Aenderungen gegenueber Tag 1-3:
 1. Lenas Werte (lena/hq_startwerte.md): Startkapital 4.500/4.500/7.000/5.000 $ plus Rahmen (3.500-5.000 usw.),
    Kettenlaengen, Kaufpreise, Nachfrage. Stimmen mit meinen Annahmen ueberein (Lena hat mein Modell uebernommen),
    Abweichungen siehe t05_final.md.
 2. Bergbau: Stahlwerk braucht Erz UND Kohle (Lena, Widersprueche 11). Zweiter Zufluss Kohlemine
    (ANNAHME: Kaufpreis 1.200 $, P_gut 0,40 aus tobias.md, 15 Felder, Verhaeltnis 1:1, 20 E/min).
 3. Kreditrahmen ab Minute 0 (D1): Vorschlag Hoehe 2.000 $, Zins 1 %/Spielminute auf den gezogenen Betrag,
    Sperre: kein Firmenkauf und kein Ausbau, solange der Kontostand negativ ist. Strasse/Lkw/Lizenz duerfen
    den Rahmen nutzen. Hoehe/Zins werden unten als Raster geprueft (t05_final_kredit_test.csv).
 4. Kaufrabatt -20 % nur einmalig (M5b). Im Modell gibt es nur einen Kauf; Vergleich mit/ohne Rabatt bleibt
    in t05_final_rabatt.csv, die Break-even-Tabelle rechnet den Direktkauf ohne Rabatt (wie bisher).
"""
import csv, math, os

OUT = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- feste Regeln (Brief / Konzept / D1)
LIC_PCT = 0.10
LIC_MIN = 30
LIC_RADIUS_DISC = 0.30
OUTSIDE_SURCH = 0.03
CREDIT_PCT = 0.50       # Anrechnung der Lizenzgebuehren beim Kauf
MARGE = 0.15
UPKEEP = 20.0
BUY_DISC = 0.20         # nur einmalig (D1), siehe Rabatt-Tabelle
TRUCK_COST, TRUCK_FIX, TRUCK_VAR, TRUCK_CAP, TRUCK_SPEED = 400, 90.0, 0.08, 10, 6.0
ROAD = 10.0
LOAD_S = 10.0           # ANNAHME wie Tag 1-3
Q1 = 20.0
FW_INVEST = 0.60
# Kreditrahmen (Vorschlag, D1 "ab Minute 0"; Hoehe und Zins sind MEINE Setzung, siehe antwort_felix_kredit.md)
KREDIT_HOEHE = 2000.0
KREDIT_ZINS = 0.01      # je Spielminute auf den gezogenen Betrag


def f_saett(s):
    if s <= 1.0:
        return 1.0
    if s <= 1.5:
        return 1.0 - 0.6 * (s - 1.0) / 0.5
    return 0.1


def d_eff(d):
    return 0.0 if d < 6 else (d if d <= 60 else 60 + 0.5 * (d - 60))


def cycle_s(d):
    return 2 * d / TRUCK_SPEED + LOAD_S


def truck_cap_per_min(d):
    return TRUCK_CAP * 60.0 / cycle_s(d)


# ---------------------------------------------------------------- Archetypen (Lenas Tabelle 1 + meine Ketten)
# inputs: Liste der Rohstoff-Firmen (Name, Kaufpreis, P_gut, Felder zum Verarbeiter). inputs[0] ist "R" (Ziel der
# Rohstoff-Startfaelle), ein etwaiger zweiter Zufluss ist "R2" (Bergbau: Kohle).
ARCH = {
    "Agrar": dict(stadt="Dorf 900 Einw. (Fluss/Ebene)", C_lena=4500, C_min=3500, C_max=5000, build=0.90,
                  inputs=[("Getreidefarm", 1000, 0.40, 18)], V=("Muehle", 2000, 1.00), d2=45, demand=25.0, export=False),
    "Hafen": dict(stadt="Kleinstadt 3.200 Einw. (Kueste)", C_lena=4500, C_min=3500, C_max=5000, build=1.20,
                  inputs=[("Holzfaeller", 1000, 0.35, 15)], V=("Saegewerk", 2000, 0.90), d2=40, demand=20.0, export=True),
    "Bergbau": dict(stadt="Kleinstadt 2.500 Einw. (Gebirge)", C_lena=7000, C_min=6000, C_max=7500, build=1.44,
                    inputs=[("Erzmine", 1800, 0.45, 20), ("Kohlemine", 1200, 0.40, 15)],   # Kohle: ANNAHME
                    V=("Stahlwerk", 4000, 1.00), d2=40, demand=40.0, export=False),
    "Handel": dict(stadt="Stadt 12.000 Einw. (Fluss+Kreuzung)", C_lena=5000, C_min=4000, C_max=5500, build=1.50,
                   inputs=[("Viehhof", 1200, 0.50, 20)], V=("Schlachthof", 2500, 1.30), d2=15, demand=120.0, export=False),
}
KEYS = ["R", "R2", "V"]


def firms(a):
    f = {"R": a["inputs"][0], "V": a["V"]}
    if len(a["inputs"]) > 1:
        f["R2"] = a["inputs"][1]
    return f


def startpaket(a):
    """Strasse + Lkw fuer 20 E/min je Zufluss und fuer den Abfluss (ohne Lager)."""
    flow = min(Q1, a["demand"])
    road = 0.0
    trucks = {}
    for i, (nm, K, P, d) in enumerate(a["inputs"]):
        key = "R" if i == 0 else "R2"
        trucks[key] = max(1, math.ceil(Q1 / truck_cap_per_min(d)))
        road += d
    trucks["out"] = max(1, math.ceil(flow / truck_cap_per_min(a["d2"])))
    road += a["d2"]
    road_cost = ROAD * a["build"] * road
    return road_cost, trucks, road_cost + sum(trucks.values()) * TRUCK_COST


def lic_price(K, in_radius=True, over=0):
    base = K * LIC_PCT
    return base * (1 - LIC_RADIUS_DISC) if in_radius else base * (1 + OUTSIDE_SURCH * over)


def simulate(arch, strategy, target="V", C=None, horizon=90, ai=False, ai_start=15, ai_market=0.4,
             rabatt=False, over=0, demand=None, kredit=0.0, zins=KREDIT_ZINS, gratis=True):
    """strategy: 'K0' Ziel sofort kaufen | 'L' nur Lizenzen | 'LK30' Lizenz, Kauf bei t=30 | 'LKa' Kauf sobald bezahlbar.
    kredit: Kreditrahmen (Kontostand darf bis -kredit fallen fuer Strasse, Lkw, Lizenz; Firmenkauf nur aus Guthaben).
    gratis: Gratis-Lizenz auf EINER Nicht-Ziel-Firma (hq.md). Rabatt: nur wenn explizit gesetzt (D1: einmalig)."""
    a = dict(ARCH[arch])
    if demand is not None:
        a["demand"] = demand
    C = a["C_lena"] if C is None else C
    F = firms(a)
    K = {k: F[k][1] for k in F}
    K[target] *= (1 + OUTSIDE_SURCH * over)
    Lp = {k: lic_price(F[k][1]) for k in F}
    Lp[target] = lic_price(F[target][1], in_radius=(over == 0), over=over)
    others = [k for k in F if k != target]
    road_cost, need, S0 = startpaket(a)
    cash = float(C)
    own = {k: False for k in F}
    lic = {k: False for k in F}
    fees = {k: 0.0 for k in F}
    have = {k: 0 for k in need}
    road_built = False
    asset_inv = paid_purchase = 0.0
    t_full = t_rev2 = t_afford = bought_at = None
    kredit_max = 0.0
    t_kredit = t_repaid = None
    zins_sum = 0.0
    rows = []

    def avail():
        return cash + kredit

    def pay_licence(f, t0):
        nonlocal cash
        price = Lp[f]
        if gratis and t0 == 0 and f == others[0]:
            price = 0.0
        if avail() >= price:
            cash -= price; fees[f] += price; lic[f] = True
        return price

    if strategy == "K0":
        if cash >= K[target]:
            cash -= K[target]; own[target] = True; paid_purchase += K[target]; bought_at = 0
        for o in others:
            pay_licence(o, 0)
    else:
        for o in others:
            pay_licence(o, 0)
        pay_licence(target, 0)

    for t in range(horizon):
        if t > 0 and t % LIC_MIN == 0:
            for f in F:
                if lic[f] and not own[f]:
                    cash -= Lp[f]; fees[f] += Lp[f]
        if strategy in ("LK30", "LKa") and not own[target]:
            disc = BUY_DISC if (rabatt and over == 0 and lic[target]) else 0.0
            net = K[target] * (1 - disc) - CREDIT_PCT * fees[target]
            if ai and t >= ai_start:
                net += 0.5 * Lp[target]
            reserve = Lp[others[0]] + TRUCK_COST
            ok = False
            if strategy == "LK30" and t == LIC_MIN:
                ok = cash >= net                              # Firmenkauf nur aus Guthaben (Sperre)
            if strategy == "LKa":
                if cash >= net + reserve and t_afford is None and road_built:
                    t_afford = t
                ok = cash >= net + reserve and road_built
            if ok:
                cash -= net; own[target] = True; paid_purchase += net; lic[target] = False; bought_at = t
        # Startpaket, Reihenfolge Strasse, Zufluss-Lkw, Abfluss-Lkw; darf den Kreditrahmen nutzen
        if not road_built and avail() >= road_cost:
            cash -= road_cost; road_built = True; asset_inv += road_cost
        if road_built:
            for key in [k for k in ("R", "R2") if k in need] + ["out"]:
                while have[key] < need[key] and avail() >= TRUCK_COST:
                    cash -= TRUCK_COST; have[key] += 1; asset_inv += TRUCK_COST
        # Fluesse
        ai_on = ai and t >= ai_start
        def pf(f):
            return 1.0 if (own[f] or lic[f]) else 0.5
        def share(f):
            return 1.0 if own[f] else (0.5 if (ai_on and lic[f]) else 1.0)
        rev1 = 0.0; dist_trips = 0.0; inflow = []
        for i, (nm, Kx, P, d) in enumerate(a["inputs"]):
            key = "R" if i == 0 else "R2"
            q = Q1 * pf(key) * share(key)
            cap = have[key] * truck_cap_per_min(d) if road_built else 0.0
            dl = min(q, cap)
            inflow.append(dl)
            r = dl * P * d_eff(d)
            rev1 += r
            if own[key]:
                rev1 += MARGE * r          # Werksmarge (Lesart: Zuschlag auf eigenen Transportertrag)
            dist_trips += 2 * d * dl / TRUCK_CAP
        del1 = min(inflow)                 # Stahl braucht Erz UND Kohle (1:1, ANNAHME)
        qV = min(del1, Q1 * pf("V") * share("V"))
        cap2 = have["out"] * truck_cap_per_min(a["d2"]) if road_built else 0.0
        del2 = min(qV, cap2, a["demand"] if a["export"] else 1e9)
        if a["export"]:
            rev2 = del2 * a["V"][2] * 40.0
        else:
            mkt = del2 + (ai_market * a["demand"] if ai_on else 0.0)
            rev2 = del2 * a["V"][2] * d_eff(a["d2"]) * f_saett(mkt / a["demand"])
        marge2 = MARGE * rev2 if own["V"] else 0.0
        dist_trips += 2 * a["d2"] * del2 / TRUCK_CAP
        truck_cost = sum(have.values()) * TRUCK_FIX + TRUCK_VAR * dist_trips
        upkeep = UPKEEP * sum(own.values())
        z = zins * max(0.0, -cash)
        zins_sum += z
        net = rev1 + rev2 + marge2 - truck_cost - upkeep - z
        if cash < 0:
            kredit_max = max(kredit_max, -cash)
            if t_kredit is None:
                t_kredit = t + 1
        cash += net
        if t_kredit is not None and t_repaid is None and cash >= 0:
            t_repaid = t + 1
        fw = FW_INVEST * paid_purchase + 0.5 * asset_inv
        if road_built and all(have[k] >= need[k] for k in need) and t_full is None:
            t_full = t + 1
        if rev2 > 0 and t_rev2 is None:
            t_rev2 = t + 1
        rows.append(dict(t=t + 1, cash=round(cash), rev=round(rev1 + rev2), net=round(net), networth=round(cash + fw),
                         own_V=int(own["V"]), trucks=sum(have.values())))
    return dict(rows=rows, t_afford=t_afford, bought_at=bought_at, S0=S0, K=K, Lp=Lp, paid=paid_purchase, t_full=t_full,
                t_rev2=t_rev2, fees=fees, kredit_max=kredit_max, t_kredit=t_kredit, t_repaid=t_repaid, zins_sum=zins_sum,
                need=need)


def breakeven(rK, rL, field):
    be = None
    for i in range(len(rK["rows"])):
        if rK["rows"][i][field] >= rL["rows"][i][field]:
            if be is None:
                be = i + 1
        else:
            be = None
    return be


def write_csv(name, rows):
    path = os.path.join(OUT, name)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()), delimiter=";")
        w.writeheader()
        w.writerows(rows)
    return path


STARTFAELLE = [
    ("F1", "V", False, 0, 1.0, "Verarbeiter im Radius, KI aus (Standard)"),
    ("F2", "V", True, 0, 1.0, "Verarbeiter im Radius, KI teilt Lizenz ab min 15"),
    ("F3", "V", False, 12, 1.0, "Verarbeiter 12 Felder ausserhalb Radius (+36 %)"),
    ("F4", "R", False, 0, 1.0, "Rohstoff-Firma im Radius, KI aus"),
    ("F5", "V", False, 0, None, "Verarbeiter im Radius, kleiner Abnehmermarkt (9 E/min, Dorf 900 Einw.)"),
]


def table_start():
    rows = []
    for arch, a in ARCH.items():
        road, need, S0 = startpaket(a)
        F = firms(a)
        L = {k: lic_price(F[k][1]) for k in F}
        drei = L["R"] + 2 * L["V"] if "R2" not in F else L["R"] + L["R2"] + L["V"]
        C = a["C_lena"]
        KV = F["V"][1]
        rows.append(dict(Archetyp=arch, Startkapital_Lena=C, Rahmen=f'{a["C_min"]}-{a["C_max"]}', Kaufpreis_V=KV,
                         Lizenz_R=round(L["R"]), Lizenz_R2=round(L.get("R2", 0)), Lizenz_V=round(L["V"]),
                         Drei_Lizenzen=round(drei), Strasse=round(road), Lkw=sum(need.values()), Startpaket_S0=round(S0),
                         Rest_nach_Kauf_V_und_S0=round(C - KV - S0), Rest_nach_S0_und_3Lizenzen=round(C - S0 - drei),
                         Rest_in_Kaufpreisen=round((C - S0 - drei) / KV, 2),
                         Kauf_plus_S0_bezahlbar=int(C >= KV + S0),
                         Formel_K_V_plus_1p5_S0_plus_L_R=math.ceil((KV + 1.5 * S0 + L["R"]) / 500) * 500))
    return rows


def table_breakeven(C=10**6, horizon=120):
    rows = []
    for arch in ARCH:
        a = ARCH[arch]
        for tag, firm, ai, over, dem, desc in STARTFAELLE:
            d = 9.0 if dem is None else a["demand"] * dem
            kw = dict(C=C, horizon=horizon, ai=ai, over=over, demand=d)
            rK = simulate(arch, "K0", target=firm, **kw)
            rL = simulate(arch, "L", target=firm, **kw)
            bec, ben = breakeven(rK, rL, "cash"), breakeven(rK, rL, "networth")
            rate_K, rate_L = rK["rows"][59]["net"], rL["rows"][59]["net"]
            Lf = rK["Lp"][firm]
            rows.append(dict(Archetyp=arch, Fall=tag, Beschreibung=desc, Firma=firms(a)[firm][0], Kaufpreis=round(rK["K"][firm]),
                             Lizenz_je30min=round(Lf, 1), Rate_Lizenz_pro_min=rate_L, Rate_Kauf_pro_min=rate_K,
                             Mehrertrag_Besitz_pro_min=round(rate_K - rate_L + Lf / LIC_MIN, 1),
                             Break_even_Cash_min=bec if bec else ">120", Break_even_Netto_min=ben if ben else ">120",
                             Lizenzroute_vorn_ueber_30min=int(bec is None or bec > LIC_MIN)))
    return rows


def table_kredit():
    """Soft-Lock-Pruefung: Kauf-Route (Verarbeiter sofort) bei Lenas Empfehlung, Unter-/Obergrenze und dem knappen
    Wert aus Tag 1-3, je ohne und mit Kreditrahmen (Raster Hoehe 1.000/2.000/3.000, Zins 0/1/2 %)."""
    rows = []
    for arch, a in ARCH.items():
        S0 = startpaket(a)[2]
        KV = a["V"][1]
        knapp = math.ceil((KV + 0.6 * S0) / 500) * 500
        for label, C in (("Empfehlung", a["C_lena"]), ("Untergrenze", a["C_min"]), ("Obergrenze", a["C_max"]),
                         ("knapp K_V+0,6 S0", knapp), ("Untergrenze -500", a["C_min"] - 500)):
            for kr, zs in ((0, 0.0), (1000, 0.01), (2000, 0.0), (2000, 0.01), (2000, 0.02), (3000, 0.01)):
                r = simulate(arch, "K0", target="V", C=C, horizon=90, kredit=kr, zins=zs)
                rows.append(dict(Archetyp=arch, Kapital=label, Startkapital=C, Kreditrahmen=kr, Zins_pro_min=zs,
                                 Kauf_min0=int(r["bought_at"] == 0), t_Linie_voll=r["t_full"] or ">90",
                                 Kredit_max_gezogen=round(r["kredit_max"]), Kredit_ab_min=r["t_kredit"] or "-",
                                 zurueckgezahlt_min=r["t_repaid"] or ("-" if r["t_kredit"] is None else ">90"),
                                 Zinsen_gesamt=round(r["zins_sum"]), Bargeld_min30=r["rows"][29]["cash"],
                                 Bargeld_min60=r["rows"][59]["cash"], Bargeld_min90=r["rows"][89]["cash"],
                                 Softlock=int(r["t_full"] is None)))
    return rows


def table_rabatt():
    rows = []
    for arch, a in ARCH.items():
        for k, (nm, K, P, *rest) in firms(a).items():
            L = lic_price(K)
            for n in (1, 2):
                for rb in (0, 1):
                    price = K * (1 - (BUY_DISC if rb else 0)) - CREDIT_PCT * n * L
                    rows.append(dict(Archetyp=arch, Firma=nm, Kaufpreis=K, Lizenz=round(L), Perioden=n, Rabatt_einmalig=rb,
                                     Kaufpreis_nach_Anrechnung=round(price), Gesamtausgabe=round(n * L + price),
                                     Anteil_vom_Direktkauf=round((n * L + price) / K, 3)))
    return rows


def table_bergbau_kohle():
    """Vergleich Bergbau nur Erz (Tag 1-3) gegen Erz + Kohle (final), Standardfall F1, Kapital unbegrenzt."""
    rows = []
    saved = ARCH["Bergbau"]["inputs"]
    for label, inputs in (("nur Erz (Tag 1-3)", [saved[0]]), ("Erz + Kohle (final)", saved)):
        ARCH["Bergbau"]["inputs"] = inputs
        a = ARCH["Bergbau"]
        road, need, S0 = startpaket(a)
        rK = simulate("Bergbau", "K0", target="V", C=10**6, horizon=120)
        rL = simulate("Bergbau", "L", target="V", C=10**6, horizon=120)
        rC = simulate("Bergbau", "K0", target="V", C=a["C_lena"], horizon=90)
        rows.append(dict(Variante=label, Startpaket_S0=round(S0), Lkw=sum(need.values()),
                         Lizenzen_Nichtziel_je30min=round(sum(lic_price(x[1]) for x in inputs) - lic_price(inputs[0][1])),
                         Rate_Lizenz_pro_min=rL["rows"][59]["net"], Rate_Kauf_pro_min=rK["rows"][59]["net"],
                         Break_even_Cash_min=breakeven(rK, rL, "cash") or ">120",
                         Kauf_Route_7000_t_Linie_voll=rC["t_full"] or ">90", Bargeld_min30_bei_7000=rC["rows"][29]["cash"],
                         Formel_Startkapital=math.ceil((a["V"][1] + 1.5 * S0 + lic_price(inputs[0][1])) / 500) * 500))
    ARCH["Bergbau"]["inputs"] = saved
    return rows


def main():
    write_csv("t05_final_startkapital.csv", table_start())
    be = table_breakeven()
    write_csv("t05_final_breakeven.csv", be)
    write_csv("t05_final_kredit_test.csv", table_kredit())
    write_csv("t05_final_rabatt.csv", table_rabatt())
    write_csv("t05_final_bergbau_kohle.csv", table_bergbau_kohle())
    # Kurzausgabe
    print("== Startkapital (Lena) und Reste")
    for r in table_start():
        print(r)
    print("== Break-even je Startfall (Kapital unbegrenzt)")
    ok = {}
    for r in be:
        print(r["Archetyp"], r["Fall"], r["Firma"], "BEc", r["Break_even_Cash_min"], "BEn", r["Break_even_Netto_min"],
              "Lizenz vorn:", r["Lizenzroute_vorn_ueber_30min"], "Rate L/K", r["Rate_Lizenz_pro_min"], r["Rate_Kauf_pro_min"])
        ok.setdefault(r["Archetyp"], []).append(r["Fall"]) if r["Lizenzroute_vorn_ueber_30min"] else None
    print("== Archetypen mit >= 1 Startfall Lizenz vorn:", {k: v for k, v in ok.items()}, "->", len(ok), "/ 4")
    print("== Bergbau Kohle")
    for r in table_bergbau_kohle():
        print(r)
    print("== Kredit-Test (nur Zeilen mit Soft-Lock ohne Kredit oder Untergrenzen)")
    for r in table_kredit():
        if r["Kapital"] != "Empfehlung" or r["Kreditrahmen"] in (0, 2000):
            print(r)


if __name__ == "__main__":
    main()
