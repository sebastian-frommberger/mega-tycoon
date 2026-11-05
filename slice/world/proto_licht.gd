class_name ProtoLicht
extends RefCounted
## Prototyp-Welt (TA): Licht- und Umgebungsaufbau, aus proto/prototyp_welt.gd (_baue_umgebung) ausgelagert (WA-03a).
## WA-03b (RL-1 Relief): flachere Sonne aus NW (kartografische Konvention: bei Blick nach Norden Licht von oben links),
## Energie so ausgeglichen, dass ebene Wiese nicht dunkler wird; Umgebungslicht vom Himmel; dazu im Terrain-Shader
## Hangschummerung und Hoehentoenung (terrain_parameter). Messung und Werte: sprints/s8/umsetzung/WA-03b.md.
##   var l := ProtoLicht.baue(self)   ->  {"env": Environment, "sun": DirectionalLight3D}
## Haengt WorldEnvironment und Sonne als Kinder an `eltern`. Nebel-Abstand und Schattenreichweite setzt die Kamera
## weiter in prototyp_welt.gd (env.fog_depth_*, sun.directional_shadow_max_distance).

const SONNE_ROT_GRAD := Vector3(-27, -135, 0)    # vorher (-42, 38, 0): Licht aus SE, Relief wirkte bei Blick N invertiert
const SONNE_FARBE := Color(1.0, 0.92, 0.78)
const SONNE_ENERGIE := 0.69                      # vorher 0,52 (Ausgleich: ebene Wiese -1,8 % statt -19 % im Pilot)
const SONNE_SCHATTEN_DECKUNG := 0.5
const UMGEBUNG_QUELLE := Environment.AMBIENT_SOURCE_SKY   # vorher Farbe; Mischung Himmel/Farbe ueber UMGEBUNG_HIMMEL_ANTEIL
const UMGEBUNG_FARBE := Color(0.74, 0.81, 0.92)  # Farbanteil (1 - Himmelsanteil)
const UMGEBUNG_ENERGIE := 0.31                   # vorher 0,36; wirkt nur auf den Farbanteil (bei Anteil 1,0 gemessen: ohne Wirkung)
const UMGEBUNG_HIMMEL_ANTEIL := 0.5
# Terrain-Shader (proto_terrain.gdshader), 0 = aus. Schummerung wirkt im Bild ~2,6x staerker als aus 25-m-Neigung gerechnet
# (lokale Mesh-Normalen), daher klein: 0,01 + Toenung 0,06 geben zusammen +3,7 pp Hang-D (Messung WA-03b.md)
const SCHUMMER_STAERKE := 0.01
const SCHUMMER_VOLL_HANG := 0.15
const TOENUNG_STAERKE := 0.06
const HOEHE_TAL_M := 40.0
const HOEHE_KUPPE_M := 110.0


static func baue(eltern: Node) -> Dictionary:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.36, 0.56, 0.80)
	sm.sky_horizon_color = Color(0.76, 0.84, 0.91)
	sm.ground_horizon_color = Color(0.76, 0.84, 0.91)
	sm.ground_bottom_color = Color(0.62, 0.72, 0.80)
	var sky := Sky.new()
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = UMGEBUNG_QUELLE
	env.ambient_light_color = UMGEBUNG_FARBE
	env.ambient_light_energy = UMGEBUNG_ENERGIE
	env.ambient_light_sky_contribution = UMGEBUNG_HIMMEL_ANTEIL
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.76, 0.84, 0.91)
	env.fog_density = 1.0
	env.fog_depth_curve = 1.6
	env.fog_sky_affect = 0.0
	we.environment = env
	eltern.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = SONNE_ROT_GRAD
	sun.light_color = SONNE_FARBE
	sun.light_energy = SONNE_ENERGIE
	sun.shadow_enabled = true
	sun.shadow_opacity = SONNE_SCHATTEN_DECKUNG
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	eltern.add_child(sun)
	return {"env": env, "sun": sun}


## xz-Laufrichtung des Sonnenlichts (normiert), aus derselben Basis wie die DirectionalLight3D (-Z der Basis).
static func sonnenrichtung_xz(rot_grad: Vector3 = SONNE_ROT_GRAD) -> Vector2:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_grad.x), deg_to_rad(rot_grad.y), deg_to_rad(rot_grad.z)))
	var d := -b.z
	return Vector2(d.x, d.z).normalized()


## WA-03b: Relief-Parameter in das Terrain-Material (proto_terrain.gd _material).
static func terrain_parameter(m: ShaderMaterial, rot_grad: Vector3 = SONNE_ROT_GRAD) -> void:
	m.set_shader_parameter("schummer_staerke", SCHUMMER_STAERKE)
	m.set_shader_parameter("schummer_richtung", sonnenrichtung_xz(rot_grad))
	m.set_shader_parameter("schummer_voll_hang", SCHUMMER_VOLL_HANG)
	m.set_shader_parameter("toenung_staerke", TOENUNG_STAERKE)
	m.set_shader_parameter("hoehe_tal_m", HOEHE_TAL_M)
	m.set_shader_parameter("hoehe_kuppe_m", HOEHE_KUPPE_M)
