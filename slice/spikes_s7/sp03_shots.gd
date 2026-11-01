extends SceneTree
## SP-03: Screenshots + Performance-Monitor + Randprüfung. Aufruf: xvfb-run ... -s res://spikes_s7/sp03_shots.gd -- <outdir>
var s: Node
func _initialize() -> void:
	s = load("res://spikes_s7/scale_terrain.tscn").instantiate()
	root.add_child(s)
	_run.call_deferred()
func _frames(n: int) -> void:
	for i in n:
		await process_frame
func _perf(tag: String) -> void:
	await _frames(20)
	print("SP03 perf %s draw_calls=%d objects=%d primitives=%d vmem_mb=%.0f fps=%.1f border=%s" % [tag,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.TIME_FPS), str(s.border_check())])
func _shot(out: String, name: String) -> void:
	await _perf(name)
	root.get_viewport().get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("saved ", name)
func _run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var only := OS.get_cmdline_user_args()[1] if OS.get_cmdline_user_args().size() > 1 else ""
	var views := [
		["sp03_uebersicht", Vector2(6600, 5500), 15.0, 4300.0, -1.0],
		["sp03_stadt_nah", s.CITY_C + Vector2(40, 120), 22.0, 700.0, 40.0],
		["sp03_stadt_strasse", s.CITY_C + Vector2(60, 60), 30.0, 160.0, 38.0],
		["sp03_rand_max_nw", Vector2(0, 0), 45.0, 99999.0, -1.0],
		["sp03_rand_max_ost", Vector2(12800, 7000), -90.0, 99999.0, -1.0],
		["sp03_mine", s.MINE_P + Vector2(-60, 40), 30.0, 420.0, -1.0],
		["sp03_farm", s.FARM_P + Vector2(200, 120), -20.0, 900.0, -1.0],
	]
	for v in views:
		if only != "" and not String(v[0]).contains(only):
			continue
		s.set_view(v[1], v[2], v[3], v[4])
		await _shot(out, v[0])
	# Randprüfung: max. Zoom an allen Ecken/Kantenmitten, 8 Blickrichtungen
	var worst := 0.0
	var miss := 0
	for p in [Vector2(0, 0), Vector2(12800, 0), Vector2(0, 12800), Vector2(12800, 12800), Vector2(6400, 0), Vector2(0, 6400)]:
		for k in 8:
			s.set_view(p, k * 45.0, 99999.0)
			await process_frame
			var r: Dictionary = s.border_check()
			worst = maxf(worst, r["max_out_m"])
			miss += r["miss"]
	print("SP03 border sweep: max Bodentreffer ausserhalb spielbarer Flaeche = %.0f m (Rand %.0f m), Fehltreffer=%d" % [worst, s.B, miss])
	quit(0)
