extends Node3D
## Phase 4 Welle 2 (Felix): Fahrzeuge der Prototyp-Welt (Easing-Probe). Ein MultiMesh je Kategorie (fuhrwerk,
## postkutsche), je Frame für alle Fahrzeuge (≤ 10, kein Nah-LOD, 16 §2 schlank), keine Engine-Interpolation
## (physics_interpolation_mode OFF), Haltung + Gangphase über INSTANCE_CUSTOM (proto_fahrzeug.gdshader).
##
## Modell: ProtoPrefabs.fahrzeug(kategorie) (TA, res://world/proto_prefabs.gd), sobald vorhanden (Hook, per Pfad
## geladen, damit die Szene ohne die Datei kompiliert); sonst Platzhalter aus Boxen in Zielmaßen
## (regelwerk.skalen.fahrzeuge_dm: Fuhrwerk 9,5 × 2,2 m, Postkutsche 12,5 × 2,2 m) mit Rädern und Pferdebeinen.
## Nutzt das Prefab-Mesh nicht den Fahrzeug-Shader, wandert die Haltung in den Instanz-Transform (Rotation, bleibt
## orthonormal) und die Gangphase steht trotzdem in INSTANCE_CUSTOM (Vertrag `gang`).

const SHADER := preload("res://proto/proto_fahrzeug.gdshader")
const PREFABS := "res://world/proto_prefabs.gd"
const KAT_TYP := {"fuhrwerk": "fuhrwerk_2_pferde", "postkutsche": "postkutsche_4_pferde"}

var ps = null                        # proto_sim.gd
var easing_an := true
var mmis: Dictionary = {}            # kat -> MultiMeshInstance3D
var haltung_im_shader: Dictionary = {}   # kat -> bool
var quelle: Dictionary = {}          # kat -> "prefab" | "platzhalter"
var masse_m: Dictionary = {}         # kat -> Vector2(laenge, breite)
var _slot: Array = []                # je Fahrzeug [kat, Index]
var frame_usec := 0                  # Kosten des letzten frame() (E8)
var regelwerk: Dictionary = {}


func bauen(p_ps, p_regelwerk: Dictionary) -> void:
	ps = p_ps
	regelwerk = p_regelwerk
	name = "Fahrzeuge"
	var je_kat := {}
	for f in ps.fahrzeuge:
		var k: String = f["kat"]
		if not je_kat.has(k):
			je_kat[k] = 0
		_slot.append([k, je_kat[k]])
		je_kat[k] += 1
	for k in je_kat:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.use_colors = true             # ohne Instanzfarbe kam COLOR im Shader schwarz an (opengl3, 4.7.2)
		var r := _modell(k)
		mm.mesh = r[0]
		mm.instance_count = je_kat[k]
		for i in je_kat[k]:
			mm.set_instance_color(i, Color.WHITE)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "FZ_" + k
		mmi.multimesh = mm
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if r[1] != null:
			mmi.material_override = r[1]
		mm.custom_aabb = AABB(Vector3(-4000, -100, -4000), Vector3(8000, 400, 8000))   # Instanzen wandern über die Karte
		add_child(mmi)
		mmis[k] = mmi
	frame(0.0, 0.0)


## [Mesh, Material-Override oder null]
func _modell(kat: String) -> Array:
	if ResourceLoader.exists(PREFABS):
		var scr: Script = load(PREFABS)
		if scr != null and scr.can_instantiate():
			var d = scr.call("fahrzeug", kat)
			if d is Dictionary and d.get("mesh") is Mesh:
				quelle[kat] = "prefab"
				var sh := false
				var m: Mesh = d["mesh"]
				for s in m.get_surface_count():
					var mat := m.surface_get_material(s)
					if mat is ShaderMaterial and (mat as ShaderMaterial).shader != null \
							and (mat as ShaderMaterial).shader.code.contains("INSTANCE_CUSTOM"):
						sh = true
				haltung_im_shader[kat] = sh
				masse_m[kat] = Vector2(float(d.get("laenge_m", 0.0)), float(d.get("breite_m", 0.0)))
				return [m, null]
	quelle[kat] = "platzhalter"
	haltung_im_shader[kat] = true
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var prof = ps.profil(kat) if ps != null else null
	if prof != null:
		mat.set_shader_parameter("rad_verhaeltnis", prof.rad_u_s / maxf(prof.gang_hz, 0.1))
	return [platzhalter_mesh(kat), mat]


## Platzhalter: Wagen/Kutsche + Räder + Pferde (Körper, Kopf, Beine) in Zielmaßen. COLOR.a = Teil-ID / 10,
## UV2 = Drehpunkt (y, z) für Rad/Bein. Ursprung Mitte Boden, Front +z.
func platzhalter_mesh(kat: String) -> ArrayMesh:
	var typ: String = KAT_TYP.get(kat, "fuhrwerk_2_pferde")
	var fz: Dictionary = regelwerk.get("skalen", {}).get("fahrzeuge_dm", {}).get(typ, {})
	var l := float(fz.get("l", 95 if kat == "fuhrwerk" else 125)) / 10.0
	var b := float(fz.get("b", 22)) / 10.0
	masse_m[kat] = Vector2(l, b)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var holz := Color(0.52, 0.38, 0.24)
	var kasten := Color(0.36, 0.30, 0.42) if kat == "postkutsche" else Color(0.58, 0.45, 0.28)
	var pferd := Color(0.42, 0.29, 0.19)
	var rad := Color(0.25, 0.2, 0.16)
	var z0 := -l * 0.5
	var wl := 4.4 if kat == "fuhrwerk" else 5.2           # Wagenlänge
	var rd := 1.2 if kat == "fuhrwerk" else 1.4           # Raddurchmesser
	# Wagenkasten
	if kat == "fuhrwerk":
		_box(st, Vector3(0, 1.05, z0 + wl * 0.5), Vector3(b, 0.35, wl), kasten, 0)
		_box(st, Vector3(b * 0.5 - 0.05, 1.45, z0 + wl * 0.5), Vector3(0.1, 0.45, wl), holz, 0)
		_box(st, Vector3(-b * 0.5 + 0.05, 1.45, z0 + wl * 0.5), Vector3(0.1, 0.45, wl), holz, 0)
		_box(st, Vector3(0, 1.55, z0 + wl * 0.45), Vector3(b - 0.3, 0.3, wl * 0.7), Color(0.8, 0.7, 0.4), 0)   # Ladung
	else:
		_box(st, Vector3(0, 1.0, z0 + wl * 0.5), Vector3(b, 0.3, wl), holz, 0)
		_box(st, Vector3(0, 1.95, z0 + wl * 0.5), Vector3(b - 0.1, 1.6, wl * 0.7), kasten, 0)
		_box(st, Vector3(0, 2.85, z0 + wl * 0.5), Vector3(b, 0.2, wl * 0.75), Color(0.2, 0.18, 0.18), 0)
		_box(st, Vector3(0, 2.2, z0 + wl - 0.4), Vector3(b - 0.4, 0.3, 0.6), holz, 0)                      # Kutschbock
	for zr in [z0 + 0.8, z0 + wl - 0.8]:
		for sx in [-1.0, 1.0]:
			var c := Vector3(sx * (b * 0.5 + 0.05), rd * 0.5, zr)
			_box(st, c, Vector3(0.12, rd, rd), rad, 1, Vector2(c.y, c.z))
	# Deichsel
	var pz0 := z0 + wl + 0.6
	_box(st, Vector3(0, 1.0, (z0 + wl + l * 0.5) * 0.5), Vector3(0.12, 0.12, l * 0.5 - z0 - wl), holz, 0)
	# Pferde: Fuhrwerk 1 Paar, Kutsche 2 Paare (Länge je 2,6 m, Abstand 0,4 m)
	var paare := 1 if kat == "fuhrwerk" else 2
	var pl := (l * 0.5 - pz0 - 0.4 * (paare - 1)) / paare
	for pi in paare:
		var pzm := pz0 + pl * 0.5 + pi * (pl + 0.4)
		for sx in [-0.5, 0.5]:
			var x: float = sx * 0.95
			_box(st, Vector3(x, 1.45, pzm), Vector3(0.55, 0.75, pl * 0.75), pferd, 4)
			_box(st, Vector3(x, 1.95, pzm + pl * 0.42), Vector3(0.3, 0.55, 0.45), pferd, 4)
			var hz := [pzm + pl * 0.28, pzm - pl * 0.28]
			for li in 2:
				for lx in [-0.18, 0.18]:
					var ph := 2 if (li == 0) == (lx < 0.0) else 3   # diagonal gleichphasig (Trab)
					var hip := Vector2(1.1, float(hz[li]))
					_box(st, Vector3(x + lx, 0.55, hz[li]), Vector3(0.13, 1.1, 0.13), pferd.darkened(0.2), ph, hip)
	st.generate_normals()
	return st.commit()


func _box(st: SurfaceTool, c: Vector3, g: Vector3, col: Color, teil: int, piv := Vector2.ZERO) -> void:
	var h := g * 0.5
	var p := [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	var cc := Color(col.r, col.g, col.b, teil / 10.0)
	for f in [[0, 3, 2, 1], [4, 5, 6, 7], [0, 4, 7, 3], [1, 2, 6, 5], [3, 7, 6, 2], [0, 1, 5, 4]]:
		for t in [[0, 2, 1], [0, 3, 2]]:
			for k in t:
				st.set_color(cc)
				st.set_uv2(piv)
				st.add_vertex(c + p[f[k]])


## Je Frame: alpha = Anteil im laufenden Tick, dt = Frame-Dauer in Ticks.
func frame(alpha: float, dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	if ps == null:
		return
	for i in ps.fahrzeuge.size():
		var f: Dictionary = ps.fahrzeuge[i]
		var z = f["zustand"]
		z.frame(alpha, dt, easing_an)
		var s: Array = _slot[i]
		var mm: MultiMesh = mmis[s[0]].multimesh
		var bas: Basis = z.basis
		var pos: Vector3 = z.pos
		var cu: Color = z.custom
		if easing_an and not haltung_im_shader.get(s[0], true):
			bas = bas * Basis(Vector3.RIGHT, -cu.a) * Basis(Vector3.BACK, cu.b)
			pos.y += cu.g
		mm.set_instance_transform(s[1], Transform3D(bas, pos))
		mm.set_instance_custom_data(s[1], cu)
	frame_usec = Time.get_ticks_usec() - t0


func dreiecke() -> int:
	var t := 0
	for k in mmis:
		var mm: MultiMesh = mmis[k].multimesh
		t += mm.mesh.get_faces().size() / 3 * mm.instance_count
	return t
