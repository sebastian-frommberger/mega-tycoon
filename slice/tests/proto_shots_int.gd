extends SceneTree
## Phase 4 Integration Welle 2 (Felix, Lead): Bilder der fertigen Szene (Prefabs, Kulissen, Schilder, Fahrzeuge).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_shots_int.gd -- <out_dir>
## int_preset_1..5: Kamera-Presets Übersicht, Dorf, Markt, Fluss, See (Schilder an, Sim vorgespult, Fuhrwerke unterwegs);
## int_fuhrwerk_nah: Kamera folgt Fuhrwerk 1 auf der Straße; int_floss_nah: Floß treibend im Kern;
## int_hasenwinkel_nah: Weiler-Schild (≤ 500 m); int_muehle_nah: Plakette Erlenmühle; int_schilder_aus: Preset 2 mit N.
## Zählwerte je Bild -> <out_dir>/int_perf.txt

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
	s.folgen = -1
	s.ziel = Vector3(ziel.x, 0, ziel.y)
	s.abstand = abstand
	s.gier = deg_to_rad(gier_grad)
	s._kamera_anwenden()


func _shot(out: String, name: String) -> void:
	await _frames(8)
	s._hud_text()                        # HUD-Zählung nach dem Rendern dieser Ansicht
	await _frames(2)
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	var z: Dictionary = s.zaehlung()
	var zl := "%-22s live %8d Dreiecke / %3d DC   gezählt %8d   Abstand %4.0f m" % [name, z["live_dreiecke"], z["live_dc"],
		z["dreiecke"], s.abstand]
	print(zl)
	zeilen.append(zl)


## Sim bis Tick t vorspulen, dann Fahrzeuge mit festem Δt einschwingen (wie proto_shots_w2).
func _bis(t: int) -> void:
	while s.proto_sim.ticks < t:
		s.proto_sim.tick()
	for i in 30:
		s.fahrzeuge.frame(0.5, 1.0 / 6.0)


func _run() -> void:
	await _frames(2)
	s.set_process(false)                 # Sim nur über _bis (deterministische Bilder); Schilder/Kulissen laufen weiter
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://int_w2"
	DirAccess.make_dir_recursive_absolute(out)
	zeilen.append("Ladezeit Szene %.0f ms, Stufen %s" % [s.lade_ms, str(s.lade_stufen)])
	var k = s.kulissen
	# Floß in den Kern (x ≈ 1880, treibend), Sim so weit, dass Fuhrwerke zwischen Halten fahren
	k.zeit_setzen(5.0 + (2450.0 - 1880.0) / 1.5)
	# vorspulen, bis Fuhrwerk 1 beladen unterwegs ist (Mitte der Fahrt, nicht am Halt)
	var t := 0
	while t < 3000 and not String(s.proto_sim.zustand_text(s.proto_sim.fahrzeuge[0])).contains("fährt"):
		s.proto_sim.tick()
		t += 1
	_bis(s.proto_sim.ticks + 12)
	zeilen.append("Sim-Tick %d: %s" % [s.proto_sim.ticks, s.proto_sim.zustand_text(s.proto_sim.fahrzeuge[0])])
	for n in range(1, 6):
		s.setze_preset(n)
		await _shot(out, "int_preset_%d_%s" % [n, ["", "uebersicht", "dorf", "markt", "fluss", "see"][n]])
	# Fuhrwerk 1 auf der Straße (Kamera folgt, 70 m)
	var z = s.proto_sim.fahrzeuge[0]["zustand"]
	_kamera(Vector2(z.pos.x, z.pos.z), 70.0, rad_to_deg(z.gier) + 135.0)
	await _shot(out, "int_fuhrwerk_nah")
	var z2 = s.proto_sim.fahrzeuge[2]["zustand"]
	_kamera(Vector2(z2.pos.x, z2.pos.z), 80.0, rad_to_deg(z2.gier) + 120.0)
	await _shot(out, "int_postkutsche_nah")
	var fp: Vector3 = k.floss.global_position
	_kamera(Vector2(fp.x, fp.z), 60.0, 210.0)
	await _shot(out, "int_floss_nah")
	_kamera(Vector2(759.8, 856.5), 300.0, 20.0)
	await _shot(out, "int_hasenwinkel_nah")
	_kamera(Vector2(1617, 1090), 180.0, 140.0)
	await _shot(out, "int_muehle_nah")
	s.setze_preset(2)
	s.setze_schilder(false)
	await _shot(out, "int_preset_2_schilder_aus")
	s.setze_schilder(true)
	var f := FileAccess.open(out.path_join("int_perf.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(zeilen)) + "\n")
		f.close()
	quit(0)
