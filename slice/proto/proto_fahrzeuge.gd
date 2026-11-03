extends Node3D
## Phase 4 Welle 2 (Felix, Integration): Fahrzeuge der Prototyp-Welt (Easing-Probe). Ein MultiMesh je Kategorie
## (fuhrwerk, postkutsche), je Frame für alle Fahrzeuge (≤ 10, kein Nah-LOD, 16 §2 schlank), keine
## Engine-Interpolation (physics_interpolation_mode OFF).
##
## Modell: ProtoPrefabs.fahrzeug(kategorie) (TA, world/proto_prefabs.gd) mit dem gemeinsamen Prefab-Shader
## (world/proto_prefab.gdshader, ein Material, kein material_override). Belegung INSTANCE_CUSTOM (eine Lösung für
## Felix' Easing und TAs Shader, siehe integration_w2.md):
##   x Gang  = fmod(Gangstrecke m, 240) – Räder drehen um ihre Achse, Pferdebeine pendeln, Rumpf wippt (Shader)
##   y Variante = ProtoPrefabs.variante_wert(i % 4) – Palettenzeile (Pferdefarbe)
##   z Nicken rad (um +x, + = Bug senkt sich: Steigung + Bremsnicken aus proto_easing)
##   w Wanken rad (um +z, + = linke Seite hebt sich: Querbeschleunigung in Kurven)
## Instanz-Transform: Position + Gier (orthonormal, E7) + Wippen des Gespanns als Höhe (0..wippen_cm).
## Use_colors = true mit Weiß (Compatibility-Renderer liefert sonst COLOR schwarz).

var ps = null                        # proto_sim.gd
var easing_an := true
var mmis: Dictionary = {}            # kat -> MultiMeshInstance3D
var masse_m: Dictionary = {}         # kat -> Vector2(laenge, breite)
var _slot: Array = []                # je Fahrzeug [kat, Index]
var frame_usec := 0                  # Kosten des letzten frame() (E8)
var regelwerk: Dictionary = {}
var _variante: PackedFloat32Array = []   # je Fahrzeug INSTANCE_CUSTOM.y


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
		_variante.append(ProtoPrefabs.variante_wert(_slot.size() % ProtoPrefabs.ZEILEN))
		je_kat[k] += 1
	for k in je_kat:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.use_colors = true             # ohne Instanzfarbe kam COLOR im Shader schwarz an (opengl3, 4.7.2)
		var d: Dictionary = ProtoPrefabs.fahrzeug(k)
		mm.mesh = d["mesh"]
		masse_m[k] = Vector2(float(d["laenge_m"]), float(d["breite_m"]))
		mm.instance_count = je_kat[k]
		for i in je_kat[k]:
			mm.set_instance_color(i, Color.WHITE)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "FZ_" + k
		mmi.multimesh = mm
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mm.custom_aabb = AABB(Vector3(-4000, -100, -4000), Vector3(8000, 400, 8000))   # Instanzen wandern über die Karte
		add_child(mmi)
		mmis[k] = mmi
	frame(0.0, 0.0)


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
		cu.g = _variante[i]
		pos.y += z.wipp
		mm.set_instance_transform(s[1], Transform3D(bas, pos))
		mm.set_instance_custom_data(s[1], cu)
	frame_usec = Time.get_ticks_usec() - t0


func dreiecke() -> int:
	var t := 0
	for k in mmis:
		var mm: MultiMesh = mmis[k].multimesh
		t += mm.mesh.get_faces().size() / 3 * mm.instance_count
	return t
