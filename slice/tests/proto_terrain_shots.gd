extends SceneTree
## Phase 4 W1 (TA): Bilder + Zaehlwerte der Prototyp-Welt (ProtoTerrain allein, ohne Orte).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/proto_terrain_shots.gd -- <out_dir> [b]
## Bilder: proto_uebersicht (ganze Karte 4 x 3,6 km), proto_kern (Kern 2 x 1,6 km), proto_mittel (900 m, See + Bach + Muehlteich),
## proto_see_nah (160 m, Ufer G2), proto_bach_nah (220 m), proto_muehlteich (260 m), proto_dorfteich (120 m).
## Je Bild: Dreiecke, Draw Calls (RenderingServer, ganzes Bild), Kameraabstand. Zweites Argument "b" = Wasser-Variante B.

const DATEN := "res://world/data/proto"

var welt: Node3D
var cam: Camera3D
var terr: ProtoTerrain
var zeilen: Array = []


func _initialize() -> void:
	welt = Node3D.new()
	root.add_child(welt)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.76, 0.84, 0.91)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.82, 0.88)
	e.ambient_light_energy = 0.55
	e.fog_enabled = true
	e.fog_light_color = Color(0.76, 0.84, 0.91)
	e.fog_density = 0.00003
	env.environment = e
	welt.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.05
	welt.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 40.0
	cam.near = 1.0
	cam.far = 20000.0
	welt.add_child(cam)
	cam.current = true
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _kamera(ziel_xz: Vector2, abstand: float, neigung_grad: float, gier_grad := 0.0) -> void:
	var y := terr.hoehe_at(ziel_xz.x, ziel_xz.y)
	var ziel := Vector3(ziel_xz.x, y, ziel_xz.y)
	var n := deg_to_rad(neigung_grad)
	var g := deg_to_rad(gier_grad)
	var dir := Vector3(sin(g) * cos(n), sin(n), cos(g) * cos(n))
	cam.position = ziel + dir * abstand
	cam.look_at(ziel, Vector3.UP)


func _shot(out: String, name: String, abstand: float) -> void:
	await _frames(8)
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	var tris := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var obj := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	var z := "%s  Dreiecke %d  DrawCalls %d  Objekte %d  Kamera %.0f m" % [name, tris, dc, obj, abstand]
	print(z)
	zeilen.append(z)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://"
	DirAccess.make_dir_recursive_absolute(out)
	var t0 := Time.get_ticks_usec()
	terr = ProtoTerrain.bauen(welt, DATEN)
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	if args.size() > 1 and args[1] == "b":
		terr.wasser_variante_b(true)
	print("Ladezeit ProtoTerrain.bauen %.0f ms  %s" % [ms, JSON.stringify(terr.stats)])
	zeilen.append("Ladezeit %.0f ms %s" % [ms, JSON.stringify(terr.stats)])
	var sfx := "_b" if args.size() > 1 and args[1] == "b" else ""
	_kamera(Vector2(1000, 800), 5200.0, 58.0, 0.0)
	await _shot(out, "proto_uebersicht" + sfx, 5200.0)
	_kamera(Vector2(1000, 800), 2900.0, 52.0, 0.0)
	await _shot(out, "proto_kern" + sfx, 2900.0)
	_kamera(Vector2(1380, 1000), 900.0, 45.0, 20.0)
	await _shot(out, "proto_mittel" + sfx, 900.0)
	var see: Dictionary = terr.see["see"]
	var sm := Vector2(see["mitte_m"][0], see["mitte_m"][1])
	_kamera(sm + Vector2(-60, 245), 160.0, 34.0, 0.0)
	await _shot(out, "proto_see_nah" + sfx, 160.0)
	_kamera(Vector2(1462.5, 760), 220.0, 40.0, -60.0)
	await _shot(out, "proto_bach_nah" + sfx, 220.0)
	var mt: Dictionary = terr.see["muehlteich"]
	_kamera(Vector2(mt["mitte_m"][0], mt["mitte_m"][1]), 260.0, 42.0, 30.0)
	await _shot(out, "proto_muehlteich" + sfx, 260.0)
	var dt: Dictionary = terr.see["dorfteich"]
	_kamera(Vector2(dt["mitte_m"][0], dt["mitte_m"][1]), 120.0, 40.0, 20.0)
	await _shot(out, "proto_dorfteich" + sfx, 120.0)
	# Perf-Worst-Case: flacher Blick ueber den Wald im Westen, Baumchunks bis 2.000 m sichtbar
	_kamera(Vector2(600, 1100), 1400.0, 30.0, 135.0)
	await _shot(out, "proto_perf_wald" + sfx, 1400.0)
	var f := FileAccess.open(out.path_join("proto_terrain_shots%s.txt" % sfx), FileAccess.WRITE)
	for z in zeilen:
		f.store_line(z)
	f.close()
	quit(0)
