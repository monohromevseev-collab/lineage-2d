extends CharacterBody2D
## Server-simulated mob with distinct silhouette + HP bar.

const MobData := preload("res://data/mobs.gd")
const Combat := preload("res://data/combat.gd")

@onready var visual: Node2D = $Visual
@onready var name_label: Label = $NameLabel
@onready var hp_bar: Node2D = $HpBar

var _selected: bool = false
var _select_poly: Polygon2D

var mob_id: int = 0
var template_id: String = "keltir"
var display_name: String = "Mob"
var max_hp: int = 50
var hp: int = 50
var p_atk: int = 5
var p_def: int = 4
var xp_reward: int = 20
var move_speed: float = 70.0
var aggro_range: float = 0.0
var attack_range: float = 42.0
var attack_interval: float = 1.4
var alive: bool = true
var spawn_pos: Vector2 = Vector2.ZERO

var _home: Vector2 = Vector2.ZERO
var _target_peer: int = 0
var _attack_cd: float = 0.0
var _remote_pos: Vector2 = Vector2.ZERO
var _has_remote: bool = false
var _hurt_flash: float = 0.0
var _anim_t: float = 0.0
var _moving: bool = false


func setup(id: int, template: String, pos: Vector2) -> void:
	mob_id = id
	template_id = template
	position = pos
	spawn_pos = pos
	_home = pos
	set_multiplayer_authority(1)
	var t: Dictionary = MobData.get_template(template)
	display_name = str(t.get("name", template))
	max_hp = int(t.get("max_hp", 50))
	hp = max_hp
	p_atk = int(t.get("p_atk", 5))
	p_def = int(t.get("p_def", 4))
	xp_reward = int(t.get("xp", 20))
	move_speed = float(t.get("speed", 70.0))
	aggro_range = float(t.get("aggro_range", 0.0))
	attack_range = float(t.get("attack_range", 42.0))
	attack_interval = float(t.get("attack_interval", 1.4))
	name_label.text = display_name
	_build_silhouette(str(t.get("silhouette", "fox")), t.get("color", Color.WHITE))
	_ensure_select_ring()
	_refresh_hp()


func set_selected(on: bool) -> void:
	_selected = on
	if _select_poly:
		_select_poly.visible = on and alive


func _ensure_select_ring() -> void:
	if _select_poly:
		return
	_select_poly = Polygon2D.new()
	_select_poly.z_index = -1
	_select_poly.color = Color(0.95, 0.55, 0.15, 0.45)
	_select_poly.polygon = PackedVector2Array([
		Vector2(0, 12), Vector2(26, 24), Vector2(0, 34), Vector2(-26, 24),
	])
	_select_poly.visible = false
	add_child(_select_poly)


func _build_silhouette(kind: String, color: Color) -> void:
	for c in visual.get_children():
		c.queue_free()
	var body := Polygon2D.new()
	body.color = color
	var accent := Polygon2D.new()
	accent.color = color.darkened(0.25)
	match kind:
		"wolf":
			body.polygon = PackedVector2Array([
				Vector2(-22, 4), Vector2(-8, -10), Vector2(10, -8), Vector2(24, 2),
				Vector2(18, 14), Vector2(-14, 14),
			])
			accent.polygon = PackedVector2Array([
				Vector2(-8, -10), Vector2(-4, -22), Vector2(2, -12), Vector2(8, -20), Vector2(10, -8),
			])
		"orc":
			body.polygon = PackedVector2Array([
				Vector2(-16, -8), Vector2(16, -8), Vector2(18, 16), Vector2(0, 22), Vector2(-18, 16),
			])
			accent.polygon = PackedVector2Array([
				Vector2(-10, -20), Vector2(10, -20), Vector2(12, -8), Vector2(-12, -8),
			])
			accent.color = Color(0.55, 0.35, 0.2)
		_:
			# Keltir / fox-like
			body.polygon = PackedVector2Array([
				Vector2(-16, 6), Vector2(-6, -6), Vector2(12, -4), Vector2(18, 8),
				Vector2(8, 14), Vector2(-12, 14),
			])
			accent.polygon = PackedVector2Array([
				Vector2(-6, -6), Vector2(-2, -18), Vector2(4, -8), Vector2(8, -16), Vector2(12, -4),
			])
			accent.color = Color(0.9, 0.85, 0.75)
	visual.add_child(body)
	visual.add_child(accent)


func _process(delta: float) -> void:
	_anim_t += delta * (8.0 if _moving else 2.0)
	var bob := sin(_anim_t) * (2.5 if _moving else 0.8)
	visual.position.y = bob
	visual.rotation = sin(_anim_t) * (0.12 if _moving else 0.03)
	if _hurt_flash > 0.0:
		_hurt_flash = maxf(0.0, _hurt_flash - delta * 4.0)
		visual.modulate = Color(1, 1, 1).lerp(Color(1.4, 0.5, 0.5), _hurt_flash)
	elif alive:
		visual.modulate = Color(1, 1, 1)
	if not multiplayer.is_server() and _has_remote and alive:
		var prev := position
		position = position.lerp(_remote_pos, clampf(10.0 * delta, 0.0, 1.0))
		_moving = prev.distance_to(position) > 0.35


func server_ai(delta: float, players_node: Node2D, on_hit_player: Callable) -> void:
	if not alive:
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)
	var nearest: Node2D = null
	var nearest_d := INF
	for p in players_node.get_children():
		if not p.get("alive"):
			continue
		var d: float = position.distance_to(p.position)
		if d < nearest_d:
			nearest_d = d
			nearest = p
	if nearest == null:
		_return_home(delta)
		return

	# Passive aggro or chase current attacker target loosely.
	var in_aggro := aggro_range > 0.0 and nearest_d <= aggro_range
	var chasing := _target_peer != 0
	if in_aggro:
		_target_peer = int(str(nearest.name))
		chasing = true
	if not chasing:
		_return_home(delta)
		return

	var target_node := players_node.get_node_or_null(str(_target_peer))
	if target_node == null or not target_node.get("alive"):
		_target_peer = 0
		_return_home(delta)
		return

	var dist: float = position.distance_to(target_node.position)
	if dist > attack_range * 0.9:
		var dir: Vector2 = (target_node.position - position).normalized()
		position += dir * move_speed * delta
		_moving = true
	elif _attack_cd <= 0.0:
		_moving = false
		_attack_cd = attack_interval
		var dmg := Combat.phys_damage(float(p_atk), float(target_node.stats.get("p_def", 5)), 1)
		on_hit_player.call(_target_peer, dmg, mob_id)
	else:
		_moving = false


func _return_home(delta: float) -> void:
	if position.distance_to(_home) > 4.0:
		position = position.move_toward(_home, move_speed * 0.7 * delta)
		_moving = true
	else:
		_moving = false


func apply_damage(amount: int, attacker_peer: int) -> void:
	if not alive:
		return
	hp = maxi(0, hp - amount)
	_target_peer = attacker_peer
	_hurt_flash = 1.0
	_refresh_hp()
	if hp <= 0:
		alive = false
		visible = false


func revive_at_spawn() -> void:
	alive = true
	visible = true
	hp = max_hp
	position = spawn_pos
	_home = spawn_pos
	_target_peer = 0
	_refresh_hp()


func apply_state(pos: Vector2, current_hp: int, is_alive: bool) -> void:
	_remote_pos = pos
	_has_remote = true
	hp = current_hp
	alive = is_alive
	visible = is_alive
	_refresh_hp()


func _refresh_hp() -> void:
	if hp_bar and hp_bar.has_method("set_ratio"):
		hp_bar.set_ratio(float(hp), float(max_hp))
		hp_bar.visible = alive
