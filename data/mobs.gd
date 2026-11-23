extends RefCounted
## Thin wrapper over HF DataRegistry NPCs + Cedric / village spawns.


static func _reg():
	return preload("res://data/data_registry.gd")


static func get_template(id: String) -> Dictionary:
	var t: Dictionary = _reg().get_npc(id)
	if t.is_empty():
		return {}
	var color_arr: Array = t.get("color", [0.6, 0.6, 0.6])
	var col := Color(1, 1, 1)
	if color_arr.size() >= 3:
		col = Color(float(color_arr[0]), float(color_arr[1]), float(color_arr[2]))
	# Tutorial / library Gremlins are always passive unless spawn overrides.
	var default_aggro := float(t.get("aggro_range", 0.0))
	if str(t.get("id", id)) == "18342":
		default_aggro = 0.0
	return {
		"name": str(t.get("name", id)),
		"level": int(t.get("level", 1)),
		"max_hp": int(t.get("max_hp", 50)),
		"p_atk": int(t.get("p_atk", 5)),
		"p_def": int(t.get("p_def", 4)),
		"xp": int(t.get("xp_reward", 20)),
		"speed": float(t.get("speed", 70.0)),
		"aggro_range": default_aggro,
		"attack_range": float(t.get("attack_range", 42.0)),
		"attack_interval": float(t.get("attack_interval", 1.4)),
		"silhouette": str(t.get("silhouette", "fox")),
		"color": col,
		"npc_id": str(t.get("id", id)),
	}


static var SPAWNS: Array:
	get:
		var out: Array = []
		for entry in _reg().spawns:
			var pos_doc: Dictionary = entry.get("pos", {})
			var aggro := -1.0
			if entry.has("aggro_range"):
				aggro = float(entry.get("aggro_range", 0.0))
			out.append({
				"template": str(entry.get("npc_id", "")),
				"pos": Vector2(float(pos_doc.get("x", 0.0)), float(pos_doc.get("y", 0.0))),
				"aggro_range": aggro,
				"zone": str(entry.get("zone", "")),
			})
		return out


static var TEMPLATES: Dictionary:
	get:
		return _reg().npcs
