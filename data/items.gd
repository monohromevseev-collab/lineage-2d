extends RefCounted
## Thin wrapper over HF DataRegistry items (Talking Island slice).

const SLOT_WEAPON := "weapon"
const SLOT_CHEST := "chest"
const SLOT_LEGS := "legs"
const SLOT_HEAD := "head"
const SLOT_GLOVES := "gloves"
const SLOT_FEET := "feet"
const SLOT_NECK := "neck"


static func _reg():
	return preload("res://data/data_registry.gd")


static func get_item(item_id: String) -> Dictionary:
	return _reg().get_item(item_id)


static func display_name(item_id: String) -> String:
	var it: Dictionary = get_item(item_id)
	return str(it.get("name", item_id))


static var STARTER_LOADOUT: Dictionary:
	get:
		var cls: Dictionary = _reg().get_char_class("0")
		var loadout: Dictionary = cls.get("starter_loadout", {})
		return {
			SLOT_WEAPON: str(loadout.get("weapon", "1")),
			SLOT_CHEST: str(loadout.get("chest", "1146")),
			SLOT_LEGS: str(loadout.get("legs", "1147")),
			SLOT_HEAD: str(loadout.get("head", "")),
			SLOT_GLOVES: "",
			SLOT_FEET: "",
			SLOT_NECK: "",
		}


## Legacy toy ids still resolve via DataRegistry aliases.
static var ITEMS: Dictionary:
	get:
		return _reg().items
