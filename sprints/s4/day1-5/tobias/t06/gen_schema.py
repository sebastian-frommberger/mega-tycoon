#!/usr/bin/env python3
"""B-03: erzeugt schema/economy_slice.schema.json mit required-Liste und additionalProperties:false auf JEDER Ebene
aus der Struktur von data/economy_slice.json. Typ je Schluessel nach Einheitensuffix (Konvention F-09).
Lauf: python3 -I gen_schema.py   (danach validate.py). Neuer Schluessel im JSON = Generator erneut laufen lassen und das
Schema-Diff im Review ansehen; unbekannter Suffix bricht ab."""
import json, os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
M = 9007199254740991
T = {  # Suffix-Regex -> Typschema (Reihenfolge: erste Treffer gewinnt)
 r"_cent(_pro_[a-z_]+)?$": {"type": "integer", "minimum": 0, "maximum": M},
 r"_ms$": {"type": "integer", "minimum": 1, "maximum": 1000},
 r"_ticks$": {"type": "integer", "minimum": 0, "maximum": M},
 r"_promille_signed$": {"type": "integer", "minimum": -1000, "maximum": 100000},
 r"_promille(_pro_[a-z_]+)?$": {"type": "integer", "minimum": 0, "maximum": 100000},
 r"_bp(_pro_[a-z_]+)?$": {"type": "integer", "minimum": -100000, "maximum": 100000},
 r"_felder$": {"type": "integer", "minimum": 0, "maximum": 100000},
 r"_einheiten(_pro_[a-z_]+)?$": {"type": "integer", "minimum": 0, "maximum": M},
 r"_anzahl$": {"type": "integer", "minimum": 0, "maximum": M},
 r"_punkte$": {"type": "integer", "minimum": 0, "maximum": 1000},
 r"_stufe$": {"type": "integer", "minimum": 1, "maximum": 4},
 r"_x100$": {"type": "integer", "minimum": 0, "maximum": 100000},
 r"_flag$": {"type": "boolean"},
 r"(^|_)id$": {"type": "string", "pattern": "^[a-z][a-z0-9_]{1,31}$"},
 r"_modus$": {"type": "string", "minLength": 1, "maxLength": 80},
 r"_text$": {"type": "string", "minLength": 1, "maxLength": 400},
}
ID_ITEM = {"type": "string", "pattern": "^[a-z][a-z0-9_]{0,31}$"}

def scalar(key, path):
    if key == "schema_version":
        return {"const": 1}
    for rx, sch in T.items():
        if re.search(rx, key):
            return dict(sch)
    sys.exit(f"Unbekannter Suffix: {path}/{key} (Konvention erweitern, nicht umgehen)")

def sch(v, key, path):
    if isinstance(v, dict):
        return obj(v, path)
    if isinstance(v, list):
        if v and all(isinstance(x, dict) for x in v):
            return {"type": "array", "minItems": 1, "items": items(v, path)}
        if v and all(isinstance(x, str) for x in v):
            return {"type": "array", "minItems": 1, "items": dict(ID_ITEM)}
        if v and all(isinstance(x, int) and not isinstance(x, bool) for x in v):
            return {"type": "array", "minItems": 1, "items": {"type": "integer", "minimum": 0, "maximum": M}}
        sys.exit(f"Liste ohne einheitlichen Elementtyp: {path}")
    return scalar(key, path)

def obj(o, path):
    return {"type": "object", "additionalProperties": False, "required": list(o.keys()),
            "properties": {k: sch(v, k, f"{path}/{k}") for k, v in o.items()}}

def items(lst, path):
    groups = {}
    for x in lst:
        groups.setdefault((x.get("rolle_modus"), tuple(x.keys())), x)
    variants = []
    for (rolle, _), x in groups.items():
        s = obj(x, path + "[]")
        if rolle is not None:
            s["properties"]["rolle_modus"] = {"const": rolle}
        variants.append(s)
    return variants[0] if len(variants) == 1 else {"anyOf": variants}

def main():
    data = json.load(open(os.path.join(HERE, "data", "economy_slice.json"), encoding="utf-8"))
    s = obj(data, "")
    s["properties"]["schema_version"] = {"const": 1}
    out = {"$schema": "https://json-schema.org/draft/2020-12/schema", "$id": "mega-tycoon/economy_slice.schema.json",
           "title": "Oekonomie-Datenmodell Vertical Slice (T-06, B-03 streng)",
           "description": "Erzeugt von gen_schema.py aus data/economy_slice.json (v2, L-10). Jede Objektebene hat required fuer alle Schluessel und additionalProperties:false; Typ je Einheitensuffix (F-09). Objekte in Listen: je Rolle/Schluesselsatz eine Variante. Keine Gleitkommazahlen."}
    out.update(s)
    p = os.path.join(HERE, "schema", "economy_slice.schema.json")
    json.dump(out, open(p, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    open(p, "a").write("\n")
    print("geschrieben:", p)
main()
