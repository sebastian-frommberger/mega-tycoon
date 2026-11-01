extends RefCounted
## REFERENZ-Kopie fuer K8 (Pfade auf res://ref/, Inhalt sonst wie Hauptordner).
## F-06 Testwelt (Felix, 24.11.): eine SimWorld mit drei getrennten Teilnetzen (F1, F2, F3 nach Lena
## l06_fehler_final.md) und einem Kontrollnetz K1 (zwei Kontrollzüge, Ausweichgleis, darf keine Meldung erzeugen).
## Dazu die Namenstabelle (kind, id) -> Anzeigename und die Verdichtung links -> Kettenzeilen nach
## Aylins Datenvertrag v1, Abschnitt 3b, mit den Textvorlagen v1 (D11: Titel T_STEHT, kein Vorschlag).
## Reine Daten, kein Node. Wird von der Testszene (f06_main.gd), dem Smoke-Test und dem Runner benutzt.
##
## Einheiten wie im Spike: mm (Vector2i). In der Szene: 1 m = 1 px Welt (pos / 1000).
## Fahrzeug-IDs = Lenas Zugnummern (Zug 4/2, 5/8/6/9, 10/7), damit Log und Text dieselbe Zahl tragen.
## Signal- und Abschnittsnummern vergibt die Namenstabelle je Teilnetz (F1 = 1x, F3 = 2x, F2 = 3x, K1 = 4x),
## Lenas Nummern (Signal 12, Abschnitt 13 ...) waren Platzhalter; welche Nummer erscheint, folgt aus dem Netz.

const SimWorld := preload("res://ref/sim_world.gd")
const Diagnostics := preload("res://ref/diagnostics.gd")

const SPEED := 4000          # Züge 40 m/s wie im Spike
const LKW_SPEED := 2000      # Lkw 20 m/s
const LKW_STRASSE_MM := 600000  # 600 m: 1 Einheit je ~600 Ticks -> F3 löst sich erst nach ~40 min Spielzeit
const VORLAUF_TICKS := 1300  # Stillstände beim Start >= 120 s (Lena 2)
const MAX_ZEILE := 60        # Aylin V10

## Die drei Testfehler: Aufgabenzug, erwartete Ursache, Soll-Zeilenzahl (Lena/Aylin), Untertitel-Ort.
const FEHLER := {
	"F1": {"vehicle": 4, "code": "EINGLEISIG_GEGENVERKEHR", "zeilen": 4, "ort": "Strecke Mühlbach–Kornfeld"},
	"F2": {"vehicle": 5, "code": "DEADLOCK", "zeilen": 6, "ort": "Kreuzung Südfeld"},
	"F3": {"vehicle": 10, "code": "WARTEN_AUF_LADUNG", "zeilen": 5, "ort": "Hafen-Ost"},
}
const KONTROLLE := [11, 12]
## Reihenfolge je Tester (Aylin testskript_l06_final.md, Abschnitt 2)
const PERMUTATION := {
	"T1": ["F1", "F2", "F3"], "T2": ["F2", "F3", "F1"], "T3": ["F3", "F1", "F2"],
	"T4": ["F1", "F3", "F2"], "T5": ["F3", "F2", "F1"], "T6": ["F2", "F1", "F3"],
}
const M := 1000  # mm je m

var sim
var names: Dictionary = {}       # "KIND:id" -> Anzeigename
var subnet_of_block: Dictionary = {}
var parallel_edges: Array = []   # Kanten-IDs, die versetzt gezeichnet werden (zweites Gleis)
var vehicle_kind: Dictionary = {}  # id -> "ZUG" | "LKW"


func build() -> void:
	sim = SimWorld.new()
	var g = sim.graph
	# ---- F1: eingleisige Strecke Oberau – Mühlbach – Talmühle – Kornfeld, Zug 4 nach Osten, Zug 2 nach Westen
	var b0 := _snap_blocks()
	var s0 := _snap_signals()
	# Knotennamen so, dass die umkämpfte Strecke (gemessen: Kanten 101 und 102) Mühlbach–Kornfeld heißt
	g.add_node(100, Vector2i(0, 0), "Mühlbach")
	g.add_node(101, Vector2i(200 * M, 0), "Talmühle")
	g.add_node(102, Vector2i(400 * M, 0), "Kornfeld")
	g.add_node(103, Vector2i(600 * M, 0), "Oberau")
	g.add_edge(101, 100, 101)
	g.add_edge(102, 101, 102)
	g.add_edge(103, 102, 103)
	_number_new(b0, s0, 10, "F1")
	sim.add_vehicle(4, "Zug 4", g.find_path(100, 103), SPEED)
	sim.add_vehicle(2, "Zug 2", g.find_path(103, 100), SPEED)
	# ---- F3: Depot – Hafen-Ost – Ziel, Zug 7 lädt in Hafen-Ost (40), Zug 10 dahinter, 1 Lkw von der Kiesgrube
	b0 = _snap_blocks()
	s0 = _snap_signals()
	g.add_node(300, Vector2i(0, 450 * M), "Depot West")
	g.add_node(301, Vector2i(200 * M, 450 * M), "Hafen-Ost")
	g.add_node(302, Vector2i(400 * M, 450 * M), "Kai Süd")
	g.add_node(310, Vector2i(200 * M, 450 * M + LKW_STRASSE_MM), "Kiesgrube")
	g.add_edge(301, 300, 301)
	g.add_edge(302, 301, 302)
	g.add_edge(310, 310, 301, false)
	_number_new(b0, s0, 20, "F3")
	sim.add_station(301, "Hafen-Ost", 0, 0, 0)
	sim.add_station(310, "Kiesgrube", 1000000, 0, 0)
	sim.add_vehicle(7, "Zug 7", g.find_path(300, 302), SPEED, 0, [301], 40)
	sim.add_vehicle(10, "Zug 10", g.find_path(300, 302), SPEED, 10, [301], 40)
	sim.add_vehicle(3, "Lkw 3", g.route_from_nodes([310, 301]), LKW_SPEED, 0, [310], 1, true, [301])
	# ---- F2: Gleisquadrat Kreuzung Südfeld, 4 Züge im Uhrzeigersinn: 5 -> 8 -> 6 -> 9 -> 5
	b0 = _snap_blocks()
	s0 = _snap_signals()
	var sq := [Vector2i(850 * M, -100 * M), Vector2i(1050 * M, -100 * M), Vector2i(1050 * M, 100 * M), Vector2i(850 * M, 100 * M)]
	var sq_names := ["Südfeld Nordwest", "Südfeld Nordost", "Südfeld Südost", "Südfeld Südwest"]
	for i in range(4):
		g.add_node(200 + i, sq[i], sq_names[i])
	for i in range(4):
		g.add_edge(201 + i, 200 + i, 200 + (i + 1) % 4)
	_number_new(b0, s0, 30, "F2")
	var ring_ids := [5, 8, 6, 9]
	for i in range(4):
		sim.add_vehicle(ring_ids[i], "Zug %d" % ring_ids[i], g.route_from_nodes([200 + i, 200 + (i + 1) % 4, 200 + (i + 2) % 4]), SPEED)
	# ---- K1: Kontrolle mit Ausweichgleis Lindenau – Birkhof (zwei Gleise), zwei pendelnde Züge, keine Meldung
	b0 = _snap_blocks()
	s0 = _snap_signals()
	g.add_node(400, Vector2i(750 * M, 450 * M), "Westend")
	g.add_node(401, Vector2i(950 * M, 450 * M), "Lindenau")
	g.add_node(402, Vector2i(1150 * M, 450 * M), "Birkhof")
	g.add_node(403, Vector2i(1350 * M, 450 * M), "Ostkreuz")
	g.add_edge(401, 400, 401)
	g.add_edge(402, 401, 402)
	g.add_edge(403, 402, 403)
	g.add_edge(405, 401, 402)  # Ausweichgleis
	parallel_edges.append(405)
	_number_new(b0, s0, 40, "K1")
	var r1: Array = [{"edge": 401, "fwd": true}, {"edge": 402, "fwd": true}, {"edge": 403, "fwd": true}]
	var r2: Array = [{"edge": 403, "fwd": false}, {"edge": 405, "fwd": false}, {"edge": 401, "fwd": false}]
	sim.add_vehicle(11, "Zug 11", r1, 4000, 0, [], 10, true)
	sim.add_vehicle(12, "Zug 12", r2, 5000, 0, [], 10, true)
	for id in sim.vehicles:
		names["FAHRZEUG:%d" % id] = sim.vehicles[id]["name"]
		vehicle_kind[id] = "LKW" if String(sim.vehicles[id]["name"]).begins_with("Lkw") else "ZUG"
	for nid in sim.stations:
		names["LAGER:%d" % nid] = sim.stations[nid]["name"]
		names["INDUSTRIE:%d" % nid] = sim.stations[nid]["name"]


func vorlauf(n: int = VORLAUF_TICKS) -> void:
	sim.run_ticks(n)


func _snap_blocks() -> Dictionary:
	return sim.graph.blocks.duplicate()


func _snap_signals() -> Dictionary:
	return sim.graph.signals.duplicate()


## Neue Blöcke/Signale eines Teilnetzes bekommen Anzeigenummern base+1, base+2 ...
func _number_new(old_blocks: Dictionary, old_signals: Dictionary, base: int, subnet: String) -> void:
	var nb: Array = sim.graph.blocks.keys().filter(func(k): return not old_blocks.has(k))
	nb.sort()
	for i in range(nb.size()):
		names["BLOCK:%d" % nb[i]] = str(base + i + 1)
		subnet_of_block[nb[i]] = subnet
	var ns: Array = sim.graph.signals.keys().filter(func(k): return not old_signals.has(k))
	ns.sort()
	for i in range(ns.size()):
		names["SIGNAL:%d" % ns[i]] = str(base + i + 1)


func name_of(kind: String, id: int) -> String:
	return names.get("%s:%d" % [kind, id], "")


static func dauer_text(ticks: int) -> String:
	var s: int = maxi(ticks, 0) / SimWorld.TICK_HZ
	return "%d:%02d min" % [s / 60, s % 60]


static func spielzeit_text(tick: int) -> String:
	var s: int = maxi(tick, 0) / SimWorld.TICK_HZ
	return "%d:%02d" % [s / 60, s % 60]


## Fehler-Schlüssel (F1/F2/F3) eines Aufgabenzugs, "" wenn keiner.
static func fehler_of(vehicle_id: int) -> String:
	for k in FEHLER:
		if FEHLER[k]["vehicle"] == vehicle_id:
			return k
	return ""


func titel(vehicle_id: int) -> String:
	var c: Dictionary = sim.get_wait_chain(vehicle_id)
	return "%s steht seit %s" % [name_of("FAHRZEUG", vehicle_id), dauer_text(c["wait_ticks"])]


## Verdichtung links -> Kettenzeilen (Datenvertrag v1, 3b). Zeile: {index, key, text, kind, id, pos, wurzel}
## Auslegung (markiert): bei R_HALTER/R_HALTER_GEGEN ist {abs} der Abschnitt, den der Halter besetzt
## (= der BLOCK direkt vor ihm in links), so liest es Lenas Soll-Kette F1/F3. Bei R_WARTET_ZUG ist {abs}
## der Abschnitt, auf den {zug} wartet und den {zug2} besetzt. INDUSTRIE erzeugt keine eigene Zeile.
func rows_for(chain: Dictionary) -> Array:
	var rows: Array = []
	var links: Array = chain["links"]
	var cyc: Array = chain["cycle"]
	var kreis3: bool = chain["is_deadlock"] and cyc.size() >= 3
	var i := 0
	while i < links.size():
		var l: Dictionary = links[i]
		var k: String = l["kind"]
		if k == "FAHRZEUG":
			var zug := name_of("FAHRZEUG", l["id"])
			var waits_block: bool = i + 2 < links.size() and links[i + 1]["kind"] == "SIGNAL" and links[i + 2]["kind"] == "BLOCK"
			if i == 0:
				_add(rows, "T_STEHT", "%s steht seit %s" % [zug, dauer_text(chain["wait_ticks"])], l)
			else:
				var prev: Dictionary = links[i - 1]
				if not (kreis3 and cyc.has(l["id"])):
					var abs_name := name_of("BLOCK", prev["id"])
					if prev["single"] and prev["holder_fwd"] != prev["wanted_fwd"]:
						_add(rows, "R_HALTER_GEGEN", "%s besetzt Abschnitt %s und fährt entgegen" % [zug, abs_name], l)
					else:
						_add(rows, "R_HALTER", "%s besetzt Abschnitt %s" % [zug, abs_name], l)
			if waits_block:
				var blk: Dictionary = links[i + 2]
				if kreis3 and cyc.has(l["id"]):
					var zug2 := name_of("FAHRZEUG", int(blk["holder"]))
					_add(rows, "R_WARTET_ZUG", "%s wartet auf %s, der Abschnitt %s besetzt" % [zug, zug2, name_of("BLOCK", blk["id"])], l)
				elif i == 0:
					_add(rows, "R_SIGNAL", "Wartet am Signal %s: Abschnitt %s ist besetzt" % [name_of("SIGNAL", links[i + 1]["id"]), name_of("BLOCK", blk["id"])], links[i + 1])
				i += 3
				continue
			i += 1
			continue
		if k == "LAGER":
			var zugl := name_of("FAHRZEUG", links[i - 1]["id"])
			var p: Dictionary = chain["params"]
			_add(rows, "R_LADUNG", "%s wartet in %s auf Ladung (%d von %d)" % [zugl, l["name"], int(p.get("fuell_ist", l["stock"])), int(p.get("fuell_soll", l["needed"]))], l)
			i += 1
			continue
		if k == "URSACHE":
			var p2: Dictionary = l["params"]
			var row := {}
			match l["code"]:
				"EINGLEISIG_GEGENVERKEHR":
					_add(rows, "W_EINGLEISIG", "%s hat nur ein Gleis (%d Felder)" % [strecke_name(p2.get("kanten", [])), int(p2["strecke_felder"])], l)
				"DEADLOCK":
					_add(rows, "W_KREIS", "Alle %d warten aufeinander, keiner kann zuerst fahren" % int(p2["n_fahrzeuge"]), l)
				"WARTEN_AUF_LADUNG":
					var n: int = int(p2["n_lkw"])
					var lager := name_of("LAGER", int(p2["lager_id"]))
					if n == 1:
						_add(rows, "W_ZULIEFERUNG", "%s bekommt zu wenig Ware: nur 1 Lkw liefert" % lager, l)
					else:
						_add(rows, "W_ZULIEFERUNG", "%s bekommt zu wenig Ware: nur %d Lkw liefern" % [lager, n], l)
				_:
					pass  # BLOCK_BELEGT_UNTERWEGS / KEINE: keine Meldung, keine Wurzelzeile
			if not rows.is_empty() and rows[-1]["kind"] == "URSACHE":
				rows[-1]["wurzel"] = true
				rows[-1]["obj_kind"] = l["obj_kind"]
		i += 1  # SIGNAL, BLOCK (verbraucht), INDUSTRIE (keine Zeile)
	return rows


func _add(rows: Array, key: String, text: String, l: Dictionary) -> void:
	rows.append({"index": rows.size() + 1, "key": key, "text": text, "kind": l["kind"], "id": l["id"],
		"pos": l["pos"], "wurzel": false})


## Streckenname aus den umkämpften Kanten: Endknoten des Kantenzugs "A–B" (Aylin: Name aus Knotennamen).
func strecke_name(kanten: Array) -> String:
	var deg: Dictionary = {}
	for eid in kanten:
		var e: Dictionary = sim.graph.edges[eid]
		deg[e["a"]] = int(deg.get(e["a"], 0)) + 1
		deg[e["b"]] = int(deg.get(e["b"], 0)) + 1
	var ends: Array = deg.keys().filter(func(n): return deg[n] == 1)
	ends.sort()
	if ends.size() != 2:
		return "Die Strecke"
	return "%s–%s" % [sim.graph.nodes[ends[0]]["name"], sim.graph.nodes[ends[1]]["name"]]


## UI-seitige Prüfung vor der Anzeige (Aylin Z5): Sim-Validator + V8 (meldungsfähig) + V9 (Namen).
## V10 (> 60 Zeichen) ist nur Warnung. Rückgabe: {fehler: Array[String] (Regeln), warnungen: Array}
func ui_check(chain: Dictionary, rows: Array) -> Dictionary:
	var fehler: Array = []
	for e in Diagnostics.validate(chain):
		fehler.append(String(e).split(":")[0])
	if chain["root_cause"] == "KEINE" or chain["root_cause"] == "BLOCK_BELEGT_UNTERWEGS":
		fehler.append("V8")
	for l in chain["links"]:
		if (l["kind"] == "FAHRZEUG" or l["kind"] == "SIGNAL" or l["kind"] == "BLOCK" or l["kind"] == "LAGER") and name_of(l["kind"], l["id"]) == "":
			fehler.append("V9")
			break
	if rows.is_empty() or not rows[-1]["wurzel"]:
		fehler.append("V2")
	var warn: Array = []
	for r in rows:
		if String(r["text"]).length() > MAX_ZEILE:
			warn.append("V10 Zeile %d: %d Zeichen" % [r["index"], String(r["text"]).length()])
	return {"fehler": fehler, "warnungen": warn}
