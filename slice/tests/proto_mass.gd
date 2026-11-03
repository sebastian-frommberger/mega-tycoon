extends SceneTree
## Phase 4 Welle 1 (Felix): Messsuite-Gerüst der Prototyp-Welt (16_prototyp_plan_v1_1 §5, 14 §3, VERTRAG Messregeln).
##   headless (Maße + gezählte Perf):  godot --headless --path slice -s res://tests/proto_mass.gd [-- --csv=<pfad>]
##   mit Renderziel (Perf live):       xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path slice \
##                                         -s res://tests/proto_mass.gd [-- --csv=<pfad>]
## CSV (Standard: sprints/s8/design-sprint/phase4/proto_mass.csv, außerhalb res:// – Godot importiert dort keine CSV):
##   Objekt;Soll;Ist;Abw. %;OK;Quelle
##
## 1) Maße: AABB je Instanztyp in Metern (Typen aus proto_instanzen.json + Pflichtliste M1/M14). Quelle der AABB:
##    res://proto/prefabs/<typ>.tscn, wenn vorhanden (Welle 2: echte Prefabs, AABB × Knoten-Skalierung = Maßstab),
##    sonst das Platzhalter-Mesh (proto_platzhalter.gd). Soll aus regelwerk.json `skalen` (gebaeude_m, industrie_m,
##    fahrzeuge_dm, baeume_m), ersatzweise `haustypen` bzw. 16 §5 M14 (Steg, Fischerhütte). Toleranz aus
##    skalen.toleranz_promille (±25 %), Fahrzeuge Länge 0,9–1,2 × real (fahrzeug_min/max_promille_real).
##    Grundriss wird sortiert verglichen (lang/quer), weil Modelle beliebig gedreht stehen.
## 2) Epoche: jeder Wohnhaustyp der Szene ist im Startjahr frei (hebel.haustypen_frei), kein ab_jahr > Epochenende.
## 3) Perf: Dreiecke, Draw Calls, Ladezeit. Gate Übersicht ≤ 1,0 M / ≤ 300 DC, Markt nah ≤ 2,9 M, Laden ≤ 3 s.
##    Ohne Renderziel (headless) zählt die Suite die Mesh-Daten (Draw Calls = Geometrie-Objekte im Farbpass, ohne
##    Schatten) und markiert das in der Quelle; mit xvfb gelten die RenderingServer-Werte.
## Exit 0 nur, wenn alle Zeilen OK sind.

const Platzhalter := preload("res://proto/proto_platzhalter.gd")
const Epochen := preload("res://proto/proto_epochen.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const PREFABS := "res://proto/prefabs/"

## Pflichtobjekte (14 §3 M1–M13, 16 §5 M14), auch wenn sie in den Instanzen fehlen.
const PFLICHT := ["kate", "bauernhof", "buergerhaus", "kirche_dorf", "kirche_stadt", "scheune", "gutshof", "wassermuehle",
	"fuhrwerk_2_pferde", "postkutsche_4_pferde", "dampflok", "tender", "personenwagen", "gueterwagen",
	"steg", "fischerhuette", "ruderboot", "laubbaum", "obstbaum"]

## Typ -> Soll-Eintrag in regelwerk.skalen (Pfad). Nicht gelistete Haustypen: Soll = regelwerk.haustypen.
const SOLL_SKALEN := {
	"kate": "gebaeude_m/haus_s_kate", "bauernhof": "gebaeude_m/haus_m", "handwerkerhaus": "gebaeude_m/haus_m",
	"grosshof": "gebaeude_m/haus_m", "buergerhaus": "gebaeude_m/haus_l", "mietshaus": "gebaeude_m/haus_xl",
	"kirche_dorf": "gebaeude_m/kirche_dorf", "kirche_stadt": "gebaeude_m/kirche_stadt", "scheune": "gebaeude_m/scheune",
	"gutshof": "industrie_m/gutshof", "wassermuehle": "industrie_m/wassermuehle", "windmuehle": "industrie_m/windmuehle",
	"fuhrwerk_2_pferde": "fahrzeuge_dm/fuhrwerk_2_pferde", "postkutsche_4_pferde": "fahrzeuge_dm/postkutsche_4_pferde",
	"dampflok": "fahrzeuge_dm/dampflok", "tender": "fahrzeuge_dm/tender", "personenwagen": "fahrzeuge_dm/personenwagen",
	"gueterwagen": "fahrzeuge_dm/gueterwagen", "pferd": "fahrzeuge_dm/pferd",
	"laubbaum": "baeume_m/laub", "eiche": "baeume_m/laub", "nadelbaum": "baeume_m/nadel",
	"nadelbaum_schlank": "baeume_m/nadel", "obstbaum": "baeume_m/obst",
}
## 16 §5 M14 (nicht in skalen): Grundriss [lang, quer] in m; Ruderboot = Fahrzeugregel mit real 4,5 m (epochen W1).
const SOLL_M14 := {"steg": [25.0, 2.0], "fischerhuette": [8.0, 6.0]}

var rw: Dictionary = {}
var tol := 0.25
var fz_min := 0.9
var fz_max := 1.2
var zeilen: Array = []
var n_fail := 0


func _initialize() -> void:
	_run.call_deferred()


func zeile(objekt: String, soll: String, ist: float, abw: float, ok: bool, quelle: String) -> void:
	zeilen.append([objekt, soll, "%.2f" % ist, "%+.1f" % abw if not is_nan(abw) else "", "ja" if ok else "NEIN", quelle])
	if not ok:
		n_fail += 1
	print("  %-4s %-34s Soll %-18s Ist %10.2f  Abw %7s  %s" % ["OK" if ok else "FAIL", objekt, soll, ist, ("%+.1f %%" % abw) if not is_nan(abw) else "", quelle])


func _run() -> void:
	print("proto_mass")
	print("  Modellquelle: %s" % ("ProtoPrefabs (TA) wo vorhanden, sonst Platzhalter" if ResourceLoader.exists("res://world/proto_prefabs.gd") else "Platzhalter (res://world/proto_prefabs.gd fehlt noch)"))
	var ep = Epochen.laden()
	rw = ep.regelwerk
	var sk: Dictionary = rw.get("skalen", {})
	tol = float(sk.get("toleranz_promille", 250)) / 1000.0
	fz_min = float(sk.get("fahrzeug_min_promille_real", 900)) / 1000.0
	fz_max = float(sk.get("fahrzeug_max_promille_real", 1200)) / 1000.0
	# Szene laden (Ladezeit = Instanziieren + _ready)
	var t0 := Time.get_ticks_usec()
	var s: Node = (load(SZENE) as PackedScene).instantiate()
	root.add_child(s)
	await process_frame
	var wand_ms := (Time.get_ticks_usec() - t0) / 1000.0
	# 1) Maße
	var ph = s.platzhalter
	var typen := {}
	for it in s.instanzen:
		typen[String(it.get("typ", ""))] = true
	for t in PFLICHT:
		typen[t] = true
	var liste := typen.keys()
	liste.sort()
	print("-- Maße (%d Typen, Toleranz ±%d %%, Fahrzeuge %.1f–%.1f × real)" % [liste.size(), int(tol * 100), fz_min, fz_max])
	for typ in liste:
		_messe(typ, ph)
	# 2) Epoche
	print("-- Epoche (Startjahr %d)" % s.startjahr)
	var akt: Dictionary = ep.fuer_jahr(s.startjahr)
	var frei: Array = akt["hebel"].get("haustypen_frei", [])
	var bis := int(akt["epoche"].get("bis", 9999))
	var ht: Dictionary = rw.get("haustypen", {})
	for typ in liste:
		if not ht.has(typ):
			continue
		var h: Dictionary = ht[typ]
		var wohn: bool = not (String(h.get("stufe", "")) in ["sonder", "neben"])
		var ab := int(h.get("ab_jahr", 0))
		var ok: bool = (not wohn or typ in frei) and ab <= bis
		if wohn or ab > 0:
			zeile("epoche.%s" % typ, "frei %d, ab ≤ %d" % [s.startjahr, bis], float(ab), NAN, ok, "hebel.haustypen_frei / haustypen.ab_jahr")
	# 3) Perf
	print("-- Perf")
	var live := DisplayServer.get_name() != "headless"
	var gate := {1: [1000000, 300], 3: [2900000, -1]}
	for n in [1, 2, 3, 4, 5]:
		s.setze_preset(n)
		for i in 6:
			await process_frame
		var z: Dictionary = s.zaehlung()
		# Gate: live (RenderingServer), sonst gezählt mit Sichtweiten-Culling (W2); ohne Culling als Info-Zeile
		var tris: int = z["live_dreiecke"] if live and z["live_dreiecke"] > 0 else z["dreiecke_sicht"]
		var dc: int = z["live_dc"] if live and z["live_dc"] > 0 else z["objekte_sicht"]
		var q := "RenderingServer (live)" if live and z["live_dreiecke"] > 0 else "gezählt mit Sichtweite (Mesh-Daten, DC ohne Schatten)"
		zeile("perf.%s.dreiecke_ohne_culling" % s.PRESET_NAMEN[n], "(Info)", z["dreiecke"], NAN, true, "gezählt ohne Frustum/Sichtweite (obere Schranke)")
		var nm: String = s.PRESET_NAMEN[n]
		if gate.has(n):
			var g: Array = gate[n]
			zeile("perf.%s.dreiecke" % nm, "≤ %d" % g[0], tris, (float(tris) / g[0] - 1.0) * 100.0, tris <= g[0], q)
			if g[1] > 0:
				zeile("perf.%s.draw_calls" % nm, "≤ %d" % g[1], dc, (float(dc) / g[1] - 1.0) * 100.0, dc <= g[1], q)
		else:
			zeile("perf.%s.dreiecke" % nm, "(Info)", tris, NAN, true, q)
			zeile("perf.%s.draw_calls" % nm, "(Info)", dc, NAN, true, q)
	# ungünstigster Übersichts-Abstand (live-Spitze bei 1,2–1,8 km, felix_perf_aufschluesselung.md)
	for d in [1800.0, 1200.0]:
		s.setze_preset(1)
		s.abstand = d
		s._kamera_anwenden()
		for i in 6:
			await process_frame
		var zz: Dictionary = s.zaehlung()
		var tt: int = zz["live_dreiecke"] if live and zz["live_dreiecke"] > 0 else zz["dreiecke_sicht"]
		var qq := "RenderingServer (live)" if live and zz["live_dreiecke"] > 0 else "gezählt mit Sichtweite"
		zeile("perf.Übersicht_%dm.dreiecke" % int(d), "≤ 1000000", tt, (float(tt) / 1000000.0 - 1.0) * 100.0, tt <= 1000000, qq)
	zeile("perf.ladezeit_ms", "≤ 3000", s.lade_ms, (s.lade_ms / 3000.0 - 1.0) * 100.0, s.lade_ms <= 3000.0, "prototyp_welt._ready")
	zeile("perf.ladezeit_wand_ms", "≤ 3000", wand_ms, (wand_ms / 3000.0 - 1.0) * 100.0, wand_ms <= 3000.0, "instantiate + 1 Frame")
	_csv()
	print("Messzeilen: %d, FAIL: %d" % [zeilen.size(), n_fail])
	quit(0 if n_fail == 0 else 1)


## AABB des Typs in Metern: ProtoPrefabs (TA, Welle 2) → res://proto/prefabs/<typ>.tscn → Platzhalter-Mesh.
## Fahrzeug-Kategorien (fuhrwerk_2_pferde, postkutsche_4_pferde) zusätzlich über ProtoPrefabs.fahrzeug(kat).
func _aabb(typ: String, ph) -> Array:
	var pm: Mesh = ph.prefab_mesh(typ)
	if pm != null:
		return [pm.get_aabb(), "prefab ProtoPrefabs.mesh_fuer(%s)" % typ]
	var kat := {"fuhrwerk_2_pferde": "fuhrwerk", "postkutsche_4_pferde": "postkutsche"}
	var scr: Script = ph.prefab_script()
	if scr != null and kat.has(typ):
		var d = scr.call("fahrzeug", kat[typ])
		if d is Dictionary and d.get("mesh") is Mesh:
			return [(d["mesh"] as Mesh).get_aabb(), "prefab ProtoPrefabs.fahrzeug(%s)" % kat[typ]]
	var pf := PREFABS + typ + ".tscn"
	if ResourceLoader.exists(pf):
		var n: Node = (load(pf) as PackedScene).instantiate()
		var bb := _merge_aabb(n, Transform3D.IDENTITY)
		n.free()
		return [bb, "prefab " + pf.get_file()]
	return [ph.mesh_fuer(typ).get_aabb(), "platzhalter (" + String(ph.masse(typ)["quelle"]) + ")"]


func _merge_aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var x := xf
	if n is Node3D:
		x = xf * (n as Node3D).transform
	if n is VisualInstance3D:
		var bb := x * (n as VisualInstance3D).get_aabb()
		out = bb
		first = false
	for c in n.get_children():
		var cb := _merge_aabb(c, x)
		if cb.size != Vector3.ZERO:
			out = cb if first else out.merge(cb)
			first = false
	return out


func _messe(typ: String, ph) -> void:
	var r := _aabb(typ, ph)
	var bb: AABB = r[0]
	var quelle: String = r[1]
	var lang := maxf(bb.size.x, bb.size.z)
	var quer := minf(bb.size.x, bb.size.z)
	var hoch := bb.size.y
	if ph.masse(typ)["kat"] == "unbekannt" and not quelle.begins_with("prefab"):
		zeile(typ, "Typ bekannt", 0.0, NAN, false, "unbekannter Typ (weder regelwerk noch import_faktoren)")
		return
	if ph.masse(typ)["kat"] == "flaeche":
		zeile(typ, "Typ bekannt (Fläche)", float(ph.anzahl.get(typ, 0)), NAN, true,
			"Bodenfläche, kein Maß-Soll (Ist = Anzahl Instanzen) | " + String(ph.masse(typ)["quelle"]))
		return
	var sk: Dictionary = rw.get("skalen", {})
	var pfad: String = SOLL_SKALEN.get(typ, "")
	if typ == "ruderboot":
		var real := float(rw.get("epochen", {}).get("stufen", {}).get("W1", {}).get("fahrzeuge", {}).get("ruderboot_dm", 45)) / 10.0
		_fahrzeug(typ, lang, [real, real], quelle + " | epochen.W1.fahrzeuge.ruderboot_dm")
		return
	if pfad.begins_with("fahrzeuge_dm/"):
		var f: Dictionary = sk["fahrzeuge_dm"][pfad.get_file()]
		var rl: Array = f.get("real_l", [f.get("l", 0), f.get("l", 0)])
		_fahrzeug(typ, lang, [float(rl[0]) / 10.0, float(rl[1]) / 10.0], quelle + " | skalen." + pfad + ".real_l")
		return
	if pfad.begins_with("baeume_m/"):
		var b: Array = sk["baeume_m"][pfad.get_file()]
		_band(typ + ".h", [float(b[0]), float(b[1])], hoch, quelle + " | skalen." + pfad)
		return
	if pfad.begins_with("gebaeude_m/") or pfad.begins_with("industrie_m/"):
		var g: Dictionary = sk[pfad.get_slice("/", 0)][pfad.get_file()]
		var gb: Array = g.get("haupt", [g.get("b", 0), g.get("t", 0)]) if g.get("haupt") is Array else [g.get("b", g.get("haupt_d", 0)), g.get("t", g.get("haupt_d", 0))]
		var sl := maxf(float(gb[0]), float(gb[1]))
		var sq := minf(float(gb[0]), float(gb[1]))
		var q := quelle + " | skalen." + pfad
		_band(typ + ".lang", [sl, sl], lang, q)
		_band(typ + ".quer", [sq, sq], quer, q)
		var hv: Variant = null
		for k in ["h", "turm", "landmarke_h"]:
			if g.has(k):
				hv = g[k]
				break
		if hv == null and g.has("first_dm"):
			hv = [float(g["first_dm"][0]) / 10.0, float(g["first_dm"][1]) / 10.0]
		if hv != null:
			_band(typ + ".h", hv if hv is Array else [float(hv), float(hv)], hoch, q)
		return
	if SOLL_M14.has(typ):
		var m: Array = SOLL_M14[typ]
		_band(typ + ".lang", [m[0], m[0]], lang, quelle + " | 16 §5 M14")
		_band(typ + ".quer", [m[1], m[1]], quer, quelle + " | 16 §5 M14")
		return
	var ht: Dictionary = rw.get("haustypen", {})
	if ht.has(typ) and not ht[typ].has("grundriss_m") and ht[typ].get("varianten_m") is Array:
		# Varianten (nebengebaeude [[18,10],[12,8],[6,4]]): Soll-Band = kleinste bis größte Variante, Ist = Grundmesh
		# (mittlere Variante); Instanzen werden auf ihr b × t skaliert.
		var lo_l := INF
		var hi_l := 0.0
		var lo_q := INF
		var hi_q := 0.0
		for v in ht[typ]["varianten_m"]:
			lo_l = minf(lo_l, maxf(v[0], v[1]))
			hi_l = maxf(hi_l, maxf(v[0], v[1]))
			lo_q = minf(lo_q, minf(v[0], v[1]))
			hi_q = maxf(hi_q, minf(v[0], v[1]))
		var qv := quelle + " | haustypen.%s.varianten_m (Band)" % typ
		_band(typ + ".lang", [lo_l, hi_l], lang, qv)
		_band(typ + ".quer", [lo_q, hi_q], quer, qv)
		return
	if ht.has(typ):
		var h: Dictionary = ht[typ]
		var g: Array = h.get("grundriss_m", (h.get("varianten_m", [[0, 0]]) as Array)[0])
		var q := quelle + " | haustypen." + typ + (".varianten_m[0]" if not h.has("grundriss_m") else "")
		_band(typ + ".lang", [maxf(g[0], g[1]), maxf(g[0], g[1])], lang, q)
		_band(typ + ".quer", [minf(g[0], g[1]), minf(g[0], g[1])], quer, q)
		var hv: Variant = h.get("turm_m", h.get("first_m", null))
		if hv != null:
			_band(typ + ".h", hv if hv is Array else [float(hv), float(hv)], hoch, q)
		return
	zeile(typ, "(kein Soll)", lang, NAN, true, quelle + " | Info: kein Soll im Regelwerk")


func _band(objekt: String, b: Array, ist: float, quelle: String) -> void:
	var lo := float(b[0])
	var hi := float(b[1])
	var abw := 0.0
	if ist < lo:
		abw = (ist / lo - 1.0) * 100.0
	elif ist > hi:
		abw = (ist / hi - 1.0) * 100.0
	var ok := ist >= lo * (1.0 - tol) - 1e-4 and ist <= hi * (1.0 + tol) + 1e-4
	var soll := ("%.1f" % lo) if is_equal_approx(lo, hi) else ("%.1f–%.1f" % [lo, hi])
	zeile(objekt, soll + " ±%d%%" % int(tol * 100), ist, abw, ok, quelle)


func _fahrzeug(typ: String, lang: float, real: Array, quelle: String) -> void:
	var lo := float(real[0]) * fz_min
	var hi := float(real[1]) * fz_max
	var mid := (float(real[0]) + float(real[1])) * 0.5
	var ok := lang >= lo - 1e-4 and lang <= hi + 1e-4
	zeile(typ + ".l", "%.2f–%.2f (%.1f–%.1f×)" % [lo, hi, fz_min, fz_max], lang, (lang / mid - 1.0) * 100.0, ok, quelle)


func _csv() -> void:
	var pfad := ProjectSettings.globalize_path("res://").path_join("../sprints/s8/design-sprint/phase4/proto_mass.csv").simplify_path()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--csv="):
			pfad = a.substr(6)
	DirAccess.make_dir_recursive_absolute(pfad.get_base_dir())
	var f := FileAccess.open(pfad, FileAccess.WRITE)
	if f == null:
		push_error("CSV nicht schreibbar: " + pfad)
		return
	f.store_line("Objekt;Soll;Ist;Abw. %;OK;Quelle")
	for z in zeilen:
		f.store_line(";".join(PackedStringArray(z)))
	f.close()
	print("CSV: ", pfad)
