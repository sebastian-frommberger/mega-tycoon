extends RefCounted
## Spike F-04: Diagnose-API. get_wait_chain(vehicle_id) folgt der Warte-Kette bis zur Wurzelursache.
## Liefert strukturierte Daten (keine Texte). Koordinaten in mm (Vector2i, x und z der Karte).
##
## Stand 19.11. (D9): Das letzte Kettenglied ist immer das Ursache-Glied (kind URSACHE, rolle WURZEL).
## root_pos ist der kanonische Ort der Ursache und per Konstruktion gleich links[-1].pos.
## Alle Mitglieder desselben Deadlocks (und Auffahrer dahinter) bekommen denselben root_pos.
##
## Rückgabe (Dictionary):
##   vehicle_id: int
##   root_cause: String   DEADLOCK | EINGLEISIG_GEGENVERKEHR | WARTEN_AUF_LADUNG | BLOCK_BELEGT_UNTERWEGS | KEINE
##   is_deadlock: bool    true bei Zyklus im Warte-Graphen (dauerhafter Stillstand)
##   in_cycle: bool       true wenn das angefragte Fahrzeug selbst Teil des Zyklus ist
##   root_pos: Vector2i   kanonischer Ort der Wurzelursache == links[-1].pos
##   root_obj: {kind, id} Objekt der Wurzelursache (BLOCK bei Deadlock/Gegenverkehr, LAGER bei Ladung, FAHRZEUG bei UNTERWEGS)
##   params: Dictionary   Zusatzfelder je Ursache (D9), identisch mit links[-1].params:
##       EINGLEISIG_GEGENVERKEHR: strecke_mm, strecke_felder, gleiszahl (=1), n_fahrzeuge, bloecke, kanten
##       DEADLOCK:                n_fahrzeuge, bloecke, kanten, gleiszahl (min über Kanten)
##       WARTEN_AUF_LADUNG:       fuell_ist, fuell_soll, n_lkw, lkw_ids, produce_every, produce_amount, lager_id
##       BLOCK_BELEGT_UNTERWEGS:  halter_id
##   cycle: Array[int]    Fahrzeug-IDs im Zyklus (leer ohne Zyklus)
##   cycle_back_index: int  Index des Kettenglieds (FAHRZEUG), auf das der Kreis zurückführt; -1 ohne Zyklus
##                          (Aylins kette_kreis_zurueck_zu)
##   suggestion_id: String  statisch zur Ursache gemappt (z. B. AUSWEICHGLEIS_BAUEN), nicht berechnet
##   wait_ticks: int      wie lange das angefragte Fahrzeug schon wartet
##   wait_since_tick: int Beginn des Stillstands (-1 wenn es nicht wartet)
##   links: Array[Dictionary]  Kettenglieder {kind, id, pos, rolle, ...}
##       kind:  FAHRZEUG (role ANFRAGE | HALTER) | SIGNAL | BLOCK | LAGER | INDUSTRIE | URSACHE
##       rolle: SYMPTOM (nur Glied 0) | ZWISCHEN | WURZEL (nur letztes Glied)

const VS_WARTET_BLOCK := 2  # entspricht SimWorld.VState.WARTET_BLOCK
const VS_WARTET_LADUNG := 3  # entspricht SimWorld.VState.WARTET_LADUNG

const FELD_MM := 10000  # 1 Logikfeld = 10 m (Sophies Maßstabsband)

const SUGGESTIONS := {
	"EINGLEISIG_GEGENVERKEHR": "AUSWEICHGLEIS_BAUEN",
	"DEADLOCK": "SIGNALE_UMBAUEN_KREIS_AUFLOESEN",
	"WARTEN_AUF_LADUNG": "ZULIEFERUNG_ERHOEHEN",
	"BLOCK_BELEGT_UNTERWEGS": "",
	"KEINE": "",
}


## Zyklus-Klassifikation: Wartet jedes Mitglied auf einen eingleisigen Block, der in Gegenrichtung
## gehalten wird, ist es Gegenverkehr ohne Ausweichmöglichkeit; sonst allgemeiner Deadlock.
static func classify_cycle(sim, cycle: Array) -> String:
	for vid in cycle:
		var v: Dictionary = sim.vehicles[vid]
		var b: Dictionary = sim.graph.blocks[v["wait_block"]]
		var want_fwd: bool = v["route"][v["idx"]]["fwd"]
		if not (b["single"] and b["holder_fwd"] != want_fwd):
			return "DEADLOCK"
	return "EINGLEISIG_GEGENVERKEHR"


## Kanonischer Ort und Zusatzfelder eines Zyklus (D9). Unabhängig davon, welches Mitglied anfragt:
## Mitglieder aufsteigend sortiert, Ort = ganzzahliger Mittelpunkt der umkämpften Block-Mitten
## (Daniels Vorschlag "Mitte der Kreisglieder"), Objekt = umkämpfter Block mit kleinster ID.
static func cycle_root(sim, cycle: Array) -> Dictionary:
	var g = sim.graph
	var members: Array = cycle.duplicate()
	members.sort()
	var blocks: Array = []
	var edges: Array = []
	var sum := Vector2i.ZERO
	var strecke := 0
	var gleiszahl := 2
	for vid in members:
		var bid: int = sim.vehicles[vid]["wait_block"]
		if not blocks.has(bid):
			blocks.append(bid)
			var b: Dictionary = g.blocks[bid]
			sum += b["center"]
			var eid: int = b["edge"]
			if not edges.has(eid):
				edges.append(eid)
				strecke += int(g.edges[eid]["length"])
				if g.edges[eid]["single"]:
					gleiszahl = 1
	blocks.sort()
	edges.sort()
	var pos: Vector2i = sum / blocks.size()
	return {
		"pos": pos, "obj": {"kind": "BLOCK", "id": blocks[0]},
		"params": {
			"n_fahrzeuge": members.size(), "bloecke": blocks, "kanten": edges,
			"strecke_mm": strecke, "strecke_felder": strecke / FELD_MM, "gleiszahl": gleiszahl,
		},
	}


static func build_wait_chain(sim, vehicle_id: int) -> Dictionary:
	var g = sim.graph
	var links: Array = []
	var visited: Array = []
	var res := {
		"vehicle_id": vehicle_id, "root_cause": "KEINE", "is_deadlock": false, "in_cycle": false,
		"root_pos": Vector2i.ZERO, "root_obj": {"kind": "", "id": -1}, "params": {},
		"cycle": [], "cycle_back_index": -1, "suggestion_id": "", "wait_ticks": 0, "wait_since_tick": -1, "links": links,
	}
	var first: Dictionary = sim.vehicles[vehicle_id]
	if first["state"] == VS_WARTET_BLOCK or first["state"] == VS_WARTET_LADUNG:
		res["wait_ticks"] = sim.tick_count - int(first["wait_since"]) + 1
		res["wait_since_tick"] = int(first["wait_since"])
	var cur: int = vehicle_id
	while true:
		var v: Dictionary = sim.vehicles[cur]
		visited.append(cur)
		links.append({"kind": "FAHRZEUG", "id": cur, "pos": sim.vehicle_pos(v),
			"role": "ANFRAGE" if cur == vehicle_id else "HALTER", "name": v["name"]})
		if v["state"] == VS_WARTET_BLOCK:
			var step: Dictionary = v["route"][v["idx"]]
			var sig_id: int = g.signal_of(step["edge"], step["fwd"])
			var b: Dictionary = g.blocks[v["wait_block"]]
			links.append({"kind": "SIGNAL", "id": sig_id, "pos": g.nodes[g.signals[sig_id]["node"]]["pos"]})
			links.append({"kind": "BLOCK", "id": v["wait_block"], "pos": b["center"],
				"edge": step["edge"], "single": b["single"], "holder": b["holder"],
				"holder_fwd": b["holder_fwd"], "wanted_fwd": step["fwd"]})
			var holder: int = b["holder"]
			if visited.has(holder):
				# Zyklus geschlossen: Mitglieder ab erstem Auftreten des Halters
				var cyc: Array = visited.slice(visited.find(holder))
				res["cycle"] = cyc
				for i in range(links.size()):
					if links[i]["kind"] == "FAHRZEUG" and links[i]["id"] == holder:
						res["cycle_back_index"] = i
						break
				res["is_deadlock"] = true
				res["in_cycle"] = cyc.has(vehicle_id)
				res["root_cause"] = classify_cycle(sim, cyc)
				var root: Dictionary = cycle_root(sim, cyc)
				res["root_pos"] = root["pos"]
				res["root_obj"] = root["obj"]
				res["params"] = root["params"]
				break
			cur = holder
			continue
		if v["state"] == VS_WARTET_LADUNG:
			var node_id: int = g.step_to_node(v["route"][v["idx"] - 1])
			var st: Dictionary = sim.stations[node_id]
			var npos: Vector2i = g.nodes[node_id]["pos"]
			var suppliers: Array = sim.station_suppliers(node_id)
			links.append({"kind": "LAGER", "id": node_id, "pos": npos, "name": st["name"],
				"stock": st["stock"], "needed": v["cargo_cap"]})
			links.append({"kind": "INDUSTRIE", "id": node_id, "pos": npos,
				"produce_every": st["produce_every"], "produce_amount": st["produce_amount"]})
			res["root_cause"] = "WARTEN_AUF_LADUNG"
			res["root_pos"] = npos
			res["root_obj"] = {"kind": "LAGER", "id": node_id}
			res["params"] = {
				"fuell_ist": int(st["stock"]), "fuell_soll": int(v["cargo_cap"]),
				"n_lkw": suppliers.size(), "lkw_ids": suppliers,
				"produce_every": int(st["produce_every"]), "produce_amount": int(st["produce_amount"]),
				"lager_id": node_id,
			}
			break
		# Fahrzeug bewegt sich: Kette endet an einem fahrenden Halter (vorübergehend)
		if links.size() > 1:
			res["root_cause"] = "BLOCK_BELEGT_UNTERWEGS"
			res["root_pos"] = sim.vehicle_pos(v)
			res["root_obj"] = {"kind": "FAHRZEUG", "id": cur}
			res["params"] = {"halter_id": cur}
		else:
			res["root_pos"] = sim.vehicle_pos(v)
			res["root_obj"] = {"kind": "FAHRZEUG", "id": cur}
		break
	# Ursache-Glied anhängen (D9: kanonischer Ort = letztes Kettenglied)
	if res["root_cause"] != "KEINE":
		links.append({"kind": "URSACHE", "id": res["root_obj"]["id"], "obj_kind": res["root_obj"]["kind"],
			"pos": res["root_pos"], "code": res["root_cause"], "params": res["params"]})
	for i in range(links.size()):
		links[i]["rolle"] = "SYMPTOM" if i == 0 else ("WURZEL" if i == links.size() - 1 else "ZWISCHEN")
	res["suggestion_id"] = SUGGESTIONS[res["root_cause"]]
	return res


## Sim-seitiger Vertragsvalidator (Aylin V1–V7, soweit die Sim sie prüfen kann). Leeres Array = gültig.
## Nicht geprüft: V6 (vorschlaege gehört der UI), Anzeigenamen.
static func validate(chain: Dictionary) -> Array:
	var errs: Array = []
	var links: Array = chain["links"]
	if chain["root_cause"] == "KEINE":
		return errs  # keine Meldung, nichts zu prüfen
	if links.size() < 2:
		errs.append("V1: Kette kürzer als 2 Glieder")
	for i in range(links.size()):
		var l: Dictionary = links[i]
		if not (l.has("pos") and l["pos"] is Vector2i):
			errs.append("V7: Glied %d ohne pos" % i)
		if not l.has("rolle"):
			errs.append("V1: Glied %d ohne rolle" % i)
	if links[0]["rolle"] != "SYMPTOM":
		errs.append("V2: Glied 0 ist nicht SYMPTOM")
	if links[-1]["rolle"] != "WURZEL" or links[-1]["kind"] != "URSACHE":
		errs.append("V2: letztes Glied ist nicht WURZEL/URSACHE")
	if links[-1]["id"] != chain["root_obj"]["id"]:
		errs.append("V3: links[-1].id != root_obj.id")
	if links[-1]["pos"] != chain["root_pos"]:
		errs.append("V3/D9: links[-1].pos != root_pos")
	if links[0]["kind"] != "FAHRZEUG" or links[0]["id"] != chain["vehicle_id"]:
		errs.append("V4: Glied 0 ist nicht das angefragte Fahrzeug")
	if chain["is_deadlock"]:
		if chain["cycle"].is_empty():
			errs.append("V5: is_deadlock ohne cycle")
		var bi: int = chain["cycle_back_index"]
		if bi < 0 or bi >= links.size() or links[bi]["kind"] != "FAHRZEUG" or links[bi]["id"] != chain["cycle"][0]:
			errs.append("V5: cycle_back_index %d zeigt nicht auf das erste Zyklusmitglied" % bi)
		for vid in chain["cycle"]:
			var found := false
			for l in links:
				if l["kind"] == "FAHRZEUG" and l["id"] == vid:
					found = true
			if not found:
				errs.append("V5: Zyklusmitglied %d nicht in der Kette" % vid)
	var need := {
		"EINGLEISIG_GEGENVERKEHR": ["strecke_mm", "strecke_felder", "gleiszahl", "n_fahrzeuge"],
		"DEADLOCK": ["n_fahrzeuge", "bloecke"],
		"WARTEN_AUF_LADUNG": ["fuell_ist", "fuell_soll", "n_lkw"],
		"BLOCK_BELEGT_UNTERWEGS": ["halter_id"],
	}
	for k in need[chain["root_cause"]]:
		if not chain["params"].has(k):
			errs.append("D9: params.%s fehlt bei %s" % [k, chain["root_cause"]])
	return errs


## Nur für Konsolen-Log des Spikes (keine UX-Textvorlage, die gehört zu Aylin/A-05).
static func debug_text(chain: Dictionary) -> String:
	var parts: PackedStringArray = []
	for l in chain["links"]:
		var p: Vector2i = l["pos"]
		parts.append("%s#%d@(%d,%d)" % [l["kind"], l["id"], p.x, p.y])
	var rp: Vector2i = chain["root_pos"]
	return "V%d: %s | Ursache=%s @(%d,%d) params=%s Vorschlag=%s wartet=%d Ticks" % [
		chain["vehicle_id"], " -> ".join(parts), chain["root_cause"], rp.x, rp.y,
		JSON.stringify(chain["params"]), chain["suggestion_id"], chain["wait_ticks"]]
