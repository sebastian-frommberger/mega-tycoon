extends SceneTree
## Phase 4 Welle 1 (Felix): Bilder der Prototyp-Welt an den 5 Kamera-Presets (+ Modelle aus, Wasser B).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_shots.gd -- <out_dir>
## Schreibt proto_<n>_<name>.png und gibt je Bild die Render-Zählwerte (Dreiecke, Draw Calls) aus.

var s: Node


func _initialize() -> void:
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(pfad: String) -> void:
	await _frames(10)
	root.get_viewport().get_texture().get_image().save_png(pfad)
	var z: Dictionary = s.zaehlung()
	print("saved %s  live %d Dreiecke / %d DC" % [pfad.get_file(), z["live_dreiecke"], z["live_dc"]])


func _run() -> void:
	await _frames(2)
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else ProjectSettings.globalize_path("res://").path_join("../d07_shots/proto")
	DirAccess.make_dir_recursive_absolute(out)
	var namen := ["", "uebersicht", "dorf", "markt", "fluss", "see"]
	for n in range(1, 6):
		s.setze_preset(n)
		await _shot(out.path_join("proto_%d_%s.png" % [n, namen[n]]))
	s.setze_preset(1)
	s.setze_modelle(false)
	await _shot(out.path_join("proto_1_ohne_modelle.png"))
	s.setze_modelle(true)
	s.setze_preset(4)
	s.setze_wasser("B")
	await _shot(out.path_join("proto_4_wasser_b.png"))
	quit(0)
