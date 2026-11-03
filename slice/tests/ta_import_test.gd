extends SceneTree
## Phase 4 W1 (TA): Import-Faktoren an Beispielmodellen, gemessene AABB gegen Soll. Headless.
##   godot --headless --path slice -s res://tests/ta_import_test.gd
## Haus S (Platzhalter-Module, Fantasy Town nicht lokal) · Fuhrwerk-Platzhalter (cart-bbox, Querfaktor 0,65) + Gespann ·
## Laubbaum tree_default.glb (echtes Modell, Faktor 0,42 je Feld = 10,54 m/u) · Nadelbaum · Dampflok train-locomotive-a.glb
## (echtes Modell aus assets/, Laengsfaktor z 1,13).

const Bau := preload("res://world/proto_prefab_bau.gd")

var fehler := 0


func _zeile(name: String, a: AABB, soll: String, ok: bool, quelle: String) -> void:
	print("%s %-18s AABB %5.2f x %5.2f x %5.2f m (x/y/z)  Soll %s  [%s]" % ["OK  " if ok else "FEHL", name, a.size.x, a.size.y, a.size.z, soll, quelle])
	if not ok:
		fehler += 1


func _initialize() -> void:
	# 1 Haus S (Zusammenbau): Soll 8 x 6 m, First 6-7 m, je +-25 %
	var h := Bau.baue_haus_s()
	var a := Bau.messen(h)
	var lang := maxf(a.size.x, a.size.z)
	var tief := minf(a.size.x, a.size.z)
	_zeile("haus_s", a, "8 x 6, H 6-7 (+-25 %)", absf(lang / 8.0 - 1.0) <= 0.25 and absf(tief / 6.0 - 1.0) <= 0.25 and a.size.y >= 6.0 * 0.75 and a.size.y <= 7.0 * 1.25, "platzhalter")
	h.free()
	# 2 Fuhrwerk-Wagen allein + Gespann
	var wg := Bau.baue("fuhrwerk_wagen")
	a = Bau.messen(wg)
	var p := Bau.pruefe("fuhrwerk_wagen", a)
	_zeile("fuhrwerk_wagen", a, "z %.2f-%.2f, Breite <= 2,2" % [p["band_m"][0], p["band_m"][1]], p["ok"] and a.size.x <= 2.2 * 1.05, wg.get_meta("quelle"))
	wg.free()
	var fw := Bau.baue_fuhrwerk()
	a = Bau.messen(fw)
	var band: Array = Bau.anleitung()["zusammenbau"]["fuhrwerk"]["band_l_m"]
	_zeile("fuhrwerk (Gespann)", a, "L %.1f-%.1f (0,9-1,2 x real 8-9 m), B 2,2" % [band[0], band[1]], a.size.z >= band[0] and a.size.z <= band[1], "platzhalter")
	fw.free()
	# 3 Baeume (echte Kenney-Modelle aus res://props/kenney)
	for r in ["laubbaum", "nadelbaum"]:
		var b := Bau.baue(r)
		a = Bau.messen(b)
		p = Bau.pruefe(r, a)
		_zeile(r, a, "y %.0f-%.0f" % [p["band_m"][0], p["band_m"][1]], p["ok"] and b.get_meta("quelle") == "modell", b.get_meta("quelle"))
		b.free()
	# 4 Dampflok (echtes Modell aus assets/kenney/Train Kit, ausserhalb res://)
	var l := Bau.baue("dampflok")
	a = Bau.messen(l)
	p = Bau.pruefe("dampflok", a)
	_zeile("dampflok", a, "z %.2f-%.2f (Laengsfaktor 1,13), H 4,3" % [p["band_m"][0], p["band_m"][1]], p["ok"], l.get_meta("quelle"))
	l.free()
	print("ERGEBNIS: %s (%d Fehler)" % ["GRUEN" if fehler == 0 else "ROT", fehler])
	quit(1 if fehler > 0 else 0)
