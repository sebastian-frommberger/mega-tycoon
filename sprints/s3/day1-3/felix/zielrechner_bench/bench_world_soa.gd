extends RefCounted
## ZIELRECHNER-KOPIE (Sprint 3, F-10): identisch zu day1-3/felix/core/bench_world.gd, nur preload-Pfade res://_bench/*_soa.gd.
## F-05: Benchmark-Welt auf Basis des F-04-Spikes. Reine Sim, kein Rendering.
## Gitternetz aus zweigleisigen Kanten (je Richtung ein Block), Fahrzeuge auf zufälligen, geschlossenen
## Rundkursen (Rechtecke im Gitter). Eigener PRNG (xorshift64*), damit Seed -> identische Welt auf jedem Rechner.
## Knotenzahl ≈ 2 × Fahrzeugzahl, damit die Last je Fahrzeug über 1k/5k/10k vergleichbar bleibt
## (ca. 8 Blöcke je Fahrzeug) und die meisten Fahrzeuge fahren statt zu warten. Das Netz ist synthetisch; es misst den Sim-Kern, nicht ein Spielnetz.

const SimWorld := preload("res://_bench/sim_world_soa.gd")

const SPACING := 200000  # mm zwischen Gitterknoten (200 m)
const JITTER := 30000    # ± mm Lagestreuung der Knoten (Kantenlängen variieren 140–260 m)
const SPEED_MIN := 3000  # mm/Tick
const SPEED_MAX := 6000

var _state: int = 0


func _seed(s: int) -> void:
	_state = s * 2654435761 + 88172645463325252
	if _state == 0:
		_state = 1


## xorshift64*, liefert nichtnegative 62-Bit-Zahl
func _rand() -> int:
	var x: int = _state
	x ^= x >> 12
	x ^= x << 25
	x ^= x >> 27
	_state = x
	return ((x * 2685821657736338717) >> 1) & 0x3FFFFFFFFFFFFFFF


func _randi_range(lo: int, hi: int) -> int:
	return lo + _rand() % (hi - lo + 1)


## Baut die Welt. Gibt {sim, nodes_w, nodes_h, n_edges, n_blocks, n_vehicles} zurück.
func build(n_vehicles: int, seed: int) -> Dictionary:
	_seed(seed)
	var sim = SimWorld.new()
	var g = sim.graph
	var w: int = maxi(6, int(ceil(sqrt(2.0 * n_vehicles))))  # ca. 2 Knoten (8 Blöcke) je Fahrzeug
	var h: int = w
	# Knoten
	for y in range(h):
		for x in range(w):
			var id := y * w + x
			var px := x * SPACING + _randi_range(-JITTER, JITTER)
			var py := y * SPACING + _randi_range(-JITTER, JITTER)
			g.add_node(id, Vector2i(px, py))
	# Kanten: rechts und unten, zweigleisig
	var eid := 1
	for y in range(h):
		for x in range(w):
			var id := y * w + x
			if x + 1 < w:
				g.add_edge(eid, id, id + 1, false)
				eid += 1
			if y + 1 < h:
				g.add_edge(eid, id, id + w, false)
				eid += 1
	# Fahrzeuge: geschlossener Rundkurs (Rechteck a x b Zellen im Gitter, Drehsinn zufällig), zyklisch
	# ohne Wenden. Pendelrouten mit Wendepunkt halten im Spike den letzten Block (Hold-and-Wait) und
	# verklemmen das Netz; Rundkurse entsprechen Linien im Spiel.
	for vid in range(n_vehicles):
		var a := _randi_range(1, 4)
		var b := _randi_range(1, 4)
		var x0 := _randi_range(0, w - 1 - a)
		var y0 := _randi_range(0, h - 1 - b)
		var corners: Array = [[x0, y0], [x0 + a, y0], [x0 + a, y0 + b], [x0, y0 + b]]
		if _rand() % 2 == 1:
			corners.reverse()
		var start_c := _randi_range(0, 3)
		var path: Array = []
		for ci in range(5):
			var c: Array = corners[(start_c + ci) % 4]
			if ci == 0:
				path.append(c[1] * w + c[0])
				continue
			var prev_c: Array = corners[(start_c + ci - 1) % 4]
			# Zwischenknoten entlang der Rechteckseite einfügen
			var dx: int = signi(c[0] - prev_c[0])
			var dy: int = signi(c[1] - prev_c[1])
			var cx: int = prev_c[0]
			var cy: int = prev_c[1]
			while cx != c[0] or cy != c[1]:
				cx += dx
				cy += dy
				path.append(cy * w + cx)
		var route: Array = g.route_from_nodes(path)
		sim.add_vehicle(vid, "V%d" % vid, route, _randi_range(SPEED_MIN, SPEED_MAX), _randi_range(0, 50), [], 10, true)
	return {
		"sim": sim, "nodes_w": w, "nodes_h": h, "n_nodes": w * h, "n_edges": g.edges.size(),
		"n_blocks": g.blocks.size(), "n_vehicles": n_vehicles,
	}
