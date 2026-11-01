extends Node3D
## Testszene Terrain-Shader (S7 Sophie): Noise-Heightmap 6,4 km (256 Zellen a 25 m), Gebirge NW, Fluss als Rinne.
## Start: godot --path . res://world/art/terrain_test.tscn ; Shots: -s res://world/art/terrain_test.gd? nein -> terrain_shots.gd
const N := 256
const CELL := 25.0
const WATER := 0.0

static func height(x: float, z: float, hills: FastNoiseLite, ridge: FastNoiseLite) -> float:
	var h := 28.0 + hills.get_noise_2d(x, z) * 55.0
	# Gebirge NW: Ridged-Noise mit Maske
	var d := Vector2(x, z).distance_to(Vector2(900.0, 900.0))
	var m := smoothstep(2900.0, 800.0, d)
	h += m * (260.0 + (ridge.get_noise_2d(x, z) * 0.5 + 0.5) * 760.0)
	# Fluss x = f(z), Maeander, Tal verbreitert Richtung Sueden
	var cx := 3300.0 + sin(z * 0.0021) * 520.0 + sin(z * 0.0057 + 1.3) * 150.0
	var dist := absf(x - cx)
	var tal := 1.0 - smoothstep(0.0, 750.0, dist)
	h = lerpf(h, minf(h, 16.0 + dist * 0.012), tal * 0.85)
	var rinne := 1.0 - smoothstep(18.0, 60.0, dist)
	h = lerpf(h, WATER - 4.0, rinne)
	return h

func build() -> MeshInstance3D:
	var hills := FastNoiseLite.new(); hills.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH; hills.frequency = 1.0 / 2600.0; hills.fractal_octaves = 4; hills.seed = 7
	var ridge := FastNoiseLite.new(); ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX; ridge.frequency = 1.0 / 1500.0; ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED; ridge.fractal_octaves = 4; ridge.seed = 11
	var hs := PackedFloat32Array(); hs.resize((N + 1) * (N + 1))
	for j in N + 1:
		for i in N + 1:
			hs[j * (N + 1) + i] = height(i * CELL, j * CELL, hills, ridge)
	var verts := PackedVector3Array(); var norms := PackedVector3Array(); var idx := PackedInt32Array()
	verts.resize((N + 1) * (N + 1)); norms.resize((N + 1) * (N + 1))
	for j in N + 1:
		for i in N + 1:
			verts[j * (N + 1) + i] = Vector3(i * CELL, hs[j * (N + 1) + i], j * CELL)
			var hl := hs[j * (N + 1) + maxi(i - 1, 0)]; var hr := hs[j * (N + 1) + mini(i + 1, N)]
			var hu := hs[maxi(j - 1, 0) * (N + 1) + i]; var hd := hs[mini(j + 1, N) * (N + 1) + i]
			norms[j * (N + 1) + i] = Vector3(hl - hr, 2.0 * CELL, hu - hd).normalized()
	for j in N:
		for i in N:
			var a := j * (N + 1) + i
			idx.append_array([a, a + 1, a + N + 1, a + 1, a + N + 2, a + N + 1])
	var arr := []; arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_NORMAL] = norms; arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var sm := ShaderMaterial.new(); sm.shader = load("res://world/art/terrain.gdshader")
	sm.set_shader_parameter("wasser_hoehe", WATER)
	mesh.surface_set_material(0, sm)
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.name = "Terrain"
	return mi

func _ready() -> void:
	add_child(build())
	var dl := DirectionalLight3D.new(); dl.rotation_degrees = Vector3(-48, -35, 0); dl.shadow_enabled = false; add_child(dl)
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.62, 0.74, 0.88)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.75, 0.8, 0.88); e.ambient_light_energy = 0.55
	e.fog_enabled = true; e.fog_light_color = Color(0.62, 0.74, 0.88); e.fog_density = 0.00004
	we.environment = e; add_child(we)
	var cam := Camera3D.new(); cam.name = "Cam"; cam.fov = 50.0; cam.far = 20000.0; add_child(cam)
	cam.position = Vector3(3200, 2600, 5600); cam.look_at(Vector3(2600, 100, 2600))
