extends RefCounted
## F-16: Aufbau-Helfer für Ökonomie-Szenarien (Tests, Bench). Positionen in Feldern (× raum.feld_mm),
## Lkw-Tempo und -Kapazität aus data/vehicles.json (lkw_e1). Straßen zweispurig (je Richtung ein Block).

const SimWorld := preload("res://sim_world.gd")
const Economy := preload("res://economy.gd")

const SLICE := "res://data/economy_slice.json"
const CONSTS := "res://data/economy_constants.json"
const VEHICLES := "res://data/vehicles.json"

var sim
var eco
var lkw_speed := 0
var lkw_cap := 0
var _next_edge := 1
var _next_vid := 1


func _init() -> void:
	sim = SimWorld.new()
	eco = Economy.new()
	eco.load_from(SLICE, CONSTS)
	eco.attach(sim)
	var f := FileAccess.open(VEHICLES, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	for v in data["fahrzeuge"]:
		if v["id"] == eco.slice["fahrzeug_ref"]["lkw_id"]:
			lkw_speed = int(v["tempo_mm_pro_tick"])
			lkw_cap = int(v["kapazitaet_einheiten"])


## Knoten in Feldern (ganzzahlig) oder direkt in mm (mm = true).
func node(id: int, x: int, y: int, label: String = "", mm: bool = false) -> void:
	var k: int = 1 if mm else eco.feld_mm
	sim.graph.add_node(id, Vector2i(x * k, y * k), label)


func road(a: int, b: int) -> void:
	sim.graph.add_edge(_next_edge, a, b, false)
	_next_edge += 1


## Pendel-Lkw über die Knotenfolge path: lädt an load_nodes, lädt an unload_nodes ab.
func truck(path: Array, load_nodes: Array, unload_nodes: Array, start_tick: int = 0, cap: int = -1) -> int:
	var vid := _next_vid
	_next_vid += 1
	sim.add_vehicle(vid, "Lkw %d" % vid, sim.graph.route_from_nodes(path), lkw_speed, start_tick,
		load_nodes, lkw_cap if cap < 0 else cap, true, unload_nodes)
	return vid


## Slice-Welt mit K1, K2, K3 (Strecken wie ketten[].strecke_felder im JSON, als Luftlinie gelegt).
## Firma Agrar, HQ in kleinstadt_a; Lizenzen für alle Quellen und Verarbeiter, soweit Guthaben reicht.
static func slice_world():
	var w = new()
	var e = w.eco
	var pos := {
		"getreidefarm": Vector2i(0, 0), "muehle": Vector2i(18, 0), "kleinstadt_a": Vector2i(63, 0),
		"kohlemine": Vector2i(0, 40), "kraftwerk": Vector2i(20, 40),
		"erzmine": Vector2i(0, 80), "stahlwerk": Vector2i(20, 80), "kohlemine_2": Vector2i(5, 95),
		"werkzeugfabrik": Vector2i(60, 80),
	}
	var ids := {}
	var nid := 0
	for k in pos:
		w.node(nid, pos[k].x, pos[k].y, k)
		ids[k] = nid
		nid += 1
	for k in pos:
		if k == "kleinstadt_a":
			e.add_city_site(ids[k], k)
		elif k == "kohlemine_2":
			e.add_industry_site(ids[k], "kohlemine")
		else:
			e.add_industry_site(ids[k], k)
	var legs := [["getreidefarm", "muehle"], ["muehle", "kleinstadt_a"], ["kohlemine", "kraftwerk"],
		["erzmine", "stahlwerk"], ["kohlemine_2", "stahlwerk"], ["stahlwerk", "werkzeugfabrik"]]
	e.start_company("agrar", ids["kleinstadt_a"], "kleinstadt")
	var st := 0
	for l in legs:
		w.road(ids[l[0]], ids[l[1]])
		w.truck([ids[l[0]], ids[l[1]]], [ids[l[0]]], [ids[l[1]]], st)   # ein Pendler je Straße (Hold-and-Wait am Wendepunkt)
		st += 11
	for k in ["getreidefarm", "muehle", "kohlemine", "erzmine", "stahlwerk", "kohlemine_2"]:
		e.buy_licence(e.site_of_node(ids[k]))
	return w
