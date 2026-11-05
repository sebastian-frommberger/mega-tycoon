extends SceneTree
## Phase 4 Welle 2 (Felix): Bilder Easing-Probe und Flächen (xvfb, opengl3).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_shots_w2.gd -- <out_dir>
## w2_fz_<n>_an/aus.png: Kamera folgt Fahrzeug n (60 m), gleiche Sim-Zeit, Easing an bzw. aus;
## w2_dorf_flaechen.png: Erlenbach nah (Höfe, Gärten, Kirchhof); w2_kreuzung.png: Dorfmitte mit Fuhrwerk 2.

var s: Node


func _initialize() -> void:
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(pfad: String) -> void:
	await _frames(3)
	root.get_viewport().get_texture().get_image().save_png(pfad)
	var z: Dictionary = s.zaehlung()
	print("saved %s  live %d Dreiecke / %d DC" % [pfad.get_file(), z["live_dreiecke"], z["live_dc"]])


## Sim bis Tick t vorspulen (ohne Frames), dann ein paar Frames mit festem Δt, damit der Folger einschwingt.
func _bis(t: int) -> void:
	while s.proto_sim.ticks < t:
		s.proto_sim.tick()
	for i in 30:
		s.fahrzeuge.frame(0.5, 1.0 / 6.0)


func _run() -> void:
	await _frames(2)
	s.set_process(false)
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://").path_join("../d07_shots/proto_w2")
	DirAccess.make_dir_recursive_absolute(out)
	s.hud.visible = true
	var ziele := [[0, 70], [1, 130], [2, 120]]
	for zt in ziele:
		_bis(int(zt[1]) + s.proto_sim.ticks)
		for an in [true, false]:
			s.setze_easing(an)
			s.fahrzeuge.frame(0.5, 1.0 / 6.0)
			s.folgen = int(zt[0])
			var z = s.proto_sim.fahrzeuge[s.folgen]["zustand"]
			s.ziel = Vector3(z.pos.x, 0, z.pos.z)
			s.abstand = 60.0
			s.gier = z.gier + PI * 0.75
			s._kamera_anwenden()
			s._hud_text()
			await _shot(out.path_join("w2_fz_%d_%s.png" % [int(zt[0]) + 1, "an" if an else "aus"]))
	s.setze_easing(true)
	s.folgen = -1
	s.setze_preset(2)
	s.abstand = 220.0
	s._kamera_anwenden()
	await _shot(out.path_join("w2_dorf_flaechen.png"))
	quit(0)
