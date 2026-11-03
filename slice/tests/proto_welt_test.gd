extends SceneTree
## Phase 4 Welle 1 (Felix): Smoke-Test der Prototyp-Szene (Laden, Daten, Kamera, Presets, Schalter-Hooks).
## Headless:  godot --headless --path slice -s res://tests/proto_welt_test.gd
## Läuft mit Vertragsdaten (res://world/data/proto/) oder Felix-Testdaten (res://proto/testdaten/), je Datei.

var n_ok := 0
var n_fail := 0
var s: Node
var signale := {}


func ok(c: bool, text: String) -> void:
	if c:
		n_ok += 1
		print("  OK   ", text)
	else:
		n_fail += 1
		print("  FAIL ", text)


func _initialize() -> void:
	_run.call_deferred()


func _key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.pressed = true
	s._unhandled_input(ev)


func _run() -> void:
	print("proto_welt_test")
	var t0 := Time.get_ticks_usec()
	s = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.wasser_modus_geaendert.connect(func(m): signale["wasser"] = m)
	s.easing_geaendert.connect(func(a): signale["easing"] = a)
	s.modelle_geaendert.connect(func(a): signale["modelle"] = a)
	root.add_child(s)
	await process_frame
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	ok(s.lade_ms > 0.0 and s.lade_ms <= 3000.0, "Szene geladen in %.0f ms (_ready), %.0f ms mit erstem Frame (Gate 3 s)" % [s.lade_ms, ms])
	ok(s.terrain != null and s.terrain.has_method("hoehe_at"), "Gelände da (%s)" % s.terrain_quelle)
	var h: float = s.hoehe_at(1000.0, 800.0)
	ok(h > 20.0 and h < 200.0, "hoehe_at(1000, 800) = %.1f m über NN" % h)
	ok(s.wege.size() > 0 and s.strassen.fahrlinien.size() == s.wege.size(), "Wege: %d Bänder/Fahrlinien" % s.wege.size())
	ok(s.strassen.knoten.any(func(k): return k["typ"] == "kreuzung"), "mindestens 1 Kreuzungsstück (%d Knoten)" % s.strassen.knoten.size())
	ok(s.strassen.bruecken.size() >= 1, "mindestens 1 Steinbogenbrücke (%d)" % s.strassen.bruecken.size())
	var typen := {}
	for it in s.instanzen:
		typen[it["typ"]] = true
	ok(s.platzhalter.mmis.size() + s.platzhalter.flaechen.size() == typen.size(), "MultiMesh bzw. Flächen-Mesh je Typ: %d Typen (%d Flächen), %d Instanzen" % [typen.size(), s.platzhalter.flaechen.size(), s.instanzen.size()])
	var fl_ok := true
	for ft in s.platzhalter.flaechen:
		var mi: MeshInstance3D = s.platzhalter.flaechen[ft]
		var arr := mi.mesh.surface_get_arrays(0)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		for k in range(0, vs.size(), 7):
			if absf(vs[k].y - s.hoehe_at(vs[k].x, vs[k].z) - 0.08) > 0.01:
				fl_ok = false
	ok(fl_ok and s.platzhalter.flaechen.size() >= 5, "Flächen flaeche_* liegen am Gelände (+0,08 m), 1 Mesh je Typ")
	ok(s.platzhalter.unbekannt.is_empty(), "keine unbekannten Typen %s" % str(s.platzhalter.unbekannt))
	ok(s.welt_epoche.get("epoche_id", "") == "W1" and s.startjahr == 1820, "Startjahr %d, Epoche %s (Datenhülle)" % [s.startjahr, s.welt_epoche.get("epoche_id", "")])
	# Presets und Kamera-Klemme
	var namen_ok := true
	for n in range(1, 6):
		_key(KEY_0 + n)
		var d: float = s.kamera_abstand()
		if s.preset_aktiv != n or d < 40.0 or d > 3000.0:
			namen_ok = false
		var cam_y: float = s.cam.global_position.y
		var boden: float = s.hoehe_at(s.cam.global_position.x, s.cam.global_position.z)
		if cam_y < boden + 7.9:
			namen_ok = false
	ok(namen_ok, "Tasten 1–5 setzen die Presets (Abstand 40 m–3 km, Kamera ≥ 8 m über Gelände)")
	_key(KEY_1)
	ok(is_equal_approx(s.kamera_abstand(), 3000.0), "Preset 1 Übersicht = 3 km")
	s.abstand = 5.0
	s._kamera_anwenden()
	ok(is_equal_approx(s.kamera_abstand(), 40.0), "Zoom-Klemme unten 40 m")
	s.abstand = 99999.0
	s._kamera_anwenden()
	ok(is_equal_approx(s.kamera_abstand(), 3000.0), "Zoom-Klemme oben 3 km")
	ok(absf(s.pitch_for(40.0) - 36.0) < 0.01 and s.pitch_for(3000.0) > 55.0, "Neigung nach Abstand wie im Spiel (36° nah, %.1f° bei 3 km)" % s.pitch_for(3000.0))
	# Schalter
	_key(KEY_V)
	ok(s.wasser_modus == "B" and signale.get("wasser", "") == "B", "V: Wasser A → B (Hook + Signal)")
	_key(KEY_V)
	ok(s.wasser_modus == "A", "V: zurück auf A")
	ok(s.easing_an, "Easing startet an (Welle 2)")
	_key(KEY_G)
	ok(not s.easing_an and signale.get("easing", true) == false and (s.fahrzeuge == null or not s.fahrzeuge.easing_an),
		"G: Easing aus (Hook + Signal, Fahrzeuge folgen)")
	_key(KEY_G)
	ok(s.easing_an and signale.get("easing", false) == true, "G: Easing wieder an")
	# Welle 2: Sim-Kette + Fahrzeuge in der Szene
	ok(s.proto_sim != null and s.proto_sim.kette_ok, "Sim-Kette Farm → Mühle → Dorf aufgebaut (%s)" % (str(s.proto_sim.fehler) if s.proto_sim != null else "keine Sim"))
	var tk0: int = s.proto_sim.ticks if s.proto_sim != null else 0
	for i in 30:
		s.sim_schritt(1.0 / 60.0)
	ok(s.proto_sim != null and s.proto_sim.ticks - tk0 == 5, "Sim tickt mit 10 Hz unabhängig vom Frame (30 Frames à 1/60 s → %d Ticks)" % (s.proto_sim.ticks - tk0 if s.proto_sim != null else -1))
	_key(KEY_F)
	ok(s.folgen == 0, "F: Kamera folgt Fuhrwerk 1")
	_key(KEY_F)
	_key(KEY_F)
	_key(KEY_F)
	ok(s.folgen == -1, "F: nach dem letzten Fahrzeug wieder frei")
	_key(KEY_T)
	ok(is_equal_approx(s.sim_tempo, 0.25), "T: Bildtempo ¼×")
	_key(KEY_T)
	ok(is_equal_approx(s.sim_tempo, 1.0), "T: Bildtempo 1×")
	var z_an: Dictionary = s.zaehlung()
	_key(KEY_M)
	var z_aus: Dictionary = s.zaehlung()
	ok(not s.modelle_an and not s.modelle_root.visible and signale.get("modelle", true) == false, "M: Modelle aus (Zeichentest)")
	ok(z_aus["dreiecke"] < z_an["dreiecke"] and z_aus["objekte"] < z_an["objekte"],
		"Modelle aus senkt Dreiecke %d → %d, Objekte %d → %d" % [z_an["dreiecke"], z_aus["dreiecke"], z_an["objekte"], z_aus["objekte"]])
	_key(KEY_M)
	ok(s.modelle_an, "M: Modelle wieder an")
	# Fahrlinie am Szenen-Band (Schnittstelle für Easing)
	var fl = s.strassen.fahrlinien[0]
	var p: Vector3 = fl.strecke_punkt(fl.laenge * 0.5)
	ok(fl.laenge > 0.0 and absf(p.y - s.hoehe_at(p.x, p.z)) < 15.0, "Fahrlinie 0: L %.0f m, Punkt auf Band-Höhe" % fl.laenge)
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)
