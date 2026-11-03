extends SceneTree
## Phase 4 Welle 2 (Felix): Messprotokoll Easing E1–E8 (15_regelwerk_v1_1 §B5, 16 §5), headless.
##   godot --headless --path slice -s res://tests/proto_easing_test.gd [-- --csv=<pfad>]
## Teil A: 10 synthetische Testrouten (Dorfstraße R 25 m, 90°-Ecken und Feld-Treppen wie die Sim heute) auf flachem
##         Gelände, je Route ein Fuhrwerk oder eine Postkutsche (abwechselnd), 900 Ticks, 60 Frames/s.
## Teil B: die echte Kette der Szene (Farm → Mühle → Dorf + Postkutsche, proto_sim.gd), 3000 Ticks.
## Teil C: E8 Kosten mit 10 Fahrzeugen in der Szene (proto_fahrzeuge.frame inkl. MultiMesh-Schreiben).
## Messgrößen je Frame (Easing an; Wende am Linienende ausgenommen und gezählt, 15 §B4 Schritt 7):
##   E1 Prüfsumme an = aus = ohne Darstellung (bitgleich)
##   E2 |Δp| ≤ 1,2 · v_bild_max · Δt + 0,05 m      (v_bild_max = (1 + Überhöhung) · v_sim)
##   E3 Gierrate ≤ ω_max (Fuhrwerk 270°/s, Kutsche 240°/s)
##   E4 Querbeschleunigung v_bild² · κ ≤ 1,25 · Profilwert (Kurvenfaktor · v_sim)² / R_Wegtyp
##   E5 Halt: Bild steht ≤ 0,1 m am Sim-Haltepunkt, ≤ W/2 Ticks nach „Easing aus“ (= Sim-Bild heute)
##   E6 Zeitversatz |τ| ≤ W/2 Ticks: R(t − τ) = Bild(t), R = heutige Sim-Darstellung (lineare Mischung der Ticks)
##   E7 Basisspalten-Norm 1 ± 1 % (an); zum Vergleich „aus“ (FAST-Mischung) als Info
##   E8 frame() ≤ 0,5 ms p95 bei 10 Fahrzeugen

const Strassenband := preload("res://proto/proto_strassenband.gd")
const ProtoSim := preload("res://proto/proto_sim.gd")
const Fahrzeuge := preload("res://proto/proto_fahrzeuge.gd")
const Epochen := preload("res://proto/proto_epochen.gd")
const SimWorld := preload("res://core/sim_world.gd")
const SZENE := "res://proto/prototyp_welt.tscn"
const FPS := 60.0

var rw: Dictionary = {}
var n_ok := 0
var n_fail := 0
var zeilen: Array = []


func _initialize() -> void:
	_run.call_deferred()


var nur_info := false


func pruef(id: String, ok: bool, text: String, wert := "") -> void:
	if nur_info:
		zeilen.append([id, text, wert, "Info " + ("grün" if ok else "rot")])
		print("  %s %-4s %s %s" % ["info" if ok else "INFO-ROT", id, text, wert])
		return
	if ok:
		n_ok += 1
	else:
		n_fail += 1
	zeilen.append([id, text, wert, "ja" if ok else "NEIN"])
	print("  %s %-4s %s %s" % ["OK  " if ok else "FAIL", id, text, wert])


static func flach(_x: float, _z: float) -> float:
	return 40.0


## 10 Testrouten (Feldmitten, 25-m-Raster), jede um 1 km versetzt.
func testrouten() -> Array:
	var r: Array = []
	r.append([[0, 0], [250, 0], [250, 250]])                                         # L
	r.append([[0, 0], [200, 0], [200, 150], [0, 150]])                               # U
	var tr: Array = [[0, 0]]
	for i in 8:
		tr.append([25 * (i + 1), 25 * i])
		tr.append([25 * (i + 1), 25 * (i + 1)])
	r.append(tr)                                                                     # Treppe 1:1
	var t2: Array = [[0, 0], [100, 0]]
	for i in 4:
		t2.append([125 + 25 * i, 25 * i])
		t2.append([125 + 25 * i, 25 * (i + 1)])
	t2.append([400, 100])
	r.append(t2)                                                                     # Gerade, Treppe, Gerade
	r.append([[0, 0], [150, 0], [150, 150], [300, 150]])                             # Z
	r.append([[0, 0], [400, 0], [400, 300], [700, 300]])                             # lang, 2 Ecken
	var t3: Array = [[0, 0]]
	for i in 5:
		t3.append([50 * (i + 1), 25 * i])
		t3.append([50 * (i + 1), 25 * (i + 1)])
	r.append(t3)                                                                     # Treppe 2:1
	r.append([[0, 0], [0, 200], [200, 200], [200, 50]])                              # Rechts-Links
	r.append([[0, 0], [125, 0], [125, 25], [150, 25], [150, 50], [300, 50], [300, 300]])   # gemischt
	r.append([[0, 0], [500, 0]])                                                     # Gerade (Kontrolle)
	var out: Array = []
	for i in r.size():
		var pts: Array = []
		for p in r[i]:
			pts.append([float(p[0]) + 1000.0 * i + 12.5, float(p[1]) + 12.5])
		out.append({"typ": "dorfstrasse", "punkte": pts, "breite_m": 6.0})
	return out


## Läuft ps über ticks, misst E2–E7 je Frame. Rückgabe: Kennzahlen.
func messen(ps, ticks: int, an := true) -> Dictionary:
	var m := {"e2_max": 0.0, "e2_fail": 0, "e3_max": 0.0, "e3_fail": 0, "e4_max": 0.0, "e4_quote": 0.0, "e4_fail": 0,
		"e5_max": 0.0, "e5_n": 0, "e5_fail": 0, "e5_pos": 0.0, "e6_max": 0.0, "e6_fail": 0, "e7_min": 9.0, "e7_max": 0.0,
		"e7_fail": 0, "wende": 0, "frames": 0, "aus_norm_min": 9.0, "v_max": 0.0}
	var n: int = ps.fahrzeuge.size()
	var alt_pos: Array = []
	var alt_g: Array = []
	var hist: Array = []             # je Fahrzeug [[t, R], …] (Ring, letzte 40 Frames)
	var halt: Array = []             # je Fahrzeug [z_stop, t_ref] offen oder []
	var st_alt: Array = []
	for i in n:
		alt_pos.append(null)
		alt_g.append(0.0)
		hist.append([])
		halt.append([])
		st_alt.append(SimWorld.S_WARTET_LADUNG)
	var acc := 0.0
	var dt := TICKS_PRO_FRAME()
	var t := 0.0
	var frames := int(ticks / dt)
	for fr in frames:
		acc += dt
		t += dt
		while acc >= 1.0:
			ps.tick()
			acc -= 1.0
			for i in n:
				var f: Dictionary = ps.fahrzeuge[i]
				var si: int = ps.sim.slot_of(f["vid"])
				var st: int = ps.sim.v_state[si]
				if st_alt[i] == SimWorld.S_UNTERWEGS and st != SimWorld.S_UNTERWEGS:
					halt[i] = [f["zustand"].z_akt, t - acc + 1.0]     # „aus“ erreicht den Halt beim nächsten Tick
				st_alt[i] = st
		for i in n:
			var f: Dictionary = ps.fahrzeuge[i]
			var z = f["zustand"]
			var prof = f["profil"]
			z.frame(acc, dt, an)
			if not an:
				m["aus_norm_min"] = minf(m["aus_norm_min"], minf(z.basis.x.length(), z.basis.z.length()))
				continue
			var r := lerpf(z.z_vor, z.z_akt, acc)
			var hi: Array = hist[i]
			hi.append([t, r])
			if hi.size() > 60:
				hi.pop_front()
			# E7
			for c in [z.basis.x, z.basis.y, z.basis.z]:
				var nn: float = (c as Vector3).length()
				m["e7_min"] = minf(m["e7_min"], nn)
				m["e7_max"] = maxf(m["e7_max"], nn)
				if absf(nn - 1.0) > 0.01:
					m["e7_fail"] += 1
			# E5
			if not halt[i].is_empty():
				var zs: float = halt[i][0]
				if absf(z.zb - zs) <= 0.1 and z.vb <= 1e-6:
					var verz: float = t - float(halt[i][1])
					if verz / (prof.w * 0.5) > m["e5_max"]:
						m["e5_wo"] = "%s t %.1f" % [f["name"], t]
					m["e5_max"] = maxf(m["e5_max"], verz / (prof.w * 0.5))
					m["e5_n"] += 1
					if verz > prof.w * 0.5 + 1e-3:
						m["e5_fail"] += 1
					halt[i] = []
				elif t - float(halt[i][1]) > prof.w * 3:
					m["e5_fail"] += 1
					m["e5_wo"] = "%s t %.1f TIMEOUT zb %.2f zs %.2f vb %.2f" % [f["name"], t, z.zb, zs, z.vb]
					halt[i] = []
			# E6: τ mit R(t − τ) = Bildposition (Fahrstrecke nach φ), beidseitig
			var e: Array = z._leg_bei(z.zb)
			var zp: float = float(e[0]) + z.p_bild
			var tau := 0.0
			if zp < r - 1e-3:
				tau = INF
				for k in range(hi.size() - 1, 0, -1):
					var a: Array = hi[k - 1]
					var b: Array = hi[k]
					if a[1] <= zp + 1e-6:
						var den: float = b[1] - a[1]
						var tt: float = b[0] if den < 1e-9 else lerpf(a[0], b[0], (zp - a[1]) / den)
						tau = t - tt
						break
			elif zp > r + 1e-3:
				var vr := maxf(z.z_akt - z.z_vor, prof.v_nom)
				tau = (zp - r) / vr
			if not is_inf(tau):
				if absf(tau) / (prof.w * 0.5) > m["e6_max"]:
					m["e6_wo"] = "%s t %.1f tau %.2f zp %.1f r %.1f" % [f["name"], t, tau, zp, r]
				m["e6_max"] = maxf(m["e6_max"], absf(tau) / (prof.w * 0.5))
				var kk: String = "e6_" + str(f["name"])
				m[kk] = maxf(m.get(kk, 0.0), absf(tau) / (prof.w * 0.5))
				if absf(tau) > prof.w * 0.5 + 1e-3:
					m["e6_fail"] += 1
			if z.in_wende:
				m["wende"] += 1
				alt_pos[i] = z.pos
				alt_g[i] = z.gier
				continue
			# E2, E3
			if alt_pos[i] != null:
				var dp: float = (z.pos - alt_pos[i]).length()
				var lim: float = 1.2 * (1.0 + prof.ueb) * prof.v_nom * dt + 0.05
				m["e2_max"] = maxf(m["e2_max"], dp / lim)
				if dp > lim:
					m["e2_fail"] += 1
				var om := absf(wrapf(z.gier - alt_g[i], -PI, PI)) / (dt / 10.0)
				if om / (prof.omega_max * 10.0) > m["e3_max"]:
					m["e3_wo"] = "%s t %.1f leg %d p %.1f/%.0f" % [f["name"], t, z.leg_bild, z.p_bild, f["legs"][z.leg_bild].laenge]
				m["e3_max"] = maxf(m["e3_max"], rad_to_deg(om) / rad_to_deg(prof.omega_max * 10.0))
				if om > prof.omega_max * 10.0 * 1.0001:
					m["e3_fail"] += 1
			alt_pos[i] = z.pos
			alt_g[i] = z.gier
			# E4 (analytisch: Bildtempo² · Krümmung der Spur am Bildpunkt)
			var rl = f["legs"][z.leg_bild]
			var kap: float = rl.kappa_bei(z.p_bild)
			var aq: float = z.v_p * z.v_p * absf(kap)
			var ref: float = prof.a_quer_ref(rl.r_typ[mini(int(z.p_bild), rl.r_typ.size() - 1)])
			m["e4_max"] = maxf(m["e4_max"], aq * 100.0)
			if aq / (1.25 * ref) > m["e4_quote"]:
				m["e4_wo"] = "%s t %.1f leg %d p %.1f v %.1f kap %.4f" % [f["name"], t, z.leg_bild, z.p_bild, z.v_p, kap]
			m["e4_quote"] = maxf(m["e4_quote"], aq / (1.25 * ref))
			if aq > 1.25 * ref:
				m["e4_fail"] += 1
			m["v_max"] = maxf(m["v_max"], z.v_p / prof.v_nom)
			m["frames"] += 1
	return m


func TICKS_PRO_FRAME() -> float:
	return 10.0 / FPS


func bericht(teil: String, m: Dictionary) -> void:
	print("  [%s] Frames %d, Wende-Frames ausgenommen %d, v_bild max %.2f × v_sim" % [teil, m["frames"], m["wende"], m["v_max"]])
	for k in ["e3_wo", "e4_wo", "e5_wo", "e6_wo"]:
		if m.has(k):
			print("    schlimmster %s: %s" % [k, m[k]])
	var e6z: Array = []
	for k in m:
		if String(k).begins_with("e6_") and k != "e6_max" and k != "e6_fail" and k != "e6_wo":
			e6z.append("%s %.2f" % [String(k).substr(3), m[k]])
	print("    E6 je Fahrzeug (× W/2): " + ", ".join(PackedStringArray(e6z)))
	pruef("E2", m["e2_fail"] == 0, "%s kein Positionssprung" % teil, "max %.2f × Grenze, %d Verstöße" % [m["e2_max"], m["e2_fail"]])
	pruef("E3", m["e3_fail"] == 0, "%s Gierrate ≤ ω_max" % teil, "max %.2f × ω_max, %d Verstöße" % [m["e3_max"], m["e3_fail"]])
	pruef("E4", m["e4_fail"] == 0, "%s Querbeschleunigung ≤ 1,25 × Profilwert" % teil, "max %.0f m/s² = %.2f × Grenze, %d Verstöße" % [m["e4_max"], m["e4_quote"], m["e4_fail"]])
	pruef("E5", m["e5_fail"] == 0 and m["e5_n"] > 0, "%s Halt ≤ 0,1 m, ≤ W/2 Ticks" % teil, "%d Halte, max %.2f × W/2, %d Verstöße" % [m["e5_n"], m["e5_max"], m["e5_fail"]])
	pruef("E6", m["e6_fail"] == 0, "%s Zeitversatz ≤ W/2" % teil, "max %.2f × W/2, %d Verstöße" % [m["e6_max"], m["e6_fail"]])
	pruef("E7", m["e7_fail"] == 0, "%s keine Stauchung (Norm 1 ± 1 %%)" % teil, "Norm %.4f–%.4f" % [m["e7_min"], m["e7_max"]])


func synth_sim(wege: Array, parent: Node3D):
	var sb = Strassenband.new()
	sb.konfig_aus_regelwerk(rw)
	sb.bauen(parent, wege, Callable(self, "flach"), {})
	var ps = ProtoSim.new(rw)
	ps.graph_bauen(sb)
	for i in wege.size():
		var p: Array = wege[i]["punkte"]
		ps.testlinie("fuhrwerk" if i % 2 == 0 else "postkutsche", Vector2(p[0][0], p[0][1]), Vector2(p[-1][0], p[-1][1]))
	return ps


func _run() -> void:
	print("proto_easing_test")
	rw = Epochen.laden().regelwerk
	var wurzel := Node3D.new()
	root.add_child(wurzel)
	# ---------------- Teil A: synthetische Routen
	var wege := testrouten()
	var psA = synth_sim(wege, wurzel)
	print("  Teil A: %d Routen, %d Fahrzeuge, Fehler %s" % [wege.size(), psA.fahrzeuge.size(), str(psA.fehler)])
	for f in psA.fahrzeuge:
		print("    %-14s Sim %.0f m, Fahrlinie %.0f m, Skala %.3f, f_min %.2f" % [f["name"], float(f["sim_mm"]) / psA.mm_pro_m, f["legs"][0].laenge, f["legs"][0].skala, Array(f["legs"][0].f).min()])
	pruef("A0", psA.fahrzeuge.size() == wege.size() and psA.fehler.is_empty(), "10 Testrouten als Sim-Linien", str(psA.fehler))
	var mA := messen(psA, 900, true)
	bericht("A", mA)
	# E7 Vergleich: heutiges Bild (aus) auf denselben Routen
	var psA2 = synth_sim(wege, wurzel)
	var mA2 := messen(psA2, 900, false)
	print("  Info E7 aus (heutiges Spiel, FAST-Mischung): kleinste Basisnorm %.3f (Schuhkarton)" % mA2["aus_norm_min"])
	zeilen.append(["E7-aus", "Info: Basisnorm heute (Easing aus, Treppen/Ecken)", "%.3f" % mA2["aus_norm_min"], "Info"])
	# E1: Prüfsumme an = aus = ohne Darstellung
	var psA3 = synth_sim(wege, wurzel)
	while psA3.sim.tick_count < psA.sim.tick_count:
		psA3.tick()
	var c_an: int = psA.pruefsumme()
	var c_aus: int = psA2.pruefsumme()
	var c_ohne: int = psA3.pruefsumme()
	pruef("E1", c_an == c_aus and c_aus == c_ohne and psA.sim.tick_count == psA3.sim.tick_count, "A Prüfsumme an = aus = ohne Darstellung", "%d" % c_an)
	# ---------------- Teil B: Szene, echte Kette
	var s: Node = (load(SZENE) as PackedScene).instantiate()
	s.sim_aus = true
	root.add_child(s)
	await process_frame
	var orte = JSON.parse_string(FileAccess.get_file_as_string(s.datei("proto_orte.json")))
	var psB = ProtoSim.new(s.regelwerk)
	psB.graph_bauen(s.strassen)
	psB.kette_aufbauen(orte)
	var psB2 = ProtoSim.new(s.regelwerk)
	psB2.graph_bauen(s.strassen)
	psB2.kette_aufbauen(orte)
	var psB3 = ProtoSim.new(s.regelwerk)
	psB3.graph_bauen(s.strassen)
	psB3.kette_aufbauen(orte)
	pruef("B0", psB.kette_ok, "Szene: Kette Farm → Mühle → Dorf + Postkutsche", str(psB.fehler))
	var mB := messen(psB, 3000, true)
	bericht("B", mB)
	var mB2 := messen(psB2, 3000, false)
	while psB3.sim.tick_count < psB.sim.tick_count:
		psB3.tick()
	var b_an: int = psB.pruefsumme()
	pruef("E1", b_an == psB2.pruefsumme() and b_an == psB3.pruefsumme(), "B Prüfsumme Kette an = aus = ohne Darstellung (3000 Ticks, %d Lieferungen)" % psB.lieferungen.size(), "%d" % b_an)
	# ---------------- Teil C: E8 Kosten, 10 Fahrzeuge (3 + 7 Bench) in der Szene
	var psC = ProtoSim.new(s.regelwerk)
	psC.graph_bauen(s.strassen)
	psC.kette_aufbauen(orte, 7)
	var fz = Fahrzeuge.new()
	s.add_child(fz)
	fz.bauen(psC, s.regelwerk)
	var proben := PackedFloat32Array()
	var acc := 0.0
	var dt := TICKS_PRO_FRAME()
	for fr in 1800:
		acc += dt
		while acc >= 1.0:
			psC.tick()
			acc -= 1.0
		fz.frame(acc, dt)
		if fr >= 60:
			proben.append(fz.frame_usec)
	var arr := Array(proben)
	arr.sort()
	var p95: float = arr[int(arr.size() * 0.95)] / 1000.0
	var mittel := 0.0
	for x in arr:
		mittel += x
	mittel /= maxf(arr.size(), 1) * 1000.0
	pruef("E8", psC.fahrzeuge.size() == 10 and p95 <= 0.5, "Kosten frame() bei %d Fahrzeugen ≤ 0,5 ms (p95)" % psC.fahrzeuge.size(),
		"Mittel %.3f ms, p95 %.3f ms, max %.3f ms (headless, GDScript)" % [mittel, p95, arr[-1] / 1000.0])
	# ---------------- Variante (Info, kein Gate): Kurvenfaktor min Fuhrwerk und Postkutsche 0,70 statt 0,55 / 0,60
	# Zeigt, ob E5/E6 an den Profildaten hängen (Defizit Kurvenzone > Überhöhung +15 % kann einholen).
	nur_info = true
	var rv: Dictionary = rw.duplicate(true)
	rv["fahrzeug_easing"]["kategorien"]["fuhrwerk"]["kurvenfaktor_min_promille"] = 700
	rv["fahrzeug_easing"]["kategorien"]["postkutsche"]["kurvenfaktor_min_promille"] = 700
	var rw_alt := rw
	rw = rv
	var psV = synth_sim(wege, wurzel)
	bericht("A-Var", messen(psV, 900, true))
	rw = rw_alt
	var rvs: Dictionary = s.regelwerk.duplicate(true)
	rvs["fahrzeug_easing"]["kategorien"]["fuhrwerk"]["kurvenfaktor_min_promille"] = 700
	rvs["fahrzeug_easing"]["kategorien"]["postkutsche"]["kurvenfaktor_min_promille"] = 700
	var psVB = ProtoSim.new(rvs)
	psVB.graph_bauen(s.strassen)
	psVB.kette_aufbauen(orte)
	bericht("B-Var", messen(psVB, 3000, true))
	nur_info = false
	_csv()
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)


func _csv() -> void:
	var pfad := ProjectSettings.globalize_path("res://").path_join("../sprints/s8/design-sprint/phase4/proto_easing.csv").simplify_path()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--csv="):
			pfad = a.substr(6)
	var f := FileAccess.open(pfad, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("Prüfung;Text;Wert;OK")
	for z in zeilen:
		f.store_line(";".join(PackedStringArray(z)))
	f.close()
	print("CSV: ", pfad)
