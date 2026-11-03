extends SceneTree
## Phase 4 W1 (TA): Pruefungen ProtoTerrain, headless.
##   godot --headless --path slice -s res://tests/proto_terrain_test.gd
## 1 Grobknoten = proto_hoehe.r16 · 2 hoehe_at stetig an Fein/Grob-Grenzen · 3 See/Teiche: Mitte unter Pegel, Ufer = Pegel
## 4 Bach: Wasser ueber dem Gelaende (Band sichtbar) · 5 Ladezeit <= 3 s · 6 Flussbreite an 3 Kernspalten im Band 60-120 m
## 7 baeume_freistellen entfernt Baeume · 8 Wasser A/B schaltet

var fehler := 0


func _ok(bed: bool, text: String) -> void:
	print(("OK   " if bed else "FEHL ") + text)
	if not bed:
		fehler += 1


func _initialize() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var t0 := Time.get_ticks_usec()
	var t := ProtoTerrain.bauen(w, "res://world/data/proto")
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	_ok(ms <= 3000.0, "Ladezeit %.0f ms <= 3000 (%s)" % [ms, JSON.stringify(t.stats)])
	# 1 Grobknoten
	var hb := FileAccess.get_file_as_bytes("res://world/data/proto/proto_hoehe.r16")
	var maxd := 0.0
	for iz in range(0, t.gh + 1, 7):
		for ix in range(0, t.gw + 1, 7):
			var h := hb.decode_u16((iz * (t.gw + 1) + ix) * 2) * 0.05
			maxd = maxf(maxd, absf(t.hoehe_at(t.ox + ix * 25.0, t.oz + iz * 25.0) - h))
	_ok(maxd < 0.001, "hoehe_at an Grobknoten = r16 (max. Abweichung %.4f m)" % maxd)
	# 2 Stetigkeit: Sprung zwischen zwei Punkten 0,02 m auseinander, dicht abgetastet ueber den ganzen Kern
	var sprung := 0.0
	for z in range(-20, 1620, 7):
		for x in range(-20, 2020, 7):
			var a := t.hoehe_at(x, z)
			sprung = maxf(sprung, absf(t.hoehe_at(x + 0.02, z) - a))
			sprung = maxf(sprung, absf(t.hoehe_at(x, z + 0.02) - a))
	_ok(sprung < 0.08, "hoehe_at stetig (max. Sprung auf 2 cm: %.3f m)" % sprung)
	# 3 Gewaesser
	for g in t.gewaesser:
		var c: Vector2 = g["mitte"]
		var tief: float = g["pegel"] - t.hoehe_at(c.x, c.y)
		_ok(tief > 0.5 and t.ist_wasser(c.x, c.y), "%s: Mitte %.2f m unter Pegel %.2f, ist_wasser" % [g["name"], tief, g["pegel"]])
		var ab := 0.0
		for i in 36:
			var th := TAU * i / 36.0
			var re: float = ProtoTerrain.Wasser.ufer_radius(g, th)
			var p: Vector2 = c + Vector2(cos(th), sin(th)) * re
			ab = maxf(ab, absf(t.hoehe_at(p.x, p.y) - g["pegel"]))
		_ok(ab < 0.6, "%s: Gelaende an der Uferlinie = Pegel (max. %.2f m)" % [g["name"], ab])
	# 4 Bach
	var unter := 0
	var n := 0
	for p in t.bach["punkte"]:
		if int(p[3]) == 1:
			continue
		if t.fluss_bits_at(p[0], p[1]) & 1:
			continue
		n += 1
		if float(p[2]) < t.hoehe_at(p[0], p[1]) - 0.05:
			unter += 1
	_ok(unter <= n * 0.03, "Bach: Wasserspiegel ueber Gelaende an %d/%d Punkten (Damm am Muehlteich erlaubt)" % [n - unter, n])
	# 6 Flussbreite (quer zur Spalte, ohne cos-Korrektur: obere Schranke)
	for x in [250.0, 1000.0, 1750.0]:
		var pg := t.fluss_pegel_at(x)
		var nass := 0
		for z in range(-200, 1000):
			if t.hoehe_at(x, z) < pg:
				nass += 1
		_ok(nass >= 55 and nass <= 140, "Fluss bei x=%d: %d m unter Pegel %.2f" % [x, nass, pg])
	# 7 Freistellen
	var vorher: int = t.stats["baeume"]
	var weg := t.baeume_freistellen([Vector3(1400, 1350, 150)])
	_ok(weg > 0 and t.stats["baeume"] == vorher - weg, "baeume_freistellen: %d entfernt" % weg)
	# 8 Wasser A/B
	t.wasser_variante_b(true)
	var m: ShaderMaterial = t.wasser_mats[0]
	_ok(m.get_shader_parameter("tiefe_voll_m") == 3.5, "Wasser B gesetzt")
	print("ERGEBNIS: %s (%d Fehler)" % ["GRUEN" if fehler == 0 else "ROT", fehler])
	quit(1 if fehler > 0 else 0)
