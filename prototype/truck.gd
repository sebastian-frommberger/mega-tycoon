extends Node3D
## Fahrzeug (Lkw oder Zug): pendelt zwischen Quelle und Ziel.
## Laden und Entladen kosten Zeit (Umschlag), Unterhalt läuft immer.

enum State { LOADING, TO_DST, UNLOADING, TO_SRC }

var kind_name := "Lkw"
var src: Node3D
var dst: Node3D
var filter: Array = []     # erlaubte Güter, leer = alles
var good := ""             # aktuell geladenes Gut
var path: Array = []
var idx := 0
var state := State.LOADING
var cargo := 0
var capacity := 10
var speed := 4.0
var load_rate := 5.0       # Einheiten pro Sekunde beim Umschlag
var max_wait := 5.0        # so lange wird auf volle Ladung gewartet
var upkeep := 1.5          # $ pro Sekunde
var wait := 0.0
var load_acc := 0.0
var unload_time := 0.0
var distance := 0
var on_delivery: Callable
var age := 0.0
var income_total := 0.0
var upkeep_total := 0.0
var load_mesh: MeshInstance3D
var load_mat: StandardMaterial3D
var good_colors := {}


func setup(p_kind: String, p_src: Node3D, p_dst: Node3D, p_filter: Array, cells: Array, p_on_delivery: Callable, params: Dictionary) -> void:
	kind_name = p_kind
	src = p_src
	dst = p_dst
	filter = p_filter
	on_delivery = p_on_delivery
	capacity = params["capacity"]
	speed = params["speed"]
	load_rate = params["load_rate"]
	max_wait = params["max_wait"]
	upkeep = params["upkeep"]
	good_colors = params["good_colors"]
	var y: float = params["y"]
	for c in cells:
		path.append(Vector3(c.x + 0.5, y, c.y + 0.5))
	distance = cells.size()
	position = path[0]

	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = params["size"]
	body.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = params["color"]
	body.material_override = mat
	add_child(body)

	load_mesh = MeshInstance3D.new()
	var lbox := BoxMesh.new()
	var s: Vector3 = params["size"]
	lbox.size = Vector3(s.x * 0.85, 0.28, s.z * 0.6)
	load_mesh.mesh = lbox
	load_mat = StandardMaterial3D.new()
	load_mesh.material_override = load_mat
	load_mesh.position = Vector3(0, s.y * 0.5 + 0.14, -s.z * 0.1)
	load_mesh.visible = false
	add_child(load_mesh)


func _process(delta: float) -> void:
	age += delta
	upkeep_total += upkeep * delta
	match state:
		State.LOADING:
			wait += delta
			if cargo == 0:
				good = src.best_good(filter)
				if good != "":
					load_mat.albedo_color = good_colors.get(good, Color.WHITE)
			if good != "":
				load_acc += load_rate * delta
				var want := mini(capacity - cargo, int(load_acc))
				if want > 0:
					var got: int = src.take(good, want)
					cargo += got
					load_acc -= want
			load_mesh.visible = cargo > 0
			if cargo >= capacity or (cargo > 0 and wait > max_wait):
				state = State.TO_DST
				idx = 1
				wait = 0.0
				load_acc = 0.0
		State.TO_DST:
			if _drive(delta, true):
				state = State.UNLOADING
				unload_time = cargo / load_rate
		State.UNLOADING:
			unload_time -= delta
			if unload_time <= 0.0:
				dst.deliver(good, cargo)
				on_delivery.call(self, cargo)
				cargo = 0
				load_mesh.visible = false
				state = State.TO_SRC
				idx = path.size() - 2
		State.TO_SRC:
			if _drive(delta, false):
				state = State.LOADING
				wait = 0.0


## Gewinn pro Minute seit Kauf (Einnahmen minus Unterhalt).
func profit_per_minute() -> float:
	return (income_total - upkeep_total) / maxf(age, 30.0) * 60.0


## Fährt zum nächsten Wegpunkt. Gibt true zurück, wenn das Ende erreicht ist.
func _drive(delta: float, fwd: bool) -> bool:
	if idx < 0 or idx >= path.size():
		return true
	var target: Vector3 = path[idx]
	var to := target - position
	var step := speed * delta
	if to.length() <= step:
		position = target
		idx += 1 if fwd else -1
		return idx < 0 or idx >= path.size()
	position += to.normalized() * step
	rotation.y = atan2(to.x, to.z)
	return false
