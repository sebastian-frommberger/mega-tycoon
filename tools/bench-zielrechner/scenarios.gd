extends RefCounted
## Spike F-04: Szenario-Aufbau. Alle Maße in mm, Kantenlänge 200 m = 200000 mm,
## Geschwindigkeit 4000 mm/Tick (40 m/s) -> 50 Ticks pro Kante.

const SimWorld := preload("res://_bench/sim_world.gd")

const SEG := 200000
const SPEED := 4000


## S1: Eingleisige Strecke A-B-C-D ohne Ausweichgleis, Zug 1 A->D, Zug 2 D->A.
static func gegenverkehr_eingleisig():
	var s = SimWorld.new()
	s.graph.add_node(0, Vector2i(0, 0), "A")
	s.graph.add_node(1, Vector2i(SEG, 0), "B")
	s.graph.add_node(2, Vector2i(2 * SEG, 0), "C")
	s.graph.add_node(3, Vector2i(3 * SEG, 0), "D")
	s.graph.add_edge(1, 0, 1)
	s.graph.add_edge(2, 1, 2)
	s.graph.add_edge(3, 2, 3)
	s.add_vehicle(1, "Zug 1", s.graph.find_path(0, 3), SPEED)
	s.add_vehicle(2, "Zug 2", s.graph.find_path(3, 0), SPEED)
	return s


## S2: Gleisquadrat mit vier Zügen im Kreis (jeder will den Block des nächsten).
static func deadlock_kreis():
	var s = SimWorld.new()
	s.graph.add_node(0, Vector2i(0, 0), "N0")
	s.graph.add_node(1, Vector2i(SEG, 0), "N1")
	s.graph.add_node(2, Vector2i(SEG, SEG), "N2")
	s.graph.add_node(3, Vector2i(0, SEG), "N3")
	s.graph.add_edge(1, 0, 1)
	s.graph.add_edge(2, 1, 2)
	s.graph.add_edge(3, 2, 3)
	s.graph.add_edge(4, 3, 0)
	for i in range(4):
		# explizite Route im Uhrzeigersinn (A* würde bei Gleichstand eine Richtung wählen)
		var route: Array = s.graph.route_from_nodes([i, (i + 1) % 4, (i + 2) % 4])
		s.add_vehicle(i, "Zug %d" % i, route, SPEED)
	return s


## S3: Lager unterversorgt (D9, Fehler 3). Zug 7 (id 1) wartet am Lager auf 40 Einheiten, Zug 10 (id 2)
## steht dahinter am Block. Das Lager wird von genau einem Lkw (id 3) beliefert, 1 Einheit je Rundfahrt
## (ca. 100 Ticks): fuell_ist waechst, bleibt aber lange unter fuell_soll (40 Einheiten erst nach ~4000 Ticks).
## produce_every/produce_amount > 0: Positivkontrolle mit Eigenproduktion des Lagers.
static func warten_auf_ladung(produce_every: int = 0, produce_amount: int = 1, n_lkw: int = 1):
	var s = SimWorld.new()
	s.graph.add_node(0, Vector2i(0, 0), "Depot")
	s.graph.add_node(1, Vector2i(SEG, 0), "Lager")
	s.graph.add_node(2, Vector2i(2 * SEG, 0), "Ziel")
	s.graph.add_edge(1, 0, 1)
	s.graph.add_edge(2, 1, 2)
	s.add_station(1, "Lager Hafen-Ost", 0, produce_every, produce_amount)
	s.add_vehicle(1, "Zug 7", s.graph.find_path(0, 2), SPEED, 0, [1], 40)
	s.add_vehicle(2, "Zug 10", s.graph.find_path(0, 2), SPEED, 10, [1], 40)
	for i in range(n_lkw):
		# Zulieferer i: eigene Strasse Mine_i <-> Lager (je Richtung ein Block), laedt 1 Einheit an der Mine,
		# laedt sie am Lager ab. Eigene Strasse je Lkw, weil im Spike ein Fahrzeug am Wendepunkt seinen
		# Block haelt (Hold-and-Wait, keine Bahnhofsgleise): zwei Pendler auf einer Strasse blockieren sich.
		var mine := 3 + i
		s.graph.add_node(mine, Vector2i(SEG + 20000 * i, -SEG), "Mine %d" % (i + 1))
		s.graph.add_edge(3 + i, mine, 1, false)
		s.add_station(mine, "Mine %d" % (i + 1), 1000000, 0, 0)
		s.add_vehicle(3 + i, "Lkw %d" % (i + 1), s.graph.route_from_nodes([mine, 1]), SPEED, 20 * i, [mine], 1, true, [1])
	return s


## K1: Kontrolle, kein Fehler. Ausweichstelle B-C mit zwei Gleisen (Kanten 2 und 5),
## Zug 1 nutzt oben, Zug 2 unten, beide pendeln (cyclic), unterschiedliche Geschwindigkeit.
static func kontrolle_ausweichgleis():
	var s = SimWorld.new()
	s.graph.add_node(0, Vector2i(0, 0), "A")
	s.graph.add_node(1, Vector2i(SEG, 0), "B")
	s.graph.add_node(2, Vector2i(2 * SEG, 0), "C")
	s.graph.add_node(3, Vector2i(3 * SEG, 0), "D")
	s.graph.add_edge(1, 0, 1)
	s.graph.add_edge(2, 1, 2)  # oberes Gleis
	s.graph.add_edge(3, 2, 3)
	s.graph.add_edge(5, 1, 2)  # unteres Gleis (Ausweichgleis)
	var r1: Array = [{"edge": 1, "fwd": true}, {"edge": 2, "fwd": true}, {"edge": 3, "fwd": true}]
	var r2: Array = [{"edge": 3, "fwd": false}, {"edge": 5, "fwd": false}, {"edge": 1, "fwd": false}]
	s.add_vehicle(1, "Zug 1", r1, 4000, 0, [], 10, true)
	s.add_vehicle(2, "Zug 2", r2, 5000, 0, [], 10, true)
	return s

## S1b (D3, Daniel E): Gegenverkehr eingleisig mit Auffahrer. Zug 3 startet 30 Ticks nach Zug 1 in
## dieselbe Richtung und faehrt auf den stehenden Zug 1 auf. Zug 3 ist nicht im Zyklus.
static func gegenverkehr_auffahrer():
	var s = gegenverkehr_eingleisig()
	s.add_vehicle(3, "Zug 3", s.graph.find_path(0, 3), SPEED, 30)
	return s


## S2b (D3): Ring mit n Zuegen auf n Bloecken (Daniels "Ring 6 Zuege"). Knoten auf einem Kreis
## mit Radius SEG, ganzzahlig gerundet; jeder Zug will zwei Kanten weiter.
static func deadlock_ring(n: int = 6):
	var s = SimWorld.new()
	for i in range(n):
		var a := TAU * i / n
		s.graph.add_node(i, Vector2i(roundi(SEG * cos(a)) + SEG, roundi(SEG * sin(a)) + SEG), "R%d" % i)
	for i in range(n):
		s.graph.add_edge(i + 1, i, (i + 1) % n)
	for i in range(n):
		s.add_vehicle(i, "Zug %d" % i, s.graph.route_from_nodes([i, (i + 1) % n, (i + 2) % n]), SPEED)
	return s
