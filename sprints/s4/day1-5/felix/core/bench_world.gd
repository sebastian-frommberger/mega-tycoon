extends RefCounted
## F-05: Benchmark-Welt auf Basis des F-04-Spikes. Reine Sim, kein Rendering.
## Gitternetz aus zweigleisigen Kanten (je Richtung ein Block), Fahrzeuge auf zufälligen, geschlossenen
## Rundkursen (Rechtecke im Gitter). Eigener PRNG (xorshift64*), damit Seed -> identische Welt auf jedem Rechner.
## Knotenzahl ≈ 2 × Fahrzeugzahl, damit die Last je Fahrzeug über 1k/5k/10k vergleichbar bleibt
## (ca. 8 Blöcke je Fahrzeug) und die meisten Fahrzeuge fahren statt zu warten. Das Netz ist synthetisch; es misst den Sim-Kern, nicht ein Spielnetz.

const SimWorld := preload("res://sim_world.gd")
const Economy := preload("res://economy.gd")

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
## eco = true (F-16): Ökonomie hängt sich ein. Routen und PRNG-Folge bleiben gleich; jedes Fahrzeug lädt an
## seinem Startknoten (Getreidefarm, Lizenz per API gekauft, Vorrat vorbelegt, damit Laden nie wartet =
## Worst Case für Ertragsbuchungen) und entlädt am gegenüberliegenden Knoten (3/4 Mühle = Endabnehmer,
## 1/4 Lager). Knoten mit widersprüchlicher Rolle: Fahrzeug fährt ohne Laden (gezählt in eco_vehicles).
func build(n_vehicles: int, seed: int, eco: bool = false) -> Dictionary:
	_seed(seed)
	var sim = SimWorld.new()
	var e = null
	var role := {}          # Knoten -> "farm" | "muehle" | "lager"
	var eco_vehicles := 0
	if eco:
		e = Economy.new()
		e.load_from("res://data/economy_slice.json", "res://data/economy_constants.json")
		e.attach(sim)
		e.ledger_enabled = false
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
		var spd := _randi_range(SPEED_MIN, SPEED_MAX)
		var st := _randi_range(0, 50)
		var ln: Array = []
		var un: Array = []
		if eco:
			var a_node: int = path[0]
			var b_node: int = path[path.size() / 2]
			var want_b: String = "lager" if vid % 4 == 3 else "muehle"
			if role.get(a_node, "farm") == "farm" and role.get(b_node, want_b) == want_b and a_node != b_node:
				role[a_node] = "farm"
				role[b_node] = want_b
				ln = [a_node]
				un = [b_node]
				eco_vehicles += 1
		sim.add_vehicle(vid, "V%d" % vid, route, spd, st, ln, 10, true, un)
	if eco:
		var keys: Array = role.keys()
		keys.sort()
		for nd in keys:
			match role[nd]:
				"farm":
					var site: int = e.add_industry_site(nd, "getreidefarm")
					e.seed_stock(site, "getreide", 100000000)
				"muehle":
					e.add_industry_site(nd, "muehle")
				"lager":
					e.add_warehouse_site(nd)
		e.start_company("agrar", 0, "kleinstadt")
		e.cash_cent = 1 << 50   # Bench: Guthaben für alle Lizenzen (keine Spielregel)
		for nd in keys:
			if role[nd] == "farm":
				e.buy_licence(e.site_of_node(nd))
	return {
		"eco": e, "eco_vehicles": eco_vehicles,
		"sim": sim, "nodes_w": w, "nodes_h": h, "n_nodes": w * h, "n_edges": g.edges.size(),
		"n_blocks": g.blocks.size(), "n_vehicles": n_vehicles,
	}
