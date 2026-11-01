#!/usr/bin/env python3
"""F-09 Validator: prueft data/*.json gegen schema/*.schema.json (Festkomma-Konvention) und zusaetzliche
Querbezuege, die JSON Schema nicht ausdrueckt. Exit 0 = alles gueltig, Exit 1 = Fehler.

Lauf:  python3 validate.py            (nutzt jsonschema, falls installiert; sonst eigenen Mini-Validator)
       python3 validate.py --fallback (erzwingt den eigenen Validator, zum Gegenpruefen)
       python3 validate.py --selftest (Negativtest: absichtlich kaputte Datensaetze muessen durchfallen)
"""
import json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SCHEMA_DIR = os.path.join(HERE, "schema")
DATA_DIR = os.path.join(HERE, "data")
PAIRS = [("goods.json", "goods.schema.json"), ("vehicles.json", "vehicles.schema.json"),
         ("economy_constants.json", "economy_constants.schema.json"),
         ("economy_slice.json", "economy_slice.schema.json")]
MAX_SAFE = 9007199254740991   # 2^53-1: Godot JSON liest Zahlen als float64


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


# ---------------------------------------------------------------- eigener Mini-Validator (Teilmenge Draft 2020-12)
class MiniValidator:
    """Deckt: type, const, enum, properties, required, additionalProperties, items, minItems, maxItems, uniqueItems,
    minimum, maximum, minLength, maxLength, pattern, dependentRequired, $ref (lokal '#/..' und 'datei.json#/..')."""

    def __init__(self, schemas_by_file):
        self.schemas = schemas_by_file

    def resolve(self, ref, current_file):
        file_part, _, ptr = ref.partition("#")
        doc = self.schemas[current_file if file_part == "" else file_part]
        node = doc
        for seg in [s for s in ptr.split("/") if s]:
            node = node[seg]
        return node, (current_file if file_part == "" else file_part)

    def check(self, inst, schema, file, path, errors):
        if "$ref" in schema:
            target, tfile = self.resolve(schema["$ref"], file)
            self.check(inst, target, tfile, path, errors)
            schema = {k: v for k, v in schema.items() if k != "$ref"}
        t = schema.get("type")
        if t is not None:
            ok = {"object": lambda x: isinstance(x, dict), "array": lambda x: isinstance(x, list),
                  "string": lambda x: isinstance(x, str), "boolean": lambda x: isinstance(x, bool),
                  "integer": lambda x: isinstance(x, int) and not isinstance(x, bool),
                  "number": lambda x: isinstance(x, (int, float)) and not isinstance(x, bool)}[t](inst)
            if not ok:
                errors.append(f"{path}: erwartet {t}, ist {type(inst).__name__} ({inst!r})"); return
        if "anyOf" in schema:
            ok_any = False
            for sub in schema["anyOf"]:
                e2 = []
                self.check(inst, sub, file, path, e2)
                if not e2:
                    ok_any = True
                    break
            if not ok_any:
                errors.append(f"{path}: passt auf keine Alternative (anyOf)")
        if "const" in schema and inst != schema["const"]:
            errors.append(f"{path}: muss {schema['const']!r} sein, ist {inst!r}")
        if "enum" in schema and inst not in schema["enum"]:
            errors.append(f"{path}: {inst!r} nicht in {schema['enum']}")
        if isinstance(inst, bool):
            return
        if isinstance(inst, int):
            if "minimum" in schema and inst < schema["minimum"]:
                errors.append(f"{path}: {inst} < minimum {schema['minimum']}")
            if "maximum" in schema and inst > schema["maximum"]:
                errors.append(f"{path}: {inst} > maximum {schema['maximum']}")
        if isinstance(inst, str):
            if "minLength" in schema and len(inst) < schema["minLength"]:
                errors.append(f"{path}: zu kurz")
            if "maxLength" in schema and len(inst) > schema["maxLength"]:
                errors.append(f"{path}: zu lang")
            if "pattern" in schema and not re.search(schema["pattern"], inst):
                errors.append(f"{path}: {inst!r} passt nicht auf {schema['pattern']}")
        if isinstance(inst, dict):
            props = schema.get("properties", {})
            for r in schema.get("required", []):
                if r not in inst:
                    errors.append(f"{path}: Pflichtfeld '{r}' fehlt")
            pats = schema.get("patternProperties", {})
            for k, v in inst.items():
                hit = False
                if k in props:
                    hit = True
                    self.check(v, props[k], file, f"{path}/{k}", errors)
                for pat, sub in pats.items():
                    if re.search(pat, k):
                        hit = True
                        self.check(v, sub, file, f"{path}/{k}", errors)
                if not hit:
                    ap = schema.get("additionalProperties", True)
                    if ap is False:
                        errors.append(f"{path}: unbekanntes Feld '{k}'")
                    elif isinstance(ap, dict):
                        self.check(v, ap, file, f"{path}/{k}", errors)
            for k, reqs in schema.get("dependentRequired", {}).items():
                if k in inst:
                    for r in reqs:
                        if r not in inst:
                            errors.append(f"{path}: '{k}' verlangt '{r}'")
        if isinstance(inst, list):
            if "minItems" in schema and len(inst) < schema["minItems"]:
                errors.append(f"{path}: weniger als {schema['minItems']} Eintraege")
            if "maxItems" in schema and len(inst) > schema["maxItems"]:
                errors.append(f"{path}: mehr als {schema['maxItems']} Eintraege")
            if schema.get("uniqueItems") and len(set(map(json.dumps, inst))) != len(inst):
                errors.append(f"{path}: doppelte Eintraege")
            if "items" in schema:
                for i, el in enumerate(inst):
                    self.check(el, schema["items"], file, f"{path}[{i}]", errors)


def validate_schema(data, schema_file, schemas, force_fallback=False):
    errors = []
    if not force_fallback:
        try:
            import jsonschema
            from referencing import Registry, Resource
            registry = Registry()
            for name, doc in schemas.items():
                registry = registry.with_resource(name, Resource.from_contents(doc))
                registry = registry.with_resource("mega-tycoon/" + name, Resource.from_contents(doc))
            v = jsonschema.Draft202012Validator(schemas[schema_file], registry=registry)
            for e in sorted(v.iter_errors(data), key=lambda e: list(e.absolute_path)):
                errors.append("/" + "/".join(map(str, e.absolute_path)) + ": " + e.message)
            return "jsonschema", errors
        except ImportError:
            pass
    MiniValidator(schemas).check(data, schemas[schema_file], schema_file, "", errors)
    return "fallback", errors


# ---------------------------------------------------------------- Querbezuege (nicht per Schema ausdrueckbar)
def walk_ints(node, path=""):
    if isinstance(node, bool):
        return
    if isinstance(node, int):
        yield path, node
    elif isinstance(node, float):
        yield path, node
    elif isinstance(node, dict):
        for k, v in node.items():
            yield from walk_ints(v, f"{path}/{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from walk_ints(v, f"{path}[{i}]")


def cross_checks(goods, vehicles, consts):
    errs = []
    for name, doc in (("goods", goods), ("vehicles", vehicles), ("economy_constants", consts)):
        for p, v in walk_ints(doc):
            if isinstance(v, float):
                errs.append(f"{name}{p}: Gleitkommazahl {v} verboten (Festkomma-Konvention)")
            elif abs(v) > MAX_SAFE:
                errs.append(f"{name}{p}: {v} ueber 2^53-1 (Godot-JSON liest float64)")
    ids = [g["id"] for g in goods["gueter"]]
    if len(ids) != len(set(ids)):
        errs.append("goods: doppelte id")
    for g in goods["gueter"]:
        for s in g.get("substitut_fuer", []):
            tgt = next((x for x in goods["gueter"] if x["id"] == s), None)
            if tgt is None:
                errs.append(f"goods/{g['id']}: substitut_fuer '{s}' unbekannt")
            elif tgt["kategorie"] != g["kategorie"]:
                errs.append(f"goods/{g['id']}: Substitut '{s}' hat andere Kategorie")
    vids = [v["id"] for v in vehicles["fahrzeuge"]]
    if len(vids) != len(set(vids)):
        errs.append("vehicles: doppelte id")
    for v in vehicles["fahrzeuge"]:
        if v["typ"] == "lok" and "max_anhaenger" not in v:
            errs.append(f"vehicles/{v['id']}: lok braucht max_anhaenger")
        if v["typ"] != "lok" and v["kapazitaet_einheiten"] == 0:
            errs.append(f"vehicles/{v['id']}: Kapazitaet 0 nur bei lok erlaubt")
    z = consts["zeit"]
    if z["periode_ticks"] % z["oeko_tick_ticks"] != 0:
        errs.append("economy_constants/zeit: periode_ticks muss Vielfaches von oeko_tick_ticks sein")
    if consts["lizenz"]["laufzeit_ticks"] % z["periode_ticks"] != 0:
        errs.append("economy_constants/lizenz: laufzeit_ticks muss Vielfaches von periode_ticks sein")
    if z["spieljahr_ticks"] != 12 * z["spielmonat_ticks"]:
        errs.append("economy_constants/zeit: spieljahr_ticks != 12 * spielmonat_ticks")
    band = consts["wachstum"]["band"]
    if [b["g_ab_promille"] for b in band] != sorted((b["g_ab_promille"] for b in band), reverse=True):
        errs.append("economy_constants/wachstum/band: g_ab_promille muss absteigend sortiert sein")
    if band[0]["rate_bp_pro_monat"] != consts["wachstum"]["basisrate_bp_pro_monat"]:
        errs.append("economy_constants/wachstum: oberstes Band muss der Basisrate entsprechen")
    w = consts["wachstum"]
    if w["zuschlag_anteil_personen_promille"] + w["zuschlag_anteil_jobs_promille"] != 1000:
        errs.append("economy_constants/wachstum: Zuschlag-Anteile muessen 1000 ergeben")
    stufen = [a["stufe"] for a in consts["ausbau"]]
    if stufen != [1, 2, 3, 4]:
        errs.append("economy_constants/ausbau: Stufen 1..4 in Reihenfolge")
    s = consts["saettigung"]
    if not (s["voll_bis_promille"] < s["abfall_bis_promille"]):
        errs.append("economy_constants/saettigung: voll_bis < abfall_bis verletzt")
    return errs



# ---------------------------------------------------------------- T-06: Slice-Querbezuege und Abgleichliste Regel -> Key
L08_PATH = os.path.abspath(os.path.join(HERE, "..", "..", "lena", "l08_slice_regeln_v2.md"))
ABGLEICH_PATH = os.path.join(HERE, "abgleich.csv")
KEY_RE = re.compile(r"^[a-z][a-z0-9]*(?:_[a-z0-9]+)+$")


def l08_keys(path):
    """Alle Schluessel aus L-08: Backtick-Tokens in snake_case. Kurzformen (`_town`, `_flour`, `hi/_mid/_low`) werden
    gegen den zuletzt genannten Vollschluessel der Zeile aufgeloest."""
    keys = set()
    with open(path, encoding="utf-8") as f:
        for line in f:
            toks = re.findall(r"`([^`]+)`", line)
            last = None
            for t in toks:
                for part in t.split("/"):
                    part = part.strip()
                    if part.startswith("_") and last:
                        segs = last.split("_")
                        keys.add("_".join(segs[:-1]) + part)
                    elif KEY_RE.match(part):
                        keys.add(part)
                        last = part
    return keys


def resolve_path(doc, pfad):
    node = doc
    for seg in pfad.split("."):
        m = re.match(r"^([a-z0-9_]+)\[id=([a-z0-9_]+)\]$", seg)
        if m:
            node = node[m.group(1)]
            node = next((x for x in node if x.get("id") == m.group(2)), None)
            if node is None:
                return False
        else:
            if not isinstance(node, dict) or seg not in node:
                return False
            node = node[seg]
    return True


def slice_checks(sl, consts, vehicles, check_abgleich=True):
    try:
        return _slice_checks(sl, consts, vehicles, check_abgleich)
    except (KeyError, TypeError, IndexError) as e:
        return [f"slice_checks abgebrochen, Struktur unvollstaendig: {type(e).__name__} {e}"]


def _slice_checks(sl, consts, vehicles, check_abgleich=True):
    errs = []
    for p, v in walk_ints(sl):
        if isinstance(v, float):
            errs.append(f"economy_slice{p}: Gleitkommazahl {v} verboten")
        elif abs(v) > MAX_SAFE:
            errs.append(f"economy_slice{p}: {v} ueber 2^53-1")
    # Referenzen
    preise = sl["preise"]
    gids = {g["id"] for g in sl["gueter"]}
    for g in sl["gueter"]:
        if not any(k.startswith(g["preis_ref_id"] + "_") for k in preise):
            errs.append(f"economy_slice/gueter/{g['id']}: preis_ref_id '{g['preis_ref_id']}' ohne Preis")
        if g["zeitklasse_modus"] not in ("frisch", "massen"):
            errs.append(f"economy_slice/gueter/{g['id']}: zeitklasse_modus unbekannt")
    inds = {i["id"]: i for i in sl["industrien"]}
    stadt = {c["id"] for c in sl["staedte"]}
    for i in sl["industrien"]:
        for gid in i.get("eingang_gut_ids", []) + ([i["ausgang_gut_id"]] if "ausgang_gut_id" in i else []):
            if gid not in gids:
                errs.append(f"economy_slice/industrien/{i['id']}: Gut '{gid}' unbekannt")
        if not (100000 <= i["kaufpreis_stufe1_cent"] <= 400000):
            errs.append(f"economy_slice/industrien/{i['id']}: Kaufpreis ausserhalb 1.000 bis 4.000 $")
    for k in sl["ketten"]:
        for e in k["kanten"]:
            if e["gut_id"] not in gids:
                errs.append(f"economy_slice/ketten/{k['id']}: Gut '{e['gut_id']}' unbekannt")
            if e["von_id"] not in inds:
                errs.append(f"economy_slice/ketten/{k['id']}: von_id '{e['von_id']}' keine Industrie")
            if e["nach_id"] not in inds and e["nach_id"] not in stadt:
                errs.append(f"economy_slice/ketten/{k['id']}: nach_id '{e['nach_id']}' unbekannt")
            if e["strecke_felder"] < sl["ertrag"]["dist_min_felder"]:
                errs.append(f"economy_slice/ketten/{k['id']}: Strecke unter Mindestdistanz (Ertrag 0)")
            src = inds[e["von_id"]]
            if src.get("ausgang_gut_id") != e["gut_id"]:
                errs.append(f"economy_slice/ketten/{k['id']}: {e['von_id']} liefert nicht {e['gut_id']}")
            if e["nach_id"] in inds and e["gut_id"] not in inds[e["nach_id"]].get("eingang_gut_ids", []):
                errs.append(f"economy_slice/ketten/{k['id']}: {e['nach_id']} nimmt {e['gut_id']} nicht an")
    if len(sl["ketten"]) != 3:
        errs.append("economy_slice/ketten: Slice hat genau 3 Ketten (Entscheidung 27.11., D17)")
    if sl["hq"]["archetyp_port_im_slice_flag"] or sl["hq"]["archetyp_trade_im_slice_flag"]:
        errs.append("economy_slice/hq: Hafen/Handel muessen laut D18 ausserhalb des Slice stehen")
    if sl["fabrik"]["factory_upgrade_cost_l2_cent"] != 200000:
        errs.append("economy_slice/fabrik: Ausbau auf Stufe 2 muss 2.000 $ sein (D19)")
    f = sl["fabrik"]
    if not (f["factory_upgrade_cost_l2_cent"] < f["factory_upgrade_cost_l3_cent"] < f["factory_upgrade_cost_l4_cent"]):
        errs.append("economy_slice/fabrik: Ausbaukosten muessen mit der Stufe steigen")
    if sl["kredit"]["credit_limit_cent"] != 200000:
        errs.append("economy_slice/kredit: Rahmen 2.000 $ (D20)")
    s_ = sl["saettigung"]
    if not (s_["sat_full_until_promille"] < s_["sat_knee_promille"]) or s_["sat_floor_at_150_promille"] <= s_["sat_over_150_promille"]:
        errs.append("economy_slice/saettigung: Kurve nicht monoton")
    w = sl["wachstum"]
    if w["growth_bonus_weight_persons_promille"] + w["growth_bonus_weight_jobs_promille"] != 1000:
        errs.append("economy_slice/wachstum: Zuschlag-Gewichte muessen 1000 ergeben")
    if not (w["growth_band_hi_promille"] > w["growth_band_mid_promille"] > w["growth_band_low_promille"]):
        errs.append("economy_slice/wachstum: Baender muessen absteigen")
    # L-10 (Holz-/Bau-Luecke per Regel) und Kredit S5
    korb = {x["stage_id"]: x["kategorien_ids"] for x in sl["saettigung"]["basket_by_stage"]}
    if not w["slice_build_category_active_flag"] and any("bau" in k for k in korb.values()):
        errs.append("economy_slice/saettigung: Bau-Kategorie im Korb, obwohl slice_build_category_active aus (L-10)")
    tor = w["gate_unlock_good_id"]
    produziert = {i.get("ausgang_gut_id") for i in sl["industrien"]}
    if tor not in gids or tor not in produziert:
        errs.append(f"economy_slice/wachstum: Tor-Gut '{tor}' wird im Slice nicht erzeugt (L-10)")
    if tor not in korb.get("stadt", []):
        errs.append("economy_slice/saettigung: Tor-Gut fehlt im Stadt-Korb (L-10)")
    if tor in korb.get("kleinstadt", []) and not w["gate_good_in_growth_supply_flag"]:
        errs.append("economy_slice/saettigung: Tor-Gut im Kleinstadt-Korb, zaehlt aber nicht in G (L-10)")
    if sl["kredit"]["credit_active_in_slice_flag"] or sl["kredit"]["credit_planned_sprint_anzahl"] < 5:
        errs.append("economy_slice/kredit: Kredit im Slice aus, geplant ab Sprint 5 (Refinement S4)")
    if not any(v["id"] == sl["fahrzeug_ref"]["lkw_id"] for v in vehicles["fahrzeuge"]):
        errs.append("economy_slice/fahrzeug_ref: lkw_id nicht in vehicles.json")
    # Konsistenz mit economy_constants.json (gleiche Zahl, zwei Dateien)
    c = consts
    pairs = [
        (sl["lizenz"]["licence_cost_share_promille"], c["lizenz"]["anteil_promille"], "licence_cost_share"),
        (sl["lizenz"]["licence_duration_ticks"], c["lizenz"]["laufzeit_ticks"], "licence_duration"),
        (sl["lizenz"]["licence_discount_in_radius_promille"], c["lizenz"]["radius_rabatt_promille"], "licence_discount_in_radius"),
        (sl["lizenz"]["licence_surcharge_per_field_promille"], c["lizenz"]["ausserhalb_zuschlag_promille_pro_feld"], "licence_surcharge"),
        (sl["kauf"]["buy_licence_credit_share_promille"], c["kauf"]["anrechnung_lizenz_promille"], "buy_licence_credit_share"),
        (sl["kauf"]["buy_discount_first_promille"], c["kauf"]["rabatt_m5b_promille"], "buy_discount_first"),
        (sl["kauf"]["works_margin_promille"], c["kauf"]["werksmarge_promille"], "works_margin"),
        (sl["kauf"]["company_upkeep_per_level_cent_pro_periode"], c["kauf"]["unterhalt_cent_pro_periode_pro_stufe"], "company_upkeep"),
        (sl["kredit"]["credit_limit_cent"], c["kredit"]["rahmen_cent"], "credit_limit"),
        (sl["kredit"]["credit_interest_promille_pro_periode"], c["kredit"]["zins_promille_pro_periode"], "credit_interest"),
        (sl["kredit"]["credit_forced_sale_after_ticks"], c["kredit"]["zwangsverkauf_nach_ticks_unter_rahmen"], "credit_forced_sale"),
        (sl["hq"]["start_capital_agrar_cent"], c["startkapital_cent"]["agrar"], "start_capital_agrar"),
        (sl["hq"]["start_capital_mining_cent"], c["startkapital_cent"]["bergbau"], "start_capital_mining"),
        (sl["hq"]["start_capital_port_cent"], c["startkapital_cent"]["hafen"], "start_capital_port"),
        (sl["hq"]["start_capital_trade_cent"], c["startkapital_cent"]["handelsknoten"], "start_capital_trade"),
        (sl["ertrag"]["dist_knee_felder"], c["ertrag"]["d_eff_knick_felder"], "dist_knee"),
        (sl["ertrag"]["dist_slope_beyond_promille"], c["ertrag"]["d_eff_jenseits_promille"], "dist_slope_beyond"),
        (sl["ertrag"]["dist_min_felder"], c["ertrag"]["mindestdistanz_felder"], "dist_min"),
        (sl["saettigung"]["sat_floor_at_150_promille"], c["saettigung"]["abfall_ziel_promille"], "sat_floor_at_150"),
        (sl["saettigung"]["sat_over_150_promille"], c["saettigung"]["darueber_promille"], "sat_over_150"),
        (sl["wachstum"]["growth_base_rate_bp_pro_monat"], c["wachstum"]["basisrate_bp_pro_monat"], "growth_base_rate"),
        (sl["fabrik"]["factory_upgrade_cost_l2_cent"], c["ausbau"][1]["kosten_cent"], "factory_upgrade_cost_l2"),
        (sl["fabrik"]["factory_upgrade_cost_l3_cent"], c["ausbau"][2]["kosten_cent"], "factory_upgrade_cost_l3"),
        (sl["fabrik"]["factory_upgrade_cost_l4_cent"], c["ausbau"][3]["kosten_cent"], "factory_upgrade_cost_l4"),
        (sl["fabrik"]["factory_throughput_l2_einheiten_pro_periode"], c["ausbau"][1]["durchsatz_einheiten_pro_periode"], "factory_throughput_l2"),
        (sl["lager"]["warehouse_cost_cent"], c["bau"]["lager_cent"], "warehouse_cost"),
        (sl["lager"]["warehouse_upkeep_cent_pro_periode"], c["bau"]["lager_unterhalt_cent_pro_periode"], "warehouse_upkeep"),
        (sl["lager"]["warehouse_capacity_einheiten"], c["bau"]["lager_kapazitaet_einheiten"], "warehouse_capacity"),
        (sl["lager"]["warehouse_ramp_rate_x100"], c["bau"]["rampe_einheiten_pro_tick_x100"], "warehouse_ramp_rate"),
        (sl["fahrzeug_ref"]["strasse_cent_pro_feld"], c["bau"]["strasse_cent_pro_feld"], "strasse_cent_pro_feld"),
    ]
    for a, b, name in pairs:
        if a != b:
            errs.append(f"Konsistenz slice/constants: {name} {a} != {b}")
    return errs + (abgleich_check(sl) if check_abgleich else [])


def abgleich_check(sl):
    errs = []
    if not os.path.exists(ABGLEICH_PATH):
        return ["abgleich.csv fehlt"]
    rows = []
    with open(ABGLEICH_PATH, encoding="utf-8") as f:
        header = f.readline().strip().split(";")
        for line in f:
            if line.strip():
                rows.append(dict(zip(header, line.rstrip("\n").split(";"))))
    for r in rows:
        if not resolve_path(sl, r["json_pfad"]):
            errs.append(f"abgleich Zeile {r['nr']}: Pfad '{r['json_pfad']}' existiert nicht")
    mapped = {r["l08_key"] for r in rows if r["l08_key"] != "-"}
    if not os.path.exists(L08_PATH):
        errs.append(f"L-08 nicht gefunden: {L08_PATH}")
        return errs
    keys = l08_keys(L08_PATH)
    missing = sorted(keys - mapped)
    for k in missing:
        errs.append(f"abgleich: L-08-Key '{k}' hat keine Zeile")
    extra = sorted(mapped - keys)
    for k in extra:
        errs.append(f"abgleich: Key '{k}' steht nicht in L-08 (Tippfehler?)")
    return errs


# ---------------------------------------------------------------- Rechenprobe der Rundungsregel (Beispiel aus konvention.md)
def runde_div(zaehler, nenner):
    """Ganzzahl-Division, halb auf, symmetrisch."""
    q, r = divmod(abs(zaehler), nenner)
    if 2 * r >= nenner:
        q += 1
    return q if zaehler >= 0 else -q


def rechenprobe(consts, goods):
    errs = []
    mehl = next(g for g in goods["gueter"] if g["id"] == "mehl")
    # 10 Einheiten Mehl ueber 45 Felder, f_zeit 1000, f_saett 1000 -> 10 * 100 Cent * 45 = 45.000 Cent = 450,00 $
    d = 45
    d_eff_x1000 = d * 1000 if d <= consts["ertrag"]["d_eff_knick_felder"] else 60000 + consts["ertrag"]["d_eff_jenseits_promille"] * (d - 60)
    ertrag = runde_div(10 * mehl["preis_cent_pro_einheit_feld"] * d_eff_x1000 * 1000 * 1000, 1000 * 1000 * 1000)
    if ertrag != 45000:
        errs.append(f"Rechenprobe Ertrag: {ertrag} != 45000")
    # Lizenz Muehle 2.000 $ im Radius: 200000 * 100/1000 * 700/1000 = 14.000 Cent
    liz = runde_div(200000 * consts["lizenz"]["anteil_promille"] * (1000 - consts["lizenz"]["radius_rabatt_promille"]), 1000 * 1000)
    if liz != 14000:
        errs.append(f"Rechenprobe Lizenz: {liz} != 14000")
    # Zins: 46.000 Cent gezogen, 10 Promille je Periode -> 460 Cent
    zins = runde_div(46000 * consts["kredit"]["zins_promille_pro_periode"], 1000)
    if zins != 460:
        errs.append(f"Rechenprobe Zins: {zins} != 460")
    # Halb-auf: 5 Cent * 150 Promille = 0,75 -> 1
    if runde_div(5 * 150, 1000) != 1 or runde_div(-5 * 150, 1000) != -1 or runde_div(3 * 150, 1000) != 0:
        errs.append("Rechenprobe Rundung halb auf fehlgeschlagen")
    return errs


def run(force_fallback=False, data_override=None, quiet=False, check_abgleich=True):
    schemas = {f: load(os.path.join(SCHEMA_DIR, f)) for f in os.listdir(SCHEMA_DIR) if f.endswith(".json")}
    docs = {}
    total = 0
    for data_file, schema_file in PAIRS:
        data = data_override[data_file] if data_override else load(os.path.join(DATA_DIR, data_file))
        docs[data_file] = data
        engine, errs = validate_schema(data, schema_file, schemas, force_fallback)
        total += len(errs)
        if not quiet:
            print(f"[{engine}] {data_file} gegen {schema_file}: {'OK' if not errs else str(len(errs)) + ' Fehler'}")
            for e in errs:
                print("   ", e)
    try:
        errs = cross_checks(docs["goods.json"], docs["vehicles.json"], docs["economy_constants.json"])
        errs += rechenprobe(docs["economy_constants.json"], docs["goods.json"])
    except (KeyError, TypeError, IndexError) as e:      # B-03: kaputte Struktur = Fehler, kein Absturz
        errs = [f"cross_checks abgebrochen, Struktur unvollstaendig: {type(e).__name__} {e}"]
    errs += slice_checks(docs["economy_slice.json"], docs["economy_constants.json"], docs["vehicles.json"], check_abgleich)
    total += len(errs)
    if not quiet:
        print(f"[querbezuege+rechenprobe+slice+abgleich]: {'OK' if not errs else str(len(errs)) + ' Fehler'}")
        for e in errs:
            print("   ", e)
    return total


def selftest():
    """Absichtlich kaputte Daten: jeder Fall muss mindestens einen Fehler liefern (mit beiden Engines)."""
    import copy
    base = {f: load(os.path.join(DATA_DIR, f)) for f, _ in PAIRS}
    cases = []
    c = copy.deepcopy(base); c["goods.json"]["gueter"][0]["preis_cent_pro_einheit_feld"] = 0.4; cases.append(("Gleitkomma-Preis", c))
    c = copy.deepcopy(base); c["vehicles.json"]["fahrzeuge"][0]["kauf_dollar"] = 400; cases.append(("unbekanntes Feld kauf_dollar", c))
    c = copy.deepcopy(base); del c["economy_constants.json"]["kredit"]["rahmen_cent"]; cases.append(("Pflichtfeld fehlt", c))
    c = copy.deepcopy(base); c["economy_constants.json"]["kauf"]["rabatt_m5b_einmalig"] = False; cases.append(("Rabatt als Dauerregel", c))
    c = copy.deepcopy(base); c["economy_constants.json"]["lizenz"]["laufzeit_ticks"] = 18001; cases.append(("Laufzeit kein Periodenvielfaches", c))
    c = copy.deepcopy(base); c["goods.json"]["gueter"][0]["id"] = "Getreide"; cases.append(("id mit Grossbuchstabe", c))
    c = copy.deepcopy(base); c["economy_constants.json"]["startkapital_cent"]["agrar"] = 2 ** 53; cases.append(("Wert ueber 2^53-1", c))
    c = copy.deepcopy(base); c["economy_constants.json"]["wachstum"]["etikett"] = "getestet"; cases.append(("Etikett 'getestet' ohne Grey-Box", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["fabrik"]["factory_upgrade_cost_l2_cent"] = 600000; cases.append(("Slice: Ausbau Stufe 2 = 6.000 $ (D19 verletzt)", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["lizenz"]["licence_cost_share_promille"] = 0.1; cases.append(("Slice: Gleitkomma Lizenzanteil", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["kauf"]["kauf_dollar"] = 5; cases.append(("Slice: unbekannter Suffix kauf_dollar", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["ketten"].pop(); cases.append(("Slice: nur 2 Ketten", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["hq"]["archetyp_port_im_slice_flag"] = True; cases.append(("Slice: Hafen im Slice (D18 verletzt)", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["kredit"]["credit_limit_cent"] = 250000; cases.append(("Slice/constants: Kreditrahmen weicht ab", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["ketten"][0]["kanten"][1]["strecke_felder"] = 4; cases.append(("Slice: Strecke unter Mindestdistanz", c))
    c = copy.deepcopy(base); del c["economy_slice.json"]["lager"]["warehouse_cost_cent"]; cases.append(("Slice: Abgleichpfad fehlt", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["saettigung"]["basket_by_stage"][1]["kategorien_ids"].append("bau"); cases.append(("Slice: Bau im Kleinstadt-Korb (L-10 verletzt)", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["wachstum"]["gate_unlock_good_id"] = "werkzeug"; cases.append(("Slice: Tor-Gut Werkzeug, im Slice nicht erzeugt", c))
    c = copy.deepcopy(base); c["economy_slice.json"]["kredit"]["credit_active_in_slice_flag"] = True; cases.append(("Slice: Kredit aktiv (S5 verletzt)", c))
    failed = 0
    for name, data in cases:
        for fb in (False, True):
            n = run(force_fallback=fb, data_override=data, quiet=True)
            tag = "fallback" if fb else "jsonschema/auto"
            print(f"selftest [{tag}] {name}: {'erkannt' if n else 'NICHT ERKANNT'} ({n} Fehler)")
            if n == 0:
                failed += 1
    return failed


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        bad = selftest()
        print("selftest:", "OK" if bad == 0 else f"{bad} Faelle nicht erkannt")
        sys.exit(0 if bad == 0 else 1)
    n = run(force_fallback="--fallback" in sys.argv)
    print("ERGEBNIS:", "gueltig, Exit 0" if n == 0 else f"{n} Fehler, Exit 1")
    sys.exit(0 if n == 0 else 1)
