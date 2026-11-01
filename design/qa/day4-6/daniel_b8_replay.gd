extends SceneTree
## Replay Befund B8 (Daniel, D-04): get_wait_chain() stuerzt ab, wenn in der Warte-Kette ein Fahrzeug im
## Zustand WARTET_BLOCK auf einen Block wartet, dessen Halter im selben Tick freigegeben hat (holder = -1).
## Aufruf: godot --headless --path <kopie> --script res://daniel_b8_replay.gd
## Netz: Daniels Normalnetz Variante 1 (siehe daniel_d04_lauf.gd build_normal(1)), Tick 3451, Fahrzeug 1.
const Lauf := preload("res://daniel_d04_lauf.gd")
const SimWorld := preload("res://sim_world.gd")

func _init() -> void:
	var sim = Lauf.build_normal(1)
	var b8_ticks := 0
	var first := -1
	for t in range(6000):
		sim.step()
		var hit := false
		for id in sim.vehicles:
			if sim.vehicles[id]["state"] == SimWorld.VState.WARTET_BLOCK and Lauf.b8_unsafe(sim, id):
				hit = true
		if hit:
			b8_ticks += 1
			if first < 0:
				first = sim.tick_count
	print("B8-Ticks in 6000 Ticks (irgendein Fahrzeug wartet auf schon freien Block): %d, erster Tick %d" % [b8_ticks, first])
	# Reproduktion des Absturzes bei Tick 3451, Fahrzeug 1
	var sim2 = Lauf.build_normal(1)
	sim2.run_ticks(3451)
	var v: Dictionary = sim2.vehicles[1]
	print("Tick %d: Fahrzeug 1 Zustand %d, wait_block %d, Halter %d" % [sim2.tick_count, v["state"], v["wait_block"], sim2.graph.blocks[v["wait_block"]]["holder"]])
	var c = sim2.get_wait_chain(1)
	print("get_wait_chain(1) Rueckgabe: %s  (leer/abgebrochen = Absturz reproduziert)" % str(c))
	sim2.step()
	v = sim2.vehicles[1]
	print("Tick %d (einen Tick spaeter): Zustand %d, held_block %d  (Fahrzeug ist eingefahren, Zustand war nur im Tick-Zwischenstand inkonsistent)" % [sim2.tick_count, v["state"], v["held_block"]])
	quit(0)
