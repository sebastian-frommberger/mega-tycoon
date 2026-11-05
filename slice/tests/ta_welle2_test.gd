extends SceneTree
## Phase 4 W2 (TA): Pruefungen Prefabs, Fahrzeuge, Kulissen (M14/M15), Freistellen, Gang-Kosten. Headless.
##   godot --headless --path slice -s res://tests/ta_welle2_test.gd
## Exit 0 nur, wenn alles OK ist.

var n_ok := 0
var n_fail := 0


func _initialize() -> void:
	_run.call_deferred()


func pr(ok: bool, text: String) -> void:
	print(("OK   " if ok else "FAIL ") + text)
	if ok:
		n_ok += 1
	else:
		n_fail += 1


func _band(ist: float, soll: float, tol := 0.25) -> bool:
	return ist >= soll * (1.0 - tol) - 1e-4 and ist <= soll * (1.0 + tol) + 1e-4


func _run() -> void:
	var t0 := Time.get_ticks_usec()
	var dreiecke := 0
	var alle_ok := true
	for t in ProtoPrefabs.TYPEN:
		var m := ProtoPrefabs.mesh_fuer(t)
		var a := m.get_aabb()
		var ok := m.get_surface_count() == 1 and absf(a.position.y) < 0.01 and absf(a.get_center().x) < 0.05 and absf(a.get_center().z) < 0.05
		ok = ok and m.surface_get_material(0) == ProtoPrefabs.material()
		if not ok:
			alle_ok = false
			print("   ", t, " Flaechen ", m.get_surface_count(), " AABB ", a)
		dreiecke += int(m.get_meta("dreiecke"))
	pr(alle_ok, "%d Prefabs: je 1 Flaeche, 1 gemeinsames Material, Ursprung Bodenmitte (%.0f ms, %d Dreiecke zusammen)" % [ProtoPrefabs.TYPEN.size(), (Time.get_ticks_usec() - t0) / 1000.0, dreiecke])
	var inst = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/proto_instanzen.json"))
	var fehlt: Array = []
	for it in inst:
		var k := ProtoPrefabs.schluessel(it)
		if not ProtoPrefabs.vorhanden(k) and not (k in fehlt):
			fehlt.append(k)
	pr(fehlt.is_empty(), "alle Instanztypen aus proto_instanzen.json haben ein Prefab (fehlend: %s)" % [str(fehlt)])
	# Fern-LOD
	var fern_ok := true
	for t in ProtoPrefabs.FERN_TYPEN:
		var nah := ProtoPrefabs.mesh_fuer(t).get_aabb()
		var fe := ProtoPrefabs.mesh_fern(t).get_aabb()
		if absf(nah.size.x - fe.size.x) > 0.5 or absf(nah.size.z - fe.size.z) > 0.5 or int(ProtoPrefabs.mesh_fern(t).get_meta("dreiecke")) > 400:
			fern_ok = false
	pr(fern_ok, "Fern-LOD: gleiche Grundflaeche, <= 400 Dreiecke je Gebaeude")
	# Fahrzeuge
	var fw := ProtoPrefabs.fahrzeug("fuhrwerk")
	pr(fw["laenge_m"] >= 8.0 and fw["laenge_m"] <= 9.0 and fw["breite_m"] <= 2.3, "Fuhrwerk L %.2f m (8-9), B %.2f m" % [fw["laenge_m"], fw["breite_m"]])
	var pk := ProtoPrefabs.fahrzeug("postkutsche")
	pr(pk["laenge_m"] >= 10.0 and pk["laenge_m"] <= 12.0, "Postkutsche (4 Pferde) L %.2f m (10-12)" % pk["laenge_m"])
	var dl := ProtoPrefabs.fahrzeug("dampflok")
	pr(absf(dl["laenge_m"] - 13.8) < 0.1, "Dampflok + Tender L %.2f m (13,8 = 1,19 x 11,6)" % dl["laenge_m"])
	var pw := ProtoPrefabs.fahrzeug("personenwagen")
	pr(absf(pw["laenge_m"] - 6.8) < 0.05, "Personenwagen L %.2f m (PO 6,8)" % pw["laenge_m"])
	var rr: Array = fw["gang"]["rad_radien_m"]
	pr(rr.size() == 4 and float(rr[0]) > 0.5, "Fuhrwerk: 4 Raeder mit Drehpunkt (Radien %s), Periode %.0f m" % [str(rr), fw["gang"]["periode_m"]])
	# Gang-Kosten CPU (10 Fahrzeuge)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = fw["mesh"]
	mm.instance_count = 10
	var t1 := Time.get_ticks_usec()
	for f in 2000:
		for i in 10:
			mm.set_instance_custom_data(i, Color(fmod(f * 0.4 + i, ProtoPrefabs.PERIODE_M), 0.125, 0.0, 0.0))
	var ms := (Time.get_ticks_usec() - t1) / 1000.0 / 2000.0
	pr(ms <= 0.1, "Gang-/Radphase: CPU %.4f ms je Frame fuer 10 Fahrzeuge (<= 0,1 ms; Shader: 1 sin/cos je Ecke)" % ms)
	# Gelaende + Kulissen
	var welt := Node3D.new()
	root.add_child(welt)
	var terr := ProtoTerrain.bauen(welt, "res://world/data/proto")
	var k := ProtoKulissen.bauen(welt, terr)
	var mw: Dictionary = k.messwerte()
	var see: Dictionary = terr.see["see"]
	var d_see := sqrt(float(see.get("flaeche_m2", 0.0)) / PI) * 2.0
	pr(d_see >= 100.0 and d_see <= 150.0, "M14 See Ø %.0f m (WA-12: Teichgröße 100-150, Kartentyp Flusstal; vorher 400-600)" % d_see)
	pr(_band(mw["steg_m"][0], 25.0) and _band(mw["steg_m"][1], 2.0), "M14 Steg %.1f x %.1f m (25 x 2 ±25 %%)" % mw["steg_m"])
	var fh := ProtoPrefabs.mesh_fuer("fischerhuette").get_aabb()
	pr(_band(maxf(fh.size.x, fh.size.z), 8.0) and _band(minf(fh.size.x, fh.size.z), 6.0), "M14 Fischerhuette %.1f x %.1f m (8 x 6 ±25 %%)" % [fh.size.x, fh.size.z])
	pr(mw["boot_m"] >= 4.05 and mw["boot_m"] <= 5.4, "M14 Ruderboot L %.2f m (4,5: 0,9-1,2 x)" % mw["boot_m"])
	pr(_band(mw["floss_m"][0], 8.0) and _band(mw["floss_m"][1], 3.0), "Floss %.1f x %.1f m (8 x 3 ±25 %%)" % mw["floss_m"])
	# Steg: Ende im Wasser, Wurzel am Ufer
	var se: Vector2 = mw["steg_ende"]
	var sw: Vector2 = mw["steg_wurzel"]
	var tiefe_ende: float = float(mw["pegel_see"]) - terr.hoehe_at(se.x, se.y)
	var ufer_wurzel: float = terr.hoehe_at(sw.x, sw.y) - float(mw["pegel_see"])
	pr(tiefe_ende > 0.5 and ufer_wurzel > -0.6, "Steg: Ende %.1f m tief, Wurzel %.1f m ueber Pegel (%s)" % [tiefe_ende, ufer_wurzel, mw["quelle"]])
	# Bootsschleife ganz im Wasser (>= 1 m tief)
	var bs: Array = mw["boot_schleife"]
	var min_t := 99.0
	for i in 72:
		var p: Vector2 = (bs[0] as Vector2) + Vector2(cos(TAU * i / 72.0), sin(TAU * i / 72.0)) * float(bs[1])
		min_t = minf(min_t, float(mw["pegel_see"]) - terr.hoehe_at(p.x, p.y))
	pr(min_t >= 1.0, "Bootsschleife r %.0f m: min. Wassertiefe %.1f m, Umlauf %.0f s" % [bs[1], min_t, bs[2]])
	# Floss: Kurs ueber Wasser (>= 0,8 m tief), Laende am Ufer
	var min_f := 99.0
	var x := ProtoKulissen.FLOSS_X0
	while x >= ProtoKulissen.FLOSS_XL:
		var kp: Vector3 = k._kurs(x)
		min_f = minf(min_f, kp.y - terr.hoehe_at(kp.x, kp.z))
		x -= 10.0
	pr(min_f >= 0.8, "Floss-Kurs x %.0f -> %.0f (nach Westen): min. Tiefe %.1f m, Periode %.0f s" % [ProtoKulissen.FLOSS_X0, ProtoKulissen.FLOSS_XL, min_f, mw["floss_periode_s"]])
	var lp: Vector3 = mw["laende"]
	var ufer_d := 99.0
	for dz in range(0, 40):
		if terr.hoehe_at(lp.x, lp.z + dz) > lp.y:
			ufer_d = dz
			break
	pr(ufer_d <= 20.0 and terr.hoehe_at(lp.x, lp.z) < lp.y - 0.5, "Holzlaende: Floss liegt %.0f m vor dem Suedufer im Wasser" % ufer_d)
	# M15: Nutzung <= 500 m vom Ufer + Pfad zum Ort
	var orte = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/proto_orte.json"))
	var huette := Vector2.ZERO
	for it in inst:
		if it["typ"] == "fischerhuette":
			huette = Vector2(it["x"], it["z"])
	var sm := Vector2(see["mitte_m"][0], see["mitte_m"][1])
	var d_ufer := huette.distance_to(sm) - float(see["radius_m"])
	pr(huette != Vector2.ZERO and d_ufer <= 500.0, "M15 Fischerhuette %.0f m vom Seeufer (<= 500)" % maxf(d_ufer, 0.0))
	var wege = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/proto_wege.json"))
	var pfad: Dictionary = {}
	for w in wege:
		if String(w.get("id", "")) == "fischerpfad":
			pfad = w
	var ok_pfad := false
	var txt := "kein fischerpfad"
	if not pfad.is_empty():
		var pts: Array = pfad["punkte"]
		var a0 := Vector2(pts[0][0], pts[0][1])
		var a1 := Vector2(pts[-1][0], pts[-1][1])
		var d_h := minf(a0.distance_to(huette), a1.distance_to(huette))
		var d_netz := 99.0
		for w in wege:
			if w == pfad:
				continue
			for q in w["punkte"]:
				d_netz = minf(d_netz, minf(Vector2(q[0], q[1]).distance_to(a1), Vector2(q[0], q[1]).distance_to(a0)))
		var dorf := Vector2.ZERO
		for o in orte["orte"]:
			if o["klasse"] == "dorf":
				dorf = Vector2(o["x"], o["z"])
		ok_pfad = d_h <= 25.0 and d_netz <= 10.0
		txt = "fischerpfad %.0f m, Start %.0f m von der Huette, Anschluss ans Wegenetz %.1f m, Dorf Erlenbach %.0f m Luftlinie" % [pfad.get("laenge_m", 0.0), d_h, d_netz, huette.distance_to(dorf)]
	pr(ok_pfad, "M15 Pfad zum Ort: " + txt)
	# Freistellen Bachbruecke / Muehle
	var nah_br := 0
	var nah_mu := 0
	for e in terr._baeume:
		var o: Vector3 = (e[1] as Transform3D).origin
		if Vector2(o.x, o.z).distance_to(Vector2(1462.5, 728.1)) < 15.0:
			nah_br += 1
		if Vector2(o.x, o.z).distance_to(Vector2(1617.0, 1090.0)) < 20.0:
			nah_mu += 1
	pr(nah_br == 0 and nah_mu == 0, "Freistellen: %d Baeume < 15 m an der Bachbruecke, %d < 20 m an der Muehle (entfernt gesamt %d)" % [nah_br, nah_mu, terr.stats.get("freigestellt", 0)])
	# Dorfteich verlegt
	var dt: Dictionary = terr.see["dorfteich"]
	pr(Vector2(dt["mitte_m"][0], dt["mitte_m"][1]).distance_to(Vector2(1512, 818)) < 0.5 and terr.ist_wasser(1512, 818), "Dorfteich bei (1512 / 818), Pegel %.2f m" % dt["pegel_m"])
	var pl: Dictionary = terr.meta.get("plateaus_w2", {})
	pr(pl.has("kern_max_neigung_pct") and float(pl["kern_max_neigung_pct"]["nachher"]) < float(pl["kern_max_neigung_pct"]["vorher"]),
		"S7-Plateaus geglaettet: Kern max. Neigung %s %%, Anteil > 30 %% %s" % [str(pl.get("kern_max_neigung_pct")), str(pl.get("kern_anteil_ueber_30pct"))])
	print("Pruefungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)
