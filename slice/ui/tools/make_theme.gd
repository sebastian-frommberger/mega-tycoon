extends SceneTree
## Speichert das im Code gebaute Theme als res://ui/theme/mega_theme.tres (für den Editor / Inspector).
##   godot --headless --path slice -s res://ui/tools/make_theme.gd
## Quelle der Wahrheit bleibt ui/theme/theme_builder.gd; die .tres wird daraus erzeugt, nie von Hand editiert.

const TB := preload("res://ui/theme/theme_builder.gd")


func _initialize() -> void:
	var t: Theme = TB.build()
	var err := ResourceSaver.save(t, "res://ui/theme/mega_theme.tres")
	print("mega_theme.tres gespeichert: ", error_string(err), " · Typen: ", t.get_type_list().size())
	quit(0 if err == OK else 1)
