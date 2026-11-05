extends SceneTree
## WA-02 Test: F12 "Stelle merken" schreibt PNG + JSON (user://stellen/) mit den vereinbarten Feldern; anwenden() stellt die Kamera wieder her.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path slice -s res://tests/wa02_f12_test.gd
## (headless ohne Renderer liefert kein Bild; deshalb xvfb)

var s: Node
var fehler := 0


func _initialize() -> void:
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	s.sim_tempo = 0
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _ok(bed: bool, text: String) -> void:
	print("%s  %s" % ["OK  " if bed else "FAIL", text])
	if not bed:
		fehler += 1


func _run() -> void:
	await _frames(3)
	s.setze_preset(3)
	s.gier = 0.77
	s.abstand = 123.0
	s._kamera_anwenden()
	await _frames(3)
	var vor := _liste()
	var ev := InputEventKey.new()
	ev.keycode = KEY_F12
	ev.pressed = true
	s._unhandled_input(ev)
	await _frames(8)
	var nach := _liste()
	var neu: Array = []
	for n in nach:
		if not vor.has(n):
			neu.append(n)
	_ok(neu.size() == 2, "zwei neue Dateien (PNG + JSON): %s" % str(neu))
	var png := ""
	var js := ""
	for n in neu:
		if n.ends_with(".png"):
			png = n
		elif n.ends_with(".json"):
			js = n
	_ok(png != "" and js != "", "PNG und JSON vorhanden")
	if png != "":
		var img := Image.load_from_file("user://stellen/" + png)
		_ok(img != null and img.get_width() > 100, "PNG lesbar %s" % ("%dx%d" % [img.get_width(), img.get_height()] if img != null else "-"))
	if js != "":
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://stellen/" + js))
		_ok(d is Dictionary, "JSON parsebar")
		if d is Dictionary:
			var k: Dictionary = d["kamera"]
			_ok(is_equal_approx(float(k["abstand"]), 123.0), "abstand 123")
			_ok(absf(float(k["gier_rad"]) - 0.77) < 1e-6, "gier 0.77")
			_ok(k["position"] is Array and k["position"].size() == 3 and k["ziel"] is Array, "position/ziel als Arrays")
			_ok(int(d["welt_seed"]) == 7, "welt_seed 7 (= %s)" % str(d["welt_seed"]))
			_ok(str(d["build_hash"]) != "", "build_hash = %s" % str(d["build_hash"]))
			_ok(d.has("zeit_lokal") and d.has("sim_tick") and int(d["sim_tick"]) == 0, "zeit + sim_tick 0 (Pause)")
			print(JSON.stringify(d))
			# anwenden: Kamera woandershin, dann wiederherstellen
			s.setze_preset(1)
			StelleMerkenRef.anwenden(s, d)
			_ok(is_equal_approx(s.abstand, 123.0) and absf(s.gier - 0.77) < 1e-6, "anwenden() stellt Kamera wieder her")
			var p2: Vector3 = s.cam.global_position
			_ok(p2.distance_to(Vector3(k["position"][0], k["position"][1], k["position"][2])) < 0.01, "Kameraposition identisch")
	for n in neu:
		DirAccess.remove_absolute("user://stellen/" + n)       # nur die eigenen Testdateien
	print("WA02_F12_TEST %s (%d Fehler)" % ["GRUEN" if fehler == 0 else "ROT", fehler])
	quit(0 if fehler == 0 else 1)


func _liste() -> Array:
	var r: Array = []
	var da := DirAccess.open("user://stellen")
	if da != null:
		for f in da.get_files():
			r.append(f)
	return r


const StelleMerkenRef := preload("res://proto/stelle_merken.gd")
