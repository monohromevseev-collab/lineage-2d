extends RefCounted
class_name DataRegistry
## Loads High Five runtime JSON (Talking Island slice) once per process.

const RUNTIME_DIR := "res://data/runtime"

static var _loaded: bool = false
static var meta: Dictionary = {}
static var items: Dictionary = {}
static var npcs: Dictionary = {}
static var drops: Dictionary = {}
static var spawns: Array = []
static var exp_table: Dictionary = {}
static var classes: Dictionary = {}
static var aliases: Dictionary = {}
static var quests: Dictionary = {}
static var friendly_npcs: Dictionary = {}
static var dialogs: Dictionary = {}


static func ensure_loaded() -> void:
	if _loaded:
		return
	meta = _read_json("%s/meta.json" % RUNTIME_DIR)
	items = _read_json("%s/items.json" % RUNTIME_DIR)
	npcs = _read_json("%s/npcs.json" % RUNTIME_DIR)
	drops = _read_json("%s/drops.json" % RUNTIME_DIR)
	var spawn_doc: Dictionary = _read_json("%s/spawns.json" % RUNTIME_DIR)
	spawns = spawn_doc.get("spawns", [])
	exp_table = _read_json("%s/exp.json" % RUNTIME_DIR)
	classes = _read_json("%s/classes.json" % RUNTIME_DIR)
	quests = _read_json("%s/quests.json" % RUNTIME_DIR)
	friendly_npcs = _read_json("%s/friendly_npcs.json" % RUNTIME_DIR)
	dialogs = _read_json("%s/dialogs.json" % RUNTIME_DIR)
	aliases = meta.get("aliases", {})
	_loaded = true
	print("[data] HF runtime loaded: %d items, %d npcs, %d spawns, %d quests (commit %s)" % [
		items.size(), npcs.size(), spawns.size(), quests.size(), str(meta.get("datapack_commit", "?"))
	])


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing runtime data: %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open %s" % path)
		return {}
	var text := f.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON object: %s" % path)
		return {}
	return parsed


static func resolve_id(id: String) -> String:
	ensure_loaded()
	if aliases.has(id):
		return str(aliases[id])
	return id


static func get_item(item_id: String) -> Dictionary:
	ensure_loaded()
	var key := resolve_id(item_id)
	return items.get(key, {})


static func get_npc(npc_id: String) -> Dictionary:
	ensure_loaded()
	var key := resolve_id(npc_id)
	return npcs.get(key, {})


static func get_char_class(class_id: String = "0") -> Dictionary:
	ensure_loaded()
	return classes.get(class_id, {})


static func get_quest(quest_id: String) -> Dictionary:
	ensure_loaded()
	return quests.get(quest_id, {})


static func get_friendly_npc(npc_id: String) -> Dictionary:
	ensure_loaded()
	return friendly_npcs.get(npc_id, {})


static func xp_to_next(level: int) -> int:
	ensure_loaded()
	var to_next: Dictionary = exp_table.get("to_next", {})
	return int(to_next.get(str(level), 999999))


static func xp_cumulative(level: int) -> int:
	ensure_loaded()
	var cum: Dictionary = exp_table.get("cumulative", {})
	return int(cum.get(str(level), 0))


## HF death-drop: each group rolls independently; one item picked by weight inside the group.
static func roll_drops(npc_id: String) -> Array:
	ensure_loaded()
	var key := resolve_id(npc_id)
	var doc: Dictionary = drops.get(key, {})
	var groups: Array = doc.get("groups", [])
	var out: Array = []
	for g in groups:
		var gchance := float(g.get("chance", 0.0))
		# L2J group chance is 0–100 percent.
		if randf() * 100.0 > gchance:
			continue
		var pool: Array = g.get("items", [])
		if pool.is_empty():
			continue
		var total := 0.0
		for it in pool:
			total += float(it.get("chance", 0.0))
		if total <= 0.0:
			continue
		var roll := randf() * total
		var acc := 0.0
		for it in pool:
			acc += float(it.get("chance", 0.0))
			if roll <= acc:
				var mn := int(it.get("min", 1))
				var mx := int(it.get("max", 1))
				var qty := mn if mx <= mn else randi_range(mn, mx)
				for _i in range(qty):
					out.append(str(it.get("item_id", "")))
				break
	return out
