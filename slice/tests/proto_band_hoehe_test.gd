extends SceneTree
## Phase 4 Welle 2 (Felix): Sinkt das Straßenband ins TA-Gelände ein? (Befund W1 #10, Auftrag W2 Punkt 3)
##   godot --headless --path slice -s res://tests/proto_band_hoehe_test.gd
## Je Band-Dreieck der Fahrbahn (|UV.x| ≤ 1, ohne Schürze/Bankett/Graben, ohne Brückendeck) 10 Stichproben
## (Ecken, Kantenmitten, Schwerpunkt, Drittelpunkte): Gelände hoehe_at (TA: exakt die gerenderten Dreiecke) minus
## Bandhöhe. > 0 heißt: Gelände verdeckt das Band. Grenze: kein Punkt > 0,05 m (Band liegt 0,15 m über dem Gelände).

const SZENE := "res://proto/prototyp_welt.tscn"
const GRENZE := 0.05

var n_ok := 0
var n_fail := 0


func _initialize() -> void:
	_run.call_deferred()


func pruef(ok: bool, text: String) -> void:
	if ok:
		n_ok += 1
	else:
		n_fail += 1
	print("  %s %s" % ["OK  " if ok else "FAIL", text])


func _run() -> void:
	print("proto_band_hoehe_test")
	var s: Node = (load(SZENE) as PackedScene).instantiate()
	s.sim_aus = true
	root.add_child(s)
	await process_frame
	pruef(s.terrain_quelle == "TA", "Gelände = TA (%s)" % s.terrain_quelle)
	var bary := [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0.5, 0.5, 0), Vector3(0, 0.5, 0.5),
		Vector3(0.5, 0, 0.5), Vector3(1, 1, 1) / 3.0, Vector3(2, 1, 0) / 3.0, Vector3(0, 2, 1) / 3.0, Vector3(1, 0, 2) / 3.0]
	var gesamt := 0
	var ueber := 0
	var max_d := -INF
	var wo := ""
	var je_weg := {}
	for mi in s.strassen.meshes:
		if not String(mi.name).begins_with("Weg_"):
			continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		var wmax := -INF
		var wn := 0
		for t in range(0, idx.size(), 3):
			var a := idx[t]
			var b := idx[t + 1]
			var c := idx[t + 2]
			if absf(uv[a].x) > 1.001 or absf(uv[b].x) > 1.001 or absf(uv[c].x) > 1.001:
				continue
			# Brückendeck/Rampe auslassen (Band deutlich über Gelände)
			var hg := float(s.hoehe_at(v[a].x, v[a].z))
			if v[a].y - hg > 1.5:
				continue
			for w in bary:
				var p: Vector3 = v[a] * w.x + v[b] * w.y + v[c] * w.z
				var d := float(s.hoehe_at(p.x, p.z)) - p.y
				gesamt += 1
				if d > GRENZE:
					ueber += 1
					wn += 1
				if d > max_d:
					max_d = d
					wo = "%s bei (%.1f, %.1f)" % [mi.name, p.x, p.z]
				wmax = maxf(wmax, d)
		je_weg[String(mi.name)] = [wmax, wn]
	for k in je_weg:
		print("    %-22s max Gelände über Band %+.3f m, Punkte > %.2f m: %d" % [k, je_weg[k][0], GRENZE, je_weg[k][1]])
	pruef(ueber == 0, "Fahrbahn nirgends unter dem Gelände: max %+.3f m (%s), %d von %d Punkten > %.2f m" % [max_d, wo, ueber, gesamt, GRENZE])
	print("Prüfungen OK: %d, FAIL: %d" % [n_ok, n_fail])
	quit(0 if n_fail == 0 else 1)
