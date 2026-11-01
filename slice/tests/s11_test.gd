extends SceneTree
## S-11 / D22-Vorarbeit: Karte (Mittelfurt Farm + Mühle, Fluss dazwischen, Quadranten) und Label-LOD. Start:
##   godot --headless --path slice -s res://tests/s11_test.gd
var fails := 0
var checks := 0


func ok(cond: bool, what: String) -> void:
	checks += 1
	print(("  OK   " if cond else "  FAIL "), what)
	if not cond:
		fails += 1


func _seg_cross(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	return Geometry2D.segment_intersects_segment(a, b, c, d) != null


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/slice_map.json"))
	var by := {}
	for k in ["staedte", "industrien"]:
		for e in map[k]:
			by[e["id"]] = Vector2(e["x_felder"], e["y_felder"])
	var mf: Vector2 = by["mittelfurt"]
	ok(by.has("farm_3") and by.has("muehle_2"), "farm_3 und muehle_2 in der Karte")
	var df: float = mf.distance_to(by["farm_3"])
	var dm: float = mf.distance_to(by["muehle_2"])
	ok(df >= 38.0 and df <= 44.0, "Farm 38-44 Felder von Mittelfurt (%.1f)" % df)
	ok(dm >= 30.0 and dm <= 40.0, "Mühle 30-40 Felder von Mittelfurt (%.1f)" % dm)
	ok(df <= 45.0 and dm <= 45.0, "beide im Radius der Stadt (45)")
	var pts: Array = map["fluesse"][0]["linie"]
	var crosses := false
	for i in pts.size() - 1:
		if _seg_cross(by["farm_3"], by["muehle_2"], Vector2(pts[i][0], pts[i][1]), Vector2(pts[i + 1][0], pts[i + 1][1])):
			crosses = true
	ok(crosses, "Fluss liegt zwischen Farm und Mühle (Brücke nötig)")
	var q := {"NW": 0, "NO": 0, "SW": 0, "SO": 0}
	var n := 0
	for id in by:
		var inslice := true
		for e in map["industrien"]:
			if e["id"] == id and not e.get("im_slice", true):
				inslice = false
		if inslice:
			q[("N" if by[id].y < 256 else "S") + ("W" if by[id].x < 256 else "O")] += 1
			n += 1
	var okq := true
	for k in q:
		var pct: float = 100.0 * q[k] / n
		okq = okq and pct >= 20.0 and pct <= 30.0
	ok(okq, "Quadranten 25 %% +-5 (%s)" % str(q))
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.start_game("agrar")
	var farm = m.by_id["farm_3"]
	var cityb = m.by_id["mittelfurt"]
	ok(farm != null and cityb != null, "farm_3 und Mittelfurt als Gebäude gebaut")
	m.focus(Vector2(380, 280), 14.0)
	await process_frame
	await process_frame
	ok(not farm.label.visible, "Zoom 14: Industrie-Label ausgeblendet")
	ok(cityb.label.visible and cityb.label.text.find("\n") < 0, "Zoom 14: Stadtname bleibt, nur eine Zeile")
	m.focus(Vector2(380, 280), 5.0)
	await process_frame
	await process_frame
	ok(farm.label.visible and farm.label.text.find("\n") < 0, "Zoom 5: Industrie nur Name")
	ok(cityb.label.text.find("Einw.") >= 0, "Zoom 5: Stadt mit Einwohnern")
	m.focus(Vector2(380, 280), 2.0)
	await process_frame
	await process_frame
	ok(farm.label.text.split("\n").size() >= 3, "Zoom 2: voller Text (Bestand, Lizenz)")
	ok(farm.label.outline_size <= 8 and farm.label.pixel_size <= 0.00075 and cityb.label.pixel_size <= 0.001, "Labels kleiner und Saum schlank (S-11)")
	ok(m.sun != null and m.sun.shadow_enabled and m.sun.light_energy < 0.8, "Sonne mit Schatten, Energie unter 0,8")
	print("\n%d/%d Prüfungen OK" % [checks - fails, checks])
	quit(0 if fails == 0 else 1)
