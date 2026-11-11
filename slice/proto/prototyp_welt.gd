extends Node3D
## Phase 4 Welle 1 (Felix): Prototyp-Szene „Welt“ (16_prototyp_plan_v1_1, schlank). Eigene Szene hinter Schalter:
## Startmenü Taste P oder Start mit `-- --proto`. Slice, S7-Welt und Sim bleiben unberührt (nichts von main.gd geladen).
##
## Aufbau (alles im Code, Einheit = 1 m, Koordinaten lokal: Ursprung NW-Ecke Kern, +x Ost, +z Süd):
##   Gelände   ProtoTerrain (TA, res://world/proto_terrain.gd) – fehlt die Datei: proto_terrain_stub.gd (flach)
##   Wege      proto_wege.json → proto_strassenband.gd (Band je Weg, Kreuzungen, Steinbogenbrücke, Fahrlinien)
##   Modelle   proto_instanzen.json → proto_platzhalter.gd (ProtoPrefabs je Typ/Variante, Fern-LOD; Box als Fallback)
##   Wasser    ProtoKulissen (TA): Steg, Ruderboote, Floß mit Holzlände (nicht aus den Instanzen)
##   Schilder  ProtoSchilder (Aylin): Ortsschilder Erlenbach/Lindenfurt/Hasenwinkel, Plaketten Gutshof/Mühle
##   Epoche    proto_epochen.gd (Datenhülle; Startjahr per `--startjahr=JJJJ`, Standard aus regelwerk.json)
## Daten je Datei: res://world/data/proto/<datei> (Vertrag: TA/Stadt), sonst res://proto/testdaten/<datei> (Felix).
##
## Steuerung (wie im Spiel): WASD/Pfeile schieben, Q/E drehen, Mausrad Zoom (40 m – 3 km), rechte/mittlere Maustaste
## ziehen = drehen, linke ziehen = schieben. Presets 1 Übersicht · 2 Dorf · 3 Markt · 4 Fluss · 5 See.
## Schalter: V Wasser A/B (Hook → terrain.set_wasser_modus) · G Easing an/aus (Hook für Welle 2, Signal) ·
##           M Modelle aus/an (Zeichentest: nur Gelände + Wege) · H Hilfe/HUD · F11 Vollbild · Esc zurück ins Startmenü.
##
## Hooks für Welle 2: Signale wasser_modus_geaendert(modus), easing_geaendert(an), modelle_geaendert(an);
## strassen.fahrlinien[i] (Schnittstelle in proto_strassenband.gd), hoehe_at(x, z) durchgereicht.
##
## Welle 2: Sim-Kette Farm → Mühle → Dorf (proto_sim.gd, echter SimWorld + Economy, Tick 10 Hz unabhängig von der
## Framerate) und Easing-Probe (proto_easing.gd, proto_fahrzeuge.gd): G schaltet Easing an/aus (Prüfsumme bleibt),
## F Kamera folgt einem Fahrzeug (Fuhrwerk 1 → Fuhrwerk 2 → Postkutsche → aus), T Zeitlupe ¼× (nur Ansicht:
## weniger Ticks je Sekunde, die Sim bleibt dieselbe), N Schilder an/aus (kein Modal).
##
## AT-05 (Block A): Leertaste = Pause, Knöpfe im Welt-HUD Pause/1×/2×/4× (sim_tempo ∈ {0,1,2,4}, Ticks/s = 10 × Tempo; die Tasten 1–5
## bleiben Kamera-Presets). Datum im HUD: Platzhalter, 1 Monat = 600 Ticks ab Startjahr (bis FZ-02 Zwei-Uhren).

signal fertig
signal wasser_modus_geaendert(modus: String)
signal easing_geaendert(an: bool)
signal modelle_geaendert(an: bool)
signal schilder_geaendert(an: bool)
signal tempo_geaendert(tempo: int)

const Strassenband := preload("res://proto/proto_strassenband.gd")
const Platzhalter := preload("res://proto/proto_platzhalter.gd")
const Epochen := preload("res://proto/proto_epochen.gd")
const ProtoSim := preload("res://proto/proto_sim.gd")
const Fahrzeuge := preload("res://proto/proto_fahrzeuge.gd")
const StelleMerken := preload("res://proto/stelle_merken.gd")     # WA-02: F12
const UiWelt := preload("res://proto/ui_welt.gd")               # S8 AT-07ff. (Mira): Welt-Panel, Linienbau, Kopfleiste
const DemoSim := preload("res://proto/demo_sim.gd")            # Demo-Sprint: nur mit --demo / Startmenü „Demo spielen“
const UiDemo := preload("res://proto/ui_demo.gd")
const STUB := "res://proto/proto_terrain_stub.gd"
const TA_TERRAIN := "res://world/proto_terrain.gd"
const DATEN := "res://world/data/proto/"
const TEST := "res://proto/testdaten/"
const START_MENU := "res://start_menu.tscn"

const FOV := 50.0
const P_NEAR := 36.0
const P_FAR := 62.0
const ABSTAND_MIN := 40.0
const ABSTAND_MAX := 3000.0
const RAND := Rect2(-1000, -1000, 4000, 3600)
const KERN_MITTE := Vector2(1000, 800)
const FLUSS_PEGEL_M := 36.4          # ausschnitt_vorgabe.json fenster.fluss_pegel_m (proto_meta.json hat Vorrang)
const PRESET_NAMEN := ["", "Übersicht", "Dorf", "Markt", "Fluss", "See"]

var terrain: Node3D = null
var terrain_quelle := ""
var strassen = null                  # proto_strassenband.gd
var platzhalter = null               # proto_platzhalter.gd
var kulissen: ProtoKulissen = null   # Steg, Boote, Floß (TA W2)
var schilder: ProtoSchilder = null   # Ortsschilder + Plaketten (Aylin W2)
var schilder_an := true
var epochen = null                   # proto_epochen.gd
var regelwerk: Dictionary = {}
var startjahr := 0
var welt_epoche: Dictionary = {}
var orte: Array = []
var instanzen: Array = []
var wege: Array = []
var see: Dictionary = {}
var quellen := {}                    # Datei -> benutzter Pfad
var lade_ms := 0.0
var lade_stufen: Dictionary = {}     # Stufe -> ms seit Start (kumuliert)
var wasser_modus := "A"
var easing_an := true
var proto_sim = null                 # proto_sim.gd (Welle 2)
var fahrzeuge = null                 # proto_fahrzeuge.gd
var orte_json: Dictionary = {}
var sim_aus := false                 # Tests: vor add_child setzen, dann keine Sim/Fahrzeuge
## AT-02: "fest" = feste Kette Farm → Mühle → Dorf (geschenkte Fahrzeuge, Stand S7/L1), "leer" = Start mit 6.000 $ ohne Kette
## (Spieler-API). Nutzerargument --kette=leer|fest. S8 AT-08 (PO-Entscheidung): Default "leer", seit die Kauf-UI steht (ui_welt.gd);
## Alttests und L1-Messungen setzen kette_modus = "fest" vor add_child oder starten mit --kette=fest.
var kette_modus := "leer"
var sim_tempo := 1                   # AT-05: Sim-Tempo 0 (Pause) | 1 | 2 | 4; Ticks je Sekunde = 10 × sim_tempo
var tempo_vor_pause := 1             # Leertaste setzt dieses Tempo wieder ein
var zeitlupe := 1.0                  # T: nur Ansicht, 1.0 oder 0.25 (multipliziert sim_tempo, nie schneller)
var sim_acc := 0.0
var tempo_knoepfe := {}              # Tempo -> Button im Welt-HUD
var datum_label: Label
const TEMPI := [0, 1, 2, 4]
## Alter Kalender-Platzhalter (AT-05): 1 Monat = 600 Ticks. Seit FZ-02 zeigt das HUD proto_sim.kalender (Monat = 150 Ticks);
## datum_text bleibt für Szenen ohne Sim (sim_aus).
const TICKS_JE_MONAT := 600
const MONATE := ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
var folgen := -1
const TICKS_JE_S := 10.0
const MAX_TICKS_JE_FRAME := 8
var modelle_an := true
var modelle_root: Node3D
var wege_root: Node3D
var rig: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var env: Environment
var ziel := Vector3(KERN_MITTE.x, 40.0, KERN_MITTE.y)
var gier := 0.0
var abstand := ABSTAND_MAX
var presets := {}                    # nr -> {name, ziel: Vector2, abstand, gier}
var preset_aktiv := 1
var hud: Label
var hud_an := true
var _hud_t := 0.0
var _drag := 0                       # 0 nichts, 1 schieben, 2 drehen
var ui_welt = null                   # S8 AT-07: proto/ui_welt.gd (nur mit Sim)
static var demo_start := false       # Demo-Sprint: Startmenü setzt das vor dem Szenenwechsel
var demo := false                    # Demo-Modus (DemoSim + ui_demo)
var ui_demo = null
var demo_daten: Dictionary = {}
var _rklick_start := Vector2(-1000, -1000)
var _klick_start := Vector2(-1, -1)  # AT-07: Linksklick ohne Ziehen = Weltklick
var _bau_zug := false                # Demo Teil 5: linke Taste unten im Baumodus (Trasse ziehen statt Kamera schieben)


static func datei(name: String) -> String:
	if FileAccess.file_exists(DATEN + name):
		return DATEN + name
	return TEST + name


func _json(name: String) -> Variant:
	var p := datei(name)
	quellen[name] = p
	if not FileAccess.file_exists(p):
		push_warning("Prototyp: Datei fehlt: " + name)
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(p))


func _ready() -> void:
	var t0 := Time.get_ticks_usec()
	var tz := {}
	_baue_umgebung()
	epochen = Epochen.laden()
	regelwerk = epochen.regelwerk
	startjahr = epochen.startjahr_standard()
	demo = demo or demo_start
	for a in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if a.begins_with("--startjahr=") and a.substr(12).is_valid_int():
			startjahr = int(a.substr(12))
		elif a == "--demo":
			demo = true
	if demo and FileAccess.file_exists(DemoSim.DEMO_JSON):
		var dd = JSON.parse_string(FileAccess.get_file_as_string(DemoSim.DEMO_JSON))
		demo_daten = dd if dd is Dictionary else {}
	welt_epoche = epochen.fuer_jahr(startjahr)
	_lies_daten()
	tz["lies_daten"] = (Time.get_ticks_usec() - t0) / 1000.0
	_baue_gelaende()
	tz["baue_gelaende"] = (Time.get_ticks_usec() - t0) / 1000.0
	_baue_wege()
	tz["baue_wege"] = (Time.get_ticks_usec() - t0) / 1000.0
	_baue_modelle()
	tz["baue_modelle"] = (Time.get_ticks_usec() - t0) / 1000.0
	_baue_fahrzeuge()
	tz["baue_fahrzeuge"] = (Time.get_ticks_usec() - t0) / 1000.0
	_baue_kamera()
	schilder = ProtoSchilder.bauen(self, cam, orte, terrain, _demo_industrie())
	tz["baue_schilder"] = (Time.get_ticks_usec() - t0) / 1000.0
	_baue_hud()
	if proto_sim != null and proto_sim.eco != null:     # AT-07: Welt-UI über dem HUD
		ui_welt = UiWelt.new()
		ui_welt.einbauen(self)
		if demo:
			ui_demo = UiDemo.new()
			ui_demo.einbauen(self, ui_welt)
	_presets_berechnen()
	setze_preset(1)
	lade_ms = (Time.get_ticks_usec() - t0) / 1000.0
	lade_stufen = tz
	print("PROTO_WELT stufen %s sim %s" % [str(lade_stufen), str(quellen.get("sim_ms", []))])
	print("PROTO_WELT lade_ms %.1f terrain=%s wege=%d instanzen=%d knoten=%d bruecken=%d fahrzeuge=%d kette=%s" % [lade_ms,
		terrain_quelle, wege.size(), instanzen.size(), strassen.knoten.size(), strassen.bruecken.size(),
		proto_sim.fahrzeuge.size() if proto_sim != null else 0, str(proto_sim.kette_ok) if proto_sim != null else "aus"])
	fertig.emit()


func _lies_daten() -> void:
	var o = _json("proto_orte.json")
	orte = o.get("orte", []) if o is Dictionary else []
	orte_json = o if o is Dictionary else {}
	var i = _json("proto_instanzen.json")
	instanzen = i if i is Array else []
	var w = _json("proto_wege.json")
	wege = w if w is Array else []
	var s = _json("proto_see.json")
	see = s if s is Dictionary else {}
	if demo:                                           # Demo-Betriebe: Gebäude als zusätzliche Instanzen (gleiche Prefabs)
		instanzen = instanzen.duplicate()
		for b in demo_daten.get("betriebe", []):
			for m in b.get("modelle", []):
				var inst := {"typ": String(m["typ"]), "x": float(b["x"]) + float(m.get("dx", 0)), "z": float(b["z"]) + float(m.get("dz", 0)),
					"rot_deg": float(m.get("rot_deg", 0)), "parzelle": "demo_" + String(b["id"]), "ort": String(b["id"])}
				for k in ["b", "t", "variante"]:
					if m.has(k):
						inst[k] = m[k]
				instanzen.append(inst)


## Demo: Schilder auch für die neuen Betriebe (leer = ProtoSchilder liest proto_orte.json wie bisher).
func _demo_industrie() -> Array:
	if not demo:
		return []
	var l: Array = orte_json.get("industrie", []).duplicate()
	for b in demo_daten.get("betriebe", []):
		l.append({"id": String(b["id"]), "name": String(b["name"]), "typ": String(b["typ"]), "x": float(b["x"]), "z": float(b["z"])})
	return l


func _baue_umgebung() -> void:
	var l := ProtoLicht.baue(self)
	env = l["env"]
	sun = l["sun"]


func _baue_gelaende() -> void:
	var pfad := TA_TERRAIN if ResourceLoader.exists(TA_TERRAIN) else STUB
	terrain_quelle = "TA" if pfad == TA_TERRAIN else "Stub (flach)"
	var dir := DATEN if FileAccess.file_exists(DATEN + "proto_hoehe.r16") or FileAccess.file_exists(DATEN + "proto_fluss.u8") else TEST
	var scr: Script = load(pfad)
	if scr != null and scr.can_instantiate():
		terrain = scr.call("bauen", self, dir)
	if terrain == null and pfad != STUB:        # TA-Datei kaputt oder andere API: Stub, damit die Szene läuft
		push_warning("Prototyp: ProtoTerrain nicht nutzbar, Stub statt TA")
		terrain_quelle = "Stub (TA-Fehler)"
		terrain = (load(STUB) as Script).call("bauen", self, dir)
	if terrain != null and terrain.get_parent() == null:
		add_child(terrain)
	quellen["terrain_dir"] = dir


func hoehe_at(x_m: float, z_m: float) -> float:
	if terrain == null:
		return 0.0
	return float(terrain.hoehe_at(x_m, z_m))


func _meta() -> Dictionary:
	var p := datei("proto_meta.json")
	if not FileAccess.file_exists(p):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d if d is Dictionary else {}


func _baue_wege() -> void:
	wege_root = Node3D.new()
	wege_root.name = "Wege"
	add_child(wege_root)
	strassen = Strassenband.new()
	strassen.konfig_aus_regelwerk(regelwerk)
	var meta := _meta()
	strassen.wasser_pegel_m = float(meta.get("fluss_pegel_m", FLUSS_PEGEL_M))
	# Flussmaske: Meta-Schlüssel defensiv lesen (TA-Format noch offen), sonst Ausschnitt-Vorgabe 160 × 144 ab (−1000, −1000)
	var fm := {}
	if meta.has("ursprung_m"):
		fm["x0"] = meta["ursprung_m"][0]
		fm["z0"] = meta["ursprung_m"][1]
	if meta.has("felder"):
		fm["w"] = meta["felder"][0]
		fm["h"] = meta["felder"][1]
	if meta.has("m_pro_feld"):
		fm["m"] = meta["m_pro_feld"]
	var fp := datei("proto_fluss.u8")
	quellen["proto_fluss.u8"] = fp
	var fluss: Dictionary = Strassenband.fluss_laden(fp, fm)
	strassen.bauen(wege_root, wege, Callable(self, "hoehe_at"), fluss)


## Welle 2: Sim-Kette und Fahrzeuge. Fehlt etwas (Daten, Verbindung), läuft die Szene ohne Fahrzeuge weiter.
func _baue_fahrzeuge() -> void:
	if sim_aus:
		return
	var t0 := Time.get_ticks_usec()
	proto_sim = DemoSim.new(regelwerk) if demo else ProtoSim.new(regelwerk)
	proto_sim.kalender.startjahr = startjahr          # FZ-02: Kalender der Welt (jahr_ticks 1.800), Startjahr der Szene
	proto_sim.graph_bauen(strassen)
	var t1 := Time.get_ticks_usec()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kette=") and a.substr(8) in ["leer", "fest"]:
			kette_modus = a.substr(8)
	var ok: bool = proto_sim.spiel_starten(orte_json) if kette_modus == "leer" else proto_sim.kette_aufbauen(orte_json)
	quellen["sim_ms"] = [(t1 - t0) / 1000.0, (Time.get_ticks_usec() - t1) / 1000.0]
	if not ok:
		push_warning("Prototyp: Sim-Kette unvollständig: " + "; ".join(PackedStringArray(proto_sim.fehler.map(func(x): return str(x)))))
	fahrzeuge = Fahrzeuge.new()
	add_child(fahrzeuge)
	fahrzeuge.easing_an = easing_an
	fahrzeuge.bauen(proto_sim, regelwerk)


## Sim-Ticks nachholen (feste 10 Hz × Bildtempo) und alle Fahrzeuge für diesen Frame setzen.
func sim_schritt(delta: float) -> void:
	if proto_sim == null:
		return
	if sim_tempo == 0:                   # Pause: kein Tick, keine Fahrzeugbewegung, Easing-Zustand eingefroren
		return
	var dt := delta * TICKS_JE_S * sim_tempo * zeitlupe
	sim_acc += dt
	var n := 0
	while sim_acc >= 1.0 and n < MAX_TICKS_JE_FRAME:
		proto_sim.tick()
		if ui_welt != null:
			ui_welt.nach_tick()                # AT-09: Netto/min tick-genau je Spielminute
		sim_acc -= 1.0
		n += 1
	if sim_acc >= 1.0:
		sim_acc = fmod(sim_acc, 1.0)
	fahrzeuge.frame(sim_acc, dt)


## AT-05: Sim-Tempo setzen (0 Pause, 1, 2, 4). Unbekannte Werte werden ignoriert.
func setze_tempo(t: int) -> void:
	if not (t in TEMPI):
		return
	if t == 0 and sim_tempo != 0:
		tempo_vor_pause = sim_tempo
	sim_tempo = t
	tempo_geaendert.emit(t)
	_hud_text()


## Leertaste: Pause an/aus (zurück auf das Tempo vor der Pause).
func pause_umschalten() -> void:
	setze_tempo(tempo_vor_pause if sim_tempo == 0 else 0)


## Datum aus Ticks (Platzhalter bis FZ-02): "Mär 1821".
static func datum_text(ticks: int, jahr0: int) -> String:
	var m: int = maxi(0, ticks) / TICKS_JE_MONAT
	return "%s %d" % [MONATE[m % 12], jahr0 + m / 12]


func _baue_modelle() -> void:
	modelle_root = Node3D.new()
	modelle_root.name = "Modelle"
	add_child(modelle_root)
	platzhalter = Platzhalter.new(regelwerk)
	platzhalter.bauen(modelle_root, instanzen, Callable(self, "hoehe_at"))
	# Kulissen am Wasser (ProtoKulissen.TYPEN_SELBST überspringt der Platzhalter); braucht das TA-Gelände (fluss_mitte_z)
	if terrain != null and terrain.has_method("fluss_mitte_z"):
		kulissen = ProtoKulissen.bauen(modelle_root, terrain, quellen.get("terrain_dir", DATEN))


# ------------------------------------------------------------------ Kamera

func _baue_kamera() -> void:
	rig = Node3D.new()
	rig.name = "KameraRig"
	add_child(rig)
	cam = Camera3D.new()
	cam.fov = FOV
	rig.add_child(cam)
	cam.current = true


static func pitch_for(d_m: float) -> float:
	var t := clampf(log(d_m / 40.0) / log(5600.0 / 40.0), 0.0, 1.0)    # gleiche Kurve wie s7_world (SP-03)
	return lerpf(P_NEAR, P_FAR, pow(t, 0.8))


func _kamera_anwenden() -> void:
	abstand = clampf(abstand, ABSTAND_MIN, ABSTAND_MAX)
	ziel.x = clampf(ziel.x, RAND.position.x, RAND.end.x)
	ziel.z = clampf(ziel.z, RAND.position.y, RAND.end.y)
	ziel.y = hoehe_at(ziel.x, ziel.z)
	rig.position = ziel
	rig.rotation = Vector3(0, gier, 0)
	var p := deg_to_rad(pitch_for(abstand))
	var cp := Vector3(0.0, sin(p) * abstand, cos(p) * abstand)
	var welt := rig.transform * cp
	var gy := hoehe_at(welt.x, welt.z) + 8.0
	if welt.y < gy:
		cp.y += gy - welt.y
	cam.position = cp
	cam.rotation = Vector3(-atan2(cp.y, cp.z), 0.0, 0.0)
	cam.near = maxf(0.1, abstand * 0.004)
	cam.far = abstand * 8.0 + 15000.0
	env.fog_depth_begin = abstand * 1.6 + 1500.0
	env.fog_depth_end = abstand * 5.0 + 15000.0
	sun.directional_shadow_max_distance = clampf(abstand * 1.4, 150.0, 2500.0)


## F: Kamera folgt Fahrzeug 1, 2, 3, dann wieder frei (Abstand 120 m beim Einstieg).
func folge_naechstem() -> void:
	if proto_sim == null or proto_sim.fahrzeuge.is_empty():
		return
	folgen += 1
	if folgen >= proto_sim.fahrzeuge.size():
		folgen = -1
	elif abstand > 400.0:
		abstand = 120.0
	_kamera_anwenden()
	_hud_text()


func kamera_abstand() -> float:
	return abstand


func _presets_berechnen() -> void:
	presets[1] = {"ziel": KERN_MITTE, "abstand": ABSTAND_MAX, "gier": 0.0}
	presets[2] = {"ziel": Vector2(700, 1060), "abstand": 450.0, "gier": 0.35}
	presets[3] = {"ziel": Vector2(930, 230), "abstand": 350.0, "gier": -0.3}
	presets[4] = {"ziel": Vector2(860, 620), "abstand": 260.0, "gier": 1.1}
	presets[5] = {"ziel": Vector2(1212.5, 1012.5), "abstand": 750.0, "gier": 0.6}
	for o in orte:
		var k: String = o.get("klasse", "")
		var p := Vector2(float(o.get("x", 0)), float(o.get("z", 0)))
		if k == "dorf" and not presets[2].has("aus_daten"):
			presets[2]["ziel"] = p
			presets[2]["aus_daten"] = true
		elif k in ["kleinstadt", "marktflecken", "markt"] and not presets[3].has("aus_daten"):
			presets[3]["ziel"] = p
			presets[3]["aus_daten"] = true
	if not strassen.bruecken.is_empty():
		var b: Dictionary = strassen.bruecken[0]
		var m: Vector3 = (b["p0"] + b["p1"]) * 0.5
		var f: Vector3 = b["p1"] - b["p0"]
		presets[4]["ziel"] = Vector2(m.x, m.z)
		presets[4]["gier"] = atan2(f.x, f.z) + PI * 0.5 + 0.35     # seitlich auf die Bögen, leicht schräg
		presets[4]["abstand"] = 170.0
		presets[4]["aus_daten"] = true
	if see.has("mitte_m"):
		presets[5]["ziel"] = Vector2(float(see["mitte_m"][0]), float(see["mitte_m"][1]))
		presets[5]["aus_daten"] = true


func setze_preset(n: int) -> void:
	if not presets.has(n):
		return
	var p: Dictionary = presets[n]
	preset_aktiv = n
	ziel = Vector3(p["ziel"].x, 0, p["ziel"].y)
	abstand = p["abstand"]
	gier = p["gier"]
	_kamera_anwenden()
	_hud_text()


# ------------------------------------------------------------------ Schalter (Hooks)

func setze_wasser(modus: String) -> void:
	wasser_modus = modus
	if terrain != null and terrain.has_method("set_wasser_modus"):
		terrain.set_wasser_modus(modus)
	elif terrain != null and terrain.has_method("wasser_variante_b"):      # TA-API (proto_terrain.gd)
		terrain.wasser_variante_b(modus == "B")
	wasser_modus_geaendert.emit(modus)
	_hud_text()


func setze_easing(an: bool) -> void:
	easing_an = an
	if fahrzeuge != null:
		fahrzeuge.easing_an = an
	easing_geaendert.emit(an)
	_hud_text()


func setze_modelle(an: bool) -> void:
	modelle_an = an
	modelle_root.visible = an
	modelle_geaendert.emit(an)
	_hud_text()


func setze_schilder(an: bool) -> void:
	schilder_an = an
	if schilder != null:
		schilder.setze_sichtbar(an)
	schilder_geaendert.emit(an)
	_hud_text()


## Vollbild (randlos) an/aus. F11 oder Alt+Enter. Sim und Kamera bleiben unberührt, die UI skaliert über stretch=expand.
func vollbild_umschalten() -> void:
	var w := get_window()
	if w.mode == Window.MODE_FULLSCREEN:
		w.mode = Window.MODE_WINDOWED
	else:
		w.mode = Window.MODE_FULLSCREEN
	_hud_text()


func _unhandled_input(ev: InputEvent) -> void:
	if ui_demo != null and ui_demo.eingabe(ev):          # Demo: Baumodus, Firmensitz, Verträge, Skills, Esc-Abfrage
		get_viewport().set_input_as_handled()
		return
	if ui_welt != null and ui_welt.eingabe(ev):          # AT-07 (G5): Esc schließt zuerst Panel/Modus
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = ev.keycode
		if k >= KEY_1 and k <= KEY_5:
			setze_preset(k - KEY_0)
		elif k >= KEY_KP_1 and k <= KEY_KP_5:
			setze_preset(k - KEY_KP_0)
		elif k == KEY_V:
			setze_wasser("B" if wasser_modus == "A" else "A")
		elif k == KEY_G:
			setze_easing(not easing_an)
		elif k == KEY_M:
			setze_modelle(not modelle_an)
		elif k == KEY_N:
			setze_schilder(not schilder_an)
		elif k == KEY_F:
			folge_naechstem()
		elif k == KEY_T:
			zeitlupe = 0.25 if zeitlupe == 1.0 else 1.0
			_hud_text()
		elif k == KEY_SPACE:
			pause_umschalten()
		elif k == KEY_H:
			hud_an = not hud_an
			hud.visible = hud_an
		elif k == KEY_F12:                  # WA-02: Stelle merken (PNG + JSON nach user://stellen/)
			StelleMerken.merken(self)
		elif k == KEY_F11 or (k == KEY_ENTER and ev.alt_pressed):
			vollbild_umschalten()
		elif k == KEY_ESCAPE:
			get_tree().change_scene_to_file(START_MENU)
			return
		else:
			return
		get_viewport().set_input_as_handled()
	elif ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			abstand *= 0.88
			_kamera_anwenden()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			abstand /= 0.88
			_kamera_anwenden()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			# Demo Teil 5: Im Baumodus gehört die gehaltene linke Taste dem Bauwerkzeug (Ziehen), nicht der Kamera.
			# Die Kamera schiebt dort die mittlere Taste, WASD und das Mausrad; die rechte Taste dreht weiter.
			if mb.pressed:
				_klick_start = mb.position
				_bau_zug = ui_demo != null and ui_demo.bau_modus() and ui_demo.maus_druck(mb.position)
				_drag = 0 if _bau_zug else 1
			else:
				_drag = 0
				var war_zug := _bau_zug
				_bau_zug = false
				if war_zug and ui_demo.maus_los(mb.position):
					pass                                     # Ziehen: der Abschnitt ist gebaut bzw. geplant
				elif ui_welt != null and _klick_start.x >= 0.0 and mb.position.distance_to(_klick_start) < 6.0:
					if ui_demo == null or not ui_demo.welt_klick(mb.position):
						ui_welt.welt_klick(mb.position)      # AT-07: Loslassen ohne Ziehen = Klick
		elif mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			var bau_an: bool = ui_demo != null and ui_demo.bau_modus()
			if not mb.pressed:
				_drag = 0
			elif mb.button_index == MOUSE_BUTTON_MIDDLE and bau_an:
				_drag = 1                                    # Baumodus: mittlere Taste schiebt (die linke zieht die Trasse)
			else:
				_drag = 2
			if ui_demo != null and mb.button_index == MOUSE_BUTTON_RIGHT:   # Demo: Rechtsklick ohne Ziehen = Punkt zurück (Bauwerkzeug)
				if mb.pressed:
					_rklick_start = mb.position
				elif mb.position.distance_to(_rklick_start) < 6.0:
					ui_demo.rechts_klick(mb.position)
	elif ev is InputEventMouseMotion:
		if _bau_zug:
			ui_demo.maus_zug((ev as InputEventMouseMotion).position)
		elif _drag != 0:
			var r: Vector2 = (ev as InputEventMouseMotion).relative
			if _drag == 2:
				gier -= r.x * 0.005
			else:
				var d := Vector3(-r.x, 0, -r.y) * abstand * 0.0012
				ziel += Basis(Vector3.UP, gier) * d
			_kamera_anwenden()


func _process(delta: float) -> void:
	var mv := Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		mv.z -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		mv.z += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		mv.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		mv.x += 1
	var dreh := 0.0
	if Input.is_key_pressed(KEY_Q):
		dreh += 1.5 * delta
	if Input.is_key_pressed(KEY_E):
		dreh -= 1.5 * delta
	if mv != Vector3.ZERO or dreh != 0.0:
		ziel += Basis(Vector3.UP, gier) * mv.normalized() * abstand * 0.8 * delta
		gier += dreh
		_kamera_anwenden()
	sim_schritt(delta)
	if folgen >= 0 and proto_sim != null and folgen < proto_sim.fahrzeuge.size():
		var z = proto_sim.fahrzeuge[folgen]["zustand"]
		ziel = Vector3(z.pos.x, 0.0, z.pos.z)
		_kamera_anwenden()
	_hud_t += delta
	if _hud_t > 0.25:
		_hud_t = 0.0
		_hud_text()


# ------------------------------------------------------------------ HUD / Zählung

func _baue_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var pc := PanelContainer.new()
	pc.position = Vector2(12, 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.09, 0.08, 0.72)
	sb.set_content_margin_all(10)
	pc.add_theme_stylebox_override("panel", sb)
	cl.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	# AT-05: Datum + Tempo-Knöpfe (Pause, 1×, 2×, 4×). Fokus aus, damit die Leertaste nie einen Knopf auslöst.
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 8)
	vb.add_child(kopf)
	datum_label = Label.new()
	datum_label.name = "Datum"
	datum_label.add_theme_font_size_override("font_size", 18)
	datum_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	datum_label.custom_minimum_size = Vector2(110, 0)
	kopf.add_child(datum_label)
	for t in TEMPI:
		var b := Button.new()
		b.name = "Tempo_%d" % t
		b.text = "Pause" if t == 0 else "%d×" % t
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(54, 28)
		b.tooltip_text = "Pause (Leertaste)" if t == 0 else "Sim-Tempo %d× (10 Ticks/s × %d)" % [t, t]
		b.pressed.connect(setze_tempo.bind(t))
		kopf.add_child(b)
		tempo_knoepfe[t] = b
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 15)
	hud.add_theme_color_override("font_color", Color(0.96, 0.92, 0.84))
	vb.add_child(hud)


func _hud_text() -> void:
	if hud == null:
		return
	for t in tempo_knoepfe:
		(tempo_knoepfe[t] as Button).set_pressed_no_signal(t == sim_tempo)
	if datum_label != null:
		datum_label.text = proto_sim.kalender.datum_text(proto_sim.ticks) if proto_sim != null else datum_text(0, startjahr)   # FZ-02
	var z := zaehlung()
	var live := ""
	if z["live_dreiecke"] > 0:
		live = "  ·  live %s Dreiecke / %d DC" % [_tsd(z["live_dreiecke"]), z["live_dc"]]
	var fz := ""
	if proto_sim != null:
		var zeilen: Array = []
		for f in proto_sim.fahrzeuge:
			zeilen.append(proto_sim.zustand_text(f))
		var kasse: int = proto_sim.eco.cash_cent if proto_sim.eco != null else 0
		fz = "Sim-Kette %s · Tick %d · Lieferungen %d · Kasse %d €\n%s\n" % ["Farm → Mühle → Dorf" if proto_sim.kette_ok else ("leer (Start ohne Kette)" if kette_modus == "leer" else "UNVOLLSTÄNDIG"),
			proto_sim.ticks, proto_sim.lieferungen.size(), kasse / 100, "  ·  ".join(PackedStringArray(zeilen))]
	hud.text = "Prototyp Welt · Welle 2 (schlank) · Startjahr %d (%s) · Tempo %s\n" % [startjahr, welt_epoche.get("epoche_id", "?"), "Pause" if sim_tempo == 0 else "%d×" % sim_tempo] \
		+ "Ansicht %d %s · Abstand %d m%s\n" % [preset_aktiv, PRESET_NAMEN[preset_aktiv], int(abstand),
			(" · folgt %s" % proto_sim.fahrzeuge[folgen]["name"]) if folgen >= 0 and proto_sim != null else ""] \
		+ "[1–5] Presets   [V] Wasser %s   [G] Easing %s   [F] Folgen   [Leertaste] Pause   [T] Zeitlupe %s   [M] Modelle %s   [N] Schilder %s   [H] Hilfe   [F11] Vollbild   [Esc] Menü\n" % [
			wasser_modus, "an" if easing_an else "aus", "aus" if zeitlupe == 1.0 else "¼×", "an" if modelle_an else "aus",
			"an" if schilder_an else "aus"] \
		+ fz \
		+ "Gelände: %s · Daten: %s · Laden %.0f ms\n" % [terrain_quelle, "Vertrag" if quellen.get("proto_wege.json", "").begins_with(DATEN) else "Testdaten", lade_ms] \
		+ "Szene %s Dreiecke / %d Objekte (gezählt), %s mit Sichtweite%s" % [_tsd(z["dreiecke"]), z["objekte"], _tsd(z["dreiecke_sicht"]), live]


static func _tsd(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


## Zählung ohne Renderziel (Mesh-Daten) + live aus dem RenderingServer, wenn gerendert wird.
## objekte = sichtbare Geometrie-Instanzen (≈ Draw Calls im Farbpass ohne Schatten/Culling).
## dreiecke_sicht/objekte_sicht: ohne Knoten, deren AABB weiter als visibility_range_end von der Kamera liegt
## (Sichtweiten-Culling, Abstand Kamera → AABB-Mitte, ohne Frustum) – die Gate-Zahl, wenn kein Renderziel da ist.
func zaehlung() -> Dictionary:
	var tris := 0
	var obj := 0
	var tris_s := 0
	var obj_s := 0
	var cpos := cam.global_position if cam != null and cam.is_inside_tree() else Vector3(INF, INF, INF)
	var stapel: Array = [self]
	while not stapel.is_empty():
		var n: Node = stapel.pop_back()
		if n is Node3D and not (n as Node3D).visible:
			continue
		var t := 0
		var o := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var m: Mesh = n.mesh
			t = _mesh_tris(m)
			o = m.get_surface_count()
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			var mm: MultiMesh = n.multimesh
			var cnt := mm.instance_count if mm.visible_instance_count < 0 else mm.visible_instance_count
			if mm.mesh != null and cnt > 0:
				t = _mesh_tris(mm.mesh) * cnt
				o = mm.mesh.get_surface_count()
		if t > 0:
			tris += t
			obj += o
			var gi := n as GeometryInstance3D
			var sicht := true
			if gi.visibility_range_end > 0.0 and cpos.x != INF:
				var lb := _aabb_cpu(gi)
				if lb.size.length() > 0.01:      # headless: MultiMesh-Transforms liegen nur im RenderingServer → unbekannt = sichtbar
					var bb: AABB = gi.global_transform * lb
					sicht = cpos.distance_to(bb.get_center()) <= gi.visibility_range_end + gi.visibility_range_end_margin   # Renderer: AABB-Mitte
			if sicht:
				tris_s += t
				obj_s += o
		for c in n.get_children():
			stapel.append(c)
	return {"dreiecke": tris, "objekte": obj, "dreiecke_sicht": tris_s, "objekte_sicht": obj_s,
		"live_dreiecke": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"live_dc": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)}


var _tri_cache := {}
var _aabb_cache := {}


## AABB ohne RenderingServer (headless liefert für MultiMesh keine AABB): aus den Instanz-Transforms, gepuffert.
## Für bewegte MultiMeshes (Fahrzeuge, keine Sichtweite) nicht benutzt.
func _aabb_cpu(gi: GeometryInstance3D) -> AABB:
	var id := gi.get_instance_id()
	if _aabb_cache.has(id):
		return _aabb_cache[id]
	var bb := AABB()
	if gi is MultiMeshInstance3D and (gi as MultiMeshInstance3D).multimesh != null:
		var mm: MultiMesh = (gi as MultiMeshInstance3D).multimesh
		var mb := mm.mesh.get_aabb() if mm.mesh != null else AABB()
		var pos_ok := false
		for i in mm.instance_count:
			var xf := mm.get_instance_transform(i)
			pos_ok = pos_ok or xf.origin != Vector3.ZERO
			var ib := xf * mb
			bb = ib if i == 0 else bb.merge(ib)
		if not pos_ok:
			bb = AABB()
	elif gi is MeshInstance3D and (gi as MeshInstance3D).mesh != null:
		bb = (gi as MeshInstance3D).mesh.get_aabb()
	_aabb_cache[id] = bb
	return bb

func _mesh_tris(m: Mesh) -> int:
	var id := m.get_instance_id()
	if _tri_cache.has(id):
		return _tri_cache[id]
	var t := 0
	if m is PrimitiveMesh:
		t = m.get_faces().size() / 3
	else:
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			t += (idx.size() if idx != null and idx.size() > 0 else arr[Mesh.ARRAY_VERTEX].size()) / 3
	_tri_cache[id] = t
	return t
