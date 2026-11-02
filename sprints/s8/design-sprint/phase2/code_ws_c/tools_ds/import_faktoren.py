#!/usr/bin/env python3
"""Design Sprint Welt (TEAM-02): Importfaktoren je Rolle aus gemessenen Bounding-Boxen (asset_audit_bbox.py, 02.11.)
und Zielmassen (phase2/01_skalen.md). faktor = Zielmass_m / Modellmass_u / 25 (Szeneneinheit = 1 Feld = 25 m).
Aufruf: python3 -I tools_ds/import_faktoren.py <ausgabe.json>"""
import json, sys
F = 25.0
K = "Kenney All-in-1 3.7.0/3D assets/"
# (rolle, kit, modell, bbox_u (x, y, z), Bezugsachse, Ziel_m, Ziel-Quelle, Notiz, Querfaktor x (optional))
R = [
 ("haus_s_modul", "Fantasy Town Kit", "wall-wood", (0.1, 1.0, 1.0), "y", 3.0, "01 A: Kenney-Modulraster 3 m", "Kit-Faktor fuer alle Fantasy-Town-Module; Haus S = 3x2 Module + roof-high -> 9x6 m, H 6,5 m"),
 ("haus_m_modul", "Fantasy Town Kit", "wall", (0.1, 1.0, 1.0), "y", 3.0, "01 A Haus M 12x9", "4x3 Module, EG Stein + OG wall-wood, roof-high -> 12x9 m, H 9,5 m"),
 ("dach_hoch", "Fantasy Town Kit", "roof-high", (1.071, 1.176, 1.0), "z", 3.0, "Modul 3 m", "Firsthoehe 3,5 m je Modultiefe"),
 ("windmuehle_fluegel", "Fantasy Town Kit", "windmill", (0.471, 3.113, 3.113), "y", 20.0, "01 D Fluegel D 20 m", "nur Fluegel; Turm aus wall-rounded (Hilfsmesh)"),
 ("wassermuehle_rad", "Fantasy Town Kit", "watermill", (0.85, 1.799, 1.799), "y", 5.0, "01 D Rad D 5 m", "Rad + Gerinne, an Haus M 4x4 Module"),
 ("fuhrwerk_wagen", "Fantasy Town Kit", "cart", (0.893, 0.536, 1.34), "z", 5.0, "01 C Wagen 4,5 m x 1,1", "Leiterwagen; Kenney zu breit (3,3 m): Querfaktor x 0,65 -> 2,2 m, Raeder (y-z-Ebene) bleiben rund; mit 2 Pferden + Deichsel ~ 9,5 m", 0.65),
 ("kutsche_wagen", "Fantasy Town Kit", "cart-high", (0.893, 0.861, 1.39), "z", 5.5, "01 C Postkutsche Wagen 5 m x 1,1", "Kasten offen, Verdeck aus roof-gable (Hilfsmesh); Querfaktor x 0,65", 0.65),
 ("pferd", "Prototype Kit", "animal-horse", (1.007, 0.889, 0.312), "x", 2.9, "01 C Pferd 2,6 x 1,1", "einziges Pferd, sehr einfach; Laengsachse x"),
 ("dampflok", "Train Kit", "train-locomotive-a", (1.429, 1.659, 2.6), "y", 4.3, "01 C Lok 7,62 x 1,19 (Laenge), real H ~3,7 x 1,15", "Kenney gedrungen (L:B:H 1,6:0,9:1): Bezug Hoehe statt Laenge -> 6,8 x 3,7 x 4,3 m, alles im Band; Laenge auf 9 m wuerde H 5,7 m (x1,55) ergeben"),
 ("tender", "Train Kit", "train-carriage-coal", (1.2, 1.646, 2.7), "z", 4.8, "01 C Tender 4,8", "Hilfsmesh: Kohlewagen auf 4,8 m gekuerzt (nur z)"),
 ("gueterwagen", "Train Kit", "train-carriage-coal", (1.2, 1.646, 2.7), "z", 6.9, "01 C Gueterwagen 6,9", "gilt fuer -dirt, -wood, -lumber, -flatbed, -box (alle 2,7 u)"),
 ("personenwagen", "Train Kit", "train-carriage-box", (1.2, 1.298, 2.7), "z", 6.9, "01 C Personenwagen 5,74 x 1,2", "Behelf, Fenster als Decal/Farbstreifen"),
 ("gleis", "Train Kit", "railroad-straight", (1.0, 0.1, 4.0), "x", 2.6, "Schwelle 2,6 m", "Segment 10,4 m"),
 ("laubbaum", "Nature Kit", "tree_default", (0.755, 1.708, 0.654), "y", 18.0, "01 E Laubbaum 15-25", "S7 heute NATURE_SCALE 0,8 -> 34 m (x1,9)"),
 ("eiche", "Nature Kit", "tree_oak", (0.641, 1.226, 0.74), "y", 20.0, "01 E Laubbaum", "Solitaer, Allee"),
 ("nadelbaum", "Nature Kit", "tree_pineDefaultA", (0.532, 1.546, 0.532), "y", 25.0, "01 E Nadelbaum 20-30", "Bergwald"),
 ("nadelbaum_schlank", "Nature Kit", "tree_pineTallA", (0.386, 1.53, 0.392), "y", 28.0, "01 E Nadelbaum", "Hochlagen"),
 ("obstbaum", "Fantasy Town Kit", "tree", (1.023, 2.413, 1.023), "y", 7.0, "01 E Obstbaum 6-8", "= Kit-Faktor 0,12 (Gaerten, Streuobst)"),
 ("busch", "Nature Kit", "plant_bushLarge", (0.374, 0.243, 0.336), "y", 2.0, "Hecke/Busch 1,5-3", "Ufergehoelz, Feldrain"),
 ("findling", "Nature Kit", "rock_largeA", (0.785, 0.26, 1.015), "z", 3.0, "Findling 2-4", ""),
 ("felsnadel", "Nature Kit", "rock_tallA", (0.983, 0.996, 0.683), "y", 10.0, "Felsturm 8-12", "nur Fels-Biom"),
 ("felsgruppe", "Pirate Kit", "rocks-a", (5.113, 2.898, 4.386), "x", 12.0, "Felsgruppe 10-15", "Palette auf Nature-Stein umfaerben"),
 ("klippe", "Nature Kit", "cliff_block_stone", (1.0, 1.0, 1.0), "y", 10.0, "Gelaendestufe 10 m", "Steinbruch, Stollenmund (cliff_blockCave_stone)"),
 ("bruecke_bach", "Nature Kit", "bridge_stoneRound", (1.04, 0.4, 1.04), "z", 8.0, "01 E Bachbruecke 8", "Breite x auf Wegbreite: eigener x-Faktor"),
 ("bruecke_fluss_bogen", "Castle Kit", "bridge-straight-pillar", (0.93, 1.176, 0.93), "z", 15.0, "01 E Bogen 15 m", "Bogen wiederholen; Querfaktor x 0,47 (Breite 7 m), Hoehe y x0,5 (9,5 m) separat; Castle-Palette auf Nature-Stein umfaerben", 0.47),
 ("bruecke_holz", "Nature Kit", "bridge_wood", (1.04, 0.4, 1.04), "z", 8.0, "01 E Joch 8 m", "Weg/Strasse, billig"),
 ("zaun_latte", "Fantasy Town Kit", "fence", (0.075, 0.38, 1.0), "y", 1.1, "Lattenzaun 1-1,2", "= Kit-Faktor"),
 ("zaun_feld", "Nature Kit", "fence_simple", (1.0, 0.345, 0.07), "y", 1.1, "Koppelzaun 1-1,2", ""),
 ("trockenmauer", "Graveyard Kit", "stone-wall", (1.0, 0.725, 0.2), "y", 1.3, "Feldmauer 1-1,5", "Weinberg, Kirchhof"),
 ("heuhaufen", "Graveyard Kit", "hay-bale", (0.607, 0.354, 0.402), "x", 1.6, "Heuhaufen/-ballen 1,2-2", "Ballen gab es 1820 nicht: als Heuhaufen-Platzhalter"),
 ("holzstapel", "Nature Kit", "log_stack", (0.425, 0.346, 0.71), "z", 4.0, "Holzstoss 3-5", "Saegewerk, Koehlerei"),
 ("fass", "Survival Kit", "barrel", (0.236, 0.344, 0.236), "y", 0.9, "Fass 0,8-1", "= Kit-Faktor 0,096"),
 ("amboss", "Survival Kit", "workbench-anvil", (0.323, 0.336, 0.296), "x", 0.8, "Amboss + Block", "Schmiede"),
 ("passant", "Graveyard Kit", "character-keeper", (0.811, 0.862, 0.537), "y", 1.75, "Figur 1,75", "nur Nahsicht"),
 ("getreide", "Nature Kit", "crops_wheatStageB", (0.54, 0.535, 0.447), "y", 1.4, "Getreide 1820 ~1,2-1,5", "MultiMesh nur <= 500 m, sonst Bodenfarbe"),
 ("brunnen", "Fantasy Town Kit", "fountain-round", (2.0, 0.28, 2.0), "x", 6.0, "Marktbrunnen 4-6", "= Kit-Faktor"),
 ("laterne", "Graveyard Kit", "lightpost-single", (0.209, 1.267, 0.465), "y", 3.0, "Laterne 3 m", "erst Stadt ab 1820"),
 ("ruderboot", "Watercraft Pack", "boat-row-small", (2.749, 0.848, 2.372), "x", 4.5, "Ruderboot 4-5", "Achse im Spiel pruefen"),
]
out = {"_zweck": "Importfaktoren je Rolle (Design Sprint Welt, TEAM-02, Skizze Phase 2). faktor_szene = Ziel_m / Modell_u / 25; m_pro_u = Ziel_m / Modell_u.",
       "_quelle_bbox": "asset_audit_bbox.py, gemessen 02.11.2026 auf Bastis Geraet (1.451 Modelle in 13 Kits, 0 Fehler)",
       "_quelle_ziel": "phase2/01_skalen.md (Art Director), Fahrzeuge <= 1,2x real, sonst 1,0",
       "_kit_faktor": {"Fantasy Town Kit": 0.12, "Train Kit": 0.104, "Nature Kit": 0.128, "Survival Kit": 0.096, "Graveyard Kit": 0.08,
                       "Castle Kit": 0.24, "Prototype Kit": 0.096, "Pirate Kit": 0.092, "Watercraft Pack": 0.068, "Hexagon Kit": 1.0},
       "rollen": {}}
for row in R:
    rolle, kit, mod, bb, ax, ziel, q, notiz = row[:8]
    u = bb["xyz".index(ax)]
    mpu = ziel / u
    f = mpu / F
    e = {"kit": kit, "modell": mod, "pfad": K + kit + "/Models/" + ("GLTF format/" if kit.startswith("Nature") else "GLB format/") + mod + ".glb",
         "bbox_u": list(bb), "bezugsachse": ax, "ziel_m": ziel, "ziel_quelle": q, "m_pro_u": round(mpu, 3), "faktor_szene": round(f, 4),
         "masse_m": [round(v * mpu, 2) for v in bb], "abweichung_kit_faktor_pct": round((f / out["_kit_faktor"][kit] - 1) * 100) if kit in out["_kit_faktor"] else None,
         "notiz": notiz}
    if len(row) > 8:
        e["querfaktor_x"] = row[8]
        e["masse_m"][0] = round(e["masse_m"][0] * row[8], 2)
    out["rollen"][rolle] = e
json.dump(out, open(sys.argv[1], "w"), ensure_ascii=False, indent=1)
for k, e in out["rollen"].items():
    print("%-22s %-18s %-26s f=%.4f  m/u=%.2f  Masse %s  dKit %s%%" % (k, e["kit"][:18], e["modell"], e["faktor_szene"], e["m_pro_u"], e["masse_m"], e["abweichung_kit_faktor_pct"]))
