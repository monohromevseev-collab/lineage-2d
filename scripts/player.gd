extends CharacterBody2D
## Server-authoritative Human Fighter with layered gear, combat, XP, inventory.

const Items := preload("res://data/items.gd")
const Combat := preload("res://data/combat.gd")
const VISUAL_SCENE := preload("res://scenes/character_visual.tscn")

@onready var name_label: Label = $NameLabel
@onready var camera: Camera2D = $Camera2D
@onready var hp_bar: Node2D = $HpBar
@onready var visual_root: Node2D = $VisualRoot

var peer_id: int = 0
var display_name: String = ""
var bot_mode: bool = false
var race: String = "human"
var class_id: String = "human_fighter"
var level: int = 1
var xp: int = 0
var hp: int = 100
var alive: bool = true
var stats: Dictionary = {}
var equipped: Dictionary = {}
var inventory: Array = []  # item_id strings
var target_mob_id: int = 0
var auto_attack: bool = false

var _zone_half: Vector2 = Vector2(420, 280)
var _input_dir: Vector2 = Vector2.ZERO
var _remote_target: Vector2 = Vector2.ZERO
var _has_remote_target: bool = false
var _bot_phase: float = 0.0
var _attack_cd: float = 0.0
var _base: Dictionary = {}
var _visual: Node2D = null
var _want_pickup: bool = false
var _want_attack_toggle: bool = false
var _want_equip_slot: String = ""


func setup(id: int, pname: String, zone_half: Vector2) -> void:
	peer_id = id
	_zone_half = zone_half
	set_multiplayer_authority(1)
	set_display_name(pname)
	_base = Combat.human_fighter_base()
	race = str(_base.get("race", "human"))
	class_id = str(_base.get("class_id", "human_fighter"))
	equipped = Items.STARTER_LOADOUT.duplicate()
	inventory = []
	level = 1
	xp = 0
	_recalc_stats(true)
	if _visual == null:
		_visual = VISUAL_SCENE.instantiate()
		visual_root.add_child(_visual)
	_refresh_visual()
	_refresh_hp_bar()

	var is_local := multiplayer.has_multiplayer_peer() \
		and not multiplayer.is_server() \
		and multiplayer.get_unique_id() == peer_id
	camera.enabled = is_local
	if is_local:
		camera.make_current()


func set_display_name(pname: String) -> void:
	display_name = pname
	if name_label:
		name_label.text = "%s  Lv%d" % [pname, level]


func is_local_client() -> bool:
	return multiplayer.has_multiplayer_peer() \
		and not multiplayer.is_server() \
		and multiplayer.get_unique_id() == peer_id


func poll_input(delta: float) -> Dictionary:
	var dir := Vector2.ZERO
	var attack := false
	var pickup := false
	var equip_slot := ""
	if bot_mode:
		_bot_phase += delta
		# Seek keltir hunting grounds east of the talking stone, then orbit.
		var hunt := Vector2(160, 40)
		var to_hunt := hunt - position
		if to_hunt.length() > 36.0:
			dir = to_hunt.normalized()
		else:
			dir = Vector2(cos(_bot_phase * 1.2), sin(_bot_phase * 1.4)).normalized()
		attack = true
		pickup = fmod(_bot_phase, 1.8) < 0.35
		if fmod(_bot_phase, 3.5) < 0.2:
			equip_slot = "auto"
	else:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		attack = Input.is_action_just_pressed("attack") or Input.is_action_pressed("attack")
		pickup = Input.is_action_just_pressed("pickup")
		if Input.is_action_just_pressed("equip_1"):
			equip_slot = Items.SLOT_WEAPON
		elif Input.is_action_just_pressed("equip_2"):
			equip_slot = Items.SLOT_CHEST
		elif Input.is_action_just_pressed("equip_3"):
			equip_slot = Items.SLOT_LEGS
		elif Input.is_action_just_pressed("equip_4"):
			equip_slot = Items.SLOT_HEAD
		elif Input.is_action_just_pressed("equip_best"):
			equip_slot = "auto"
	return {"dir": dir, "attack": attack, "pickup": pickup, "equip_slot": equip_slot}


func receive_input_packet(dir: Vector2, attack: bool, pickup: bool, equip_slot: String) -> void:
	_input_dir = dir.limit_length(1.0)
	if attack:
		auto_attack = true
	_want_pickup = pickup
	_want_equip_slot = equip_slot


func server_tick(delta: float, world: Node) -> void:
	if not alive:
		return
	var speed: float = float(stats.get("speed", 180.0))
	if _input_dir != Vector2.ZERO:
		position += _input_dir.normalized() * speed * delta
		if _visual and _visual.has_method("set_facing_x"):
			_visual.set_facing_x(_input_dir.x)
	position = clamp_to_zone(position)

	_attack_cd = maxf(0.0, _attack_cd - delta)

	if _want_equip_slot != "":
		_server_try_equip(_want_equip_slot)
		_want_equip_slot = ""

	if _want_pickup:
		world.server_try_pickup(peer_id)
		_want_pickup = false

	if auto_attack:
		world.server_player_auto_attack(self, delta)


func predict_local(dir: Vector2, delta: float) -> void:
	if not alive:
		return
	var speed: float = float(stats.get("speed", 180.0))
	if dir != Vector2.ZERO:
		position += dir.normalized() * speed * delta
		position = clamp_to_zone(position)
		if _visual and _visual.has_method("set_facing_x"):
			_visual.set_facing_x(dir.x)


func apply_authoritative(pos: Vector2) -> void:
	if is_local_client():
		position = position.lerp(pos, 0.35)
		position = clamp_to_zone(position)
	else:
		_remote_target = pos
		_has_remote_target = true


func apply_full_state(state: Dictionary) -> void:
	level = int(state.get("level", level))
	xp = int(state.get("xp", xp))
	hp = int(state.get("hp", hp))
	alive = bool(state.get("alive", true))
	equipped = state.get("equipped", equipped)
	inventory = state.get("inventory", inventory)
	stats = state.get("stats", stats)
	target_mob_id = int(state.get("target_mob_id", target_mob_id))
	set_display_name(display_name)
	_refresh_visual()
	_refresh_hp_bar()
	visible = alive


func snapshot() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"hp": hp,
		"alive": alive,
		"equipped": equipped.duplicate(),
		"inventory": inventory.duplicate(),
		"stats": stats.duplicate(),
		"target_mob_id": target_mob_id,
		"display_name": display_name,
		"race": race,
	}


func apply_damage(amount: int) -> void:
	if not alive:
		return
	hp = maxi(0, hp - amount)
	_refresh_hp_bar()
	if hp <= 0:
		alive = false
		auto_attack = false
		visible = false


func heal_full() -> void:
	hp = int(stats.get("max_hp", hp))
	alive = true
	visible = true
	_refresh_hp_bar()


func grant_xp(amount: int) -> Dictionary:
	xp += amount
	var leveled := false
	while xp >= Combat.xp_to_next(level):
		xp -= Combat.xp_to_next(level)
		level += 1
		leveled = true
	_recalc_stats(false)
	if leveled:
		hp = int(stats.get("max_hp", hp))
	set_display_name(display_name)
	_refresh_hp_bar()
	return {"leveled": leveled, "level": level, "xp": xp}


func add_loot_item(item_id: String) -> void:
	inventory.append(item_id)


func _server_try_equip(slot_or_auto: String) -> void:
	if slot_or_auto == "auto":
		_equip_best_from_inventory()
		return
	# Equip first inventory item matching slot.
	for i in range(inventory.size()):
		var id: String = str(inventory[i])
		var it: Dictionary = Items.get_item(id)
		if str(it.get("slot", "")) == slot_or_auto:
			_swap_equip(slot_or_auto, id, i)
			return


func _equip_best_from_inventory() -> void:
	for slot in [Items.SLOT_WEAPON, Items.SLOT_CHEST, Items.SLOT_LEGS, Items.SLOT_HEAD]:
		var best_i := -1
		var best_score := -1
		for i in range(inventory.size()):
			var id: String = str(inventory[i])
			var it: Dictionary = Items.get_item(id)
			if str(it.get("slot", "")) != slot:
				continue
			var score: int = int(it.get("p_atk", 0)) + int(it.get("p_def", 0))
			if score > best_score:
				best_score = score
				best_i = i
		if best_i >= 0:
			var id2: String = str(inventory[best_i])
			var cur: String = str(equipped.get(slot, ""))
			var cur_score := 0
			if cur != "":
				var cit: Dictionary = Items.get_item(cur)
				cur_score = int(cit.get("p_atk", 0)) + int(cit.get("p_def", 0))
			if best_score > cur_score:
				_swap_equip(slot, id2, best_i)


func _swap_equip(slot: String, item_id: String, inv_index: int) -> void:
	var old: String = str(equipped.get(slot, ""))
	inventory.remove_at(inv_index)
	if old != "":
		inventory.append(old)
	equipped[slot] = item_id
	_recalc_stats(false)
	_refresh_visual()
	var world := get_parent().get_parent() if get_parent() else null
	if world and world.has_method("_fx_equip") and multiplayer.is_server():
		world._fx_equip.rpc(peer_id, item_id)


func _recalc_stats(reset_hp: bool) -> void:
	var old_max: int = int(stats.get("max_hp", 0))
	stats = Combat.derived_stats(_base, level, equipped)
	var new_max: int = int(stats.get("max_hp", 100))
	if reset_hp or hp <= 0:
		hp = new_max
	elif old_max > 0:
		hp = mini(new_max, hp + maxi(0, new_max - old_max))
	else:
		hp = new_max
	_refresh_hp_bar()


func _refresh_visual() -> void:
	if _visual and _visual.has_method("apply_gear"):
		_visual.apply_gear(equipped)


func _refresh_hp_bar() -> void:
	if hp_bar and hp_bar.has_method("set_ratio"):
		hp_bar.set_ratio(float(hp), float(stats.get("max_hp", 100)))
		hp_bar.bar_color = Color(0.35, 0.85, 0.45)
		hp_bar.visible = alive


func play_attack_fx() -> void:
	if _visual and _visual.has_method("play_attack_flash"):
		_visual.play_attack_flash()


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		return
	if not is_local_client() and _has_remote_target and alive:
		position = position.lerp(_remote_target, clampf(12.0 * delta, 0.0, 1.0))


func clamp_to_zone(pos: Vector2) -> Vector2:
	var q := Vector2(absf(pos.x) / _zone_half.x, absf(pos.y) / _zone_half.y)
	var m := q.x + q.y
	if m <= 1.0:
		return pos
	return pos / m
