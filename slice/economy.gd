extends RefCounted
## F-16 (Sprint 4): Ökonomie-Modul für den SoA-Kern (sim_world.gd). Alle Spielzahlen kommen aus
## data/economy_slice.json (T-06, L-08) und data/economy_constants.json (F-09); im Code stehen nur
## Schlüsselnamen, Einheiten-Umrechnungen (Promille = 1000) und die Tempo-Konstante MAX_VEHICLES_AT_8X.
##
## Regeln (L-08 §2–§4, §7):
##   - Ertrag NUR beim Endabnehmer (Industrie mit passendem Eingangsgut oder Stadt mit Kategorie im
##     Warenkorb). Lager zahlt `lager.warehouse_yield_cent` (= 0) je Einheit, Laden zahlt nichts.
##   - Jede Ladung trägt einen Herkunftsstempel (Ursprungs-Standort, Abfahrtstick). Der Stempel bleibt
##     im Lager erhalten (`origin_stamp.persists_in_warehouse_flag`).
##   - Distanz = Luftlinie Ursprung -> Endabnehmer in Feldern (`dist_basis_modus`), nicht Pfadlänge.
##     Ein Umweg erhöht den Ertrag also nie; er kostet nur Zeit (F_zeit).
##   - E = M × P × D_eff × F_zeit × F_sätt × (1 + B_skill), alles Ganzzahl, genau eine Division
##     (Rundung halb auf, Konvention F-09). B_skill = 0 (Skills nicht in F-16).
##   - Sättigung je Stadt und Kategorie und Periode; jede Einheit wird mit ihrem eigenen
##     Versorgungsgrad bewertet (Grenzpreis), Summe der F_sätt geht in die eine Division.
##   - Lizenz: Preis = Kaufpreis × Anteil × (1 − Rabatt im HQ-Radius | 1 + Zuschlag je Feld außerhalb),
##     Laufzeit aus JSON, Auto-Verlängerung, erste Lizenz gratis (`free_licence_count_anzahl`).
##     Laden an einer Industrie nur mit gültiger Lizenz (`licence_required_to_load_flag`).
##   - Firma = Startkapital je Archetyp beim Spielstart. Kein Kredit (S5): jede Ausgabe nur aus Guthaben.
##   - Produktion je Öko-Tick (`zeit.oeko_tick_ticks`) mit Restakkumulator (Bresenham), damit je
##     Periode exakt `produktion_l1_einheiten_pro_periode` entstehen (Tobias' offene Frage 1, F-09).
##
## Annahmen (nicht im JSON, markiert): Verarbeitung 1 Einheit je Eingangsgut -> 1 Einheit Ausgang;
## Durchsatz eines Verarbeiters = `factory_throughput_l1`; Industrien mit `abnahme_max` nehmen je Periode
## höchstens so viel an, der Rest bleibt auf dem Fahrzeug; Lager nimmt bis `warehouse_capacity` an.
## Fahrzeuge tragen jedes Gut (keine Güterklassen am Fahrzeug); ein Fahrzeug mit Restladung lädt nicht nach.

const K_INDUSTRIE := 0
const K_STADT := 1
const K_LAGER := 2

const L_WAIT := 0   # Fahrzeug wartet am Ladeknoten
const L_LOAD := 1   # laden
const L_SKIP := 2   # nicht laden, weiterfahren (Restladung an Bord)

## Refinement S4 (F-16): 8×-Tempo nur bis 5.000 Fahrzeuge. Stufen 0/1/2/4 kommen aus dem JSON.
const MAX_VEHICLES_AT_8X := 5000
const SPEED_8X := 8

const PROMILLE := 1000
const E12 := 1000000000000
const E6 := 1000000

var ok := false
var errors: PackedStringArray = PackedStringArray()
var slice: Dictionary = {}
var consts: Dictionary = {}

# ---- Konstanten (aus JSON) ----
var periode_ticks := 0
var oeko_tick_ticks := 0
var feld_mm := 0
var dist_knee := 0
var dist_slope := 0
var dist_min := 0
var f_time_min := 0
var sat_full := 0
var sat_knee := 0
var sat_floor := 0
var sat_over := 0
var demand_per_100 := 0
var lic_share := 0
var lic_duration := 0
var lic_disc := 0
var lic_surcharge := 0
var lic_auto_renew := false
var lic_required := false
var free_licences_start := 0
var warehouse_cap := 0
var warehouse_yield := 0
var stamp_persists := true
var skill_bonus := 0                     # B_skill in Promille; Skills nicht in F-16
var basket: Dictionary = {}              # stage_id -> Array[kategorie_id]
var speed_stufen: Array = []

# ---- Güter ----
var g_index: Dictionary = {}             # gut_id -> Index
var g_ids := PackedStringArray()
var g_price := PackedInt64Array()        # Cent je Einheit und Feld
var g_cat := PackedStringArray()
var g_grace := PackedInt32Array()
var g_decay := PackedInt32Array()

# ---- Industrie-Definitionen ----
var i_index: Dictionary = {}             # industrie_id -> Index
var i_ids := PackedStringArray()
var i_def: Array = []                    # Dictionary je Industrie (Rohdaten aus JSON, ints)
var c_index: Dictionary = {}             # stadt_id -> Dictionary
var chains: Array = []

# ---- Standorte (SoA) ----
var s_kind := PackedInt32Array()
var s_def := PackedInt32Array()          # Industrie-Index, -1 sonst
var s_city_id := PackedStringArray()
var s_stage := PackedStringArray()
var s_node := PackedInt32Array()
var s_x := PackedInt64Array()
var s_y := PackedInt64Array()
var s_station := PackedInt32Array()      # Lager-Slot im SimWorld
var s_out_good := PackedInt32Array()     # Ausgangsgut-Index oder -1
var s_rate := PackedInt32Array()         # Einheiten je Periode (Rohstoff: Produktion, Verarbeiter: Durchsatz)
var s_acc := PackedInt64Array()          # Restakkumulator
var s_abn_max := PackedInt32Array()      # abnahme_max je Periode, -1 = unbegrenzt
var s_intake := PackedInt32Array()
var s_intake_period := PackedInt32Array()
var s_inbuf: Array = []                  # Dictionary gut_idx -> Einheiten
var s_lots: Array = []                   # FIFO [gut, ursprung, abfahrt, menge]
var s_sat: Array = []                    # Stadt: Dictionary kategorie -> geliefert in Periode
var s_sat_period := PackedInt32Array()
var s_lic_until := PackedInt32Array()    # Tick, bis zu dem die Lizenz gilt; -1 keine
var s_revenue := PackedInt64Array()      # Ertrag, der an diesem Standort (als Ziel) gebucht wurde
var s_raw := PackedByteArray()           # 1 = Rohstoffquelle (Produktion lazy, geschlossene Form)
var s_born := PackedInt32Array()         # Öko-Tick-Index bei Anlage
var s_made := PackedInt64Array()         # Rohstoff: bisher in den Bestand gelegte Einheiten
var s_last_n := PackedInt32Array()       # Verarbeiter: Tick der letzten Kapazitätsrechnung
var s_active := PackedByteArray()        # Verarbeiter/Abnehmer mit Eingangsbestand in _buckets
var _buckets: Array = []                 # je Phase (t mod oeko_tick_ticks) die zu bearbeitenden Standorte
var _next_expiry := -1                   # frühester Lizenzablauf (Tick), -1 = keiner
var _site_of_station: Dictionary = {}    # Lager-Slot -> Standort
var _site_of_node: Dictionary = {}

# ---- Fahrzeugladungen mit Stempel (kalter Pfad, nur bei Laden/Entladen) ----
var v_lots: Dictionary = {}              # Fahrzeug-ID -> Array[[gut, ursprung, abfahrt, menge]]

# ---- Firma ----
var company_started := false
var archetyp := ""
var cash_cent := 0
var start_capital_cent := 0
var hq_x := 0
var hq_y := 0
var hq_radius_felder := 0
var free_licences_left := 0
var licence_paid_total := 0
var revenue_total := 0
var units_paid := 0
var units_to_warehouse := 0
var yield_events := 0
var ledger_enabled := true
var ledger: Array = []                   # Buchungen (nur wenn ledger_enabled)

var _simref: WeakRef = null           # schwache Referenz: sim.economy hält das Modul, kein Ref-Zyklus


func _sim_get():
	return _simref.get_ref() if _simref != null else null


# =====================================================================================  Laden

func _err(s: String) -> void:
	errors.append(s)


func _read_json(path: String):
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_err("Datei fehlt: %s" % path)
		return null
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK:
		_err("JSON-Fehler in %s Zeile %d: %s" % [path, j.get_error_line(), j.get_error_message()])
		return null
	return _ints(j.data, path)


## JSON-Zahlen kommen als float64; jede Zahl muss ganzzahlig und < 2^53 sein (Konvention F-09).
func _ints(v, path: String):
	if v is float:
		if v != floor(v) or absf(v) > 9007199254740991.0:
			_err("%s: keine Festkommazahl (%s)" % [path, str(v)])
			return 0
		return int(v)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[k] = _ints(v[k], "%s/%s" % [path, k])
		return d
	if v is Array:
		var a := []
		for k in range(v.size()):
			a.append(_ints(v[k], "%s[%d]" % [path, k]))
		return a
	return v


func _need(d: Dictionary, path: String):
	var cur = d
	for part in path.split("."):
		if not (cur is Dictionary) or not cur.has(part):
			_err("Schlüssel fehlt: %s" % path)
			return 0
		cur = cur[part]
	return cur


func _same(a_path: String, b_path: String) -> void:
	var a = _need(slice, a_path)
	var b = _need(consts, b_path)
	if a != b:
		_err("Slice %s = %s weicht von constants %s = %s ab" % [a_path, str(a), b_path, str(b)])


## Lädt Slice- und Konstanten-JSON; danach ok == true oder errors gefüllt.
func load_from(slice_path: String, consts_path: String) -> bool:
	var s = _read_json(slice_path)
	var c = _read_json(consts_path)
	if s == null or c == null:
		return false
	slice = s
	consts = c
	if _need(slice, "schema_version") != 1 or _need(consts, "schema_version") != 1:
		_err("schema_version != 1")
	periode_ticks = _need(slice, "zeit.periode_ticks")
	oeko_tick_ticks = _need(consts, "zeit.oeko_tick_ticks")
	feld_mm = _need(consts, "raum.feld_mm")
	dist_knee = _need(slice, "ertrag.dist_knee_felder")
	dist_slope = _need(slice, "ertrag.dist_slope_beyond_promille")
	dist_min = _need(slice, "ertrag.dist_min_felder")
	f_time_min = _need(slice, "zeitfaktor.f_time_min_promille")
	sat_full = _need(slice, "saettigung.sat_full_until_promille")
	sat_knee = _need(slice, "saettigung.sat_knee_promille")
	sat_floor = _need(slice, "saettigung.sat_floor_at_150_promille")
	sat_over = _need(slice, "saettigung.sat_over_150_promille")
	demand_per_100 = _need(slice, "saettigung.demand_per_100_inhabitants_einheiten_pro_periode")
	lic_share = _need(slice, "lizenz.licence_cost_share_promille")
	lic_duration = _need(slice, "lizenz.licence_duration_ticks")
	lic_disc = _need(slice, "lizenz.licence_discount_in_radius_promille")
	lic_surcharge = _need(slice, "lizenz.licence_surcharge_per_field_promille")
	lic_auto_renew = _need(slice, "lizenz.licence_auto_renew_flag")
	lic_required = _need(slice, "lizenz.licence_required_to_load_flag")
	free_licences_start = _need(slice, "hq.free_licence_count_anzahl")
	warehouse_cap = _need(slice, "lager.warehouse_capacity_einheiten")
	warehouse_yield = _need(slice, "lager.warehouse_yield_cent")
	speed_stufen = _need(slice, "genre_standard.game_speed_stufen")
	# Regeln, die das Modul so und nicht anders umsetzt: abweichende JSON-Werte sind ein Ladefehler
	if _need(slice, "ertrag.dist_basis_modus") != "luftlinie_herkunft_zu_endabnehmer":
		_err("ertrag.dist_basis_modus nicht unterstützt")
	if _need(slice, "ertrag.yield_only_at_end_customer_flag") != true:
		_err("ertrag.yield_only_at_end_customer_flag != true nicht unterstützt")
	if _need(slice, "ertrag.origin_stamp.enabled_flag") != true:
		_err("origin_stamp.enabled_flag != true nicht unterstützt")
	if _need(slice, "ertrag.rundung_modus") != "halb_auf":
		_err("rundung_modus nicht unterstützt")
	if _need(slice, "saettigung.sat_scope_modus") != "je_stadt_und_kategorie":
		_err("sat_scope_modus nicht unterstützt")
	stamp_persists = _need(slice, "ertrag.origin_stamp.persists_in_warehouse_flag")
	# Gegenprobe Slice <-> Konstanten (F-09), wo beide denselben Wert tragen
	_same("ertrag.dist_knee_felder", "ertrag.d_eff_knick_felder")
	_same("ertrag.dist_slope_beyond_promille", "ertrag.d_eff_jenseits_promille")
	_same("ertrag.dist_min_felder", "ertrag.mindestdistanz_felder")
	_same("lizenz.licence_cost_share_promille", "lizenz.anteil_promille")
	_same("lizenz.licence_duration_ticks", "lizenz.laufzeit_ticks")
	_same("saettigung.sat_floor_at_150_promille", "saettigung.abfall_ziel_promille")
	_same("hq.start_capital_agrar_cent", "startkapital_cent.agrar")
	_same("hq.start_capital_mining_cent", "startkapital_cent.bergbau")
	_same("zeit.periode_ticks", "zeit.periode_ticks")
	if periode_ticks <= 0 or oeko_tick_ticks <= 0 or periode_ticks % oeko_tick_ticks != 0:
		_err("periode_ticks muss Vielfaches von oeko_tick_ticks sein")
	for b in _need(slice, "saettigung.basket_by_stage"):
		basket[b["stage_id"]] = b["kategorien_ids"]
	# Güter
	var preise: Dictionary = _need(slice, "preise")
	for g in _need(slice, "gueter"):
		var key: String = "%s_cent_pro_einheit_feld" % g["preis_ref_id"]
		if not preise.has(key):
			_err("Preis fehlt: %s" % key)
			continue
		var kl: String = "fresh" if g["zeitklasse_modus"] == "frisch" else "bulk"
		g_index[g["id"]] = g_ids.size()
		g_ids.append(g["id"])
		g_price.append(preise[key])
		g_cat.append(g["kategorie_id"])
		g_grace.append(_need(slice, "zeitfaktor.%s_grace_ticks" % kl))
		g_decay.append(_need(slice, "zeitfaktor.%s_decay_ticks" % kl))
	# Industrien
	for ind in _need(slice, "industrien"):
		i_index[ind["id"]] = i_ids.size()
		i_ids.append(ind["id"])
		i_def.append(ind)
		for gid in ind.get("eingang_gut_ids", []):
			if not g_index.has(gid):
				_err("Industrie %s: Gut %s unbekannt" % [ind["id"], gid])
		if ind.has("ausgang_gut_id") and not g_index.has(ind["ausgang_gut_id"]):
			_err("Industrie %s: Gut %s unbekannt" % [ind["id"], ind["ausgang_gut_id"]])
	for st in _need(slice, "staedte"):
		c_index[st["id"]] = st
	chains = _need(slice, "ketten")
	for k in range(maxi(1, oeko_tick_ticks)):
		_buckets.append([])
	ok = errors.is_empty()
	return ok


# =====================================================================================  Rechnen (rein)

## Halb-auf-Division, negative Werte symmetrisch (Konvention F-09).
static func rdiv(z: int, n: int) -> int:
	var a: int = absi(z)
	var q: int = a / n
	if 2 * (a - q * n) >= n:
		q += 1
	return q if z >= 0 else -q


## round(a × b / 10^12) halb auf, ohne int64-Überlauf im Zwischenprodukt (a, b >= 0).
static func muldiv_e12(a: int, b: int) -> int:
	var ah: int = a / E6
	var al: int = a % E6
	var bh: int = b / E6
	var bl: int = b % E6
	var mid: int = ah * bl + al * bh
	var rest: int = (mid % E6) * E6 + al * bl
	return ah * bh + mid / E6 + (rest + E12 / 2) / E12


static func isqrt(v: int) -> int:
	if v <= 0:
		return 0
	var x := int(sqrt(float(v)))
	while x * x > v:
		x -= 1
	while (x + 1) * (x + 1) <= v:
		x += 1
	return x


func d_eff_x1000(d_felder: int) -> int:
	if d_felder < dist_min:
		return 0
	if d_felder <= dist_knee:
		return d_felder * PROMILLE
	return dist_knee * PROMILLE + dist_slope * (d_felder - dist_knee)


func f_zeit_promille(g: int, age_ticks: int) -> int:
	var grace := g_grace[g]
	var decay := g_decay[g]
	if age_ticks <= grace:
		return PROMILLE
	if age_ticks >= grace + decay:
		return f_time_min
	return PROMILLE - rdiv((PROMILLE - f_time_min) * (age_ticks - grace), decay)


func f_saett_promille(s_promille: int) -> int:
	if s_promille <= sat_full:
		return PROMILLE
	if s_promille <= sat_knee:
		return PROMILLE - rdiv((PROMILLE - sat_floor) * (s_promille - sat_full), sat_knee - sat_full)
	return sat_over


## E = M × P × D_eff × F_zeit × F_sätt × (1 + B_skill); fs_sum = Σ F_sätt über die M Einheiten
## (bei konstantem F_sätt = M × F_sätt). Eine Division durch 10^12.
func yield_cent(g: int, d_felder: int, fz: int, fs_sum: int) -> int:
	return muldiv_e12(g_price[g] * d_eff_x1000(d_felder), fz * fs_sum * (PROMILLE + skill_bonus))


func luftlinie_felder(a: int, b: int) -> int:
	return _felder(s_x[a] - s_x[b], s_y[a] - s_y[b])


func _felder(dx: int, dy: int) -> int:
	return rdiv(isqrt(dx * dx + dy * dy), feld_mm)


func city_demand(site: int) -> int:
	return rdiv(int(c_index[s_city_id[site]]["einwohner_anzahl"]) * demand_per_100, 100)


func city_accepts(site: int, g: int) -> bool:
	return basket.get(s_stage[site], []).has(g_cat[g])


## Erlaubte Tempostufen: JSON-Stufen, dazu 8× nur bis MAX_VEHICLES_AT_8X Fahrzeuge (Refinement S4).
func speed_steps(n_vehicles: int) -> Array:
	var a: Array = speed_stufen.duplicate()
	if n_vehicles <= MAX_VEHICLES_AT_8X:
		a.append(SPEED_8X)
	return a


# =====================================================================================  Welt

func attach(sim) -> void:
	_simref = weakref(sim)
	sim.economy = self


func _add_site(node_id: int, kind: int, label: String) -> int:
	var _sim = _sim_get()
	assert(_sim != null, "attach(sim) zuerst")
	var site := s_kind.size()
	var pos: Vector2i = _sim.graph.nodes[node_id]["pos"]
	_sim.add_station(node_id, label, 0, 0, 0)
	var k: int = _sim._station_of[node_id]
	s_kind.append(kind)
	s_def.append(-1)
	s_city_id.append("")
	s_stage.append("")
	s_node.append(node_id)
	s_x.append(pos.x)
	s_y.append(pos.y)
	s_station.append(k)
	s_out_good.append(-1)
	s_rate.append(0)
	s_acc.append(0)
	s_abn_max.append(-1)
	s_intake.append(0)
	s_intake_period.append(-1)
	s_inbuf.append({})
	s_lots.append([])
	s_sat.append({})
	s_sat_period.append(-1)
	s_lic_until.append(-1)
	s_revenue.append(0)
	s_raw.append(0)
	s_born.append(_sim.tick_count / oeko_tick_ticks)
	s_made.append(0)
	s_last_n.append(_sim.tick_count)
	s_active.append(0)
	_site_of_station[k] = site
	_site_of_node[node_id] = site
	return site


func add_industry_site(node_id: int, industry_id: String) -> int:
	if not i_index.has(industry_id):
		push_error("Industrie unbekannt: %s" % industry_id)
		return -1
	var site := _add_site(node_id, K_INDUSTRIE, industry_id)
	var di: int = i_index[industry_id]
	var d: Dictionary = i_def[di]
	s_def[site] = di
	if d.has("ausgang_gut_id"):
		s_out_good[site] = g_index[d["ausgang_gut_id"]]
		if d.get("eingang_gut_ids", []).is_empty():
			s_rate[site] = d["produktion_l1_einheiten_pro_periode"]
			s_raw[site] = 1
		else:
			s_rate[site] = _need(slice, "fabrik.factory_throughput_l1_einheiten_pro_periode")  # ANNAHME Stufe 1
	s_abn_max[site] = d.get("abnahme_max_einheiten_pro_periode", -1)
	var buf := {}
	for gid in d.get("eingang_gut_ids", []):
		buf[g_index[gid]] = 0
	s_inbuf[site] = buf
	return site


func add_city_site(node_id: int, city_id: String) -> int:
	if not c_index.has(city_id):
		push_error("Stadt unbekannt: %s" % city_id)
		return -1
	var site := _add_site(node_id, K_STADT, city_id)
	s_city_id[site] = city_id
	s_stage[site] = c_index[city_id]["stage_id"]
	return site


func add_warehouse_site(node_id: int) -> int:
	return _add_site(node_id, K_LAGER, "lager")


func site_of_node(node_id: int) -> int:
	return _site_of_node.get(node_id, -1)


## Nur für Tests/Bench: Bestand mit Stempel in einen Standort legen (Ursprung = dieser Standort).
func seed_stock(site: int, gut_id: String, units: int) -> void:
	_push_lot(site, [g_index[gut_id], site, -1, units])
	_sim_get().st_stock[s_station[site]] += units


# =====================================================================================  Firma, Lizenz

## Spielstart: Firma mit Startkapital des Archetyps (L-08 §1, D1). Kein Kredit (S5).
func start_company(archetyp_id: String, hq_node_id: int, hq_stage_id: String) -> bool:
	var keymap := {"agrar": "agrar", "bergbau": "mining", "hafen": "port", "handelsknoten": "trade"}
	var radmap := {"dorf": "village", "kleinstadt": "town", "stadt": "city", "metropole": "metro"}
	if not keymap.has(archetyp_id) or not radmap.has(hq_stage_id):
		return false
	if not slice["hq"].get("archetyp_%s_im_slice_flag" % keymap[archetyp_id], false):
		return false
	archetyp = archetyp_id
	start_capital_cent = slice["hq"]["start_capital_%s_cent" % keymap[archetyp_id]]
	cash_cent = start_capital_cent - int(slice["hq"]["hq_found_cost_cent"])
	hq_radius_felder = slice["hq"]["hq_radius_%s_felder" % radmap[hq_stage_id]]
	var hp: Vector2i = _sim_get().graph.nodes[hq_node_id]["pos"]
	hq_x = hp.x
	hq_y = hp.y
	free_licences_left = free_licences_start
	company_started = true
	return true


func licence_valid(site: int) -> bool:
	var sm = _sim_get()
	return s_lic_until[site] > (sm.tick_count if sm != null else 0)


func _licence_cost(site: int) -> int:
	var price: int = i_def[s_def[site]]["kaufpreis_stufe1_cent"]
	var d := _felder(s_x[site] - hq_x, s_y[site] - hq_y)
	var factor: int = PROMILLE - lic_disc if d <= hq_radius_felder else PROMILLE + lic_surcharge * (d - hq_radius_felder)
	return rdiv(price * lic_share * factor, PROMILLE * PROMILLE)


## Ertrag je Spielmonat bei voller Frische, ohne Sättigung: Menge je Periode × Preis × D_eff (Luftlinie
## zum nächsten Abnehmer der Kette in der Welt, sonst `strecke_felder` aus dem JSON).
func _licence_yield_month(site: int) -> Dictionary:
	var g := s_out_good[site]
	if g < 0:
		return {"cent": 0, "ziel": "", "felder": 0, "quelle": "kein Ausgangsgut"}
	var monat_perioden: int = int(_need(slice, "zeit.spielmonat_ticks")) / periode_ticks
	var units: int = s_rate[site] * monat_perioden
	var best_d := -1
	var best_ziel := ""
	var quelle := ""
	for ch in chains:
		for e in ch["kanten"]:
			if e["von_id"] != i_ids[s_def[site]] or e["gut_id"] != g_ids[g]:
				continue
			# Abnehmer der Kante in der Welt? Dann Luftlinie zum nächsten, sonst Streckenwert aus dem JSON.
			var w_d := -1
			for t in range(s_kind.size()):
				var tid: String = i_ids[s_def[t]] if s_kind[t] == K_INDUSTRIE else s_city_id[t]
				if tid == e["nach_id"]:
					var dd := luftlinie_felder(site, t)
					if w_d < 0 or dd < w_d:
						w_d = dd
			var cand_q := "welt" if w_d >= 0 else "json"
			var cand_d: int = w_d if w_d >= 0 else int(e["strecke_felder"])
			# Welt schlägt JSON; innerhalb derselben Quelle gewinnt die kürzere Distanz
			if best_d < 0 or (cand_q == "welt" and quelle == "json") or (cand_q == quelle and cand_d < best_d):
				best_d = cand_d
				best_ziel = e["nach_id"]
				quelle = cand_q
	if best_d < 0:
		return {"cent": 0, "ziel": "", "felder": 0, "quelle": "keine Kette"}
	return {"cent": yield_cent(g, best_d, PROMILLE, units * PROMILLE), "ziel": best_ziel, "felder": best_d, "quelle": quelle}


## 1-Klick-Angebot für den Button "Lizenz kaufen": Preis, Laufzeit, Ertrag/Monat.
func licence_quote(site: int, with_yield: bool = true) -> Dictionary:
	if site < 0 or site >= s_kind.size() or s_kind[site] != K_INDUSTRIE or s_out_good[site] < 0:
		return {"ok": false, "fehler": "keine_lizenzierbare_industrie"}
	if not company_started:
		return {"ok": false, "fehler": "keine_firma"}
	var cost := _licence_cost(site)
	var gratis := free_licences_left > 0
	var y := _licence_yield_month(site) if with_yield else {"cent": -1, "ziel": "", "felder": -1, "quelle": "nicht berechnet"}
	return {
		"ok": true, "industrie_id": i_ids[s_def[site]], "kosten_cent": cost, "gratis": gratis,
		"zu_zahlen_cent": 0 if gratis else cost, "laufzeit_ticks": lic_duration,
		"ertrag_pro_monat_cent": y["cent"], "ertrag_ziel_id": y["ziel"], "ertrag_distanz_felder": y["felder"],
		"ertrag_distanz_quelle": y["quelle"], "ertrag_annahme_text": "volle Frische, ohne Sättigung, Stufe 1",
		"aktiv": licence_valid(site), "guthaben_cent": cash_cent,
		"kaufbar": not licence_valid(site) and cash_cent >= (0 if gratis else cost),
	}


## 1 Klick = 1 Aufruf. Zahlt nur aus Guthaben (kein Kredit in S4).
func buy_licence(site: int) -> Dictionary:
	var q := licence_quote(site, false)
	if not q["ok"]:
		return q
	if q["aktiv"]:
		return {"ok": false, "fehler": "schon_lizenziert"}
	var pay: int = q["zu_zahlen_cent"]
	if cash_cent < pay:
		return {"ok": false, "fehler": "guthaben_reicht_nicht", "fehlt_cent": pay - cash_cent}
	cash_cent -= pay
	licence_paid_total += pay
	if q["gratis"]:
		free_licences_left -= 1
	s_lic_until[site] = _sim_get().tick_count + lic_duration
	if _next_expiry == -1 or s_lic_until[site] < _next_expiry:
		_next_expiry = s_lic_until[site]
	return {"ok": true, "bezahlt_cent": pay, "gueltig_bis_tick": s_lic_until[site], "guthaben_cent": cash_cent}


func _update_next_expiry() -> void:
	_next_expiry = -1
	for site in range(s_kind.size()):
		if s_lic_until[site] != -1 and (_next_expiry == -1 or s_lic_until[site] < _next_expiry):
			_next_expiry = s_lic_until[site]


func _renew_licences(t: int) -> void:
	if not lic_auto_renew:
		for site in range(s_kind.size()):
			if s_lic_until[site] != -1 and s_lic_until[site] <= t:
				s_lic_until[site] = -1
		_update_next_expiry()
		return
	for site in range(s_kind.size()):
		if s_lic_until[site] != -1 and s_lic_until[site] <= t:
			var cost := _licence_cost(site)
			if cash_cent >= cost:
				cash_cent -= cost
				licence_paid_total += cost
				s_lic_until[site] += lic_duration
			else:
				s_lic_until[site] = -1
	_update_next_expiry()


# =====================================================================================  Tick-Hooks (aus sim_world)

func _push_lot(site: int, lot: Array) -> void:
	var q: Array = s_lots[site]
	if not q.is_empty():
		var last: Array = q[-1]
		if last[0] == lot[0] and last[1] == lot[1] and last[2] == lot[2]:
			last[3] += lot[3]
			return
	q.append(lot)


## Öko-Tick je Standort: Verarbeitung/Verbrauch nur für Standorte mit Eingangsbestand. Jeder Standort hat
## eine feste Phase (Index mod oeko_tick_ticks) und wird alle oeko_tick_ticks Ticks in seiner Phase bearbeitet;
## so verteilt sich die Last gleichmäßig auf die Ticks (wie die Industrie-Schleife in Transport-Tycoon-Spielen,
## D15) statt jeden zehnten Tick zu springen. Kapazität: Restakkumulator in Ticks (acc += Rate × Δt, Deckel
## eine Periode), je Periode also exakt `Rate` Einheiten.
## Rohstoffquellen werden nicht je Tick besucht: ihr Bestand ist die geschlossene Form des Restakkumulators
## (floor(n × Rate × oeko_tick / periode) nach n Öko-Ticks) und wird beim Laden und vor Prüfsumme/Lesesicht
## nachgezogen (_sync_raw). Lizenzverlängerung in Ticks mit t mod oeko_tick_ticks == 0.
func on_tick(sim) -> void:
	var t: int = sim.tick_count
	var phase: int = t % oeko_tick_ticks
	if phase == 0 and company_started and _next_expiry != -1 and t >= _next_expiry:
		_renew_licences(t)
	var list: Array = _buckets[phase]
	if list.is_empty():
		return
	_buckets[phase] = []
	for site in list:
		s_active[site] = 0
		var buf: Dictionary = s_inbuf[site]
		var g := s_out_good[site]
		if g < 0:
			for gi in buf:
				buf[gi] = 0                    # Abnehmer ohne Ausgang verbraucht
			continue
		var cap_max: int = s_rate[site] * periode_ticks
		s_acc[site] = mini(s_acc[site] + s_rate[site] * (t - s_last_n[site]), cap_max)
		s_last_n[site] = t
		var units: int = s_acc[site] / periode_ticks
		for gi in buf:
			units = mini(units, buf[gi])       # ANNAHME 1:1 je Eingangsgut
		if units > 0:
			for gi in buf:
				buf[gi] -= units
			s_acc[site] -= units * periode_ticks
			_push_lot(site, [g, site, -1, units])
			sim.st_stock[s_station[site]] += units
		_activate_if_ready(site)


func _activate_if_ready(site: int) -> void:
	if s_active[site] == 1:
		return
	var buf: Dictionary = s_inbuf[site]
	var ready := not buf.is_empty()
	var any := false
	for gi in buf:
		ready = ready and buf[gi] > 0
		any = any or buf[gi] > 0
	if (s_out_good[site] >= 0 and ready) or (s_out_good[site] < 0 and any):
		s_active[site] = 1
		_buckets[site % oeko_tick_ticks].append(site)


## Rohstoffquelle auf den aktuellen Tick nachziehen.
func _sync_raw(sim, site: int) -> void:
	var n: int = sim.tick_count / oeko_tick_ticks - s_born[site]
	var due: int = n * s_rate[site] * oeko_tick_ticks / periode_ticks - s_made[site]
	if due > 0:
		s_made[site] += due
		_push_lot(site, [s_out_good[site], site, -1, due])
		sim.st_stock[s_station[site]] += due


## Alle Rohstoffquellen nachziehen (vor Prüfsumme und Lesesichten).
func sync_all(sim) -> void:
	for site in range(s_kind.size()):
		if s_raw[site] == 1:
			_sync_raw(sim, site)


## Darf Fahrzeug-Slot i am Lager-Slot k laden?
func load_gate(sim, i: int, k: int) -> int:
	if sim.v_cargo[i] > 0:
		return L_SKIP
	var site: int = _site_of_station.get(k, -1)
	if site == -1:
		return L_LOAD
	if s_kind[site] == K_INDUSTRIE and lic_required and not licence_valid(site):
		return L_WAIT
	if s_raw[site] == 1:
		_sync_raw(sim, site)
	return L_LOAD


## Nach dem Laden (sim hat st_stock schon um cap verringert): Lose mit Stempel aufs Fahrzeug.
func on_load(sim, i: int, k: int, amount: int) -> void:
	var site: int = _site_of_station.get(k, -1)
	if site == -1:
		return
	var vid: int = sim.v_id[i]
	var vl: Array = v_lots.get(vid, [])
	var q: Array = s_lots[site]
	var rest := amount
	while rest > 0 and not q.is_empty():
		var lot: Array = q[0]
		var take: int = mini(rest, lot[3])
		var dep: int = lot[2] if lot[2] >= 0 else sim.tick_count
		vl.append([lot[0], lot[1], dep, take])
		lot[3] -= take
		rest -= take
		if lot[3] == 0:
			q.pop_front()
	assert(rest == 0, "Lagerbestand und Lose auseinander")
	v_lots[vid] = vl


## Entladen am Lager-Slot k. Gibt die Zahl der abgegebenen Einheiten zurück (sim zieht sie von v_cargo ab).
func on_unload(sim, i: int, k: int) -> int:
	var site: int = _site_of_station.get(k, -1)
	var vid: int = sim.v_id[i]
	var vl: Array = v_lots.get(vid, [])
	if site == -1 or vl.is_empty():
		return 0
	var t: int = sim.tick_count
	var per: int = t / periode_ticks
	var given := 0
	var keep: Array = []
	for lot in vl:
		var g: int = lot[0]
		var q: int = lot[3]
		var acc := 0
		match s_kind[site]:
			K_LAGER:
				# B-xx (S5): Bestand über Kapazität (z. B. seed_stock) machte acc negativ -> given < 0 und Lose wuchsen.
				acc = clampi(warehouse_cap - sim.st_stock[k], 0, q)
				if acc > 0:
					if stamp_persists:
						_push_lot(site, [g, lot[1], lot[2], acc])
					else:
						_push_lot(site, [g, site, -1, acc])
					sim.st_stock[k] += acc
					sim.st_delivered[k] += acc
					units_to_warehouse += acc
					_book(site, lot, acc, 0, 0, 0, warehouse_yield * acc)
			K_INDUSTRIE:
				var buf: Dictionary = s_inbuf[site]
				if buf.has(g):
					acc = q
					if s_abn_max[site] >= 0:
						if s_intake_period[site] != per:
							s_intake_period[site] = per
							s_intake[site] = 0
						acc = mini(q, s_abn_max[site] - s_intake[site])
					if acc > 0:
						s_intake[site] += acc
						buf[g] += acc
						_activate_if_ready(site)
						var d := luftlinie_felder(lot[1], site)
						var fz := f_zeit_promille(g, t - lot[2])
						_book(site, lot, acc, d, fz, acc * PROMILLE, yield_cent(g, d, fz, acc * PROMILLE))
			K_STADT:
				if city_accepts(site, g):
					acc = q
					if s_sat_period[site] != per:
						s_sat_period[site] = per
						s_sat[site] = {}
					var sat: Dictionary = s_sat[site]
					var cat: String = g_cat[g]
					var before: int = sat.get(cat, 0)
					var dem := maxi(1, city_demand(site))
					var fs_sum := 0
					for u in range(1, acc + 1):
						fs_sum += f_saett_promille(rdiv((before + u) * PROMILLE, dem))
					sat[cat] = before + acc
					var d := luftlinie_felder(lot[1], site)
					var fz := f_zeit_promille(g, t - lot[2])
					_book(site, lot, acc, d, fz, fs_sum, yield_cent(g, d, fz, fs_sum))
		given += acc
		if acc < q:
			keep.append([g, lot[1], lot[2], q - acc])
	if keep.is_empty():
		v_lots.erase(vid)
	else:
		v_lots[vid] = keep
	return given


func _book(site: int, lot: Array, units: int, d: int, fz: int, fs_sum: int, cent: int) -> void:
	cash_cent += cent
	revenue_total += cent
	s_revenue[site] += cent
	if s_kind[site] != K_LAGER:
		units_paid += units
		yield_events += 1
	if ledger_enabled:
		ledger.append({"tick": _sim_get().tick_count, "ziel": site, "gut": g_ids[lot[0]], "ursprung": lot[1],
			"abfahrt": lot[2], "menge": units, "felder": d, "f_zeit": fz, "f_saett_summe": fs_sum, "cent": cent})


# =====================================================================================  Prüfsumme

func checksum() -> int:
	var h: int = -3750763034362895579
	var prime: int = 1099511628211
	for v in [cash_cent, revenue_total, licence_paid_total, units_paid, units_to_warehouse, free_licences_left]:
		h = (h ^ v) * prime
	for site in range(s_kind.size()):
		h = (h ^ s_acc[site]) * prime
		h = (h ^ s_made[site]) * prime
		h = (h ^ s_lic_until[site]) * prime
		h = (h ^ s_intake[site]) * prime
		for gi in s_inbuf[site]:
			h = (h ^ s_inbuf[site][gi]) * prime
		for lot in s_lots[site]:
			for x in lot:
				h = (h ^ int(x)) * prime
		for cat in s_sat[site]:
			h = (h ^ int(s_sat[site][cat])) * prime
	var vids: Array = v_lots.keys()
	vids.sort()
	for vid in vids:
		h = (h ^ int(vid)) * prime
		for lot in v_lots[vid]:
			for x in lot:
				h = (h ^ int(x)) * prime
	return h
