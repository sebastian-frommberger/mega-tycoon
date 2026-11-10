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
	var kategorie := "zug" if kat in ["zug", "pferdebahn", "dampflok", "dampfzug"] else "fuhrwerk"
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
	var pm := bonus("kap_zug_pm") if String(d.get("kategorie", "")) == "zug" else bonus("kap_strasse_pm")
	return k * (1000 + pm) / 1000


func _preis(d: Dictionary) -> int:
	return int(d.get("kauf_cent", 0)) * (1000 - mini(500, bonus("fz_kauf_pm"))) / 1000


func fix_eff(f: Dictionary) -> int:
	return super.fix_eff(f) * (1000 - mini(500, bonus("fz_fix_pm"))) / 1000


func profil_fuer(kat: String, d: Dictionary):
	var tempo := int(d.get("tempo_promille", 600))
	var gleis := String(d.get("kategorie", "")) == "zug"
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
	return String(vdef(String(f.get("def_id", ""))).get("kategorie", "")) == "zug"


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
	if String(vdef(def_id).get("kategorie", "")) == "zug":
		return gleisroute(von_name, nach_name)
	return strassenroute(von_name, nach_name)


func linie_anlegen(von_name: String, nach_name: String, kat := "fuhrwerk", def_id := "") -> Dictionary:
	if def_id == "":
		def_id = def_fuer(kat)
	var d := vdef(def_id)
	if d.is_empty():
		return _nein("unbekanntes_fahrzeug")
	var dar := String(d.get("darstellung", "fuhrwerk"))
	if String(d.get("kategorie", "")) != "zug":
		return super.linie_anlegen(von_name, nach_name, dar, def_id)
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if not stationen.has(von_name) or not stationen.has(nach_name):
		return _nein("unbekannter_ort")
	if von_name == nach_name:
		return _nein("gleicher_ort")
	if kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(d["verfuegbar_ab_jahr"])})
	for nm in [von_name, nach_name]:
		if not bahnhof.has(nm):
			return _nein("kein_bahnhof", {"name": nm})
	if gleisroute(von_name, nach_name).is_empty():
		return _nein("keine_gleisverbindung")
	var preis := _preis(d)
	if preis > eco.cash_cent:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": preis - eco.cash_cent})
	var a: Dictionary = stationen[von_name]
	var b: Dictionary = stationen[nach_name]
	var n_alt := fehler.size()
	var f := linie(dar, "%s %d" % [String(d.get("name", kat)), fahrzeuge.size() + 1], int(bahnhof[von_name]), int(bahnhof[nach_name]),
		int(a["k"]), int(b["k"]), false, d)
	if f.is_empty():
		return _nein(String(fehler[-1]) if fehler.size() > n_alt else "linie")
	konto.charge(preis)
	kauf_total += preis
	f["von"] = int(a["knoten"])                  # UI/Bot erkennen die Linie an den Stationsknoten
	f["nach"] = int(b["knoten"])
	f["gleis"] = true
	f["def_id"] = def_id
	f["kauf_cent"] = preis
	f["fix_cent"] = int(d.get("fix_cent_pro_periode", 0))
	f["kauf_tick"] = sim.tick_count
	_fix_dirty = true
	zug_gekauft = true
	return _ok({"vid": f["vid"], "preis_cent": preis})


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
	for bw in bauwerke:
		c += int(bw.get("unterhalt_cent", 0))
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
			bauwerke.size(), roundi(hq_pos.x * 10.0), roundi(hq_pos.y * 10.0), meilensteine_erreicht.size(), _vz]:
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
	return a
