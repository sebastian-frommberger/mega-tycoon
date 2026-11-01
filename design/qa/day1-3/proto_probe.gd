extends SceneTree
var main
var frame := 0
var t0
func _initialize():
	t0 = Time.get_ticks_msec()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	print("LOAD_MS ", Time.get_ticks_msec() - t0)
func _digest() -> String:
	var parts := PackedStringArray()
	parts.append(str(int(main.money * 100)))
	parts.append(str(main.vehicles.size()))
	for v in main.vehicles:
		parts.append("%d,%d,%d" % [int(v.position.x*1000), int(v.position.z*1000), v.cargo])
	for b in main.buildings:
		parts.append("%d,%d" % [int(b.stock_out*1000), int(b.stock_in*1000)])
	return str("\n".join(parts)).md5_text()
func _process(delta):
	frame += 1
	if frame == 5:
		var f = main.cell_to_building[Vector2i(20,104)]
		var m = main.cell_to_building[Vector2i(30,113)]
		main._buy(f); main._buy(m)
		main._build_track(main._l_path(Vector2i(24,106), Vector2i(29,113)), false)
		main._create_line(f, m, main._line_filter(f, m), "truck")
		print("VEH ", main.vehicles.size(), " money ", int(main.money))
	if frame == 10 or frame == 300 or frame == 600:
		print("FRAME ", frame, " delta ", delta, " DIGEST ", _digest(), " money ", main.money)
	if frame >= 600:
		return true
	return false
