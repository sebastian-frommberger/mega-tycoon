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
	# AT-08 (AT-14 S2/S3)
	"modus": "Linie von {name}: klicke das Ziel. Esc bricht ab.",
	"linie_ok": "Linie {a} → {b} läuft. Fuhrwerk {n} ist unterwegs.",
	"fuhrwerk_ok": "Fuhrwerk {n} gekauft: −{p}, Unterhalt +{u}/min. Linie bringt jetzt ca. {z}/min.",
	"keine_verbindung": "Zwischen {a} und {b} gibt es keine Straße. Wähle ein Ziel am bestehenden Netz.",
	"liefert_nichts": "{name} liefert nichts. Starte die Linie bei Farm, Mühle oder Lager.",
	"keine_lizenz": "{name} hat keine Lizenz. Kaufe sie im Panel (Klick auf das Gebäude).",
	"nimmt_nicht": "{ziel} nimmt {ware} nicht an. Wähle einen Abnehmer, der sie braucht.",
	"fuhrwerk_geld": "Fuhrwerk kostet {x}, es fehlen {d}. Nimm Kredit oder warte auf Einnahmen.",
	# AT-09 (AT-14 S4)
	"kredit_ab12": "Kredit gibt es ab Minute 12. Bis dahin: Einnahmen abwarten.",
	"kredit_voll": "Kreditrahmen {x} ist voll. Tilge Schulden oder warte auf Einnahmen.",
	"kredit_ok": "Kredit {x} aufgenommen. Zins {z}/min, Rahmen noch {r}.",
	"tilgen_geld": "Zum Tilgen fehlen {x} in der Kasse. Warte auf Einnahmen.",
	"tilgen_ok": "Kredit {x} getilgt, offen noch {r}.",
	"kein_kredit": "Du hast keinen Kredit offen. Tilgen ist nicht nötig.",
	"liefert_wenig": "{name} liefert nur {x} E/min. Ein weiteres Fuhrwerk bringt kaum mehr.",
	"gibt_es_schon": "Diese Linie gibt es schon. Füge ihr ein Fuhrwerk hinzu (+ Fuhrwerk).",
	"ins_leere": "Klicke ein Gebäude an: erst die Quelle, dann das Ziel.",
	"gleich": "Start und Ziel sind gleich. Wähle ein anderes Ziel.",
	"frachtwagen_1830": "Frachtwagen gibt es erst ab 1830. Bis dahin kaufst du das Fuhrwerk.",
	"linie_sonst": "Linie gerade nicht möglich. Bitte erneut klicken (Meldung an uns: {code}).",
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
var _taste_unten := false            # linke Maustaste gehalten (Neuaufbau des Panels würde den Klick verschlucken)
var _bereiche: Dictionary = {}       # "panel" | "vorschau" | "modus" -> Knopf-IDs
# AT-08: Linienbau
var modus_von := ""                  # Quelle im Modus „Linie von hier“, "" = kein Modus
var vorschau_ziel := ""              # Ziel der offenen Vorschau, "" = keine
var vorschau_werte: Dictionary = {}  # Zahlen der Vorschau (Test gegen Spielwert)
var modus_panel: PanelContainer
var modus_hb: HBoxContainer
var vorschau_panel: PanelContainer
var vorschau_vb: VBoxContainer
# AT-09: Kopfleiste
var kopf: PanelContainer
var kopf_hb: HBoxContainer
var lbl_kasse: Label
var lbl_netto: Label
var lbl_fix: Label
var lbl_kredit: Label
var lbl_k: Label
var hud_werte: Dictionary = {}       # angezeigte HUD-Zahlen (Test gegen Spielwert)
var _schnapp: Array = []             # Schnappschüsse an den letzten zwei Periodengrenzen


func einbauen(p_welt: Node) -> void:
	welt = p_welt
	ps = welt.proto_sim
	name = "UiWelt"
	layer = 2
	welt.add_child(self)
	_orte_lesen()
	_baue_panel()
	_baue_toast()
	_baue_linienbau()
	_baue_kopfleiste()


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


func _knopf(t: String, id: String, f: Callable, primaer := false, grau := false, bereich := "panel") -> Button:
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
	if not _bereiche.has(bereich):
		_bereiche[bereich] = []
	_bereiche[bereich].append(id)
	return b


func _bereich_leeren(bereich: String) -> void:
	for id in _bereiche.get(bereich, []):
		knoepfe.erase(id)
	_bereiche[bereich] = []


# ------------------------------------------------------------------ Meldungen

func meldung(t: String, dauer := TOAST_S) -> void:
	toast_label.text = t
	toast_panel.visible = true
	toast_rest = dauer
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
		if auswahl != "" and not _taste_unten:          # BUG-1-Muster: kein Neuaufbau, solange die linke Taste gehalten wird
			panel_neu()
		kopf_neu()


# ------------------------------------------------------------------ Eingabe

func _input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_taste_unten = (ev as InputEventMouseButton).pressed


## Weltklick (Bildschirmposition). Gibt true zurück, wenn ein Ort getroffen wurde (oder ein Modus den Klick braucht).
func welt_klick(pos: Vector2) -> bool:
	var nm := ort_unter(pos)
	if modus_von != "":
		klicks += 1
		if nm == "":
			meldung(text("ins_leere"), 2.0)
		else:
			ziel_waehlen(nm)
		return true
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
		if modus_von != "" or vorschau_ziel != "":       # AT-14 S2: Esc bricht in jeder Stufe ohne Text ab
			modus_ende()
			return true
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
	_bereich_leeren("panel")


func panel_neu() -> void:
	for c in panel_vb.get_children():
		panel_vb.remove_child(c)
		c.queue_free()
	_bereich_leeren("panel")
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
	_linien_ab(auswahl)


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
	var l2 := _label(text("postkutsche"), 15, C_GRAU)
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




# ------------------------------------------------------------------ AT-08 Linienbau

func _baue_linienbau() -> void:
	modus_panel = PanelContainer.new()
	modus_panel.name = "LinienModus"
	modus_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	modus_panel.add_theme_stylebox_override("panel", _stil(Color(0.12, 0.2, 0.14, 0.9), 8))
	modus_panel.anchor_left = 0.5                         # unten Mitte: oben liegt das Prototyp-HUD (H blendet es aus)
	modus_panel.anchor_right = 0.5
	modus_panel.anchor_top = 1.0
	modus_panel.anchor_bottom = 1.0
	modus_panel.offset_bottom = -16.0
	modus_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	modus_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	modus_panel.visible = false
	add_child(modus_panel)
	modus_hb = HBoxContainer.new()
	modus_hb.add_theme_constant_override("separation", 10)
	modus_panel.add_child(modus_hb)
	vorschau_panel = PanelContainer.new()
	vorschau_panel.name = "Linienvorschau"
	vorschau_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	vorschau_panel.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.92), 12))
	vorschau_panel.anchor_left = 0.5
	vorschau_panel.anchor_right = 0.5
	vorschau_panel.anchor_top = 1.0
	vorschau_panel.anchor_bottom = 1.0
	vorschau_panel.offset_bottom = -72.0                   # über der Modusleiste
	vorschau_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vorschau_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	vorschau_panel.visible = false
	add_child(vorschau_panel)
	vorschau_vb = VBoxContainer.new()
	vorschau_vb.add_theme_constant_override("separation", 4)
	vorschau_panel.add_child(vorschau_vb)


func _leeren(c: Node) -> void:
	for k in c.get_children():
		c.remove_child(k)
		k.queue_free()


## Modus „Linie von hier“ (S2a). Ohne Lizenz zeigt die Modusleiste den Grund und den Kauf (ein Klick, Modus bleibt).
func linie_von_hier(nm: String) -> void:
	var site := site_of(nm)
	if site < 0 or ausgang(site) == "":
		meldung(text("liefert_nichts", {"name": nm}))
		return
	modus_von = nm
	vorschau_ziel = ""
	vorschau_panel.visible = false
	_bereich_leeren("vorschau")
	modus_neu()


func modus_neu() -> void:
	_leeren(modus_hb)
	_bereich_leeren("modus")
	if modus_von == "":
		modus_panel.visible = false
		return
	modus_hb.add_child(_label(text("modus", {"name": modus_von}), 16))
	var site := site_of(modus_von)
	if not ps.eco.licence_valid(site):
		modus_hb.add_child(_label("Keine Lizenz.", 16, C_WARN))
		var q: Dictionary = ps.eco.licence_quote(site, false)
		var preis: int = int(q.get("zu_zahlen_cent", 0))
		var b := _knopf("Lizenz kaufen %s" % geld(preis), "modus_lizenz", func():
			lizenz_kaufen(modus_von)
			modus_neu(), false, preis > ps.eco.cash_cent, "modus")
		modus_hb.add_child(b)
	modus_hb.add_child(_knopf("Abbrechen · Esc", "modus_abbrechen", modus_ende, false, false, "modus"))
	modus_panel.visible = true


func modus_ende() -> void:
	modus_von = ""
	vorschau_ziel = ""
	vorschau_werte = {}
	vorschau_panel.visible = false
	_bereich_leeren("vorschau")
	modus_neu()


## Fahrzeuge (nicht verkauft) der Linie von → nach.
func linien_fahrzeuge(von: String, nach: String) -> Array:
	var a: int = int(ps.stationen[von]["knoten"])
	var b: int = int(ps.stationen[nach]["knoten"])
	return ps.fahrzeuge.filter(func(f): return int(f["von"]) == a and int(f["nach"]) == b and not f["verkauft"] and f["kauf_cent"] > 0)


## Ziel im Modus angeklickt (S2b). Prüfreihenfolge: gleich → Verbindung → Annahme → Lizenz → Vorschau.
func ziel_waehlen(nm: String) -> void:
	var von := modus_von
	if nm == von:
		meldung(text("gleich"))
		return
	var sv := site_of(von)
	var sz := site_of(nm)
	var g: int = ps.eco.s_out_good[sv]
	var v := route_vorschau(von, nm, 1)
	if not v["ok"]:
		meldung(text("keine_verbindung", {"a": von, "b": nm}))
		return
	if not nimmt_an(sz, g):
		meldung(text("nimmt_nicht", {"ziel": nm, "ware": String(ps.eco.g_ids[g]).capitalize()}))
		return
	if not ps.eco.licence_valid(sv):
		meldung(text("keine_lizenz", {"name": von}))
		oeffnen(von)
		return
	var n_alt := linien_fahrzeuge(von, nm).size()
	if n_alt > 0:
		meldung(text("gibt_es_schon"))
	vorschau_ziel = nm
	vorschau_zeigen(von, nm, n_alt)


## Routenvorschau (W3): Strecke, Fahrzeit, Ertrag je Fuhre, Netto/min (Schätzung), Preis, Unterhalt.
## n = Zahl der Fuhrwerke auf der Linie nach dem Kauf. Schätzung: volle Frische, ohne Sättigung, Fahrzeit ohne Easing;
## Fuhren je Minute höchstens Liefermenge der Quelle ÷ Ladung.
func route_vorschau(von: String, nach: String, n: int) -> Dictionary:
	var a: Dictionary = ps.stationen[von]
	var b: Dictionary = ps.stationen[nach]
	var route: Array = ps.sim.graph.find_path(int(a["knoten"]), int(b["knoten"]))
	if route.is_empty():
		return {"ok": false, "fehler": "keine_verbindung"}
	var e = ps.eco
	var d := fuhrwerk_def()
	var sv := int(a["site"])
	var sz := int(b["site"])
	var g: int = e.s_out_good[sv]
	var cap := int(d.get("kapazitaet_einheiten", 10))
	var route_mm: int = ps.sim.graph.route_length(route)
	var strecke_m: float = route_mm / ps.mm_pro_m
	var v_nom: float = maxf(0.001, ps.profil("fuhrwerk").v_nom)
	var fahr_ticks: float = strecke_m / v_nom
	var load_ticks := int(e.slice.get("fahrzeug_ref", {}).get("load_ticks", 100))
	var umlauf: float = 2.0 * fahr_ticks + 2.0 * load_ticks
	var felder: int = e.luftlinie_felder(sv, sz)
	var ertrag: int = e.yield_cent(g, felder, Economy.PROMILLE, cap * Economy.PROMILLE) if g >= 0 else 0
	var fahrk: int = int(round(2.0 * route_mm / float(e.feld_mm))) * int(d.get("variabel_cent_pro_feld", 0))
	var fuhren_fz: float = n * float(e.periode_ticks) / umlauf
	var fuhren: float = minf(fuhren_fz, float(e.s_rate[sv]) / cap)
	var fix := int(d.get("fix_cent_pro_periode", 0))
	return {"ok": true, "strecke_m": roundi(strecke_m), "fahrzeit_s": roundi(fahr_ticks / 10.0), "felder": felder,
		"ertrag_fuhre_cent": ertrag, "fahrkosten_fuhre_cent": fahrk, "fuhren_min": fuhren,
		"netto_min_cent": roundi(fuhren * (ertrag - fahrk)) - n * fix, "preis_cent": int(d.get("kauf_cent", 0)), "fix_cent": fix,
		"gut": String(e.g_ids[g]) if g >= 0 else "", "quelle_begrenzt": fuhren_fz > fuhren and n > 1, "quelle_rate": int(e.s_rate[sv])}


func vorschau_zeigen(von: String, nach: String, n_alt: int) -> void:
	_leeren(vorschau_vb)
	_bereich_leeren("vorschau")
	var v := route_vorschau(von, nach, n_alt + 1)
	vorschau_werte = v.duplicate()
	vorschau_werte["von"] = von
	vorschau_werte["nach"] = nach
	vorschau_vb.add_child(_label("Linie: %s → %s (%s)%s" % [von, nach, String(v["gut"]).capitalize(),
		(" · %d Fuhrwerk(e) fahren schon" % n_alt) if n_alt > 0 else ""], 18))
	vorschau_vb.add_child(_label("Strecke %s m · Fahrzeit ~%d s · Ertrag je Fuhre %s · ca. %s%s/min" % [_tsd(v["strecke_m"]), v["fahrzeit_s"],
		geld(v["ertrag_fuhre_cent"]), "+" if v["netto_min_cent"] >= 0 else "", geld(v["netto_min_cent"])], 16))
	vorschau_vb.add_child(_label("Fuhrwerk: %s einmalig · Unterhalt %s/min · Fahrkosten %s je Fuhre" % [geld(v["preis_cent"]),
		geld(v["fix_cent"]), geld(v["fahrkosten_fuhre_cent"])], 16))
	if v["quelle_begrenzt"]:                                # F3.2: Hinweis, Kauf bleibt möglich
		vorschau_vb.add_child(_label("▲ " + text("liefert_wenig", {"name": von, "x": v["quelle_rate"]}), 16, C_WARN))
	vorschau_vb.add_child(_label("Schätzung: volle Frische, ohne Sättigung des Abnehmers.", 15, C_GRAU))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var grau: bool = v["preis_cent"] > ps.eco.cash_cent
	var t := ("+ Fuhrwerk · %s" if n_alt > 0 else "Anlegen · %s") % geld(v["preis_cent"])
	var b := _knopf(t, "anlegen", anlegen, not grau, grau, "vorschau")
	if grau:
		b.tooltip_text = "Es fehlen %s." % fehlbetrag(v["preis_cent"] - ps.eco.cash_cent)
	hb.add_child(b)
	hb.add_child(_knopf("Abbrechen · Esc", "vorschau_abbrechen", modus_ende, false, false, "vorschau"))
	vorschau_vb.add_child(hb)
	vorschau_panel.visible = true


## [Anlegen] in der Vorschau (S2c, A1: kauft das erste Fuhrwerk mit). Danach geht der Modus am Ziel weiter, wenn es liefert.
func anlegen() -> Dictionary:
	var von := String(vorschau_werte.get("von", ""))
	var nach := String(vorschau_werte.get("nach", ""))
	var r := fuhrwerk_kaufen(von, nach)
	if r.get("ok", false):
		var sz := site_of(nach)
		if ausgang(sz) != "":
			linie_von_hier(nach)                          # Kette weiter: Ziel ist die nächste Quelle (Esc beendet)
		else:
			modus_ende()
		oeffnen(nach)
	return r


## Fuhrwerk auf der Linie von → nach kaufen (erste Linie oder + Fuhrwerk). Prüft Lizenz und Kasse vor der API,
## jede Ablehnung der API wird übersetzt (nie stumm).
func fuhrwerk_kaufen(von: String, nach: String) -> Dictionary:
	if von == "" or nach == "":
		meldung(text("ins_leere"))
		return {"ok": false, "fehler": "keine_auswahl"}
	var sv := site_of(von)
	if sv >= 0 and ist_industrie(sv) and ps.eco.lic_required and not ps.eco.licence_valid(sv):
		meldung(text("keine_lizenz", {"name": von}))       # API-Lücke: linie_anlegen prüft die Lizenz nicht (Bericht)
		oeffnen(von)
		return {"ok": false, "fehler": "keine_lizenz"}
	var n_alt := linien_fahrzeuge(von, nach).size()
	var r: Dictionary = ps.linie_anlegen(von, nach, "fuhrwerk")
	if not r.get("ok", false):
		meldung(linie_fehlertext(von, nach, r))
		return r
	_fahrzeuge_neu()
	var v := route_vorschau(von, nach, n_alt + 1)
	if n_alt == 0:
		meldung(text("linie_ok", {"a": von, "b": nach, "n": r["vid"]}))
	else:
		meldung(text("fuhrwerk_ok", {"n": r["vid"], "p": geld(int(r["preis_cent"])), "u": geld(v["fix_cent"]),
			"z": ("+" if v["netto_min_cent"] >= 0 else "") + geld(v["netto_min_cent"])}))
	if vorschau_ziel != "" and modus_von == von:
		vorschau_zeigen(von, nach, n_alt + 1)
	if auswahl != "":
		panel_neu()
	return r


func linie_fehlertext(von: String, nach: String, r: Dictionary) -> String:
	var f := String(r.get("fehler", "?"))
	match f:
		"keine_verbindung":
			return text("keine_verbindung", {"a": von, "b": nach})
		"guthaben_reicht_nicht":
			return text("fuhrwerk_geld", {"x": geld(int(fuhrwerk_def().get("kauf_cent", 0))), "d": fehlbetrag(int(r.get("fehlt_cent", 0)))})
		"gleicher_ort":
			return text("gleich")
		"bankrott":
			return text("bankrott")
		"noch_nicht_verfuegbar":
			return text("frachtwagen_1830")
		"unbekannter_ort":
			return text("ins_leere")
	return text("linie_sonst", {"code": f})


## Adapter (API-Lücke): proto_fahrzeuge.gd legt die Slots nur in bauen() an. Nach jedem Kauf baut die UI die Darstellung
## neu (Zustand und Easing liegen in proto_sim, gehen also nicht verloren). Anforderung an Felix: fahrzeug_dazu(f).
func _fahrzeuge_neu() -> void:
	var alt = welt.fahrzeuge
	var neu = preload("res://proto/proto_fahrzeuge.gd").new()
	welt.add_child(neu)
	neu.easing_an = welt.easing_an
	neu.bauen(ps, welt.regelwerk)
	welt.fahrzeuge = neu
	if alt != null:
		alt.queue_free()


## Panel-Abschnitt „Linien ab hier“ (W4-Ausschnitt): je Ziel Fuhrwerke und [+ Fuhrwerk] (S3: ≤ 2 Klicks ab Panel).
func _linien_ab(von: String) -> void:
	var ziele := {}
	var a: int = int(ps.stationen[von]["knoten"])
	for f in ps.fahrzeuge:
		if int(f["von"]) == a and not f["verkauft"] and f["kauf_cent"] > 0:
			for nm in ps.stationen:
				if int(ps.stationen[nm]["knoten"]) == int(f["nach"]):
					ziele[nm] = int(ziele.get(nm, 0)) + 1
	if ziele.is_empty():
		return
	_trenner()
	panel_vb.add_child(_label("Linien ab hier:", 16, C_GRAU))
	var preis := int(fuhrwerk_def().get("kauf_cent", 0))
	for nm in ziele:
		var hb := HBoxContainer.new()
		var l := _label("→ %s · %d Fuhrwerk(e)" % [nm, ziele[nm]], 16)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(l)
		var grau: bool = preis > ps.eco.cash_cent
		var b := _knopf("+ Fuhrwerk %s" % geld(preis), "plus_" + nm, fuhrwerk_kaufen.bind(von, nm), false, grau)
		if grau:
			b.tooltip_text = "Es fehlen %s." % fehlbetrag(preis - ps.eco.cash_cent)
		hb.add_child(b)
		panel_vb.add_child(hb)
		panel_werte["linie_" + nm] = ziele[nm]


# ------------------------------------------------------------------ AT-09 Kopfleiste (HUD Welt)

## W1: Kasse zuerst (links), Netto/min, Fix/min, Kredit-Chip, rechts Datum (Kalender), Tempo-Knöpfe und k (AT-14 A7).
## Netto und Ertrag sind Werte der letzten vollen Spielminute (Periode), tick-genau über nach_tick() aus sim_schritt:
## Ertrag = Δ revenue_total, laufende Kosten = Δ konto.expenses_total − Δ kauf_total (Fahrkosten, Unterhalt, Zins; ohne
## Fahrzeug- und Lizenzkäufe). Fix/min = konto.running_cost_per_period (Unterhalt aller Fahrzeuge je Minute).
func _baue_kopfleiste() -> void:
	kopf = PanelContainer.new()
	kopf.name = "Kopfleiste"
	kopf.mouse_filter = Control.MOUSE_FILTER_STOP
	kopf.add_theme_stylebox_override("panel", _stil(Color(0.1, 0.09, 0.08, 0.88), 8))
	kopf.anchor_left = 0.0
	kopf.anchor_right = 1.0
	kopf.offset_left = 8.0
	kopf.offset_right = -8.0
	kopf.offset_top = 8.0
	add_child(kopf)
	kopf_hb = HBoxContainer.new()
	kopf_hb.add_theme_constant_override("separation", 14)
	kopf.add_child(kopf_hb)
	lbl_kasse = _label("", 18)
	lbl_kasse.name = "Kasse"
	kopf_hb.add_child(lbl_kasse)
	lbl_netto = _label("", 16)
	lbl_netto.name = "Netto"
	lbl_netto.tooltip_text = "Ertrag minus Fahrkosten, Unterhalt und Zins der letzten vollen Minute"
	lbl_netto.mouse_filter = Control.MOUSE_FILTER_PASS
	kopf_hb.add_child(lbl_netto)
	lbl_fix = _label("", 16)
	lbl_fix.name = "Fix"
	lbl_fix.tooltip_text = "Unterhalt aller Fuhrwerke je Minute"
	lbl_fix.mouse_filter = Control.MOUSE_FILTER_PASS
	kopf_hb.add_child(lbl_fix)
	lbl_kredit = _label("", 16)
	lbl_kredit.name = "Kredit"
	kopf_hb.add_child(lbl_kredit)
	kopf_hb.add_child(_knopf("Kredit", "kredit", kredit_aufnehmen, false, false, "kopf"))
	kopf_hb.add_child(_knopf("Tilgen", "tilgen", kredit_tilgen, false, false, "kopf"))
	var luecke := Control.new()
	luecke.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	luecke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kopf_hb.add_child(luecke)
	# Datum und Tempo-Knöpfe der Szene (AT-05) ziehen in die Kopfleiste um (gleiche Knoten, Tests der Szene bleiben gültig)
	if welt.datum_label != null:
		welt.datum_label.get_parent().remove_child(welt.datum_label)
		kopf_hb.add_child(welt.datum_label)
	for t in welt.TEMPI:
		var b: Button = welt.tempo_knoepfe.get(t)
		if b != null:
			b.get_parent().remove_child(b)
			kopf_hb.add_child(b)
	lbl_k = _label("", 16)
	lbl_k.name = "TempoK"
	lbl_k.tooltip_text = "Tempo-Teiler k der Fuhrwerke (AT-04): Fahrzeuge fahren 1/k so schnell"
	lbl_k.mouse_filter = Control.MOUSE_FILTER_PASS
	kopf_hb.add_child(lbl_k)
	# altes Prototyp-HUD (Zählung, Hilfe) unter die Kopfleiste
	if welt.hud != null:
		var pc: Control = welt.hud.get_parent().get_parent()
		pc.position.y = 64.0
	_schnapp_neu()
	kopf_neu()


func _schnapp_neu() -> void:
	_schnapp.append({"tick": ps.sim.tick_count, "rev": int(ps.eco.revenue_total), "ausg": int(ps.konto.expenses_total), "kauf": int(ps.kauf_total)})
	while _schnapp.size() > 2:
		_schnapp.pop_front()


## Aus sim_schritt nach jedem Tick (prototyp_welt.gd): Schnappschuss genau an der Periodengrenze.
func nach_tick() -> void:
	if _sim_ok() and ps.sim.tick_count % periode() == 0:
		_schnapp_neu()


func kopf_neu() -> void:
	if not _sim_ok() or kopf == null:
		return
	var e = ps.eco
	hud_werte = {"kasse": int(e.cash_cent), "fix": int(ps.konto.running_cost_per_period), "kredit": int(ps.credit.loan_cent),
		"zins": int(ps.credit.interest_per_period()), "k": int(ps.tempo_k), "tempo": int(welt.sim_tempo),
		"datum": ps.kalender.datum_text(ps.ticks)}
	var form := "■" if e.cash_cent < 0 else "●"
	lbl_kasse.text = "Kasse %s %s" % [form, geld(e.cash_cent)]
	if _schnapp.size() == 2 and _schnapp[0]["tick"] + periode() == _schnapp[1]["tick"]:
		var a: Dictionary = _schnapp[0]
		var b: Dictionary = _schnapp[1]
		var ertrag: int = b["rev"] - a["rev"]
		var laufend: int = (b["ausg"] - a["ausg"]) - (b["kauf"] - a["kauf"])
		hud_werte["ertrag"] = ertrag
		hud_werte["netto"] = ertrag - laufend
		var n: int = hud_werte["netto"]
		lbl_netto.text = "Netto %s %s%s/min" % ["▲" if n >= 0 else "▼", "+" if n > 0 else "", geld(n)]
	else:
		lbl_netto.text = "Netto — $/min"
	lbl_fix.text = "Fix %s/min" % geld(hud_werte["fix"])
	if ps.credit.loan_cent > 0:
		lbl_kredit.text = "Kredit %s · Zins %s/min" % [geld(ps.credit.loan_cent), geld(hud_werte["zins"])]
	else:
		lbl_kredit.text = "Kredit —"
	var ab: bool = ps.sim.tick_count >= int(ps.credit.from_ticks)
	var kb: Button = knoepfe.get("kredit")
	if kb != null:
		kb.text = "Kredit +%s" % geld(ps.credit.step_cent)
		var frei: bool = ab and ps.credit.borrow_amount(ps.sim.tick_count) > 0
		kb.add_theme_color_override("font_color", C_TEXT if frei else C_GRAU)
		kb.tooltip_text = "Zins %d %% je Minute auf den offenen Betrag" % roundi(ps.credit.interest_pm / 10.0) if ab else text("kredit_ab12")
	var tb: Button = knoepfe.get("tilgen")
	if tb != null:
		tb.visible = ps.credit.loan_cent > 0
		tb.text = "Tilgen %s" % geld(mini(ps.credit.step_cent, ps.credit.loan_cent))
	lbl_k.text = "k=%d" % ps.tempo_k


func kredit_aufnehmen() -> int:
	var t: int = ps.sim.tick_count
	if ps.konto.bankrupt:
		meldung(text("bankrott"))
		return 0
	if t < int(ps.credit.from_ticks):
		meldung(text("kredit_ab12"))
		return 0
	var a: int = ps.kredit_aufnehmen()
	if a <= 0:
		meldung(text("kredit_voll", {"x": geld(ps.credit.limit_cent)}))
	else:
		meldung(text("kredit_ok", {"x": geld(a), "z": geld(ps.credit.interest_per_period()), "r": geld(ps.credit.limit_cent - ps.credit.loan_cent)}))
	kopf_neu()
	return a


func kredit_tilgen() -> int:
	if ps.konto.bankrupt:
		meldung(text("bankrott"))
		return 0
	if ps.credit.loan_cent <= 0:
		meldung(text("kein_kredit"))
		return 0
	var a: int = ps.kredit_tilgen()
	if a <= 0:
		meldung(text("tilgen_geld", {"x": fehlbetrag(mini(ps.credit.step_cent, ps.credit.loan_cent) - ps.eco.cash_cent)}))
	else:
		meldung(text("tilgen_ok", {"x": geld(a), "r": geld(ps.credit.loan_cent)}))
	kopf_neu()
	return a
