extends RefCounted
## Mob templates scattered across the expanded Talking Island meadow.

const TEMPLATES := {
	"keltir": {
		"name": "Keltir",
		"max_hp": 55,
		"p_atk": 6,
		"p_def": 4,
		"xp": 28,
		"speed": 70.0,
		"aggro_range": 0.0,
		"attack_range": 42.0,
		"attack_interval": 1.4,
		"silhouette": "fox",
		"color": Color(0.72, 0.48, 0.28),
		"loot": [
			{"item_id": "bronze_sword", "chance": 0.55, "min": 1, "max": 1},
			{"item_id": "bronze_breastplate", "chance": 0.40, "min": 1, "max": 1},
		],
	},
	"wolf": {
		"name": "Wolf",
		"max_hp": 90,
		"p_atk": 11,
		"p_def": 7,
		"xp": 48,
		"speed": 95.0,
		"aggro_range": 110.0,
		"attack_range": 46.0,
		"attack_interval": 1.2,
		"silhouette": "wolf",
		"color": Color(0.45, 0.48, 0.55),
		"loot": [
			{"item_id": "bronze_greaves", "chance": 0.50, "min": 1, "max": 1},
			{"item_id": "bronze_helm", "chance": 0.45, "min": 1, "max": 1},
			{"item_id": "steel_longsword", "chance": 0.18, "min": 1, "max": 1},
		],
	},
	"orc_grunt": {
		"name": "Orc Grunt",
		"max_hp": 160,
		"p_atk": 16,
		"p_def": 14,
		"xp": 85,
		"speed": 55.0,
		"aggro_range": 130.0,
		"attack_range": 50.0,
		"attack_interval": 1.6,
		"silhouette": "orc",
		"color": Color(0.35, 0.55, 0.32),
		"loot": [
			{"item_id": "steel_cuirass", "chance": 0.55, "min": 1, "max": 1},
			{"item_id": "steel_greaves", "chance": 0.45, "min": 1, "max": 1},
			{"item_id": "steel_helm", "chance": 0.40, "min": 1, "max": 1},
			{"item_id": "steel_longsword", "chance": 0.35, "min": 1, "max": 1},
		],
	},
}

## Spread across a large seamless meadow (world coords).
const SPAWNS := [
	{"template": "keltir", "pos": Vector2(220, 40)},
	{"template": "keltir", "pos": Vector2(280, 110)},
	{"template": "keltir", "pos": Vector2(180, 160)},
	{"template": "keltir", "pos": Vector2(340, 60)},
	{"template": "keltir", "pos": Vector2(420, 140)},
	{"template": "wolf", "pos": Vector2(-320, -80)},
	{"template": "wolf", "pos": Vector2(-400, 40)},
	{"template": "wolf", "pos": Vector2(-280, 120)},
	{"template": "wolf", "pos": Vector2(-480, -40)},
	{"template": "orc_grunt", "pos": Vector2(80, -320)},
	{"template": "orc_grunt", "pos": Vector2(-60, -380)},
	{"template": "orc_grunt", "pos": Vector2(160, -400)},
	{"template": "keltir", "pos": Vector2(520, -100)},
	{"template": "wolf", "pos": Vector2(-200, 280)},
	{"template": "orc_grunt", "pos": Vector2(300, 300)},
]


static func get_template(id: String) -> Dictionary:
	return TEMPLATES.get(id, {})
