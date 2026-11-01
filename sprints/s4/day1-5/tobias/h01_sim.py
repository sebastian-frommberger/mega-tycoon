#!/usr/bin/env python3
"""H-01 Headless-Balancing-Sim Vertical Slice (Tobias Brandt, Sprint 4). Ausgang: t11_modell.py (Sprint 3), Aenderungen:
 (1) Kredit aus der JSON (credit_active_in_slice_flag, S5): ohne Kredit ist Konto < 0 = Bankrott; Modus mods["kredit_an"] zum Vergleich.
 (2) L-10: Wachstum G nur aus Nahrung (slice_build_category_active_flag = false); Modus mods["l10"]=False rechnet die alte Regel (Bau = 0).
 (3) Lange Laeufe (horizon) und Stadtgroesse je Minute fuer die Dauer Kleinstadt -> Stadt; Modus mods["versorgt"] isoliert die Regel
     (Nahrungsversorgung 100 %), mods["bonus_promille"] simuliert den Wachstumszuschlag (0 bis 250).
 (4) Absturzzaehlung je Lauf, Determinismus-Pruefung (gleicher Seed, gleiches Ergebnis) in h01_main().
Liest NUR t06/data/economy_slice.json und vehicles.json. Ganzzahl-Festkomma wie die Konvention. Keine Spielerdaten: alles
Modellrechnung, Spielerverhalten (Typen, Fehler, Bauverzoegerung) sind Setzungen (ANNAHME) wie in T-11.
Lauf: python3 -I h01_sim.py  -> schreibt h01_*.csv und h01_log.txt neben das Skript."""
import csv, json, math, os, random, statistics, sys

HERE = os.path.dirname(os.path.abspath(__file__))
E = json.load(open(os.path.join(HERE, "t06", "data", "economy_slice.json"), encoding="utf-8"))
V = json.load(open(os.path.join(HERE, "t06", "data", "vehicles.json"), encoding="utf-8"))
LKW = next(v for v in V["fahrzeuge"] if v["id"] == E["fahrzeug_ref"]["lkw_id"])
PER = E["zeit"]["periode_ticks"]
HORIZON = 60          # Minuten; Kennzahl Bankrott und Gewinn werden bei 30 gelesen
SPEED_FELDER_S = LKW["tempo_mm_pro_tick"] * 10 / 1000      # 600 mm/Tick = 6 Felder/s
LOAD_S = E["fahrzeug_ref"]["load_ticks"] / 10               # 10 s
PRICE = {g["id"]: E["preise"][g["preis_ref_id"] + "_cent_pro_einheit_feld"] for g in E["gueter"]}
ZK = {g["id"]: g["zeitklasse_modus"] for g in E["gueter"]}
IND = {i["id"]: i for i in E["industrien"]}


def rdiv(z, n):
    q, r = divmod(abs(z), n)
    if 2 * r >= n:
        q += 1
    return q if z >= 0 else -q


def d_eff_x1000(d, rules=True):
    ee = E["ertrag"]
    if rules and d < ee["dist_min_felder"]:
        return 0
    if d <= ee["dist_knee_felder"]:
        return d * 1000
    return ee["dist_knee_felder"] * 1000 + ee["dist_slope_beyond_promille"] * (d - ee["dist_knee_felder"])


def f_zeit_promille(good, age_s):
    z = E["zeitfaktor"]
    kl = "fresh" if ZK[good] == "frisch" else "bulk"
    grace, decay = z[kl + "_grace_ticks"] / 10, z[kl + "_decay_ticks"] / 10
    fmin = z["f_time_min_promille"]
    if age_s <= grace:
        return 1000
    if age_s >= grace + decay:
        return fmin
    return 1000 - rdiv((1000 - fmin) * int((age_s - grace) * 1000), int(decay * 1000))


def f_saett_promille(s_promille):
    s = E["saettigung"]
    if s_promille <= s["sat_full_until_promille"]:
        return 1000
    if s_promille <= s["sat_knee_promille"]:
        return 1000 - rdiv((1000 - s["sat_floor_at_150_promille"]) * (s_promille - s["sat_full_until_promille"]),
                           s["sat_knee_promille"] - s["sat_full_until_promille"])
    return s["sat_over_150_promille"]


def ertrag_cent(m, good, d, fz, fs, rules=True, bonus=0):
    """E = M x P x D_eff x F_zeit x F_saett x (1+B_skill), eine Division am Ende (Konvention)."""
    return rdiv(m * PRICE[good] * d_eff_x1000(d, rules) * fz * fs * (1000 + bonus), 10 ** 12)


def truck_cap_pm(road_len):
    cycle = 2 * road_len / SPEED_FELDER_S + LOAD_S
    return LKW["kapazitaet_einheiten"] * 60.0 / cycle


# ---------------------------------------------------------------------------------- Welten (aus ketten[] im JSON)
def edges(chain):
    return {(k["von_id"], k["nach_id"]): k for c in E["ketten"] if c["id"] == chain for k in c["kanten"]}


def world(arch, rng, p):
    """Linien eines Archetyps mit Streckenvariation (+-25 %, ANNAHME Kartenzufall)."""
    def dd(base):
        return max(E["ertrag"]["dist_min_felder"] + 2, round(base * (0.75 + 0.5 * rng.random())))
    if arch == "agrar":
        k1 = edges("k1")
        return dict(arch=arch, lizenz=["getreidefarm", "muehle"], proc="muehle",
                    in_lines=[dict(id="farm_a", src="getreidefarm", good="getreide", d=dd(k1[("getreidefarm", "muehle")]["strecke_felder"]))],
                    out=dict(good="mehl", d=dd(k1[("muehle", "kleinstadt_a")]["strecke_felder"]), kind="stadt", demand0=25),
                    extra_src=dict(id="farm_b", src="getreidefarm_b", good="getreide", d=dd(22), price_cent=IND["getreidefarm"]["kaufpreis_stufe1_cent"]))
    k3 = edges("k3")
    return dict(arch=arch, lizenz=["erzmine", "kohlemine", "stahlwerk"], proc="stahlwerk",
                in_lines=[dict(id="erz", src="erzmine", good="erz", d=dd(k3[("erzmine", "stahlwerk")]["strecke_felder"])),
                          dict(id="kohle", src="kohlemine", good="kohle", d=dd(k3[("kohlemine", "stahlwerk")]["strecke_felder"]))],
                out=dict(good="stahl", d=dd(k3[("stahlwerk", "werkzeugfabrik")]["strecke_felder"]), kind="abnehmer",
                         cap=IND["werkzeugfabrik"]["abnahme_max_einheiten_pro_periode"]),
                k2=dict(d=dd(edges("k2")[("kohlemine", "kraftwerk")]["strecke_felder"]), cap=IND["kraftwerk"]["abnahme_max_einheiten_pro_periode"]))


# ---------------------------------------------------------------------------------- Spielertypen (ANNAHME)
PTYPES = [("sorgfaeltig", 0.40, (1, 2), (1.00, 1.15), (0, 0), 0.0),
          ("normal", 0.40, (2, 4), (1.10, 1.35), (0, 1), 0.0),
          ("hastig", 0.20, (3, 6), (1.20, 1.60), (1, 2), 0.5)]    # Name, Anteil, Bauverzoegerung min, Wegfaktor, Extra-Lkw, P(Fehlverbindung)


def draw_player(rng, force=None, mix=None):
    r = rng.random()
    acc = 0.0
    shares = mix or [t[1] for t in PTYPES]
    for t, sh in zip(PTYPES, shares):
        acc += sh
        if r < acc or t is PTYPES[-1]:
            if force:
                t = next(x for x in PTYPES if x[0] == force)
            name, _, bd, wf, ex, pb = t
            return dict(name=name, delay=rng.randint(*bd), detour=wf[0] + (wf[1] - wf[0]) * rng.random(),
                        extra=rng.randint(*ex), blunder=(rng.random() < pb),
                        blunder_len=rng.randint(3, 8), k2_share=rng.choice([0, 0, 250, 500]))


# ---------------------------------------------------------------------------------- Lauf
def simulate(seed, arch, strat, force_ptype=None, exploit=None, rules=True, mods=None, horizon=HORIZON):
    mods = mods or {}
    rng = random.Random(seed)
    p = draw_player(rng, force_ptype, mods.get("mix"))
    if mods.get("kredit_hebel"):
        p["extra"] += 3            # Rahmen voll ziehen: drei Lkw mehr je Linie
    w = world(arch, rng, p)
    cap0 = E["hq"]["start_capital_agrar_cent" if arch == "agrar" else "start_capital_mining_cent"]
    cap0 = int(cap0 * mods.get("kapital", 1.0))
    credit = E["kredit"]["credit_limit_cent"] if mods.get("kredit_an", E["kredit"]["credit_active_in_slice_flag"]) else 0
    zins_pm = E["kredit"]["credit_interest_promille_pro_periode"]
    truck_fix = int(LKW["fix_cent_pro_periode"] * mods.get("lkw_fix", 1.0))
    price_scale = mods.get("preis", 1.0)
    road_cpf = E["fahrzeug_ref"]["strasse_cent_pro_feld"]
    liz_share, liz_disc = E["lizenz"]["licence_cost_share_promille"], E["lizenz"]["licence_discount_in_radius_promille"]
    cash = cap0
    invest = 0          # Strasse + Lkw + Lager (Anlagen)
    paid_firms = 0      # gezahlte Kaufpreise
    own, licensed, fees, level = {}, {}, {}, {}
    free_used = False
    lines_built, trucks = False, {}
    hub = False
    k2_on = False
    bought_n, upgraded = 0, False
    t_first, t_buy, t_bank, t_soft = None, None, None, None
    soft_run = 0
    kredit_max = 0
    zins_sum = 0
    discount_pending = False
    log = []
    pop = mods.get("pop0", next(c["einwohner_anzahl"] for c in E["staedte"] if c["id"] == "kleinstadt_a"))
    t_pop4750 = t_pop5000 = None
    t_growth0 = None
    l10 = mods.get("l10", not E["wachstum"]["slice_build_category_active_flag"])
    mehl_ratio_hist = []
    detected_blunder = p["blunder"]
    blunder_until = None
    rebuilt = False
    exploit_gain = 0

    def avail():
        return cash + credit

    def price(f):
        return IND[f]["kaufpreis_stufe1_cent"]

    def lic_cost(f):
        return rdiv(price(f) * liz_share * (1000 - liz_disc), 10 ** 6)

    def pay_licence(f, renew=False):
        nonlocal cash, free_used
        c = lic_cost(f)
        if not renew and not free_used and f != w["proc"]:
            free_used = True
            c = 0
        if avail() >= c:
            cash -= c
            fees[f] = fees.get(f, 0) + c
            licensed[f] = True
            return True
        return False

    lic_expire = {}
    for t in range(horizon):
        # ---- A) Entscheidungen zu Beginn der Minute
        if t == 0:
            for f in w["lizenz"]:
                if pay_licence(f):
                    lic_expire[f] = t + E["lizenz"]["licence_duration_ticks"] // PER
        if exploit == "x04_lizenz_hopping" and t == 40:
            for f in list(w["lizenz"]):
                if not own.get(f):
                    licensed[f] = False        # Lagerbestand (200 E) ist aufgebraucht, Laden ohne Lizenz nicht moeglich
        if t > 0 and t % (E["lizenz"]["licence_duration_ticks"] // PER) == 0 and E["lizenz"]["licence_auto_renew_flag"] and exploit != "x04_lizenz_hopping":
            for f in list(w["lizenz"]):
                if licensed.get(f) and not own.get(f):
                    if not pay_licence(f, renew=True):
                        licensed[f] = False        # nicht bezahlbar: Lizenz laeuft aus
        # Bau: Strasse + Lkw (aus Guthaben + Kreditrahmen erlaubt)
        if not lines_built and t >= p["delay"]:
            lens = [l["d"] for l in w["in_lines"]] + [w["out"]["d"]]
            road = sum(round(d * p["detour"]) for d in lens) * road_cpf * mods.get("strasse", 1.0)
            need = {}
            for l in w["in_lines"]:
                rl = round(l["d"] * p["detour"])
                need[l["id"]] = max(1, math.ceil(20 / truck_cap_pm(rl))) + p["extra"]
            rl = round(w["out"]["d"] * p["detour"])
            need["out"] = max(1, math.ceil(20 / truck_cap_pm(rl))) + p["extra"]
            cost = int(road) + sum(need.values()) * LKW["kauf_cent"]
            if avail() >= cost:
                cash -= cost
                invest += cost
                trucks = need
                lines_built = True
                t_build = t
        op = lines_built
        # Fehlverbindung (hastig): Abnehmer zu nah (d<6), Ertrag 0, bis Fehler erkannt, dann neue Strasse
        if op and detected_blunder and blunder_until is None:
            blunder_until = t + p["blunder_len"]
        if op and blunder_until is not None and t == blunder_until and not rebuilt:
            c = int(round(w["out"]["d"] * p["detour"]) * road_cpf)
            cash -= c
            invest += c
            rebuilt = True
        blunder_active = op and detected_blunder and not rebuilt
        # Kauf / Hub / Ausbau je Strategie
        kauf_frei = t_first is not None            # Kauf-Angebot, sobald die Kette liefert (M3), nur aus Guthaben
        proc = w["proc"]
        if strat in ("direktkauf", "lager_hub") and op:
            if strat == "lager_hub" and not hub:
                hub_cost = E["lager"]["warehouse_cost_cent"]
                if arch == "agrar" and "getreidefarm_b" not in licensed:
                    extra_need = hub_cost + lic_cost("getreidefarm") + 2 * 12 * road_cpf + 2 * LKW["kauf_cent"]
                    if avail() >= extra_need + 2000:
                        cash -= extra_need
                        invest += extra_need
                        licensed["getreidefarm_b"] = True
                        fees["getreidefarm_b"] = lic_cost("getreidefarm")
                        hub = True
                elif arch == "bergbau" and avail() >= hub_cost + 2 * 12 * road_cpf + LKW["kauf_cent"]:
                    c = hub_cost + 2 * 12 * road_cpf + LKW["kauf_cent"]
                    cash -= c
                    invest += c
                    hub = True
            if kauf_frei and not own.get(proc) and (strat == "direktkauf" or hub):
                net = price(proc) - rdiv(E["kauf"]["buy_licence_credit_share_promille"] * fees.get(proc, 0), 1000)
                if cash >= net:
                    cash -= net
                    paid_firms += net
                    own[proc] = True
                    level[proc] = 1
                    bought_n += 1
                    t_buy = t
                    discount_pending = True      # M5b: naechster Kauf -20 %, einmalig
            if own.get(proc) and not upgraded and level[proc] == 1:
                up = E["fabrik"]["factory_upgrade_cost_l2_cent"]
                if cash >= up and (strat == "lager_hub" and hub or mods.get("upgrade_always")):
                    cash -= up
                    paid_firms += up
                    level[proc] = 2
                    upgraded = True
        # K2 (Kohle teilt sich), nur Bergbau, nach Min 8, wenn Geld da
        if arch == "bergbau" and not k2_on and op and t >= 8 and p["k2_share"] > 0:
            c = round(w["k2"]["d"] * p["detour"]) * road_cpf + LKW["kauf_cent"]
            if cash > c + 100000:
                cash -= c
                invest += c
                k2_on = True
                trucks["k2"] = 1
        # Exploit-Aktionen (Anlagen kosten Geld)
        if exploit and op and t == p["delay"] + 1 and exploit in ("x01_lager_pingpong", "x02_umweg", "x07_kurzstrecken_spam", "x08_zwei_staedte", "x03_stempel_reset"):
            c = 2 * E["lager"]["warehouse_cost_cent"] + 4 * LKW["kauf_cent"] + 60 * road_cpf if exploit == "x01_lager_pingpong" else 2 * LKW["kauf_cent"] + 120 * road_cpf
            if exploit == "x08_zwei_staedte":
                c = 2 * LKW["kauf_cent"] + 30 * road_cpf
            if exploit == "x07_kurzstrecken_spam":
                c = 6 * LKW["kauf_cent"] + 24 * road_cpf
            if exploit == "x03_stempel_reset":
                c = E["lager"]["warehouse_cost_cent"] + LKW["kauf_cent"] + 10 * road_cpf
            cash -= c
            invest += c

        # ---- B) Fluss und Ertrag der Minute (nur wenn Linien stehen und Lizenz da)
        rev = 0
        trips_fields = 0
        if op and t >= p["delay"] + 1:
            mult = 1000
            cons = {}
            for l in w["in_lines"]:
                f = l["src"]
                ok = licensed.get(f) or own.get(f)
                prod = 20 if ok else 0
                if arch == "bergbau" and l["id"] == "kohle" and k2_on:
                    prod_k3 = prod * (1000 - p["k2_share"]) // 1000
                else:
                    prod_k3 = prod
                rl = round(l["d"] * p["detour"])
                cap = int(trucks.get(l["id"], 0) * truck_cap_pm(rl))
                cons[l["id"]] = min(prod_k3, cap)
            if hub:
                # zweite Quelle ueber Lager (Agrar: Farm B; Bergbau: beide Quellen laufen ueber das Lager)
                if arch == "agrar":
                    cons["farm_b"] = 20 if licensed.get("getreidefarm_b") else 0
                # Rampen: 2 x 2 E/s = 240 E/min je Richtung, nie der Engpass
            proc_in = sum(cons.values()) if arch == "agrar" else min(cons.get("erz", 0), cons.get("kohle", 0))
            lvl_cap = E["fabrik"]["factory_throughput_l%d_einheiten_pro_periode" % level.get(proc, 1)] if own.get(proc) else E["fabrik"]["factory_throughput_l1_einheiten_pro_periode"]
            proc_in = min(proc_in, lvl_cap)
            # Ertrag fuer Rohstoffe beim Verarbeiter (Eingangsgut), Herkunftsstempel: Luftlinie Quelle -> Verarbeiter
            if arch == "agrar":
                share = {k: v for k, v in cons.items()}
                scale = proc_in / max(1, sum(share.values()))
                for l in w["in_lines"] + ([w["extra_src"]] if hub else []):
                    m = int(share.get(l["id"], 0) * scale)
                    age = 5 + (60 if hub else 0)
                    r = ertrag_cent(m, l["good"], l["d"], f_zeit_promille(l["good"], age), 1000, rules)
                    rev += rdiv(r * price_scale * 1000, 1000)
                    trips_fields += 2 * round(l["d"] * p["detour"]) * m / LKW["kapazitaet_einheiten"]
            else:
                for l in w["in_lines"]:
                    m = proc_in if l["id"] in ("erz",) else proc_in
                    r = ertrag_cent(m, l["good"], l["d"], f_zeit_promille(l["good"], 5 + (60 if hub else 0)), 1000, rules)
                    rev += int(r * price_scale)
                    trips_fields += 2 * round(l["d"] * p["detour"]) * m / LKW["kapazitaet_einheiten"]
            if own.get(proc):
                rev += rdiv(rev * E["kauf"]["works_margin_promille"], 1000)       # Werksmarge, Lesart t05
            # Abfluss
            out = w["out"]
            rl = round(out["d"] * p["detour"])
            cap = int(trucks.get("out", 0) * truck_cap_pm(rl))
            m_out = min(proc_in, cap)
            if out["kind"] == "abnehmer":
                m_out = min(m_out, out["cap"])
            age = 20 + rl / SPEED_FELDER_S + (60 if hub else 0)
            if exploit == "x03_stempel_reset":
                age = 20 + rl / SPEED_FELDER_S + 400      # Gut liegt im Lager, Spieler will durch Umladen neu stempeln
            dem = max(1, pop // 100) if out["kind"] == "stadt" else 1
            dlist = [(out["d"], m_out, dem)]
            if exploit == "x08_zwei_staedte" and out["kind"] == "stadt":
                m1 = min(m_out, dem)
                dlist = [(out["d"], m1, dem), (max(E["ertrag"]["dist_min_felder"], 30), m_out - m1, 9)]
            if exploit == "x07_kurzstrecken_spam":
                dlist = [(out["d"], m_out - 6, dem), (5, 6, dem)]
            if blunder_active and out["kind"] == "stadt":
                dlist = [(4, m_out, dem)]
            if blunder_active and out["kind"] != "stadt":
                dlist = [(4, m_out, 1)]
            for d, m, dm in dlist:
                s_prom = rdiv(m * 1000, dm) if out["kind"] == "stadt" else 0
                fs = f_saett_promille(s_prom) if out["kind"] == "stadt" else 1000
                fz = f_zeit_promille(out["good"], age)
                if exploit == "x03_stempel_reset" and not rules:
                    fz = f_zeit_promille(out["good"], 25)
                r = ertrag_cent(m, out["good"], d, fz, fs, rules)
                rev += int(r * price_scale)
                trips_fields += 2 * rl * m / LKW["kapazitaet_einheiten"]
                if m > 0 and t_first is None and r > 0:
                    t_first = t + 1
            # Stadtwachstum Variante B (nur Kleinstadt A, Agrar), G = Mittel der Kategorien, Bau nicht versorgt
            if arch == "agrar":
                nahrung = 1000 if mods.get("versorgt") else min(1000, rdiv(m_out * 1000, dem))
                G = nahrung if l10 else (nahrung + 0) // 2     # L-10: nur Nahrung; alt: Nahrung + Bau, Bau 0 (kein Holz im Slice)
                if t_growth0 is None:
                    t_growth0 = t + 1
                g_ = E["wachstum"]
                if G >= g_["growth_band_hi_promille"]:
                    rate = g_["growth_base_rate_bp_pro_monat"]
                elif G >= g_["growth_band_mid_promille"]:
                    rate = g_["growth_base_rate_bp_pro_monat"] * g_["growth_mid_factor_promille"] // 1000
                elif G >= g_["growth_band_low_promille"]:
                    rate = 0
                else:
                    rate = g_["growth_base_rate_bp_pro_monat"] * g_["growth_neg_factor_promille_signed"] // 1000
                if rate > 0 and G >= g_["growth_band_mid_promille"]:
                    rate = rate * (1000 + mods.get("bonus_promille", 0)) // 1000      # Zuschlag nur bei positivem Band
                pop = pop + rdiv(pop * rate, 10000)
                if t_pop4750 is None and pop >= 4750:
                    t_pop4750 = t + 1
                if t_pop5000 is None and pop >= E["wachstum"]["stage_threshold_stadt_anzahl"]:
                    t_pop5000 = t + 1
            # K2: Kohle zum Kraftwerk, Energiebonus (nur Menge) auf K3-Rohstoffe, Deckel x1,6
            if k2_on:
                m2 = min(20 * p["k2_share"] // 1000, w["k2"]["cap"])
                r = ertrag_cent(m2, "kohle", w["k2"]["d"], 1000, 1000, rules)
                rev += int(r * price_scale)
                trips_fields += 2 * round(w["k2"]["d"] * p["detour"]) * m2 / LKW["kapazitaet_einheiten"]
        if exploit == "x01_lager_pingpong" and op and t >= p["delay"] + 1:
            # Pendeln zwischen zwei Lagern, 60 Felder Luftlinie; Ertrag nur beim Endabnehmer (Regel) -> 0; ohne Regel: Distanz je Fahrt
            m = 20
            r = ertrag_cent(m, "getreide", 60, 1000, 1000, True) if not rules else 0
            rev += r
            trips_fields += 2 * 60 * m / LKW["kapazitaet_einheiten"]
        if exploit == "x02_umweg" and op and t >= p["delay"] + 1:
            # 120 Felder Rundweg statt 18 Luftlinie: Regel wertet Luftlinie (kein Mehrertrag), ohne Regel Wegstrecke
            m = 20
            d_pay = 120 if not rules else 18
            rev += ertrag_cent(m, "getreide", d_pay, 1000, 1000, True) - ertrag_cent(m, "getreide", 18, 1000, 1000, True)
            trips_fields += 2 * 120 * m / LKW["kapazitaet_einheiten"]

        # ---- C) Kosten
        n_trucks = sum(trucks.values()) if op else 0
        costs = n_trucks * truck_fix + int(LKW["variabel_cent_pro_feld"] * trips_fields)
        costs += sum(E["kauf"]["company_upkeep_per_level_cent_pro_periode"] * level.get(f, 1) for f in own if own[f])
        costs += E["lager"]["warehouse_upkeep_cent_pro_periode"] * (1 if hub else 0)
        z = rdiv(max(0, -cash) * zins_pm, 1000)
        zins_sum += z
        cash_open = cash
        cash += rev - costs - z
        net = rev - costs - z
        if cash < 0:
            kredit_max = max(kredit_max, -cash)
        # Bankrott: Konto unter -Rahmen (zahlungsunfaehig) oder 5 Minuten Konto<0 bei Netto<=0 (Soft-Lock)
        if cash < -credit and t_bank is None:
            t_bank = t + 1
        if cash < 0 and net <= 0:
            soft_run += 1
            if soft_run >= 5 and t_soft is None:
                t_soft = t + 1
        else:
            soft_run = 0
        fw = rdiv(600 * paid_firms, 1000)       # firmenwert_invest_promille aus economy_constants.json (600)
        nw = cash + fw + invest // 2
        log.append(dict(t=t + 1, cash=cash, net=net, nw=nw, rev=rev))
    r30 = log[29]
    bank30 = (t_bank is not None and t_bank <= 30) or (t_soft is not None and t_soft <= 30)
    bank60 = t_bank is not None or t_soft is not None
    return dict(seed=seed, archetyp=arch, strategie=strat, spieler=p["name"], bauverzoegerung_min=p["delay"],
                wegfaktor=round(p["detour"], 2), extra_lkw=p["extra"], fehlverbindung=int(p["blunder"]),
                k2_anteil_promille=p["k2_share"] if arch == "bergbau" else 0,
                bankrott_min30=int(bank30), bankrott_min60=int(bank60), t_zahlungsunfaehig=t_bank or "", t_softlock=t_soft or "",
                konto_min30_usd=round(r30["cash"] / 100), reinverm_min30_usd=round(r30["nw"] / 100),
                gewinn_min30_usd=round((r30["nw"] - cap0) / 100), gewinn_min60_usd=round((log[59]["nw"] - cap0) / 100),
                kredit_max_usd=round(kredit_max / 100), zinsen_usd=round(zins_sum / 100), t_erste_lieferung_min=t_first or "",
                t_kauf_min=t_buy if t_buy is not None else "", hub=int(hub), stufe2=int(upgraded), gebaut=int(lines_built),
                einwohner_ende=pop if arch == "agrar" else "",
                dauer_bis_4750_min=(t_pop4750 - t_growth0 + 1) if (t_pop4750 and t_growth0) else "",
                dauer_bis_5000_min=(t_pop5000 - t_growth0 + 1) if (t_pop5000 and t_growth0) else "")


STRATS = ["lizenz", "direktkauf", "lager_hub"]


def standard_laeufe(n=100, mods=None, rules=True):
    rows = []
    for s in range(1, n + 1):
        arch = "agrar" if s % 2 == 1 else "bergbau"
        strat = STRATS[((s - 1) // 2) % 3]
        rows.append(simulate(s, arch, strat, mods=mods, rules=rules))
    return rows


def write_csv(name, rows):
    with open(os.path.join(HERE, name), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()), delimiter=";")
        w.writeheader()
        w.writerows(rows)


EXPLOITS = [("x01_lager_pingpong", "Lager-Pingpong: Ware zwischen zwei Lagern (60 Felder) pendeln, Distanz abgreifen", ["agrar"]),
            ("x02_umweg", "Umweg: 120-Felder-Rundweg statt 18 Felder Luftlinie", ["agrar"]),
            ("x03_stempel_reset", "Stempel-Reset: gealtertes Mehl umladen, um F_zeit zurueckzusetzen", ["agrar"]),
            ("x04_lizenz_hopping", "Lizenz-Hopping: Lizenz nach Ablauf nicht verlaengern, Bestand weiterfahren", ["agrar", "bergbau"]),
            ("x05_kauf_verkauf", "Kauf-Verkauf-Zyklus: Firma kaufen (Rabatt, Anrechnung), zu 70 % Firmenwert verkaufen", ["agrar", "bergbau"]),
            ("x06_kredit_hebel", "Kredit-Hebel: Rahmen voll ziehen und in Lkw und Strasse stecken", ["agrar", "bergbau"]),
            ("x07_kurzstrecken_spam", "Kurzstrecken-Spam: viele 5-Felder-Lieferungen", ["agrar"]),
            ("x08_zwei_staedte", "Saettigung umgehen: Mehl auf zwei Staedte verteilen (je Stadt unter 100 %)", ["agrar"])]


def x05_cycle(arch):
    """Reine Rechnung je Zyklus (Ganzzahl): Kauf des Verarbeiters, Verkauf nach Firmenwertregel. Kein Zeitlauf noetig."""
    proc = "muehle" if arch == "agrar" else "stahlwerk"
    K = IND[proc]["kaufpreis_stufe1_cent"]
    fees = rdiv(K * E["lizenz"]["licence_cost_share_promille"] * (1000 - E["lizenz"]["licence_discount_in_radius_promille"]), 10 ** 6)
    paid1 = K - rdiv(E["kauf"]["buy_licence_credit_share_promille"] * fees, 1000)           # erster Kauf, kein Rabatt
    paid2 = rdiv(K * (1000 - E["kauf"]["buy_discount_first_promille"]), 1000) - rdiv(E["kauf"]["buy_licence_credit_share_promille"] * fees, 1000)  # zweiter Kauf mit einmaligem Rabatt
    value = lambda paid: rdiv(600 * paid, 1000)       # firmenwert_invest_promille (constants) , Ueberschuss 0 im Modell
    sell = lambda paid: rdiv(700 * value(paid), 1000)  # verkauf_anteil_firmenwert_promille
    return dict(archetyp=arch, kauf1_usd=paid1 / 100, verkauf1_usd=sell(paid1) / 100, netto1_usd=(sell(paid1) - paid1) / 100,
                kauf2_mit_rabatt_usd=paid2 / 100, verkauf2_usd=sell(paid2) / 100, netto2_usd=(sell(paid2) - paid2) / 100)


def exploit_laeufe(ref, ref60):
    rows = []
    for code, text, archs in EXPLOITS:
        for arch in archs:
            if code in ("x05_kauf_verkauf",):
                c = x05_cycle(arch)
                rows.append(dict(exploit=code, archetyp=arch, beschreibung=text, regeln="an", n=1, gewinn_median_usd=round(c["netto1_usd"]),
                                 referenz_usd=ref[arch], verhaeltnis=round(c["netto1_usd"] / ref[arch], 2), bemerkung=f"je Zyklus netto {c['netto1_usd']:.0f} $ (2. Kauf mit Rabatt {c['netto2_usd']:.0f} $)"))
                continue
            for rules in (True, False):
                if code in ("x04_lizenz_hopping", "x06_kredit_hebel", "x07_kurzstrecken_spam", "x08_zwei_staedte") and not rules:
                    continue
                res = []
                for s in range(1001, 1011):
                    strat = "lager_hub" if code == "x08_zwei_staedte" else "lizenz"
                    res.append(simulate(s, arch, strat, force_ptype="sorgfaeltig", exploit=code, rules=rules,
                                        mods={"kredit_hebel": True} if code == "x06_kredit_hebel" else None))
                if code == "x04_lizenz_hopping":
                    g = statistics.median(r["gewinn_min60_usd"] for r in res)
                    rf, bem = ref60[arch], "Vergleich bei Minute 60 (Lizenz laeuft bei 30 aus)"
                else:
                    g = statistics.median(r["gewinn_min30_usd"] for r in res)
                    rf, bem = ref[arch], ""
                rows.append(dict(exploit=code, archetyp=arch, beschreibung=text, regeln="an" if rules else "AUS (Gegenprobe)", n=len(res),
                                 gewinn_median_usd=round(g), referenz_usd=rf, verhaeltnis=round(g / rf, 2), bemerkung=bem))
    return rows


def kalibrierung():
    rows = []
    varianten = [("Basis (JSON unveraendert)", {}),
                 ("Lkw-Fixkosten x3", {"lkw_fix": 3.0}), ("Lkw-Fixkosten x6", {"lkw_fix": 6.0}),
                 ("Ertragspreise x0,5", {"preis": 0.5}), ("Ertragspreise x0,25", {"preis": 0.25}),
                 ("Strasse x5 (50 $/Feld)", {"strasse": 5.0}),
                 ("Startkapital x0,6", {"kapital": 0.6}),
                 ("Preise x0,5 und Kapital x0,6", {"preis": 0.5, "kapital": 0.6}),
                 ("Lkw-Fixkosten x3 und Strasse x3", {"lkw_fix": 3.0, "strasse": 3.0}),
                 ("Spielermix 50 % hastig (Basis 20 %)", {"mix": [0.20, 0.30, 0.50]}),
                 ("Spielermix nur sorgfaeltig", {"mix": [1.0, 0.0, 0.0]})]
    for name, mods in varianten:
        rr = standard_laeufe(100, mods=mods)
        b = sum(r["bankrott_min30"] for r in rr)
        rows.append(dict(variante=name, bankrott_min30_prozent=b, median_gewinn_min30_usd=round(statistics.median(r["gewinn_min30_usd"] for r in rr))))
    return rows


# ====================================================================================================== H-01
import hashlib, io

CRASHES = []


def laeufe(n=100, mods=None, horizon=HORIZON, archs=None, seed0=0):
    """Seeds 1..n wie T-11: ungerade Agrar, gerade Bergbau; Strategie rotiert. Jeder Absturz wird gezaehlt, nicht verschluckt."""
    rows = []
    for s in range(seed0 + 1, seed0 + n + 1):
        arch = "agrar" if s % 2 == 1 else "bergbau"
        if archs and arch not in archs:
            continue
        strat = STRATS[((s - 1) // 2) % 3]
        try:
            rows.append(simulate(s, arch, strat, mods=mods, horizon=horizon))
        except Exception as ex:      # noqa: BLE001 - Absturz zaehlt als Befund
            CRASHES.append((s, repr(ex)))
    return rows


def csv_text(rows):
    b = io.StringIO()
    w = csv.DictWriter(b, fieldnames=list(rows[0].keys()), delimiter=";", lineterminator="\n")
    w.writeheader()
    w.writerows(rows)
    return b.getvalue()


def write_text(name, text):
    with open(os.path.join(HERE, name), "w", encoding="utf-8", newline="") as f:
        f.write(text)


def bank_pct(rows):
    return round(100 * sum(r["bankrott_min30"] for r in rows) / len(rows), 1)


def med(rows, key):
    return round(statistics.median(r[key] for r in rows))


def h01_main():
    out = []
    P = lambda *a: out.append(" ".join(str(x) for x in a))
    credit_flag = E["kredit"]["credit_active_in_slice_flag"]
    P("H-01 Lauf. JSON: Kredit im Slice", "an" if credit_flag else "AUS", "| Bau-Kategorie aktiv:", E["wachstum"]["slice_build_category_active_flag"],
      "| Tor-Gut:", E["wachstum"]["gate_unlock_good_id"])

    # 0) Treue-Check gegen T-11: Kredit an, alte Wachstumsregel -> Bankrott 7 % laut Sprint 3
    r0 = laeufe(100, mods={"kredit_an": True, "l10": False})
    P(f"[0] Treue-Check T-11 (Kredit an, alte Regel): Bankrott {bank_pct(r0)} % (Sprint 3: 7 %), Median Gewinn Min 30 {med(r0, 'gewinn_min30_usd')} $ (Sprint 3: 15.850 $)")

    # 1) Basis Sprint 4: Kredit aus (JSON), L-10
    base = laeufe(100)
    write_text("h01_laeufe_basis.csv", csv_text(base))
    nb = sum(1 for r in base if not r["gebaut"])
    P(f"[1] Basis S4 (Kredit aus, L-10): Bankrott Min 30 {bank_pct(base)} % ({sum(r['bankrott_min30'] for r in base)}/100), Bankrott Min 60 "
      f"{round(100 * sum(r['bankrott_min60'] for r in base) / 100)} %, nie gebaut {nb}, Median Gewinn Min 30 {med(base, 'gewinn_min30_usd')} $, "
      f"Median erste Lieferung {statistics.median([r['t_erste_lieferung_min'] for r in base if r['t_erste_lieferung_min'] != '']):.0f} min")
    for arch in ("agrar", "bergbau"):
        rr = [r for r in base if r["archetyp"] == arch]
        P(f"    {arch}: Bankrott {bank_pct(rr)} % (n={len(rr)}), Median Gewinn Min 30 {med(rr, 'gewinn_min30_usd')} $")
    for t_ in ("sorgfaeltig", "normal", "hastig"):
        rr = [r for r in base if r["spieler"] == t_]
        P(f"    Spieler {t_}: n={len(rr)}, Bankrott {bank_pct(rr)} %, nie gebaut {sum(1 for r in rr if not r['gebaut'])}")

    # 1b) Robustheit: andere Seed-Bloecke (Ziel gilt fuer Seeds 1-100; hier nur Streuung des Messwerts)
    P("[1b] Streuung der Bankrottrate ueber weitere Seed-Bloecke (Kredit aus, L-10): " + ", ".join(
        f"Seeds {k * 100 + 1}-{k * 100 + 100}: {bank_pct(laeufe(100, seed0=k * 100))} %" for k in range(1, 6)))

    # 2) Determinismus: komplett zweiter Lauf, Byte-Vergleich; Einzelseeds mehrfach
    base2 = laeufe(100)
    h1, h2 = hashlib.sha256(csv_text(base).encode()).hexdigest(), hashlib.sha256(csv_text(base2).encode()).hexdigest()
    seeds_equal = all(simulate(s, "agrar", "lager_hub") == simulate(s, "agrar", "lager_hub") for s in (7, 41, 99))
    P(f"[2] Determinismus: Lauf A sha256 {h1[:16]}, Lauf B {h2[:16]} -> {'GLEICH' if h1 == h2 else 'UNGLEICH'}; Einzelseeds 7/41/99 doppelt: {'gleich' if seeds_equal else 'UNGLEICH'}")

    # 3) Dauer Kleinstadt -> Stadt (L-10), Regel isoliert (Versorgung 100 %), 20 Agrar-Seeds
    rows = []
    for l10 in (False, True):
        for pop0 in (1000, 2500):
            for bonus in (0, 125, 250):
                ds4, ds5 = [], []
                for s in range(1, 41, 2):
                    r = simulate(s, "agrar", "lizenz", mods={"versorgt": True, "l10": l10, "pop0": pop0, "bonus_promille": bonus}, horizon=500)
                    if r["dauer_bis_4750_min"] != "":
                        ds4.append(r["dauer_bis_4750_min"])
                    if r["dauer_bis_5000_min"] != "":
                        ds5.append(r["dauer_bis_5000_min"])
                rows.append(dict(regel="L-10 (G nur Nahrung)" if l10 else "alt (Bau = 0, G <= 0,5)", start_einwohner=pop0, bonus_promille=bonus,
                                 n=len(ds5), dauer_bis_4750_min_median=round(statistics.median(ds4)) if ds4 else "nie (500 min)",
                                 dauer_bis_5000_min_median=round(statistics.median(ds5)) if ds5 else "nie (500 min)"))
    write_text("h01_stadt_dauer.csv", csv_text(rows))
    P("[3] Dauer bis Stadt (Regel isoliert, Mehl-Versorgung 100 %, Tor-Stahl nicht eingerechnet; ab Wachstumsstart):")
    for r in rows:
        P(f"    {r['regel']:<26} Start {r['start_einwohner']:>4} Bonus +{r['bonus_promille'] // 10:>2} %: 4.750 nach {r['dauer_bis_4750_min_median']} min, 5.000 nach {r['dauer_bis_5000_min_median']} min")

    # 4) Dynamik mit den (nicht nachbauenden) Modellspielern: wer erreicht die Stadt?
    dyn = laeufe(100, horizon=240, archs=["agrar"])
    reach = [r for r in dyn if r["dauer_bis_5000_min"] != ""]
    write_text("h01_stadt_dynamik.csv", csv_text(dyn))
    P(f"[4] Modellspieler Agrar (n={len(dyn)}, 240 min, Kredit aus, ohne Mehl-Nachbau): Stadt erreicht {len(reach)}, Median Einwohner bei 240 min "
      f"{statistics.median([r['einwohner_ende'] for r in dyn]):.0f}, Max {max(r['einwohner_ende'] for r in dyn)}")
    for st in STRATS:
        rr = [r for r in dyn if r["strategie"] == st]
        P(f"    {st}: n={len(rr)}, Stadt erreicht {sum(1 for r in rr if r['dauer_bis_5000_min'] != '')}, Median Einwohner {statistics.median([r['einwohner_ende'] for r in rr]):.0f}, Stufe 2 gebaut {sum(r['stufe2'] for r in rr)}")

    # 5) Kalibrierung, falls Bankrott ausserhalb 10-30 %
    kal = None
    b = bank_pct(base)
    kal_rows = []
    if not (10 <= b <= 30):
        P(f"[5] Bankrott {b} % ausserhalb 10-30 %: schonendste Kalibrierung aus T-11 (Strasse x5, Startkapital x0,6, Kombination, weitere Stufen) im Regime Kredit aus")
        cands = [("Basis", {}), ("Strasse x2", {"strasse": 2.0}), ("Strasse x3", {"strasse": 3.0}), ("Strasse x5", {"strasse": 5.0}),
                 ("Startkapital x0,8", {"kapital": 0.8}), ("Startkapital x0,6", {"kapital": 0.6}),
                 ("Strasse x3 und Kapital x0,8", {"strasse": 3.0, "kapital": 0.8}), ("Strasse x5 und Kapital x0,6", {"strasse": 5.0, "kapital": 0.6}),
                 ("Ertragspreise x0,5 (T-11: verworfen)", {"preis": 0.5}), ("Lkw-Fixkosten x3 (T-11: verworfen)", {"lkw_fix": 3.0})]
        for name, m in cands:
            rr = laeufe(100, mods=m)
            kal_rows.append(dict(variante=name, bankrott_min30_prozent=bank_pct(rr), median_gewinn_min30_usd=med(rr, "gewinn_min30_usd"),
                                 nie_gebaut=sum(1 for r in rr if not r["gebaut"]), median_erste_lieferung_min=statistics.median([r["t_erste_lieferung_min"] for r in rr if r["t_erste_lieferung_min"] != ""]) if any(r["t_erste_lieferung_min"] != "" for r in rr) else ""))
            P(f"    {name:<40} Bankrott {kal_rows[-1]['bankrott_min30_prozent']:>5} %, Median Gewinn {kal_rows[-1]['median_gewinn_min30_usd']:>7} $, nie gebaut {kal_rows[-1]['nie_gebaut']}")
        write_text("h01_kalibrierung.csv", csv_text(kal_rows))
        # Regel: nur Varianten aus der T-11-Kandidatenliste (Strasse/Kapital), im Korridor, kleinster Eingriff = hoechster Median-Gewinn
        ok = [r for r in kal_rows if r["variante"].startswith(("Strasse", "Startkapital")) and 10 <= r["bankrott_min30_prozent"] <= 30]
        if ok:
            best = max(ok, key=lambda r: r["median_gewinn_min30_usd"])
            kal = dict(c for c in cands)[best["variante"]]
            P(f"    -> gewaehlt (Regel: im Korridor, hoechster Median-Gewinn): {best['variante']} {kal}")
            fin = laeufe(100, mods=kal)
            fin2 = laeufe(100, mods=kal)
            write_text("h01_laeufe_kalibriert.csv", csv_text(fin))
            same = csv_text(fin) == csv_text(fin2)
            P(f"[6] Nach Kalibrierung ({best['variante']}): Bankrott Min 30 {bank_pct(fin)} % ({sum(r['bankrott_min30'] for r in fin)}/100), Median Gewinn Min 30 {med(fin, 'gewinn_min30_usd')} $, "
              f"nie gebaut {sum(1 for r in fin if not r['gebaut'])}; zweiter Lauf identisch: {'JA' if same else 'NEIN'}")
            for arch in ("agrar", "bergbau"):
                rr = [r for r in fin if r["archetyp"] == arch]
                P(f"    {arch}: Bankrott {bank_pct(rr)} %, Median Gewinn {med(rr, 'gewinn_min30_usd')} $")
            P(f"    Bankrott Min 60: {sum(r['bankrott_min60'] for r in fin)} %")
        else:
            P("    -> keine T-11-Variante liegt im Korridor; Befund an Jonas/Tobias (T-12), keine weitere Kalibrierung ohne Grey-Box")
    P(f"Abstuerze gesamt (alle Laeufe oben): {len(CRASHES)}", CRASHES[:3])
    write_text("h01_log.txt", "\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    h01_main()
