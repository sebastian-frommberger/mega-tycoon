extends CanvasLayer
## S8 AT-07 (Mira): Welt-Panel der Prototyp-Welt. Klick auf Farm, Mühle oder Ort öffnet rechts ein Panel (W2, AT-14):
## Bestand, Bedarf, Sättigung, Lizenz kaufen, „Linie von hier“, am HQ der Eintrag „Fuhrhalterei“ (ohne Sim-Funktion).
## Alles in Code, kein Modal (D21). Zahlen kommen nur aus proto_sim/economy (Lesesicht, keine Schreibzugriffe außer über
## die Spieler-API von proto_sim.gd). Jede angezeigte Zahl steht zusätzlich in `panel_werte` (Cent bzw. Einheiten), damit
## Tests sie gegen den Spielwert prüfen können.
##
## Einbau: prototyp_welt.gd legt den Knoten nach dem HUD an (`UiWelt.new()`, `einbauen(welt)`), leitet Klicks
## (Loslassen ohne Ziehen) an `welt_klick(pos)` und Esc an `eingabe(ev)` weiter.
## Fehlertexte: vorläufig hier in FT_WELT (Quelle AT-14, Ursache + Lösung, ≤ 90 Zeichen). Ziel ist ui/fehlertexte.gd
## (Aylin, AT-12). Platzhalter benannt: "{name}".format({...}).

const Economy := preload("res://economy.gd")

const PANEL_B := 360.0
const KLICK_RADIUS_PX := 44.0
const TOAST_S := 6.0
const C_TEXT := Color(0.96, 0.92, 0.84)
const C_GRAU := Color(0.62, 0.58, 0.52)
const C_OK := Color("#48E08A")
const C_WARN := Color("#FFA640")
const C_BAD := Color("#FF988A")

## Vorläufige Fehler- und Meldungstexte (AT-14 S1/S3, Wortlaut übernommen). Gehören nach ui/fehlertexte.gd (Aylin).
const FT_WELT := {
	"lizenz_ok": "Lizenz für {name} gekauft, sie gilt {t} min. Jetzt: Linie von hier anlegen.",
	"lizenz_geld_vor12": "Lizenz kostet {x}, es fehlen {d}. Kredit gibt es erst ab Minute 12.",
	"lizenz_geld_ab12": "Lizenz kostet {x}, es fehlen {d}. Nimm Kredit oder warte auf Einnahmen.",
	"lizenz_schon": "{name} ist schon lizenziert, noch {t} min.",
	"lizenz_nicht_noetig": "{name} braucht keine Lizenz. Lege direkt eine Linie dorthin.",
	"lizenz_sonst": "Lizenz gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {code}).",
	"bankrott": "Du bist bankrott, Käufe gehen nicht mehr. Starte neu über das Menü (Esc).",
	"fuhrhalterei": "Unterhalt enthält Futter, Knecht, Stellmacher.",
	"postkutsche": "Postkutschen fahren nur als Kulisse. Passagiere kommen in einer späteren Version.",
}

var welt: Node = null                # prototyp_welt.gd
var ps = null                        # proto_sim.gd
var auswahl := ""                    # Stationsname des offenen Panels, "" = zu
var panel: PanelContainer
var panel_vb: VBoxContainer
var toast_panel: PanelContainer
var toast_label: Label
var toast_rest := 0.0
var meldungen_log: Array = []        # [{t_ms, text}] alle gezeigten Meldungen (Test: nie stumm)
var panel_werte: Dictionary = {}     # zuletzt angezeigte Zahlen (Test gegen Spielwert)
var knoepfe: Dictionary = {}         # Name -> Button im offenen Panel (Tests, play_welt)
var klicks := 0                      # gezählte Spielerklicks (Welt + Knöpfe), Messgröße AT-08
var orte_pos: Dictionary = {}        # Stationsname -> Vector3 (m, Gelände)
var _refresh_t := 0.0


func einbauen(p_welt: Node) -> void:
	welt = p_welt
	ps = welt.proto_sim
	name = "UiWelt"
	layer = 2
	welt.add_child(self)
	_orte_lesen()
	_baue_panel()
	_baue_toast()


func _orte_lesen() -> void:
	orte_pos.clear()
	var oj: Dictionary = welt.orte_json
	for ind in oj.get("industrie", []):
		var nm := String(ind.get("name", ""))
		orte_pos[nm] = Vector3(float(ind["x"]), welt.hoehe_at(float(ind["x"]), float(ind["z"])), float(ind["z"]))
	for o in oj.get("orte", []):
		var nm := String(o.get("name", ""))
		orte_pos[nm] = Vector3(float(o["x"]), welt.hoehe_at(float(o["x"]), float(o["z"])), float(o["z"]))


func _sim_ok() -> bool:
	return ps != null and ps.eco != null


# ------------------------------------------------------------------ Format

## Cent → "6.000 $" (ganze Dollar, Tausenderpunkt). Negative Beträge mit Minus und aufgerundet (nie "0 $" bei Schulden).
static func geld(cent: int) -> String:
	if cent < 0:
		return "-" + _tsd(int(ceil(-cent / 100.0))) + " $"
	return _tsd(roundi(cent / 100.0)) + " $"


## Fehlbetrag: immer aufgerundet, damit nie "es fehlen 0 $" dasteht.
static func fehlbetrag(cent: int) -> String:
	return _tsd(int(ceil(maxi(0, cent) / 100.0))) + " $"


static func _tsd(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


static func text(key: String, werte: Dictionary = {}) -> String:
	return String(FT_WELT.get(key, key)).format(werte)


# ------------------------------------------------------------------ Lesesicht (Spielwerte)

func site_of(nm: String) -> int:
	if not _sim_ok() or not ps.stationen.has(nm):
		return -1
	return int(ps.stationen[nm]["site"])


func ist_industrie(site: int) -> bool:
	return site >= 0 and ps.eco.s_kind[site] == Economy.K_INDUSTRIE


func ist_ort(site: int) -> bool:
	return site >= 0 and ps.eco.s_kind[site] == Economy.K_STADT


func periode() -> int:
	return int(ps.eco.periode_ticks)


## Bestand am Lager-Slot der Site, Rohstoffquellen ohne Schreibzugriff auf den Tick nachgerechnet
## (gleiche Formel wie economy._sync_raw: floor(n × Rate × oeko_tick / periode) − bereits gelegt).
func bestand(site: int) -> int:
	var e = ps.eco
	var k: int = e.s_station[site]
	var st: int = ps.sim.st_stock[k]
	if e.s_raw[site] == 1:
		var n: int = ps.sim.tick_count / e.oeko_tick_ticks - e.s_born[site]
		st += maxi(0, n * e.s_rate[site] * e.oeko_tick_ticks / e.periode_ticks - e.s_made[site])
	return st


## Gut-ID (String) des Ausgangsguts oder "".
func ausgang(site: int) -> String:
	var g: int = ps.eco.s_out_good[site]
	return String(ps.eco.g_ids[g]) if g >= 0 else ""


## Warengruppen (kategorie_id), die der Ort annimmt.
func ort_korb(site: int) -> Array:
	return ps.eco.basket.get(ps.eco.s_stage[site], [])


## Geliefert in der laufenden Periode (Spielminute) je Warengruppe.
func ort_geliefert(site: int, kat: String) -> int:
	var e = ps.eco
	if e.s_sat_period[site] != ps.sim.tick_count / e.periode_ticks:
		return 0
	return int(e.s_sat[site].get(kat, 0))


## Sättigung in Prozent (geliefert ÷ Bedarf der laufenden Minute), ganzzahlig gerundet.
func ort_saettigung_pct(site: int, kat: String) -> int:
	var dem: int = maxi(1, ps.eco.city_demand(site))
	return Economy.rdiv(ort_geliefert(site, kat) * 100, dem)


func lizenz_rest_min(site: int) -> int:
	var rest: int = ps.eco.s_lic_until[site] - ps.sim.tick_count
	return maxi(0, int(ceil(rest / float(periode()))))


func ist_hq(site: int) -> bool:
	var e = ps.eco
	return e.company_started and e.s_x[site] == e.hq_x and e.s_y[site] == e.hq_y


## Mögliche Abnehmer des Ausgangsguts: [{name, site, felder, m}] nach Entfernung.
func abnehmer(site: int) -> Array:
	var g: int = ps.eco.s_out_good[site]
	var out: Array = []
	if g < 0:
		return out
	for nm in ps.stationen:
		var t := int(ps.stationen[nm]["site"])
		if t < 0 or t == site or not nimmt_an(t, g):
			continue
		var f: int = ps.eco.luftlinie_felder(site, t)
		out.append({"name": nm, "site": t, "felder": f, "m": roundi(f * ps.eco.feld_mm / ps.mm_pro_m)})
	out.sort_custom(func(a, b): return a["felder"] < b["felder"])
	return out


func nimmt_an(site: int, g: int) -> bool:
	if ist_industrie(site):
		return ps.eco.s_inbuf[site].has(g)
	if ist_ort(site):
		return ps.eco.city_accepts(site, g)
	return false


func fuhrwerk_def() -> Dictionary:
	return ps.vdef(ps.def_fuer("fuhrwerk"))


# ------------------------------------------------------------------ Aufbau

func _stil(bg: Color, rand := 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_content_margin_all(rand)
	sb.set_corner_radius_all(4)
	return sb


func _baue_panel() -> void:
	panel = PanelContainer.new()
	panel.name = "WeltPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP           # Klicks im Panel gehen nicht in die Welt
	panel.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.88), 12))
	panel.custom_minimum_size = Vector2(PANEL_B, 0)
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -PANEL_B - 12.0
	panel.offset_right = -12.0
	panel.offset_top = 72.0
	panel.visible = false
	add_child(panel)
	panel_vb = VBoxContainer.new()
	panel_vb.add_theme_constant_override("separation", 6)
	panel.add_child(panel_vb)


func _baue_toast() -> void:
	toast_panel = PanelContainer.new()
	toast_panel.name = "Toast"
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_panel.add_theme_stylebox_override("panel", _stil(Color(0.08, 0.07, 0.06, 0.9), 10))
	toast_panel.anchor_left = 1.0
	toast_panel.anchor_right = 1.0
	toast_panel.anchor_top = 1.0
	toast_panel.anchor_bottom = 1.0
	toast_panel.offset_left = -PANEL_B - 12.0
	toast_panel.offset_right = -12.0
	toast_panel.offset_top = -96.0
	toast_panel.offset_bottom = -12.0
	toast_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_panel.visible = false
	add_child(toast_panel)
	toast_label = _label("", 16)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_panel.add_child(toast_label)


func _label(t: String, gr := 16, farbe := C_TEXT) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", gr)
	l.add_theme_color_override("font_color", farbe)
	return l


func _knopf(t: String, id: String, f: Callable, primaer := false, grau := false) -> Button:
	var b := Button.new()
	b.text = t
	b.name = id
	b.focus_mode = Control.FOCUS_NONE                      # Leertaste bleibt Pause
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 16)
	if primaer:
		b.add_theme_stylebox_override("normal", _stil(Color(0.24, 0.42, 0.3), 6))
		b.add_theme_stylebox_override("hover", _stil(Color(0.3, 0.5, 0.36), 6))
	if grau:                                                # G3: grau, aber klickbar – der Klick erklärt den Grund (nie stumm)
		b.add_theme_color_override("font_color", C_GRAU)
		b.add_theme_color_override("font_hover_color", C_GRAU)
	b.pressed.connect(func():
		klicks += 1
		f.call())
	knoepfe[id] = b
	return b


# ------------------------------------------------------------------ Meldungen

func meldung(t: String) -> void:
	toast_label.text = t
	toast_panel.visible = true
	toast_rest = TOAST_S
	meldungen_log.append({"t_ms": Time.get_ticks_msec(), "text": t})


func _process(delta: float) -> void:
	if toast_rest > 0.0:
		toast_rest -= delta
		if toast_rest <= 0.0:
			toast_panel.visible = false
	if _sim_ok():
		while not ps.meldungen.is_empty():                 # Sim-Meldungen (Freischaltung, Bankrott) als Toast
			meldung(String(ps.meldungen.pop_front()))
	_refresh_t += delta
	if _refresh_t >= 0.25:
		_refresh_t = 0.0
		if auswahl != "":
			panel_neu()


# ------------------------------------------------------------------ Eingabe

## Weltklick (Bildschirmposition). Gibt true zurück, wenn ein Ort getroffen wurde (oder ein Modus den Klick braucht).
func welt_klick(pos: Vector2) -> bool:
	var nm := ort_unter(pos)
	if nm == "":
		return false
	klicks += 1
	oeffnen(nm)
	return true


## Nächster Stationsort im Radius KLICK_RADIUS_PX um pos (Projektion der Ortsmitte), "" = keiner.
func ort_unter(pos: Vector2) -> String:
	var cam: Camera3D = welt.cam
	var best := ""
	var best_d := KLICK_RADIUS_PX
	for nm in orte_pos:
		if not ps.stationen.has(nm):
			continue
		var p: Vector3 = orte_pos[nm]
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(pos)
		if d <= best_d:
			best_d = d
			best = nm
	return best


func bildschirm_pos(nm: String) -> Vector2:
	return welt.cam.unproject_position(orte_pos[nm])


## Esc und andere Tasten. true = verbraucht (G5: Esc schließt zuerst das Panel, erst dann kommt das Menü).
func eingabe(ev: InputEvent) -> bool:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if auswahl != "":
			schliessen()
			return true
	return false


# ------------------------------------------------------------------ Panel

func oeffnen(nm: String) -> void:
	auswahl = nm
	panel_neu()
	panel.visible = true


func schliessen() -> void:
	auswahl = ""
	panel.visible = false
	knoepfe.clear()


func panel_neu() -> void:
	for c in panel_vb.get_children():
		panel_vb.remove_child(c)
		c.queue_free()
	knoepfe.clear()
	panel_werte = {"name": auswahl}
	var site := site_of(auswahl)
	if site < 0:
		panel_vb.add_child(_label(auswahl, 18))
		panel_vb.add_child(_label("Kein Handelsort.", 16, C_GRAU))
		return
	var e = ps.eco
	var kopf := HBoxContainer.new()
	var titel := _label(auswahl, 18)
	titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(titel)
	var typ := "Ort"
	if ist_industrie(site):
		typ = {"getreidefarm": "Getreidefarm", "muehle": "Mühle"}.get(String(e.i_ids[e.s_def[site]]), String(e.i_ids[e.s_def[site]]))
	elif ist_ort(site):
		typ = {"dorf": "Dorf", "kleinstadt": "Kleinstadt"}.get(String(e.s_stage[site]), String(e.s_stage[site]))
	kopf.add_child(_label(typ, 16, C_GRAU))
	kopf.add_child(_knopf("x", "schliessen", schliessen))
	panel_vb.add_child(kopf)
	if ist_industrie(site):
		_panel_industrie(site)
	elif ist_ort(site):
		_panel_ort(site)
	if ist_hq(site):
		_panel_hq()


func _trenner() -> void:
	panel_vb.add_child(HSeparator.new())


func _panel_industrie(site: int) -> void:
	var e = ps.eco
	var gut := ausgang(site)
	var b := bestand(site)
	panel_werte["bestand"] = b
	panel_werte["rate"] = int(e.s_rate[site])
	var roh: bool = e.s_raw[site] == 1
	var zeile := "Bestand %d E %s · %s %d E/min" % [b, gut.capitalize(), "liefert" if roh else "verarbeitet bis", e.s_rate[site]]
	panel_vb.add_child(_label(zeile, 16))
	for gi in e.s_inbuf[site]:                              # Verarbeiter: Eingangslager (Bedarf = Durchsatz)
		var n: int = e.s_inbuf[site][gi]
		panel_werte["eingang_" + String(e.g_ids[gi])] = n
		panel_werte["bedarf"] = int(e.s_rate[site])
		panel_vb.add_child(_label("Eingang %s %d E · Bedarf %d E/min" % [String(e.g_ids[gi]).capitalize(), n, e.s_rate[site]], 16))
	_trenner()
	_lizenz_zeile(site)
	var ab := abnehmer(site)
	if not ab.is_empty():
		_trenner()
		panel_vb.add_child(_label("Abnehmer in Reichweite:", 16, C_GRAU))
		var liste: Array = []
		for a in ab:
			var form := "●"
			var zus := ""
			if ist_ort(int(a["site"])):
				var kat: String = e.g_cat[e.s_out_good[site]]
				var p := ort_saettigung_pct(int(a["site"]), kat)
				form = "■" if p >= 150 else ("▲" if p >= 100 else "●")
				zus = " %d %%" % p
			panel_vb.add_child(_label("  %s  %d Felder (%d m)  %s%s" % [a["name"], a["felder"], a["m"], form, zus], 16))
			liste.append(a["name"])
		panel_werte["abnehmer"] = liste
	panel_vb.add_child(_knopf("Linie von hier", "linie_von_hier", linie_von_hier.bind(auswahl), e.licence_valid(site)))


func _lizenz_zeile(site: int) -> void:
	var e = ps.eco
	var q: Dictionary = e.licence_quote(site, false)
	var hb := HBoxContainer.new()
	var lt := ""
	if e.licence_valid(site):
		var t := lizenz_rest_min(site)
		panel_werte["lizenz_rest_min"] = t
		lt = "%s Lizenz: gilt noch %d min" % ["▲" if t < 3 else "●", t]
	else:
		lt = "Lizenz: keine"
	var l := _label(lt, 16)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(l)
	if q.get("ok", false) and not e.licence_valid(site):
		var preis: int = q["zu_zahlen_cent"]
		panel_werte["lizenz_preis"] = preis
		var b := _knopf("Lizenz kaufen %s" % geld(preis), "lizenz_kaufen", lizenz_kaufen.bind(auswahl), false, preis > e.cash_cent)
		if preis > e.cash_cent:
			b.tooltip_text = "Es fehlen %s." % fehlbetrag(preis - e.cash_cent)
		hb.add_child(b)
	panel_vb.add_child(hb)


func _panel_ort(site: int) -> void:
	var e = ps.eco
	var ew := int(e.c_index[e.s_city_id[site]].get("einwohner_anzahl", 0))
	var dem: int = e.city_demand(site)
	panel_werte["einwohner"] = ew
	panel_werte["bedarf"] = dem
	panel_vb.add_child(_label("Einwohner %s · Bedarf %d E/min je Warengruppe" % [_tsd(ew), dem], 16))
	var korb := ort_korb(site)
	var gueter: Array = []
	for g in e.g_ids.size():
		if String(e.g_cat[g]) in korb:
			gueter.append(String(e.g_ids[g]).capitalize())
	panel_werte["korb"] = korb
	panel_vb.add_child(_label("Nimmt an: %s" % (", ".join(PackedStringArray(gueter)) if not gueter.is_empty() else "nichts"), 16))
	for kat in korb:
		var p := ort_saettigung_pct(site, kat)
		var n := ort_geliefert(site, kat)
		panel_werte["saettigung_" + String(kat)] = p
		panel_werte["geliefert_" + String(kat)] = n
		var form := "■" if p >= 150 else ("▲" if p >= 100 else "●")
		var l := _label("%s Sättigung %s: %d %% (%d von %d E diese Minute)" % [form, String(kat).capitalize(), p, n, dem], 16,
			C_BAD if p >= 150 else (C_WARN if p >= 100 else C_TEXT))
		panel_vb.add_child(l)
	panel_vb.add_child(_label("Lizenz: nicht nötig", 16, C_GRAU))


## Fuhrhalterei am HQ: nur Panel-Eintrag (AT-14 S3), keine Sim-Funktion. Preis und Unterhalt aus vehicles.json.
func _panel_hq() -> void:
	var d := fuhrwerk_def()
	_trenner()
	panel_vb.add_child(_label("Firmensitz (HQ) · Fuhrhalterei", 18))
	panel_werte["fuhrwerk_preis"] = int(d.get("kauf_cent", 0))
	panel_werte["fuhrwerk_fix"] = int(d.get("fix_cent_pro_periode", 0))
	panel_vb.add_child(_label("Fuhrwerk %s · Unterhalt %s/min · %d E Ladung" % [geld(int(d.get("kauf_cent", 0))),
		geld(int(d.get("fix_cent_pro_periode", 0))), int(d.get("kapazitaet_einheiten", 0))], 16))
	var l := _label(text("fuhrhalterei"), 16, C_GRAU)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vb.add_child(l)
	var l2 := _label(text("postkutsche"), 14, C_GRAU)
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_vb.add_child(l2)


# ------------------------------------------------------------------ Aktionen

## Lizenz kaufen über proto_sim.lizenz_kaufen. Jede Ablehnung mit Text (AT-14 F1.x).
func lizenz_kaufen(nm: String) -> Dictionary:
	var site := site_of(nm)
	var r: Dictionary
	if site < 0:
		r = {"ok": false, "fehler": "unbekannter_ort"}
	elif ist_ort(site):
		meldung(text("lizenz_nicht_noetig", {"name": nm}))
		return {"ok": false, "fehler": "nicht_noetig"}
	else:
		r = ps.lizenz_kaufen(nm)
	if r.get("ok", false):
		meldung(text("lizenz_ok", {"name": nm, "t": lizenz_rest_min(site)}))
	else:
		meldung(lizenz_fehlertext(nm, r))
	if auswahl != "":
		panel_neu()
	return r


func lizenz_fehlertext(nm: String, r: Dictionary) -> String:
	var f := String(r.get("fehler", "?"))
	var site := site_of(nm)
	match f:
		"guthaben_reicht_nicht":
			var q: Dictionary = ps.eco.licence_quote(site, false)
			var w := {"x": geld(int(q.get("zu_zahlen_cent", 0))), "d": fehlbetrag(int(r.get("fehlt_cent", 0)))}
			return text("lizenz_geld_ab12" if ps.sim.tick_count >= int(ps.credit.from_ticks) else "lizenz_geld_vor12", w)
		"schon_lizenziert":
			return text("lizenz_schon", {"name": nm, "t": lizenz_rest_min(site)})
		"bankrott":
			return text("bankrott")
		"keine_lizenzierbare_industrie":
			return text("lizenz_nicht_noetig", {"name": nm})
	return text("lizenz_sonst", {"code": f})


## AT-08 setzt hier an (Modus „Linie von hier“). AT-07: Knopf vorhanden, Aktion meldet sich.
func linie_von_hier(nm: String) -> void:
	meldung("Linie von %s: kommt mit AT-08." % nm)
