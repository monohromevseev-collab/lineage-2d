extends Node2D
## Pixel-art Human Fighter (m/f) with gear tint layers; race silhouette scaffolds.

@onready var shadow: Polygon2D = $Shadow
@onready var legs: Polygon2D = $Legs
@onready var torso: Polygon2D = $Torso
@onready var arms: Polygon2D = $Arms
@onready var head: Polygon2D = $Head
@onready var hair: Polygon2D = $Hair
@onready var helm: Polygon2D = $Helm
@onready var weapon: Polygon2D = $Weapon
@onready var accent: Polygon2D = $Accent

const TEX_M := "res://assets/characters/human_fighter_m.png"
const TEX_F := "res://assets/characters/human_fighter_f.png"

## Race visual scaffolds (silhouette hints from L2 race ref).
const RACE_PROFILES := {
	"human": {"scale": 1.0, "skin": Color(0.93, 0.78, 0.62), "ear": "none", "wing": false, "height": 1.0},
	"elf": {"scale": 0.98, "skin": Color(0.95, 0.88, 0.78), "ear": "long", "wing": false, "height": 1.02},
	"dark_elf": {"scale": 1.0, "skin": Color(0.35, 0.42, 0.55), "ear": "up", "wing": false, "height": 1.04},
	"orc": {"scale": 1.12, "skin": Color(0.45, 0.55, 0.38), "ear": "none", "wing": false, "height": 1.08},
	"dwarf": {"scale": 0.82, "skin": Color(0.90, 0.72, 0.55), "ear": "short", "wing": false, "height": 0.78},
	"kamael": {"scale": 1.02, "skin": Color(0.92, 0.86, 0.82), "ear": "none", "wing": true, "height": 1.06},
}

var _facing: float = 1.0
var _attack_flash: float = 0.0
var moving: bool = false
var _anim_t: float = 0.0
var _base_leg_y: float = 0.0
var _base_arm_y: float = 0.0
var _base_torso_y: float = 0.0
var _sprite: Sprite2D
var _wing: Polygon2D
var _ear_l: Polygon2D
var _ear_r: Polygon2D
var sex: String = "male"
var race_id: String = "human"
var _use_pixel: bool = true
var _race_modulate: Color = Color(1, 1, 1)
var _equipped_cache: Dictionary = {}
var _loaded_sheet: String = ""


func _ready() -> void:
	_build_base_shapes()
	_ensure_sprite()
	_apply_race_profile(race_id)
	apply_gear(_equipped_cache)
	_base_leg_y = legs.position.y
	_base_arm_y = arms.position.y
	_base_torso_y = torso.position.y


func _ensure_sprite() -> void:
	if _sprite:
		return
	_sprite = Sprite2D.new()
	_sprite.name = "PixelBody"
	_sprite.centered = true
	_sprite.position = Vector2(0, -6)
	_sprite.z_index = 2
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(1.0, 1.0)
	add_child(_sprite)
	_wing = Polygon2D.new()
	_wing.name = "Wing"
	_wing.visible = false
	_wing.z_index = -1
	add_child(_wing)
	_ear_l = Polygon2D.new()
	_ear_r = Polygon2D.new()
	_ear_l.visible = false
	_ear_r.visible = false
	add_child(_ear_l)
	add_child(_ear_r)
	_load_sex_texture()


func _load_sex_texture() -> void:
	## Load PNG from disk (bypass stale .godot/imported cache).
	var path := TEX_M if sex != "female" else TEX_F
	if path == _loaded_sheet and _sprite and _sprite.texture != null and _use_pixel:
		_set_poly_visible(false)
		return
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.new()
	var err := img.load(abs_path)
	if err == OK and img.get_width() > 0:
		var tex := ImageTexture.create_from_image(img)
		_sprite.texture = tex
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_use_pixel = true
		_loaded_sheet = path
		_set_poly_visible(false)
		print("[visual] pixel sheet %s %sx%s sex=%s" % [path, img.get_width(), img.get_height(), sex])
		return
	# Fallback to ResourceLoader if Image.load failed.
	if ResourceLoader.exists(path):
		_sprite.texture = load(path)
		_use_pixel = true
		_loaded_sheet = path
		_set_poly_visible(false)
		print("[visual] resource sheet %s sex=%s" % [path, sex])
		return
	_use_pixel = false
	_loaded_sheet = ""
	_set_poly_visible(true)
	push_warning("[visual] missing pixel sheet %s — polygons fallback" % path)


func _set_poly_visible(on: bool) -> void:
	# Keep weapon/accent available for gear overlays; hide body polygons when pixel sheet is on.
	for n in [legs, torso, arms, head, hair, helm]:
		if n:
			n.visible = on
	if not on:
		# Pixel mode: body from sheet; weapon/accent toggled by apply_gear.
		if helm:
			helm.visible = false
	if _sprite:
		_sprite.visible = not on


func configure(p_race: String = "human", p_sex: String = "male") -> void:
	race_id = p_race
	sex = p_sex
	if _sprite == null:
		_ensure_sprite()
	else:
		_load_sex_texture()
	_apply_race_profile(race_id)
	apply_gear(_equipped_cache)


func _apply_race_profile(rid: String) -> void:
	var prof: Dictionary = RACE_PROFILES.get(rid, RACE_PROFILES["human"])
	var h: float = float(prof.get("height", 1.0))
	var sc: float = float(prof.get("scale", 1.0))
	scale = Vector2(sc * _facing, h)
	_race_modulate = Color(1, 1, 1)
	# Slight skin tint for non-human scaffolds when using human sheet as base.
	if rid == "orc":
		_race_modulate = Color(0.75, 0.95, 0.7)
	elif rid == "dark_elf":
		_race_modulate = Color(0.7, 0.75, 0.95)
	elif rid == "elf":
		_race_modulate = Color(1.02, 1.0, 0.95)
	elif rid == "dwarf":
		_race_modulate = Color(1.0, 0.95, 0.85)
	elif rid == "kamael":
		_race_modulate = Color(1.0, 0.96, 0.98)
	if _sprite:
		_sprite.modulate = _race_modulate
	_wing.visible = bool(prof.get("wing", false))
	if _wing.visible:
		_wing.color = Color(0.92, 0.92, 0.95, 0.9)
		_wing.polygon = PackedVector2Array([
			Vector2(-6, -10), Vector2(-28, -36), Vector2(-18, -8), Vector2(-22, 8), Vector2(-4, 4),
		])
	var ear: String = str(prof.get("ear", "none"))
	_ear_l.visible = ear != "none"
	_ear_r.visible = ear != "none"
	if ear == "long":
		_ear_l.color = prof.skin
		_ear_r.color = prof.skin
		_ear_l.polygon = PackedVector2Array([Vector2(-14, -28), Vector2(-28, -30), Vector2(-12, -20)])
		_ear_r.polygon = PackedVector2Array([Vector2(14, -28), Vector2(28, -30), Vector2(12, -20)])
	elif ear == "up":
		_ear_l.color = prof.skin
		_ear_r.color = prof.skin
		_ear_l.polygon = PackedVector2Array([Vector2(-12, -30), Vector2(-18, -42), Vector2(-8, -24)])
		_ear_r.polygon = PackedVector2Array([Vector2(12, -30), Vector2(18, -42), Vector2(8, -24)])
	elif ear == "short":
		_ear_l.color = prof.skin
		_ear_r.color = prof.skin
		_ear_l.polygon = PackedVector2Array([Vector2(-10, -22), Vector2(-16, -24), Vector2(-10, -16)])
		_ear_r.polygon = PackedVector2Array([Vector2(10, -22), Vector2(16, -24), Vector2(10, -16)])


func _process(delta: float) -> void:
	_anim_t += delta * (9.0 if moving else 2.2)
	var bob := sin(_anim_t) * (3.2 if moving else 1.1)
	var sway := cos(_anim_t * 0.5) * (0.08 if moving else 0.02)
	if _use_pixel and _sprite:
		_sprite.position.y = -8 + bob
		_sprite.rotation = sway * 0.4
		if _wing.visible:
			_wing.position.y = bob
			_wing.rotation = sway
		if _ear_l.visible:
			_ear_l.position.y = bob * 0.9
			_ear_r.position.y = bob * 0.9
	else:
		legs.position.y = _base_leg_y + bob * 0.35
		torso.position.y = _base_torso_y + bob
		arms.position.y = _base_arm_y + bob * 0.7
		head.position.y = bob * 0.9
		hair.position.y = bob * 0.9
		helm.position.y = bob * 0.9
		accent.position.y = bob
		if moving:
			legs.rotation = sin(_anim_t) * 0.18
			arms.rotation = -sin(_anim_t) * 0.22
		else:
			legs.rotation = lerp_angle(legs.rotation, 0.0, 8.0 * delta)
			arms.rotation = lerp_angle(arms.rotation, sway, 6.0 * delta)

	if _attack_flash > 0.0:
		_attack_flash = maxf(0.0, _attack_flash - delta * 3.0)
		weapon.rotation = -0.7 * _attack_flash
		modulate = Color(1, 1, 1).lerp(Color(1.25, 1.1, 0.85), _attack_flash)
	else:
		weapon.rotation = -0.12 + (sin(_anim_t) * 0.08 if moving else 0.0)
		modulate = Color(1, 1, 1)


func set_moving(is_moving: bool) -> void:
	moving = is_moving


func play_attack_flash() -> void:
	_attack_flash = 1.0


func set_facing_x(dx: float) -> void:
	if absf(dx) < 0.05:
		return
	_facing = 1.0 if dx >= 0.0 else -1.0
	var prof: Dictionary = RACE_PROFILES.get(race_id, RACE_PROFILES["human"])
	var sc: float = float(prof.get("scale", 1.0))
	var h: float = float(prof.get("height", 1.0))
	scale = Vector2(absf(sc) * _facing, h)


func apply_gear(equipped: Dictionary) -> void:
	_equipped_cache = equipped.duplicate() if equipped else {}
	var Items := preload("res://data/items.gd")
	var tier := _max_tier(Items, equipped)
	if _use_pixel and _sprite:
		# Gear readability: tint + optional weapon polygon overlay.
		var tint := Color(1, 1, 1)
		if tier >= 2:
			tint = Color(0.85, 0.9, 1.05)  # steel sheen
		elif tier == 1:
			tint = Color(1.05, 0.95, 0.8)  # bronze warmth
		_sprite.modulate = Color(
			_race_modulate.r * tint.r,
			_race_modulate.g * tint.g,
			_race_modulate.b * tint.b
		)
		weapon.visible = true
		_style_weapon(_visual_key(Items, equipped, Items.SLOT_WEAPON, "weapon", "wood_blade"))
		accent.visible = tier >= 2
		if accent.visible:
			accent.color = Color(0.78, 0.86, 0.95)
			accent.polygon = PackedVector2Array([
				Vector2(-8, -18), Vector2(-2, -24), Vector2(4, -18), Vector2(0, -12),
			])
		return
	var chest := _visual_key(Items, equipped, Items.SLOT_CHEST, "chest", "linen")
	var legs_k := _visual_key(Items, equipped, Items.SLOT_LEGS, "legs", "linen")
	var head_k := _visual_key(Items, equipped, Items.SLOT_HEAD, "head", "cloth")
	var weap := _visual_key(Items, equipped, Items.SLOT_WEAPON, "weapon", "wood_blade")
	_style_legs(legs_k)
	_style_chest(chest)
	_style_head(head_k)
	_style_weapon(weap)
	accent.visible = tier >= 2


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
	head.color = Color(0.93, 0.78, 0.62)
	hair.color = Color(0.35, 0.22, 0.12)
	arms.color = Color(0.82, 0.62, 0.48)
	legs.color = Color(0.62, 0.56, 0.42)
	torso.color = Color(0.78, 0.72, 0.58)
	helm.visible = false
	weapon.color = Color(0.6, 0.4, 0.2)
	legs.polygon = PackedVector2Array([
		Vector2(-10, 4), Vector2(-2, 4), Vector2(-4, 20), Vector2(-12, 20),
		Vector2(2, 4), Vector2(10, 4), Vector2(12, 20), Vector2(4, 20),
	])
	torso.polygon = PackedVector2Array([
		Vector2(-14, -10), Vector2(14, -10), Vector2(16, 8), Vector2(0, 14), Vector2(-16, 8),
	])
	arms.polygon = PackedVector2Array([
		Vector2(-18, -6), Vector2(-12, -8), Vector2(-10, 10), Vector2(-16, 12),
		Vector2(12, -8), Vector2(18, -6), Vector2(16, 12), Vector2(10, 10),
	])
	head.polygon = PackedVector2Array([
		Vector2(-8, -28), Vector2(8, -28), Vector2(10, -16), Vector2(0, -12), Vector2(-10, -16),
	])
	hair.polygon = PackedVector2Array([
		Vector2(-9, -32), Vector2(9, -32), Vector2(10, -22), Vector2(-10, -22),
	])
	weapon.polygon = PackedVector2Array([
		Vector2(10, 6), Vector2(14, 6), Vector2(15, -20), Vector2(11, -28), Vector2(9, -20),
	])
	accent.visible = false


func _style_legs(kind: String) -> void:
	match kind:
		"bronze":
			legs.color = Color(0.48, 0.30, 0.12)
		"steel":
			legs.color = Color(0.28, 0.34, 0.42)
		_:
			legs.color = Color(0.62, 0.56, 0.42)


func _style_chest(kind: String) -> void:
	match kind:
		"bronze":
			torso.color = Color(0.72, 0.48, 0.22)
		"steel":
			torso.color = Color(0.55, 0.62, 0.72)
		_:
			torso.color = Color(0.78, 0.72, 0.58)


func _style_head(kind: String) -> void:
	helm.visible = kind != "cloth"
	if kind == "bronze":
		helm.color = Color(0.72, 0.48, 0.22)
		helm.polygon = PackedVector2Array([
			Vector2(-11, -32), Vector2(11, -32), Vector2(13, -18), Vector2(0, -14), Vector2(-13, -18),
		])
	elif kind == "steel":
		helm.color = Color(0.55, 0.62, 0.72)
		helm.polygon = PackedVector2Array([
			Vector2(0, -40), Vector2(12, -30), Vector2(14, -18), Vector2(0, -12), Vector2(-14, -18), Vector2(-12, -30),
		])


func _style_weapon(kind: String) -> void:
	match kind:
		"bronze_blade":
			weapon.color = Color(0.8, 0.55, 0.25)
			weapon.polygon = PackedVector2Array([
				Vector2(10, 6), Vector2(15, 6), Vector2(16, -24), Vector2(12, -34), Vector2(9, -24),
			])
		"steel_blade":
			weapon.color = Color(0.85, 0.85, 0.95)
			weapon.polygon = PackedVector2Array([
				Vector2(10, 6), Vector2(16, 6), Vector2(17, -28), Vector2(12, -40), Vector2(8, -28),
			])
		_:
			weapon.color = Color(0.6, 0.4, 0.2)
			weapon.polygon = PackedVector2Array([
				Vector2(10, 6), Vector2(14, 6), Vector2(15, -20), Vector2(11, -28), Vector2(9, -20),
			])
