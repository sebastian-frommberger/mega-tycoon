extends SceneTree
## S6 (Felix): Profil der Frame-Bausteine nach Bench-Setup (headless, Sandbox-Zeiten nur relativ).
## Aufruf: godot --headless --path . -s res://tests/prof_s6.gd -- --bench-units=5000 [--frames=300]
var m
var frames := 300
var acc := {}
var samples := {}

func _t(name: String, c: Callable) -> void:
	var t0 := Time.get_ticks_usec()
	c.call()
	var d := Time.get_ticks_usec() - t0
	if not samples.has(name):
		samples[name] = []
	samples[name].append(d)

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames = int(a.substr(9))
	_run.call_deferred()

func _run() -> void:
	var Bench = load("res://bench.gd")
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	var b = Bench.new()
	m.bench = b
	m.add_child(b)
	b.start(m)
	print("PROF Fahrzeuge %d, Kern %s" % [m.vehicles.size(), m.vehicle_core])
	for i in 20:
		m.sim_tick()
	for i in frames:
		_t("sim_tick", m.sim_tick)
		_t("render_vehicles", m._render_vehicles)
		for q in 4:
			_t("render_step (je Frame)", m.fleet.render_step)
		_t("refresh_labels", m._refresh_labels)
		_t("refresh_panel", m._refresh_panel)
		if i % 4 == 0:
			_t("refresh_lines", m._refresh_lines)
		_t("update_label_lod", m._update_label_lod)
		_t("update_hud", func(): m._update_hud(0))
	# Teilzeiten im Kern
	var ks := []
	var kv := []
	for i in 100:
		m.sim_tick()
		ks.append(m.shim.profile_usec.get("total", 0))
		kv.append(m.shim.profile_usec.get("economy", 0))
	samples["kern.total(profile_usec)"] = ks
	samples["kern.economy(profile_usec)"] = kv
	var keys := samples.keys()
	for k in keys:
		var a: Array = samples[k]
		a.sort()
		var s := 0
		for x in a: s += x
		print("PROF %-28s n=%4d  median %7.2f ms  p95 %7.2f ms  max %7.2f ms  mittel %7.2f ms" % [k, a.size(),
			a[a.size() / 2] / 1000.0, a[int(a.size() * 0.95)] / 1000.0, a[-1] / 1000.0, s / 1000.0 / a.size()])
	quit(0)
