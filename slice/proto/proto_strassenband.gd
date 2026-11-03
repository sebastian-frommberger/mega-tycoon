extends RefCounted
## Phase 4 Welle 1 (Felix): Straßenband für die Prototyp-Welt (15_regelwerk_v1_1 K28, 12 strasse_gleis_bild).
## Aus einer Polylinie (lokale Meter, [[x, z], …], z. B. Feldmitten der Sim) entsteht ein durchgehendes, geglättetes
## Band ohne Kachelfugen, das auf dem Gelände liegt (hoehe_fn = ProtoTerrain.hoehe_at). Ein Mesh je Weg, dazu
## Kreuzungsstücke (Knotenflächen) und Steinbogenbrücken (Platzhalter aus Boxen). Jedes Band liefert eine FAHRLINIE
## (innere Klasse Fahrlinie), die das Easing in Welle 2 benutzt.
##
## Glättung (Standard "bogen"):
##   0. Treppen (Kanten ≤ 40 m) werden durch Kantenmittelpunkte ersetzt (liegen bei regelmäßiger Treppe auf der Diagonale).
##   1. Douglas-Peucker mit Toleranz max(ortsstrasse_abweichung.m_max, 9 m): Feldmitten-Treppen werden Diagonalen
##      (mind. 9 m, weil die halbe Feldstufe am Treppenanfang 8,84 m neben der Diagonale liegt).
##      Entscheidung PO (Integration W2): Kurvenradius Dorfstraße 25 m bleibt, Fahrlinie und Band dürfen bis 11 m von
##      der Feldmitte abweichen (m_max 11 statt 8, regelwerk.json). Damit passt der Bogenscheitel einer 90°-Ecke
##      (R·(√2 − 1) = 10,4 m) und Treppen 2:1 werden ohne Zickzack geglättet.
##      Kreuzungspunkte sind fest (bleiben erhalten, Abweichung dort ≤ 1 m).
##   2. Jede Ecke bekommt einen Kreisbogen mit dem Kurvenradius des Wegtyps (Dorfstraße 25 m, Chaussee 50 m), begrenzt
##      auf 0,45 × kürzere Nachbarkante (gleiche Regel wie der Easing-Fallback 15 §B4). Ergebnis: G1-stetig, Radius bekannt.
##   Alternative "catmull" (centripetal Catmull-Rom durch die DP-Punkte), Schalter glaettung; kein garantierter Radius.
##
## Querschnitt je Typ (aus regelwerk.skalen.wege_dm, breite_m aus proto_wege.json hat Vorrang für die Trasse):
##   Chaussee: Fahrbahn 6 m, Trasse 11 m inkl. Bankett und Graben (Graben 0,5 m tief); Dorfstraße 6; Gasse 5; Feldweg 3,5.
##   Außen je Seite eine Schürze 0,6 m nach unten (keine Kante zum Gelände sichtbar).
##
## Brücke: Abschnitte, deren Fahrlinie über Rinne (proto_fluss.u8 Bit 1) läuft (Lauf ≥ 10 m; Bach = Durchlass, keine
##   Brücke, 12 bruecken.bach), oder Wege mit typ "bruecke". Deck zwischen den Ufern (Wasser ± 12,5 m),
##   Rampen mindestens bis ± 25 m (1 Rampenfeld je Seite, 12 bruecken), länger, wenn die steilste Rampenstelle sonst
##   > 8 % wäre. Deckhöhe = max(Ufer, Pegel + 4,5 m lichte Höhe + 1 m Deck); Segmentbögen ≈ stein_bogen_m (15 m),
##   Kämpfer knapp über Pegel. Deckbreite = Fahrbahn + 2 × 0,8 m Rand + 2 × 0,5 m Brüstung; Bankett/Graben laufen auf
##   der Rampe auf den Brückenrand zusammen. Kenney-Castle-Bögen ersetzen die Boxen in Welle 2.
##
## ---- Schnittstelle Fahrlinie (für Easing Welle 2, stabil) ----
##   fl.laenge                      Bogenlänge in m (horizontal gemessen, wie die Sim-Felder)
##   fl.strecke_punkt(s) -> Vector3 Punkt auf der Bandmitte (y = Fahrbahnoberfläche inkl. Brückendeck), O(1)
##   fl.strecke_richtung(s)         horizontale Einheits-Tangente (Vector3, y = 0)
##   fl.strecke_gier(s) -> float    Gierwinkel atan2(dx, dz) wie fleet_soa (Modell-Vorne = +z)
##   fl.strecke_kruemmung(s)        vorzeichenbehaftet 1/m, + = Linkskurve (von oben gegen den Uhrzeigersinn)
##   fl.spur_punkt(s, versatz_m)    Rechtsverkehr: + = rechts in Fahrtrichtung (Spur-Versatz aus fahrzeug_easing)
##   fl.naechstes_s(p) -> float     Projektion eines Punktes auf die Fahrlinie (Sim-Knoten → s)
##   fl.anker[k], fl.anker_s[k]     k-ter Ankerpunkt (Eingabepunkt/Feldmitte, plus eingefügte Kreuzungspunkte) und sein s
##                                  → Sim-Kante k..k+1 = Spline-Abschnitt (Sim-Knoten = Anker, gemeinsame Anker = Kreuzung)
##   fl.sim_auf_s(k, anteil)        K28 längentreu-proportional: Sim-Kante k mit Anteil 0..1 → s
##   fl.r_min                       kleinster gebauter Bogenradius (m), Prüfgröße E4
##   Tabelle: gleichmäßig je DS = 1 m (punkte, gier), Lookup O(1) per Index; Speicher ≈ 16 B/m.

const SHADER := preload("res://proto/proto_strasse.gdshader")
const Y_OFF := 0.15                  # Band über Gelände (m)
const SCHUERZE_M := 0.6
const SCHRITT_GERADE_M := 8.0        # Mesh-Querschnitte auf Geraden (Gelände-Raster 25 m)
const BOGEN_SEHNE_M := 2.0
const BOGEN_WINKEL := deg_to_rad(5.0)
const WASSER_LAUF_MIN_M := 10.0
const UFER_M := 12.5
const RAMPE_M := 25.0
const LICHTE_M := 4.5
const DECK_M := 1.0
const BUCKEL_M := 0.5
const RAMPE_STEIGUNG := 0.08         # steilste Rampenstelle (Annahme Felix; strasse_hart 20 %, Generator Chaussee 5 %)
const KNOTEN_FANG_M := 4.0
const BRUECKE_RAND_M := 0.8          # Kiesrand zwischen Fahrbahn und Brüstung
const STUFE_MAX_M := 55.0            # Kante ≤ 2,2 Felder = Treppenstufe (W2: auch 2:1-Treppen, vorher 40 m)
const DP_MIN_M := 9.0                # halbe Feldstufe liegt 12,5/√2 = 8,84 m neben der Diagonale (8-m-Regel reicht nicht)

## Querschnitt je Typ: fahrbahn, trasse (m), radius (m). Werte aus regelwerk (konfig_aus_regelwerk), sonst diese Annahmen.
var profile := {
	"chaussee": {"fahrbahn": 6.0, "trasse": 11.0, "radius": 50.0, "graben": true},
	"dorfstrasse": {"fahrbahn": 6.0, "trasse": 6.0, "radius": 25.0, "graben": false},
	"gasse": {"fahrbahn": 5.0, "trasse": 5.0, "radius": 10.0, "graben": false},      # Radius Annahme Felix
	"feldweg": {"fahrbahn": 3.5, "trasse": 3.5, "radius": 25.0, "graben": false},    # Radius Annahme Felix (W2: 25 m, E3)
	"bruecke": {"fahrbahn": 6.0, "trasse": 6.0, "radius": 25.0, "graben": false},
}
var abweichung_max_m := 11.0          # regelwerk strasse_gleis_bild.ortsstrasse_abweichung.m_max (PO W2: 11 m)
var bogen_m := 15.0
var wasser_pegel_m := 36.4
var glaettung := "bogen"

var fahrlinien: Array = []           # je Weg (Index wie proto_wege.json)
var knoten: Array = []               # [{pos: Vector3, typ: "kreuzung"|"stoss", radius, arme: [[weg, s], …]}]
var bruecken: Array = []             # [{weg, s0, s1, s_wasser0, s_wasser1, deck_m, boegen, laenge}]
var meshes: Array = []               # alle erzeugten MeshInstance3D
var warnungen: Array = []
var hoehe_funktion: Callable = Callable()  # ProtoTerrain.hoehe_at (Fix-Pass W2: Quergefälle der Fahrzeuge am Band)
var _mat: ShaderMaterial
var _mat_stein: StandardMaterial3D


class Fahrlinie extends RefCounted:
	const DS := 1.0
	var weg_index := -1
	var typ := ""
	var fahrbahn_m := 0.0
	var trasse_m := 0.0
	var laenge := 0.0
	var punkte := PackedVector3Array()     # s = k × DS, letzter Punkt bei s = laenge
	var gier := PackedFloat32Array()
	var anker := PackedVector2Array()      # Ankerpunkte (Eingabepunkte + eingefügte Kreuzungspunkte), Sim-Knoten
	var anker_s := PackedFloat32Array()
	var r_min := INF

	func _idx(s: float) -> Vector2:
		var n := punkte.size()
		if n < 2:
			return Vector2(0, 0)
		s = clampf(s, 0.0, laenge)
		var i := mini(int(s / DS), n - 2)
		var seg := DS if i < n - 2 else maxf(laenge - i * DS, 1e-6)
		return Vector2(i, clampf((s - i * DS) / seg, 0.0, 1.0))

	func strecke_punkt(s: float) -> Vector3:
		if punkte.size() < 2:
			return punkte[0] if punkte.size() == 1 else Vector3.ZERO
		var t := _idx(s)
		var i := int(t.x)
		return punkte[i].lerp(punkte[i + 1], t.y)

	func strecke_richtung(s: float) -> Vector3:
		var g := strecke_gier(s)
		return Vector3(sin(g), 0.0, cos(g))

	func strecke_gier(s: float) -> float:
		if gier.size() < 2:
			return 0.0
		var t := _idx(s)
		var i := int(t.x)
		return gier[i] + wrapf(gier[i + 1] - gier[i], -PI, PI) * t.y

	func strecke_kruemmung(s: float) -> float:
		var h := 1.5
		var a := clampf(s - h, 0.0, laenge)
		var b := clampf(s + h, 0.0, laenge)
		if b - a < 1e-3:
			return 0.0
		return wrapf(strecke_gier(b) - strecke_gier(a), -PI, PI) / (b - a)

	func spur_punkt(s: float, versatz_m: float) -> Vector3:
		var d := strecke_richtung(s)
		return strecke_punkt(s) + Vector3(-d.z, 0.0, d.x) * versatz_m

	func naechstes_s(p: Vector3) -> float:
		var best := INF
		var bs := 0.0
		var q := Vector2(p.x, p.z)
		for k in punkte.size() - 1:
			var a := Vector2(punkte[k].x, punkte[k].z)
			var b := Vector2(punkte[k + 1].x, punkte[k + 1].z)
			var ab := b - a
			var l2 := ab.length_squared()
			var t := 0.0 if l2 < 1e-9 else clampf((q - a).dot(ab) / l2, 0.0, 1.0)
			var d := q.distance_squared_to(a + ab * t)
			if d < best:
				best = d
				bs = k * DS + t * (DS if k < punkte.size() - 2 else laenge - k * DS)
		return bs

	## Wie naechstes_s, aber ab Tabellenindex i0 vorwärts; bricht ab, sobald die Linie > 100 m weiter weg ist als das
	## bisher Beste und 200 m hinter ihm liegt (Anker sind geordnet; spart O(n²) beim Bau, W2 Ladezeit).
	func naechstes_s_ab(p: Vector3, i0: int) -> float:
		var best := INF
		var bs := 0.0
		var bk := i0
		var q := Vector2(p.x, p.z)
		for k in range(maxi(i0, 0), punkte.size() - 1):
			var a := Vector2(punkte[k].x, punkte[k].z)
			var b := Vector2(punkte[k + 1].x, punkte[k + 1].z)
			var ab := b - a
			var l2 := ab.length_squared()
			var t := 0.0 if l2 < 1e-9 else clampf((q - a).dot(ab) / l2, 0.0, 1.0)
			var d := q.distance_squared_to(a + ab * t)
			if d < best:
				best = d
				bk = k
				bs = k * DS + t * (DS if k < punkte.size() - 2 else laenge - k * DS)
			elif k > bk + 200 and sqrt(d) > sqrt(best) + 100.0:
				break
		return bs

	func sim_auf_s(kante: int, anteil: float) -> float:
		if anker_s.size() < 2:
			return anteil * laenge
		kante = clampi(kante, 0, anker_s.size() - 2)
		return lerpf(anker_s[kante], anker_s[kante + 1], clampf(anteil, 0.0, 1.0))


## Werte aus regelwerk.json (skalen.wege_dm, ortsstrasse_abweichung, bruecken). Fehlt etwas, bleiben die Annahmen.
func konfig_aus_regelwerk(rw: Dictionary) -> void:
	var w: Dictionary = rw.get("skalen", {}).get("wege_dm", {})
	var r: Dictionary = w.get("kurvenradius_m", {})
	if w.has("chaussee_fahrbahn"):
		profile["chaussee"]["fahrbahn"] = w["chaussee_fahrbahn"] / 10.0
	if w.has("chaussee_trasse"):
		profile["chaussee"]["trasse"] = w["chaussee_trasse"] / 10.0
	for t in ["dorfstrasse", "gasse", "feldweg"]:
		if w.has(t):
			profile[t]["fahrbahn"] = w[t] / 10.0
			profile[t]["trasse"] = w[t] / 10.0
	for t in ["dorfstrasse", "chaussee"]:
		if r.has(t):
			profile[t]["radius"] = float(r[t])
	var ab: Dictionary = rw.get("strasse_gleis_bild", {}).get("ortsstrasse_abweichung", {})
	if ab.has("m_max"):
		abweichung_max_m = float(ab["m_max"])
	var br: Dictionary = rw.get("skalen", {}).get("bruecken", {})
	if br.has("stein_bogen_m"):
		bogen_m = float(br["stein_bogen_m"])


## Flussmaske laden (proto_fluss.u8, Bits 1 Rinne / 2 Aue). Meta optional (proto_meta.json), sonst Ausschnitt-Vorgabe.
static func fluss_laden(pfad: String, meta: Dictionary = {}) -> Dictionary:
	var d := FileAccess.get_file_as_bytes(pfad) if FileAccess.file_exists(pfad) else PackedByteArray()
	var w := int(meta.get("w", 160))
	var h := int(meta.get("h", 144))
	if d.size() != w * h:
		return {}
	return {"daten": d, "w": w, "h": h, "x0": float(meta.get("x0", -1000.0)), "z0": float(meta.get("z0", -1000.0)),
		"m": float(meta.get("m", 25.0))}


static func _nass(fluss: Dictionary, x: float, z: float) -> bool:
	if fluss.is_empty():
		return false
	var c := int(floor((x - fluss["x0"]) / fluss["m"]))
	var r := int(floor((z - fluss["z0"]) / fluss["m"]))
	if c < 0 or r < 0 or c >= fluss["w"] or r >= fluss["h"]:
		return false
	return (fluss["daten"][r * fluss["w"] + c] & 1) != 0


## Alles bauen. wege = proto_wege.json, hoehe_fn(x_m, z_m) -> m, fluss = fluss_laden(...).
func bauen(parent: Node3D, wege: Array, hoehe_fn: Callable, fluss: Dictionary) -> void:
	hoehe_funktion = hoehe_fn
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat_stein = StandardMaterial3D.new()
	_mat_stein.albedo_color = Color(0.63, 0.6, 0.55)
	_mat_stein.roughness = 1.0
	var roh: Array = []
	for w in wege:
		var p := PackedVector2Array()
		for q in w.get("punkte", []):
			var v := Vector2(float(q[0]), float(q[1]))
			if p.is_empty() or p[-1].distance_to(v) > 0.01:
				p.append(v)
		roh.append(p)
	var fest: Array = []
	for p in roh:
		var f := PackedByteArray()
		f.resize(p.size())
		fest.append(f)
	var kand := _knoten_finden(wege, roh, fest)
	fahrlinien.clear()
	for i in wege.size():
		var w: Dictionary = wege[i]
		var typ: String = w.get("typ", "dorfstrasse")
		var pr: Dictionary = profile.get(typ, profile["dorfstrasse"])
		var trasse := float(w.get("breite_m", pr["trasse"]))
		var fahrbahn := minf(float(pr["fahrbahn"]), trasse)
		if typ != "chaussee":
			fahrbahn = trasse
		var fl := Fahrlinie.new()
		fl.weg_index = i
		fl.typ = typ
		fl.trasse_m = trasse
		fl.fahrbahn_m = fahrbahn
		fahrlinien.append(fl)
		if roh[i].size() < 2:
			warnungen.append("Weg %d: weniger als 2 Punkte" % i)
			continue
		var geo := _glaetten(roh[i], fest[i], float(pr["radius"]), fl)
		_bauen_weg(parent, i, typ, geo, roh[i], fl, hoehe_fn, fluss, bool(pr.get("graben", false)))
	_knoten_bauen(parent, kand, hoehe_fn)


# ------------------------------------------------------------------ Knoten

## Endpunkte, die auf einem anderen Weg liegen, werden Knoten; auf dem durchgehenden Weg wird dort ein fester Punkt
## eingefügt (Glättung hält ihn). Rückgabe: [{pos2: Vector2, arme: [[weg, "anfang"|"ende"|idx]]}]
func _knoten_finden(wege: Array, roh: Array, fest: Array) -> Array:
	var kand: Array = []
	for i in roh.size():
		var p: PackedVector2Array = roh[i]
		if p.size() < 2:
			continue
		for ende in [0, p.size() - 1]:
			var e: Vector2 = p[ende]
			var arm := [i, "anfang" if ende == 0 else "ende"]
			var k := _kand_bei(kand, e)
			k["arme"].append(arm)
			for j in roh.size():
				if j == i or roh[j].size() < 2:
					continue
				var pj: PackedVector2Array = roh[j]
				var tj := float(profile.get(wege[j].get("typ", ""), profile["dorfstrasse"])["trasse"])
				var best := INF
				var bseg := -1
				var bq := Vector2.ZERO
				for s in pj.size() - 1:
					var q := Geometry2D.get_closest_point_to_segment(e, pj[s], pj[s + 1])
					var d := e.distance_to(q)
					if d < best:
						best = d
						bseg = s
						bq = q
				if best > maxf(KNOTEN_FANG_M, tj * 0.5):
					continue
				# Endpunkt von j? Dann zählt j über seine eigene Endpunkt-Schleife.
				if bq.distance_to(pj[0]) < 1.0 or bq.distance_to(pj[-1]) < 1.0:
					continue
				var vi := -1
				if bq.distance_to(pj[bseg]) < 2.0:
					vi = bseg
				elif bq.distance_to(pj[bseg + 1]) < 2.0:
					vi = bseg + 1
				else:
					pj.insert(bseg + 1, bq)
					roh[j] = pj
					var fj: PackedByteArray = fest[j]
					fj.insert(bseg + 1, 0)
					fest[j] = fj
					vi = bseg + 1
				var fj2: PackedByteArray = fest[j]
				fj2[vi] = 1
				fest[j] = fj2
				var schon := false
				for a in k["arme"]:
					if a[0] == j:
						schon = true
				if not schon:
					k["arme"].append([j, "durch"])
	return kand.filter(func(k): return k["arme"].size() >= 2)


func _kand_bei(kand: Array, e: Vector2) -> Dictionary:
	for k in kand:
		if k["pos2"].distance_to(e) < 8.0:
			return k
	var k := {"pos2": e, "arme": []}
	kand.append(k)
	return k


func _knoten_bauen(parent: Node3D, kand: Array, hoehe_fn: Callable) -> void:
	knoten.clear()
	for k in kand:
		var c: Vector2 = k["pos2"]
		var r := 0.0
		var arme: Array = []
		var n_arme := 0
		for a in k["arme"]:
			var fl: Fahrlinie = fahrlinien[a[0]]
			r = maxf(r, fl.trasse_m * 0.5)
			var s := fl.naechstes_s(Vector3(c.x, 0, c.y))
			arme.append([a[0], s])
			n_arme += 2 if a[1] == "durch" else 1
		r += 1.5
		var y0 := float(hoehe_fn.call(c.x, c.y)) + Y_OFF + 0.03
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n := 24
		st.set_uv(Vector2(0.5, 0.0))
		st.add_vertex(Vector3(c.x, y0 + 0.02, c.y))
		for i in n:
			var a := TAU * i / n
			var x := c.x + cos(a) * r
			var z := c.y + sin(a) * r
			st.set_uv(Vector2(0.5, 0.0))
			st.add_vertex(Vector3(x, float(hoehe_fn.call(x, z)) + Y_OFF + 0.03, z))
		for i in n:
			st.add_index(0)
			st.add_index(1 + i)
			st.add_index(1 + (i + 1) % n)
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = "Knoten_%d" % knoten.size()
		mi.mesh = st.commit()
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		meshes.append(mi)
		knoten.append({"pos": Vector3(c.x, y0, c.y), "typ": "kreuzung" if n_arme >= 3 else "stoss", "radius": r, "arme": arme})


# ------------------------------------------------------------------ Glättung

func _glaetten(p0: PackedVector2Array, fest0: PackedByteArray, radius: float, fl: Fahrlinie) -> PackedVector2Array:
	var tr := _treppe(p0, fest0)
	var p: PackedVector2Array = tr[0]
	var fest: PackedByteArray = tr[1]
	var keep := PackedByteArray()
	keep.resize(p.size())
	keep[0] = 1
	keep[p.size() - 1] = 1
	for i in p.size():
		if fest[i]:
			keep[i] = 1
	_dp(p, 0, p.size() - 1, maxf(abweichung_max_m, DP_MIN_M), keep)
	var q := PackedVector2Array()
	var qf := PackedByteArray()
	for i in p.size():
		if keep[i]:
			q.append(p[i])
			qf.append(fest[i])
	if glaettung == "catmull":
		return _catmull(q)
	return _boegen(q, qf, radius, fl)


## Treppen aus Feldmitten: eine Ecke, deren beide Nachbarkanten kurz sind (≤ STUFE_MAX_M, also 1 Feld), wird durch die
## Mittelpunkte ihrer Kanten ersetzt. Bei einer regelmäßigen Treppe liegen diese Mittelpunkte genau auf der Diagonale,
## Douglas-Peucker fasst sie danach zusammen. Ecken mit langem Schenkel (echte Kurven) bleiben, feste Punkte auch.
func _treppe(p: PackedVector2Array, fest: PackedByteArray) -> Array:
	var q := PackedVector2Array()
	var qf := PackedByteArray()
	q.append(p[0])
	qf.append(fest[0])
	for i in range(1, p.size() - 1):
		var l0 := p[i - 1].distance_to(p[i])
		var l1 := p[i].distance_to(p[i + 1])
		if fest[i] or l0 > STUFE_MAX_M or l1 > STUFE_MAX_M:
			q.append(p[i])
			qf.append(fest[i])
			continue
		for m in [(p[i - 1] + p[i]) * 0.5, (p[i] + p[i + 1]) * 0.5]:
			if q[-1].distance_to(m) > 0.5:
				q.append(m)
				qf.append(0)
	if q[-1].distance_to(p[-1]) > 0.01:
		q.append(p[-1])
		qf.append(fest[-1])
	else:
		qf[-1] = fest[-1]
	return [q, qf]


func _dp(p: PackedVector2Array, a: int, b: int, tol: float, keep: PackedByteArray) -> void:
	if b <= a + 1:
		return
	var dmax := -1.0
	var imax := -1
	for i in range(a + 1, b):
		var q := Geometry2D.get_closest_point_to_segment(p[i], p[a], p[b])
		var d := p[i].distance_to(q)
		if keep[i]:
			d = INF                 # feste Punkte teilen immer
		if d > dmax:
			dmax = d
			imax = i
	if dmax > tol:
		keep[imax] = 1
		_dp(p, a, imax, tol, keep)
		_dp(p, imax, b, tol, keep)


func _boegen(q: PackedVector2Array, qf: PackedByteArray, radius: float, fl: Fahrlinie) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(q[0])
	for i in range(1, q.size() - 1):
		var a := q[i - 1]
		var b := q[i]
		var c := q[i + 1]
		var d0 := (b - a).normalized()
		var d1 := (c - b).normalized()
		var th := acos(clampf(d0.dot(d1), -1.0, 1.0))
		if th < 0.005:
			_gerade(out, b)
			continue
		var tn := tan(th * 0.5)
		var t := radius * tn
		t = minf(t, minf(0.45 * a.distance_to(b), 0.45 * b.distance_to(c)))
		if qf[i]:   # fester Punkt (Kreuzung): Bogen höchstens 1 m vom Punkt
			var r_max := 1.0 / maxf(1.0 / cos(th * 0.5) - 1.0, 1e-6)
			t = minf(t, r_max * tn)
		var r := t / tn
		fl.r_min = minf(fl.r_min, r)
		var p0 := b - d0 * t
		var sgn := signf(d0.x * d1.y - d0.y * d1.x)
		var nrm := Vector2(-d0.y, d0.x) * sgn
		var ctr := p0 + nrm * r
		var a0 := (p0 - ctr).angle()
		var steps := maxi(2, maxi(ceili(th * r / BOGEN_SEHNE_M), ceili(th / BOGEN_WINKEL)))
		_gerade(out, p0)
		for k in range(1, steps + 1):
			out.append(ctr + Vector2.from_angle(a0 + sgn * th * k / steps) * r)
	_gerade(out, q[-1])
	return out


## Gerade bis p in Stücken ≤ SCHRITT_GERADE_M anhängen.
func _gerade(out: PackedVector2Array, p: Vector2) -> void:
	var a := out[-1]
	var l := a.distance_to(p)
	if l < 0.05:
		return
	var n := ceili(l / SCHRITT_GERADE_M)
	for k in range(1, n + 1):
		out.append(a.lerp(p, float(k) / n))


func _catmull(q: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(q[0])
	for i in q.size() - 1:
		var p0 := q[maxi(i - 1, 0)]
		var p1 := q[i]
		var p2 := q[i + 1]
		var p3 := q[mini(i + 2, q.size() - 1)]
		var t1 := pow(maxf(p0.distance_to(p1), 1e-3), 0.5)
		var t2 := t1 + pow(maxf(p1.distance_to(p2), 1e-3), 0.5)
		var t3 := t2 + pow(maxf(p2.distance_to(p3), 1e-3), 0.5)
		var n := maxi(2, ceili(p1.distance_to(p2) / BOGEN_SEHNE_M))
		for k in range(1, n + 1):
			var t := lerpf(t1, t2, float(k) / n)
			var a1 := p0 * ((t1 - t) / t1) + p1 * (t / t1)
			var a2 := p1 * ((t2 - t) / (t2 - t1)) + p2 * ((t - t1) / (t2 - t1))
			var a3 := p2 * ((t3 - t) / (t3 - t2)) + p3 * ((t - t2) / (t3 - t2))
			var b1 := a1 * ((t2 - t) / t2) + a2 * (t / t2)
			var b2 := a2 * ((t3 - t) / (t3 - t1)) + a3 * ((t - t1) / (t3 - t1))
			out.append(b1 * ((t2 - t) / (t2 - t1)) + b2 * ((t - t1) / (t2 - t1)))
	return out


# ------------------------------------------------------------------ Band

func _bauen_weg(parent: Node3D, i: int, typ: String, geo: PackedVector2Array, roh: PackedVector2Array, fl: Fahrlinie,
		hoehe_fn: Callable, fluss: Dictionary, graben: bool) -> void:
	# Bogenlänge der Geometrie
	var gs := PackedFloat32Array()
	gs.resize(geo.size())
	for k in range(1, geo.size()):
		gs[k] = gs[k - 1] + geo[k - 1].distance_to(geo[k])
	var L := gs[-1]
	fl.laenge = L
	# Gleichmäßige 2D-Tabelle (DS = 1 m)
	var n := int(floor(L / Fahrlinie.DS)) + 1
	if L - (n - 1) * Fahrlinie.DS < 1e-3:
		n -= 1
	var tab := PackedVector2Array()
	var tab_s := PackedFloat32Array()
	var j := 0
	for k in n:
		var s := k * Fahrlinie.DS
		while j < geo.size() - 2 and gs[j + 1] < s:
			j += 1
		var seg := maxf(gs[j + 1] - gs[j], 1e-6)
		tab.append(geo[j].lerp(geo[j + 1], (s - gs[j]) / seg))
		tab_s.append(s)
	tab.append(geo[-1])
	tab_s.append(L)
	# Brücken auf der Tabelle finden
	var br: Array = []
	if typ == "bruecke":
		br.append(_bruecke_neu(i, 0.0, L, L, hoehe_fn, tab, tab_s, true))
	else:
		var lauf0 := -1.0
		var letzt := -1.0
		for k in tab.size():
			var nass := _nass(fluss, tab[k].x, tab[k].y)
			if nass:
				if lauf0 < 0.0 or tab_s[k] - letzt > 10.0:
					if lauf0 >= 0.0 and letzt - lauf0 >= WASSER_LAUF_MIN_M:
						br.append(_bruecke_neu(i, lauf0, letzt, L, hoehe_fn, tab, tab_s, false))
					lauf0 = tab_s[k]
				letzt = tab_s[k]
		if lauf0 >= 0.0 and letzt - lauf0 >= WASSER_LAUF_MIN_M:
			br.append(_bruecke_neu(i, lauf0, letzt, L, hoehe_fn, tab, tab_s, false))
	# Höhen der Fahrlinie
	fl.punkte.resize(tab.size())
	fl.gier.resize(tab.size())
	for k in tab.size():
		var y := _hoehe_s(tab_s[k], tab[k], hoehe_fn, br)
		fl.punkte[k] = Vector3(tab[k].x, y, tab[k].y)
	for k in tab.size():
		var a := tab[maxi(k - 1, 0)]
		var b := tab[mini(k + 1, tab.size() - 1)]
		fl.gier[k] = atan2(b.x - a.x, b.y - a.y)
	fl.anker = roh
	fl.anker_s.resize(roh.size())
	var i_ab := 0
	for k in roh.size():
		fl.anker_s[k] = fl.naechstes_s_ab(Vector3(roh[k].x, 0, roh[k].y), i_ab - 30)
		i_ab = int(fl.anker_s[k] / Fahrlinie.DS)
	# Mesh
	var off: Array
	var dy: Array
	var hb := fl.fahrbahn_m * 0.5
	var ht := fl.trasse_m * 0.5
	if graben and ht > hb + 0.5:
		var gm := hb + (ht - hb) * 0.55
		off = [-ht - SCHUERZE_M, -ht, -gm, -hb - 0.4, -hb, 0.0, hb, hb + 0.4, gm, ht, ht + SCHUERZE_M]
		dy = [-0.6, 0.0, -0.5, 0.0, 0.0, 0.05, 0.0, 0.0, -0.5, 0.0, -0.6]
	else:
		off = [-hb - SCHUERZE_M, -hb, 0.0, hb, hb + SCHUERZE_M]
		dy = [-0.6, 0.0, 0.05, 0.0, -0.6]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m := off.size()
	var aussen := ht + SCHUERZE_M - hb
	var k_deck := (BRUECKE_RAND_M / aussen) if aussen > 0.01 else 1.0
	for k in geo.size():
		var a := geo[maxi(k - 1, 0)]
		var b := geo[mini(k + 1, geo.size() - 1)]
		var d := (b - a).normalized()
		var rgt := Vector2(-d.y, d.x)
		var s := gs[k]
		var tb := _bruecke_t(s, br)
		var deck: Variant = _deck_bei(s, br)
		for q in m:
			var o := float(off[q])
			var ao := absf(o)
			var om := o
			if ao > hb and tb > 0.0:      # auf Rampe/Brücke: Bankett und Graben auf den Brückenrand zusammenziehen
				om = signf(o) * (hb + (ao - hb) * lerpf(1.0, k_deck, tb))
			var p := geo[k] + rgt * om
			var y: float
			var u := om / hb
			if deck != null:
				y = float(deck) + (0.05 if o == 0.0 else 0.0)
				if ao > hb:
					u = signf(o) * 1.1
			else:
				y = _hoehe_s(s, p, hoehe_fn, br)
				if tb <= 0.0:
					# W2: Gelände zwischen zwei Querschnitten (TA-Feinraster 5 m) darf nicht über das Band ragen:
					# Querschnitt auf das Maximum bei ±halbem Abstand zu den Nachbarn heben (Wölbung abdecken).
					var hv := (gs[mini(k + 1, geo.size() - 1)] - gs[maxi(k - 1, 0)]) * 0.25
					for e in [-1.0, -0.5, 0.5, 1.0]:
						var pe: Vector2 = p + d * hv * e
						y = maxf(y, float(hoehe_fn.call(pe.x, pe.y)) + Y_OFF)
				y += float(dy[q]) * (1.0 - tb)
			st.set_uv(Vector2(u, s))
			st.add_vertex(Vector3(p.x, y, p.y))
	for k in geo.size() - 1:
		for q in m - 1:
			var v := k * m + q
			st.add_index(v); st.add_index(v + m + 1); st.add_index(v + 1)
			st.add_index(v); st.add_index(v + m); st.add_index(v + m + 1)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "Weg_%d_%s" % [i, typ]
	mi.mesh = st.commit()
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	meshes.append(mi)
	for b in br:
		_bruecke_bauen(parent, b, fl, hoehe_fn)
		bruecken.append(b)


## Fahrbahnhöhe an s: Gelände, auf Rampe/Deck die Brückenhöhe.
func _hoehe_s(s: float, p: Vector2, hoehe_fn: Callable, br: Array) -> float:
	var g := float(hoehe_fn.call(p.x, p.y)) + Y_OFF
	for b in br:
		if s >= b["r0"] and s <= b["r1"]:
			var deck: float = b["deck_m"] + Y_OFF
			if s < b["s0"]:      # Rampe als Damm: nie unter die Geländehöhe am Rampenfuß (Uferböschung)
				return lerpf(maxf(g, b["h_r0"] + Y_OFF), deck, smoothstep(b["r0"], b["s0"], s))
			if s > b["s1"]:
				return lerpf(deck, maxf(g, b["h_r1"] + Y_OFF), smoothstep(b["s1"], b["r1"], s))
			var t: float = (s - b["s0"]) / maxf(b["s1"] - b["s0"], 1e-3)
			return deck + BUCKEL_M * sin(PI * t)
	return g


## 0 außerhalb, 0..1 auf der Rampe, 1 auf dem Deck.
func _bruecke_t(s: float, br: Array) -> float:
	for b in br:
		if s >= b["r0"] and s <= b["r1"]:
			if s < b["s0"]:
				return smoothstep(b["r0"], b["s0"], s)
			if s > b["s1"]:
				return 1.0 - smoothstep(b["s1"], b["r1"], s)
			return 1.0
	return 0.0


## Deckoberfläche (ohne Buckel-Anteil der Rampe) oder null, wenn s nicht auf dem Deck liegt.
func _deck_bei(s: float, br: Array) -> Variant:
	for b in br:
		if s >= b["s0"] and s <= b["s1"]:
			var t: float = (s - b["s0"]) / maxf(b["s1"] - b["s0"], 1e-3)
			return b["deck_m"] + Y_OFF + BUCKEL_M * sin(PI * t)
	return null


func _bruecke_neu(i: int, w0: float, w1: float, L: float, hoehe_fn: Callable, tab: PackedVector2Array,
		tab_s: PackedFloat32Array, ganz: bool) -> Dictionary:
	var s0 := 0.0 if ganz else maxf(0.0, w0 - UFER_M)
	var s1 := L if ganz else minf(L, w1 + UFER_M)
	var r0 := s0 if ganz else maxf(0.0, w0 - RAMPE_M)
	var r1 := s1 if ganz else minf(L, w1 + RAMPE_M)
	var pa := _tab_punkt(tab, tab_s, r0)
	var pb := _tab_punkt(tab, tab_s, r1)
	var ha := float(hoehe_fn.call(pa.x, pa.y))
	var hb := float(hoehe_fn.call(pb.x, pb.y))
	var deck := maxf(maxf(ha, hb), wasser_pegel_m + LICHTE_M + DECK_M)
	if not ganz:   # Rampe so lang, dass die steilste Stelle (smoothstep: 1,5 × Mittel) ≤ RAMPE_STEIGUNG bleibt
		r0 = maxf(0.0, s0 - maxf(RAMPE_M - UFER_M, absf(deck - ha) * 1.5 / RAMPE_STEIGUNG))
		r1 = minf(L, s1 + maxf(RAMPE_M - UFER_M, absf(deck - hb) * 1.5 / RAMPE_STEIGUNG))
		pa = _tab_punkt(tab, tab_s, r0)
		pb = _tab_punkt(tab, tab_s, r1)
		ha = float(hoehe_fn.call(pa.x, pa.y))
		hb = float(hoehe_fn.call(pb.x, pb.y))
	var span := s1 - s0
	return {"weg": i, "s0": s0, "s1": s1, "r0": r0, "r1": r1, "s_wasser0": w0, "s_wasser1": w1, "deck_m": deck,
		"h_r0": ha, "h_r1": hb,
		"laenge": span, "boegen": maxi(1, ceili(span / bogen_m)),
		"p0": Vector3(_tab_punkt(tab, tab_s, s0).x, deck, _tab_punkt(tab, tab_s, s0).y),
		"p1": Vector3(_tab_punkt(tab, tab_s, s1).x, deck, _tab_punkt(tab, tab_s, s1).y)}


static func _tab_punkt(tab: PackedVector2Array, tab_s: PackedFloat32Array, s: float) -> Vector2:
	var k := clampi(int(s / Fahrlinie.DS), 0, tab.size() - 2)
	var seg := maxf(tab_s[k + 1] - tab_s[k], 1e-6)
	return tab[k].lerp(tab[k + 1], clampf((s - tab_s[k]) / seg, 0.0, 1.0))


## Steinbogenbrücke aus Boxen (ein Mesh): Deckplatte, Brüstungen, Pfeiler, Bogensteine, Zwickel.
func _bruecke_bauen(parent: Node3D, b: Dictionary, fl: Fahrlinie, hoehe_fn: Callable) -> void:
	var p0: Vector3 = b["p0"]
	var p1: Vector3 = b["p1"]
	var f := Vector3(p1.x - p0.x, 0, p1.z - p0.z)
	var L := f.length()
	if L < 1.0:
		return
	f /= L
	var r := Vector3(-f.z, 0, f.x)
	var basis0 := Basis(r, Vector3.UP, f)
	var deck: float = b["deck_m"]
	var breite := fl.fahrbahn_m + 2.0 * BRUECKE_RAND_M + 1.0     # Fahrbahn + Rand + 2 × Brüstung 0,5
	var box := BoxMesh.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var teile := 0
	var put := func(mitte_l: float, quer: float, y_mitte: float, groesse: Vector3, kipp: float) -> void:
		var bas := basis0 * Basis(Vector3.RIGHT, kipp) * Basis.from_scale(groesse)
		var pos := Vector3(p0.x, 0, p0.z) + f * mitte_l + r * quer + Vector3(0, y_mitte, 0)
		st.append_from(box, 0, Transform3D(bas, pos))
	# Deck und Brüstungen
	put.call(L * 0.5, 0.0, deck - DECK_M * 0.5, Vector3(breite, DECK_M, L), 0.0)
	put.call(L * 0.5, -(breite * 0.5 - 0.25), deck + 0.5, Vector3(0.5, 1.0, L), 0.0)
	put.call(L * 0.5, breite * 0.5 - 0.25, deck + 0.5, Vector3(0.5, 1.0, L), 0.0)
	teile += 3
	var nb: int = b["boegen"]
	var spann := L / nb
	var pf := 2.4
	# Segmentbogen: Kämpfer knapp über dem Pegel, Stich bis unter die Deckplatte (≤ halbe Lichtweite = Halbkreis)
	var c := maxf(spann - pf, 2.0)
	var stich := clampf(deck - DECK_M - (wasser_pegel_m + 0.3), 1.0, c * 0.5)
	var kaempfer := deck - DECK_M - stich
	var rr := (c * c * 0.25 + stich * stich) / (2.0 * stich)
	var halb := asin(clampf(c * 0.5 / rr, 0.0, 1.0))
	var mitte_y := kaempfer + stich - rr
	var fuss := minf(wasser_pegel_m, float(hoehe_fn.call(p0.x, p0.z))) - 1.5
	for k in nb + 1:
		var lk := k * spann
		var h := maxf(kaempfer - fuss, 0.5)
		var lpf := pf if (k > 0 and k < nb) else pf * 1.5
		put.call(clampf(lk, lpf * 0.5, L - lpf * 0.5), 0.0, fuss + h * 0.5, Vector3(breite, h, lpf), 0.0)
		teile += 1
	var nv := 7
	for k in nb:
		var mitte := (k + 0.5) * spann
		for v in nv:
			var a := PI * 0.5 - halb + 2.0 * halb * (v + 0.5) / nv     # Winkel auf dem Bogenkreis
			var lx := mitte - cos(a) * rr
			var yy := mitte_y + sin(a) * rr
			put.call(lx, 0.0, yy, Vector3(breite, 0.9, 2.0 * halb * rr / nv * 1.08), a - PI * 0.5)
			teile += 1
		# Zwickel an beiden Bogenenden (zwischen Kämpfer und Deck, über dem Pfeiler)
		var zl := spann * 0.18
		var zh := maxf(deck - DECK_M - kaempfer, 0.3)
		put.call(k * spann + zl * 0.5, 0.0, kaempfer + zh * 0.5, Vector3(breite - 0.6, zh, zl), 0.0)
		put.call((k + 1) * spann - zl * 0.5, 0.0, kaempfer + zh * 0.5, Vector3(breite - 0.6, zh, zl), 0.0)
		teile += 2
	var mi := MeshInstance3D.new()
	mi.name = "Bruecke_%d" % bruecken.size()
	mi.mesh = st.commit()
	mi.material_override = _mat_stein
	parent.add_child(mi)
	meshes.append(mi)
	b["teile"] = teile
	b["kaempfer_m"] = kaempfer
	b["bogen_radius_m"] = rr
	b["stich_m"] = stich


## Dreiecke aller Bänder/Knoten/Brücken (Perf-Zählung).
func dreiecke() -> int:
	var t := 0
	for mi in meshes:
		var m: Mesh = mi.mesh
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			t += (idx.size() if idx != null and idx.size() > 0 else arr[Mesh.ARRAY_VERTEX].size()) / 3
	return t
