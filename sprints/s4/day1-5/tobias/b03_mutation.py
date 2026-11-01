#!/usr/bin/env python3
"""B-03 Mutationstest (angelehnt an Daniels t06_mutation.py, erweitert): loescht JEDEN Objekt-Schluessel (alle Ebenen) in
allen vier Daten-Dateien und prueft, ob (a) allein das Schema (jsonschema UND Mini-Validator), (b) der volle Validator den
Fehler meldet. Zusaetzlich negativ (Wert -1 bzw. falscher Typ) und Gleitkomma (+0,5) als Information.
Lauf: python3 -I b03_mutation.py [pfad_zu_t06]"""
import copy, importlib.util, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
T06 = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "t06")
spec = importlib.util.spec_from_file_location("validate", os.path.join(T06, "validate.py"))
V = importlib.util.module_from_spec(spec); spec.loader.exec_module(V)
schemas = {f: V.load(os.path.join(V.SCHEMA_DIR, f)) for f in os.listdir(V.SCHEMA_DIR) if f.endswith(".json")}
base = {f: V.load(os.path.join(V.DATA_DIR, f)) for f, _ in V.PAIRS}

def leaves(o, path=()):
    if isinstance(o, dict):
        for k, v in o.items():
            yield from leaves(v, path + (k,))
    elif isinstance(o, list):
        for i, v in enumerate(o):
            yield from leaves(v, path + (i,))
    else:
        yield path, o

def mutate(d, path, op):
    n = d
    for k in path[:-1]:
        n = n[k]
    k = path[-1]
    if op == "del":
        if isinstance(n, list):
            return False
        del n[k]
    elif op == "neg":
        if isinstance(n[k], str):
            return False
        n[k] = "x" if isinstance(n[k], bool) else -1
    elif op == "float":
        if isinstance(n[k], (bool, str)):
            return False
        n[k] = n[k] + 0.5
    return True

# Einziger bewusst optionaler Schluessel: Frische-Verfall nur fuer Frischegut (Fleisch); ohne semantischen Marker im Gut nicht
# erzwingbar. Wird gezaehlt, aber als dokumentierte Ausnahme ausgewiesen.
OPTIONAL_OK = {("goods.json", "gueter/6/frische_verfall_ticks")}
res = {}
for df, sf in V.PAIRS:
    for op in ("del", "neg", "float"):
        tot = hit_js = hit_fb = hit_full = 0
        miss = []
        for path, _ in leaves(base[df]):
            d = copy.deepcopy(base); 
            if not mutate(d[df], path, op):
                continue
            tot += 1
            e_js = V.validate_schema(d[df], sf, schemas, False)[1]
            e_fb = V.validate_schema(d[df], sf, schemas, True)[1]
            full = V.run(force_fallback=True, data_override=d, quiet=True)
            hit_js += bool(e_js); hit_fb += bool(e_fb); hit_full += bool(full)
            if not (e_js and e_fb):
                miss.append("/".join(map(str, path)))
        res[(df, op)] = (tot, hit_js, hit_fb, hit_full, miss)
print("Datei;Operation;Mutationen;Schema_jsonschema;Schema_mini;Voller_Validator;NICHT_vom_Schema_erkannt")
for (df, op), (tot, a, b, c, miss) in res.items():
    print(f"{df};{op};{tot};{a};{b};{c};{len(miss)}")
    if op == "del":
        for m in miss[:60]:
            print("   offen:", m)
dels = [v for (df, op), v in res.items() if op == "del"]
tot = sum(v[0] for v in dels)
erk = sum(min(v[1], v[2]) for v in dels)
offen = {(df, m) for (df, op), v in res.items() if op == "del" for m in v[4]}
ok = offen <= OPTIONAL_OK and all(v[3] >= min(v[1], v[2]) - len(OPTIONAL_OK) for v in dels)
print(f"Key-Loeschungen gesamt {tot}, vom Schema (beide Engines) erkannt {erk}, dokumentierte Ausnahme {len(offen)} (goods frische_verfall_ticks)")
print("B-03 Key-Loeschung 100 % (ausser dokumentierter Ausnahme):", "JA" if ok else "NEIN")
sys.exit(0 if ok else 1)
