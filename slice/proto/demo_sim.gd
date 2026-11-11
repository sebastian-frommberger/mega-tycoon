extends "res://proto/proto_sim.gd"
## Demo-Sprint (10.11.2026): DemoSim = ProtoSim + alles, was die 30-Minuten-Demo braucht. Nur aktiv mit `--demo`
## (prototyp_welt.gd legt dann diese Klasse statt ProtoSim an). ProtoSim, Slice und alle Bestandstests bleiben unberührt.
##
##   Ketten      data/demo_welt.json "oekonomie" → economy.apply_demo: Holz → Bretter, Kohle + Erz → Eisen → Werkzeug,
##               6 neue Betriebe ("betriebe"), 4 davon ohne Straßenanschluss (eigener Anschlussknoten, Grad 0).
##   Bauen       bau_angebot/bauen(art, punkte): Straße oder Gleis als Linienzug. Enden rasten an Netzknoten, an den
##               Anschlusspunkt eines Betriebs (Straße) bzw. an Bahnhöfe/Gleisknoten (Gleis). Gleis und Straße sind im
##               Sim-Graphen getrennte Komponenten: Züge fahren nur auf Gleis, Fuhrwerke nur auf Straße.
##   Fahrzeuge   Generationen aus "fahrzeuge" (Fuhrwerk 1820, Planwagen 1822, Frachtwagen 1826; Pferdebahn 1824, Dampfzug 1828).
##   Firmensitz  hq_vorschau/hq_platzieren(pos): frei in einem Ort, Radius/Lizenzpreise/Heimatbonus aus der Lage; 3 Stufen, 3 Anbauten.
##   Skilltree   3 Äste × 4 Knoten, Punkte nur aus Meilensteinen, Respec frei; Wirkung über boni_anwenden() (B_skill u. a.).
##   Verträge    Angebote alle intervall_ticks (deterministisch aus vertrag_seed), annehmen/ablehnen, Fortschritt aus dem
##               Ertragsbuch (eco.ledger), Prämie/Strafe über core/konto.gd, Ruf.
##   Aktionen    aktionen_moeglich(): was der Spieler jetzt sinnvoll und bezahlbar tun kann (Demo-Bot Gate A, UI-Hinweis).
## Alle Kassenänderungen laufen über konto.charge/erstatten (W12). Alles ganzzahlig und tick-getrieben (deterministisch).

const DEMO_JSON := "res://data/demo_welt.json"
const SEE_JSON := "res://world/data/proto/proto_see.json"
const BAHNHOF_MIN_ABSTAND_M := 6.0

var demo := true
var daten: Dictionary = {}
var see_kreise: Array = []            # [[x, z, r]] stehende Gewässer (Bauverbot)
var orte_liste: Array = []            # proto_orte.json orte (HQ-Platzierung)
var betrieb_pos: Dictionary = {}      # Stationsname -> Vector2 (Gebäudemitte, UI-Klick/Schild)
var betrieb_typ: Dictionary = {}      # Stationsname -> industrie_id (Demo-Betriebe)
var gleis_knoten: Dictionary = {}     # Knoten-ID -> true (Gleisnetz)
var bahnhof: Dictionary = {}          # Stationsname -> Gleisknoten
var bauwerke: Array = []              # [{art, weg, felder, kosten_cent, laenge_m, von, nach, bruecke_m, tick}]
var _knoten_next := 1
var _kante_next := 1
# Firmensitz
var hq_platziert := false
var hq_pos := Vector2.ZERO
var hq_ort := ""                      # Ortsname
var hq_stufe := 1
var hq_anbauten: Array = []           # IDs
var hq_knoten := -1
var hq_umzuege := 0
# Skilltree
var skillpunkte := 0                  # verdient gesamt
var skills: Array = []                # gesetzte Knoten-IDs (Reihenfolge)
var meilensteine_erreicht: Dictionary = {}   # id -> Tick
# Verträge
var vertrag_seed := 1
var _vz := 1
var _vertrag_nr := 0
var vertraege_angebote: Array = []
var vertraege_aktiv: Array = []
var vertraege_log: Array = []         # [{id, ergebnis, tick, cent}]
var vertraege_erfuellt := 0
var vertraege_verfehlt := 0
var ruf := 0
var _ledger_idx := 0
var geliefert: Dictionary = {}        # gut_id -> Einheiten gesamt (Meilensteine)
var ereignisse: Array = []            # [{tick, art, text}] Chronik (Bot, UI)
var ertrag_periode_cent := 0          # Ertrag der letzten vollen Spielminute
var _rev_alt := 0
var _basis: Dictionary = {}           # Grundwerte vor Boni (lic_share, upkeep, demand, credit)
var _prof_cache: Dictionary = {}
var _demo_katalog: Array = []
var zug_gekauft := false


func _init(p_regelwerk: Dictionary = {}) -> void:
	super(p_regelwerk)
	if FileAccess.file_exists(DEMO_JSON):
		var d = JSON.parse_string(FileAccess.get_file_as_string(DEMO_JSON))
		if d is Dictionary:
			daten = d
	var k_arg := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tempo_k="):
			k_arg = true
		elif a.begins_with("--vertrag_seed=") and a.substr(15).is_valid_int():
			vertrag_seed = int(a.substr(15))
	if not k_arg:
		tempo_k = maxi(1, int(daten.get("tempo_k", tempo_k)))
	if FileAccess.file_exists(SEE_JSON):
		var s = JSON.parse_string(FileAccess.get_file_as_string(SEE_JSON))
		if s is Dictionary:
			for key in s:
				if s[key] is Dictionary and s[key].has("mitte_m") and s[key].has("radius_m"):
					see_kreise.append([float(s[key]["mitte_m"][0]), float(s[key]["mitte_m"][1]), float(s[key]["radius_m"]) * 1.12])


# ------------------------------------------------------------------ Start

func graph_bauen(p_strassen) -> void:
	if p_strassen != null and p_strassen.has_method("zuruecksetzen"):
		p_strassen.zuruecksetzen()                 # neues Spiel = Grundnetz (gebaute Wege eines früheren Spiels entfernen)
	super.graph_bauen(p_strassen)
	_knoten_next = 1
	for nid in knoten_pos:
		_knoten_next = maxi(_knoten_next, int(nid) + 1)
	_kante_next = 1
	for eid in kante:
		_kante_next = maxi(_kante_next, int(eid) + 1)


func oeko_laden() -> bool:
	eco = Economy.new()
	if not eco.load_from(SLICE_JSON, CONSTS_JSON):
		fehler.append("Ökonomie-JSON: " + ", ".join(eco.errors))
		eco = null
		return false
	var pj = JSON.parse_string(FileAccess.get_file_as_string(PROTO_JSON)) if FileAccess.file_exists(PROTO_JSON) else {}
	if pj is Dictionary:
		if daten.has("oe_set") and daten["oe_set"] != null:
			pj["kalibrierung_aktiv_set"] = String(daten["oe_set"])      # Demo aktiviert den Satz (Nutzerargument --oe_set= gewinnt)
		eco.apply_proto(pj)
	eco.apply_demo(daten.get("oekonomie", {}))
	if not eco.ok:
		fehler.append("Demo-Ökonomie: " + ", ".join(eco.errors))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--a=") and arg.substr(4).is_valid_int():
			eco.ertrag_a_promille = int(arg.substr(4))
	eco.attach(sim)
	sim.feld_mm = eco.feld_mm
	konto.eco = eco
	credit.setup(eco)
	return true


func _knoten_neu(p: Vector2, y: float) -> int:
	var id := _knoten_next
	_knoten_next += 1
	knoten_pos[id] = Vector3(p.x, y, p.y)
	knoten_grad[id] = 0
	knoten_wege[id] = 0
	sim.add_node(id, Vector2i(roundi(p.x * mm_pro_m), roundi(p.y * mm_pro_m)), "k%d" % id)
	return id


func _hoehe(p: Vector2) -> float:
	if strassen != null and strassen.hoehe_funktion.is_valid():
		return float(strassen.hoehe_funktion.call(p.x, p.y))
	return 0.0


## Demo-Start: Ökonomie + Overlay, Bestandsorte, Demo-Betriebe (eigener Anschlussknoten, wenn nicht am Netz), Firma mit
## Startkapital. Der Firmensitz ist noch nicht platziert: bis hq_platzieren() lehnt die Spieler-API mit "kein_hq" ab.
func spiel_starten(orte: Dictionary) -> bool:
	if not oeko_laden():
		return false
	if not orte_registrieren(orte):
		return false
	orte_liste = orte.get("orte", [])
	for ind in orte.get("industrie", []):
		betrieb_pos[String(ind.get("name", ""))] = Vector2(float(ind["x"]), float(ind["z"]))
	for o in orte_liste:
		betrieb_pos[String(o.get("name", ""))] = Vector2(float(o["x"]), float(o["z"]))
	for b in daten.get("betriebe", []):
		var nm := String(b["name"])
		var p := Vector2(float(b["x"]), float(b["z"]))
		var lp := p
		if b.get("ladeplatz") is Dictionary:
			lp = Vector2(float(b["ladeplatz"]["x"]), float(b["ladeplatz"]["z"]))
		var n := -1
		if bool(b.get("angeschlossen", false)):
			n = _freier_knoten_bei(lp)
		if n < 0:
			n = _knoten_neu(lp, _hoehe(lp))
		var site: int = eco.add_industry_site(n, String(b["typ"]))
		if site < 0:
			fehler.append("Demo-Betrieb %s: Typ %s unbekannt" % [nm, b["typ"]])
			continue
		stationen[nm] = {"knoten": n, "site": site, "k": eco.s_station[site], "id": String(b["typ"]), "ort_id": String(b["id"]),
			"abstand_m": lp.distance_to(Vector2(knoten_pos[n].x, knoten_pos[n].z))}
		betrieb_pos[nm] = p
		betrieb_typ[nm] = String(b["typ"])
	var pd: Dictionary = daten.get("personen", {})
	for h in pd.get("haltestellen", []):
		var hn := String(h["name"])
		var hp := Vector2(float(h["x"]), float(h["z"]))
		var hk := _freier_knoten_bei(hp)
		if hk < 0:
			fehler.append("Haltestelle %s: kein freier Straßenknoten" % hn)
			continue
		var cid := "halt_" + String(h["id"])
		eco.c_index[cid] = {"id": cid, "stage_id": "haltestelle", "einwohner_anzahl": int(h["ew"])}
		var hs: int = eco.add_city_site(hk, cid)
		stationen[hn] = {"knoten": hk, "site": hs, "k": eco.s_station[hs], "id": cid, "ort_id": String(h["id"]), "abstand_m": 0.0, "haltestelle": true}
		betrieb_pos[hn] = hp
	for nm in stationen:
		var ps_site: int = stationen[nm]["site"]
		if eco.s_kind[ps_site] == Economy.K_STADT and eco.g_index.has(String(pd.get("gut", "fahrgaeste"))):
			personen_sites.append(ps_site)
			personen_acc.append(0)
	if not eco.start_company_at(_reg["n_dorf"], "dorf"):
		fehler.append("Start: Firma nicht gegründet")
		return false
	_basis = {"lic_share": eco.lic_share, "upkeep": eco.upkeep_per_level, "demand": eco.demand_factor,
		"kredit_limit": credit.limit_cent, "zins": credit.interest_pm, "hq_radius": eco.hq_radius_felder}
	_vz = (vertrag_seed * 7919 + 104729) & 0x7fffffff
	vdef("")
	boni_anwenden()
	return fehler.is_empty()


## Nächster Straßenknoten bis 30 m, an dem noch kein Standort hängt (Betriebe am Bestandsnetz).
func _freier_knoten_bei(p: Vector2) -> int:
	var best := -1
	var bd := 30.0
	for nid in knoten_grad:
		if knoten_grad[nid] == 0 or gleis_knoten.has(nid) or eco.site_of_node(nid) >= 0:
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd:
			bd = d
			best = nid
	return best


func _spielbar() -> String:
	var g := super._spielbar()
	if g == "" and not hq_platziert:
		return "kein_hq"
	return g


func _log(art: String, text: String, melden := true) -> void:
	ereignisse.append({"tick": sim.tick_count, "art": art, "text": text})
	if melden:
		meldungen.append(text)


# ------------------------------------------------------------------ Fahrzeuge (Generationen, Züge)

func vdef(def_id: String) -> Dictionary:
	if _demo_katalog.is_empty():
		super.vdef("")
		for v in daten.get("fahrzeuge", []):
			var d: Dictionary = {}
			for k in v:
				d[k] = int(v[k]) if v[k] is float else v[k]
			_vdefs[String(d["id"])] = d
			_demo_katalog.append(String(d["id"]))
	return _vdefs.get(def_id, {})


func _katalog() -> Array:
	vdef("")
	return _demo_katalog


func _gesperrt(_id: String) -> bool:
	return false


## Modelle einer Kategorie ("fuhrwerk" | "zug"), die im laufenden Jahr kaufbar sind, alt → neu.
func modelle(kategorie: String, nur_verfuegbar := true) -> Array:
	var r: Array = []
	for id in _katalog():
		var d: Dictionary = _vdefs[id]
		if String(d.get("kategorie", "")) != kategorie:
			continue
		if nur_verfuegbar and kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
			continue
		r.append(id)
	r.sort_custom(func(a, b): return int(_vdefs[a].get("generation", 0)) < int(_vdefs[b].get("generation", 0)))
	return r


## Neuestes kaufbares Modell der Kategorie.
func def_fuer(kat: String) -> String:
	var kategorie := "zug" if kat in ["zug", "pferdebahn", "dampflok", "dampfzug"] else ("fuhrwerk" if not (kat in ["kutsche", "pzug"]) else kat)
	var m := modelle(kategorie)
	if m.is_empty():
		return super.def_fuer(kat)
	return String(m[-1])


func bonus(key: String) -> int:
	var s := 0
	for ast in daten.get("skilltree", {}).get("aeste", []):
		for kn in ast.get("knoten", []):
			if kn["id"] in skills:
				s += int(kn.get("wirkung", {}).get(key, 0))
	for an in daten.get("hq", {}).get("anbauten", []):
		if an["id"] in hq_anbauten:
			s += int(an.get("wirkung", {}).get(key, 0))
	return s


func _kap(d: Dictionary) -> int:
	var k := int(d.get("kapazitaet_einheiten", 10))
	var pm := bonus("kap_zug_pm") if auf_gleis(d) else bonus("kap_strasse_pm")
	return k * (1000 + pm) / 1000


func _preis(d: Dictionary) -> int:
	return int(d.get("kauf_cent", 0)) * (1000 - mini(500, bonus("fz_kauf_pm"))) / 1000


## Unterhalt mit Alterung ab der letzten Überholung (Depot) und Boni.
func fix_eff(f: Dictionary) -> int:
	if f.is_empty() or f.get("verkauft", false):
		return 0
	var fix := int(f.get("fix_cent", 0))
	if alterung_an and fix > 0:
		var bp := int(vdef(String(f.get("def_id", ""))).get("alterung_unterhalt_bp_pro_jahr", 0))
		fix = fix * (10000 + bp * maxi(0, alter_jahre(f) - int(f.get("ueberholt_jahre", 0)))) / 10000
	return fix * (1000 - mini(500, bonus("fz_fix_pm"))) / 1000


func profil_fuer(kat: String, d: Dictionary):
	var tempo := int(d.get("tempo_promille", 600))
	var gleis := auf_gleis(d)
	var key := "%s:%d:%s" % [kat, tempo, str(gleis)]
	if _prof_cache.has(key):
		return _prof_cache[key]
	var p = Easing.Profil.aus_regelwerk(regelwerk, "fuhrwerk")
	p.kat = kat
	var mpf := float(regelwerk.get("skalen", {}).get("m_pro_feld", Easing.M_PRO_FELD))
	if tempo % tempo_k != 0:
		fehler.append("tempo_k %d teilt %s-Tempo %d nicht ganzzahlig" % [tempo_k, kat, tempo])
	p.v_nom = float(tempo / tempo_k) / 1000.0 * mpf
	if gleis:
		p.spur = 0.0
		p.roll_max = 0.0
		p.wipp_m = 0.0 if kat != "pferdebahn" else p.wipp_m * 0.5
		if kat == "dampflok":
			p.laenge_m = 24.0
			p.nick_max = deg_to_rad(0.5)
	_prof_cache[key] = p
	return p


func ist_zug(f: Dictionary) -> bool:
	return auf_gleis(vdef(String(f.get("def_id", ""))))


func auf_gleis(d: Dictionary) -> bool:
	return bool(d.get("gleis", String(d.get("kategorie", "")) == "zug"))


func fracht(d: Dictionary) -> String:
	return String(d.get("fracht", "gueter"))


## Passt die Fracht des Modells zur Station? Personen nur an Orten/Haltestellen, Güter nur ab Betrieben.
func fracht_passt(d: Dictionary, name: String, als_quelle: bool) -> bool:
	var site: int = stationen[name]["site"]
	var stadt: bool = eco.s_kind[site] == Economy.K_STADT
	if fracht(d) == "personen":
		return stadt
	return not stadt if als_quelle else true


## Straßenweg zwischen zwei Stationen (leer = keine Verbindung). Ergebnis je Paar gemerkt, bis wieder gebaut wird
## (aktionen_moeglich und die UI fragen das mehrmals je Sekunde; das Netz ändert sich nur in bauen()).
var _routen: Dictionary = {}

func strassenroute(von_name: String, nach_name: String) -> Array:
	if not stationen.has(von_name) or not stationen.has(nach_name):
		return []
	var key := "s|%s|%s" % [von_name, nach_name]
	if not _routen.has(key):
		_routen[key] = sim.graph.find_path(int(stationen[von_name]["knoten"]), int(stationen[nach_name]["knoten"]))
	return _routen[key]


func gleisroute(von_name: String, nach_name: String) -> Array:
	if not bahnhof.has(von_name) or not bahnhof.has(nach_name):
		return []
	var key := "g|%s|%s" % [von_name, nach_name]
	if not _routen.has(key):
		_routen[key] = sim.graph.find_path(int(bahnhof[von_name]), int(bahnhof[nach_name]))
	return _routen[key]


func route_fuer(von_name: String, nach_name: String, def_id: String) -> Array:
	if auf_gleis(vdef(def_id)):
		return gleisroute(von_name, nach_name)
	return strassenroute(von_name, nach_name)


## Ersetzen: neues Modell derselben Kategorie; Tempo und Darstellung des neuen Modells (Linie, Position, Ladung bleiben).
func fahrzeug_ersetzen(vid: int, def_id := "") -> Dictionary:
	var f := fahrzeug(vid)
	var r := super.fahrzeug_ersetzen(vid, def_id)
	if not r.get("ok", false):
		return r
	var d := vdef(String(f["def_id"]))
	var dar := String(d.get("darstellung", f["kat"]))
	var prof = profil_fuer(dar, d)
	if prof != f["profil"]:
		f["kat"] = dar
		f["profil"] = prof
		sim.set_vehicle_speed(vid, roundi(prof.v_nom * mm_pro_m))
		var legs: Array = [null, null]
		var hin: Array = f["route"]
		legs[0] = routenlinie(hin, prof)
		legs[1] = routenlinie(sim.graph.reverse_route(hin), prof)
		f["legs"] = legs
		f["zustand"] = Easing.Zustand.new(prof, legs)
		_probe(f)
		f["zustand"].folger_setzen()
	f["name"] = "%s %d" % [String(d.get("name", "Fahrzeug")), vid]
	_var_neu(f)
	_log("ersetzt", "%s fährt jetzt auf der Linie." % f["name"], false)
	return r


## Bestes neueres Modell für ein Fahrzeug ("" = keins): Angebot „Ersetzen“ der UI und des Bots.
func neueres_modell(vid: int) -> String:
	var f := fahrzeug(vid)
	if f.is_empty() or f["verkauft"] or String(f.get("def_id", "")) == "":
		return ""
	var d := vdef(String(f["def_id"]))
	var m := modelle(String(d.get("kategorie", "")))
	if m.is_empty():
		return ""
	var neu := String(m[-1])
	if int(vdef(neu).get("generation", 0)) > int(d.get("generation", 0)):
		return neu
	return ""


func _fix_extra() -> int:
	var c := 0
	var su := 1000 - mini(800, bonus("strecke_unterhalt_pm"))
	for bw in bauwerke:
		if not bw.get("verkauft", false):
			c += int(bw.get("unterhalt_cent", 0)) * su / 1000
	if maut_gekauft:
		c += int(daten.get("maut", {}).get("unterhalt_cent_pro_periode", 0)) * su / 1000
	var n_dep := 0
	for dp in depots:
		if not dp.get("fuhrhof", false):
			n_dep += 1
	c += n_dep * int(daten.get("depot", {}).get("unterhalt_cent_pro_periode", 0)) * (1000 - mini(1000, bonus("depot_unterhalt_pm"))) / 1000
	for rec in abgestellt:                               # abgestellte Fahrzeuge: Stallkosten (Anteil des Unterhalts)
		c += fix_eff(rec) * int(daten.get("depot", {}).get("abgestellt_unterhalt_promille", 250)) / 1000
	var st: Array = daten.get("hq", {}).get("stufen", [])
	if hq_platziert and hq_stufe - 1 < st.size():
		c += int(st[hq_stufe - 1].get("unterhalt_cent_pro_periode", 0))
	return c


# ------------------------------------------------------------------ Boni (Skilltree + HQ) auf die Ökonomie legen

func boni_anwenden() -> void:
	if eco == null or _basis.is_empty():
		return
	var cap: int = int(eco.slice.get("ertrag", {}).get("skill_bonus_cap_promille", 400))
	eco.skill_bonus = mini(cap, bonus("ertrag_pm"))
	var cat := {}
	if bonus("ertrag_nahrung_pm") > 0:
		cat["nahrung"] = mini(cap - eco.skill_bonus, bonus("ertrag_nahrung_pm"))
	if bonus("ertrag_personen_pm") > 0:
		cat["personen"] = mini(cap - eco.skill_bonus, bonus("ertrag_personen_pm"))
	eco.demo_cat_bonus = cat
	eco.demand_factor = int(_basis["demand"]) * (1000 + bonus("nachfrage_pm")) / 1000
	eco.lic_share = int(_basis["lic_share"]) * (1000 - mini(800, bonus("lizenz_pm"))) / 1000
	eco.upkeep_per_level = int(_basis["upkeep"]) * (1000 - mini(800, bonus("werk_unterhalt_pm"))) / 1000
	var st: Array = daten.get("hq", {}).get("stufen", [])
	var hs: Dictionary = st[hq_stufe - 1] if hq_platziert and hq_stufe - 1 < st.size() else {}
	credit.limit_cent = int(_basis["kredit_limit"]) + bonus("kredit_limit_cent") + int(hs.get("kredit_bonus_cent", 0))
	credit.interest_pm = maxi(0, int(_basis["zins"]) - bonus("zins_pm"))
	if hq_platziert:
		eco.hq_radius_felder = int(_basis["hq_radius"]) + int(hs.get("radius_bonus_felder", 0))
	_raten_neu()
	for f in fahrzeuge:
		if f["verkauft"] or String(f.get("def_id", "")) == "":
			continue
		sim.v_cargo_cap[sim.slot_of(f["vid"])] = _kap(vdef(String(f["def_id"])))
		_var_neu(f)
	_fix_dirty = true


## Durchsatz aller Verarbeiter = Werksstufe (demo_rate/fabrik) × (1 + Skill „Mahlrecht“).
func _raten_neu() -> void:
	var pm := bonus("durchsatz_pm")
	for site in range(eco.s_kind.size()):
		if eco.s_kind[site] != Economy.K_INDUSTRIE or eco.s_raw[site] == 1 or eco.s_out_good[site] < 0:
			continue
		eco.s_rate[site] = eco.demo_rate_basis(site) * (1000 + pm) / 1000


func werk_ausbauen(name: String) -> Dictionary:
	var r := super.werk_ausbauen(name)
	if r.get("ok", false):
		_raten_neu()
		_log("ausbau", "%s ausgebaut: %d E/min." % [name, int(eco.s_rate[_site_von(name)])], false)
	return r


## Demo-Gate (offener Punkt S8 „Mühle ab Minute 0 kaufbar“): Betriebe stehen erst ab firmenkauf_ab_jahr zum Verkauf.
func kauf_angebot(name: String) -> Dictionary:
	var q := super.kauf_angebot(name)
	var ab := int(daten.get("firmenkauf_ab_jahr", 0))
	if q.get("ok", false) and kalenderjahr() < ab and String(q.get("grund", "")) == "":
		q["kaufbar"] = false
		q["grund"] = "noch_nicht_verfuegbar"
		q["ab_jahr"] = ab
	return q


func firma_kaufen(name: String) -> Dictionary:
	var ab := int(daten.get("firmenkauf_ab_jahr", 0))
	if kalenderjahr() < ab and _spielbar() == "":
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": ab})
	var r := super.firma_kaufen(name)
	if r.get("ok", false):
		_log("firma", "%s gekauft." % name, false)
	return r


# ------------------------------------------------------------------ Bauen: Straße und Gleis

func ist_nass(p: Vector2) -> bool:
	return strassen != null and strassen.nass(p.x, p.y)


func im_see(p: Vector2) -> bool:
	for k in see_kreise:
		if p.distance_to(Vector2(k[0], k[1])) <= float(k[2]):
			return true
	return false


func bau_regel(art: String) -> Dictionary:
	return daten.get("bau", {}).get(art, {})


func angeschlossen(name: String) -> bool:
	return stationen.has(name) and int(knoten_grad.get(int(stationen[name]["knoten"]), 0)) > 0


## Einrasten eines Endpunkts. {typ: "knoten"|"betrieb"|"bahnhof"|"bahnhof_neu"|"frei", knoten, name, pos}
func fang(art: String, p: Vector2) -> Dictionary:
	var rg := bau_regel(art)
	var r_kn := float(rg.get("fang_knoten_m", 20.0))
	var r_be := float(rg.get("fang_betrieb_m", 45.0))
	var best := -1
	var bd := r_kn
	for nid in knoten_grad:
		if knoten_grad[nid] == 0:
			continue
		if (art == "gleis") != gleis_knoten.has(nid):
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd:
			bd = d
			best = nid
	var bn := ""
	var bnd := r_be
	for nm in stationen:
		var hp := halt_pos(nm)
		var d2 := minf(p.distance_to(hp), p.distance_to(betrieb_pos.get(nm, hp)))
		if d2 < bnd:
			bnd = d2
			bn = nm
	if art == "gleis":
		if bn != "" and bahnhof.has(bn) and (best < 0 or best == int(bahnhof[bn]) or bnd < bd):
			var nb: int = bahnhof[bn]
			return {"typ": "bahnhof", "knoten": nb, "name": bn, "pos": Vector2(knoten_pos[nb].x, knoten_pos[nb].z)}
		if best >= 0:
			return {"typ": "knoten", "knoten": best, "name": "", "pos": Vector2(knoten_pos[best].x, knoten_pos[best].z)}
		if bn != "":
			return {"typ": "bahnhof_neu", "knoten": -1, "name": bn, "pos": _bahnhof_platz(bn, p)}
		return {"typ": "frei", "knoten": -1, "name": "", "pos": p}
	# Straße: nicht angeschlossener Betrieb zuerst (sein Anschlusspunkt), sonst Netzknoten
	if bn != "" and not angeschlossen(bn):
		var n: int = stationen[bn]["knoten"]
		return {"typ": "betrieb", "knoten": n, "name": bn, "pos": Vector2(knoten_pos[n].x, knoten_pos[n].z)}
	if best >= 0:
		return {"typ": "knoten", "knoten": best, "name": "", "pos": Vector2(knoten_pos[best].x, knoten_pos[best].z)}
	return {"typ": "frei", "knoten": -1, "name": "", "pos": p}


func halt_pos(name: String) -> Vector2:
	var n: int = stationen[name]["knoten"]
	return Vector2(knoten_pos[n].x, knoten_pos[n].z)


## Bahnhofspunkt: der Klickpunkt, aber mindestens 12 m neben dem Straßen-Halt (Gleis kreuzt die Ladestraße nicht im Knoten).
func _bahnhof_platz(name: String, p: Vector2) -> Vector2:
	var hp := halt_pos(name)
	if p.distance_to(hp) < 12.0:
		var r := (p - hp)
		r = r.normalized() if r.length() > 0.1 else Vector2(1, 0)
		return hp + r * 12.0
	return p


func _verdichten(pkt: PackedVector2Array, schritt: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pkt.size() - 1:
		var a := pkt[i]
		var b := pkt[i + 1]
		var n := maxi(1, ceili(a.distance_to(b) / schritt))
		for j in n:
			out.append(a.lerp(b, float(j) / n))
	out.append(pkt[-1])
	return out


## Vorschau eines Bauwerks. punkte: Klickpunkte (m, x/z). Ergebnis {ok, kosten_cent, laenge_m, felder, bruecke_m, start, ende,
## punkte (eingerastet), kaufbar, unterhalt_cent} oder {ok: false, fehler, …} mit Details für den Fehlertext.
func bau_angebot(art: String, punkte: PackedVector2Array) -> Dictionary:
	if eco == null or not eco.company_started:
		return _nein("keine_firma")
	if konto.bankrupt:
		return _nein("bankrott")
	if not hq_platziert:
		return _nein("kein_hq")
	var rg := bau_regel(art)
	if rg.is_empty():
		return _nein("unbekannte_bauart")
	if kalenderjahr() < int(rg.get("ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(rg["ab_jahr"])})
	if punkte.size() < 2:
		return _nein("zu_wenig_punkte")
	var a := fang(art, punkte[0])
	var b := fang(art, punkte[-1])
	var pkt := PackedVector2Array(punkte)
	pkt[0] = a["pos"]
	pkt[-1] = b["pos"]
	if a["typ"] == "frei" and b["typ"] == "frei":
		return _nein("kein_anschluss")
	if a["typ"] != "frei" and b["typ"] != "frei" and ((int(a["knoten"]) >= 0 and a["knoten"] == b["knoten"]) or (a["name"] != "" and a["name"] == b["name"])):
		return _nein("gleicher_punkt")
	var bd: Dictionary = daten.get("bau", {})
	var dicht := _verdichten(pkt, 10.0)
	var laenge := 0.0
	var nass_m := 0.0
	var lauf := 0.0
	var lauf_max := 0.0
	for i in dicht.size():
		if i > 0:
			laenge += dicht[i - 1].distance_to(dicht[i])
		if i > 0 and i < dicht.size() - 1 and im_see(dicht[i]):
			return _nein("see", {"bei": dicht[i]})
		if ist_nass(dicht[i]):
			nass_m += 10.0
			lauf += 10.0
			lauf_max = maxf(lauf_max, lauf)
		else:
			lauf = 0.0
	if laenge < float(bd.get("min_laenge_m", 40.0)):
		return _nein("zu_kurz", {"min_m": int(bd.get("min_laenge_m", 40))})
	if laenge > float(bd.get("max_laenge_m", 3500.0)):
		return _nein("zu_lang", {"max_m": int(bd.get("max_laenge_m", 3500))})
	if lauf_max > float(bd.get("max_bruecke_m", 160.0)):
		return _nein("bruecke_zu_lang", {"max_m": int(bd.get("max_bruecke_m", 160))})
	if ist_nass(pkt[0]) or ist_nass(pkt[-1]):
		return _nein("ende_im_wasser")
	# Steigung über 30 m; Uferböschungen neben Wasser zählen nicht (dort liegen Rampe und Brücke, ±50 m)
	var max_pct := float(rg.get("max_steigung_pct", 12.0))
	var ufer := PackedByteArray()
	ufer.resize(dicht.size())
	for i in dicht.size():
		if ist_nass(dicht[i]):
			for j in range(maxi(0, i - 5), mini(dicht.size(), i + 6)):
				ufer[j] = 1
	var steil := 0.0
	for i in range(3, dicht.size()):
		if ufer[i] == 1 or ufer[i - 3] == 1:
			continue
		var dh := absf(_hoehe(dicht[i]) - _hoehe(dicht[i - 3]))
		var dl := maxf(1.0, dicht[i].distance_to(dicht[i - 3]))
		steil = maxf(steil, dh / dl * 100.0)
	if steil > max_pct:
		return _nein("zu_steil", {"pct": int(round(steil)), "max_pct": int(max_pct)})
	if rg.has("max_knick_grad"):
		for i in range(1, pkt.size() - 1):
			var w := absf(rad_to_deg((pkt[i] - pkt[i - 1]).angle_to(pkt[i + 1] - pkt[i])))
			if w > float(rg["max_knick_grad"]):
				return _nein("kurve_zu_eng", {"grad": int(round(w)), "max_grad": int(rg["max_knick_grad"])})
	var mpf := float(regelwerk.get("skalen", {}).get("m_pro_feld", 25.0))
	var felder := maxi(1, int(ceil(laenge / mpf)))
	var nass_felder := int(ceil(nass_m / mpf))
	var je := int(rg.get("kosten_cent_pro_feld", 0))
	var kosten := (felder - nass_felder) * je + nass_felder * je * int(rg.get("bruecke_faktor_promille", 1000)) / 1000
	kosten = kosten * (1000 - mini(800, bonus("bau_%s_pm" % art))) / 1000
	var unterhalt := felder * int(rg.get("unterhalt_cent_pro_feld_pro_periode", 0))
	return _ok({"kosten_cent": kosten, "laenge_m": int(round(laenge)), "felder": felder, "bruecke_m": int(nass_m), "start": a, "ende": b,
		"punkte": pkt, "unterhalt_cent": unterhalt, "kaufbar": kosten <= eco.cash_cent, "fehlt_cent": maxi(0, kosten - eco.cash_cent)})


## Bauen: bucht die Kosten (konto.charge, Kredit erlaubt: Straße), legt Band, Fahrlinie und Sim-Knoten an.
func bauen(art: String, punkte: PackedVector2Array) -> Dictionary:
	var q := bau_angebot(art, punkte)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"]), "kosten_cent": int(q["kosten_cent"])})
	if strassen == null:
		return _nein("kein_netz")
	var rg := bau_regel(art)
	var pkt: PackedVector2Array = q["punkte"]
	var dicht := _verdichten(pkt, 12.0)
	var liste: Array = []
	for p in dicht:
		liste.append([p.x, p.y])
	var wi: int = strassen.weg_hinzufuegen({"typ": String(rg.get("weg_typ", "feldweg")), "punkte": liste, "breite_m": float(rg.get("breite_m", 3.5))})
	var fl = strassen.fahrlinien[wi]
	if fl.anker.size() < 2:
		return _nein("bau_fehlgeschlagen")
	var a: Dictionary = q["start"]
	var b: Dictionary = q["ende"]
	var ids := PackedInt32Array()
	var ss := PackedFloat32Array()
	var n_anker: int = fl.anker.size()
	for k in n_anker:
		var s := float(fl.anker_s[k]) if k < fl.anker_s.size() else 0.0
		if ss.size() > 0:
			s = maxf(s, ss[-1])
		ss.append(s)
		var id := -1
		if k == 0 and int(a["knoten"]) >= 0:
			id = int(a["knoten"])
		elif k == n_anker - 1 and int(b["knoten"]) >= 0:
			id = int(b["knoten"])
		else:
			var ap: Vector2 = fl.anker[k]
			id = _knoten_neu(ap, fl.strecke_punkt(s).y)
			if art == "gleis":
				gleis_knoten[id] = true
		ids.append(id)
		knoten_wege[id] = int(knoten_wege.get(id, 0)) + 1
	while anker_knoten.size() < wi:
		anker_knoten.append(PackedInt32Array())
		anker_s.append(PackedFloat32Array())
	anker_knoten.append(ids)
	anker_s.append(ss)
	for k in ids.size() - 1:
		var na := ids[k]
		var nb := ids[k + 1]
		if na == nb or sim.graph.nodes[na]["pos"] == sim.graph.nodes[nb]["pos"]:
			continue
		var eid := _kante_next
		_kante_next += 1
		sim.graph.add_edge(eid, na, nb, true)
		kante[eid] = [wi, k]
		knoten_grad[na] = int(knoten_grad.get(na, 0)) + 1
		knoten_grad[nb] = int(knoten_grad.get(nb, 0)) + 1
	if art == "gleis":
		if a["typ"] == "bahnhof_neu":
			bahnhof[String(a["name"])] = ids[0]
		if b["typ"] == "bahnhof_neu":
			bahnhof[String(b["name"])] = ids[-1]
	_routen = {}
	_kanten = []
	konto.charge(int(q["kosten_cent"]))
	kauf_total += int(q["kosten_cent"])
	var bw := {"art": art, "weg": wi, "felder": int(q["felder"]), "kosten_cent": int(q["kosten_cent"]), "laenge_m": int(q["laenge_m"]),
		"von": String(a["name"]), "nach": String(b["name"]), "bruecke_m": int(q["bruecke_m"]), "tick": sim.tick_count,
		"unterhalt_cent": int(q["unterhalt_cent"])}
	bauwerke.append(bw)
	_fix_dirty = true
	var txt := "%s gebaut: %d m für %d $." % [String(rg.get("name", art)), int(q["laenge_m"]), int(q["kosten_cent"]) / 100]
	for e in [a, b]:
		if e["typ"] == "betrieb":
			txt += " %s ist angeschlossen." % e["name"]
		elif e["typ"] == "bahnhof_neu":
			txt += " Bahnhof %s." % e["name"]
	_log("bau_" + art, txt, false)
	var r := _ok(bw)
	r["text"] = txt
	return r


func gleis_frei() -> bool:
	return kalenderjahr() >= int(bau_regel("gleis").get("ab_jahr", 9999))


# ------------------------------------------------------------------ Firmensitz

func _ort_bei(p: Vector2) -> Dictionary:
	var best := {}
	var bd := INF
	for o in orte_liste:
		var c := Vector2(float(o["x"]), float(o["z"]))
		var r := float(o.get("r_max_m", o.get("r_m", 150.0)))
		var d := c.distance_to(p)
		if d <= r and d < bd:
			bd = d
			best = o
	return best


func _hq_stufe_daten(st: int = -1) -> Dictionary:
	var l: Array = daten.get("hq", {}).get("stufen", [])
	var i := (hq_stufe if st < 0 else st) - 1
	return l[i] if i >= 0 and i < l.size() else {}


## Standortvorschau (Civ-artig): was bringt der Firmensitz an dieser Stelle? Keine Zustandsänderung.
## {ok, ort, klasse, stufe_id, radius_felder, betriebe [{name, typ, felder, im_radius, lizenz_cent, gratis_moeglich}],
##  im_radius_n, lizenz_summe_cent, heimat (Stationsname oder ""), heimat_bonus_promille, kosten_cent} oder {ok: false, fehler}.
func hq_vorschau(p: Vector2) -> Dictionary:
	if eco == null or not eco.company_started:
		return _nein("keine_firma")
	var o := _ort_bei(p)
	if o.is_empty():
		return _nein("kein_ort")
	if ist_nass(p) or im_see(p):
		return _nein("wasser")
	for nid in knoten_grad:
		if knoten_grad[nid] == 0:
			continue
		var q: Vector3 = knoten_pos[nid]
		if p.distance_to(Vector2(q.x, q.z)) < 7.0:
			return _nein("auf_der_strasse")
	var klasse := String(o.get("klasse", "dorf"))
	var stufe_id := "kleinstadt" if klasse in ["kleinstadt", "marktflecken", "markt"] else "dorf"
	var hd: Dictionary = daten.get("hq", {})
	var radius := int(hd.get("radius_felder", {}).get(stufe_id, eco.hq_radius_felder)) + int(_hq_stufe_daten().get("radius_bonus_felder", 0))
	var alt := [eco.hq_x, eco.hq_y, eco.hq_radius_felder]
	eco.hq_x = roundi(p.x * mm_pro_m)
	eco.hq_y = roundi(p.y * mm_pro_m)
	eco.hq_radius_felder = radius
	var liste: Array = []
	var summe := 0
	var n_in := 0
	for nm in stationen:
		var site: int = stationen[nm]["site"]
		if site < 0 or eco.s_kind[site] != Economy.K_INDUSTRIE or eco.s_out_good[site] < 0:
			continue
		var felder: int = eco._hq_felder(site)
		var lic: int = eco._licence_cost(site)
		var drin := felder <= radius
		liste.append({"name": nm, "typ": String(eco.i_ids[eco.s_def[site]]), "felder": felder, "im_radius": drin, "lizenz_cent": lic})
		summe += lic
		if drin:
			n_in += 1
	eco.hq_x = alt[0]
	eco.hq_y = alt[1]
	eco.hq_radius_felder = alt[2]
	liste.sort_custom(func(x, y): return int(x["felder"]) < int(y["felder"]))
	var heimat := String(o.get("name", "")) if stationen.has(String(o.get("name", ""))) else ""
	return _ok({"ort": String(o.get("name", "")), "klasse": klasse, "stufe_id": stufe_id, "radius_felder": radius, "betriebe": liste,
		"im_radius_n": n_in, "lizenz_summe_cent": summe, "heimat": heimat,
		"heimat_bonus_promille": int(hd.get("heimat_bonus_promille", {}).get(stufe_id, 0)) if heimat != "" else 0,
		"kosten_cent": int(hd.get("umzug_cent", 0)) if hq_platziert else 0, "pos": p})


func hq_platzieren(p: Vector2) -> Dictionary:
	if konto.bankrupt:
		return _nein("bankrott")
	var v := hq_vorschau(p)
	if not v["ok"]:
		return v
	var kosten: int = v["kosten_cent"]
	if kosten > eco.cash_cent:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": kosten - eco.cash_cent})
	if hq_knoten < 0:
		hq_knoten = _knoten_neu(p, _hoehe(p))
	else:
		knoten_pos[hq_knoten] = Vector3(p.x, _hoehe(p), p.y)
		sim.graph.nodes[hq_knoten]["pos"] = Vector2i(roundi(p.x * mm_pro_m), roundi(p.y * mm_pro_m))
	eco.move_hq_to(hq_knoten, String(v["stufe_id"]))
	_basis["hq_radius"] = int(daten.get("hq", {}).get("radius_felder", {}).get(String(v["stufe_id"]), eco.hq_radius_felder))
	if kosten > 0:
		konto.charge(kosten)
		hq_umzuege += 1
	hq_platziert = true
	hq_pos = p
	hq_ort = String(v["ort"])
	eco.demo_site_bonus = {}
	if String(v["heimat"]) != "":
		eco.demo_site_bonus[int(stationen[String(v["heimat"])]["site"])] = int(v["heimat_bonus_promille"])
	_fuhrhof_setzen()
	boni_anwenden()
	_log("hq", "Firmensitz in %s gegründet: %d Betriebe im Umkreis, Lizenzen dort 30 %% billiger." % [hq_ort, int(v["im_radius_n"])], false)
	return v


## Ausbau auf die nächste Stufe. {ok, stufe_neu, name, kosten_cent, kaufbar, radius_bonus_felder, vertraege_max, anbauten_max, …}
func hq_ausbau_angebot() -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var neu := _hq_stufe_daten(hq_stufe + 1)
	if neu.is_empty():
		return _nein("hoechste_stufe")
	var frei: int = eco.cash_cent - credit.loan_cent
	var r := _ok({"stufe_neu": hq_stufe + 1, "kaufbar": frei >= int(neu.get("kosten_cent", 0)), "fehlt_cent": maxi(0, int(neu.get("kosten_cent", 0)) - frei)})
	r.merge(neu)
	return r


func hq_ausbauen() -> Dictionary:
	var q := hq_ausbau_angebot()
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("kredit_sperrt_hq" if credit.loan_cent > 0 and eco.cash_cent >= int(q["kosten_cent"]) else "guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"])})
	konto.charge(int(q["kosten_cent"]))
	kauf_total += int(q["kosten_cent"])
	hq_stufe = int(q["stufe_neu"])
	skillpunkte += int(q.get("skillpunkte", 0))
	boni_anwenden()
	_log("hq_ausbau", "Firmensitz ist jetzt %s: Radius +%d Felder, %d Verträge zugleich." % [String(q.get("name", "")),
		int(q.get("radius_bonus_felder", 0)), int(q.get("vertraege_max", 2))], false)
	return q


func hq_anbau_angebot(id: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	for an in daten.get("hq", {}).get("anbauten", []):
		if String(an["id"]) != id:
			continue
		if id in hq_anbauten:
			return _nein("schon_gebaut")
		if hq_anbauten.size() >= int(_hq_stufe_daten().get("anbauten_max", 1)):
			return _nein("kein_platz", {"max": int(_hq_stufe_daten().get("anbauten_max", 1))})
		var frei: int = eco.cash_cent - credit.loan_cent
		var r := _ok({"kaufbar": frei >= int(an["kosten_cent"]), "fehlt_cent": maxi(0, int(an["kosten_cent"]) - frei)})
		r.merge(an)
		return r
	return _nein("unbekannter_anbau")


func hq_anbauen(id: String) -> Dictionary:
	var q := hq_anbau_angebot(id)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"])})
	konto.charge(int(q["kosten_cent"]))
	kauf_total += int(q["kosten_cent"])
	hq_anbauten.append(id)
	boni_anwenden()
	_log("hq_anbau", "%s gebaut. %s" % [String(q.get("name", id)), String(q.get("text", ""))], false)
	return q


func vertraege_max() -> int:
	return int(_hq_stufe_daten().get("vertraege_max", 2))


# ------------------------------------------------------------------ Skilltree

func skillpunkte_frei() -> int:
	return skillpunkte - skills.size()


func skill_knoten(id: String) -> Dictionary:
	for ast in daten.get("skilltree", {}).get("aeste", []):
		var kn: Array = ast.get("knoten", [])
		for i in kn.size():
			if String(kn[i]["id"]) == id:
				var r: Dictionary = kn[i].duplicate()
				r["ast"] = String(ast["id"])
				r["rang"] = i
				r["braucht"] = String(kn[i - 1]["id"]) if i > 0 else ""
				return r
	return {}


## "gesetzt" | "frei" (kaufbar mit Punkt) | "gesperrt" (Vorgänger fehlt)
func skill_zustand(id: String) -> String:
	if id in skills:
		return "gesetzt"
	var kn := skill_knoten(id)
	if kn.is_empty():
		return "gesperrt"
	if String(kn["braucht"]) != "" and not (String(kn["braucht"]) in skills):
		return "gesperrt"
	return "frei"


func skill_setzen(id: String) -> Dictionary:
	if eco == null or konto.bankrupt:
		return _nein("bankrott")
	var kn := skill_knoten(id)
	if kn.is_empty():
		return _nein("unbekannter_skill")
	match skill_zustand(id):
		"gesetzt":
			return _nein("schon_gesetzt")
		"gesperrt":
			return _nein("vorgaenger_fehlt", {"braucht": String(skill_knoten(String(kn["braucht"])).get("name", ""))})
	if skillpunkte_frei() <= 0:
		return _nein("kein_punkt")
	skills.append(id)
	boni_anwenden()
	_log("skill", "Skill gesetzt: %s. %s" % [String(kn["name"]), String(kn["text"])], false)
	return _ok(kn)


func skill_zuruecksetzen() -> Dictionary:
	var n := skills.size()
	skills = []
	boni_anwenden()
	_log("skill_reset", "Skills zurückgesetzt: %d Punkte wieder frei." % n, false)
	return _ok({"punkte": n})


func _skills_kaufbar() -> Array:
	var r: Array = []
	for ast in daten.get("skilltree", {}).get("aeste", []):
		for kn in ast.get("knoten", []):
			if skill_zustand(String(kn["id"])) == "frei":
				r.append(String(kn["id"]))
	return r


func _meilenstein(id: String) -> void:
	if meilensteine_erreicht.has(id):
		return
	for m in daten.get("meilensteine", []):
		if String(m["id"]) == id:
			meilensteine_erreicht[id] = sim.tick_count
			var sp := int(m.get("skillpunkte", 0))
			skillpunkte += sp
			_log("meilenstein", "Meilenstein: %s.%s" % [String(m["name"]), (" +%d Skillpunkt" % sp) if sp > 0 else ""])
			return


func naechster_meilenstein() -> Dictionary:
	for m in daten.get("meilensteine", []):
		if not meilensteine_erreicht.has(String(m["id"])):
			return m
	return {}


func _meilensteine_pruefen() -> void:
	if hq_platziert:
		_meilenstein("hq")
	if int(geliefert.get("mehl", 0)) > 0:
		_meilenstein("mehl")
	if vertraege_erfuellt >= 1:
		_meilenstein("vertrag1")
	if vertraege_erfuellt >= 3:
		_meilenstein("vertrag3")
	for bw in bauwerke:
		if bw["art"] == "strasse":
			_meilenstein("strasse")
	if int(geliefert.get("bretter", 0)) > 0:
		_meilenstein("bretter")
	if int(geliefert.get("werkzeug", 0)) > 0:
		_meilenstein("werkzeug")
	if int(geliefert.get("fahrgaeste", 0)) > 0:
		_meilenstein("fahrgast")
	if plan3_geliefert:
		_meilenstein("linienplan")
	if zug_gekauft:
		_meilenstein("zug")
	if eco.owned_count >= 1:
		_meilenstein("firma")
	if hq_stufe >= 2:
		_meilenstein("hq2")
	if ertrag_periode_cent >= int(daten.get("umsatz_ziel_cent", 150000)):
		_meilenstein("umsatz")
	for f in fahrzeuge:
		if not f["verkauft"] and String(f.get("def_id", "")) == "dampfzug_d":
			_meilenstein("dampf")


# ------------------------------------------------------------------ Verträge

func _zufall(n: int) -> int:
	_vz = (_vz * 1103515245 + 12345) & 0x7fffffff
	return (_vz >> 8) % maxi(1, n)


func gutname(gid: String) -> String:
	return String(daten.get("gutnamen", {}).get(gid, gid.capitalize()))


## Kanten der Welt: [{von, nach, gut, felder}] für jede Quelle und jeden Abnehmer ihres Guts (fest nach dem Start).
var _kanten: Array = []

func kanten() -> Array:
	if not _kanten.is_empty():
		return _kanten
	var r: Array = []
	for a in stationen:
		var sa: int = stationen[a]["site"]
		if sa < 0 or eco.s_kind[sa] != Economy.K_INDUSTRIE or eco.s_out_good[sa] < 0:
			continue
		var g: int = eco.s_out_good[sa]
		for b in stationen:
			if b == a:
				continue
			var sb: int = stationen[b]["site"]
			if sb < 0:
				continue
			var ok := false
			if eco.s_kind[sb] == Economy.K_STADT:
				ok = eco.city_accepts(sb, g)
			elif eco.s_kind[sb] == Economy.K_INDUSTRIE:
				ok = eco.s_inbuf[sb].has(g)
			if ok:
				r.append({"von": a, "nach": b, "gut": String(eco.g_ids[g]), "felder": eco.luftlinie_felder(sa, sb)})
	_kanten = r
	return r


func _abnahme_je_periode(site: int) -> int:
	if eco.s_kind[site] == Economy.K_STADT:
		return maxi(1, eco.city_demand(site))
	return maxi(1, int(eco.s_rate[site]))


func _vertrag_erzeugen() -> void:
	var vd: Dictionary = daten.get("vertraege", {})
	var t: int = sim.tick_count
	var ab: Dictionary = vd.get("gut_ab_tick", {})
	if _vertrag_nr == 0 and vd.get("erster_vertrag") is Dictionary and stationen.has(String(vd["erster_vertrag"].get("ort", ""))):
		var e: Dictionary = vd["erster_vertrag"]            # Einstieg: kleiner, sicher machbarer Vertrag
		_vertrag_nr = 1
		var v1 := {"id": 1, "ort": String(e["ort"]), "gut": String(e["gut"]), "menge": int(e["menge"]), "frist_ticks": int(e["frist_ticks"]),
			"praemie_cent": int(e["praemie_cent"]), "strafe_cent": int(e["praemie_cent"]) * int(vd.get("strafe_anteil_promille", 400)) / 1000 / 100 * 100,
			"bonus_promille": 0, "angebot_bis_tick": t + int(vd.get("angebot_gilt_ticks", 2400)), "angebot_tick": t}
		vertraege_angebote.append(v1)
		_log("vertrag_angebot", "Erstes Vertragsangebot: %s will %d %s (Taste V)." % [v1["ort"], int(v1["menge"]), gutname(v1["gut"])])
		return
	var kand: Array = []
	for k in kanten():
		if t < int(ab.get(k["gut"], 0)):
			continue
		var doppelt := false
		for v in vertraege_angebote + vertraege_aktiv:
			if v["ort"] == k["nach"] and v["gut"] == k["gut"]:
				doppelt = true
		if not doppelt and not kand.any(func(x): return x["nach"] == k["nach"] and x["gut"] == k["gut"]):
			kand.append(k)
	if kand.is_empty():
		return
	# neue Güter bevorzugen: die letzten drei freigeschalteten Güter zählen doppelt
	var k: Dictionary = kand[_zufall(kand.size())]
	var spaet: Dictionary = kand[_zufall(kand.size())]
	if int(ab.get(spaet["gut"], 0)) > int(ab.get(k["gut"], 0)):
		k = spaet
	var site: int = stationen[k["nach"]]["site"]
	var dauer_l: Array = vd.get("dauer_ticks", [3000])
	var anteil_l: Array = vd.get("anteil_promille", [600])
	var pr_l: Array = vd.get("praemie_promille", [500])
	var dauer := int(dauer_l[_zufall(dauer_l.size())])
	var anteil := int(anteil_l[_zufall(anteil_l.size())])
	var menge := maxi(10, _abnahme_je_periode(site) * dauer / eco.periode_ticks * anteil / 1000 / 5 * 5)
	var wert: int = menge * int(vd.get("praemie_cent_je_einheit", {}).get(k["gut"], 300))
	var praemie := wert * int(pr_l[_zufall(pr_l.size())]) / 1000
	praemie = praemie * (1000 + ruf * int(vd.get("ruf_praemie_promille_je_punkt", 0))) / 1000
	praemie = maxi(5000, praemie / 500 * 500)
	_vertrag_nr += 1
	var bonus_pm := int(vd.get("bonus_promille", 0)) if int(vd.get("bonus_jeder_n", 0)) > 0 and _vertrag_nr % int(vd["bonus_jeder_n"]) == 0 else 0
	var v := {"id": _vertrag_nr, "ort": String(k["nach"]), "gut": String(k["gut"]), "menge": menge, "frist_ticks": dauer,
		"praemie_cent": praemie, "strafe_cent": praemie * int(vd.get("strafe_anteil_promille", 400)) / 1000 / 100 * 100,
		"bonus_promille": bonus_pm, "angebot_bis_tick": t + int(vd.get("angebot_gilt_ticks", 2400)), "angebot_tick": t}
	vertraege_angebote.append(v)
	_log("vertrag_angebot", "Neues Vertragsangebot: %s will %d %s." % [v["ort"], menge, gutname(v["gut"])])


## Prämie eines Angebots/Vertrags mit den aktuellen Boni (Verhandler, Schreibstube).
func vertrag_praemie(v: Dictionary) -> int:
	return int(v["praemie_cent"]) * (1000 + bonus("vertrag_praemie_pm")) / 1000


func _vertrag_finden(liste: Array, id: int) -> int:
	for i in liste.size():
		if int(liste[i]["id"]) == id:
			return i
	return -1


func vertrag_annehmen(id: int) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var i := _vertrag_finden(vertraege_angebote, id)
	if i < 0:
		return _nein("angebot_weg")
	if vertraege_aktiv.size() >= vertraege_max():
		return _nein("zu_viele_vertraege", {"max": vertraege_max()})
	var v: Dictionary = vertraege_angebote[i]
	vertraege_angebote.remove_at(i)
	v["start_tick"] = sim.tick_count
	v["ende_tick"] = sim.tick_count + int(v["frist_ticks"])
	v["geliefert"] = 0
	v["erloes_cent"] = 0
	vertraege_aktiv.append(v)
	_log("vertrag_an", "Vertrag angenommen: %d %s nach %s." % [int(v["menge"]), gutname(v["gut"]), v["ort"]], false)
	return _ok(v)


func vertrag_ablehnen(id: int) -> Dictionary:
	var i := _vertrag_finden(vertraege_angebote, id)
	if i < 0:
		return _nein("angebot_weg")
	vertraege_angebote.remove_at(i)
	vertraege_log.append({"id": id, "ergebnis": "abgelehnt", "tick": sim.tick_count, "cent": 0})
	return _ok({})


func _vertraege_tick() -> void:
	var vd: Dictionary = daten.get("vertraege", {})
	var t: int = sim.tick_count
	# Lieferungen aus dem Ertragsbuch
	var led: Array = eco.ledger
	while _ledger_idx < led.size():
		var e: Dictionary = led[_ledger_idx]
		_ledger_idx += 1
		var gid := String(e["gut"])
		geliefert[gid] = int(geliefert.get(gid, 0)) + int(e["menge"])
		for v in vertraege_aktiv:
			if v["gut"] == gid and int(stationen[v["ort"]]["site"]) == int(e["ziel"]):
				v["geliefert"] = int(v["geliefert"]) + int(e["menge"])
				v["erloes_cent"] = int(v["erloes_cent"]) + int(e["cent"])
	var i := 0
	while i < vertraege_aktiv.size():
		var v: Dictionary = vertraege_aktiv[i]
		if int(v["geliefert"]) >= int(v["menge"]):
			var cent := vertrag_praemie(v) + int(v["erloes_cent"]) * int(v["bonus_promille"]) / 1000
			konto.erstatten(cent)
			vertraege_erfuellt += 1
			ruf = mini(int(vd.get("ruf_max", 5)), ruf + 1)
			vertraege_log.append({"id": v["id"], "ergebnis": "erfuellt", "tick": t, "cent": cent})
			_log("vertrag_ok", "Vertrag erfüllt: %s zahlt %d $ Prämie. Ruf %+d." % [v["ort"], cent / 100, ruf])
			vertraege_aktiv.remove_at(i)
			continue
		if t >= int(v["ende_tick"]):
			konto.charge(int(v["strafe_cent"]))
			vertraege_verfehlt += 1
			ruf = maxi(int(vd.get("ruf_min", -3)), ruf - 1)
			vertraege_log.append({"id": v["id"], "ergebnis": "verfehlt", "tick": t, "cent": -int(v["strafe_cent"])})
			_log("vertrag_fehl", "Vertrag verfehlt: %s bekam %d von %d %s. Strafe %d $, Ruf %+d." % [v["ort"], int(v["geliefert"]),
				int(v["menge"]), gutname(v["gut"]), int(v["strafe_cent"]) / 100, ruf])
			vertraege_aktiv.remove_at(i)
			continue
		i += 1
	i = 0
	while i < vertraege_angebote.size():
		if t >= int(vertraege_angebote[i]["angebot_bis_tick"]):
			vertraege_log.append({"id": vertraege_angebote[i]["id"], "ergebnis": "verfallen", "tick": t, "cent": 0})
			vertraege_angebote.remove_at(i)
			continue
		i += 1
	var t0 := int(vd.get("erstes_angebot_tick", 900))
	var iv := maxi(1, int(vd.get("intervall_ticks", 1200)))
	if hq_platziert and t >= t0 and (t - t0) % iv == 0 and vertraege_angebote.size() < int(vd.get("angebote_max", 3)):
		_vertrag_erzeugen()


# ------------------------------------------------------------------ Tick

func tick() -> void:
	if konto.bankrupt:
		return
	super.tick()
	if eco == null or not eco.company_started:
		return
	_vertraege_tick()
	_plan_tick()
	if sim.tick_count % 60 == 0:
		_fahrgaeste_erzeugen()
	if sim.tick_count % eco.periode_ticks == 0:
		ertrag_periode_cent = eco.revenue_total - _rev_alt
		_rev_alt = eco.revenue_total
	if sim.tick_count % 10 == 0:
		_meilensteine_pruefen()


func _jahreswechsel(jahr: int) -> void:
	super._jahreswechsel(jahr)
	for art in ["strasse", "gleis"]:
		if int(bau_regel(art).get("ab_jahr", 0)) == jahr and jahr > startjahr:
			_log("frei", "Neu: %s bauen (Taste %s)." % [String(bau_regel(art).get("name", art)), "G" if art == "gleis" else "B"])


func pruefsumme() -> int:
	var h: int = sim.checksum()
	var prime: int = 1099511628211
	for v in [ruf, skillpunkte, skills.size(), hq_stufe, hq_anbauten.size(), vertraege_erfuellt, vertraege_verfehlt, _vertrag_nr,
			bauwerke.size(), linien.size(), depots.size(), abgestellt.size(), _fz_nr, 1 if maut_gekauft else 0, roundi(hq_pos.x * 10.0), roundi(hq_pos.y * 10.0), meilensteine_erreicht.size(), _vz]:
		h = (h ^ int(v)) * prime
	for bw in bauwerke:
		h = (h ^ int(bw["kosten_cent"])) * prime
	for s in skills:
		h = (h ^ String(s).hash()) * prime
	for v in vertraege_aktiv:
		h = (h ^ (int(v["id"]) * 1000003 + int(v["geliefert"]))) * prime
	return h


# ------------------------------------------------------------------ Aktionen (Gate A, UI-Hinweis)

func _bau_schaetzung(art: String, a: Vector2, b: Vector2) -> int:
	var mpf := float(regelwerk.get("skalen", {}).get("m_pro_feld", 25.0))
	var felder := int(ceil(a.distance_to(b) * 1.15 / mpf))
	return felder * int(bau_regel(art).get("kosten_cent_pro_feld", 0)) * (1000 - mini(800, bonus("bau_%s_pm" % art))) / 1000


func naechster_strassenknoten(p: Vector2) -> Vector2:
	var best := p
	var bd := INF
	for nid in knoten_grad:
		if knoten_grad[nid] == 0 or gleis_knoten.has(nid):
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd:
			bd = d
			best = Vector2(q.x, q.z)
	return best


func darf_laden(name: String) -> bool:
	var site: int = stationen[name]["site"]
	return eco.licence_valid(site) or int(eco.s_owner[site]) == Economy.OWNER_SPIELER


## Liste der Aktionen, die jetzt sinnvoll UND bezahlbar sind. Einträge "art" oder "art:ziel".
func aktionen_moeglich() -> Array:
	var a: Array = []
	if eco == null or not eco.company_started or konto.bankrupt:
		return a
	if not hq_platziert:
		return ["hq"]
	var cash: int = eco.cash_cent
	var frei: int = cash - credit.loan_cent
	if skillpunkte_frei() > 0 and not _skills_kaufbar().is_empty():
		a.append("skill")
	if not vertraege_angebote.is_empty() and vertraege_aktiv.size() < vertraege_max():
		a.append("vertrag")
	var fz_strasse := vdef(def_fuer("fuhrwerk"))
	for nm in stationen:
		var site: int = stationen[nm]["site"]
		if site < 0 or eco.s_kind[site] != Economy.K_INDUSTRIE:
			continue
		if not angeschlossen(nm) and not bahnhof.has(nm):
			if _bau_schaetzung("strasse", halt_pos(nm), naechster_strassenknoten(halt_pos(nm))) <= cash:
				a.append("strasse:" + nm)
			continue
		if eco.s_out_good[site] >= 0 and not darf_laden(nm):
			var q: Dictionary = eco.licence_quote(site, false)
			if q.get("ok", false) and int(q["zu_zahlen_cent"]) <= cash:
				a.append("lizenz:" + nm)
		var kq := kauf_angebot(nm)
		if kq.get("ok", false) and kq.get("kaufbar", false):
			a.append("firma:" + nm)
		var aq := ausbau_angebot(nm)
		if aq.get("ok", false) and int(aq["kosten_cent"]) <= frei:
			a.append("ausbau:" + nm)
	for k in kanten():
		var von := String(k["von"])
		var nach := String(k["nach"])
		if not darf_laden(von):
			continue
		var sv: int = stationen[von]["site"]
		var lager: int = sim.st_stock[eco.s_station[sv]]
		if eco.s_raw[sv] == 1:
			eco._sync_raw(sim, sv)
			lager = sim.st_stock[eco.s_station[sv]]
		if lager >= _kap(fz_strasse) and _preis(fz_strasse) <= cash and not strassenroute(von, nach).is_empty():
			a.append("fahrzeug:%s>%s" % [von, nach])
		if gleis_frei() and int(k["felder"]) >= 15 and gleisroute(von, nach).is_empty():
			if _bau_schaetzung("gleis", halt_pos(von), halt_pos(nach)) <= cash:
				a.append("gleis:%s>%s" % [von, nach])
		elif gleis_frei() and not gleisroute(von, nach).is_empty():
			var zd := vdef(def_fuer("zug"))
			if lager >= _kap(zd) / 2 and _preis(zd) <= cash:
				a.append("zug:%s>%s" % [von, nach])
	var hq := hq_ausbau_angebot()
	if hq.get("ok", false) and hq.get("kaufbar", false):
		a.append("hq_ausbau")
	for an in daten.get("hq", {}).get("anbauten", []):
		var q2 := hq_anbau_angebot(String(an["id"]))
		if q2.get("ok", false) and q2.get("kaufbar", false):
			a.append("hq_anbau:" + String(an["id"]))
	for f in fahrzeuge:
		if f["verkauft"] or int(f.get("kauf_cent", 0)) <= 0:
			continue
		var neu := neueres_modell(int(f["vid"]))
		if neu != "":
			var eq := ersetzen_angebot(int(f["vid"]), neu)
			if eq.get("ok", false) and eq.get("kaufbar", false):
				a.append("ersetzen:%d" % int(f["vid"]))
		var uq := ueberholen_angebot(int(f["vid"]))
		if uq.get("ok", false) and uq.get("kaufbar", false) and int(uq["spart_cent_pro_periode"]) * 10 >= int(f.get("fix_cent", 0)) * 2:
			a.append("ueberholen:%d" % int(f["vid"]))
	# Personenverkehr: Halt mit wartenden Fahrgästen, den keine Linie bedient
	var kd := vdef(def_fuer("kutsche"))
	if not kd.is_empty() and _preis(kd) <= cash:
		for site in personen_sites:
			var hn := _name_von_site(site)
			if sim.st_stock[eco.s_station[site]] >= _kap(kd) and not _halt_bedient(hn):
				a.append("personen:" + hn)
	if not abgestellt.is_empty() and not linien.is_empty():
		a.append("zuweisen")
	if linien.is_empty():
		a.append("linie")
	if depots.size() <= 1 and int(daten.get("depot", {}).get("kosten_cent", 0)) <= cash and sim.tick_count >= 3600:
		a.append("depot")
	var mq := strecke_kauf_angebot("chaussee")
	if mq.get("ok", false) and mq.get("kaufbar", false) and int(mq["maut_cent_pro_periode"]) > int(mq["unterhalt_cent"]):
		a.append("strecke:chaussee")
	return a


# ====================================================================== Teil 2: Personen, Linienpläne, Depots, Strecken
# (Erweiterung 10.11.: Punkte 7–11 des Demo-Auftrags)

var personen_sites: Array = []        # Standorte (Orte, Haltestellen), die Fahrgäste erzeugen und annehmen
var personen_acc: Array = []
var linien: Array = []                # Linienpläne [{id, name, halte [Namen], auftrag ["voll"|"mitnehmen"|"nichts"], def_kat, gleis, fracht}]
var _linie_nr := 0
var plan3_geliefert := false
var depots: Array = []                # [{id, art "strasse"|"gleis", knoten, pos Vector2, tick}]
var maut_gekauft := false
var maut_gezahlt_cent := 0            # Σ Chausseegeld (in den Fahrkosten enthalten), Anzeige
var _leg_cache: Dictionary = {}


func _name_von_site(site: int) -> String:
	for nm in stationen:
		if int(stationen[nm]["site"]) == site:
			return nm
	return ""


func _halt_bedient(name: String) -> bool:
	for l in linien:
		if name in l["halte"]:
			for f in fahrzeuge:
				if not f["verkauft"] and int(f.get("plan", -1)) == int(l["id"]):
					return true
	return false


## Fahrgäste entstehen an jedem Ort/Halt: je Minute so viele, wie er annimmt; Vorrat höchstens wartend_max_perioden Minuten.
func _fahrgaeste_erzeugen() -> void:
	var pd: Dictionary = daten.get("personen", {})
	var gid := String(pd.get("gut", "fahrgaeste"))
	if not eco.g_index.has(gid):
		return
	var g: int = eco.g_index[gid]
	var mx := int(pd.get("wartend_max_perioden", 3))
	for i in personen_sites.size():
		var site: int = personen_sites[i]
		var je: int = maxi(1, eco.city_demand(site))
		personen_acc[i] = int(personen_acc[i]) + je * 60
		var n: int = int(personen_acc[i]) / eco.periode_ticks
		if n <= 0:
			continue
		personen_acc[i] = int(personen_acc[i]) - n * eco.periode_ticks
		var k: int = eco.s_station[site]
		n = mini(n, je * mx - sim.st_stock[k])
		if n > 0:
			eco._push_lot(site, [g, site, -1, n])
			sim.st_stock[k] += n


func wartende(name: String) -> int:
	return sim.st_stock[int(stationen[name]["k"])] if stationen.has(name) and eco.s_kind[int(stationen[name]["site"])] == Economy.K_STADT else 0


# ------------------------------------------------------------------ Maut und Fahrkosten je Feld

## Anteil der Route (Promille der Länge) auf der Mautstrecke.
func maut_anteil_pm(route: Array) -> int:
	var wi := int(daten.get("maut", {}).get("weg_index", -1))
	if wi < 0 or route.is_empty():
		return 0
	var ges := 0
	var auf := 0
	for st in route:
		var l: int = int(sim.graph.edges[st["edge"]]["length"])
		ges += l
		if int(kante[st["edge"]][0]) == wi:
			auf += l
	return auf * 1000 / maxi(1, ges)


func maut_cent_pro_feld() -> int:
	if maut_gekauft:
		return 0
	return int(daten.get("maut", {}).get("cent_pro_feld", 0)) * (1000 - mini(1000, bonus("maut_pm"))) / 1000


## Fahrkosten je Feld eines Fahrzeugs = Modell + Chausseegeld × Anteil der Route auf der Chaussee (gerundet).
func _var_neu(f: Dictionary) -> void:
	var d := vdef(String(f.get("def_id", "")))
	if d.is_empty() or f["verkauft"]:
		return
	var m := (maut_cent_pro_feld() * maut_anteil_pm(f["route"]) + 500) / 1000
	f["maut_cent_pro_feld"] = m
	sim.v_var_cent[sim.slot_of(f["vid"])] = int(d.get("variabel_cent_pro_feld", 0)) + m


# ------------------------------------------------------------------ Linienpläne (mehrere Halte)

func linie_plan(id: int) -> Dictionary:
	for l in linien:
		if int(l["id"]) == id:
			return l
	return {}


func _halt_knoten(name: String, gleis: bool) -> int:
	if gleis:
		return int(bahnhof.get(name, -1))
	return int(stationen[name]["knoten"]) if stationen.has(name) else -1


func _hop(von: String, nach: String, gleis: bool) -> Array:
	return gleisroute(von, nach) if gleis else strassenroute(von, nach)


## Ladeauftrag am Halt idx auf das Sim-Fahrzeug legen (Zustand „lädt“ oder gleich „fährt“).
func _halt_laden(f: Dictionary, l: Dictionary, idx: int) -> void:
	var i: int = sim.slot_of(f["vid"])
	var modus := String(l["auftrag"][idx]) if idx < l["auftrag"].size() else "mitnehmen"
	if not halt_ladbar(l, idx):
		modus = "nichts"
	sim.v_lwait[i] = 0
	sim.v_timer[i] = 0
	if modus == "nichts":
		sim.v_state[i] = SimWorld.S_UNTERWEGS
	else:
		sim.v_state[i] = SimWorld.S_WARTET_LADUNG
		sim.set_line_flags(f["vid"], modus == "mitnehmen", MAX_WAIT_TICKS)


## Kann am Halt idx sinnvoll geladen werden? Nur, wenn ein anderer Halt der Linie die Ware (bzw. Fahrgäste) abnimmt.
## Sonst lädt das Fahrzeug dort nie, egal was der Ladeauftrag sagt (keine Fuhre, die niemand haben will).
func halt_ladbar(l: Dictionary, idx: int) -> bool:
	var nm := String(l["halte"][idx])
	if not stationen.has(nm) or not _fracht_ok(String(l["fracht"]), nm, true):
		return false
	var site: int = stationen[nm]["site"]
	var g := -1
	if eco.s_kind[site] == Economy.K_STADT:
		g = int(eco.g_index.get(String(daten.get("personen", {}).get("gut", "fahrgaeste")), -1))
	else:
		g = eco.s_out_good[site]
	if g < 0:
		return false
	for j in l["halte"].size():
		if j == idx or not stationen.has(String(l["halte"][j])):
			continue
		var zs: int = stationen[String(l["halte"][j])]["site"]
		if eco.s_kind[zs] == Economy.K_STADT:
			if eco.city_accepts(zs, g):
				return true
		elif eco.s_inbuf[zs].has(g):
			return true
	return false


func _route_setzen(f: Dictionary, route: Array, prof) -> void:
	var i: int = sim.slot_of(f["vid"])
	sim.v_rstart[i] = sim.r_edge.size()
	sim.v_rlen[i] = route.size()
	for st in route:
		var e: Dictionary = sim.graph.edges[st["edge"]]
		var fwd: bool = st["fwd"]
		sim.r_edge.append(int(st["edge"]))
		sim.r_fwd.append(1 if fwd else 0)
		sim.r_block.append(e["block_fwd"] if fwd else e["block_rev"])
		sim.r_len.append(e["length"])
		sim.r_from.append(e["a"] if fwd else e["b"])
		sim.r_to.append(e["b"] if fwd else e["a"])
		sim.r_stop.append(0)
	sim.v_idx[i] = 0
	sim.v_pos[i] = 0
	sim.v_leg[i] = 0
	f["route"] = route
	f["route_kanten"] = route.size()
	f["sim_mm"] = sim.graph.route_length(route)
	var key := "%d|%d|%d|%s" % [int(route[0]["edge"]), int(route[-1]["edge"]), route.size(), String(prof.kat) + str(prof.v_nom)]
	if not _leg_cache.has(key):
		_leg_cache[key] = [routenlinie(route, prof), routenlinie(sim.graph.reverse_route(route), prof)]
	f["legs"] = _leg_cache[key]
	f["zustand"] = Easing.Zustand.new(prof, f["legs"])
	_probe(f)
	f["zustand"].folger_setzen()


## Fahrzeuge auf Linienplänen: nach dem Entladen am Ziel der Teilstrecke geht es zum nächsten Halt des Plans weiter.
func _plan_tick() -> void:
	for f in fahrzeuge:
		if f["verkauft"] or not f.has("plan"):
			continue
		var i: int = sim.slot_of(f["vid"])
		if sim.v_leg[i] != 1 or sim.v_state[i] != SimWorld.S_UNTERWEGS:
			continue
		var l := linie_plan(int(f["plan"]))
		if l.is_empty():
			continue
		var n: int = l["halte"].size()
		var cur := (int(f["halt"]) + 1) % n
		var nxt := (cur + 1) % n
		var a := String(l["halte"][cur])
		var b := String(l["halte"][nxt])
		var route := _hop(a, b, bool(l["gleis"]))
		if route.is_empty():
			sim.line_stop(f["vid"])
			if not f.get("gestrandet", false):
				f["gestrandet"] = true
				_log("linie_unterbrochen", "%s steht: zwischen %s und %s fehlt die Strecke." % [f["name"], a, b])
			continue
		if n >= 3 and int(f.get("hops", 0)) + 1 >= n:
			plan3_geliefert = true
		f["hops"] = int(f.get("hops", 0)) + 1
		f["halt"] = cur
		_route_setzen(f, route, f["profil"])
		sim.v_src_k[i] = int(stationen[a]["k"])
		sim.v_dst_k[i] = int(stationen[b]["k"])
		f["von_halt"] = a
		_var_neu(f)
		_halt_laden(f, l, cur)


func _plan_neu_einsetzen(f: Dictionary, l: Dictionary) -> bool:
	var a := String(l["halte"][0])
	var b := String(l["halte"][1])
	var route := _hop(a, b, bool(l["gleis"]))
	if route.is_empty():
		return false
	var i: int = sim.slot_of(f["vid"])
	sim.v_cargo[i] = 0
	if eco.v_lots.has(f["vid"]):
		eco.v_lots.erase(f["vid"])
	f["halt"] = 0
	f["hops"] = 0
	_route_setzen(f, route, f["profil"])
	sim.v_src_k[i] = int(stationen[a]["k"])
	sim.v_dst_k[i] = int(stationen[b]["k"])
	f["von"] = int(stationen[a]["knoten"])
	f["nach"] = int(stationen[b]["knoten"])
	_var_neu(f)
	_halt_laden(f, l, 0)
	return true


## Plan ändern. Die Änderung gilt sofort; Fahrzeuge der Linie beginnen wieder am ersten Halt (Ladung verfällt wie beim Verkauf).
func _plan_geaendert(l: Dictionary, halte_alt: Array, auftrag_alt: Array) -> Dictionary:
	var def_id := ""
	for f in fahrzeuge:
		if not f["verkauft"] and int(f.get("plan", -1)) == int(l["id"]):
			def_id = String(f["def_id"])
	if def_id == "":
		def_id = def_fuer(String(l["kategorie"]))
	var q := plan_pruefen(l["halte"], def_id)
	if not q["ok"]:
		l["halte"] = halte_alt
		l["auftrag"] = auftrag_alt
		return q
	for f in fahrzeuge:
		if not f["verkauft"] and int(f.get("plan", -1)) == int(l["id"]):
			_plan_neu_einsetzen(f, l)
	return _ok({"halte": l["halte"].duplicate()})


func linie_halt_dazu(id: int, name: String, pos := -1) -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	var ha: Array = l["halte"].duplicate()
	var aa: Array = l["auftrag"].duplicate()
	var p: int = l["halte"].size() if pos < 0 else clampi(pos, 0, l["halte"].size())
	l["halte"].insert(p, name)
	var d := vdef(def_fuer(String(l["kategorie"])))
	l["auftrag"].insert(p, _auftrag_standard([name], d)[0] if stationen.has(name) else "nichts")
	return _plan_geaendert(l, ha, aa)


func linie_halt_weg(id: int, idx: int) -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	if idx < 0 or idx >= l["halte"].size():
		return _nein("unbekannter_halt")
	if l["halte"].size() <= 2:
		return _nein("zu_wenig_halte")
	var ha: Array = l["halte"].duplicate()
	var aa: Array = l["auftrag"].duplicate()
	l["halte"].remove_at(idx)
	l["auftrag"].remove_at(idx)
	return _plan_geaendert(l, ha, aa)


## Halt um eine Stelle nach vorn (richtung −1) oder hinten (+1) schieben.
func linie_halt_schieben(id: int, idx: int, richtung: int) -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	var j := idx + richtung
	if idx < 0 or idx >= l["halte"].size() or j < 0 or j >= l["halte"].size():
		return _nein("unbekannter_halt")
	var ha: Array = l["halte"].duplicate()
	var aa: Array = l["auftrag"].duplicate()
	var t = l["halte"][idx]
	l["halte"][idx] = l["halte"][j]
	l["halte"][j] = t
	t = l["auftrag"][idx]
	l["auftrag"][idx] = l["auftrag"][j]
	l["auftrag"][j] = t
	return _plan_geaendert(l, ha, aa)


## Ladeauftrag eines Halts setzen: "voll" | "mitnehmen" | "nichts" (gilt ab der nächsten Ankunft, kein Neustart).
func linie_auftrag(id: int, idx: int, modus: String) -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	if idx < 0 or idx >= l["halte"].size():
		return _nein("unbekannter_halt")
	if not (modus in ["voll", "mitnehmen", "nichts"]):
		return _nein("unbekannter_auftrag")
	l["auftrag"][idx] = modus
	return _ok({})


func linie_fahrzeuge(id: int) -> Array:
	return fahrzeuge.filter(func(f): return not f["verkauft"] and int(f.get("plan", -1)) == id)


## Linie auflösen: nur ohne Fahrzeuge (erst verkaufen oder umsetzen).
func linie_aufloesen(id: int) -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	if not linie_fahrzeuge(id).is_empty():
		return _nein("linie_hat_fahrzeuge", {"n": linie_fahrzeuge(id).size()})
	linien.erase(l)
	return _ok({})


func fahrzeug_verkaufen(vid: int) -> Dictionary:
	var r := super.fahrzeug_verkaufen(vid)
	if r.get("ok", false):
		fahrzeug(vid)["versteckt"] = true
		_log("verkauf", "%s verkauft: +%d $ Restwert." % [fahrzeug(vid)["name"], int(r["restwert_cent"]) / 100], false)
	return r


## Linienname eines Fahrzeugs für Listen: Plan „Linie 2“ oder „A → B“.
func linie_text(f: Dictionary) -> String:
	if f.has("plan"):
		var l := linie_plan(int(f["plan"]))
		if not l.is_empty():
			return "%s (%d Halte)" % [l["name"], l["halte"].size()]
	var a := ""
	var b := ""
	for nm in stationen:
		if int(stationen[nm]["knoten"]) == int(f["von"]):
			a = nm
		if int(stationen[nm]["knoten"]) == int(f["nach"]):
			b = nm
	return "%s → %s" % [a, b]


# ------------------------------------------------------------------ Depots

## Depot-Vorschau an einem Punkt: rastet an einen Straßenknoten (Betriebshof) oder Gleisknoten/Bahnhof (Lokschuppen).
func depot_angebot(p: Vector2) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var dd: Dictionary = daten.get("depot", {})
	var best := -1
	var bd := float(dd.get("fang_m", 30.0))
	for nid in knoten_grad:
		if knoten_grad[nid] == 0:
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd:
			bd = d
			best = nid
	if best < 0:
		return _nein("kein_anschluss")
	for dp in depots:
		if int(dp["knoten"]) == best:
			return _nein("schon_gebaut")
	var art := "gleis" if gleis_knoten.has(best) else "strasse"
	var kosten := int(dd.get("kosten_cent", 0))
	return _ok({"knoten": best, "art": art, "name": String(dd.get("name_" + art, "Depot")), "kosten_cent": kosten,
		"unterhalt_cent": int(dd.get("unterhalt_cent_pro_periode", 0)), "pos": Vector2(knoten_pos[best].x, knoten_pos[best].z),
		"kaufbar": kosten <= eco.cash_cent, "fehlt_cent": maxi(0, kosten - eco.cash_cent)})


func depot_bauen(p: Vector2) -> Dictionary:
	var q := depot_angebot(p)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"])})
	konto.charge(int(q["kosten_cent"]))
	kauf_total += int(q["kosten_cent"])
	var dp := {"id": depots.size() + 1, "art": String(q["art"]), "knoten": int(q["knoten"]), "pos": q["pos"], "tick": sim.tick_count,
		"name": "%s %d" % [String(q["name"]), depots.size() + 1]}
	depots.append(dp)
	_fix_dirty = true
	_log("depot", "%s gebaut: Fahrzeuge im Einzugsbereich 8 %% billiger, Überholung möglich." % dp["name"], false)
	var r := _ok(dp)
	return r


## Index des nächstgelegenen Depots, das die Station über das Netz erreicht (−1 = keins). Gleis: Depot im selben Gleisnetz wie der Bahnhof.
func depot_erreicht(name: String, gleis: bool) -> int:
	if not stationen.has(name):
		return -1
	var ziel := _halt_knoten(name, gleis)
	if ziel < 0:
		return -1
	var best := -1
	var bd := INF
	var zp := Vector2(knoten_pos[ziel].x, knoten_pos[ziel].z)
	for i in depots.size():
		var dp: Dictionary = depots[i]
		if (String(dp["art"]) == "gleis") != gleis:
			continue
		var key := "d|%d|%d" % [int(dp["knoten"]), ziel]
		if not _routen.has(key):
			_routen[key] = int(dp["knoten"]) == ziel or not sim.graph.find_path(int(dp["knoten"]), ziel).is_empty()
		var dist: float = zp.distance_to(dp["pos"])
		if _routen[key] and dist < bd:
			bd = dist
			best = i
	return best


func _start_name(f: Dictionary) -> String:
	if f.has("plan"):
		var l := linie_plan(int(f["plan"]))
		if not l.is_empty():
			return String(l["halte"][0])
	for nm in stationen:
		if int(stationen[nm]["knoten"]) == int(f["von"]):
			return nm
	return ""


## Überholung im Depot: setzt den Alterszuschlag auf den Unterhalt zurück (Alter und Restwert bleiben).
## {ok, kosten_cent, fix_alt_cent, fix_neu_cent, spart_cent_pro_periode, depot, kaufbar}
func ueberholen_angebot(vid: int) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var f := fahrzeug(vid)
	if f.is_empty() or f["verkauft"] or String(f.get("def_id", "")) == "":
		return _nein("unbekanntes_fahrzeug")
	var d := vdef(String(f["def_id"]))
	var di := depot_erreicht(_start_name(f), auf_gleis(d))
	if di < 0:
		return _nein("kein_depot", {"art": "Lokschuppen" if auf_gleis(d) else "Betriebshof"})
	var jahre: int = alter_jahre(f) - int(f.get("ueberholt_jahre", 0))
	if jahre <= 0:
		return _nein("nichts_zu_ueberholen")
	var kosten := int(d.get("kauf_cent", 0)) * int(daten.get("depot", {}).get("ueberholung_promille", 200)) / 1000
	kosten = kosten * (1000 - mini(900, bonus("ueberholung_pm"))) / 1000
	var alt := fix_eff(f)
	var neu := int(f.get("fix_cent", 0)) * (1000 - mini(500, bonus("fz_fix_pm"))) / 1000
	return _ok({"kosten_cent": kosten, "fix_alt_cent": alt, "fix_neu_cent": neu, "spart_cent_pro_periode": alt - neu, "depot": String(depots[di]["name"]),
		"kaufbar": kosten <= eco.cash_cent, "fehlt_cent": maxi(0, kosten - eco.cash_cent)})


func fahrzeug_ueberholen(vid: int) -> Dictionary:
	var q := ueberholen_angebot(vid)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"])})
	var f := fahrzeug(vid)
	konto.charge(int(q["kosten_cent"]))
	kauf_total += int(q["kosten_cent"])
	f["ueberholt_jahre"] = alter_jahre(f)
	_fix_dirty = true
	_log("ueberholt", "%s überholt: Unterhalt %d → %d $/min." % [f["name"], int(q["fix_alt_cent"]) / 100, int(q["fix_neu_cent"]) / 100], false)
	return q


# ------------------------------------------------------------------ Strecken: Besitz, Kauf, Verkauf

## Alle Teilstrecken, die ein Fahrzeug befährt: sein laufender Weg (auch die Ausfahrt) und alle Teilstrecken seiner Linie.
func _routen_von(f: Dictionary) -> Array:
	var r: Array = [f["route"]]
	var l := linie_plan(int(f.get("plan", -1)))
	if not l.is_empty():
		var n: int = l["halte"].size()
		for i in n:
			r.append(_hop(String(l["halte"][i]), String(l["halte"][(i + 1) % n]), bool(l["gleis"])))
	return r


func _weg_benutzt(wi: int) -> int:
	var n := 0
	for f in fahrzeuge:
		if f["verkauft"]:
			continue
		var trifft := false
		for route in _routen_von(f):
			for st in route:
				if kante.has(st["edge"]) and int(kante[st["edge"]][0]) == wi:
					trifft = true
					break
			if trifft:
				break
		if trifft:
			n += 1
	return n


## Alle Strecken, die dem Spieler gehören oder die er kaufen kann.
## [{id, name, art, laenge_m, besitz "eigen"|"staat", unterhalt_cent, wert_cent (Verkaufserlös bzw. Kaufpreis), benutzt}]
func strecken() -> Array:
	var r: Array = []
	var md: Dictionary = daten.get("maut", {})
	var erst := int(daten.get("strecken", {}).get("erstattung_promille", 500))
	var su := 1000 - mini(800, bonus("strecke_unterhalt_pm"))
	if not md.is_empty():
		r.append({"id": String(md.get("id", "chaussee")), "name": String(md.get("name", "Chaussee")), "art": "strasse", "laenge_m": int(md.get("laenge_m", 0)),
			"besitz": "eigen" if maut_gekauft else "staat", "unterhalt_cent": int(md.get("unterhalt_cent_pro_periode", 0)) * su / 1000 if maut_gekauft else 0,
			"wert_cent": int(md.get("kaufpreis_cent", 0)) * (erst if maut_gekauft else 1000) / 1000, "benutzt": _weg_benutzt(int(md.get("weg_index", -1))),
			"maut_cent_pro_feld": maut_cent_pro_feld()})
	for i in bauwerke.size():
		var bw: Dictionary = bauwerke[i]
		if bw.get("verkauft", false):
			continue
		var nm := "%s %d" % ["Gleis" if bw["art"] == "gleis" else "Straße", i + 1]
		if String(bw["von"]) != "" or String(bw["nach"]) != "":
			nm += " (%s)" % " – ".join(PackedStringArray([String(bw["von"]), String(bw["nach"])].filter(func(x): return x != "")))
		r.append({"id": "bau_%d" % i, "name": nm, "art": String(bw["art"]), "laenge_m": int(bw["laenge_m"]), "besitz": "eigen",
			"unterhalt_cent": int(bw.get("unterhalt_cent", 0)) * su / 1000, "wert_cent": int(bw["kosten_cent"]) * erst / 1000, "benutzt": _weg_benutzt(int(bw["weg"]))})
	return r


## Maut je Minute, die die eigenen Fahrzeuge zuletzt auf der Staatsstrecke zahlten (Schätzung aus Route und Umlauf).
func _maut_je_periode() -> int:
	var c := 0
	var satz := int(daten.get("maut", {}).get("cent_pro_feld", 0)) * (1000 - mini(1000, bonus("maut_pm"))) / 1000
	for f in fahrzeuge:
		if f["verkauft"]:
			continue
		var l := linie_plan(int(f.get("plan", -1)))
		if l.is_empty():
			continue
		var mm := 0
		var maut_mm := 0
		var n: int = l["halte"].size()
		for i in n:
			var route := _hop(String(l["halte"][i]), String(l["halte"][(i + 1) % n]), bool(l["gleis"]))
			var hm: int = sim.graph.route_length(route)
			mm += hm
			maut_mm += hm * maut_anteil_pm(route) / 1000
		var umlauf: int = mm / maxi(1, sim.v_speed[sim.slot_of(f["vid"])]) + 100 * n
		c += maut_mm / maxi(1, eco.feld_mm) * satz * eco.periode_ticks / maxi(1, umlauf)
	return c


func strecke_kauf_angebot(id: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var md: Dictionary = daten.get("maut", {})
	if md.is_empty() or id != String(md.get("id", "")):
		return _nein("nicht_kaeuflich")
	if maut_gekauft:
		return _nein("schon_gekauft")
	var preis := int(md.get("kaufpreis_cent", 0))
	var frei: int = eco.cash_cent - credit.loan_cent
	return _ok({"preis_cent": preis, "unterhalt_cent": int(md.get("unterhalt_cent_pro_periode", 0)) * (1000 - mini(800, bonus("strecke_unterhalt_pm"))) / 1000,
		"maut_cent_pro_periode": _maut_je_periode(), "kaufbar": frei >= preis, "fehlt_cent": maxi(0, preis - frei)})


## Staatsstrecke kaufen (Pacht auf Dauer): keine Maut mehr, dafür Unterhalt. Nur aus der Kasse (kein Kreditgeld).
func strecke_kaufen(id: String) -> Dictionary:
	var q := strecke_kauf_angebot(id)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"])})
	konto.charge(int(q["preis_cent"]))
	kauf_total += int(q["preis_cent"])
	maut_gekauft = true
	for f in fahrzeuge:
		_var_neu(f)
	_fix_dirty = true
	_log("strecke_kauf", "%s gekauft: keine Maut mehr, Unterhalt %d $/min." % [String(daten["maut"].get("name", "")), int(q["unterhalt_cent"]) / 100], false)
	return q


## Strecke verkaufen: eigene Trasse (bau_<n>) wird abgebaut, wenn kein Fahrzeug sie befährt; die Chaussee geht an den Staat zurück.
## Erlös = Kaufpreis × erstattung_promille.
func strecke_verkaufen(id: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var erst := int(daten.get("strecken", {}).get("erstattung_promille", 500))
	var md: Dictionary = daten.get("maut", {})
	if id == String(md.get("id", "?")):
		if not maut_gekauft:
			return _nein("nicht_im_besitz")
		var erl := int(md.get("kaufpreis_cent", 0)) * erst / 1000
		konto.erstatten(erl)
		maut_gekauft = false
		for f in fahrzeuge:
			_var_neu(f)
		_fix_dirty = true
		_log("strecke_verkauf", "%s verkauft: +%d $. Deine Fahrzeuge zahlen dort wieder Maut." % [String(md.get("name", "")), erl / 100], false)
		return _ok({"erloes_cent": erl})
	if not id.begins_with("bau_") or not id.substr(4).is_valid_int():
		return _nein("unbekannte_strecke")
	var bi := int(id.substr(4))
	if bi < 0 or bi >= bauwerke.size() or bauwerke[bi].get("verkauft", false):
		return _nein("unbekannte_strecke")
	var bw: Dictionary = bauwerke[bi]
	var wi := int(bw["weg"])
	var n := _weg_benutzt(wi)
	if n > 0:
		return _nein("strecke_benutzt", {"n": n})
	for dp in depots:
		for eid in kante:
			if int(kante[eid][0]) == wi:
				var e: Dictionary = sim.graph.edges[eid]
				if int(e["a"]) == int(dp["knoten"]) or int(e["b"]) == int(dp["knoten"]):
					if int(knoten_grad[int(dp["knoten"])]) <= 1:
						return _nein("depot_an_strecke", {"name": String(dp["name"])})
	# Kanten aus dem Sim-Graphen nehmen
	var weg_kanten: Array = []
	for eid in kante:
		if int(kante[eid][0]) == wi:
			weg_kanten.append(eid)
	for eid in weg_kanten:
		var e: Dictionary = sim.graph.edges[eid]
		for nd in [int(e["a"]), int(e["b"])]:
			sim.graph._adj[nd] = sim.graph._adj[nd].filter(func(x): return int(x["edge"]) != int(eid))
			knoten_grad[nd] = int(knoten_grad[nd]) - 1
		sim.graph.edges.erase(eid)
		kante.erase(eid)
	for nm in bahnhof.keys():
		if int(knoten_grad.get(int(bahnhof[nm]), 0)) <= 0:
			bahnhof.erase(nm)
	_routen = {}
	_leg_cache = {}
	bw["verkauft"] = true
	var erl2 := int(bw["kosten_cent"]) * erst / 1000
	konto.erstatten(erl2)
	_fix_dirty = true
	_log("strecke_verkauf", "Strecke abgebaut und verkauft: +%d $." % (erl2 / 100), false)
	return _ok({"erloes_cent": erl2, "weg": wi})


func zustand_text(f: Dictionary) -> String:
	return super.zustand_text(f).replace("Fahrgaeste", "Fahrgäste")


# ====================================================================== Teil 3: Depot als Kaufort, Linien ohne Fahrzeug, Sammelaktionen
# (Umbau 11.11. nach Bastis Spieltest, Vorbild Transport Fever 2: Linie anlegen → im Depot kaufen → zuweisen)
#
# Modell: Eine Linie (linien[]) existiert ohne Fahrzeuge. Fahrzeuge werden nur im Depot gekauft und stehen dort als Datensatz in
# `abgestellt` (Schlüssel "d<nr>", kein Sim-Fahrzeug, kein Ertrag, 25 % Unterhalt). Zuweisen erzeugt das Sim-Fahrzeug am Depotknoten;
# es fährt über das Netz zum ersten Halt und beginnt dort den Umlauf (Schlüssel "v<vid>"). „Ins Depot“ nimmt es sofort von der Linie
# (die Rückfahrt wird nicht simuliert: der Sim-Kern kann ein Linienfahrzeug nicht mitten auf der Route umleiten).

const ARTEN := {
	"strasse_gueter": {"gleis": false, "fracht": "gueter", "kategorie": "fuhrwerk", "name": "Straße · Güter"},
	"strasse_personen": {"gleis": false, "fracht": "personen", "kategorie": "kutsche", "name": "Straße · Personen"},
	"gleis_gueter": {"gleis": true, "fracht": "gueter", "kategorie": "zug", "name": "Gleis · Güter"},
	"gleis_personen": {"gleis": true, "fracht": "personen", "kategorie": "pzug", "name": "Gleis · Personen"},
}
const LINIENFARBEN := ["#E0A848", "#6BC48A", "#7FA8D8", "#C98BD0", "#E07A5F", "#5FC9C9", "#D9D05A", "#B0B8C8"]

var abgestellt: Array = []            # Fahrzeuge im Depot [{key, nr, def_id, kauf_cent, fix_cent, kauf_tick, ueberholt_jahre, name, depot, verkauft}]
var _fz_nr := 0                       # laufende Fahrzeugnummer (Name bleibt über Depot und Linien hinweg)


func art_von(d: Dictionary) -> String:
	return ("gleis_" if auf_gleis(d) else "strasse_") + fracht(d)


func art_der_linie(l: Dictionary) -> String:
	return ("gleis_" if bool(l["gleis"]) else "strasse_") + String(l["fracht"])


func _fracht_ok(fr: String, name: String, als_quelle: bool) -> bool:
	var stadt: bool = eco.s_kind[int(stationen[name]["site"])] == Economy.K_STADT
	if fr == "personen":
		return stadt
	return not stadt if als_quelle else true


## Standard-Ladeaufträge: laden, wo es etwas gibt, das ein anderer Halt der Linie annimmt; sonst nur abladen.
func _auftrag_std(halte: Array, fr: String) -> Array:
	var r: Array = []
	var l := {"halte": halte, "fracht": fr}
	for i in halte.size():
		var h := String(halte[i])
		if not stationen.has(h) or not _fracht_ok(fr, h, true) or (halte.size() >= 2 and not halt_ladbar(l, i)):
			r.append("nichts")
		else:
			r.append("mitnehmen" if fr == "personen" else "voll")
	return r


func _auftrag_standard(halte: Array, d: Dictionary) -> Array:
	return _auftrag_std(halte, fracht(d))


## Prüft einen Plan für eine Linienart: ≥ 2 Halte, keine gleichen Nachbarn, jede Teilstrecke (auch zurück zum ersten Halt)
## befahrbar, Fracht passt. {ok, strecke_m, teilstrecken} oder {ok: false, fehler, von, nach, name}.
func plan_pruefen_art(halte: Array, gl: bool, fr: String) -> Dictionary:
	if halte.size() < 2:
		return _nein("zu_wenig_halte")
	if halte.size() > 8:
		return _nein("zu_viele_halte", {"max": 8})
	var mm := 0
	var laden_moeglich := false
	for i in halte.size():
		var a := String(halte[i])
		var b := String(halte[(i + 1) % halte.size()])
		if not stationen.has(a):
			return _nein("unbekannter_ort", {"name": a})
		if a == b:
			return _nein("gleicher_ort", {"name": a})
		if gl and not bahnhof.has(a):
			return _nein("kein_bahnhof", {"name": a})
		if fr == "personen" and not _fracht_ok(fr, a, true):
			return _nein("falsche_fracht", {"fracht": "personen", "name": a})
		if _fracht_ok(fr, a, true):
			laden_moeglich = true
		var r := _hop(a, b, gl)
		if r.is_empty():
			return _nein("keine_gleisverbindung" if gl else "keine_verbindung", {"von": a, "nach": b})
		mm += sim.graph.route_length(r)
	if not laden_moeglich:
		return _nein("falsche_fracht", {"fracht": fr, "name": String(halte[0])})
	return _ok({"strecke_m": int(mm / mm_pro_m), "teilstrecken": halte.size()})


func plan_pruefen(halte: Array, def_id: String) -> Dictionary:
	var d := vdef(def_id)
	if d.is_empty():
		return _nein("unbekanntes_fahrzeug")
	return plan_pruefen_art(halte, auf_gleis(d), fracht(d))


## Linie OHNE Fahrzeug anlegen. art: "strasse_gueter" | "strasse_personen" | "gleis_gueter" | "gleis_personen".
func linie_neu(art: String, halte: Array, auftrag: Array = [], name := "") -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if not ARTEN.has(art):
		return _nein("unbekannte_linienart")
	var a: Dictionary = ARTEN[art]
	if bool(a["gleis"]) and not gleis_frei():
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(bau_regel("gleis").get("ab_jahr", 0))})
	var q := plan_pruefen_art(halte, bool(a["gleis"]), String(a["fracht"]))
	if not q["ok"]:
		return q
	_linie_nr += 1
	var l := {"id": _linie_nr, "name": name if name != "" else "Linie %d" % _linie_nr, "halte": halte.duplicate(),
		"auftrag": auftrag.duplicate() if auftrag.size() == halte.size() else _auftrag_std(halte, String(a["fracht"])),
		"gleis": bool(a["gleis"]), "fracht": String(a["fracht"]), "kategorie": String(a["kategorie"]), "art": art,
		"farbe": LINIENFARBEN[(_linie_nr - 1) % LINIENFARBEN.size()]}
	linien.append(l)
	_log("linie", "%s angelegt: %s. Noch ohne Fahrzeug." % [l["name"], " → ".join(PackedStringArray(halte))], false)
	return _ok({"linie": int(l["id"]), "strecke_m": int(q["strecke_m"])})


func linie_umbenennen(id: int, name: String) -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	if name.strip_edges() != "":
		l["name"] = name.strip_edges()
	return _ok({})


# ------------------------------------------------------------------ Fuhrhof des Firmensitzes, Depot-Bestand

func _strassenknoten_id(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for nid in knoten_grad:
		if knoten_grad[nid] == 0 or gleis_knoten.has(nid):
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd:
			bd = d
			best = nid
	return best


## Der Firmensitz bringt einen Fuhrhof mit (erstes Straßendepot, kostenlos, kein Unterhalt). Beim Umzug zieht er mit.
func _fuhrhof_setzen() -> void:
	var n := _strassenknoten_id(hq_pos)
	if n < 0:
		return
	var pos := Vector2(knoten_pos[n].x, knoten_pos[n].z)
	for dp in depots:
		if dp.get("fuhrhof", false):
			dp["knoten"] = n
			dp["pos"] = pos
			_routen = {}
			return
	depots.append({"id": depots.size() + 1, "art": "strasse", "knoten": n, "pos": pos, "tick": sim.tick_count, "name": "Fuhrhof am Firmensitz", "fuhrhof": true})
	_routen = {}


func depot_index_bei(p: Vector2, r_max := 30.0) -> int:
	var best := -1
	var bd := r_max
	for i in depots.size():
		var d := p.distance_to(depots[i]["pos"])
		if d < bd:
			bd = d
			best = i
	return best


## Modelle, die dieses Depot verkauft (Straße oder Gleis), im laufenden Jahr kaufbar: neuestes je Kategorie zuerst.
func depot_katalog(di: int) -> Array:
	var r: Array = []
	if di < 0 or di >= depots.size():
		return r
	var gl: bool = String(depots[di]["art"]) == "gleis"
	for kat in (["zug", "pzug"] if gl else ["fuhrwerk", "kutsche"]):
		var m := modelle(kat)
		m.reverse()
		for id in m:
			r.append(String(id))
	return r


func depot_bestand(di: int) -> Array:
	return abgestellt.filter(func(x): return int(x["depot"]) == di)


## Kauf im Depot: `anzahl` Fahrzeuge eines Modells, sie stehen danach im Depot (ohne Linie).
## {ok, keys [..], preis_cent (gesamt), stueck_cent} oder {ok: false, fehler}.
func depot_kaufen(di: int, def_id: String, anzahl := 1) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if di < 0 or di >= depots.size():
		return _nein("kein_depot", {"art": "Depot"})
	var d := vdef(def_id)
	if d.is_empty() or not _demo_katalog.has(def_id):
		return _nein("unbekanntes_fahrzeug")
	if auf_gleis(d) != (String(depots[di]["art"]) == "gleis"):
		return _nein("falsches_depot", {"art": "Lokschuppen" if auf_gleis(d) else "Betriebshof"})
	if kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(d["verfuegbar_ab_jahr"])})
	anzahl = clampi(anzahl, 1, 20)
	var stueck := _preis(d)
	if stueck * anzahl > eco.cash_cent:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": stueck * anzahl - eco.cash_cent})
	var keys: Array = []
	for i in anzahl:
		konto.charge(stueck)
		kauf_total += stueck
		_fz_nr += 1
		var rec := {"key": "d%d" % _fz_nr, "nr": _fz_nr, "def_id": def_id, "kauf_cent": stueck, "fix_cent": int(d.get("fix_cent_pro_periode", 0)),
			"kauf_tick": sim.tick_count, "ueberholt_jahre": 0, "name": "%s %d" % [String(d.get("name", "Fahrzeug")), _fz_nr], "depot": di, "verkauft": false}
		abgestellt.append(rec)
		keys.append(rec["key"])
	_fix_dirty = true
	_log("kauf", "%d × %s im %s gekauft." % [anzahl, String(d.get("name", "")), String(depots[di]["name"])], false)
	return _ok({"keys": keys, "preis_cent": stueck * anzahl, "stueck_cent": stueck})


func fz_key(f: Dictionary) -> String:
	return String(f["key"]) if f.has("key") and not f.has("vid") else "v%d" % int(f["vid"])


## Fahrzeug zu einem Schlüssel: Depot-Datensatz ("d…") oder fahrendes Fahrzeug ("v…"); {} = gibt es nicht (mehr).
func fz(key: String) -> Dictionary:
	if key.begins_with("d"):
		for rec in abgestellt:
			if String(rec["key"]) == key:
				return rec
		return {}
	if key.begins_with("v") and key.substr(1).is_valid_int():
		var f := fahrzeug(int(key.substr(1)))
		if not f.is_empty() and not f["verkauft"] and String(f.get("def_id", "")) != "":
			return f
	return {}


## Alle Fahrzeuge des Spielers (fahrend und im Depot) als Schlüssel-Liste: Depot zuerst, dann nach Fahrzeugnummer.
func alle_fahrzeuge() -> Array:
	var r: Array = []
	for rec in abgestellt:
		r.append(String(rec["key"]))
	for f in fahrzeuge:
		if not f["verkauft"] and int(f.get("kauf_cent", 0)) > 0 and String(f.get("def_id", "")) != "":
			r.append("v%d" % int(f["vid"]))
	return r


func _ausruecken(rec: Dictionary, l: Dictionary) -> Dictionary:
	var d := vdef(String(rec["def_id"]))
	var gl: bool = l["gleis"]
	var dp: Dictionary = depots[int(rec["depot"])]
	var a := String(l["halte"][0])
	var b := String(l["halte"][1])
	var ziel := _halt_knoten(a, gl)
	var start := int(dp["knoten"])
	var direkt: bool = start == ziel
	if not direkt and sim.graph.find_path(start, ziel).is_empty():
		return _nein("depot_erreicht_linie_nicht", {"name": a, "depot": String(dp["name"])})
	var dar := String(d.get("darstellung", "fuhrwerk"))
	var ka := int(stationen[a]["k"])
	var f: Dictionary
	if direkt:
		f = linie(dar, String(rec["name"]), ziel, _halt_knoten(b, gl), ka, int(stationen[b]["k"]), false, d)
	else:
		f = linie(dar, String(rec["name"]), start, ziel, ka, ka, false, d)
	if f.is_empty():
		return _nein("linie")
	f["von"] = int(stationen[a]["knoten"])
	f["nach"] = int(stationen[b]["knoten"])
	f["gleis"] = gl
	f["def_id"] = String(rec["def_id"])
	f["kauf_cent"] = int(rec["kauf_cent"])
	f["fix_cent"] = int(rec["fix_cent"])
	f["kauf_tick"] = int(rec["kauf_tick"])
	f["ueberholt_jahre"] = int(rec.get("ueberholt_jahre", 0))
	f["nr"] = int(rec["nr"])
	f["heimat_depot"] = int(rec["depot"])
	f["plan"] = int(l["id"])
	if gl:
		zug_gekauft = true
	if direkt:
		f["halt"] = 0
		_halt_laden(f, l, 0)
	else:
		f["halt"] = -1                               # Ausfahrt: nach der Ankunft am ersten Halt beginnt der Umlauf (_plan_tick)
		f["ausfahrt"] = true
		var i: int = sim.slot_of(f["vid"])
		sim.v_state[i] = SimWorld.S_UNTERWEGS
		sim.v_lwait[i] = 0
	_var_neu(f)
	abgestellt.erase(rec)
	_fix_dirty = true
	return _ok({"vid": int(f["vid"]), "key": "v%d" % int(f["vid"])})


## Sammelaktion: Fahrzeuge (Schlüssel aus Depot oder von anderen Linien) einer Linie zuweisen. Nur passende Art.
## {ok (mind. eines zugewiesen), zugewiesen, keys (neue Schlüssel), abgelehnt [{key, fehler, …}]}; ok false + fehler, wenn keines ging.
func zuweisen(keys: Array, linie_id: int) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var l := linie_plan(linie_id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	var q := plan_pruefen_art(l["halte"], bool(l["gleis"]), String(l["fracht"]))
	if not q["ok"]:
		return q
	var neu: Array = []
	var abg: Array = []
	for key in keys:
		var x := fz(String(key))
		if x.is_empty():
			abg.append({"key": key, "fehler": "unbekanntes_fahrzeug"})
			continue
		var d := vdef(String(x["def_id"]))
		if art_von(d) != art_der_linie(l):
			abg.append({"key": key, "fehler": "passt_nicht_zur_linie"})
			continue
		if String(key).begins_with("d"):
			var r := _ausruecken(x, l)
			if r["ok"]:
				neu.append(r["key"])
			else:
				r["key"] = key
				abg.append(r)
		else:
			if int(x.get("plan", -1)) == linie_id:
				neu.append(key)
				continue
			x["plan"] = linie_id
			x.erase("gestrandet")
			x.erase("ausfahrt")
			if _plan_neu_einsetzen(x, l):
				neu.append(key)
			else:
				abg.append({"key": key, "fehler": "keine_verbindung"})
	if neu.is_empty():
		var erst: Dictionary = abg[0] if not abg.is_empty() else {"fehler": "keine_auswahl"}
		return _nein(String(erst.get("fehler", "?")), {"abgelehnt": abg, "name": erst.get("name", ""), "depot": erst.get("depot", "")})
	_log("zuweisen", "%d Fahrzeug(e) fahren jetzt auf %s." % [neu.size(), l["name"]], false)
	return _ok({"zugewiesen": neu.size(), "keys": neu, "abgelehnt": abg, "linie": linie_id})


## Sammelaktion: Fahrzeuge von der Linie nehmen und ins Depot stellen (di < 0: Heimatdepot, sonst nächstes passendes).
func ins_depot(keys: Array, di := -1) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var n := 0
	var neu: Array = []
	for key in keys:
		if not String(key).begins_with("v"):
			continue
		var f := fz(String(key))
		if f.is_empty():
			continue
		var d := vdef(String(f["def_id"]))
		var ziel := di
		if ziel < 0 or ziel >= depots.size() or (String(depots[ziel]["art"]) == "gleis") != auf_gleis(d):
			ziel = int(f.get("heimat_depot", -1))
		if ziel < 0 or ziel >= depots.size() or (String(depots[ziel]["art"]) == "gleis") != auf_gleis(d):
			ziel = -1
			for i in depots.size():
				if (String(depots[i]["art"]) == "gleis") == auf_gleis(d):
					ziel = i
					break
		if ziel < 0:
			continue
		sim.line_stop(int(f["vid"]))
		if eco.v_lots.has(int(f["vid"])):
			eco.v_lots.erase(int(f["vid"]))
		_fz_nr = maxi(_fz_nr, int(f.get("nr", 0)))
		var nr: int = int(f["nr"]) if f.has("nr") else _fz_nr + 1
		_fz_nr = maxi(_fz_nr, nr)
		var rec := {"key": "d%d" % nr, "nr": nr, "def_id": String(f["def_id"]), "kauf_cent": int(f["kauf_cent"]), "fix_cent": int(f["fix_cent"]),
			"kauf_tick": int(f["kauf_tick"]), "ueberholt_jahre": int(f.get("ueberholt_jahre", 0)), "name": String(f["name"]), "depot": ziel, "verkauft": false}
		f["verkauft"] = true
		f["versteckt"] = true
		f["fix_cent"] = 0
		abgestellt.append(rec)
		neu.append(rec["key"])
		n += 1
	if n == 0:
		return _nein("keine_auswahl")
	_fix_dirty = true
	_log("ins_depot", "%d Fahrzeug(e) stehen jetzt im Depot." % n, false)
	return _ok({"n": n, "keys": neu})


## Sammelaktion Verkauf (Restwert W20 je Fahrzeug, auch aus dem Depot).
func verkaufen_viele(keys: Array) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var n := 0
	var summe := 0
	for key in keys:
		var x := fz(String(key))
		if x.is_empty():
			continue
		if String(key).begins_with("d"):
			var rw := restwert(x)
			konto.erstatten(rw)
			abgestellt.erase(x)
			summe += rw
			n += 1
		else:
			var r := fahrzeug_verkaufen(int(x["vid"]))
			if r.get("ok", false):
				x["versteckt"] = true
				summe += int(r["restwert_cent"])
				n += 1
	if n == 0:
		return _nein("keine_auswahl")
	_fix_dirty = true
	return _ok({"n": n, "erloes_cent": summe})


func neueres_modell_def(def_id: String) -> String:
	var d := vdef(def_id)
	var m := modelle(String(d.get("kategorie", "")))
	if m.is_empty():
		return ""
	var neu := String(m[-1])
	return neu if int(vdef(neu).get("generation", 0)) > int(d.get("generation", 0)) else ""


## Angebot Ersetzen für einen Schlüssel (neuestes Modell der Kategorie): {ok, def_id, netto_cent, restwert_cent, preis_cent}.
func ersetzen_angebot_key(key: String) -> Dictionary:
	var x := fz(key)
	if x.is_empty():
		return _nein("unbekanntes_fahrzeug")
	var neu := neueres_modell_def(String(x["def_id"]))
	if neu == "":
		return _nein("kein_neueres_modell")
	if key.begins_with("v"):
		var q := ersetzen_angebot(int(x["vid"]), neu)
		if q.get("ok", false):
			q["def_id"] = neu
		return q
	var rw := restwert(x)
	var preis := _preis(vdef(neu))
	return _ok({"def_id": neu, "restwert_cent": rw, "preis_cent": preis, "netto_cent": preis - rw, "kaufbar": preis - rw <= eco.cash_cent})


## Sammelaktion Ersetzen: jedes gewählte Fahrzeug durch das neueste Modell seiner Kategorie (solange das Geld reicht).
func ersetzen_viele(keys: Array) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var n := 0
	var summe := 0
	var grund := "kein_neueres_modell"
	var fehlt := 0
	for key in keys:
		var q := ersetzen_angebot_key(String(key))
		if not q.get("ok", false):
			if String(q.get("fehler", "")) != "kein_neueres_modell":
				grund = String(q.get("fehler", grund))
			continue
		if not q.get("kaufbar", false):
			grund = "guthaben_reicht_nicht"
			fehlt = int(q["netto_cent"]) - eco.cash_cent
			continue
		var x := fz(String(key))
		if String(key).begins_with("v"):
			if fahrzeug_ersetzen(int(x["vid"]), String(q["def_id"])).get("ok", false):
				n += 1
				summe += int(q["netto_cent"])
		else:
			var d := vdef(String(q["def_id"]))
			konto.erstatten(int(q["restwert_cent"]))
			konto.charge(int(q["preis_cent"]))
			kauf_total += int(q["preis_cent"])
			x["def_id"] = String(q["def_id"])
			x["kauf_cent"] = int(q["preis_cent"])
			x["fix_cent"] = int(d.get("fix_cent_pro_periode", 0))
			x["kauf_tick"] = sim.tick_count
			x["ueberholt_jahre"] = 0
			x["name"] = "%s %d" % [String(d.get("name", "Fahrzeug")), int(x["nr"])]
			n += 1
			summe += int(q["netto_cent"])
	if n == 0:
		return _nein(grund, {"fehlt_cent": fehlt})
	_fix_dirty = true
	return _ok({"n": n, "netto_cent": summe})


## Überholung für einen Schlüssel: Fahrzeuge im Depot immer, fahrende, wenn ein Depot ihre Linie erreicht.
func ueberholen_angebot_key(key: String) -> Dictionary:
	if key.begins_with("v"):
		var f := fz(key)
		return ueberholen_angebot(int(f["vid"])) if not f.is_empty() else _nein("unbekanntes_fahrzeug")
	var rec := fz(key)
	if rec.is_empty():
		return _nein("unbekanntes_fahrzeug")
	if alter_jahre(rec) - int(rec.get("ueberholt_jahre", 0)) <= 0:
		return _nein("nichts_zu_ueberholen")
	var d := vdef(String(rec["def_id"]))
	var kosten := int(d.get("kauf_cent", 0)) * int(daten.get("depot", {}).get("ueberholung_promille", 200)) / 1000 * (1000 - mini(900, bonus("ueberholung_pm"))) / 1000
	return _ok({"kosten_cent": kosten, "kaufbar": kosten <= eco.cash_cent, "fehlt_cent": maxi(0, kosten - eco.cash_cent), "depot": String(depots[int(rec["depot"])]["name"])})


func ueberholen_key(key: String) -> Dictionary:
	if key.begins_with("v"):
		var f := fz(key)
		return fahrzeug_ueberholen(int(f["vid"])) if not f.is_empty() else _nein("unbekanntes_fahrzeug")
	var q := ueberholen_angebot_key(key)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["fehlt_cent"])})
	var rec := fz(key)
	konto.charge(int(q["kosten_cent"]))
	kauf_total += int(q["kosten_cent"])
	rec["ueberholt_jahre"] = alter_jahre(rec)
	_fix_dirty = true
	return q


## Ertrag (Cent) der letzten vollen Spielminute je Linie und Auslastung: {ertrag_cent, fahrzeuge, ladung, kapazitaet}.
func linie_kennzahlen(id: int) -> Dictionary:
	var fz_l := linie_fahrzeuge(id)
	var vids := {}
	var ladung := 0
	var kap := 0
	for f in fz_l:
		vids[int(f["vid"])] = true
		var i: int = sim.slot_of(f["vid"])
		ladung += sim.v_cargo[i]
		kap += sim.v_cargo_cap[i]
	var ab: int = sim.tick_count - eco.periode_ticks
	var cent := 0
	var k := lieferungen.size() - 1
	while k >= 0 and int(lieferungen[k]["tick"]) > ab:
		if vids.has(int(lieferungen[k]["vid"])):
			cent += int(lieferungen[k]["cent"])
		k -= 1
	return {"ertrag_cent": cent, "fahrzeuge": fz_l.size(), "ladung": ladung, "kapazitaet": kap}


## Wegpunkte (m) des Rundkurses einer Linie für die Hervorhebung in der Welt.
func linie_punkte(id: int) -> PackedVector2Array:
	var l := linie_plan(id)
	var r := PackedVector2Array()
	if l.is_empty():
		return r
	var n: int = l["halte"].size()
	for i in n:
		var route := _hop(String(l["halte"][i]), String(l["halte"][(i + 1) % n]), bool(l["gleis"]))
		for st in route:
			var e: Dictionary = sim.graph.edges[st["edge"]]
			var a: int = e["a"] if st["fwd"] else e["b"]
			r.append(Vector2(knoten_pos[a].x, knoten_pos[a].z))
		if not route.is_empty():
			var e2: Dictionary = sim.graph.edges[route[-1]["edge"]]
			var b: int = e2["b"] if route[-1]["fwd"] else e2["a"]
			r.append(Vector2(knoten_pos[b].x, knoten_pos[b].z))
	return r


# ------------------------------------------------------------------ Komfort-API (Tests, Bot): Linie + Kauf im Depot + Zuweisen in einem Aufruf

func _kauf_und_zuweisen(l: Dictionary, def_id: String) -> Dictionary:
	var d := vdef(def_id)
	if d.is_empty() or art_von(d) != art_der_linie(l):
		return _nein("passt_nicht_zur_linie")
	var pq := plan_pruefen_art(l["halte"], bool(l["gleis"]), String(l["fracht"]))
	if not pq["ok"]:
		return pq
	var di := depot_erreicht(String(l["halte"][0]), bool(l["gleis"]))
	if di < 0:
		return _nein("kein_depot", {"art": "Lokschuppen" if bool(l["gleis"]) else "Betriebshof"})
	var k := depot_kaufen(di, def_id, 1)
	if not k["ok"]:
		return k
	var z := zuweisen(k["keys"], int(l["id"]))
	if not z["ok"]:
		verkaufen_viele(k["keys"])
		return z
	return _ok({"vid": int(String(z["keys"][0]).substr(1)), "preis_cent": int(k["stueck_cent"]), "linie": int(l["id"]), "depot": di})


## Direktlinie von → nach (zwei Halte, am Ziel wird nur abgeladen) samt einem Fahrzeug aus dem Depot, das den Start erreicht.
## Gibt es die Linie schon, kommt nur ein weiteres Fahrzeug dazu.
func linie_anlegen(von_name: String, nach_name: String, kat := "fuhrwerk", def_id := "") -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if def_id == "":
		def_id = def_fuer(kat)
	var d := vdef(def_id)
	if d.is_empty():
		return _nein("unbekanntes_fahrzeug")
	if not stationen.has(von_name) or not stationen.has(nach_name):
		return _nein("unbekannter_ort")
	if von_name == nach_name:
		return _nein("gleicher_ort")
	if kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(d["verfuegbar_ab_jahr"])})
	if not (fracht_passt(d, von_name, true) and fracht_passt(d, nach_name, false)):
		return _nein("falsche_fracht", {"fracht": fracht(d)})
	var art := art_von(d)
	for l in linien:
		if String(l["art"]) == art and l["halte"] == [von_name, nach_name]:
			return _kauf_und_zuweisen(l, def_id)
	var fr := fracht(d)
	var r := linie_neu(art, [von_name, nach_name], [_auftrag_std([von_name], fr)[0], "nichts"], "%s → %s" % [von_name, nach_name])
	if not r["ok"]:
		return r
	var l2 := linie_plan(int(r["linie"]))
	var k := _kauf_und_zuweisen(l2, def_id)
	if not k["ok"]:
		linien.erase(l2)
		_linie_nr -= 1
	return k


func linienplan_anlegen(halte: Array, def_id := "", auftrag: Array = [], name := "") -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if def_id == "":
		def_id = def_fuer("fuhrwerk")
	var d := vdef(def_id)
	if d.is_empty():
		return _nein("unbekanntes_fahrzeug")
	if kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(d["verfuegbar_ab_jahr"])})
	var r := linie_neu(art_von(d), halte, auftrag, name)
	if not r["ok"]:
		return r
	var l := linie_plan(int(r["linie"]))
	var k := _kauf_und_zuweisen(l, def_id)
	if not k["ok"]:
		linien.erase(l)
		_linie_nr -= 1
	return k


func linie_fahrzeug_dazu(id: int, def_id := "") -> Dictionary:
	var l := linie_plan(id)
	if l.is_empty():
		return _nein("unbekannte_linie")
	return _kauf_und_zuweisen(l, def_id if def_id != "" else def_fuer(String(l["kategorie"])))


func fahrzeug_zuweisen(vid: int, id: int) -> Dictionary:
	return zuweisen(["v%d" % vid], id)
