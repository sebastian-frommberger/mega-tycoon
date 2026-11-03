extends SceneTree
## Phase 4 W2 (TA): Kamerabilder der Prototyp-Szene mit Prefabs, Kulissen und Gelaendekorrekturen + Perf je Bild.
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/ta_welle2_shots.gd -- <out_dir>
## Bilder: w2_uebersicht, w2_dorf, w2_markt, w2_fluss_floss, w2_floss_laende, w2_see_steg, w2_muehle, w2_gutshof, w2_dorfteich.
## Zaehlwerte: RenderingServer (live) und gezaehlt (Mesh-Daten, wie proto_mass headless) -> <out_dir>/w2_perf.txt

var s: Node
var zeilen: Array = []


func _initialize() -> void:
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _kamera(ziel: Vector2, abstand: float, gier_grad: float) -> void:
	s.ziel = Vector3(ziel.x, 0, ziel.y)
	s.abstand = abstand
	s.gier = deg_to_rad(gier_grad)
	s._kamera_anwenden()


func _shot(out: String, name: String) -> void:
	await _frames(10)
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	var z: Dictionary = s.zaehlung()
	var zl := "%-18s live %8d Dreiecke / %3d DC   gezaehlt %8d / %3d Objekte   Abstand %4.0f m" % [name, z["live_dreiecke"], z["live_dc"],
		z["dreiecke"], z["objekte"], s.abstand]
	print(zl)
	zeilen.append(zl)


func _run() -> void:
	await _frames(2)
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://w2"
	DirAccess.make_dir_recursive_absolute(out)
	zeilen.append("Ladezeit Szene %.0f ms, Prefab-Bau %.0f ms, Gelaende %s" % [s.lade_ms, float(ProtoPrefabs.stats["ms_gesamt"]), JSON.stringify(s.terrain.stats)])
	var k = s.kulissen
	s.setze_preset(1)
	await _shot(out, "w2_uebersicht")
	s.setze_preset(2)
	await _shot(out, "w2_dorf")
	_kamera(Vector2(1640, 735), 170.0, 25.0)
	await _shot(out, "w2_dorf_nah")
	s.setze_preset(3)
	await _shot(out, "w2_markt")
	_kamera(Vector2(110, 150), 140.0, -20.0)
	await _shot(out, "w2_markt_nah")
	# Floss: treibend im Kern (x ~ 1900), dann an der Holzlaende
	if k != null:
		var t_treib: float = 5.0 + (2450.0 - 1880.0) / 1.5
		k.zeit_setzen(t_treib)
		var fp: Vector3 = k.floss.global_position
		_kamera(Vector2(fp.x, fp.z), 55.0, 210.0)
		await _shot(out, "w2_fluss_floss")
		k.zeit_setzen(5.0 + (2450.0 - 1600.0) / 1.5 + 25.0 + 15.0)
		var lp: Vector3 = k.floss.global_position
		_kamera(Vector2(lp.x, lp.z + 10.0), 75.0, 160.0)
		await _shot(out, "w2_floss_laende")
		k.zeit_setzen(40.0)
		var sm: Vector3 = k.steg_mi.global_position
		_kamera(Vector2(sm.x, sm.z), 140.0, 200.0)
		await _shot(out, "w2_see_steg")
		_kamera(Vector2(sm.x - 120, sm.z + 120), 520.0, 225.0)
		await _shot(out, "w2_see_uebersicht")
	_kamera(Vector2(1612, 1100), 150.0, 140.0)
	await _shot(out, "w2_muehle")
	_kamera(Vector2(1935, 1355), 260.0, 200.0)
	await _shot(out, "w2_gutshof")
	_kamera(Vector2(1512, 818), 110.0, 30.0)
	await _shot(out, "w2_dorfteich")
	_kamera(Vector2(1462, 728), 120.0, 300.0)
	await _shot(out, "w2_bachbruecke")
	var f := FileAccess.open(out.path_join("w2_perf.txt"), FileAccess.WRITE)
	for zl in zeilen:
		f.store_line(zl)
	f.close()
	quit(0)
