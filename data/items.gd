extends RefCounted
## Item templates + starter / upgrade gear for Human Fighter.

const SLOT_WEAPON := "weapon"
const SLOT_CHEST := "chest"
const SLOT_LEGS := "legs"
const SLOT_HEAD := "head"

## Visual tiers: 0 starter linen, 1 bronze, 2 steel — drive layered look.
const ITEMS := {
	"training_sword": {
		"name": "Training Sword",
		"slot": SLOT_WEAPON,
		"p_atk": 8,
		"visual": {"tier": 0, "weapon": "wood_blade"},
	},
	"bronze_sword": {
		"name": "Bronze Sword",
		"slot": SLOT_WEAPON,
		"p_atk": 22,
		"visual": {"tier": 1, "weapon": "bronze_blade"},
	},
	"steel_longsword": {
		"name": "Steel Longsword",
		"slot": SLOT_WEAPON,
		"p_atk": 38,
		"visual": {"tier": 2, "weapon": "steel_blade"},
	},
	"linen_tunic": {
		"name": "Linen Tunic",
		"slot": SLOT_CHEST,
		"p_def": 4,
		"visual": {"tier": 0, "chest": "linen"},
	},
	"bronze_breastplate": {
		"name": "Bronze Breastplate",
		"slot": SLOT_CHEST,
		"p_def": 14,
		"visual": {"tier": 1, "chest": "bronze"},
	},
	"steel_cuirass": {
		"name": "Steel Cuirass",
		"slot": SLOT_CHEST,
		"p_def": 26,
		"visual": {"tier": 2, "chest": "steel"},
	},
	"linen_pants": {
		"name": "Linen Pants",
		"slot": SLOT_LEGS,
		"p_def": 3,
		"visual": {"tier": 0, "legs": "linen"},
	},
	"bronze_greaves": {
		"name": "Bronze Greaves",
		"slot": SLOT_LEGS,
		"p_def": 10,
		"visual": {"tier": 1, "legs": "bronze"},
	},
	"steel_greaves": {
		"name": "Steel Greaves",
		"slot": SLOT_LEGS,
		"p_def": 18,
		"visual": {"tier": 2, "legs": "steel"},
	},
	"cloth_cap": {
		"name": "Cloth Cap",
		"slot": SLOT_HEAD,
		"p_def": 2,
		"visual": {"tier": 0, "head": "cloth"},
	},
	"bronze_helm": {
		"name": "Bronze Helm",
		"slot": SLOT_HEAD,
		"p_def": 8,
		"visual": {"tier": 1, "head": "bronze"},
	},
	"steel_helm": {
		"name": "Steel Helm",
		"slot": SLOT_HEAD,
		"p_def": 14,
		"visual": {"tier": 2, "head": "steel"},
	},
}

const STARTER_LOADOUT := {
	SLOT_WEAPON: "training_sword",
	SLOT_CHEST: "linen_tunic",
	SLOT_LEGS: "linen_pants",
	SLOT_HEAD: "cloth_cap",
}


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func display_name(item_id: String) -> String:
	var it: Dictionary = get_item(item_id)
	return str(it.get("name", item_id))
