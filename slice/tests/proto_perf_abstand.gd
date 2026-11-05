extends SceneTree
## Phase 4 Welle 2 (Felix): live Dreiecke/DC über dem Kamera-Abstand (Kernmitte, Übersicht-Neigung), xvfb.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var s: Node = (load("res://proto/prototyp_welt.tscn") as PackedScene).instantiate()
	s.kette_modus = "fest"              # S8 AT-08: Szenen-Default ist "leer"; dieser Test misst die feste Kette
	root.add_child(s)
	await process_frame
	for d in [3000.0, 2500.0, 2000.0, 1800.0, 1500.0, 1200.0, 900.0, 600.0, 350.0]:
		s.setze_preset(1)
		s.abstand = d
		s._kamera_anwenden()
		for i in 4:
			await process_frame
		var z: Dictionary = s.zaehlung()
		var b: Node3D = s.get_node_or_null("ProtoTerrain/Baeume")
		var bt := 0
		if b != null:
			b.visible = false
			for i in 3:
				await process_frame
			bt = int(z["live_dreiecke"]) - int(s.zaehlung()["live_dreiecke"])
			b.visible = true
		print("ABSTAND %5.0f m  live %8d Dreiecke  %4d DC  davon Baeume %8d" % [d, z["live_dreiecke"], z["live_dc"], bt])
	quit(0)
