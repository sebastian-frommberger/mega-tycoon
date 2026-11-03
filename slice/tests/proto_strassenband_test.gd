extends SceneTree
## Phase 4 Welle 1 (Felix): Straßenband und Fahrlinie mit synthetischen Daten (unabhängig von TA-/Stadt-Dateien).
## Headless:  godot --headless --path slice -s res://tests/proto_strassenband_test.gd
## Gelände: schiefe Ebene h = 40 + 0,01·z; Fluss: Rinne z ∈ [400, 475) über die ganze Breite (Pegel 36,4 m).
## Wege: 0 Chaussee N–S über den Fluss · 1 Dorfstraße als regelmäßige Feldmitten-Treppe · 2 Dorfstraße mit 90°-Ecke
##       (lange Schenkel) · 3 Gasse endet als T auf der Chaussee.

const Band := preload("res://proto/proto_strassenband.gd")

var n_ok := 0
var n_fail := 0


func ok(c: bool, text: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", text)
	else:
		n_fail += 1
		print("  FAIL ", text)


func hoehe(x: float, z: float) -> float:
	return 40.0 + 0.01 * z


func _fluss() -> Dictionary:
	var d := PackedByteArray()
	d.resize(160 * 144)
	for r in 144:
		var z := -1000.0 + r * 25.0
		if z >= 400.0 and z < 475.0:
			for c in 160:
				d[r * 160 + c] = 1
	return {"daten": d, "w": 160, "h": 144, "x0": -1000.0, "z0": -1000.0, "m": 25.0}


func _wege() -> Array:
	var treppe := [[100.0, 100.0]]
	var x := 100.0
	var z := 100.0
	for i in 8:
		if i % 2 == 0:
			x += 25.0
		else:
			z += 25.0
		treppe.append([x, z])
	return [
		{"typ": "chaussee", "punkte": [[500, 100], [500, 300], [500, 600], [500, 800]], "breite_m": 11.0},
		{"typ": "dorfstrasse", "punkte": treppe, "breite_m": 6.0},
		{"typ": "dorfstrasse", "punkte": [[100, 600], [300, 600], [300, 800]], "breite_m": 6.0},
		{"typ": "gasse", "punkte": [[300, 200], [500, 200]], "breite_m": 5.0},
	]


func _initialize() -> void:
	print("proto_strassenband_test")
	var rw = JSON.parse_string(FileAccess.get_file_as_string("res://world/data/proto/regelwerk.json"))
	var root3 := Node3D.new()
	root.add_child(root3)
	var sb = Band.new()
	sb.konfig_aus_regelwerk(rw)
	ok(is_equal_approx(sb.profile["chaussee"]["trasse"], 11.0) and is_equal_approx(sb.profile["chaussee"]["fahrbahn"], 6.0),
		"Chaussee 6 m Fahrbahn / 11 m Trasse aus regelwerk.skalen.wege_dm")
	ok(is_equal_approx(sb.profile["dorfstrasse"]["radius"], 25.0) and is_equal_approx(sb.profile["chaussee"]["radius"], 50.0),
		"Kurvenradien 25/50 m aus regelwerk")
	sb.bauen(root3, _wege(), Callable(self, "hoehe"), _fluss())
	ok(sb.fahrlinien.size() == 4 and sb.meshes.size() >= 4, "4 Fahrlinien, %d Meshes" % sb.meshes.size())
	# Stetigkeit und Glätte aller Fahrlinien
	for fl in sb.fahrlinien:
		var max_dp := 0.0
		var max_dy := 0.0
		var max_k := 0.0
		var s := 0.0
		var p_alt: Vector3 = fl.strecke_punkt(0.0)
		while s < fl.laenge:
			s = minf(s + 0.5, fl.laenge)
			var p: Vector3 = fl.strecke_punkt(s)
			max_dp = maxf(max_dp, Vector2(p.x - p_alt.x, p.z - p_alt.z).length())
			max_dy = maxf(max_dy, absf(p.y - p_alt.y))
			if s > 2.0 and s < fl.laenge - 2.0:
				max_k = maxf(max_k, absf(fl.strecke_kruemmung(s)))
			p_alt = p
		var r_soll: float = sb.profile[fl.typ]["radius"]
		ok(max_dp <= 0.5 + 1e-3 and max_dy < 0.2, "Weg %d %s: Fahrlinie stetig (max Schritt %.3f m, dy %.3f m)" % [fl.weg_index, fl.typ, max_dp, max_dy])
		ok(max_k <= 1.0 / minf(r_soll, fl.r_min) * 1.15 + 1e-3, "Weg %d: Krümmung ≤ 1/R (max %.4f 1/m, R_min %.1f m)" % [fl.weg_index, max_k, minf(r_soll, fl.r_min)])
		var mono := true
		for k in range(1, fl.anker_s.size()):
			if fl.anker_s[k] < fl.anker_s[k - 1] - 0.01:
				mono = false
		ok(mono and is_zero_approx(fl.sim_auf_s(0, 0.0)) and is_equal_approx(fl.sim_auf_s(fl.anker_s.size() - 2, 1.0), fl.laenge),
			"Weg %d: Anker monoton, sim_auf_s deckt 0..L" % fl.weg_index)
	# Treppe -> Diagonale
	var fl1 = sb.fahrlinien[1]
	var dmax := 0.0
	var a := Vector2(100, 100)
	var b := Vector2(200, 200)
	var s1 := 0.0
	while s1 <= fl1.laenge:
		var p: Vector3 = fl1.strecke_punkt(s1)
		dmax = maxf(dmax, Vector2(p.x, p.z).distance_to(Geometry2D.get_closest_point_to_segment(Vector2(p.x, p.z), a, b)))
		s1 += 1.0
	ok(dmax < 1.0 and absf(fl1.laenge - a.distance_to(b)) < 1.0,
		"Feldmitten-Treppe wird Diagonale (Abstand ≤ %.2f m, L %.1f m statt 200 m Treppe)" % [dmax, fl1.laenge])
	ok(fl1.r_min == INF or fl1.r_min >= 25.0 - 0.01, "Treppe ohne Knick-Bögen unter 25 m (r_min %s)" % str(fl1.r_min))
	# 90°-Ecke: Bogen mit genau R 25 m, Scheitel 10,4 m von der Feldmitte (im Eckfeld, ±12,5 m)
	var fl2 = sb.fahrlinien[2]
	var ecke := Vector3(300, 0, 600)
	var dmin := INF
	for k in fl2.punkte.size():
		dmin = minf(dmin, Vector2(fl2.punkte[k].x, fl2.punkte[k].z).distance_to(Vector2(ecke.x, ecke.z)))
	ok(is_equal_approx(fl2.r_min, 25.0), "90°-Ecke: Bogen R = %.1f m (Dorfstraße 25 m)" % fl2.r_min)
	ok(dmin <= sb.abweichung_max_m + 0.01 and dmin < 12.5 * sqrt(2.0),
		"90°-Ecke: Scheitel %.1f m vom Eckpunkt, im Eckfeld und ≤ %.0f m Abweichung (PO W2: R 25 m, 11 m)" % [dmin, sb.abweichung_max_m])
	# Höhe folgt dem Gelände (außerhalb der Brücke)
	var dh := 0.0
	var fl0 = sb.fahrlinien[0]
	for s in [10.0, 100.0, 150.0, 650.0]:
		var p: Vector3 = fl0.strecke_punkt(s)
		dh = maxf(dh, absf(p.y - (hoehe(p.x, p.z) + Band.Y_OFF)))
	ok(dh < 0.02, "Band liegt auf dem Gelände (max Abweichung %.3f m)" % dh)
	# Brücke
	ok(sb.bruecken.size() == 1 and sb.bruecken[0]["weg"] == 0, "genau 1 Brücke, auf der Chaussee (%d)" % sb.bruecken.size())
	if sb.bruecken.size() >= 1:
		var br: Dictionary = sb.bruecken[0]
		ok(br["s_wasser0"] >= 299.0 and br["s_wasser0"] <= 301.0 and br["s_wasser1"] >= 373.0 and br["s_wasser1"] <= 375.5,
			"Wasserlauf erkannt s %.0f–%.0f (Rinne z 400–475)" % [br["s_wasser0"], br["s_wasser1"]])
		ok(br["s0"] <= br["s_wasser0"] - 12.0 and br["s1"] >= br["s_wasser1"] + 12.0, "Deck reicht über beide Ufer (%.1f–%.1f)" % [br["s0"], br["s1"]])
		ok(br["deck_m"] >= 36.4 + 4.5 + 1.0 - 0.01, "Deckhöhe %.2f m ≥ Pegel + lichte Höhe + Deck" % br["deck_m"])
		ok(br["boegen"] == ceili(br["laenge"] / 15.0), "%d Bögen à ≤ 15 m über %.0f m" % [br["boegen"], br["laenge"]])
		var mid: Vector3 = fl0.strecke_punkt((br["s0"] + br["s1"]) * 0.5)
		ok(mid.y >= br["deck_m"], "Fahrlinie liegt auf dem Deck (%.2f m)" % mid.y)
		var steil := 0.0
		var s: float = br["r0"] - 5.0
		while s < br["r1"] + 5.0:
			steil = maxf(steil, absf(fl0.strecke_punkt(s + 1.0).y - fl0.strecke_punkt(s).y))
			s += 1.0
		ok(steil <= 0.10, "Rampen/Deck: steilste Stelle %.1f %% ≤ 10 %%" % (steil * 100.0))
		ok(br.get("teile", 0) > 10 and br["stich_m"] > 0.9, "Steinbogenbrücke gebaut (%d Teile, Stich %.1f m)" % [br.get("teile", 0), br["stich_m"]])
	# Kreuzung
	var kr: Array = sb.knoten.filter(func(k): return k["typ"] == "kreuzung")
	ok(kr.size() == 1, "1 Kreuzungsstück (%d Knoten gesamt)" % sb.knoten.size())
	if kr.size() == 1:
		var k: Dictionary = kr[0]
		ok(Vector2(k["pos"].x, k["pos"].z).distance_to(Vector2(500, 200)) < 1.0 and k["arme"].size() == 2,
			"T-Knoten bei (500, 200): Gasse-Ende + Chaussee durch")
		var s_ch: float = k["arme"].filter(func(a): return a[0] == 0)[0][1]
		ok(absf(s_ch - 100.0) < 1.5, "Arm Chaussee bei s = %.1f (≈ 100)" % s_ch)
	# Spur-Versatz rechts in Fahrtrichtung (Chaussee fährt nach Süden: rechts = Westen = −x)
	var sp: Vector3 = fl0.spur_punkt(50.0, 1.5)
	ok(absf(sp.x - (500.0 - 1.5)) < 0.01, "spur_punkt: +1,5 m = rechts in Fahrtrichtung (x %.2f)" % sp.x)
	ok(absf(fl0.strecke_gier(50.0) - 0.0) < 1e-3, "strecke_gier Süd = 0 (atan2(dx, dz) wie fleet_soa)")
	ok(absf(fl0.naechstes_s(Vector3(503, 0, 350)) - 250.0) < 0.6, "naechstes_s projiziert auf die Fahrlinie")
	# Mesh ohne NaN
	var nan := false
	for mi in sb.meshes:
		for v in (mi.mesh as Mesh).get_faces():
			if is_nan(v.x) or is_nan(v.y) or is_nan(v.z):
				nan = true
	ok(not nan, "Meshes ohne NaN (%d Dreiecke)" % sb.dreiecke())
	# Catmull-Rom-Variante läuft auch
	var sb2 = Band.new()
	sb2.glaettung = "catmull"
	sb2.bauen(root3, _wege(), Callable(self, "hoehe"), _fluss())
	ok(sb2.fahrlinien.size() == 4 and sb2.fahrlinien[2].laenge > 300.0, "Glättung catmull baut ebenfalls (L Ecke %.1f m)" % sb2.fahrlinien[2].laenge)
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)
