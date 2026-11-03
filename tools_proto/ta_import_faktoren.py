#!/usr/bin/env python3
"""Phase 4, Welle 1 (TA): Prefab-Bauanleitung aus den Importfaktoren (Szene in METERN).

Aufruf (Repo-Wurzel der Arbeitskopie):
    python3 -I tools_proto/ta_import_faktoren.py [--ziel slice/world/data/proto/proto_prefab_bauanleitung.json]

Quellen: sprints/s8/design-sprint/phase2/10_import_faktoren.json (bbox, Ziel, m_pro_u),
         sprints/s8/design-sprint/phase3b/12_regelwerk_v1_1.json (asset_mapping: Quer-/Laengsfaktoren R3, skalen = Soll).
Ausgabe je Rolle: Modellpfad (Kenney All-in-1 + res-Ziel fuer Welle 2), Skalierung [sx, sy, sz] in m je Kenney-Einheit,
Soll-AABB in m, Toleranzband, Pivot-Regel. Zusammenbauten (Haus S/M, Fuhrwerk, Kutsche, Lok+Tender, Steg, Fischerhuette,
Ruderboot, Floss) mit Teilen und Versatz. Der Bauer in GDScript ist slice/world/proto_prefab_bau.gd, Test slice/tests/ta_import_test.gd.
Szene Prototyp = Meter: skala = m_pro_u (= faktor_szene x 25). Deterministisch (sort_keys).
"""
import argparse
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DS = os.path.join(ROOT, "sprints", "s8", "design-sprint")
KENNEY_ROOT = "Kenney Game Assets All-in-1 3.7.0/3D assets/"

# Soll je Rolle aus skalen (12_regelwerk_v1_1.json) bzw. 01_skalen; Fahrzeuge: Band 0,9-1,2 x real, sonst +-25 %
SOLL = {
    "laubbaum": {"achse": "y", "band_m": [15, 25], "quelle": "skalen.baeume_m.laub"},
    "eiche": {"achse": "y", "band_m": [15, 25], "quelle": "skalen.baeume_m.laub"},
    "nadelbaum": {"achse": "y", "band_m": [20, 30], "quelle": "skalen.baeume_m.nadel"},
    "nadelbaum_schlank": {"achse": "y", "band_m": [20, 30], "quelle": "skalen.baeume_m.nadel"},
    "obstbaum": {"achse": "y", "band_m": [6, 8], "quelle": "skalen.baeume_m.obst"},
    "fuhrwerk_wagen": {"achse": "z", "band_m": [4.5 * 0.9, 5.5 * 1.2], "quelle": "01 C Wagen 4,5-5,5 m, Fahrzeugband"},
    "dampflok": {"achse": "z", "band_m": [7.62 * 0.9, 7.62 * 1.2], "quelle": "skalen.fahrzeuge_dm.dampflok l 76 dm"},
    "ruderboot": {"achse": "x", "band_m": [4.5 * 0.9, 4.5 * 1.2], "quelle": "15 C6 / M14 Ruderboot 4,5 m"},
}

# Zusammenbauten (Welle 2 baut sie als je 1 Mesh, R4). Teile: [rolle, versatz_m [x,y,z], drehung_y_grad, anzahl/raster]
ZUSAMMENBAU = {
    "haus_s": {"soll_m": {"b": 8, "t": 6, "h": [6, 7]}, "quelle": "skalen.gebaeude_m.haus_s_kate / haustypen.kate",
               "teile": [["haus_s_modul", "raster 3 x 2 Module, 1 Geschoss (3 m)"], ["dach_hoch", "3 Module laengs, First 3,5 m"]],
               "erwartet_m": [9.0, 6.53, 6.0], "notiz": "Kenney-Modulraster 3 m: 9 x 6 m statt 8 x 6 (+12 %, im Band)"},
    "haus_m": {"soll_m": {"b": 12, "t": 9, "h": [9, 11]}, "quelle": "skalen.gebaeude_m.haus_m / haustypen.bauernhof",
               "teile": [["haus_m_modul", "raster 4 x 3, EG Stein"], ["haus_s_modul", "OG wall-wood"], ["dach_hoch", "4 Module"]],
               "erwartet_m": [12.0, 9.53, 9.0]},
    "fuhrwerk": {"soll_m": {"l": 9.5, "b": 2.2}, "band_l_m": [8.0 * 0.9, 9.0 * 1.2], "quelle": "skalen.fahrzeuge_dm.fuhrwerk_2_pferde",
                 "teile": [["fuhrwerk_wagen", [0, 0, 0]], ["pferd", "2 x nebeneinander vor der Deichsel, Laengsachse x -> 90 Grad drehen"],
                           ["deichsel", "Hilfsmesh 2,0 x 0,1 x 0,1 m"]], "erwartet_m": [2.2, 2.6, 9.5]},
    "postkutsche": {"soll_m": {"l": 12.5, "b": 2.2}, "band_l_m": [10.0 * 0.9, 12.0 * 1.2], "quelle": "skalen.fahrzeuge_dm.postkutsche_4_pferde",
                    "teile": [["kutsche_wagen", [0, 0, 0]], ["pferd", "4 x (2 x 2)"], ["verdeck", "Fantasy roof-gable (Hilfsmesh)"]]},
    "lok_tender": {"soll_m": {"l": 7.6 + 4.8}, "quelle": "skalen.fahrzeuge_dm.dampflok + tender", "teile": [["dampflok", [0, 0, 0]], ["tender", [0, 0, -6.4]]]},
    "steg": {"soll_m": {"l": 25, "b": 2}, "quelle": "16 M14 Steg 25 x 2 m", "teile": [["planken", "Fantasy planks (fehlt lokal) oder Hilfsmesh Box 25 x 0,15 x 2 m"],
                                                                                    ["pfaehle", "alle 2,5 m je Seite, Hilfsmesh Zylinder 0,2 m"]],
             "notiz": "Welle 2: Hilfsmesh, da Fantasy Town nicht lokal"},
    "fischerhuette": {"soll_m": {"b": 8, "t": 6}, "quelle": "16 M14 Fischerhuette 8 x 6 m", "teile": [["haus_s", "Kate"], ["netzgestell", "Pfosten 2,5 m + Querstange, Hilfsmesh"]]},
    "ruderboot": {"soll_m": {"l": 4.5}, "quelle": "16 M14", "teile": [["ruderboot", [0, 0, 0]]], "notiz": "Watercraft boat-row-small fehlt lokal (nur ship-cargo-a), Welle 2 kopiert aus Bastis Kenney-Ordner"},
    "floss": {"soll_m": {"l": [8, 12], "b": [3, 4]}, "quelle": "15 C6 Floss aus log_stack (Kulisse)", "teile": [["holzstapel", "3 x nebeneinander, flach gelegt"]]},
}

LOKAL = {   # Modelle, die in dieser Arbeitskopie liegen (Rest: Welle 2 kopiert aus Bastis Kenney-Ordner)
    "laubbaum": "res://props/kenney/tree_default.glb",
    "nadelbaum": "res://props/kenney/tree_pineDefaultA.glb",
    "findling": "res://props/kenney/rock_largeA.glb",
}
LOKAL_ASSETS = {  # ausserhalb res:// (assets/kenney der Arbeitskopie), nur fuer Tests per GLTFDocument
    "dampflok": "assets/kenney/Train Kit/Models/GLB format/train-locomotive-a.glb",
}


def slug(kit):
    return kit.lower().replace(" kit", "").replace(" pack", "").replace(" ", "_")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--ziel", default=os.path.join(ROOT, "slice", "world", "data", "proto", "proto_prefab_bauanleitung.json"))
    a = ap.parse_args()
    imp = json.load(open(os.path.join(DS, "phase2", "10_import_faktoren.json")))
    reg = json.load(open(os.path.join(DS, "phase3b", "12_regelwerk_v1_1.json")))
    am = reg["asset_mapping"]["rollen"]
    tol = reg["skalen"]["toleranz_promille"] / 1000.0
    rollen = {}
    for name, r in sorted(imp["rollen"].items()):
        mpu = float(r["m_pro_u"])
        q = am.get(name, {})
        fx = q.get("querfaktor_x_1e4", r.get("querfaktor_x", 1.0) * 1e4) / 1e4
        fz = q.get("laengsfaktor_z_1e4", 1e4) / 1e4
        fy = 0.5 if name == "bruecke_fluss_bogen" else 1.0        # 12_welt_regelwerk_v1 §8: Flussbruecke y 0,5
        bb = r["bbox_u"]
        skala = [round(mpu * fx, 4), round(mpu * fy, 4), round(mpu * fz, 4)]
        soll = [round(bb[i] * skala[i], 3) for i in range(3)]
        e = {
            "kit": r["kit"], "modell": r["modell"], "kenney_pfad": KENNEY_ROOT + r["kit"] + "/Models/" +
            ("GLTF format/" if r["kit"].startswith("Nature") else "GLB format/") + r["modell"] + ".glb",
            "res_ziel": LOKAL.get(name, "res://props/kenney_proto/%s/%s.glb" % (slug(r["kit"]), r["modell"])),
            "lokal_vorhanden": name in LOKAL, "lokal_asset": LOKAL_ASSETS.get(name, ""),
            "bbox_u": bb, "bezugsachse": r["bezugsachse"], "ziel_m": r["ziel_m"],
            "m_pro_u": mpu, "faktor_szene_25m": r["faktor_szene"], "faktoren_xyz": [fx, fy, fz],
            "skala_m_pro_u": skala, "soll_aabb_m": soll, "pivot": "unten_mitte (AABB-Boden y = 0, Mitte x/z = 0)",
            "toleranz": SOLL.get(name, {"achse": r["bezugsachse"], "band_m": [round(r["ziel_m"] * (1 - tol), 3), round(r["ziel_m"] * (1 + tol), 3)],
                                         "quelle": "Ziel +-25 % (skalen.toleranz_promille)"}),
            "prefab_ziel": "res://proto/prefabs/%s.tres" % name, "notiz": r.get("notiz", ""),
        }
        if r["kit"] in reg["asset_mapping"].get("fremdpaletten_umfaerben", []):
            e["umfaerben"] = True
        rollen[name] = e
    out = {
        "_zweck": "Prefab-Bauanleitung Prototyp (Szene in Metern). Erzeugt von tools_proto/ta_import_faktoren.py. "
                  "Bauer: slice/world/proto_prefab_bau.gd; Welle 2 kopiert die Modelle nach res_ziel und speichert je Rolle 1 Mesh (R4).",
        "einheit": "m", "regeln": reg["asset_mapping"]["regeln"],
        "quelle": ["sprints/s8/design-sprint/phase2/10_import_faktoren.json", "sprints/s8/design-sprint/phase3b/12_regelwerk_v1_1.json asset_mapping, skalen"],
        "rollen": rollen, "zusammenbau": ZUSAMMENBAU,
        "fernproxy_ab_m": 1400, "kits_erlaubt": reg["asset_mapping"]["kits_erlaubt"],
    }
    os.makedirs(os.path.dirname(a.ziel), exist_ok=True)
    json.dump(out, open(a.ziel, "w"), ensure_ascii=False, indent=1, sort_keys=True)
    for n, e in rollen.items():
        print("%-20s skala %-26s soll %s" % (n, e["skala_m_pro_u"], e["soll_aabb_m"]))
    print("->", os.path.relpath(a.ziel, ROOT), len(rollen), "Rollen,", len(ZUSAMMENBAU), "Zusammenbauten")


if __name__ == "__main__":
    main()
