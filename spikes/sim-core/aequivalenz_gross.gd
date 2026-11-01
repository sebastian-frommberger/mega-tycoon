extends SceneTree
## F-10 Äquivalenz in Bench-Größe (Sandbox, einmalig): SoA-Kern gegen unveränderten Spike-Kern (res://ref/)
## auf der Bench-Welt (bench_world.gd, Seed 1001 + n), 300 + 3000 Ticks. Prüfsumme alle 100 Ticks und am Ende,
## deadlock_events am Ende; ereignisgesteuerte Zyklen == Vollscan in jedem Tick. Exit 0 nur bei Gleichheit.
## Aufruf: godot --headless --path . --script res://aequivalenz_gross.gd -- [--vehicles=5000,10000]
const BenchWorld := preload("res://bench_world.gd")
const RefBenchWorld := preload("res://ref/bench_world.gd")

func _init() -> void:
	var sizes: Array = [5000, 10000]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--vehicles="):
			sizes = Array(a.split("=")[1].split(",")).map(func(x): return int(x))
	var ok_all := true
	for nv in sizes:
		var sim = BenchWorld.new().build(nv, 1001 + nv)["sim"]
		var ref = RefBenchWorld.new().build(nv, 1001 + nv)["sim"]
		var eq := true
		var ev := true
		var checks := 0
		for t in range(3300):
			sim.step()
			ref.step()
			if sim.tick_count % 100 == 0:
				checks += 1
				if sim.checksum() != ref.checksum():
					eq = false
			if JSON.stringify(sim.active_cycles()) != JSON.stringify(sim.find_wait_cycles_full()):
				ev = false
		var evs: bool = JSON.stringify(sim.deadlock_events) == JSON.stringify(ref.deadlock_events)
		var ok: bool = eq and ev and evs and sim.checksum() == ref.checksum()
		ok_all = ok_all and ok
		print("%dk: Prüfsumme (%d Vergleiche) %s, End-Prüfsumme SoA %d / Spike %d, Ereignisse SoA %d / Spike %d (%s), Ereignisprüfung = Vollscan je Tick: %s, Ereignisse: %s" % [
			nv / 1000, checks, "gleich" if eq else "ABWEICHEND", sim.checksum(), ref.checksum(), sim.deadlock_events.size(), ref.deadlock_events.size(),
			"gleich" if evs else "ABWEICHEND", "ja" if ev else "NEIN", JSON.stringify(sim.deadlock_events)])
	print("ERGEBNIS: %s" % ("GLEICH (Exit 0)" if ok_all else "ABWEICHUNG (Exit 1)"))
	quit(0 if ok_all else 1)
