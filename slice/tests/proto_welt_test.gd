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
	s.schilder_geaendert.connect(func(a): signale["schilder"] = a)
	s.tempo_geaendert.connect(func(t): signale["tempo"] = t)
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
		if not (String(it["typ"]) in ProtoKulissen.TYPEN_SELBST):
			typen[ProtoPrefabs.schluessel(it)] = true
	ok(s.platzhalter.mmis.size() + s.platzhalter.flaechen.size() == typen.size(), "MultiMesh bzw. Flächen-Mesh je Schlüssel (Typ/Variante, ohne Steg/Ruderboot): %d (%d Flächen), %d Instanzen" % [typen.size(), s.platzhalter.flaechen.size(), s.instanzen.size()])
	ok(s.platzhalter.prefab_typen.size() >= typen.size() - s.platzhalter.flaechen.size() and s.platzhalter.mmis_fern.size() > 0,
		"Prefabs (ProtoPrefabs) für alle Modell-Schlüssel: %d, Fern-LOD: %d" % [s.platzhalter.prefab_typen.size(), s.platzhalter.mmis_fern.size()])
	ok(s.kulissen != null, "Kulissen am Wasser (ProtoKulissen: Steg, Ruderboot, Floß)")
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
	s.sim_acc = 0.5                    # definierter Rest, sonst hängt das Ergebnis (4 oder 5) an Float-Rundung
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
	ok(is_equal_approx(s.zeitlupe, 0.25) and s.sim_tempo == 1, "T: Zeitlupe ¼× (nur Ansicht, sim_tempo bleibt 1)")
	_key(KEY_T)
	ok(is_equal_approx(s.zeitlupe, 1.0), "T: Zeitlupe aus")
	var z_an: Dictionary = s.zaehlung()
	_key(KEY_M)
	var z_aus: Dictionary = s.zaehlung()
	ok(not s.modelle_an and not s.modelle_root.visible and signale.get("modelle", true) == false, "M: Modelle aus (Zeichentest)")
	ok(z_aus["dreiecke"] < z_an["dreiecke"] and z_aus["objekte"] < z_an["objekte"],
		"Modelle aus senkt Dreiecke %d → %d, Objekte %d → %d" % [z_an["dreiecke"], z_aus["dreiecke"], z_an["objekte"], z_aus["objekte"]])
	_key(KEY_M)
	ok(s.modelle_an, "M: Modelle wieder an")
	# Integration W2: Schilder (Aylin) in der Szene, Schalter N
	var ids := {}
	if s.schilder != null:
		for e in s.schilder.liste():
			ids[e["id"]] = e["art"]
	ok(ids.get("erlenbach") == "ort" and ids.get("lindenfurt") == "ort" and ids.get("hasenwinkel") == "ort"
		and ids.get("gut_kuppenhof") == "industrie" and ids.get("erlenmuehle") == "industrie",
		"Schilder: Erlenbach, Lindenfurt, Hasenwinkel (Ort), Gut Kuppenhof, Erlenmühle (Plakette) %s" % str(ids))
	_key(KEY_N)
	ok(not s.schilder_an and not s.schilder.sichtbar and signale.get("schilder", true) == false, "N: Schilder aus (kein Modal)")
	_key(KEY_N)
	ok(s.schilder_an and s.schilder.sichtbar, "N: Schilder wieder an")
	await _at05_tempo()
	# Fahrlinie am Szenen-Band (Schnittstelle für Easing)
	var fl = s.strassen.fahrlinien[0]
	var p: Vector3 = fl.strecke_punkt(fl.laenge * 0.5)
	ok(fl.laenge > 0.0 and absf(p.y - s.hoehe_at(p.x, p.z)) < 15.0, "Fahrlinie 0: L %.0f m, Punkt auf Band-Höhe" % fl.laenge)
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)


# ------------------------------------------------------------------ AT-05: Pause, Tempo 1×/2×/4×, Datum

## Ticks, die sim_schritt bei simulierten delta-Werten liefert (Akkumulator, ohne Wanduhr, ohne Rendering).
func _sim_ticks(tempo: int, delta: float, sekunden: float) -> int:
	s.setze_tempo(tempo)
	s.sim_acc = 0.0
	var t0: int = s.proto_sim.ticks
	for i in int(round(sekunden / delta)):
		s.sim_schritt(delta)
	return s.proto_sim.ticks - t0


## Wanduhr-Messung: lässt die Szene `sekunden` lang echte Frames laufen (_process der Szene tickt selbst).
## Rückgabe: [Ticks, gemessene Sekunden, Frames]
func _wanduhr(tempo: int, sekunden: float) -> Array:
	s.setze_tempo(tempo)
	s.sim_acc = 0.0
	await process_frame
	var t0 := Time.get_ticks_usec()
	var tk0: int = s.proto_sim.ticks
	var fr := 0
	while (Time.get_ticks_usec() - t0) < int(sekunden * 1e6):
		await process_frame
		fr += 1
	var dt_s := (Time.get_ticks_usec() - t0) / 1e6
	return [s.proto_sim.ticks - tk0, dt_s, fr]


func _at05_tempo() -> void:
	print("  -- AT-05 Pause / Tempo / Datum")
	if s.proto_sim == null:
		ok(false, "AT-05: Sim fehlt")
		return
	ok(s.sim_tempo == 1 and s.TEMPI == [0, 1, 2, 4], "AT-05: Start-Tempo 1, erlaubte Stufen {0,1,2,4}")
	# Tasten 1–5 bleiben Kamera-Presets, Tempo unberührt
	s.setze_tempo(2)
	_key(KEY_3)
	ok(s.preset_aktiv == 3 and s.sim_tempo == 2, "AT-05: Taste 3 = Preset 3, Tempo bleibt 2× (Tasten 1–5 nicht belegt)")
	_key(KEY_1)
	s.setze_tempo(3)
	ok(s.sim_tempo == 2, "AT-05: ungültige Stufe 3 wird ignoriert")
	# Leertaste = Pause an/aus, zurück aufs vorherige Tempo
	_key(KEY_SPACE)
	ok(s.sim_tempo == 0 and signale.get("tempo", -1) == 0, "AT-05: Leertaste → Pause (Signal)")
	_key(KEY_SPACE)
	ok(s.sim_tempo == 2, "AT-05: Leertaste noch einmal → zurück auf 2×")
	# Knöpfe im HUD
	ok(s.tempo_knoepfe.size() == 4 and s.datum_label != null, "AT-05: HUD hat Knöpfe Pause/1×/2×/4× und Datum")
	(s.tempo_knoepfe[4] as Button).pressed.emit()
	ok(s.sim_tempo == 4 and (s.tempo_knoepfe[4] as Button).button_pressed and not (s.tempo_knoepfe[2] as Button).button_pressed, "AT-05: Knopf 4× setzt Tempo, nur er ist markiert")
	(s.tempo_knoepfe[0] as Button).pressed.emit()
	ok(s.sim_tempo == 0 and s.tempo_vor_pause == 4, "AT-05: Knopf Pause, merkt 4× für die Leertaste")
	var fokus_aus := true
	for b in s.tempo_knoepfe.values():
		fokus_aus = fokus_aus and (b as Button).focus_mode == Control.FOCUS_NONE
	ok(fokus_aus, "AT-05: alle Tempo-Knöpfe ohne Fokus (Leertaste löst nie einen Knopf aus)")
	# Datum (Platzhalter: 600 Ticks = 1 Monat ab Startjahr)
	const DT = preload("res://proto/prototyp_welt.gd")
	ok(DT.datum_text(0, 1820) == "Jan 1820" and DT.datum_text(599, 1820) == "Jan 1820" and DT.datum_text(600, 1820) == "Feb 1820"
		and DT.datum_text(7200, 1820) == "Jan 1821" and DT.datum_text(600 * 23, 1820) == "Dez 1821", "AT-05: Datum = Monat je 600 Ticks ab 1820")
	var tk: int = s.proto_sim.ticks
	s._hud_text()
	ok(s.datum_label.text == DT.datum_text(tk, s.startjahr), "AT-05: HUD zeigt das Datum (%s bei Tick %d)" % [s.datum_label.text, tk])
	# A) Akkumulator mit simulierten delta-Werten (deterministisch, ohne Wanduhr)
	var pos0: Vector3 = s.proto_sim.fahrzeuge[0]["zustand"].pos
	var n0 := _sim_ticks(0, 1.0 / 60.0, 10.0)
	var pos1: Vector3 = s.proto_sim.fahrzeuge[0]["zustand"].pos
	ok(n0 == 0 and pos1 == pos0, "AT-05 (simuliert): Pause, 600 Frames à 1/60 s → %d Ticks, Fahrzeug 0 steht (Δ %.4f m)" % [n0, pos1.distance_to(pos0)])
	for fps in [60.0, 30.0, 20.0]:
		for tempo in [1, 2, 4]:
			var n := _sim_ticks(tempo, 1.0 / fps, 10.0)
			var soll: int = 100 * int(tempo)
			ok(n <= soll and n >= soll - 1, "AT-05 (simuliert): %d× bei %d fps, 10 s → %d Ticks (Soll %d, nie darüber)" % [tempo, int(fps), n, soll])
	var n_slow := _sim_ticks(4, 0.5, 10.0)
	ok(n_slow <= 20 * s.MAX_TICKS_JE_FRAME and n_slow <= 400, "AT-05 (simuliert): 4× bei 2 fps → %d Ticks (Deckel %d je Frame, nie > 400)" % [n_slow, s.MAX_TICKS_JE_FRAME])
	# B) Wanduhr: echte Frames der Szene (headless: kein Rendering → fps nur Hinweis auf Schleifenrate)
	s.setze_tempo(0)
	var pos_vor: Vector3 = s.proto_sim.fahrzeuge[0]["zustand"].pos
	var r0: Array = await _wanduhr(0, 10.0)
	var pos2: Vector3 = s.proto_sim.fahrzeuge[0]["zustand"].pos
	ok(r0[0] == 0 and pos2 == pos_vor, "AT-05 (Wanduhr): Pause, %.1f s, %d Frames → %d Ticks, Fahrzeug steht" % [r0[1], r0[2], r0[0]])
	for tempo in [1, 2, 4]:
		var sek := 5.0 if tempo == 4 else 3.0
		var r: Array = await _wanduhr(tempo, sek)
		var rate: float = r[0] / r[1]
		var fps_m: float = r[2] / r[1]
		var soll_r: float = 10.0 * float(tempo)
		ok(fps_m >= 20.0 and absf(rate - soll_r) <= 1.0 and rate <= soll_r + 1.0,
			"AT-05 (Wanduhr): %d× → %.2f Ticks/s (Soll %.0f ± 1) bei %.0f fps, %d Ticks in %.2f s" % [tempo, rate, soll_r, fps_m, r[0], r[1]])
	s.setze_tempo(1)
