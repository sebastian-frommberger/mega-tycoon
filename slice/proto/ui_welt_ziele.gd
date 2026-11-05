extends RefCounted
## S8 AT-13 (Mira): Ziele E-1…E-6, F1, F2 der Welt aus data/ziele_welt.json (OE-01), Szenario (i): Textliste + „Nächster Schritt“.
## Prüft die Messgrößen aus der JSON gegen proto_sim/economy (Lesesicht) und die Linienstatistik (AT-10). Erfüllt bleibt erfüllt.
## Aufruf: pruefen(periode_ende) aus ui_welt (alle 10 Ticks, an Periodenenden mit Minutenwerten).

const JSON_PFAD := "res://data/ziele_welt.json"

var ps = null
var statistik = null
var ziele: Array = []                # [{id, name, skillpunkte, erfuellt_tick}] in JSON-Reihenfolge
var _e6_serie := 0
var _f2_serie := 0
var f2_schwelle := 60000
var neu_erfuellt: Array = []         # IDs, die beim letzten pruefen() erfüllt wurden (Toast)


func _init(p_ps, p_statistik) -> void:
	ps = p_ps
	statistik = p_statistik
	var d = JSON.parse_string(FileAccess.get_file_as_string(JSON_PFAD)) if FileAccess.file_exists(JSON_PFAD) else null
	if not d is Dictionary:
		return
	for z in d.get("ziele", []):
		ziele.append({"id": String(z["id"]), "name": anzeige(String(z.get("name_text", z["id"]))),
			"skillpunkte": int(z.get("skillpunkte", 0)), "erfuellt_tick": -1})
		if String(z["id"]) == "f2":
			f2_schwelle = int(z.get("messgroesse", {}).get("schwelle", f2_schwelle))


## ASCII-Umschrift der JSON für die Anzeige (Muehle → Mühle, -> → →).
static func anzeige(t: String) -> String:
	for paar in [["->", "→"], ["Muehle", "Mühle"], ["traegt", "trägt"], ["faehig", "fähig"], ["Getreidelieferung", "Getreidelieferung"]]:
		t = t.replace(paar[0], paar[1])
	return t


static func kurz(id: String) -> String:
	return id.to_upper().insert(1, "-") if id.begins_with("e") else id.to_upper()


func ziel(id: String) -> Dictionary:
	for z in ziele:
		if z["id"] == id:
			return z
	return {}


func erfuellt(id: String) -> bool:
	return int(ziel(id).get("erfuellt_tick", -1)) >= 0


func skillpunkte() -> int:
	var n := 0
	for z in ziele:
		if int(z["erfuellt_tick"]) >= 0:
			n += int(z["skillpunkte"])
	return n


func _knoten(nm: String) -> int:
	return int(ps.stationen[nm]["knoten"]) if ps.stationen.has(nm) else -1


func _farm_knoten() -> Array:
	var out: Array = []
	for nm in ps.stationen:
		var s := int(ps.stationen[nm]["site"])
		if s >= 0 and ps.eco.s_kind[s] == 0 and String(ps.eco.i_ids[ps.eco.s_def[s]]) == "getreidefarm":
			out.append(int(ps.stationen[nm]["knoten"]))
	return out


func _geliefert_nach(knoten: int, gut: String) -> int:
	var nach := {}
	for f in ps.fahrzeuge:
		nach[int(f["vid"])] = int(f["nach"])
	var g_idx: int = ps.eco.g_index.get(gut, -1)
	var n := 0
	for l in ps.lieferungen:
		if int(nach.get(int(l["vid"]), -1)) != knoten:
			continue
		var lg = l.get("gut", "")
		if String(lg) == "" or String(lg) == gut or (lg is int and int(lg) == g_idx):
			n += int(l["menge"])
	return n


## Gibt die Bedingungen je Ziel zurück (ohne Festhalten); pruefen() hält die erste Erfüllung fest.
func _bedingungen(periode_ende: bool, netto: Variant) -> Dictionary:
	var e = ps.eco
	var b := {}
	var farms := _farm_knoten()
	var lizenz := false
	for nm in ps.stationen:
		var s := int(ps.stationen[nm]["site"])
		if s >= 0 and int(ps.stationen[nm]["knoten"]) in farms and (e.licence_valid(s) or int(e.s_owner[s]) == 1):
			lizenz = true
	b["e1"] = lizenz
	var muehle := _knoten("Erlenmühle")
	var gruppen := {}
	var e2 := false
	for f in ps.fahrzeuge:
		if f["verkauft"] or int(f.get("kauf_cent", 0)) <= 0:
			continue
		if int(f["von"]) in farms and int(f["nach"]) == muehle:
			e2 = true
		var k := "%d|%d" % [int(f["von"]), int(f["nach"])]
		gruppen[k] = int(gruppen.get(k, 0)) + 1
	b["e2"] = e2
	b["e3"] = _geliefert_nach(muehle, "getreide") >= 1
	b["e4"] = _geliefert_nach(_knoten("Erlenbach"), "mehl") >= 10
	var maxg := 0
	for k in gruppen:
		maxg = maxi(maxg, int(gruppen[k]))
	b["e5"] = maxg >= 2
	if periode_ende:
		var alle_ok: bool = not statistik.linien.is_empty()
		var eine_plus := false
		for k in statistik.linien:
			var g := int(statistik.linien[k]["gewinn"])
			alle_ok = alle_ok and g >= 0
			eine_plus = eine_plus or g > 0
		_e6_serie = _e6_serie + 1 if alle_ok and eine_plus else 0
		if netto != null and int(netto) >= f2_schwelle and int(ps.credit.loan_cent) == 0:
			_f2_serie += 1
		else:
			_f2_serie = 0
	b["e6"] = _e6_serie >= 3
	var f1 := true
	for nm in ["Erlenbach", "Lindenfurt"]:
		var s: int = int(ps.stationen[nm]["site"]) if ps.stationen.has(nm) else -1
		var v: Array = statistik.ort_v.get(s, [])
		if v.size() < 3:
			f1 = false
			continue
		var summe := 0
		for x in v.slice(v.size() - 3):
			summe += int(x)
		f1 = f1 and summe / 3 >= 500
	b["f1"] = f1
	b["f2"] = _f2_serie >= 5
	return b


func pruefen(periode_ende: bool, netto: Variant = null) -> void:
	neu_erfuellt = []
	var b := _bedingungen(periode_ende, netto)
	for z in ziele:
		if int(z["erfuellt_tick"]) < 0 and bool(b.get(z["id"], false)):
			z["erfuellt_tick"] = ps.sim.tick_count
			neu_erfuellt.append(z["id"])


## Erstes offenes Ziel (JSON-Reihenfolge) oder {}.
func naechstes() -> Dictionary:
	for z in ziele:
		if int(z["erfuellt_tick"]) < 0:
			return z
	return {}
