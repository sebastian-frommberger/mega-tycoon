class_name ProtoLicht
extends RefCounted
## Prototyp-Welt (TA, WA-03a): Licht- und Umgebungsaufbau, aus proto/prototyp_welt.gd (_baue_umgebung) ausgelagert.
## Werte UNVERAENDERT uebernommen (Stand S7/S8-Start). Neue Werte (RL-1) kommen erst in WA-03b.
##   var l := ProtoLicht.baue(self)   ->  {"env": Environment, "sun": DirectionalLight3D}
## Haengt WorldEnvironment und Sonne als Kinder an `eltern`. Nebel-Abstand und Schattenreichweite setzt die Kamera
## weiter in prototyp_welt.gd (env.fog_depth_*, sun.directional_shadow_max_distance).

const SONNE_ROT_GRAD := Vector3(-42, 38, 0)
const SONNE_FARBE := Color(1.0, 0.92, 0.78)
const SONNE_ENERGIE := 0.52
const SONNE_SCHATTEN_DECKUNG := 0.5
const UMGEBUNG_FARBE := Color(0.74, 0.81, 0.92)
const UMGEBUNG_ENERGIE := 0.36


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
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = UMGEBUNG_FARBE
	env.ambient_light_energy = UMGEBUNG_ENERGIE
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
