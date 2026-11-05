extends SceneTree
## WA-02 (TA): Messskript Bodentextur/Relief, TEIL 1 = Aufnahme (Godot). Teil 2 = Auswertung `wa02_auswertung.py`.
## Alles zusammen: `bash tests/wa02_bodenmetrik.sh <out_dir>` (xvfb + opengl3 + llvmpipe, ca. 1-2 min).
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice -s res://tests/wa02_bodenmetrik.gd -- <out_dir>
##
## Was passiert (Definitionen: sprints/s8/umsetzung/WA-02.md):
##  - Welt geladen, Sim auf Pause (sim_tempo 0, Tick 0), Engine.time_scale = 0 (Shader-TIME steht -> Wasser/Boote eingefroren).
##    Damit sind zwei Laeufe bildgleich; Frametime ist reine Wanduhr.
##  - Je Standpunkt (5 Presets + Markt-Ufer + 2 Ackerraender): (A) Frametime mit allem an (Modelle, Baeume, Wege, HUD),
##    (B) Ortho-Senkrechtshot 1 px = 1 m (Treppenmetrik), Modelle/Baeume/Wege/Schilder aus.
##  - Wiesenstandpunkte (40 m, 120 m) + Preset 1 (3 km): Perspektivshot ohne Modelle; gueltige 64x64-Fenster (Wiese, >= 16 m vom
##    Klassenrand, kein Wasser) per Strahl auf das Gelaende bestimmt -> Detail-/Kachelmetrik.
##  - Hang: ein Ortho-Shot 2,5 m/px (Kern + Rand), dazu Gelaendedaten (Wiese-innen, Hang x/z) in 15-m-Stichproben.
## Schreibt <out_dir>/meta.json, <out_dir>/img/*.png, <out_dir>/hang_daten.f32.

## Bildgroesse = tatsaechliche Fenstergroesse (Projektstandard 1600x900; root.size laesst sich unter xvfb nicht aendern)
var W := 1600
var H := 900
const FT_WARM := 5
const FT_N := 20
const HANG_MPP := 2.5
const STICH_PX := 6                    # Stichprobenabstand der Hangmaske in Pixeln (= 15 m)
const FENSTER := 64
const RAND_M := 16.0                   # Mindestabstand der Fenster zum Klassenrand (Rauschversatz +-11 m)
const BAUM_BEREICH_NODE := "Baeume"

## Fest: Preset 1-5 kommen aus der Welt (setze_preset), die uebrigen aus ziel/abstand/gier.
## Koordinaten lokal (m): Ursprung NW-Ecke Kern, +x Ost, +z Sued. Herkunft: Standortsuche WA-02 (Markt-Ufer = naechstes Wasser
## zu Lindenfurt; Ackerraender = dichteste Acker/Wiese-Grenzen im Kern; Wiesen = groesste zusammenhaengende Wiese im Kern).
const STELLEN := [
	{"id": "p1_uebersicht", "preset": 1},
	{"id": "p2_dorf", "preset": 2},
	{"id": "p3_markt", "preset": 3},
	{"id": "p4_fluss", "preset": 4},
	{"id": "p5_see", "preset": 5},
	{"id": "markt_ufer", "ziel": Vector2(24.0, 268.0), "abstand": 160.0, "gier": 0.0},
	{"id": "acker_1", "ziel": Vector2(1900.0, 1200.0), "abstand": 160.0, "gier": 0.0},
	{"id": "acker_2", "ziel": Vector2(400.0, 1200.0), "abstand": 160.0, "gier": 0.0},
]
const WIESEN := [
	{"id": "w40_a", "ziel": Vector2(0.0, 1350.0), "abstand": 40.0, "gier": 0.0},
	{"id": "w40_b", "ziel": Vector2(1100.0, 1500.0), "abstand": 40.0, "gier": 0.0},
	{"id": "w120_a", "ziel": Vector2(0.0, 1350.0), "abstand": 120.0, "gier": 0.0},
	{"id": "w120_b", "ziel": Vector2(1100.0, 1500.0), "abstand": 120.0, "gier": 0.0},
]

var s: Node
var out := ""
var meta := {"stellen": [], "wiesen": []}
var hud_layer: CanvasLayer = null
var _t0 := 0


func _initialize() -> void:
	Engine.time_scale = 0.0
	s = load("res://proto/prototyp_welt.tscn").instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	s.sim_tempo = 0
	root.add_child(s)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _hud_finden() -> CanvasLayer:
	var n: Node = s.hud
	while n != null and not (n is CanvasLayer):
		n = n.get_parent()
	return n as CanvasLayer


## Szene fuer Bildmessung: nur Gelaende (+ Wasser), ohne Modelle, Fahrzeuge, Baeume, Wege, Schilder, HUD.
func _isoliert(an: bool) -> void:
	s.setze_modelle(not an)
	s.setze_schilder(not an)
	s.wege_root.visible = not an
	if s.fahrzeuge is Node3D:
		(s.fahrzeuge as Node3D).visible = not an
	var b: Node = s.terrain.get_node_or_null(BAUM_BEREICH_NODE)
	if b is Node3D:
		(b as Node3D).visible = not an
	if hud_layer != null:
		hud_layer.visible = not an


func _kamera(st: Dictionary) -> void:
	s.cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	if st.has("preset"):
		s.setze_preset(int(st["preset"]))
	else:
		var z: Vector2 = st["ziel"]
		s.folgen = -1
		s.ziel = Vector3(z.x, 0, z.y)
		s.abstand = float(st["abstand"])
		s.gier = float(st["gier"])
		s._kamera_anwenden()


func _kam_info() -> Dictionary:
	var c: Camera3D = s.cam
	var o := c.global_position
	return {"cam_pos": [o.x, o.y, o.z], "ziel": [s.ziel.x, s.ziel.y, s.ziel.z], "abstand": s.abstand, "gier_rad": s.gier,
		"pitch_grad": s.pitch_for(s.abstand), "fov": c.fov, "near": c.near, "far": c.far}


func _speichern(img: Image, name: String) -> void:
	img.save_png(out.path_join("img").path_join(name + ".png"))


func _bild() -> Image:
	return root.get_viewport().get_texture().get_image()


# ------------------------------------------------------------------ Frametime

## CPU-Zeit (utime + stime) dieses Prozesses in ms aus /proc/self/stat (nur Linux, 10-ms-Aufloesung); -1 sonst.
## llvmpipe rastert auf der CPU: CPU-ms je Frame ist weniger lastempfindlich als die Wanduhr (andere Prozesse auf dem Rechner).
func _cpu_ms() -> float:
	var f := FileAccess.open("/proc/self/stat", FileAccess.READ)
	if f == null:
		return -1.0
	var t := f.get_line()           # procfs meldet Laenge 0: nicht get_as_text/get_file_as_string, sondern zeilenweise lesen
	f.close()
	var teile := t.substr(t.rfind(")") + 2).split(" ")
	if teile.size() < 13:
		return -1.0
	return (float(teile[11]) + float(teile[12])) * 10.0           # Felder 14/15 (utime/stime) = Index 11/12 nach ")" + Leerzeichen; Tick = 10 ms


func _frametime() -> Dictionary:
	await _frames(FT_WARM)
	var ms: Array = []
	var cpu0 := _cpu_ms()
	var t_prev := Time.get_ticks_usec()
	for i in FT_N:
		await process_frame
		var t := Time.get_ticks_usec()
		ms.append((t - t_prev) / 1000.0)
		t_prev = t
	var cpu1 := _cpu_ms()
	var z: Dictionary = s.zaehlung()
	var sorted := ms.duplicate()
	sorted.sort()
	var summe := 0.0
	for v in ms:
		summe += v
	return {"ms_median": sorted[sorted.size() / 2], "ms_mean": summe / ms.size(), "ms_min": sorted[0],
		"ms_p90": sorted[int(sorted.size() * 0.9)], "ms_max": sorted[sorted.size() - 1],
		"cpu_ms_je_frame": (cpu1 - cpu0) / FT_N if cpu0 >= 0.0 else -1.0,
		"live_dreiecke": z["live_dreiecke"], "live_dc": z["live_dc"]}


# ------------------------------------------------------------------ Ortho-Senkrechtshot

## Ortho nach unten, Bild oben = Norden (-z), 1 Pixel = mpp Meter. Gibt Bild zurueck.
func _ortho(mitte: Vector2, mpp: float) -> Image:
	var c: Camera3D = s.cam
	var alt_far := c.far
	var alt_near := c.near
	c.projection = Camera3D.PROJECTION_ORTHOGONAL
	c.keep_aspect = Camera3D.KEEP_HEIGHT
	c.size = float(H) * mpp
	c.near = 10.0
	c.far = 1500.0
	c.global_transform = Transform3D(Basis.from_euler(Vector3(-PI * 0.5, 0, 0)), Vector3(mitte.x, 900.0, mitte.y))
	var fog_alt: bool = s.env.fog_enabled
	var schatten_alt: float = s.sun.directional_shadow_max_distance
	s.env.fog_enabled = false
	s.sun.directional_shadow_max_distance = 2500.0
	await _frames(4)
	var img := _bild()
	s.env.fog_enabled = fog_alt
	s.sun.directional_shadow_max_distance = schatten_alt
	c.projection = Camera3D.PROJECTION_PERSPECTIVE
	c.near = alt_near
	c.far = alt_far
	return img


# ------------------------------------------------------------------ Fenster auf Wiese (Perspektive)

## Schnittpunkt Strahl/Gelaende (Marsch + Bisektion); Vector3.INF wenn kein Treffer innerhalb far.
func _gelaende_treffer(o: Vector3, d: Vector3, far: float) -> Vector3:
	var t := 0.0
	var vorher := 0.0
	while t < far:
		var p := o + d * t
		if p.y < s.hoehe_at(p.x, p.z):
			var lo := vorher
			var hi := t
			for i in 10:
				var m := (lo + hi) * 0.5
				var q := o + d * m
				if q.y < s.hoehe_at(q.x, q.z):
					hi = m
				else:
					lo = m
			return o + d * hi
		vorher = t
		t += maxf(1.5, t * 0.01)
	return Vector3.INF


func _wiese_innen(x: float, z: float) -> bool:
	var tr = s.terrain
	for off in [Vector2.ZERO, Vector2(RAND_M, 0), Vector2(-RAND_M, 0), Vector2(0, RAND_M), Vector2(0, -RAND_M)]:
		if tr.boden_at(x + off.x, z + off.y) != 0:
			return false
	return not tr.ist_wasser(x, z)


func _gueltige_fenster() -> Array:
	var c: Camera3D = s.cam
	var gueltig: Array = []
	var nx := W / FENSTER
	var ny := H / FENSTER
	for wy in ny:
		for wx in nx:
			var ok := true
			for gy in 3:
				for gx in 3:
					if not ok:
						break
					var px := wx * FENSTER + gx * (FENSTER - 1) / 2.0
					var py := wy * FENSTER + gy * (FENSTER - 1) / 2.0
					var sp := Vector2(px, py)
					var hit := _gelaende_treffer(c.project_ray_origin(sp), c.project_ray_normal(sp), c.far)
					if hit == Vector3.INF or not _wiese_innen(hit.x, hit.z):
						ok = false
			if ok:
				gueltig.append([wx, wy])
	return gueltig


# ------------------------------------------------------------------ Hangdaten

func _hangdaten(mitte: Vector2, mpp: float) -> void:
	var nx := W / STICH_PX
	var ny := H / STICH_PX
	var arr := PackedFloat32Array()
	arr.resize(nx * ny * 3)
	var tr = s.terrain
	var i := 0
	for j in ny:
		for k in nx:
			var px := (k + 0.5) * STICH_PX
			var py := (j + 0.5) * STICH_PX
			var x := mitte.x + (px - W * 0.5) * mpp
			var z := mitte.y + (py - H * 0.5) * mpp
			var innen := 1.0 if _wiese_innen(x, z) else 0.0
			var hx: float = (tr.hoehe_at(x + 25.0, z) - tr.hoehe_at(x - 25.0, z)) / 50.0
			var hz: float = (tr.hoehe_at(x, z + 25.0) - tr.hoehe_at(x, z - 25.0)) / 50.0
			arr[i] = innen
			arr[i + 1] = hx
			arr[i + 2] = hz
			i += 3
	var f := FileAccess.open(out.path_join("hang_daten.f32"), FileAccess.WRITE)
	f.store_buffer(arr.to_byte_array())
	f.close()


# ------------------------------------------------------------------ Ablauf

func _run() -> void:
	await _frames(3)
	s.set_process(false)
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://wa02"
	DirAccess.make_dir_recursive_absolute(out.path_join("img"))
	hud_layer = _hud_finden()
	var vs0 := root.get_viewport().get_visible_rect().size
	W = int(vs0.x)
	H = int(vs0.y)
	_t0 = Time.get_ticks_msec()
	for a in args:                                   # Test fuer WA-03b: --sonne=<pitch>,<yaw> (Grad) ueberschreibt die Sonnenrichtung
		if a.begins_with("--sonne="):
			var p := a.substr(8).split(",")
			s.sun.rotation_degrees = Vector3(float(p[0]), float(p[1]), 0.0)
	var vs := root.get_viewport().get_visible_rect().size
	meta["fenster_px"] = [int(vs.x), int(vs.y)]
	meta["godot"] = Engine.get_version_info().get("string", "?")
	meta["renderer"] = str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "?"))
	meta["adapter"] = RenderingServer.get_video_adapter_name()
	meta["sim_tick"] = s.proto_sim.ticks if s.proto_sim != null else -1
	meta["time_scale"] = Engine.time_scale
	var sd: Vector3 = -s.sun.global_transform.basis.z       # Richtung, in die das Licht laeuft
	meta["sonne_laufrichtung"] = [sd.x, sd.y, sd.z]
	meta["sonne_rot_grad"] = [s.sun.rotation_degrees.x, s.sun.rotation_degrees.y, s.sun.rotation_degrees.z]
	meta["sonne_energie"] = s.sun.light_energy
	meta["umgebung_energie"] = s.env.ambient_light_energy
	meta["ladezeit_ms"] = s.lade_ms
	meta["build_hash"] = (load("res://proto/stelle_merken.gd") as Script).call("_build_hash")
	meta["viewport_px"] = [W, H]
	# 1) Frametime + Ortho je Standpunkt
	for st in STELLEN:
		_isoliert(false)
		_kamera(st)
		var info := _kam_info()
		info["id"] = st["id"]
		info["frametime"] = await _frametime()
		var mitte := Vector2(info["ziel"][0], info["ziel"][2])
		_isoliert(true)
		var oimg := await _ortho(mitte, 1.0)
		_speichern(oimg, "ortho_" + st["id"])
		info["ortho_mitte"] = [mitte.x, mitte.y]
		info["ortho_mpp"] = 1.0
		# Perspektivbild ohne Modelle nur fuer Preset 1 (Detail bei 3 km)
		if st["id"] == "p1_uebersicht":
			_kamera(st)
			await _frames(3)
			_speichern(_bild(), "persp_" + st["id"])
			var cam_info := _kam_info()
			info["fenster"] = _gueltige_fenster()
			info["persp_cam"] = cam_info
		meta["stellen"].append(info)
		print("STELLE %-14s median %.1f ms  p90 %.1f  (%d Dreiecke, %d DC)  %.0f s" % [st["id"], info["frametime"]["ms_median"],
			info["frametime"]["ms_p90"], info["frametime"]["live_dreiecke"], info["frametime"]["live_dc"], (Time.get_ticks_msec() - _t0) / 1000.0])
	# 2) Wiesenstandpunkte (Perspektive, isoliert)
	_isoliert(true)
	for st in WIESEN:
		_kamera(st)
		await _frames(4)
		_speichern(_bild(), "persp_" + st["id"])
		var info := _kam_info()
		info["id"] = st["id"]
		info["fenster"] = _gueltige_fenster()
		meta["wiesen"].append(info)
		print("WIESE %-8s gueltige 64er-Fenster: %d  %.0f s" % [st["id"], info["fenster"].size(), (Time.get_ticks_msec() - _t0) / 1000.0])
	# 3) Hang: Ortho 2,5 m/px ueber den Kern
	var hm := Vector2(1000.0, 800.0)
	var himg := await _ortho(hm, HANG_MPP)
	_speichern(himg, "ortho_hang")
	_hangdaten(hm, HANG_MPP)
	meta["hang"] = {"mitte": [hm.x, hm.y], "mpp": HANG_MPP, "stich_px": STICH_PX, "nx": W / STICH_PX, "ny": H / STICH_PX}
	# Zustand wiederherstellen und schreiben
	_isoliert(false)
	meta["dauer_s"] = (Time.get_ticks_msec() - _t0) / 1000.0
	var f := FileAccess.open(out.path_join("meta.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  "))
	f.close()
	print("WA02_AUFNAHME fertig in %.1f s -> %s" % [meta["dauer_s"], out])
	quit(0)
