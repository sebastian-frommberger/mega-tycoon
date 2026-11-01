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
         ("economy_constants.json", "economy_constants.schema.json")]
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
            for k, v in inst.items():
                if k in props:
                    self.check(v, props[k], file, f"{path}/{k}", errors)
                elif schema.get("additionalProperties", True) is False:
                    errors.append(f"{path}: unbekanntes Feld '{k}'")
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


def run(force_fallback=False, data_override=None, quiet=False):
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
    errs = cross_checks(docs["goods.json"], docs["vehicles.json"], docs["economy_constants.json"])
    errs += rechenprobe(docs["economy_constants.json"], docs["goods.json"])
    total += len(errs)
    if not quiet:
        print(f"[querbezuege+rechenprobe]: {'OK' if not errs else str(len(errs)) + ' Fehler'}")
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
