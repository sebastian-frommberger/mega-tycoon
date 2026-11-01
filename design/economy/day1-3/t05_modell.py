#!/usr/bin/env python3
"""T-05 Startkapital und Lizenz/Kauf-Leiter -- Modellrechnung (deterministisch, kein Zufall).

Alles hier ist eine MODELLRECHNUNG mit offengelegten Annahmen (Markierung ANNAHME).
Quellen: concept/tobias.md, industry.md, hq.md, city.md, briefing.md (Prototyp-Preise).
Lauf:  python3 t05_modell.py   -> schreibt CSV-Dateien neben das Skript.

Zeitschritt: 1 min = 1 Spielmonat (city.md). Ertrag je min im Gleichgewicht der gebauten Anlage.
"""
import csv, math, os, itertools

OUT = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- feste Regeln (Brief / Konzept)
LIC_PCT = 0.10          # Lizenz = 10 % des Kaufpreises je Laufzeit
LIC_MIN = 30            # Laufzeit in min
LIC_RADIUS_DISC = 0.30  # Lizenzrabatt im Radius (hq.md)
OUTSIDE_SURCH = 0.03    # +3 %/Feld ausserhalb Radius
CREDIT = 0.50           # 50 % der gezahlten Lizenzgebuehren werden beim Kauf angerechnet
MARGE = 0.15            # Werksmarge
UPKEEP = 20.0           # $/min x Stufe
BUY_DISC = 0.20         # Kaufrabatt fuer lizenzierte Firma im Radius (hq.md) -- wird als Variante geprueft
TRUCK_COST, TRUCK_FIX, TRUCK_VAR, TRUCK_CAP, TRUCK_SPEED = 400, 90.0, 0.08, 10, 6.0
ROAD = 10.0             # $/Feld (briefing.md, Prototyp)
LOAD_S = 10.0           # ANNAHME: Be-/Entladen je Fahrt gesamt 10 s (Rampe 2 E/s, 10 Einheiten je Seite 5 s)
Q1 = 20.0               # Durchsatz Stufe 1 (E/min)
FW_INVEST = 0.60        # Firmenwert = 60 % der Investition (+12 x Monatsueberschuss, hier konservativ weggelassen)


def f_saett(s):
    """F_saett: bis 100 % Bedarf 1,0; 100->150 % linear auf 0,4; darueber 0,1 (tobias.md)."""
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


# ---------------------------------------------------------------- Archetypen (ANNAHME: konkrete Ketten/Distanzen)
# hq.md liefert: Stadtgroesse, Startkapital, Baufaktor, Radius, Lagebonus. Die Start-Kette je Archetyp,
# Basispreise und Distanzen sind ANNAHMEN von mir (Lenas Dateien lagen nicht vor).
ARCH = {
    "Agrar": dict(
        stadt="Dorf 900 Einw. (Fluss/Ebene)", C_hq=30000, build=1.0 * 0.9,   # Ebene: Strecken -10 %
        R=("Getreidefarm", 1000, 0.40), V=("Muehle", 2000, 1.00),
        d1=18, d2=45, in_radius=True, demand=25.0, export=False,   # Abnehmer: Nachbar-Kleinstadt 2.500 Einw. -> 25 E/min Nahrung
    ),
    "Hafen": dict(
        stadt="Kleinstadt 3.200 Einw. (Kueste)", C_hq=25000, build=1.2,
        R=("Holzfaeller", 1000, 0.35), V=("Saegewerk", 2000, 0.90),
        d1=15, d2=40, in_radius=True, demand=20.0, export=True,    # Export zu Fixpreis, 20 E/min Deckel (hq.md); Preis ANNAHME = P x 40 Felder
    ),
    "Bergbau": dict(
        stadt="Kleinstadt 2.500 Einw. (Gebirge)", C_hq=25000, build=1.2 * 1.2,  # Bau +20 % und Strecken +20 %
        R=("Erzmine", 1800, 0.45), V=("Stahlwerk", 4000, 1.00),
        d1=20, d2=40, in_radius=True, demand=40.0, export=False,   # Abnehmer ANNAHME: Werkzeugfabrik/Stadt, 40 E/min
    ),
    "Handel": dict(
        stadt="Stadt 12.000 Einw. (Fluss+Kreuzung)", C_hq=20000, build=1.5,
        R=("Viehhof", 1200, 0.50), V=("Schlachthof", 2500, 1.30),
        d1=20, d2=15, in_radius=True, demand=120.0, export=False,  # Nahrung 12.000/100 = 120 E/min, Fleisch (Frischegut)
    ),
}


def startpaket(a, extra_road=0):
    """Strasse + Lkw, die fuer 20 E/min Durchsatz noetig sind (ohne Lager)."""
    d1, d2 = a["d1"], a["d2"]
    flow = min(Q1, a["demand"])
    n1 = max(1, math.ceil(Q1 / truck_cap_per_min(d1)))
    n2 = max(1, math.ceil(flow / truck_cap_per_min(d2)))
    road = ROAD * a["build"] * (d1 + d2 + extra_road)
    return road, n1, n2, road + (n1 + n2) * TRUCK_COST


def lic_price(K, in_radius=True, over=0):
    """Lizenzgebuehr je Laufzeit fuer Kaufpreis K (Radius -30 %, ausserhalb +3 %/Feld auf den Preis)."""
    base = K * LIC_PCT
    return base * (1 - LIC_RADIUS_DISC) if in_radius else base * (1 + OUTSIDE_SURCH * over)


# ---------------------------------------------------------------- Zeitreihen-Simulation
def simulate(arch, strategy, target="V", C=None, horizon=90, ai=False, ai_start=15, ai_market=0.4,
             marge_on_own=True, rabatt=True, over=0, stufe_mult=1.0, afford_reserve=None, demand=None):
    """strategy: 'K0' (Ziel sofort kaufen), 'L' (nur Lizenzen), 'LK30' (Lizenz, Kauf im ersten Verlaengerungsfenster t=30),
    'LKa' (Lizenz, Kauf sobald bezahlbar mit Reserve; liefert t_afford).
    Das jeweils andere Unternehmen der Kette wird lizenziert (Gratis-Lizenz auf dem NICHT-Ziel).
    over: Felder ausserhalb des Radius fuer das Ziel (Aufschlag +3 %/Feld auf Kaufpreis und Lizenz).
    """
    a = dict(ARCH[arch])
    if demand is not None:
        a["demand"] = demand
    C = a["C_hq"] if C is None else C
    names = {"R": a["R"], "V": a["V"]}
    K = {"R": a["R"][1] * stufe_mult, "V": a["V"][1] * stufe_mult}
    K[target] *= (1 + OUTSIDE_SURCH * over)           # Kaufpreis ausserhalb Radius +3 %/Feld
    other = "R" if target == "V" else "V"
    Lp = {"R": lic_price(a["R"][1] * stufe_mult), "V": lic_price(a["V"][1] * stufe_mult)}
    Lp[target] = lic_price(a["V" if target == "V" else "R"][1] * stufe_mult, in_radius=(over == 0), over=over)
    road_cost, n1, n2, S0 = startpaket(a)
    cash = float(C)
    asset_inv = 0.0
    t_full = None
    t_rev2 = None
    own = {"R": False, "V": False}
    lic = {"R": False, "V": False}
    fees = {"R": 0.0, "V": 0.0}
    paid_purchase = 0.0
    road_built, t1, t2 = False, 0, 0
    rows = []
    cum_rev = 0.0
    t_afford = None
    bought_at = None
    firm_in_flow = {}

    # ---- t = 0 Entscheidungen
    def pay_licence(f, t):
        nonlocal cash
        price = Lp[f]
        if f == other and t == 0:
            price = 0.0                              # Gratis-Lizenz auf dem Nicht-Ziel
        if cash >= price:
            cash -= price
            fees[f] += price
            lic[f] = True
        return price

    if strategy == "K0":
        if cash >= K[target]:
            cash -= K[target]; own[target] = True; paid_purchase += K[target]; bought_at = 0
        pay_licence(other, 0)
    else:
        pay_licence(other, 0)
        pay_licence(target, 0)

    for t in range(horizon):
        # ---- Verlaengerung (Auto-Verlaengern) alle 30 min, ausser Besitz
        if t > 0 and t % LIC_MIN == 0:
            for f in ("R", "V"):
                if lic[f] and not own[f]:
                    cash -= Lp[f]; fees[f] += Lp[f]
        # ---- Kauf-Entscheidungen
        if strategy in ("LK30", "LKa") and not own[target]:
            price = K[target]
            disc = BUY_DISC if (rabatt and over == 0 and lic[target]) else 0.0
            net = price * (1 - disc) - CREDIT * fees[target]
            refund = 0.0
            if ai and t >= ai_start:
                refund = 0.5 * Lp[target]            # Fremdlizenz mit Restlaufzeit auszahlen (ANNAHME: im Mittel halbe Laufzeit)
            net += refund
            reserve = afford_reserve if afford_reserve is not None else (Lp[other] + TRUCK_COST)
            ok = False
            if strategy == "LK30" and t == LIC_MIN:
                ok = cash >= net
            if strategy == "LKa":
                if cash >= net + reserve and t_afford is None and road_built:
                    t_afford = t
                ok = cash >= net + reserve and road_built
            if ok:
                cash -= net; own[target] = True; paid_purchase += net; lic[target] = False; bought_at = t
        # ---- Bau des Startpakets (cash-begrenzt, Reihenfolge Strasse, Lkw1, Lkw2)
        if not road_built and cash >= road_cost:
            cash -= road_cost; road_built = True; asset_inv += road_cost
        if road_built:
            while t1 < n1 and cash >= TRUCK_COST:
                cash -= TRUCK_COST; t1 += 1; asset_inv += TRUCK_COST
            while t1 >= n1 and t2 < n2 and cash >= TRUCK_COST:
                cash -= TRUCK_COST; t2 += 1; asset_inv += TRUCK_COST
        # ---- Fluesse
        ai_on = ai and t >= ai_start
        def pf(f):
            return 1.0 if (own[f] or lic[f]) else 0.5
        def share(f):
            return 1.0 if own[f] else (0.5 if (ai_on and lic[f]) else 1.0)
        qR = Q1 * pf("R") * share("R")
        cap1 = t1 * truck_cap_per_min(a["d1"]) if road_built else 0.0
        del1 = min(qR, cap1)
        qV = min(del1, Q1 * pf("V") * share("V"))
        cap2 = t2 * truck_cap_per_min(a["d2"]) if road_built else 0.0
        del2 = min(qV, cap2, a["demand"] if a["export"] else 1e9)
        rev1 = del1 * a["R"][2] * d_eff(a["d1"])
        if a["export"]:
            rev2 = del2 * a["V"][2] * 40.0
        else:
            mkt = del2 + (ai_market * a["demand"] if ai_on else 0.0)
            rev2 = del2 * a["V"][2] * d_eff(a["d2"]) * f_saett(mkt / a["demand"])
        trips1 = del1 / TRUCK_CAP
        trips2 = del2 / TRUCK_CAP
        truck_cost = (t1 + t2) * TRUCK_FIX + TRUCK_VAR * (2 * a["d1"] * trips1 + 2 * a["d2"] * trips2)
        marge = 0.0
        if marge_on_own:
            if own["R"]: marge += MARGE * rev1
            if own["V"]: marge += MARGE * rev2
        upkeep = UPKEEP * stufe_mult * (own["R"] + own["V"])
        net = rev1 + rev2 + marge - truck_cost - upkeep
        cash += net
        cum_rev += rev1 + rev2
        fw = FW_INVEST * paid_purchase + 0.5 * asset_inv
        if road_built and t1 >= n1 and t2 >= n2 and t_full is None:
            t_full = t + 1
        if rev2 > 0 and t_rev2 is None:
            t_rev2 = t + 1
        rows.append(dict(t=t + 1, cash=round(cash), rev=round(rev1 + rev2), marge=round(marge), net=round(net),
                         networth=round(cash + fw), own_V=int(own["V"]), own_R=int(own["R"]), trucks=t1 + t2))
    res = dict(rows=rows, t_afford=t_afford, bought_at=bought_at, S0=S0, K=K, Lp=Lp, paid=paid_purchase, t_full=t_full, t_rev2=t_rev2, fees=dict(fees))
    return res


def nw(res, t):
    return res["rows"][t - 1]["networth"]


def breakeven_nw(rK, rL):
    """Erste Minute, ab der Kauf-Route (rK) Nettovermoegen >= Lizenz-Route (rL) hat und es bleibt."""
    n = len(rK["rows"])
    be = None
    for i in range(n):
        if rK["rows"][i]["networth"] >= rL["rows"][i]["networth"]:
            if be is None:
                be = i + 1
        else:
            be = None
    return be


def breakeven_cash(rK, rL):
    n = len(rK["rows"])
    be = None
    for i in range(n):
        if rK["rows"][i]["cash"] >= rL["rows"][i]["cash"]:
            if be is None:
                be = i + 1
        else:
            be = None
    return be


# ---------------------------------------------------------------- Auswertungen
def write_csv(name, rows, fields=None):
    path = os.path.join(OUT, name)
    fields = fields or list(rows[0].keys())
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, delimiter=";")
        w.writeheader()
        for r in rows:
            w.writerow(r)
    return path


def table_archetypes():
    rows = []
    for k, a in ARCH.items():
        road, n1, n2, S0 = startpaket(a)
        KR, KV = a["R"][1], a["V"][1]
        LR, LV = lic_price(KR), lic_price(KV)
        rows.append(dict(
            Archetyp=k, Stadt=a["stadt"], Startkapital_hq=a["C_hq"],
            Rohstoff=a["R"][0], K_R=KR, Lizenz_R_je30min=round(LR, 1),
            Verarbeiter=a["V"][0], K_V=KV, Lizenz_V_je30min=round(LV, 1),
            Lizenz_3x_Summe=round(2 * LV + LR, 1) if False else round(LR + LV + LV, 1),
            Startpaket_S0=round(S0), Strasse=round(road), Lkw=n1 + n2,
            hq_Kapital_in_K_V=round(a["C_hq"] / KV, 1), hq_Kapital_in_S0=round(a["C_hq"] / S0, 1),
            Verhaeltnis_3Lizenzen_zu_1Kauf=round((LR + LV + LV) / KV, 3),
        ))
    return rows



STARTFAELLE = [
    # (Kuerzel, Firma, KI aktiv, Felder ausserhalb Radius, Nachfrage-Faktor auf den Abnehmermarkt, Beschreibung)
    ("F1", "V", False, 0, 1.0, "Verarbeiter im Radius, KI aus (Standard)"),
    ("F2", "V", True, 0, 1.0, "Verarbeiter im Radius, KI teilt Lizenz ab min 15"),
    ("F3", "V", False, 12, 1.0, "Verarbeiter 12 Felder ausserhalb Radius (+36 %)"),
    ("F4", "R", False, 0, 1.0, "Rohstoff-Firma im Radius, KI aus"),
    ("F5", "V", False, 0, None, "Verarbeiter im Radius, kleiner Abnehmermarkt (nur 9 E/min Nachfrage = Dorf 900 Einw.)"),
]


def run_cases(C=10**6, horizon=120):
    rows = []
    for arch in ARCH:
        a = ARCH[arch]
        for tag, firm, ai, over, dem, desc in STARTFAELLE:
            d = 9.0 if dem is None else a["demand"] * dem
            kw = dict(C=C, horizon=horizon, ai=ai, ai_start=15, over=over, demand=d)
            rK = simulate(arch, "K0", target=firm, **kw)
            rL = simulate(arch, "L", target=firm, **kw)
            rLK = simulate(arch, "LK30", target=firm, **kw)
            bec, ben = breakeven_cash(rK, rL), breakeven_nw(rK, rL)
            K = rK["K"][firm]; Lf = rK["Lp"][firm]
            rate_K, rate_L = rK["rows"][59]["net"], rL["rows"][59]["net"]
            dRate = rate_K - rate_L + Lf / LIC_MIN
            Keff_direct = K
            payback_analytic = Keff_direct / dRate if dRate > 0 else float("inf")
            verdict = "Lizenz vorn" if (bec is None or bec > LIC_MIN) else "Kauf vorn"
            rows.append(dict(
                Archetyp=arch, Fall=tag, Beschreibung=desc, Firma=a[firm][0], Kaufpreis=round(K), Lizenz_je30min=round(Lf, 1),
                Rate_Kauf_pro_min=round(rate_K), Rate_Lizenz_pro_min=round(rate_L),
                Mehrertrag_Besitz_pro_min=round(dRate, 1),
                Break_even_Cash_min=bec if bec else ">120", Break_even_Cash_analytisch_min=round(payback_analytic, 1) if payback_analytic < 1e6 else ">120",
                Break_even_Netto_min=ben if ben else ">120",
                Urteil_Schwelle_30min=verdict,
                Lizenz_dann_Kauf_t30_Gesamtausgabe_vs_Direkt=round((rLK["paid"] + rLK["fees"][firm]) / rK["paid"], 3) if rK["paid"] else "",
            ))
    return rows


def pinch_table(C_by_arch, label):
    """Kapitalbegrenzter Vergleich bei gegebenem Startkapital (Ziel = Verarbeiter, Fall F1)."""
    rows = []
    for arch in ARCH:
        C = C_by_arch[arch]
        out = {"Archetyp": arch, "Startkapital": C, "Variante": label}
        for strat in ("K0", "L", "LKa"):
            r = simulate(arch, strat, target="V", C=C, horizon=90, ai=False)
            out[f"{strat}_t_Linie_voll"] = r["t_full"] if r["t_full"] else ">90"
            out[f"{strat}_t_erste_Einnahme_Stufe2"] = r["t_rev2"] if r["t_rev2"] else ">90"
            out[f"{strat}_NW_min10"] = nw(r, 10)
            out[f"{strat}_NW_min30"] = nw(r, 30)
            out[f"{strat}_NW_min60"] = nw(r, 60)
            if strat == "LKa":
                out["LKa_t_Kauf_bezahlbar_mit_Reserve"] = r["t_afford"] if r["t_afford"] is not None else ">90"
                out["LKa_Kauf_ausgefuehrt_min"] = r["bought_at"] if r["bought_at"] is not None else "-"
        K0 = simulate(arch, "K0", target="V", C=C, horizon=90)
        out["K0_Kauf_moeglich_bei_min0"] = int(K0["bought_at"] == 0)
        Lr = simulate(arch, "L", target="V", C=C, horizon=90)
        out["Casual_Einkommen_pro_min_voll"] = Lr["rows"][59]["net"]
        out["Startkapital_in_min_Einkommen"] = round(C / max(Lr["rows"][59]["net"], 1), 1)
        rows.append(out)
    return rows


def derive_C_neu():
    """Startkapital aus Bedingungen (Operationalisierung von '3 Lizenzen oder knapp 1 Kauf'):
    (A) Casual-Route: Startpaket S0 + Zahlungs-Lizenz + 1 Verlaengerung aller Lizenzen sind bezahlbar, danach bleibt
        etwa der Gegenwert EINES Kaufs uebrig (Puffer fuer Lager/Lkw/Ausbau, Kauf nach Beweis).
    (B) Kauf-Route: Kauf des Verarbeiters (K_V) + volles Startpaket S0 sind bezahlbar ('knapp 1 Kauf'), aber ohne Puffer.
    (C) Kein Soft-Lock: nach dem Kauf laeuft die Linie ab Minute 1-2 (Simulation K0: t_Linie_voll <= 2).
    -> C_neu = K_V + 1,5 x S0 + Lizenz_R, aufgerundet auf 500 (Sicherheitsmarge 50 % auf das Startpaket).
    """
    res = {}
    chk = []
    for arch, a in ARCH.items():
        S0 = startpaket(a)[3]
        KV, KR = a["V"][1], a["R"][1]
        LV, LR = lic_price(KV), lic_price(KR)
        C = math.ceil((KV + 1.5 * S0 + LR) / 500.0) * 500   # 1,5 x S0: 50 % Spielraum fuer Fehlplanung (Umweg, Gelaende)
        A = C >= 1.5 * S0 + LV + (LV + LR)
        B = C >= KV + 1.5 * S0
        k0 = simulate(arch, "K0", target="V", C=C, horizon=30)
        Cc = (k0["t_full"] is not None) and k0["t_full"] <= 2
        res[arch] = C
        chk.append(dict(Archetyp=arch, S0=round(S0), K_V=KV, C_neu=C, C_hq=a["C_hq"], Faktor_zu_hq=round(C / a["C_hq"], 2),
                        A_casual_ok_mit_1p5_S0=int(A), B_kauf_plus_1p5_S0_ok=int(B), C_kein_softlock_K0=int(Cc),
                        Rest_nach_Kauf_und_Startpaket=round(C - KV - S0),
                        Rest_Casual_nach_Startpaket_und_3Lizenzen=round(C - S0 - (LR + 2 * LV)),
                        Rest_Casual_in_K_V=round((C - S0 - (LR + 2 * LV)) / KV, 2),
                        Drei_Lizenzen_Summe=round(LR + 2 * LV, 1), Drei_Lizenzen_Anteil_von_K_V=round((LR + 2 * LV) / KV, 3)))
    return res, chk


def with_scale(scale):
    """Kaufpreise (und damit Lizenzen) skalieren -- fuer Option B im Decision Record."""
    import copy
    saved = copy.deepcopy(ARCH)
    for a in ARCH.values():
        a["R"] = (a["R"][0], a["R"][1] * scale, a["R"][2])
        a["V"] = (a["V"][0], a["V"][1] * scale, a["V"][2])
    return saved


def restore(saved):
    ARCH.clear()
    ARCH.update(saved)


def option_table(C_neu):
    """Optionen zur Aufloesung des Widerspruchs, je Archetyp (Fall F1, Ziel Verarbeiter)."""
    rows = []
    # Option 0: Ist-Zustand hq.md + 1-4k x Stufe (Widerspruch)
    # Option A: Startkapital runter (C_neu), Preise bleiben
    # Option B: Kaufpreise x6, Startkapital bleibt (hq.md)
    # Option C: nichts aendern, nur den Satz streichen (= Option 0 als Spielregel)
    for name, scale, Cmap in (("0/C Ist: hq-Kapital, Preise 1-4k", 1, {k: a["C_hq"] for k, a in ARCH.items()}),
                              ("A Startkapital runter", 1, C_neu),
                              ("B Kaufpreise x6, hq-Kapital", 6, {k: a["C_hq"] for k, a in ARCH.items()})):
        saved = with_scale(scale) if scale != 1 else None
        for arch, a in ARCH.items():
            C = Cmap[arch]
            KV = a["V"][1]; LV = lic_price(KV); LR = lic_price(a["R"][1])
            S0 = startpaket(a)[3]
            kw = dict(C=10**6, horizon=300)
            rK = simulate(arch, "K0", target="V", **kw); rL = simulate(arch, "L", target="V", **kw)
            bec = breakeven_cash(rK, rL)
            Lr = simulate(arch, "L", target="V", C=C, horizon=60)
            K0 = simulate(arch, "K0", target="V", C=C, horizon=60)
            LKa = simulate(arch, "LKa", target="V", C=C, horizon=60)
            rate = Lr["rows"][59]["net"]
            rows.append(dict(Option=name, Archetyp=arch, Startkapital=C, K_V=KV, Lizenz_V=round(LV, 1),
                             Drei_Lizenzen=round(LR + 2 * LV, 1), Drei_Lizenzen_in_K_V=round((LR + 2 * LV) / KV, 3),
                             C_in_K_V=round(C / KV, 2), C_in_S0=round(C / S0, 1), C_in_min_Einkommen=round(C / max(rate, 1), 1),
                             Kauf_plus_Startpaket_bezahlbar=int(C >= KV + S0), Kauf_bei_min0=int(K0["bought_at"] == 0),
                             K0_t_Linie_voll=K0["t_full"] if K0["t_full"] else ">60", L_t_Linie_voll=Lr["t_full"] if Lr["t_full"] else ">60",
                             t_Kauf_bezahlbar_Casual=LKa["t_afford"] if LKa["t_afford"] is not None else ">60",
                             Break_even_Cash_Kauf_vs_Lizenz_min=bec if bec else ">300",
                             Ausbau_Stufe2_in_K_V=round(2000 / KV, 2)))
        if saved is not None:
            restore(saved)
    return rows


def main():
    tab = table_archetypes()
    write_csv("t05_archetypen_hq_ist.csv", tab)

    cases = run_cases()
    write_csv("t05_breakeven.csv", cases)

    rab = []
    for arch in ARCH:
        for firm in ("R", "V"):
            K = ARCH[arch][firm][1]
            L = lic_price(K)
            for n in (1, 2, 3):
                for rabatt in (True, False):
                    price = K * (1 - (BUY_DISC if rabatt else 0)) - CREDIT * n * L
                    total = n * L + price
                    rab.append(dict(Archetyp=arch, Firma=ARCH[arch][firm][0], K=K, Lizenz=round(L, 1), Perioden_n=n,
                                    Kaufrabatt20=int(rabatt), Kaufpreis_nach_Anrechnung=round(price),
                                    Gesamtausgabe=round(total), Anteil_vom_Direktkauf=round(total / K, 3)))
    write_csv("t05_rabatt_stapelung.csv", rab)

    C_neu, chk = derive_C_neu()
    write_csv("t05_startkapital_neu.csv", chk)
    hq = {k: a["C_hq"] for k, a in ARCH.items()}
    p_hq = pinch_table(hq, "hq.md (15-30k)")
    p_neu = pinch_table(C_neu, "neu")
    write_csv("t05_startkapital_pinch.csv", p_hq + p_neu)
    opt = option_table(C_neu)
    write_csv("t05_optionen.csv", opt)

    # Kapitalbegrenzte Break-even-Fenster bei C_neu fuer F1 (Kauf vs Lizenz mit Pinch)
    be_pinch = []
    for arch in ARCH:
        for tag, firm, ai, over, dem, desc in STARTFAELLE:
            a = ARCH[arch]
            kw = dict(C=C_neu[arch], horizon=120, ai=ai, ai_start=15, over=over, demand=(9.0 if dem is None else a["demand"] * dem))
            rK = simulate(arch, "K0", target=firm, **kw)
            rL = simulate(arch, "L", target=firm, **kw)
            be_pinch.append(dict(Archetyp=arch, Fall=tag, Startkapital=C_neu[arch],
                                 K0_Kauf_bei_min0=int(rK["bought_at"] == 0),
                                 Break_even_Cash_min=breakeven_cash(rK, rL) or ">120",
                                 Break_even_Netto_min=breakeven_nw(rK, rL) or ">120",
                                 NW_min10_Kauf=nw(rK, 10), NW_min10_Lizenz=nw(rL, 10),
                                 NW_min30_Kauf=nw(rK, 30), NW_min30_Lizenz=nw(rL, 30),
                                 NW_min60_Kauf=nw(rK, 60), NW_min60_Lizenz=nw(rL, 60)))
    write_csv("t05_breakeven_kapitalbegrenzt.csv", be_pinch)

    # Soft-Lock-Test: knappes Startkapital C = K_V + 0,6 x S0 (aufgerundet 500) -> Kauf-Route (Verarbeiter sofort kaufen)
    soft = []
    for arch, a in ARCH.items():
        S0 = startpaket(a)[3]
        Cx = math.ceil((a["V"][1] + 0.6 * S0) / 500.0) * 500
        r = simulate(arch, "K0", target="V", C=Cx, horizon=90)
        soft.append(dict(Archetyp=arch, Startkapital_knapp=Cx, Kauf_Verarbeiter_min0=int(r["bought_at"] == 0),
                         t_Linie_voll=r["t_full"] if r["t_full"] else ">90", Bargeld_min10=r["rows"][9]["cash"],
                         Bargeld_min60=r["rows"][59]["cash"], Bargeld_min90=r["rows"][89]["cash"],
                         Einnahme_stufe2_ab_min=r["t_rev2"] if r["t_rev2"] else "nie"))
    write_csv("t05_softlock_test.csv", soft)
    return tab, cases, rab, chk, p_hq, p_neu, be_pinch, opt


if __name__ == "__main__":
    tab, cases, rab, chk, p_hq, p_neu, bp, opt = main()
    print("== Startkapital neu"); [print(r) for r in chk]
    print("== Break-even unbegrenzt"); [print(r['Archetyp'], r['Fall'], r['Firma'], 'K', r['Kaufpreis'], 'dRate', r['Mehrertrag_Besitz_pro_min'], 'BEc', r['Break_even_Cash_min'], r['Break_even_Cash_analytisch_min'], 'BEn', r['Break_even_Netto_min'], r['Urteil_Schwelle_30min']) for r in cases]
    print("== pinch"); [print({k: v for k, v in r.items()}) for r in p_hq + p_neu]
    print("== be pinch"); [print(r) for r in bp]
    print("== optionen"); [print(r) for r in opt]
