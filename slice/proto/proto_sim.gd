extends RefCounted
## Phase 4 Welle 2 (Felix): ProtoSim-Adapter (Empfehlung B aus phase4/proto_sim_anbindung.md).
## Echte Sim-Kette Farm → Mühle → Dorf in der Prototyp-Welt mit dem Bestandskern (core/sim_world.gd, economy.gd,
## data/economy_slice.json, data/vehicles.json), ohne main.gd und ohne Bestandscode zu ändern.
##
##   Graph   Je Weg die Anker der Fahrlinie (proto_strassenband.gd fl.anker = Eingabepunkte + eingefügte
##           Kreuzungspunkte) als Sim-Knoten, Kanten k → k+1; gleiche Punkte (0,5 m) und Wegenden auf einem anderen
##           Weg (Fang max(4 m, halbe Trasse) + 0,5 m) = ein Knoten. Position in mm: x_m · feld_mm / m_pro_feld
##           (1 Feld = 25 m = 1000 mm). Kantenlänge = Luftlinie der Anker (net_graph), Fahrlinie zwischen denselben
##           Ankern = Darstellung (K28 längentreu-proportional).
##   Kette   Gut Kuppenhof (proto_orte.industrie typ getreidefarm) → Industrie „getreidefarm“, Erlenmühle → „muehle“,
##           Dorf (klasse dorf) → Stadt „dorf_agrar“ (Dorfmitte = Kreuzung nächst Ortsmitte), Kleinstadt →
##           „kleinstadt_a“. Firma mit HQ im Dorf, Lizenzen Farm (gratis) und Mühle (bezahlt) über buy_licence.
##           Linien wie im Spiel (Werte von lkw_e1, Fuhrwerk ersetzt Lkw laut regelwerk fahrzeuge_dm.ersetzt):
##             Fuhrwerk 1  Farm → Mühle (Getreide),  Fuhrwerk 2  Mühle → Dorf (Mehl),
##             Postkutsche Dorf → Kleinstadt (leer, Personen nicht in der Sim: leave_empty, Annahme)
##           Start: 10 Getreide im Farmlager (economy.seed_stock), damit Fuhrwerk 1 sofort fährt (Annahme, sichtbar).
##   Tick    tick(): sim.step(), Fahrkosten wie main.charge (eco.cash_cent −= line_cost_cent), Lieferungen ins
##           Protokoll, danach je Fahrzeug die Sim-Probe (Leg, Fahrstrecke) an proto_easing.Zustand. Die Sim liest
##           nichts aus der Darstellung (K27): Prüfsumme mit Easing an/aus gleich (E1).

const SimWorld := preload("res://core/sim_world.gd")
const Economy := preload("res://economy.gd")
const Easing := preload("res://proto/proto_easing.gd")
const Konto := preload("res://core/konto.gd")          # AT-01 (S8, W12): Buchungen über konto.charge
const Credit := preload("res://credit.gd")             # AT-02: Kredit wie Slice (Sperre credit_available_from_ticks)
const Kalender := preload("res://core/kalender.gd")    # FZ-02: Zwei Uhren
## AT-02 (W10): Freischaltungen, die in S8 gesperrt bleiben (kein Eintrag in freischaltungen, kein Toast).
const GESPERRT_S8 := {"bahn_moeglich": "W10 Gleis in S8 gesperrt", "lok_e1": "W10", "waggon_e1": "W10"}
## AT-02 (W20): Restwert = Kauf × 50 % × max(20 %, 1 − Alter/Lebensdauer), in Promille.
const RESTWERT_PM := 500
const RESTWERT_MIN_PM := 200
const SLICE_JSON := "res://data/economy_slice.json"
const CONSTS_JSON := "res://data/economy_constants.json"
const VEHICLES_JSON := "res://data/vehicles.json"
const PROTO_JSON := "res://data/economy_proto.json"   # FK-02: Welt-Overlay (firmenkauf_c1: Mühlendeckel, Aufschlag, Rückfall W3)
const MAX_WAIT_TICKS := 50           # main.gd TRUCK_MAX_WAIT_TICKS
const START_GETREIDE := 10

var sim = null                       # SimWorld
var eco = null                       # Economy oder null (synthetische Tests)
var konto = Konto.new()              # AT-01/AT-02: Fahrkosten, Fix, Zins, Bankrott (core/konto.gd)
var credit = Credit.new()            # AT-02
var kalender = Kalender.new()        # FZ-02: Datum, Alter, Freischaltungen (jahr_ticks 1.800, economy_proto.json)
var startjahr: int:                  # Weiterleitung auf kalender
	get:
		return kalender.startjahr
	set(v):
		kalender.startjahr = v
var jahr_ticks: int:                 # Weiterleitung auf kalender
	get:
		return kalender.jahr_ticks
	set(v):
		kalender.jahr_ticks = v
var freischaltungen: Array = []      # AT-02: [{tick, jahr, id}] je neuer Freischaltung
var gesperrt_log: Array = []         # AT-02 (W10): [{tick, jahr, id, grund}] unterdrückte Freischaltungen
var meldungen: Array = []            # AT-02: Texte für Toasts (die Welt liest und leert)
var bankrott_tick := -1
var fahrkosten_total := 0            # AT-02: Σ Fahrkosten (Cent), Testspur/HUD
var kauf_total := 0                  # AT-02/FX3: Σ Käufe (Cent): Fahrzeuge, Ersetzen, Firmenkauf, Werksausbau
var _fix_dirty := false
var lebensdauer_erreicht: Array = []  # FZ-03: [{tick, vid}]
var alterung_an := true              # FZ-03: Unterhalt steigt je Kalenderjahr (aus nur für den Zwei-Uhren-Test)
var _vdefs: Dictionary = {}          # vehicles.json id -> Datensatz
var strassen = null                  # proto_strassenband.gd
var regelwerk: Dictionary = {}
var mm_pro_m := 40.0
var knoten_pos: Dictionary = {}      # Knoten-ID -> Vector3 (m)
var knoten_grad: Dictionary = {}     # Knoten-ID -> Anzahl Kanten
var knoten_wege: Dictionary = {}     # Knoten-ID -> Anzahl Wege (≥ 2 = Einmündung/Kreuzung)
var anker_knoten: Array = []         # je Weg: PackedInt32Array Knoten-ID je Anker
var anker_s: Array = []              # je Weg: PackedFloat32Array monotones s je Anker
var kante: Dictionary = {}           # Kanten-ID -> [weg, k]  (a = Anker k, b = Anker k+1)
var fahrzeuge: Array = []            # [{vid, kat, name, von, nach, legs, zustand, profil}]
var stationen: Dictionary = {}       # Name -> {knoten, site, k, id}
var lieferungen: Array = []          # [{tick, vid, menge, cent, gut}]
var fehler: Array = []
var kette_ok := false
var ticks := 0
var _profile: Dictionary = {}
var tempo_k := 1                     # AT-04 (S8): Tempo-Teiler aus regelwerk fahrzeug_easing.tempo_k, Nutzerargument --tempo_k=
var _vdef: Dictionary = {}


func _init(p_regelwerk: Dictionary = {}) -> void:
	regelwerk = p_regelwerk
	sim = SimWorld.new()
	tempo_k = tempo_k_aus(regelwerk)
	kalender = Kalender.fuer_welt(int(regelwerk.get("startjahr", 1820)))


## AT-04 (W1): k aus regelwerk fahrzeug_easing.tempo_k.standard (fehlt = 1); `--tempo_k=N` überschreibt.
static func tempo_k_aus(rw: Dictionary) -> int:
	var tk = rw.get("fahrzeug_easing", {}).get("tempo_k", {})
	var k: int = int(tk.get("standard", 1)) if tk is Dictionary else 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tempo_k="):
			k = int(a.substr(10))
	return maxi(k, 1)


func profil(kat: String):
	if not _profile.has(kat):
		var p = Easing.Profil.aus_regelwerk(regelwerk, kat)
		var fe: Dictionary = regelwerk.get("fahrzeug_easing", {})
		var tk = fe.get("tempo_k", {})
		var gilt: Array = tk.get("gilt_fuer", ["fuhrwerk", "postkutsche"]) if tk is Dictionary else ["fuhrwerk", "postkutsche"]
		if tempo_k != 1 and kat in gilt:
			# AT-04: einzige Tempo-Quelle bleibt sim_felder_je_tick_promille (W1), hier nur ÷ k, ganzzahlig in mm/Tick
			var promille: int = int(fe.get("kategorien", {}).get(kat, {}).get("sim_felder_je_tick_promille", 600))
			if promille % tempo_k != 0:
				fehler.append("tempo_k %d teilt %s-Tempo %d nicht ganzzahlig" % [tempo_k, kat, promille])
			var mpf := float(regelwerk.get("skalen", {}).get("m_pro_feld", Easing.M_PRO_FELD))
			p.v_nom = float(promille / tempo_k) / 1000.0 * mpf
		_profile[kat] = p
	return _profile[kat]


# ------------------------------------------------------------------ Graph

func graph_bauen(p_strassen) -> void:
	strassen = p_strassen
	var mpf := float(regelwerk.get("skalen", {}).get("m_pro_feld", 25.0))
	mm_pro_m = float(sim.feld_mm) / mpf
	var schluessel := {}
	var naechste := 1
	anker_knoten.clear()
	anker_s.clear()
	for wi in strassen.fahrlinien.size():
		var fl = strassen.fahrlinien[wi]
		var ids := PackedInt32Array()
		var ss := PackedFloat32Array()
		for k in fl.anker.size():
			var a: Vector2 = fl.anker[k]
			var key := Vector2i(roundi(a.x * 2.0), roundi(a.y * 2.0))
			var s := float(fl.anker_s[k]) if k < fl.anker_s.size() else 0.0
			if ss.size() > 0:
				s = maxf(s, ss[-1])              # Projektion kann bei dichten Ankern minimal rückwärts laufen
			ss.append(s)
			if schluessel.has(key):
				ids.append(schluessel[key])
				continue
			schluessel[key] = naechste
			knoten_pos[naechste] = Vector3(a.x, fl.strecke_punkt(s).y, a.y)
			ids.append(naechste)
			naechste += 1
		anker_knoten.append(ids)
		anker_s.append(ss)
	# Wegenden auf andere Wege fangen (Kreuzungspunkt wurde dort als Anker eingefügt, liegt ≤ Fang daneben).
	# Ein Wegende, das schon ein Knoten eines anderen Wegs ist (gleicher Punkt), bleibt, wie es ist.
	var wege_je_knoten := {}
	for wi in anker_knoten.size():
		for nid in anker_knoten[wi]:
			if not wege_je_knoten.has(nid):
				wege_je_knoten[nid] = {}
			wege_je_knoten[nid][wi] = true
	var alias := {}
	for wi in anker_knoten.size():
		var ids: PackedInt32Array = anker_knoten[wi]
		if ids.size() < 2:
			continue
		var fang := maxf(4.0, float(strassen.fahrlinien[wi].trasse_m) * 0.5) + 0.5
		for ende in [0, ids.size() - 1]:
			var nid: int = ids[ende]
			if wege_je_knoten[nid].size() > 1:
				continue
			var p: Vector3 = knoten_pos[nid]
			var best := -1
			var bd := INF
			for wj in anker_knoten.size():
				if wj == wi:
					continue
				var fj := maxf(4.0, float(strassen.fahrlinien[wj].trasse_m) * 0.5) + 0.5
				for oid in anker_knoten[wj]:
					if oid == nid:
						continue
					var d := Vector2(p.x, p.z).distance_to(Vector2(knoten_pos[oid].x, knoten_pos[oid].z))
					if d < bd and d <= maxf(fang, fj):
						bd = d
						best = oid
			if best > 0 and not alias.has(best):
				alias[nid] = best
	for wi in anker_knoten.size():
		var ids: PackedInt32Array = anker_knoten[wi]
		for k in ids.size():
			while alias.has(ids[k]):
				ids[k] = alias[ids[k]]
		anker_knoten[wi] = ids
	var benutzt := {}
	for wi in anker_knoten.size():
		var gesehen := {}
		for nid in anker_knoten[wi]:
			benutzt[nid] = true
			if not gesehen.has(nid):
				gesehen[nid] = true
				knoten_wege[nid] = knoten_wege.get(nid, 0) + 1
	var sortiert := benutzt.keys()
	sortiert.sort()
	for nid in sortiert:
		var p: Vector3 = knoten_pos[nid]
		sim.add_node(nid, Vector2i(roundi(p.x * mm_pro_m), roundi(p.z * mm_pro_m)), "k%d" % nid)
		knoten_grad[nid] = 0
	var eid := 1
	var paare := {}
	for wi in anker_knoten.size():
		var ids: PackedInt32Array = anker_knoten[wi]
		for k in ids.size() - 1:
			var a := ids[k]
			var b := ids[k + 1]
			if a == b:
				continue
			var pk := Vector2i(mini(a, b), maxi(a, b))
			if paare.has(pk):
				continue
			if sim.graph.nodes[a]["pos"] == sim.graph.nodes[b]["pos"]:
				continue
			paare[pk] = true
			sim.graph.add_edge(eid, a, b, true)
			kante[eid] = [wi, k]
			knoten_grad[a] += 1
			knoten_grad[b] += 1
			eid += 1


func knoten_naechst(p: Vector2, nur_kreuzung := false, r_max := INF) -> int:
	var best := -1
	var bd := INF
	for nid in knoten_grad:
		if knoten_grad[nid] == 0:
			continue
		if nur_kreuzung and knoten_grad[nid] < 3:
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd and d <= r_max:
			bd = d
			best = nid
	return best


## Halteknoten an einem Gebäude: Wegende oder Kreuzung (Grad ≠ 2) bis 40 m, sonst nächster Knoten. So endet die
## Linie nicht 10 m vor einer Einmündung (sonst bleibt für den Übergangsbogen kein Platz).
func knoten_halt(p: Vector2) -> int:
	var best := -1
	var bd := INF
	for nid in knoten_grad:
		var g: int = knoten_grad[nid]
		if g == 0 or (g == 2 and knoten_wege.get(nid, 1) < 2):
			continue
		var q: Vector3 = knoten_pos[nid]
		var d := p.distance_to(Vector2(q.x, q.z))
		if d < bd and d <= 40.0:
			bd = d
			best = nid
	return best if best > 0 else knoten_naechst(p)


# ------------------------------------------------------------------ Linien

## Routenlinie (Darstellung) aus einer Sim-Route [{edge, fwd}].
func routenlinie(route: Array, prof):
	var roh := PackedVector3Array()
	var roh_s := PackedFloat32Array()
	var ueb := PackedInt32Array()
	var grenzen := PackedFloat32Array()
	var knoten := PackedVector3Array()
	var rtyp := PackedFloat32Array()
	var fahrbahn := PackedFloat32Array()
	var r_ueb := PackedFloat32Array()
	var weg_alt := -1
	var cum := 0.0
	for si in route.size():
		var st: Dictionary = route[si]
		var info: Array = kante[st["edge"]]
		var wi: int = info[0]
		var k: int = info[1]
		var fl = strassen.fahrlinien[wi]
		var ss: PackedFloat32Array = anker_s[wi]
		var e: Dictionary = sim.graph.edges[st["edge"]]
		var von_a: bool = st["fwd"]          # fwd = a → b = Anker k → k+1
		var s0 := ss[k] if von_a else ss[k + 1]
		var s1 := ss[k + 1] if von_a else ss[k]
		var r_typ := float(strassen.profile.get(fl.typ, strassen.profile["dorfstrasse"])["radius"])
		var n := maxi(1, ceili(absf(s1 - s0) / Easing.DS))
		if si == 0:
			var n0: int = e["a"] if von_a else e["b"]
			var p0: Vector3 = fl.strecke_punkt(s0)
			knoten.append(Vector3(knoten_pos[n0].x, p0.y, knoten_pos[n0].z))
		if wi != weg_alt and weg_alt >= 0:
			ueb.append(roh.size() - 1)
			var r_alt := float(strassen.profile.get(strassen.fahrlinien[weg_alt].typ, strassen.profile["dorfstrasse"])["radius"])
			r_ueb.append(minf(r_alt, r_typ))
		for j in n + 1:
			if j == 0 and roh.size() > 0 and wi == weg_alt:
				continue
			var s := lerpf(s0, s1, float(j) / n)
			var p: Vector3 = fl.strecke_punkt(s)
			if roh.size() > 0:
				cum += Vector2(p.x, p.z).distance_to(Vector2(roh[-1].x, roh[-1].z))
			roh.append(p)
			roh_s.append(cum)
			rtyp.append(r_typ)
			fahrbahn.append(float(fl.fahrbahn_m))
		if si == 0:
			grenzen.append(0.0)
		grenzen.append(cum)
		var n1: int = e["b"] if von_a else e["a"]
		knoten.append(Vector3(knoten_pos[n1].x, roh[-1].y, knoten_pos[n1].z))
		weg_alt = wi
	var rl = Easing.routenlinie_bauen(roh, roh_s, ueb, grenzen, knoten, rtyp, r_ueb, prof, fahrbahn)
	# Fix-Pass W2 (M2): Sackgasse (Knoten mit nur einer Kante) → das Gespann hält ein halbes Gespann vor dem Bandende
	if not route.is_empty():
		var e_a: Dictionary = sim.graph.edges[route[0]["edge"]]
		var e_b: Dictionary = sim.graph.edges[route[-1]["edge"]]
		var n_start: int = e_a["a"] if route[0]["fwd"] else e_a["b"]
		var n_ende: int = e_b["b"] if route[-1]["fwd"] else e_b["a"]
		var rand: float = minf(prof.halt_rand_m(), rl.laenge * 0.25)
		rl.rand_start = rand if int(knoten_grad.get(n_start, 0)) == 1 else 0.0
		rl.rand_ende = rand if int(knoten_grad.get(n_ende, 0)) == 1 else 0.0
	_quergefaelle(rl, prof)
	return rl


## Quergefälle des Bands je Fahrlinien-Probe → Wanken (rad, + = linke Modellseite höher): Gelände links/rechts der
## Bandmitte im Abstand der halben Spurweite (das Band folgt dem Gelände, proto_strassenband Y_OFF konstant).
func _quergefaelle(rl, prof) -> void:
	if strassen == null or not strassen.hoehe_funktion.is_valid():
		return
	var n: int = rl.spur.size()
	rl.quer.resize(n)
	var h: float = prof.breite_m * 0.5
	for k in n:
		var g: float = rl.gier[k]
		var l: Vector2 = Vector2(cos(g), -sin(g)) * h          # Modell +x (links) in der Fahrtrichtung g
		var m: Vector3 = rl.spur[k]
		if m.y - float(strassen.hoehe_funktion.call(m.x, m.z)) > 0.6:
			rl.quer[k] = 0.0                              # Brückendeck/Rampe: Deck ist waagerecht, nicht das Gelände darunter
			continue
		var hl: float = float(strassen.hoehe_funktion.call(m.x + l.x, m.z + l.y))
		var hr: float = float(strassen.hoehe_funktion.call(m.x - l.x, m.z - l.y))
		rl.quer[k] = clampf(atan((hl - hr) / (2.0 * h)), -deg_to_rad(6.0), deg_to_rad(6.0))
	rl.quer = Easing._kasten(rl.quer, 4)


## Linienfahrzeug von Knoten a nach b (Pendel). Gibt den Fahrzeug-Eintrag zurück oder {} bei Fehler.
func linie(kat: String, name: String, von: int, nach: int, src_k: int, dst_k: int, leere_fahrt := false, vdef: Dictionary = {}) -> Dictionary:
	if von < 0 or nach < 0:
		fehler.append("%s: Knoten fehlt" % name)
		return {}
	var route: Array = sim.graph.find_path(von, nach)
	if route.is_empty():
		fehler.append("%s: keine Verbindung %d → %d" % [name, von, nach])
		return {}
	var prof = profil(kat)
	var lkw: Dictionary = vdef if not vdef.is_empty() else self.vdef(def_fuer(kat))   # FZ-01: Kosten je Kategorie
	if lkw.is_empty():
		lkw = _lkw()
	var vid := fahrzeuge.size() + 1
	var cap := int(lkw.get("kapazitaet_einheiten", 10))
	var var_cent := int(lkw.get("variabel_cent_pro_feld", 0))
	var load_ticks := 100
	if eco != null:
		load_ticks = int(eco.slice.get("fahrzeug_ref", {}).get("load_ticks", 100))
	var speed_mm := roundi(prof.v_nom * mm_pro_m)
	sim.add_line_vehicle(vid, name, route, speed_mm, cap, src_k, dst_k, load_ticks, MAX_WAIT_TICKS, var_cent)
	if leere_fahrt:
		sim.set_line_flags(vid, true, MAX_WAIT_TICKS)
	# Leg 1 (Rückweg) wird nachgereicht (tick(): eines je Tick), das spart Ladezeit; gebraucht erst am Linienende.
	var legs := [routenlinie(route, prof), null]
	var z = Easing.Zustand.new(prof, legs)
	var f := {"vid": vid, "kat": kat, "name": name, "von": von, "nach": nach, "legs": legs, "zustand": z,
		"profil": prof, "route_kanten": route.size(), "sim_mm": sim.graph.route_length(route), "route": route,
		"def_id": "", "kauf_cent": 0, "fix_cent": 0, "kauf_tick": sim.tick_count, "verkauft": false}
	fahrzeuge.append(f)
	_probe(f)
	z.folger_setzen()
	return f


func _lkw() -> Dictionary:
	if _vdef.is_empty() and FileAccess.file_exists(VEHICLES_JSON):
		var d = JSON.parse_string(FileAccess.get_file_as_string(VEHICLES_JSON))
		var id := "lkw_e1"
		if eco != null:
			id = String(eco.slice.get("fahrzeug_ref", {}).get("lkw_id", id))
		for v in d.get("fahrzeuge", []):
			if v.get("id", "") == id:
				_vdef = v
	return _vdef


## FX4: Lager-Slot am Knoten für die Kulisse (Postkutsche); vorhandene Station wird wiederverwendet, kein Eintrag in stationen.
func _halt_station(knoten: int) -> int:
	if not sim._station_of.has(knoten):
		sim.add_station(knoten, "Halt k%d" % knoten, 0, 0, 0)
	return int(sim._station_of[knoten])


## Station ohne Ökonomie (synthetische Tests): Lager-Slot am Knoten.
func station_leer(name: String, knoten: int) -> int:
	sim.add_station(knoten, name, 0, 0, 0)
	var k: int = sim._station_of[knoten]
	stationen[name] = {"knoten": knoten, "site": -1, "k": k, "id": ""}
	return k


## Synthetische Pendellinie (Tests): Knoten nächst den Punkten, leere Stationen, leave_empty.
func testlinie(kat: String, von: Vector2, nach: Vector2) -> Dictionary:
	var a := knoten_naechst(von)
	var b := knoten_naechst(nach)
	var ka := station_leer("A%d" % fahrzeuge.size(), a) if not sim._station_of.has(a) else int(sim._station_of[a])
	var kb := station_leer("B%d" % fahrzeuge.size(), b) if not sim._station_of.has(b) else int(sim._station_of[b])
	return linie(kat, "%s %d" % [kat, fahrzeuge.size() + 1], a, b, ka, kb, true)


# ------------------------------------------------------------------ Kette Farm → Mühle → Dorf

## orte = proto_orte.json (Dictionary mit orte, industrie). extra_fuhrwerke: zusätzliche Fahrzeuge (nur E8-Bench).
func kette_aufbauen(orte: Dictionary, extra_fuhrwerke := 0) -> bool:
	if not oeko_laden():
		return false
	if not orte_registrieren(orte):
		return false
	var n_farm: int = _reg["n_farm"]
	var n_muehle: int = _reg["n_muehle"]
	var n_dorf: int = _reg["n_dorf"]
	var n_stadt: int = _reg["n_stadt"]
	var s_farm: int = _reg["s_farm"]
	var s_muehle: int = _reg["s_muehle"]
	var s_dorf: int = _reg["s_dorf"]
	var s_stadt: int = _reg["s_stadt"]
	if not eco.start_company_at(n_dorf, "dorf"):                   # HQ an der Dorf-Station (UI ist_hq vergleicht Site-Position)
		fehler.append("Kette: Firma nicht gegründet")
	for s in [s_farm, s_muehle]:
		var r: Dictionary = eco.buy_licence(s)
		if not r.get("ok", false):
			fehler.append("Lizenz %s: %s" % [eco.i_ids[eco.s_def[s]], r.get("fehler", "?")])
	eco.seed_stock(s_farm, "getreide", START_GETREIDE)
	var n0 := fahrzeuge.size()
	linie("fuhrwerk", "Fuhrwerk 1 (Getreide)", n_farm, n_muehle, eco.s_station[s_farm], eco.s_station[s_muehle])
	linie("fuhrwerk", "Fuhrwerk 2 (Mehl)", n_muehle, n_dorf, eco.s_station[s_muehle], eco.s_station[s_dorf])
	if s_stadt >= 0:
		# FX4 (Option b): Postkutsche (Kulisse, W21) hält wie bisher an den Ortsknoten, nicht am Ladeplatz
		var m_dorf: int = _reg["m_dorf"]
		var m_stadt: int = _reg["m_stadt"]
		linie("postkutsche", "Postkutsche", m_dorf, m_stadt, _halt_station(m_dorf), _halt_station(m_stadt), true)
	for x in extra_fuhrwerke:
		if x % 2 == 0:
			linie("fuhrwerk", "Fuhrwerk Bench %d" % x, n_farm, n_muehle, eco.s_station[s_farm], eco.s_station[s_muehle])
		else:
			linie("fuhrwerk", "Fuhrwerk Bench %d" % x, n_muehle, n_dorf, eco.s_station[s_muehle], eco.s_station[s_dorf])
	kette_ok = fahrzeuge.size() - n0 >= 2 and fehler.is_empty()
	return kette_ok


var _reg: Dictionary = {}            # Knoten/Sites der registrierten Orte (orte_registrieren)

## AT-02: Ökonomie laden (economy_slice.json), Konto und Kredit anbinden. Keine Firma, keine Kette.
func oeko_laden() -> bool:
	eco = Economy.new()
	if not eco.load_from(SLICE_JSON, CONSTS_JSON):
		fehler.append("Ökonomie-JSON: " + ", ".join(eco.errors))
		eco = null
		return false
	if FileAccess.file_exists(PROTO_JSON):
		var pj = JSON.parse_string(FileAccess.get_file_as_string(PROTO_JSON))
		if pj is Dictionary:
			eco.apply_proto(pj)                   # FK-02: nur die Welt, der Slice ruft das nie
	for arg in OS.get_cmdline_user_args():          # FX3: --a=<Promille> überschreibt tempo_ausgleich_promille (Bot, Kalibrierung)
		if arg.begins_with("--a=") and arg.substr(4).is_valid_int():
			eco.ertrag_a_promille = int(arg.substr(4))
	eco.attach(sim)
	sim.feld_mm = eco.feld_mm
	konto.eco = eco
	credit.setup(eco)
	return true


## AT-03: alle Industrien und Sim-Orte aus proto_orte.json als Sites registrieren (Stationen, keine Lizenz, keine
## Fahrzeuge). Industrie-Typ → economy-Industrie über IND_TYP; Ladeplatz (falls in den Daten) vor Hofmitte.
## Orte mit sim_knoten: Stadt-Eintrag je Ort aus sim_stufe + sim_ew (Overlay in eco.c_index, id "proto_<ort>"),
## economy_slice.json bleibt unberührt. Fehlt sim_ew, gilt der Slice-Typ (dorf_agrar / kleinstadt_a) wie bis S8.
## _reg merkt den ersten Ort je Rolle (Farm, Mühle, Dorf, Kleinstadt) für die feste Kette.
const IND_TYP := {"getreidefarm": "getreidefarm", "wassermuehle": "muehle", "muehle": "muehle"}
const ORT_FALLBACK := {"dorf": "dorf_agrar", "kleinstadt": "kleinstadt_a", "marktflecken": "kleinstadt_a", "markt": "kleinstadt_a"}
var uebersprungen: Array = []        # AT-03: [Name, Grund] nicht registrierter Einträge

func orte_registrieren(orte: Dictionary) -> bool:
	_reg = {"n_farm": -1, "n_muehle": -1, "n_dorf": -1, "n_stadt": -1, "s_farm": -1, "s_muehle": -1, "s_dorf": -1, "s_stadt": -1,
		"m_dorf": -1, "m_stadt": -1}
	for ind in orte.get("industrie", []):
		var nm := String(ind.get("name", ind.get("id", "?")))
		var def: String = IND_TYP.get(String(ind.get("typ", "")), "")
		if def == "":
			uebersprungen.append([nm, "Typ %s ohne Industrie" % ind.get("typ", "")])
			continue
		var p := Vector2(float(ind["x"]), float(ind["z"]))
		var lp = ind.get("ladeplatz", null)
		if lp is Dictionary and lp.has("x"):
			p = Vector2(float(lp["x"]), float(lp["z"]))
		var n := knoten_halt(p)
		if n < 0 or eco.site_of_node(n) >= 0:
			uebersprungen.append([nm, "kein freier Knoten"])
			continue
		var site: int = eco.add_industry_site(n, def)
		stationen[nm] = {"knoten": n, "site": site, "k": eco.s_station[site], "id": def, "ort_id": String(ind.get("id", "")),
			"abstand_m": p.distance_to(Vector2(knoten_pos[n].x, knoten_pos[n].z))}
		var rolle := "farm" if def == "getreidefarm" else "muehle"
		if int(_reg["s_" + rolle]) < 0:
			_reg["n_" + rolle] = n
			_reg["s_" + rolle] = site
	for o in orte.get("orte", []):
		var nm := String(o.get("name", o.get("id", "?")))
		var klasse := String(o.get("klasse", ""))
		if not bool(o.get("sim_knoten", ORT_FALLBACK.has(klasse))):
			uebersprungen.append([nm, "kein Sim-Knoten"])
			continue
		var stufe := String(o.get("sim_stufe", "dorf" if klasse == "dorf" else "kleinstadt"))
		var city_id: String = ORT_FALLBACK.get(klasse, "")
		if o.has("sim_ew"):
			city_id = "proto_" + String(o.get("id", nm))
			eco.c_index[city_id] = {"id": city_id, "stage_id": stufe, "einwohner_anzahl": int(o["sim_ew"])}
		if city_id == "":
			uebersprungen.append([nm, "Klasse %s ohne Stadt-Typ" % klasse])
			continue
		var c := Vector2(float(o["x"]), float(o["z"]))
		var n_mitte := knoten_naechst(c, true, float(o.get("r_m", 200.0)))
		if n_mitte < 0:
			n_mitte = knoten_naechst(c)
		# FX4 (PO 05.11., Option b): Wirtschafts-Station (Fuhrwerke, HQ) am Ladeplatz (WA-08); Ortsknoten bleibt für die Postkutsche
		var n := n_mitte
		var olp = o.get("ladeplatz", null)
		if olp is Dictionary and olp.has("x"):
			var lp := Vector2(float(olp["x"]), float(olp["z"]))
			var n_lp := knoten_halt(lp)
			if n_lp >= 0 and eco.site_of_node(n_lp) < 0:
				n = n_lp
				c = lp
		if n < 0 or eco.site_of_node(n) >= 0:
			uebersprungen.append([nm, "kein freier Knoten"])
			continue
		var site: int = eco.add_city_site(n, city_id)
		stationen[nm] = {"knoten": n, "site": site, "k": eco.s_station[site], "id": city_id, "ort_id": String(o.get("id", "")),
			"abstand_m": c.distance_to(Vector2(knoten_pos[n].x, knoten_pos[n].z)), "knoten_mitte": n_mitte}
		var rolle := "dorf" if stufe == "dorf" else "stadt"
		if int(_reg["s_" + rolle]) < 0:
			_reg["n_" + rolle] = n
			_reg["s_" + rolle] = site
			_reg["m_" + rolle] = n_mitte
	if int(_reg["s_farm"]) < 0 or int(_reg["s_muehle"]) < 0 or int(_reg["s_dorf"]) < 0:
		fehler.append("Kette: Farm/Mühle/Dorf fehlt in proto_orte.json")
		return false
	return true


# ------------------------------------------------------------------ Spieler-API (AT-02)

## Start ohne Kette: Ökonomie, Orte als Sites, Firma mit HQ im Dorf und Startkapital aus economy_slice.json
## (hq.start_capital_cent, 6.000 $). Keine Lizenz, kein Fahrzeug, kein Startbestand.
func spiel_starten(orte: Dictionary) -> bool:
	if not oeko_laden():
		return false
	if not orte_registrieren(orte):
		return false
	if not eco.start_company_at(_reg["n_dorf"], "dorf"):          # HQ an der Dorf-Station (FX4: Ladeplatz)
		fehler.append("Start: Firma nicht gegründet")
		return false
	return true


func _ok(daten := {}) -> Dictionary:
	var r := {"ok": true}
	r.merge(daten)
	return r


func _nein(grund: String, daten := {}) -> Dictionary:
	var r := {"ok": false, "fehler": grund}
	r.merge(daten)
	return r


func _spielbar() -> String:
	if eco == null or not eco.company_started:
		return "keine_firma"
	if konto.bankrupt:
		return "bankrott"
	return ""


## Station an einer registrierten Site (Name aus proto_orte.json). Stationen entstehen mit der Site;
## hier nur Nachschlagen. Annahme S8: kein Preis (economy_slice.json kennt keinen Stationspreis).
func station_anlegen(name: String) -> Dictionary:
	if not stationen.has(name):
		return _nein("unbekannter_ort")
	return _ok(stationen[name])


## Lizenz einer Site kaufen (economy.buy_licence, Preis und Gratis-Lizenz wie Slice).
func lizenz_kaufen(name: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if not stationen.has(name) or int(stationen[name]["site"]) < 0:
		return _nein("unbekannter_ort")
	return eco.buy_licence(int(stationen[name]["site"]))


func vdef(def_id: String) -> Dictionary:
	if _vdefs.is_empty() and FileAccess.file_exists(VEHICLES_JSON):
		var d = JSON.parse_string(FileAccess.get_file_as_string(VEHICLES_JSON))
		for v in d.get("fahrzeuge", []):
			_vdefs[String(v.get("id", ""))] = v
	return _vdefs.get(def_id, {})


## FZ-01: Standard-Datensatz je Kategorie = erster kaufbarer Datensatz mit "kategorie" == kat (vehicles.json,
## fuhrwerk → fuhrwerk_e1). Fehlt einer (Postkutsche: nicht kaufbar, W21), gilt der Slice-Lkw (Fahrkosten der Kulisse).
const DEF_JE_KAT := {"fuhrwerk": "fuhrwerk_e1"}

func def_fuer(kat: String) -> String:
	var id: String = DEF_JE_KAT.get(kat, "")
	if id != "" and not vdef(id).is_empty():
		return id
	if eco != null:
		return String(eco.slice.get("fahrzeug_ref", {}).get("lkw_id", "lkw_e1"))
	return "lkw_e1"


## Linie von Station a nach b anlegen und ein Fahrzeug kaufen (Kaufpreis über konto.charge, Fix ab sofort).
## Eine zweite Linie a→b ist ein weiteres Fahrzeug. Gibt {ok, vid, preis_cent} oder {ok: false, fehler}.
func linie_anlegen(von_name: String, nach_name: String, kat := "fuhrwerk", def_id := "") -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	if not stationen.has(von_name) or not stationen.has(nach_name):
		return _nein("unbekannter_ort")
	if von_name == nach_name:
		return _nein("gleicher_ort")
	if def_id == "":
		def_id = def_fuer(kat)
	if GESPERRT_S8.has(def_id):
		return _nein("gesperrt")
	var d := vdef(def_id)
	if d.is_empty():
		return _nein("unbekanntes_fahrzeug")
	if kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(d["verfuegbar_ab_jahr"])})
	var a: Dictionary = stationen[von_name]
	var b: Dictionary = stationen[nach_name]
	if sim.graph.find_path(int(a["knoten"]), int(b["knoten"])).is_empty():
		return _nein("keine_verbindung")
	var preis := int(d.get("kauf_cent", 0))
	if preis > eco.cash_cent:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": preis - eco.cash_cent})
	var n_alt := fehler.size()
	var f := linie(kat, "%s %d" % [String(d.get("name", kat)), fahrzeuge.size() + 1], int(a["knoten"]), int(b["knoten"]), int(a["k"]), int(b["k"]), false, d)
	if f.is_empty():
		return _nein(String(fehler[-1]) if fehler.size() > n_alt else "linie")
	konto.charge(preis)
	kauf_total += preis
	f["def_id"] = def_id
	f["kauf_cent"] = preis
	f["fix_cent"] = int(d.get("fix_cent_pro_periode", 0))
	f["kauf_tick"] = sim.tick_count
	_fix_dirty = true
	return _ok({"vid": f["vid"], "preis_cent": preis})


func fahrzeug(vid: int) -> Dictionary:
	for f in fahrzeuge:
		if f["vid"] == vid:
			return f
	return {}


## Lebensdauer in Ticks: lebensdauer_jahre × jahr_ticks (FZ-01), sonst lebensdauer_ticks (Slice-Datensatz).
func lebensdauer_ticks(f: Dictionary) -> int:
	var d := vdef(String(f.get("def_id", "")))
	if d.has("lebensdauer_jahre"):
		return int(d["lebensdauer_jahre"]) * jahr_ticks
	return int(d.get("lebensdauer_ticks", 0))


## W20: Restwert = Kauf × 50 % × max(20 %, 1 − Alter/Lebensdauer) (Untergrenze 10 % des Kaufpreises). Ganzzahlig.
func restwert(f: Dictionary) -> int:
	var kauf: int = int(f.get("kauf_cent", 0))
	var ld := lebensdauer_ticks(f)
	var alter: int = sim.tick_count - int(f.get("kauf_tick", 0))
	var rest_pm := RESTWERT_MIN_PM
	if ld > 0:
		rest_pm = maxi(RESTWERT_MIN_PM, 1000 - alter * 1000 / ld)
	return kauf * RESTWERT_PM / 1000 * rest_pm / 1000


## Fahrzeug verkaufen: Restwert gutschreiben (konto.erstatten), Fix 0, Fahrzeug steht (Ladung verfällt wie Slice B-01).
func fahrzeug_verkaufen(vid: int) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var f := fahrzeug(vid)
	if f.is_empty() or f["verkauft"]:
		return _nein("unbekanntes_fahrzeug")
	var rw := restwert(f)
	sim.line_stop(vid)
	if eco.v_lots.has(vid):
		eco.v_lots.erase(vid)
	f["verkauft"] = true
	f["fix_cent"] = 0
	konto.erstatten(rw)
	_fix_dirty = true
	return _ok({"restwert_cent": rw})


func kredit_aufnehmen() -> int:
	if _spielbar() != "":
		return 0
	return credit.borrow(eco, sim.tick_count)


func kredit_tilgen() -> int:
	if _spielbar() != "":
		return 0
	return credit.repay(eco, sim.tick_count)


## FZ-03: Alter in Kalenderjahren = Jahreswechsel seit dem Kauf (einmal je Kalenderjahr, nicht am Kaufjubiläum).
func alter_jahre(f: Dictionary) -> int:
	return maxi(0, kalender.jahr(sim.tick_count) - kalender.jahr(int(f.get("kauf_tick", 0))))


## FZ-03: fix_eff = fix × (10.000 + bp × Jahre) / 10.000, ganzzahlig (bp = alterung_unterhalt_bp_pro_jahr).
func fix_eff(f: Dictionary) -> int:
	if f["verkauft"]:
		return 0
	var fix := int(f.get("fix_cent", 0))
	if not alterung_an or fix == 0:
		return fix
	var bp := int(vdef(String(f.get("def_id", ""))).get("alterung_unterhalt_bp_pro_jahr", 0))
	return fix * (10000 + bp * alter_jahre(f)) / 10000


## FZ-04: Vorschau Ersetzen (Karte „Ersetzen spart z/min“): altes Fahrzeug zum Restwert (W20) gegen neues Modell
## derselben Kategorie, die Linie läuft weiter. {ok, restwert_cent, preis_cent, netto_cent, fix_alt_cent, fix_neu_cent,
## spart_cent_pro_periode, alter_jahre, def_id} oder {ok: false, fehler}.
func ersetzen_angebot(vid: int, def_id := "") -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var f := fahrzeug(vid)
	if f.is_empty() or f["verkauft"] or String(f.get("def_id", "")) == "":
		return _nein("unbekanntes_fahrzeug")
	if def_id == "":
		def_id = String(f["def_id"])
	var d := vdef(def_id)
	if d.is_empty():
		return _nein("unbekanntes_fahrzeug")
	if String(d.get("kategorie", "")) != String(vdef(String(f["def_id"])).get("kategorie", "?")):
		return _nein("andere_kategorie")
	if kalenderjahr() < int(d.get("verfuegbar_ab_jahr", 0)):
		return _nein("noch_nicht_verfuegbar", {"ab_jahr": int(d["verfuegbar_ab_jahr"])})
	if sim.v_cargo[sim.slot_of(vid)] > int(d.get("kapazitaet_einheiten", 0)):
		return _nein("ladung_zu_gross")
	var rw := restwert(f)
	var preis := int(d.get("kauf_cent", 0))
	var fa := fix_eff(f)
	var fn := int(d.get("fix_cent_pro_periode", 0))
	return _ok({"restwert_cent": rw, "preis_cent": preis, "netto_cent": preis - rw, "fix_alt_cent": fa, "fix_neu_cent": fn,
		"spart_cent_pro_periode": fa - fn, "alter_jahre": alter_jahre(f), "def_id": def_id,
		"kapazitaet_neu": int(d.get("kapazitaet_einheiten", 0)), "kaufbar": preis - rw <= eco.cash_cent})


## FZ-04: Ersetzen. Restwert gutschreiben (konto.erstatten), Kauf buchen (konto.charge), Fahrzeug bleibt auf der Linie
## (gleicher Sim-Slot, Position, Ladung); neues Alter 0, Kosten und Kapazität aus dem neuen Datensatz.
func fahrzeug_ersetzen(vid: int, def_id := "") -> Dictionary:
	var q := ersetzen_angebot(vid, def_id)
	if not q["ok"]:
		return q
	if not q["kaufbar"]:
		return _nein("guthaben_reicht_nicht", {"fehlt_cent": int(q["netto_cent"]) - eco.cash_cent})
	var f := fahrzeug(vid)
	var d := vdef(String(q["def_id"]))
	konto.erstatten(int(q["restwert_cent"]))
	konto.charge(int(q["preis_cent"]))
	kauf_total += int(q["preis_cent"])
	var i: int = sim.slot_of(vid)
	sim.v_cargo_cap[i] = int(d.get("kapazitaet_einheiten", sim.v_cargo_cap[i]))
	sim.v_var_cent[i] = int(d.get("variabel_cent_pro_feld", sim.v_var_cent[i]))
	f["def_id"] = String(q["def_id"])
	f["kauf_cent"] = int(q["preis_cent"])
	f["fix_cent"] = int(d.get("fix_cent_pro_periode", 0))
	f["kauf_tick"] = sim.tick_count
	f["lebensdauer_gemeldet"] = false
	_fix_dirty = true
	return _ok({"restwert_cent": q["restwert_cent"], "preis_cent": q["preis_cent"], "netto_cent": q["netto_cent"]})


func _fix_neu() -> void:
	var liste: Array = []
	for f in fahrzeuge:
		liste.append(fix_eff(f))
	konto.fix_neu(liste, eco.works_upkeep_cent_pro_periode() if eco != null else 0, 0)   # FK-02: Werksunterhalt über konto
	_fix_dirty = false


func kalenderjahr(t: int = -1) -> int:
	return kalender.jahr(sim.tick_count if t < 0 else t)


## Jahreswechsel: Freischaltungen aus regelwerk startjahr_hebel.stufen.<jahr> (*_moeglich) und vehicles.json
## verfuegbar_ab_jahr. GESPERRT_S8 (W10, Gleis) erzeugt weder Freischaltung noch Meldung.
func _jahreswechsel(jahr: int) -> void:
	var kandidaten: Array = []
	var st: Dictionary = regelwerk.get("startjahr_hebel", {}).get("stufen", {}).get(str(jahr), {})
	for k in st:
		if String(k).ends_with("_moeglich") and bool(st[k]):
			kandidaten.append(String(k))
	vdef("")
	for id in _vdefs:
		if int(_vdefs[id].get("verfuegbar_ab_jahr", -1)) == jahr:
			kandidaten.append(String(id))
	for id in kandidaten:
		if GESPERRT_S8.has(id):
			gesperrt_log.append({"tick": sim.tick_count, "jahr": jahr, "id": id, "grund": GESPERRT_S8[id]})
		else:
			freischaltungen.append({"tick": sim.tick_count, "jahr": jahr, "id": id})
			meldungen.append("Neu verfügbar: %s" % String(_vdefs.get(id, {}).get("name", id)))
	# FZ-03: Meldung, sobald ein Fahrzeug 100 % seiner Lebensdauer (Kalenderjahre) erreicht
	for f in fahrzeuge:
		if f["verkauft"] or f.get("lebensdauer_gemeldet", false):
			continue
		var ld := int(vdef(String(f.get("def_id", ""))).get("lebensdauer_jahre", 0))
		if ld > 0 and alter_jahre(f) >= ld:
			f["lebensdauer_gemeldet"] = true
			lebensdauer_erreicht.append({"tick": sim.tick_count, "vid": f["vid"]})
			meldungen.append("%s hat seine Lebensdauer erreicht (%d Jahre), Unterhalt +%d %%" % [f["name"], ld,
				int(vdef(String(f["def_id"])).get("alterung_unterhalt_bp_pro_jahr", 0)) * alter_jahre(f) / 100])


# ------------------------------------------------------------------ Firmenkauf C1 (FK-02, API für Mira)

func _site_von(name: String) -> int:
	return int(stationen[name]["site"]) if stationen.has(name) else -1


## Vorschau Kauf: Preis wie buy_site (economy.buy_quote), dazu Folgen und ob der Kauf jetzt geht.
## {ok, preis_cent, werkspreis_cent, anrechnung_cent, lizenz_gezahlt_cent, rabatt_erster_kauf, felder_hq, faktor_*,
##  unterhalt_neu_cent_pro_periode, marge_promille, lizenz_entfaellt, guthaben_ohne_kredit_cent, kaufbar, grund}
func kauf_angebot(name: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var site := _site_von(name)
	var q: Dictionary = eco.buy_quote(site)
	if not q["ok"]:
		return q
	var frei: int = eco.cash_cent - (credit.loan_cent if eco.buy_credit_blocks else 0)
	q["unterhalt_neu_cent_pro_periode"] = eco.upkeep_per_level * int(eco.s_werksstufe[site])
	q["marge_promille"] = eco.works_margin
	q["lizenz_entfaellt"] = true
	q["guthaben_ohne_kredit_cent"] = frei
	var preis: int = q["preis_cent"]
	var grund := ""
	if int(eco.s_owner[site]) == 1:
		grund = "schon_gekauft"
	elif int(eco.s_owner[site]) != 0:
		grund = "besitzer_reserviert"
	elif eco.cash_cent < 0:
		grund = "kasse_im_minus"
	elif eco.buy_only_balance and frei < preis:
		grund = "kredit_sperrt_firmenkauf" if eco.cash_cent >= preis else "guthaben_reicht_nicht"
	q["kaufbar"] = grund == ""
	q["grund"] = grund
	return q


## Kauf: economy.buy_site mit konto (Buchung als Ausgabe) und credit (Kreditgeld kauft keine Firma).
func firma_kaufen(name: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var r: Dictionary = eco.buy_site(_site_von(name), konto, credit)
	if r.get("ok", false):
		kauf_total += int(r.get("bezahlt_cent", 0))  # FX3 (QT-03b): Käufe inkl. Firmenkauf
		_fix_dirty = true
	return r


## Vorschau Ausbau: {ok, stufe_neu, kosten_cent, durchsatz_neu, unterhalt_neu_cent_pro_periode} oder {ok: false, fehler}.
func ausbau_angebot(name: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	return eco.upgrade_quote(_site_von(name))


func werk_ausbauen(name: String) -> Dictionary:
	var g := _spielbar()
	if g != "":
		return _nein(g)
	var r: Dictionary = eco.upgrade_site(_site_von(name), konto, credit)
	if r.get("ok", false):
		kauf_total += int(r.get("bezahlt_cent", 0))  # FX3 (QT-03b): Käufe inkl. Werksausbau
		_fix_dirty = true
	return r


func werksunterhalt_cent_pro_periode() -> int:
	return eco.works_upkeep_cent_pro_periode() if eco != null else 0


# ------------------------------------------------------------------ Tick

## Reihenfolge wie main.sim_tick (Slice): Sim-Schritt inkl. Öko-Tick, Fahrkosten, Lieferungen, Fix neu, konto.tick
## (Fixkosten-Akkumulator, Zins, Kasse < 0 → bankrott). Nach dem Bankrott tickt nichts mehr.
func tick() -> void:
	if konto.bankrupt:
		return
	sim.step()
	ticks += 1
	if sim.line_cost_cent != 0:
		if eco != null:
			konto.eco = eco
			konto.charge(sim.line_cost_cent)             # AT-01 (W12): wie main.charge()
			fahrkosten_total += sim.line_cost_cent
		sim.line_cost_cent = 0
	if not sim.line_events.is_empty():
		for ev in sim.line_events:
			lieferungen.append({"tick": sim.tick_count, "vid": ev[0], "menge": ev[1], "cent": ev[2], "gut": ev[3]})
		sim.line_events = []
	if eco != null and eco.company_started:
		var jw: bool = kalender.jahreswechsel(sim.tick_count)
		if jw and alterung_an:
			_fix_dirty = true                     # FZ-03: Alterung greift einmal je Kalenderjahr
		if _fix_dirty:
			_fix_neu()
		if konto.tick(sim.tick_count, credit):
			bankrott_tick = sim.tick_count
			meldungen.append("Bankrott: Kasse unter 0 $")
		if jw:
			_jahreswechsel(kalenderjahr())
	var gebaut := false
	for f in fahrzeuge:
		if not gebaut and f["legs"][1] == null:
			_leg1(f)
			gebaut = true
		_probe(f)


func _leg1(f: Dictionary) -> void:
	f["legs"][1] = routenlinie(sim.graph.reverse_route(f["route"]), f["profil"])


## Alle Rückwege sofort bauen (Tests, die Legs direkt prüfen).
func legs_vollstaendig() -> void:
	for f in fahrzeuge:
		if f["legs"][1] == null:
			_leg1(f)


func _probe(f: Dictionary) -> void:
	var i: int = sim.slot_of(f["vid"])
	var leg: int = sim.v_leg[i]
	if f["legs"][leg] == null:
		_leg1(f)
	var d := 0.0
	if sim.v_state[i] == SimWorld.S_UNTERWEGS:
		var rs: int = sim.v_rstart[i]
		var idx: int = sim.v_idx[i]
		var rl = f["legs"][leg]
		d = rl.d_von_sim(idx, float(sim.v_pos[i]) / maxf(1.0, float(sim.r_len[rs + idx])))
	f["zustand"].probe(leg, d)


func pruefsumme() -> int:
	return sim.checksum()


## Zustandstext je Fahrzeug (HUD): Name, Zustand, Ladung.
func zustand_text(f: Dictionary) -> String:
	var i: int = sim.slot_of(f["vid"])
	var st: int = sim.v_state[i]
	var namen := {SimWorld.S_UNTERWEGS: "fährt", SimWorld.S_WARTET_LADUNG: "lädt", SimWorld.S_ENTLADEN: "entlädt",
		SimWorld.S_ENDE: "steht", SimWorld.S_GEPLANT: "geplant", SimWorld.S_WARTET_BLOCK: "wartet"}
	var lad := ""
	if sim.v_cargo[i] > 0:
		var gut := "Ware"
		if eco != null and eco.v_lots.has(f["vid"]) and not eco.v_lots[f["vid"]].is_empty():
			gut = String(eco.g_ids[eco.v_lots[f["vid"]][0][0]]).capitalize()
		lad = " · %d %s" % [sim.v_cargo[i], gut]
	return "%s: %s%s" % [f["name"], namen.get(st, "?"), lad]
