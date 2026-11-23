extends Node
## Entry scene: start dedicated server or client from CLI, then load the zone.

const GAME_WORLD := preload("res://scenes/game_world.tscn")
const NetConfig := preload("res://scripts/net_config.gd")


func _ready() -> void:
	var cfg: Dictionary = NetConfig.from_cmdline()
	if cfg.mode == "server":
		DisplayServer.window_set_title("Lineage 2d — Dedicated Server")
		# Prefer headless: `godot --headless -- --server`
		print("[bootstrap] Starting dedicated server on port %s" % cfg.port)
	else:
		var title := "Lineage 2d — Client"
		if str(cfg.display_name) != "":
			title += " (%s)" % cfg.display_name
		DisplayServer.window_set_title(title)
		print("[bootstrap] Connecting to %s:%s" % [cfg.host, cfg.port])

	var world: Node = GAME_WORLD.instantiate()
	world.set("net_cfg", cfg)
	add_child(world)
