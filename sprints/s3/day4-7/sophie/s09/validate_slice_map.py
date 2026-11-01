#!/usr/bin/env python3
"""Prueft slice_map.json mit Tobias' F-09-Validator (importiert validate.py: jsonschema-Engine UND Fallback) + Querbezuege.
Aufruf: python3 -I validate_slice_map.py   Exit 0 = valide."""
import importlib.util, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); F09 = "/tmp/claude-0/gd/sprint2/day4-6/tobias/f09"
spec = importlib.util.spec_from_file_location("f09validate", F09 + "/validate.py"); V = importlib.util.module_from_spec(spec); spec.loader.exec_module(V)
schemas = {n: V.load(os.path.join(F09, "schema", n)) for n in os.listdir(F09 + "/schema")}
schemas["slice_map.schema.json"] = V.load(HERE + "/slice_map.schema.json")
doc = V.load(HERE + "/slice_map.json"); goods = {g["id"] for g in V.load(F09 + "/data/goods.json")["gueter"]}
errs = []
for force in (False, True):
    eng, e = V.validate_schema(doc, "slice_map.schema.json", schemas, force_fallback=force)
    print(f"engine={eng} fehler={len(e)}"); errs += [f"[{eng}] {x}" for x in e]
for p, v in V.walk_ints(doc):
    if isinstance(v, float): errs.append(f"{p}: Float {v}")
    elif abs(v) > V.MAX_SAFE: errs.append(f"{p}: > 2^53-1")
ids = [x["id"] for k in ("staedte", "industrien") for x in doc[k]]
if len(ids) != len(set(ids)): errs.append("doppelte id")
idset = set(ids); stadt = {s["id"] for s in doc["staedte"]}
for i in doc["industrien"]:
    for g in i["eingang_gueter"] + i["ausgang_gueter"]:
        if g not in goods: errs.append(f"{i['id']}: Gut {g} unbekannt (goods.json)")
for k in doc["ketten"]:
    for s in k["strecken"]:
        for e in (s["von"], s["nach"]):
            if e not in idset: errs.append(f"kette {k['id']}: {e} unbekannt")
    for g in k["gueter"]:
        if g not in goods: errs.append(f"kette {k['id']}: Gut {g}")
for h in doc["hq_optionen"]:
    if h["stadt"] not in stadt: errs.append(f"hq {h['archetyp']}: Stadt unbekannt")
    for i in h["industrien_im_radius"] + [h["bau_quelle"]]:
        if i not in idset: errs.append(f"hq {h['archetyp']}: {i}")
slice_k = [k for k in doc["ketten"] if k["im_slice"]]
if len(slice_k) != 3: errs.append(f"{len(slice_k)} Slice-Ketten statt 3")
print("staedte", len(doc["staedte"]), "industrien", len(doc["industrien"]), "slice_ketten", len(slice_k))
print("VALIDIERUNG", "OK" if not errs else "FEHLER"); [print(" -", e) for e in errs]
sys.exit(1 if errs else 0)
