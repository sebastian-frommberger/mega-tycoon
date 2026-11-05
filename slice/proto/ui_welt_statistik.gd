extends RefCounted
## S8 AT-10 (Mira): Kennzahlen je Fahrzeug und Linie je Spielminute (Periode = 600 Ticks), tick-genau.
## Aufruf: nach_tick() nach jedem proto_sim.tick() (über ui_welt.nach_tick aus prototyp_welt.sim_schritt).
## Je Fahrzeug und Periode: Ertrag = Σ lieferungen.cent, Fahrkosten = Δ sim.v_fields × v_var_cent (gleiche Rechnung wie
## sim_world: line_cost_cent += ganze Felder × v_var_cent), Fix = proto_sim.fix_eff am Periodenende.
## Gewinn je Linie = Σ (Ertrag − Fahrkosten − fix_eff) der Fahrzeuge der Linie (Definition AT-10, e6).
## Nur Lesesicht, keine Schreibzugriffe auf Sim oder Ökonomie.

var ps = null
var _lief_idx := 0
var _felder: Dictionary = {}         # vid -> v_fields am letzten Periodenende
var _lauf: Dictionary = {}           # vid -> {ertrag, units}
var fz_letzte: Dictionary = {}       # vid -> {ertrag, units, fahrk, fix, gewinn} der letzten vollen Periode
var linien: Dictionary = {}          # "von|nach" (Knoten) -> {von, nach, vids, ertrag, fahrk, fix, gewinn, units}
var linien_verlauf: Dictionary = {}  # "von|nach" -> Array[int] Gewinne der letzten Perioden (max. VERLAUF)
var ort_v: Dictionary = {}           # Stadt-Site -> Array[int] V in Promille (geliefert/Bedarf) der letzten Perioden
var perioden := 0                    # Zahl abgeschlossener Perioden seit Start der Statistik
var letzte_periode_tick := -1
const VERLAUF := 6


func _init(p_ps) -> void:
	ps = p_ps


static func schluessel(von: int, nach: int) -> String:
	return "%d|%d" % [von, nach]


func nach_tick() -> void:
	if ps == null or ps.eco == null:
		return
	while _lief_idx < ps.lieferungen.size():
		var l: Dictionary = ps.lieferungen[_lief_idx]
		_lief_idx += 1
		var vid := int(l["vid"])
		if not _lauf.has(vid):
			_lauf[vid] = {"ertrag": 0, "units": 0}
		_lauf[vid]["ertrag"] += int(l["cent"])
		_lauf[vid]["units"] += int(l["menge"])
	if ps.sim.tick_count % int(ps.eco.periode_ticks) == 0:
		abschluss()


func abschluss() -> void:
	fz_letzte = {}
	var neu: Dictionary = {}
	for f in ps.fahrzeuge:
		var vid := int(f["vid"])
		var i: int = ps.sim.slot_of(vid)
		var fl: int = ps.sim.v_fields[i]
		var fahrk: int = (fl - int(_felder.get(vid, 0))) * int(ps.sim.v_var_cent[i])
		_felder[vid] = fl
		var l: Dictionary = _lauf.get(vid, {"ertrag": 0, "units": 0})
		var fix: int = ps.fix_eff(f)
		var g: int = int(l["ertrag"]) - fahrk - fix
		fz_letzte[vid] = {"ertrag": int(l["ertrag"]), "units": int(l["units"]), "fahrk": fahrk, "fix": fix, "gewinn": g}
		if int(f.get("kauf_cent", 0)) <= 0:           # feste Kette (geschenkt): keine Spielerlinie
			continue
		var k := schluessel(int(f["von"]), int(f["nach"]))
		if not neu.has(k):
			neu[k] = {"von": int(f["von"]), "nach": int(f["nach"]), "vids": [], "ertrag": 0, "fahrk": 0, "fix": 0, "gewinn": 0, "units": 0}
		var z: Dictionary = neu[k]
		z["vids"].append(vid)
		for feld in ["ertrag", "fahrk", "fix", "gewinn", "units"]:
			z[feld] += int(fz_letzte[vid][feld])
	_lauf = {}
	linien = neu
	for k in linien:
		if not linien_verlauf.has(k):
			linien_verlauf[k] = []
		linien_verlauf[k].append(int(linien[k]["gewinn"]))
		while linien_verlauf[k].size() > VERLAUF:
			linien_verlauf[k].pop_front()
	# Orte: V der eben beendeten Periode (s_sat gilt für Periode p, solange in p+1 noch nichts geliefert wurde)
	var e = ps.eco
	var p_fertig: int = ps.sim.tick_count / int(e.periode_ticks) - 1
	for site in e.s_kind.size():
		if e.s_kind[site] != 1:                         # Economy.K_STADT
			continue
		var geliefert := 0
		if int(e.s_sat_period[site]) == p_fertig:
			geliefert = int(e.s_sat[site].get("nahrung", 0))
		var v: int = geliefert * 1000 / maxi(1, e.city_demand(site))
		if not ort_v.has(site):
			ort_v[site] = []
		ort_v[site].append(v)
		while ort_v[site].size() > VERLAUF:
			ort_v[site].pop_front()
	perioden += 1
	letzte_periode_tick = ps.sim.tick_count


## Verlustperioden am Stück (von hinten) einer Linie.
func verlust_serie(k: String) -> int:
	var n := 0
	var a: Array = linien_verlauf.get(k, [])
	for i in range(a.size() - 1, -1, -1):
		if int(a[i]) < 0:
			n += 1
		else:
			break
	return n
