extends SceneTree
## Daniel 27.11.: B8-Fix-Pruefung, unabhaengig. Alle 3 Normalnetz-Varianten x 6000 Ticks, JEDER Tick, JEDES wartende Fahrzeug
## (auch B8-Faelle, die daniel_d04_lauf_v2 bei der Validierung ausspart): Kette nicht leer, validate() leer,
## letztes Glied URSACHE, root_pos == links[-1].pos, keine Meldung bei BLOCK_BELEGT_UNTERWEGS. Zaehlt B8-Faelle.
const Lauf := preload("res://daniel_d04_lauf_v2.gd")
const SimWorld := preload("res://sim_world.gd")
const Diagnostics := preload("res://diagnostics.gd")
func _init() -> void:
	var gesamt := 0; var b8 := 0; var leer := 0; var ungueltig := 0; var ohne_wurzel := 0; var pos_diff := 0; var fehlalarm := 0
	for variant in [1, 2, 3]:
		var sim = Lauf.build_normal(variant)
		for t in range(6000):
			sim.step()
			for id in sim.vehicles:
				var st = sim.vehicles[id]["state"]
				if st != SimWorld.VState.WARTET_BLOCK and st != SimWorld.VState.WARTET_LADUNG:
					continue
				var isb8: bool = st == SimWorld.VState.WARTET_BLOCK and Lauf.b8_unsafe(sim, id)
				var c: Dictionary = sim.get_wait_chain(id)
				gesamt += 1
				if isb8: b8 += 1
				if c.is_empty() or c.get("links", []).is_empty():
					leer += 1; print("LEER V%d t%d f%d b8=%s" % [variant, sim.tick_count, id, isb8]); continue
				if not Diagnostics.validate(c).is_empty():
					ungueltig += 1; print("UNGUELTIG V%d t%d f%d: %s" % [variant, sim.tick_count, id, str(Diagnostics.validate(c))])
				var l: Array = c["links"]
				if l[-1]["kind"] != "URSACHE": ohne_wurzel += 1
				elif l[-1]["pos"] != c["root_pos"]: pos_diff += 1
				if c["is_deadlock"] or c["root_cause"] in ["DEADLOCK", "EINGLEISIG_GEGENVERKEHR"]: fehlalarm += 1
	print("ERGEBNIS wartende Fahrzeug-Ticks %d, davon B8 %d, leer %d, ungueltig %d, ohne URSACHE-Glied %d, root_pos!=links[-1].pos %d, Deadlock-Fehlalarme %d" % [gesamt, b8, leer, ungueltig, ohne_wurzel, pos_diff, fehlalarm])
	quit(0 if (leer + ungueltig + ohne_wurzel + pos_diff + fehlalarm) == 0 else 1)
