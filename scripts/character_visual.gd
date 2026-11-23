extends Node2D
## Layered ¾ isometric Human Fighter. Gear tiers visibly recolor / reshape layers.

@onready var shadow: Polygon2D = $Shadow
@onready var legs: Polygon2D = $Legs
@onready var torso: Polygon2D = $Torso
@onready var arms: Polygon2D = $Arms
@onready var head: Polygon2D = $Head
@onready var hair: Polygon2D = $Hair
@onready var helm: Polygon2D = $Helm
@onready var weapon: Polygon2D = $Weapon
@onready var accent: Polygon2D = $Accent

## Human skin / hair palette (readable vs gear).
const SKIN := Color(0.93, 0.78, 0.62)
const SKIN_SHADE := Color(0.82, 0.62, 0.48)
const HAIR := Color(0.35, 0.22, 0.12)

const LINEN := Color(0.78, 0.72, 0.58)
const LINEN_DARK := Color(0.62, 0.56, 0.42)
const BRONZE := Color(0.72, 0.48, 0.22)
const BRONZE_DARK := Color(0.48, 0.30, 0.12)
const STEEL := Color(0.55, 0.62, 0.72)
const STEEL_DARK := Color(0.28, 0.34, 0.42)
const STEEL_EDGE := Color(0.78, 0.86, 0.95)

var _facing: float = 1.0
var _attack_flash: float = 0.0


func _ready() -> void:
	_build_base_shapes()
	apply_gear({})


func _process(delta: float) -> void:
	if _attack_flash > 0.0:
		_attack_flash = maxf(0.0, _attack_flash - delta * 3.0)
		weapon.rotation = -0.55 * _attack_flash * _facing
		modulate = Color(1, 1, 1).lerp(Color(1.25, 1.1, 0.85), _attack_flash)
	else:
		weapon.rotation = -0.15 * _facing
		modulate = Color(1, 1, 1)


func play_attack_flash() -> void:
	_attack_flash = 1.0


func set_facing_x(dx: float) -> void:
	if absf(dx) < 0.05:
		return
	_facing = 1.0 if dx >= 0.0 else -1.0
	scale.x = absf(scale.x) * _facing


func apply_gear(equipped: Dictionary) -> void:
	var Items := preload("res://data/items.gd")
	var chest := _visual_key(Items, equipped, Items.SLOT_CHEST, "chest", "linen")
	var legs_k := _visual_key(Items, equipped, Items.SLOT_LEGS, "legs", "linen")
	var head_k := _visual_key(Items, equipped, Items.SLOT_HEAD, "head", "cloth")
	var weap := _visual_key(Items, equipped, Items.SLOT_WEAPON, "weapon", "wood_blade")
	var tier := _max_tier(Items, equipped)

	_style_legs(legs_k)
	_style_chest(chest)
	_style_head(head_k)
	_style_weapon(weap)
	# Shoulder accent plate only on steel tier for a clear “upgraded” read.
	accent.visible = tier >= 2
	if accent.visible:
		accent.color = STEEL_EDGE
		accent.polygon = PackedVector2Array([
			Vector2(-10, -6), Vector2(-2, -12), Vector2(6, -8), Vector2(2, -2),
		])


func _visual_key(Items, equipped: Dictionary, slot: String, key: String, fallback: String) -> String:
	var id: String = str(equipped.get(slot, ""))
	if id == "" or id == "null":
		return fallback
	var it: Dictionary = Items.get_item(id)
	var vis: Dictionary = it.get("visual", {})
	return str(vis.get(key, fallback))


func _max_tier(Items, equipped: Dictionary) -> int:
	var t := 0
	for slot in equipped.keys():
		var id: String = str(equipped[slot])
		var it: Dictionary = Items.get_item(id)
		var vis: Dictionary = it.get("visual", {})
		t = maxi(t, int(vis.get("tier", 0)))
	return t


func _build_base_shapes() -> void:
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.polygon = PackedVector2Array([
		Vector2(0, 18), Vector2(20, 28), Vector2(0, 34), Vector2(-20, 28),
	])
	head.color = SKIN
	hair.color = HAIR
	arms.color = SKIN_SHADE


func _style_legs(kind: String) -> void:
	match kind:
		"bronze":
			legs.color = BRONZE_DARK
			legs.polygon = PackedVector2Array([
				Vector2(-9, 4), Vector2(9, 4), Vector2(12, 22), Vector2(3, 24),
				Vector2(0, 12), Vector2(-3, 24), Vector2(-12, 22),
			])
		"steel":
			legs.color = STEEL_DARK
			legs.polygon = PackedVector2Array([
				Vector2(-10, 2), Vector2(10, 2), Vector2(14, 22), Vector2(4, 26),
				Vector2(0, 12), Vector2(-4, 26), Vector2(-14, 22),
			])
		_:
			legs.color = LINEN_DARK
			legs.polygon = PackedVector2Array([
				Vector2(-8, 4), Vector2(8, 4), Vector2(10, 22), Vector2(2, 22),
				Vector2(0, 12), Vector2(-2, 22), Vector2(-10, 22),
			])


func _style_chest(kind: String) -> void:
	match kind:
		"bronze":
			torso.color = BRONZE
			torso.polygon = PackedVector2Array([
				Vector2(-14, -10), Vector2(14, -10), Vector2(16, 8), Vector2(0, 14), Vector2(-16, 8),
			])
			arms.color = BRONZE_DARK
		"steel":
			torso.color = STEEL
			torso.polygon = PackedVector2Array([
				Vector2(-16, -12), Vector2(16, -12), Vector2(18, 8), Vector2(0, 16), Vector2(-18, 8),
			])
			arms.color = STEEL_DARK
		_:
			torso.color = LINEN
			torso.polygon = PackedVector2Array([
				Vector2(-12, -8), Vector2(12, -8), Vector2(13, 8), Vector2(0, 12), Vector2(-13, 8),
			])
			arms.color = SKIN_SHADE
	arms.polygon = PackedVector2Array([
		Vector2(-18, -6), Vector2(-10, -8), Vector2(-8, 6), Vector2(-16, 10),
		Vector2(16, 10), Vector2(8, 6), Vector2(10, -8), Vector2(18, -6),
	])


func _style_head(kind: String) -> void:
	head.polygon = PackedVector2Array([
		Vector2(-8, -28), Vector2(8, -28), Vector2(10, -16), Vector2(0, -12), Vector2(-10, -16),
	])
	hair.polygon = PackedVector2Array([
		Vector2(-9, -30), Vector2(9, -30), Vector2(11, -22), Vector2(-11, -22),
	])
	match kind:
		"bronze":
			helm.visible = true
			hair.visible = false
			helm.color = BRONZE
			helm.polygon = PackedVector2Array([
				Vector2(-11, -32), Vector2(11, -32), Vector2(13, -18), Vector2(0, -14), Vector2(-13, -18),
				Vector2(-8, -26), Vector2(8, -26),
			])
		"steel":
			helm.visible = true
			hair.visible = false
			helm.color = STEEL_EDGE
			helm.polygon = PackedVector2Array([
				Vector2(0, -40), Vector2(12, -30), Vector2(14, -18), Vector2(0, -12), Vector2(-14, -18), Vector2(-12, -30),
			])
		_:
			helm.visible = false
			hair.visible = true


func _style_weapon(kind: String) -> void:
	weapon.position = Vector2(18, -4)
	match kind:
		"bronze_blade":
			weapon.color = BRONZE
			weapon.polygon = PackedVector2Array([
				Vector2(0, 10), Vector2(4, 10), Vector2(5, -18), Vector2(2, -28), Vector2(-1, -18),
			])
		"steel_blade":
			weapon.color = STEEL_EDGE
			weapon.polygon = PackedVector2Array([
				Vector2(-1, 12), Vector2(5, 12), Vector2(7, -8), Vector2(4, -34), Vector2(1, -36), Vector2(-2, -20),
			])
		_:
			weapon.color = Color(0.55, 0.38, 0.18)
			weapon.polygon = PackedVector2Array([
				Vector2(0, 8), Vector2(3, 8), Vector2(4, -14), Vector2(1, -20), Vector2(-1, -14),
			])
