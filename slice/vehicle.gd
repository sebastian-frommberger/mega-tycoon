extends RefCounted
## Fahrzeug (Lkw oder Zug) aus dem Prototyp (truck.gd), umgebaut auf feste Ticks (tick_ms aus JSON)
## und auf economy.gd: Laden über load_gate/on_load (Lizenzpflicht, Herkunftsstempel), Entladen über
## on_unload (Ertrag nur beim Endabnehmer). Gezeichnet wird über eine MultiMesh in main.gd (kein Node je
## Fahrzeug), damit die Bench mit 5.000 Einheiten dieselbe Logik misst wie das Spiel.
## Ablauf wie Prototyp: an der Quelle auf Ladung warten (max. max_wait_ticks, dann mit Teilladung los),
## Umschlagzeit = load_ticks × Ladung / Kapazität, zum Ziel fahren, entladen, zurück.

const Economy := preload("res://economy.gd")

enum State { IDLE, LOADING, TO_DST, UNLOADING, TO_SRC }

var vid := 0
var rindex := 0                # Index in der MultiMesh seines Typs
var slot := -1                 # Slot im EcoShim (v_id/v_cargo)
var type := "truck"            # "truck" | "train"
var kind_name := "Lkw"
var src = null                 # Building
var dst = null
var path := PackedVector2Array()
var prog := 0.0                # Position entlang path (in Feldern)
var state := State.IDLE
var cap := 10
var speed := 0.6               # Felder je Tick (tempo_mm_pro_tick / feld_mm)
var load_ticks := 100
var max_wait_ticks := 50
var fix_cent := 0              # je Periode
var var_cent_per_field := 0
var wait := 0
var timer := 0
var no_licence := false        # wartet an einer Quelle ohne gültige Lizenz
var leave_empty := false       # nur Bench: ohne Ladung weiterfahren statt warten
var field_acc := 0.0
var age_ticks := 0
var income_total := 0          # Cent
var var_cost_total := 0        # Cent Fahrkosten (Unterhalt wird aus age_ticks gerechnet)
var trip_var := 0              # Fahrkosten seit der letzten Entladung
var trip_start_age := 0        # age_ticks bei der letzten Entladung
var periode_ticks := 600
var deliveries := 0
var deliveries_profit := 0
var distance := 0              # Pfadlänge in Feldern
var path_end := 0.0
var group_key := ""            # Linienliste: Typ|Quelle|Ziel
var paid_cent := 0             # Kaufpreis (0 = Startpaket), Basis für die Erstattung beim Auflösen (B-01)
var sold := false              # B-01: verkauft; bleibt als IDLE im Array, damit MultiMesh-Indizes stabil bleiben


func assign(p_src, p_dst, cells: Array) -> void:
	src = p_src
	dst = p_dst
	path = PackedVector2Array()
	for c in cells:
		path.append(Vector2(c.x + 0.5, c.y + 0.5))
	distance = cells.size() - 1
	path_end = float(distance)
	group_key = "%s|%s|%s" % [type, src.map_id, dst.map_id]
	prog = 0.0
	state = State.LOADING
	wait = 0
	timer = 0


func cargo(m) -> int:
	return m.shim.v_cargo[slot]


## Ein Simulations-Tick. m = main.gd (eco, shim, charge()).
func tick(m) -> void:
	age_ticks += 1
	# schneller Pfad: fahren (die meisten Fahrzeuge in den meisten Ticks)
	if state == State.TO_DST:
		prog += speed
		field_acc += speed
		if field_acc >= 1.0:
			_pay_fields(m)
		if prog >= path_end:
			field_acc -= prog - path_end
			prog = path_end
			state = State.UNLOADING
			timer = maxi(1, load_ticks * cargo(m) / cap)
		return
	if state == State.TO_SRC:
		prog -= speed
		field_acc += speed
		if field_acc >= 1.0:
			_pay_fields(m)
		if prog <= 0.0:
			field_acc += prog
			prog = 0.0
			state = State.LOADING
			wait = 0
		return
	match state:
		State.IDLE:
			return
		State.LOADING:
			if timer > 0:
				timer -= 1
				if timer == 0:
					state = State.TO_DST
				return
			var k: int = src.station
			var gate: int = m.eco.load_gate(m.shim, slot, k)
			if gate == Economy.L_SKIP:       # Restladung an Bord: wieder zum Ziel
				state = State.TO_DST
				return
			if gate == Economy.L_WAIT:       # keine Lizenz
				no_licence = true
				return
			no_licence = false
			wait += 1
			var stock: int = m.shim.st_stock[k]
			if stock >= cap or (stock > 0 and wait >= max_wait_ticks):
				var amount := mini(stock, cap)
				m.shim.st_stock[k] = stock - amount
				m.shim.v_cargo[slot] = amount
				m.eco.on_load(m.shim, slot, k, amount)
				timer = maxi(1, load_ticks * amount / cap)
				wait = 0
			elif leave_empty and wait >= max_wait_ticks:
				state = State.TO_DST
				wait = 0
		State.UNLOADING:
			timer -= 1
			if timer <= 0:
				var n := cargo(m)
				if n > 0:
					var before: int = m.eco.revenue_total
					var given: int = m.eco.on_unload(m.shim, slot, dst.station)
					m.shim.v_cargo[slot] = n - given
					var income: int = m.eco.revenue_total - before
					if given > 0:
						var tc := trip_cost()
						income_total += income
						deliveries += 1
						if income > tc:
							deliveries_profit += 1
						m.on_delivery(self, given, income, tc)
						trip_var = 0
						trip_start_age = age_ticks
				state = State.TO_SRC


## Fahrkosten je ganz gefahrenem Feld (vehicles.json variabel_cent_pro_feld).
func _pay_fields(m) -> void:
	var whole := int(field_acc)
	field_acc -= whole
	var c := whole * var_cent_per_field
	m.charge(c)
	var_cost_total += c
	trip_var += c


## Unterhalt (fix je Periode, anteilig nach Ticks) plus Fahrkosten, ohne Kaufpreis. Abgebucht wird der
## Unterhalt zentral in main.sim_tick; hier nur die Zuordnung für Linienliste und „Lieferung mit Gewinn“.
func cost_total() -> int:
	return age_ticks * fix_cent / periode_ticks + var_cost_total


## Kosten seit der letzten Entladung (Unterhalt anteilig + Fahrkosten).
func trip_cost() -> int:
	return (age_ticks - trip_start_age) * fix_cent / periode_ticks + trip_var


## Weltposition (x, z) und Blickrichtung für die Darstellung; alpha = Anteil bis zum nächsten Tick.
func world_xz(alpha: float) -> Vector3:
	if path.size() == 0:
		return Vector3.ZERO
	var p := prog
	if state == State.TO_DST:
		p = minf(prog + speed * alpha, path.size() - 1)
	elif state == State.TO_SRC:
		p = maxf(prog - speed * alpha, 0.0)
	var i := int(p)
	var f := p - i
	var a: Vector2 = path[mini(i, path.size() - 1)]
	var b: Vector2 = path[mini(i + 1, path.size() - 1)]
	var q := a.lerp(b, f)
	var d := b - a
	if state == State.TO_SRC:
		d = -d
	var yaw := atan2(d.x, d.y) if d.length_squared() > 0.0 else 0.0
	return Vector3(q.x, yaw, q.y)


func profit_per_minute(ticks_per_min: int) -> float:
	return float(income_total - cost_total()) / 100.0 / maxf(float(age_ticks), 300.0) * ticks_per_min
