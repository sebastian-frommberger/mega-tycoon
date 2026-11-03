extends RefCounted
## Phase 4 Welle 2 (Felix): Fahrzeug-Easing der Prototyp-Welt (15_regelwerk_v1_1 Teil B, K27–K31, 12 fahrzeug_easing).
## Reine Darstellung: liest Sim-Proben (Fahrstrecke je Tick), schreibt nichts zurück (K27, E1).
##
## Ursache „Schuhkarton“ (15 §B1): Sim-Kanten sind Geraden, das Spiel mischt die Basis zweier Ticks linear
## (MultiMesh FAST) → in der 90°-Ecke schrumpft das Modell auf ≈ 71 % und dreht als Sehne. Behebung hier:
##   1. Fahrlinie = Spline des Straßenbands (proto_strassenband.gd), Sim-Kante k ↔ Abschnitt zwischen denselben
##      Ankern, längentreu-proportional (K28). Übergänge zwischen zwei Wegen bekommen einen Kreisbogen.
##   2. Position und Gier je Frame aus der Fahrlinie (Gier = Tangente, Winkel nie linear gemischt) →
##      Basis orthonormal (E7), Gierrate = v · κ (E3).
##   3. Anfahren/Bremsen: Folger auf der Fahrstrecke (K29): Rampe a = v_sim / (W/2 Ticks), Bremsen auf den bekannten
##      Halt am Linienende (die Sim hält dort immer ≥ 1 Tick), Aufholen ≤ +10 %, nie vor der Sim.
##      Ergebnis: Versatz ≤ W/4 Ticks im Lauf, Halt ≤ W/2 Ticks nach der Sim (E5, E6).
##      Abweichung von K29 „gleitender Mittelwert“: der Mittelwert über W Proben erreicht den Halt erst W−1 Ticks
##      nach der Sim (E5 verlangt ≤ W/2); gleiche Rampenlänge, gleiche Kosten O(1), Begründung in felix_welle2.md.
##   4. Kurvenzone (K30): zeiterhaltende Umparametrisierung p = φ(u); Tempofaktor f(p) aus Krümmung der Spur
##      (Querbeschleunigung ≤ Profilwert, Gierrate ≤ ω_max, f ≥ Kurvenfaktor min), Defizit wird davor/danach mit
##      ≤ +15 % Überhöhung wieder eingeholt → Bild und Sim treffen sich am Zonenrand.
##   5. Spur-Versatz rechts (Rechtsverkehr), Haltung (Rollen, Nicken, Wippen) und Gang-/Radphase aus der Strecke
##      (gedeckelte Frequenz) → INSTANCE_CUSTOM (x Gangphase 0..1, y Wippen m, z Rollen rad, w Nicken rad).
##   6. Wende am Linienende (die Sim kehrt die Route im Stand um): Pose-Überblendung, Gierrate ≤ ω_max, einziger
##      erlaubter Sprung neben Routenwechsel/Kauf/Verkauf (B4 Schritt 7), in den Tests ausgenommen und gezählt.
## „Easing aus“ bildet das heutige Spiel nach: Gerade zwischen den Sim-Knoten, Richtung = Kante, Basis linear
## zwischen zwei Ticks gemischt (FAST) → Stauchung sichtbar und messbar.
##
## Zeiteinheit intern: Ticks (10 Hz bei 1×), Längen in m.

const M_PRO_FELD := 25.0
const DS := 1.0


## Bewegungsprofil einer Kategorie aus regelwerk.fahrzeug_easing.kategorien[kat].
class Profil extends RefCounted:
	var kat := ""
	var w := 4                       # Fenster W (Ticks)
	var v_nom := 15.0                # m/Tick (Sim-Tempo)
	var kf_min := 0.55
	var ueb := 0.15                  # Überhöhung max
	var r_min := 8.0
	var spur := 1.5                  # m, + = rechts
	var roll_max := deg_to_rad(3.0)
	var nick_max := deg_to_rad(2.0)
	var wipp_m := 0.12
	var wipp_hz := 2.0
	var gang_hz := 2.5
	var rad_u_s := 3.0
	var omega_max := deg_to_rad(270.0) / 10.0    # rad/Tick
	var aufholen := 0.10
	var r_ref := 25.0                # Kurvenradius Dorfstraße (regelwerk skalen.wege_dm.kurvenradius_m)

	static func aus_regelwerk(rw: Dictionary, kat: String) -> Profil:
		var p := Profil.new()
		p.kat = kat
		var k: Dictionary = rw.get("fahrzeug_easing", {}).get("kategorien", {}).get(kat, {})
		var mpf := float(rw.get("skalen", {}).get("m_pro_feld", M_PRO_FELD))
		var fw = k.get("fenster_ticks", 4)
		p.w = int(fw[0]) if fw is Array else int(fw)
		p.v_nom = float(k.get("sim_felder_je_tick_promille", 600)) / 1000.0 * mpf
		p.kf_min = float(k.get("kurvenfaktor_min_promille", 550)) / 1000.0
		p.ueb = float(k.get("ueberhoehung_max_promille", 150)) / 1000.0
		p.r_min = float(k.get("radius_min_m", 8))
		p.spur = float(k.get("spur_versatz_dm", 15)) / 10.0
		p.roll_max = deg_to_rad(float(k.get("rollen_max_grad", 3)))
		p.nick_max = deg_to_rad(float(k.get("nicken_max_grad", 2)))
		p.wipp_m = float(k.get("wippen_cm", 12)) / 100.0
		p.wipp_hz = float(k.get("wippen_hz_max_dez", 20)) / 10.0
		p.gang_hz = float(k.get("gang_hz_max_dez", 25)) / 10.0
		p.rad_u_s = float(k.get("rad_u_s_max", 3))
		p.omega_max = deg_to_rad(float(k.get("gierrate_max_grad_s", 270))) / 10.0
		p.r_ref = float(rw.get("skalen", {}).get("wege_dm", {}).get("kurvenradius_m", {}).get("dorfstrasse", 25))
		return p

	## Anfahr-/Bremsrampe (m/Tick²): v_nom in W/2 Ticks.
	func a_max() -> float:
		return v_nom / (w * 0.5)

	## Bremsen etwas kürzer (0,9 × W/2), damit der Halt sicher ≤ W/2 Ticks nach der Sim liegt.
	func a_brems() -> float:
		return v_nom / (w * 0.5 * 0.9)

	## E4-Profilwert (m/Tick²) je Kategorie: (Kurvenfaktor · v_sim)² / R_ref, R_ref = Kurvenradius Dorfstraße
	## (15 §B5 E4: „Fuhrwerk auf Dorfstraße R 25 m: (0,55 × 150)² / 25 ≈ 270 m/s²“). Gilt auf allen Wegtypen:
	## in einer Chaussee-Kurve R 50 m darf das Fuhrwerk also schneller sein (f = √(270 · 50) / 150 ≈ 0,78).
	## r_typ bleibt als Parameter (Wegtyp-Radius, nur Info).
	func a_quer_ref(_r_typ: float = 0.0) -> float:
		return pow(kf_min * v_nom, 2) / maxf(r_ref, 1.0)


## Fahrlinie einer Linien-Strecke (ein Leg): Spur-Punkte je 1 m, Gier, Krümmung, Tempofaktor, φ⁻¹-Tabelle,
## Sim-Abschnitte (Schritt-Grenzen) und die Geraden zwischen den Sim-Knoten (für „Easing aus“).
class Routenlinie extends RefCounted:
	var laenge := 0.0
	var mitte := PackedVector3Array()        # Bandmitte je 1 m
	var spur := PackedVector3Array()         # Spur-Punkt je 1 m (Rechtsverkehr)
	var gier := PackedFloat32Array()         # Gier der Spur (atan2(dx, dz), Modell-Vorne +z)
	var kappa := PackedFloat32Array()        # Krümmung der Spur (1/m, + = links)
	var kappa_spitze := PackedFloat32Array() # |κ| Spitze im Umkreis ±2 m (Gierraten-Limit)
	var steigung := PackedFloat32Array()     # dy/ds geglättet (±12,5 m)
	var f := PackedFloat32Array()            # Tempofaktor Kurvenzone (mit Überhöhung davor/danach)
	var f_lim := PackedFloat32Array()        # Kurvenlimit (Querbeschleunigung, Gierrate), ≤ 1
	var n_unter_kf := 0                      # Proben mit Limit < Kurvenfaktor min (Radius zu klein)
	var r_typ := PackedFloat32Array()        # Kurvenradius des Wegtyps je m (E4-Profilwert)
	var p_von_u := PackedFloat32Array()      # φ: u (je 1 m) → p
	var skala := 1.0
	var schritt_s := PackedFloat32Array()    # Sim-Schritt k: [schritt_s[k], schritt_s[k+1]]
	var knoten := PackedVector3Array()       # Sim-Knoten (Schritt-Grenzen), für „aus“
	var r_uebergang_min := INF               # kleinster Bogen an Weg-Übergängen

	func _i(s: float) -> Vector2:
		var n := spur.size()
		s = clampf(s, 0.0, laenge)
		var i := mini(int(s / DS), n - 2)
		var seg := DS if i < n - 2 else maxf(laenge - i * DS, 1e-6)
		return Vector2(i, clampf((s - i * DS) / seg, 0.0, 1.0))

	func spur_punkt(p: float) -> Vector3:
		var t := _i(p)
		return spur[int(t.x)].lerp(spur[int(t.x) + 1], t.y)

	func mitte_punkt(p: float) -> Vector3:
		var t := _i(p)
		return mitte[int(t.x)].lerp(mitte[int(t.x) + 1], t.y)

	func gier_bei(p: float) -> float:
		var t := _i(p)
		var i := int(t.x)
		return gier[i] + wrapf(gier[i + 1] - gier[i], -PI, PI) * t.y

	func _lin(a: PackedFloat32Array, p: float) -> float:
		var t := _i(p)
		return lerpf(a[int(t.x)], a[int(t.x) + 1], t.y)

	func kappa_bei(p: float) -> float:
		return _lin(kappa, p)

	func f_bei(p: float) -> float:
		return _lin(f, p) * skala

	func f_lim_bei(p: float) -> float:
		return _lin(f_lim, p)

	func steigung_bei(p: float) -> float:
		return _lin(steigung, p)

	func phi(u: float) -> float:
		var n := p_von_u.size()
		if n < 2:
			return u
		u = clampf(u, 0.0, laenge)
		var i := mini(int(u), n - 2)
		var seg := 1.0 if i < n - 2 else maxf(laenge - i, 1e-6)
		return lerpf(p_von_u[i], p_von_u[i + 1], clampf((u - i) / seg, 0.0, 1.0))

	## Sim-Probe (Schritt k, Anteil 0..1) → Fahrstrecke d auf dieser Linie (K28 längentreu-proportional).
	func d_von_sim(k: int, anteil: float) -> float:
		if schritt_s.size() < 2:
			return 0.0
		k = clampi(k, 0, schritt_s.size() - 2)
		return lerpf(schritt_s[k], schritt_s[k + 1], clampf(anteil, 0.0, 1.0))

	## „Easing aus“: Gerade zwischen den Sim-Knoten wie heute (Position, Gier der Kante) an Fahrstrecke d.
	func aus_pose(d: float) -> Array:
		var n := schritt_s.size()
		if n < 2:
			return [Vector3.ZERO, 0.0]
		var lo := 0
		var hi := n - 2
		while lo < hi:
			var mid := (lo + hi + 1) >> 1
			if schritt_s[mid] <= d:
				lo = mid
			else:
				hi = mid - 1
		var a := knoten[lo]
		var b := knoten[lo + 1]
		var seg := maxf(schritt_s[lo + 1] - schritt_s[lo], 1e-6)
		var t := clampf((d - schritt_s[lo]) / seg, 0.0, 1.0)
		var dir := b - a
		var g := atan2(dir.x, dir.z) if Vector2(dir.x, dir.z).length() > 1e-4 else 0.0
		return [a.lerp(b, t), g]


## Baut eine Routenlinie aus Rohproben (Bandmitte je ~1 m entlang der Sim-Schritte).
## roh: PackedVector3Array, roh_s: Bogenlänge je Probe, uebergaenge: Indizes in roh, an denen der Weg wechselt,
## grenzen_s: Schritt-Grenzen (Bogenlänge in roh_s), knoten: Sim-Knoten (m, y), rtyp: Kurvenradius je Probe,
## r_uebergang: Bogenradius an Weg-Übergängen (Typ-Radius).
static func routenlinie_bauen(roh: PackedVector3Array, roh_s: PackedFloat32Array, uebergaenge: PackedInt32Array,
		grenzen_s: PackedFloat32Array, knoten: PackedVector3Array, rtyp: PackedFloat32Array,
		r_uebergang: PackedFloat32Array, prof: Profil) -> Routenlinie:
	var rl := Routenlinie.new()
	# 1) Kreisbogen an jedem Weg-Übergang (Knick zwischen zwei Fahrlinien)
	var pts := PackedVector2Array()
	var ys := PackedFloat32Array()
	var alt_s := PackedFloat32Array()
	var rt := PackedFloat32Array()
	for i in roh.size():
		pts.append(Vector2(roh[i].x, roh[i].z))
		ys.append(roh[i].y)
		alt_s.append(roh_s[i])
		rt.append(rtyp[i])
	var fenster: Array = []                  # [s0, s1, mitte(Vector2), ...] Bögen auf alt_s
	for ui in uebergaenge.size():
		var j := uebergaenge[ui]
		if j <= 0 or j >= roh.size() - 1:
			continue
		var sj := roh_s[j]
		var s_vor := roh_s[uebergaenge[ui - 1]] if ui > 0 else 0.0
		var s_nach := roh_s[uebergaenge[ui + 1]] if ui + 1 < uebergaenge.size() else roh_s[-1]
		var d0 := (_bei(pts, roh_s, sj) - _bei(pts, roh_s, maxf(sj - 4.0, s_vor))).normalized()
		var d1 := (_bei(pts, roh_s, minf(sj + 4.0, s_nach)) - _bei(pts, roh_s, sj)).normalized()
		var th := acos(clampf(d0.dot(d1), -1.0, 1.0))
		if th < deg_to_rad(2.0):
			continue
		var r := maxf(float(r_uebergang[ui]), prof.r_min)
		var t := r * tan(th * 0.5)
		t = minf(t, minf(0.45 * (sj - s_vor), 0.45 * (s_nach - sj)))
		if t < 0.5:
			continue
		rl.r_uebergang_min = minf(rl.r_uebergang_min, t / tan(th * 0.5))
		fenster.append([sj - t, sj + t])
	# Neue Polylinie: Proben außerhalb der Fenster, im Fenster quadratische Bézier (tangential an beide Enden;
	# bei gleichen Schenkeln ≈ Kreisbogen) mit Probenabstand 1 m.
	var np := PackedVector2Array()
	var ny := PackedFloat32Array()
	var nalt := PackedFloat32Array()
	var nrt := PackedFloat32Array()
	var fi := 0
	var i := 0
	while i < pts.size():
		if fi < fenster.size() and roh_s[i] >= fenster[fi][0]:
			var s0: float = fenster[fi][0]
			var s1: float = fenster[fi][1]
			var a := _bei(pts, roh_s, s0)
			var b := _bei(pts, roh_s, s1)
			var c := _bei(pts, roh_s, (s0 + s1) * 0.5)
			# Kontrollpunkt = Schnitt der Tangenten ≈ Knickpunkt
			var ta := (a - _bei(pts, roh_s, s0 - 1.0)).normalized()
			var tb := (_bei(pts, roh_s, s1 + 1.0) - b).normalized()
			var ctrl := c
			var den := ta.cross(tb)
			if absf(den) > 1e-4:
				var lam := (b - a).cross(tb) / den
				ctrl = a + ta * lam
			var n := maxi(2, ceili((s1 - s0) / DS))
			var y0 := _bei_f(ys, roh_s, s0)
			var y1 := _bei_f(ys, roh_s, s1)
			var rmid := _bei_f(rt, roh_s, (s0 + s1) * 0.5)
			for k in n + 1:
				var u := float(k) / n
				np.append(a.lerp(ctrl, u).lerp(ctrl.lerp(b, u), u))
				ny.append(lerpf(y0, y1, u))
				nalt.append(lerpf(s0, s1, u))
				nrt.append(rmid)
			while i < pts.size() and roh_s[i] <= s1:
				i += 1
			fi += 1
			continue
		if np.is_empty() or np[-1].distance_to(pts[i]) > 1e-3:
			np.append(pts[i])
			ny.append(ys[i])
			nalt.append(roh_s[i])
			nrt.append(rt[i])
		i += 1
	# 2) Gleichmäßig je 1 m neu abtasten (neue Bogenlänge), alte Bogenlänge mitführen (Schritt-Grenzen)
	var cum := PackedFloat32Array()
	cum.resize(np.size())
	for k in range(1, np.size()):
		cum[k] = cum[k - 1] + np[k - 1].distance_to(np[k])
	var L := cum[-1] if cum.size() > 0 else 0.0
	rl.laenge = L
	var n_t := int(floor(L / DS)) + 1
	if n_t > 1 and L - (n_t - 1) * DS < 1e-3:
		n_t -= 1
	var j2 := 0
	var tab2 := PackedVector2Array()
	var taby := PackedFloat32Array()
	var tabr := PackedFloat32Array()
	for k in n_t + 1:
		var s := minf(k * DS, L) if k < n_t else L
		while j2 < np.size() - 2 and cum[j2 + 1] < s:
			j2 += 1
		var seg := maxf(cum[j2 + 1] - cum[j2], 1e-6) if np.size() > 1 else 1.0
		var t := clampf((s - cum[j2]) / seg, 0.0, 1.0) if np.size() > 1 else 0.0
		tab2.append(np[j2].lerp(np[mini(j2 + 1, np.size() - 1)], t))
		taby.append(lerpf(ny[j2], ny[mini(j2 + 1, np.size() - 1)], t))
		tabr.append(nrt[j2])
	# Schritt-Grenzen: alte Bogenlänge → neue (monoton über nalt/cum)
	rl.schritt_s.resize(grenzen_s.size())
	for k in grenzen_s.size():
		rl.schritt_s[k] = _map(nalt, cum, grenzen_s[k])
	rl.schritt_s[0] = 0.0
	rl.schritt_s[-1] = L
	for k in range(1, rl.schritt_s.size()):
		rl.schritt_s[k] = maxf(rl.schritt_s[k], rl.schritt_s[k - 1])
	rl.knoten = knoten
	# 3) Mitte, Spur, Gier, Krümmung, Steigung
	var n2 := tab2.size()
	rl.mitte.resize(n2)
	rl.spur.resize(n2)
	rl.gier.resize(n2)
	rl.kappa.resize(n2)
	rl.steigung.resize(n2)
	rl.r_typ.resize(n2)
	var g0 := PackedFloat32Array()
	g0.resize(n2)
	for k in n2:
		var a := tab2[maxi(k - 1, 0)]
		var b := tab2[mini(k + 1, n2 - 1)]
		g0[k] = atan2(b.x - a.x, b.y - a.y)
	for k in n2:
		var d := Vector2(sin(g0[k]), cos(g0[k]))
		var rgt := Vector2(-d.y, d.x)          # rechts in Fahrtrichtung (wie Fahrlinie.spur_punkt)
		rl.mitte[k] = Vector3(tab2[k].x, taby[k], tab2[k].y)
		var q := tab2[k] + rgt * prof.spur
		rl.spur[k] = Vector3(q.x, taby[k], q.y)
		rl.r_typ[k] = tabr[k]
	for k in n2:
		var a := rl.spur[maxi(k - 1, 0)]
		var b := rl.spur[mini(k + 1, n2 - 1)]
		rl.gier[k] = atan2(b.x - a.x, b.z - a.z)
	for k in n2:
		var ka := maxi(k - 2, 0)
		var kb := mini(k + 2, n2 - 1)
		var ds := 0.0
		for m in range(ka, kb):
			ds += Vector2(rl.spur[m].x, rl.spur[m].z).distance_to(Vector2(rl.spur[m + 1].x, rl.spur[m + 1].z))
		rl.kappa[k] = wrapf(rl.gier[kb] - rl.gier[ka], -PI, PI) / maxf(ds, 1e-3) if kb > ka else 0.0
	# Spitzenkrümmung je Probe (Einzelschritt, für das Gierraten-Limit: Knicke liegen in 1–2 m)
	rl.kappa_spitze.resize(n2)
	for k in n2:
		var mx := 0.0
		for m in range(maxi(k - 2, 0), mini(k + 2, n2 - 1)):
			var ds1 := maxf(Vector2(rl.spur[m].x, rl.spur[m].z).distance_to(Vector2(rl.spur[m + 1].x, rl.spur[m + 1].z)), 0.05)
			mx = maxf(mx, absf(wrapf(rl.gier[m + 1] - rl.gier[m], -PI, PI)) / ds1)
		rl.kappa_spitze[k] = maxf(mx, absf(rl.kappa[k]))
		var sa := maxi(k - 12, 0)
		var sb := mini(k + 12, n2 - 1)
		rl.steigung[k] = (taby[sb] - taby[sa]) / maxf(float(sb - sa) * DS, 1e-3) if sb > sa else 0.0
	# 4) Kurvenzone: Tempofaktor f(p)
	_kurvenzone(rl, prof)
	return rl


static func _bei(pts: PackedVector2Array, s_arr: PackedFloat32Array, s: float) -> Vector2:
	var n := s_arr.size()
	if n == 0:
		return Vector2.ZERO
	if s <= s_arr[0]:
		return pts[0]
	if s >= s_arr[n - 1]:
		return pts[n - 1]
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if s_arr[mid] <= s:
			lo = mid
		else:
			hi = mid
	var seg := maxf(s_arr[hi] - s_arr[lo], 1e-6)
	return pts[lo].lerp(pts[hi], (s - s_arr[lo]) / seg)


static func _bei_f(a: PackedFloat32Array, s_arr: PackedFloat32Array, s: float) -> float:
	var n := s_arr.size()
	if s <= s_arr[0]:
		return a[0]
	if s >= s_arr[n - 1]:
		return a[n - 1]
	var lo := 0
	var hi := n - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if s_arr[mid] <= s:
			lo = mid
		else:
			hi = mid
	return lerpf(a[lo], a[hi], (s - s_arr[lo]) / maxf(s_arr[hi] - s_arr[lo], 1e-6))


## Monotone Abbildung x → y über die Stützstellen (xs aufsteigend, ys aufsteigend).
static func _map(xs: PackedFloat32Array, ys: PackedFloat32Array, x: float) -> float:
	return _bei_f(ys, xs, x)


## Tempofaktor je m: Kurvenlimit aus Querbeschleunigung (Profilwert des Wegtyps) und Gierrate, geglättet,
## Defizit davor/danach mit Überhöhung eingeholt, Rest über skala (Zeit über das ganze Leg erhalten).
static func _kurvenzone(rl: Routenlinie, prof: Profil) -> void:
	var n := rl.spur.size()
	var roh := PackedFloat32Array()
	roh.resize(n)
	var v := prof.v_nom
	for k in n:
		var ka := absf(rl.kappa[k])
		var ks := rl.kappa_spitze[k]
		var fk := 1.0
		if ks > 1e-5:
			var f_aq := sqrt(prof.a_quer_ref(rl.r_typ[k]) / (v * v * maxf(ka, 1e-6)))
			var f_om := 0.9 * prof.omega_max / (v * ks)
			fk = minf(1.0, minf(f_aq, f_om))
		if fk < prof.kf_min - 1e-3:
			rl.n_unter_kf += 1
		# Kurvenfaktor min ist das Ziel; ist der Bogen enger als der Wegtyp erlaubt, gewinnen E3/E4 (gezählt)
		roh[k] = clampf(fk, 0.2, 1.0)
	# Glätten: gleitendes Minimum ±W, dann Kastenmittel ±W (bleibt ≤ Rohlimit, stetig)
	var w := 8
	var mn := _fenster_min(roh, w)
	var f := _kasten(mn, w)
	rl.f_lim = f.duplicate()
	# Überhöhung: je Zone (f < 1) Defizit Σ(1/f − 1) davor und danach mit fb einholen
	var fb := 1.0 + prof.ueb * 0.9
	var g := 1.0 - 1.0 / fb
	var belegt := PackedByteArray()
	belegt.resize(n)
	for k in n:
		belegt[k] = 1 if f[k] < 0.999 else 0
	var k0 := 0
	while k0 < n:
		if belegt[k0] == 0 or f[k0] >= 0.999:
			k0 += 1
			continue
		var k1 := k0
		var defizit := 0.0
		while k1 < n and f[k1] < 0.999:
			defizit += 1.0 / f[k1] - 1.0
			k1 += 1
		var bedarf := int(ceil(defizit / g))
		var a := k0 - 1
		var b := k1
		var seite := 0
		var sperr := 0
		while bedarf > 0 and sperr < 2:
			var idx := a if seite == 0 else b
			if idx >= 0 and idx < n and belegt[idx] == 0 and f[idx] >= 0.999:
				f[idx] = fb
				belegt[idx] = 2
				bedarf -= 1
				sperr = 0
			elif idx < 0 or idx >= n or belegt[idx] == 1:
				sperr += 1
			if seite == 0:
				a -= 1
			else:
				b += 1
			seite = 1 - seite
		k0 = k1
	f = _kasten(f, 3)
	for k in n:
		f[k] = clampf(minf(f[k], maxf(rl.f_lim[k], 1.0 + prof.ueb) if rl.f_lim[k] >= 0.999 else rl.f_lim[k]), 0.2, 1.0 + prof.ueb)
	rl.f = f
	# φ⁻¹: U(p) = ∫ dp / f, normiert auf U(L) = L (Zeit über das Leg exakt erhalten)
	var U := PackedFloat32Array()
	U.resize(n)
	for k in range(1, n):
		var ds := DS if k < n - 1 else maxf(rl.laenge - (n - 2) * DS, 1e-6)
		U[k] = U[k - 1] + ds * 0.5 * (1.0 / f[k - 1] + 1.0 / f[k])
	var uges := U[-1] if n > 0 else 0.0
	rl.skala = uges / maxf(rl.laenge, 1e-6) if rl.laenge > 0.0 else 1.0
	var ps := PackedFloat32Array()
	for k in n:
		ps.append(minf(k * DS, rl.laenge))
	for k in n:
		U[k] = U[k] / maxf(rl.skala, 1e-6)
	var nu := int(ceil(rl.laenge)) + 1
	rl.p_von_u.resize(nu)
	var j := 0
	for m in nu:
		var u := minf(float(m), rl.laenge)
		while j < n - 2 and U[j + 1] < u:
			j += 1
		var seg := maxf(U[j + 1] - U[j], 1e-6) if n > 1 else 1.0
		rl.p_von_u[m] = lerpf(ps[j], ps[mini(j + 1, n - 1)], clampf((u - U[j]) / seg, 0.0, 1.0)) if n > 1 else 0.0


static func _fenster_min(a: PackedFloat32Array, w: int) -> PackedFloat32Array:
	var n := a.size()
	var o := PackedFloat32Array()
	o.resize(n)
	for k in n:
		var m := a[k]
		for j in range(maxi(0, k - w), mini(n, k + w + 1)):
			m = minf(m, a[j])
		o[k] = m
	return o


static func _kasten(a: PackedFloat32Array, w: int) -> PackedFloat32Array:
	var n := a.size()
	var o := PackedFloat32Array()
	o.resize(n)
	for k in n:
		var s := 0.0
		var c := 0
		for j in range(maxi(0, k - w), mini(n, k + w + 1)):
			s += a[j]
			c += 1
		o[k] = s / maxf(c, 1)
	return o


## Darstellungszustand eines Fahrzeugs (Folger + Pose). Eine Instanz je Sim-Fahrzeug.
class Zustand extends RefCounted:
	var prof: Profil
	var legs: Array = []                 # [Routenlinie Leg 0 (hin), Leg 1 (zurück)]
	# Sim-Proben (monotoner Zähler Z über alle Legs)
	var z_vor := 0.0
	var z_akt := 0.0
	var hist: Array = []                 # [[z_anfang, leg]] jüngste zuerst hinten, max 4
	var aus_vor: Array = []              # [pos, gier] Probe Tick n−1 (Easing aus)
	var aus_akt: Array = []
	var leg_akt := 0
	var off_akt := 0.0
	var tick := 0
	# Folger (Easing an)
	var zb := 0.0
	var vb := 0.0
	var wende_t := 1.0
	var wende_von: Array = []            # [pos, gier] am Leg-Ende
	var wende_z := -1.0                  # Leg-Anfang, an dem die Wende läuft
	# Ausgabe
	var pos := Vector3.ZERO
	var gier := 0.0
	var basis := Basis.IDENTITY          # Instanz-Basis (an: nur Gier; aus: FAST-Mischung)
	## INSTANCE_CUSTOM nach Vertrag ProtoPrefabs (gang): x Gang = fmod(Gangstrecke m, 240), y Variante (setzt
	## proto_fahrzeuge), z Nicken rad (Drehung um +x, + = Bug senkt sich), w Wanken rad (Drehung um +z, + = linke
	## Modellseite hebt sich). Gangstrecke = Gangphase × ProtoPrefabs.SCHRITT_M (Schrittfrequenz gedeckelt, K31).
	var custom := Color(0, 0, 0, 0)
	var wipp := 0.0                      # Wippen des ganzen Gespanns in m (0..wipp_m), geht in den Instanz-Transform
	var p_bild := 0.0                    # Bildposition auf dem Bild-Leg (nach φ)
	var u_bild := 0.0
	var leg_bild := 0
	var v_p := 0.0                       # Bildtempo (m/Tick) auf der Fahrlinie
	var a_l := 0.0
	var in_wende := false
	var _p_alt := -1.0
	var _leg_alt := -1
	var _v_alt := 0.0

	func _init(p_prof: Profil, p_legs: Array) -> void:
		prof = p_prof
		legs = p_legs
		hist = [[0.0, 0]]

	## Sim-Probe nach jedem Tick: leg (0 hin / 1 zurück), d (m auf dem Leg).
	func probe(leg: int, d: float) -> void:
		tick += 1
		if leg != leg_akt:
			off_akt += (legs[leg_akt] as Routenlinie).laenge
			leg_akt = leg
			hist.append([off_akt, leg])
			if hist.size() > 4:
				hist.pop_front()
		z_vor = z_akt
		z_akt = off_akt + d
		aus_vor = aus_akt
		aus_akt = (legs[leg] as Routenlinie).aus_pose(d)
		if aus_vor.is_empty():
			aus_vor = aus_akt

	## Startzustand (ohne Vorgeschichte), z. B. beim Anlegen oder beim Umschalten auf „an“.
	func folger_setzen() -> void:
		zb = z_vor
		vb = maxf(0.0, z_akt - z_vor)
		wende_t = 1.0

	func _leg_bei(z: float) -> Array:
		var e: Array = hist[0]
		for h in hist:
			if h[0] <= z + 1e-6:
				e = h
		return e

	## Frame: alpha = Anteil im laufenden Tick (0..1), dt = Frame-Dauer in Ticks, an = Easing an.
	func frame(alpha: float, dt: float, an: bool) -> void:
		var r := lerpf(z_vor, z_akt, alpha)
		if not an:
			_frame_aus(alpha, r)
			return
		var v_ref := maxf(0.0, z_akt - z_vor)
		var e: Array = _leg_bei(zb)
		var rl: Routenlinie = legs[e[1]]
		var z_ende: float = e[0] + rl.laenge
		var p_jetzt := rl.phi(zb - e[0])
		# Bildtempo dp/dt = v_u · f(p) ≤ Limit: im Bogen f_lim · v_sim (E3/E4), sonst (1 + Überhöhung) · v_sim
		var fl := rl.f_lim_bei(p_jetzt)
		var vp_max := prof.v_nom * (fl if fl < 0.999 else 1.0 + prof.ueb)
		var v_cap := minf(prof.v_nom * (1.0 + prof.aufholen), vp_max / maxf(rl.f_bei(p_jetzt), 0.05))
		var luecke := r - zb
		var v_ziel := 0.0
		if v_ref > 0.0:
			v_ziel = v_ref + clampf(luecke * 0.25, -v_ref, prof.aufholen * prof.v_nom)
		elif luecke > 1e-4:
			v_ziel = prof.v_nom            # Sim steht am Halt, Bild fährt noch hin (Bremsgrenze unten)
		v_ziel = clampf(v_ziel, 0.0, v_cap)
		var dv := clampf(v_ziel - vb, -prof.a_brems() * dt, prof.a_max() * dt)
		vb += dv
		var rest := maxf(0.0, z_ende - zb)
		vb = minf(vb, sqrt(2.0 * prof.a_brems() * rest))
		var zn := zb + vb * dt
		if zn >= z_ende - 1e-4 and z_ende <= r + 1e-4:
			zn = z_ende                   # Halt am Leg-Ende erreicht (Sim war dort)
			vb = 0.0
		if zn > r:
			zn = r
			vb = minf(vb, v_ref)
		zb = maxf(zb, zn)
		# Bild-Leg und Pose
		e = _leg_bei(zb)
		var leg_b: int = e[1]
		rl = legs[leg_b]
		u_bild = zb - float(e[0])
		p_bild = rl.phi(u_bild)
		var p3 := rl.spur_punkt(p_bild)
		var g := rl.gier_bei(p_bild)
		# Wende: neues Leg begonnen → Pose von „Ende altes Leg“ über W/2 Ticks auf das neue überblenden
		if float(e[0]) > 0.0 and absf(float(e[0]) - wende_z) > 1e-3 and u_bild < prof.v_nom * prof.w:
			var alt := _leg_vor(float(e[0]))
			if not alt.is_empty():
				var rla: Routenlinie = legs[alt[1]]
				wende_von = [rla.spur_punkt(rla.laenge), rla.gier_bei(rla.laenge)]
				wende_z = float(e[0])
				wende_t = 0.0
		in_wende = wende_t < 1.0
		if in_wende:
			wende_t = minf(1.0, wende_t + dt / wende_ticks())
			var s := smoothstep(0.0, 1.0, wende_t)
			p3 = (wende_von[0] as Vector3).lerp(p3, s)
			g = lerp_angle(float(wende_von[1]), g, s)
		# Bildtempo und Haltung
		if _leg_alt == leg_b and _p_alt >= 0.0 and dt > 1e-6:
			v_p = (p_bild - _p_alt) / dt
		elif dt > 1e-6:
			v_p = vb * rl.f_bei(p_bild)
		a_l = (v_p - _v_alt) / dt if dt > 1e-6 else 0.0
		_v_alt = v_p
		_p_alt = p_bild
		_leg_alt = leg_b
		leg_bild = leg_b
		pos = p3
		gier = g
		basis = Basis(Vector3.UP, g)
		var kap := rl.kappa_bei(p_bild)
		var aq_ref := prof.a_quer_ref(rl.r_typ[mini(int(p_bild), rl.r_typ.size() - 1)])
		var roll := prof.roll_max * clampf(v_p * v_p * kap / maxf(aq_ref, 1e-6), -1.0, 1.0)
		var nick_dyn := -prof.nick_max * clampf(a_l / prof.a_max(), -1.0, 1.0)   # Bremsen: Bug taucht ein
		var nick := atan(rl.steigung_bei(p_bild)) + nick_dyn
		var v_rel := clampf(v_p / prof.v_nom, 0.0, 1.0)
		var stride_w := (1.0 + prof.ueb) * prof.v_nom * 10.0 / prof.wipp_hz      # m je Wipp-Periode
		var stride_g := (1.0 + prof.ueb) * prof.v_nom * 10.0 / prof.gang_hz      # m je Schritt-Periode (Deckel)
		wipp = prof.wipp_m * v_rel * 0.5 * (1.0 - cos(TAU * zb / stride_w))   # hebt, sinkt nie ein
		custom = Color(gang_m(zb / stride_g), 0.0, -nick, roll)

	## Gangphase (Schritte) → INSTANCE_CUSTOM.x in m: Schritte × SCHRITT_M, modulo PERIODE_M (nahtlos, TA-Shader).
	static func gang_m(schritte: float) -> float:
		return fposmod(schritte * ProtoPrefabs.SCHRITT_M, ProtoPrefabs.PERIODE_M)

	## Wende 180° mit Gierrate ≤ ω_max (smoothstep: Spitze 1,5 × Mittel).
	func wende_ticks() -> float:
		return 1.5 * PI / prof.omega_max

	func _leg_vor(z0: float) -> Array:
		var vor: Array = []
		for h in hist:
			if h[0] < z0 - 1e-6:
				vor = h
		return vor

	## Heutiges Spiel: Gerade zwischen Sim-Knoten, Basis linear zwischen den beiden Tick-Transforms (FAST).
	func _frame_aus(alpha: float, r: float) -> void:
		var pa: Vector3 = aus_vor[0]
		var pb: Vector3 = aus_akt[0]
		pos = pa.lerp(pb, alpha)
		var ba := Basis(Vector3.UP, float(aus_vor[1]))
		var bb := Basis(Vector3.UP, float(aus_akt[1]))
		basis = Basis(ba.x.lerp(bb.x, alpha), ba.y.lerp(bb.y, alpha), ba.z.lerp(bb.z, alpha))
		gier = lerp_angle(float(aus_vor[1]), float(aus_akt[1]), alpha)
		var stride_g := (1.0 + prof.ueb) * prof.v_nom * 10.0 / prof.gang_hz
		custom = Color(gang_m(r / stride_g), 0.0, 0.0, 0.0)
		wipp = 0.0
		zb = r
		vb = maxf(0.0, z_akt - z_vor)
		in_wende = false
		_p_alt = -1.0
