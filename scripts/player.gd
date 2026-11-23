extends CharacterBody2D
## Server-authoritative Human Fighter — target combat, MP/CP, walk anim.

const Items := preload("res://data/items.gd")
const Combat := preload("res://data/combat.gd")
const QuestEngine := preload("res://data/quest_engine.gd")
const VISUAL_SCENE := preload("res://scenes/character_visual.tscn")

@onready var name_label: Label = $NameLabel
@onready var camera: Camera2D = $Camera2D
@onready var hp_bar: Node2D = $HpBar
@onready var visual_root: Node2D = $VisualRoot
@onready var select_ring: Polygon2D = $SelectRing

var peer_id: int = 0
var display_name: String = ""
var bot_mode: bool = false
var race: String = "human"
var class_id: String = "human_fighter"
var level: int = 1
var xp: int = 0
var hp: int = 100
var mp: int = 40
var cp: int = 40
var alive: bool = true
var stats: Dictionary = {}
var equipped: Dictionary = {}
var inventory: Array = []
var quests: Dictionary = {}
var target_mob_id: int = 0
var target_npc_id: String = ""  ## friendly NPC template id when selected
var engaged: bool = false  ## attacking selected target (L2-style after Attack skill)
var facing: Vector2 = Vector2.RIGHT

var _world_half: Vector2 = Vector2(1400, 1000)
var _input_dir: Vector2 = Vector2.ZERO
var _remote_target: Vector2 = Vector2.ZERO
var _has_remote_target: bool = false
var _bot_phase: float = 0.0
var _attack_cd: float = 0.0
var _base: Dictionary = {}
var _visual: Node2D = null
var _want_pickup: bool = false
var _want_attack_press: bool = false
var _want_clear_target: bool = false
var _want_equip_item: String = ""
var _want_equip_slot: String = ""
var _moving: bool = false
var _bot_did_attack: bool = false


func setup(id: int, pname: String, world_half: Vector2) -> void:
	peer_id = id
	_world_half = world_half
	set_multiplayer_authority(1)
	set_display_name(pname)
	_base = Combat.human_fighter_base()
	race = str(_base.get("race", "human"))
	class_id = str(_base.get("class_id", "human_fighter"))
	equipped = Items.STARTER_LOADOUT.duplicate()
	inventory = []
	quests = QuestEngine.default_state()
	level = 1
	xp = 0
	engaged = false
	target_mob_id = 0
	target_npc_id = ""
	_recalc_stats(true)
	if _visual == null:
		_visual = VISUAL_SCENE.instantiate()
		visual_root.add_child(_visual)
	_refresh_visual()
	_refresh_hp_bar()
	if select_ring:
		select_ring.visible = false

	var is_local := multiplayer.has_multiplayer_peer() \
		and not multiplayer.is_server() \
		and multiplayer.get_unique_id() == peer_id
	camera.enabled = is_local
	if is_local:
		camera.make_current()
		camera.zoom = Vector2(1.05, 1.05)


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
	var attack_press := false
	var pickup := false
	var clear_t := false
	var equip_item := ""
	var equip_slot := ""
	if bot_mode:
		_bot_phase += delta
		# Hunt Tutorial Gremlins near Newbie Helper, then Elpy pocket.
		var hunt := Vector2(55, 95) if _bot_phase < 25.0 else Vector2(-20, 120)
		var to_hunt := hunt - position
		if to_hunt.length() > 48.0:
			dir = to_hunt.normalized()
			_bot_did_attack = false
		else:
			dir = (hunt - position).normalized() * 0.2
			if not _bot_did_attack:
				attack_press = true
				_bot_did_attack = true
			elif fmod(_bot_phase, 6.0) < delta:
				attack_press = true
		pickup = fmod(_bot_phase, 2.0) < delta
		if fmod(_bot_phase, 5.0) < delta:
			equip_slot = "auto"
	else:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		attack_press = Input.is_action_just_pressed("attack")
		pickup = Input.is_action_just_pressed("pickup")
		clear_t = Input.is_action_just_pressed("ui_cancel")
		if Input.is_action_just_pressed("equip_best"):
			equip_slot = "auto"
	return {
		"dir": dir,
		"attack_press": attack_press,
		"pickup": pickup,
		"clear_target": clear_t,
		"equip_item": equip_item,
		"equip_slot": equip_slot,
	}


func receive_input_packet(pkt: Dictionary) -> void:
	_input_dir = Vector2(pkt.get("dir", Vector2.ZERO)).limit_length(1.0)
	_want_attack_press = bool(pkt.get("attack_press", false))
	_want_pickup = bool(pkt.get("pickup", false))
	_want_clear_target = bool(pkt.get("clear_target", false))
	_want_equip_item = str(pkt.get("equip_item", ""))
	_want_equip_slot = str(pkt.get("equip_slot", ""))


func server_tick(delta: float, world: Node) -> void:
	if not alive:
		return
	var speed: float = float(stats.get("speed", 180.0))
	_moving = _input_dir != Vector2.ZERO
	if _moving:
		position += _input_dir.normalized() * speed * delta
		facing = _input_dir.normalized()
		if _visual and _visual.has_method("set_facing_x"):
			_visual.set_facing_x(_input_dir.x)
	position = soft_bound(position)
	if _visual and _visual.has_method("set_moving"):
		_visual.set_moving(_moving)

	_attack_cd = maxf(0.0, _attack_cd - delta)

	if _want_clear_target:
		target_mob_id = 0
		engaged = false
		_want_clear_target = false

	if _want_equip_item != "":
		_server_equip_item_id(_want_equip_item)
		_want_equip_item = ""
	if _want_equip_slot != "":
		_server_try_equip(_want_equip_slot)
		_want_equip_slot = ""

	if _want_pickup:
		world.server_try_pickup(peer_id)
		_want_pickup = false

	if _want_attack_press:
		_want_attack_press = false
		if target_mob_id == 0:
			var n = world._nearest_alive_mob(position)
			if n:
				target_mob_id = n.mob_id
		if target_mob_id != 0:
			# Pressing Attack while already engaged keeps engaged (does not cancel).
			# Esc / clear target cancels. Second press while engaged re-asserts.
			if not engaged:
				engaged = true
			else:
				engaged = true
		else:
			engaged = false

	if engaged:
		# Face target while engaged so range checks pass as we close in.
		var t = world._find_mob(target_mob_id)
		if t and t.alive:
			facing = (t.position - position).normalized()
		world.server_player_swing(self, delta)


func predict_local(dir: Vector2, delta: float) -> void:
	if not alive:
		return
	var speed: float = float(stats.get("speed", 180.0))
	_moving = dir != Vector2.ZERO
	if _moving:
		position += dir.normalized() * speed * delta
		position = soft_bound(position)
		facing = dir.normalized()
		if _visual and _visual.has_method("set_facing_x"):
			_visual.set_facing_x(dir.x)
	if _visual and _visual.has_method("set_moving"):
		_visual.set_moving(_moving)


func apply_authoritative(pos: Vector2) -> void:
	if is_local_client():
		position = position.lerp(pos, 0.35)
		position = soft_bound(position)
	else:
		_remote_target = pos
		_has_remote_target = true


func apply_full_state(state: Dictionary) -> void:
	level = int(state.get("level", level))
	xp = int(state.get("xp", xp))
	hp = int(state.get("hp", hp))
	mp = int(state.get("mp", mp))
	cp = int(state.get("cp", cp))
	alive = bool(state.get("alive", true))
	equipped = state.get("equipped", equipped)
	inventory = state.get("inventory", inventory)
	stats = state.get("stats", stats)
	target_mob_id = int(state.get("target_mob_id", target_mob_id))
	target_npc_id = str(state.get("target_npc_id", target_npc_id))
	engaged = bool(state.get("engaged", engaged))
	quests = state.get("quests", quests)
	var f = state.get("facing", facing)
	if typeof(f) == TYPE_VECTOR2:
		facing = f
	_moving = bool(state.get("moving", _moving))
	set_display_name(display_name)
	_refresh_visual()
	_refresh_hp_bar()
	visible = alive
	if _visual and _visual.has_method("set_moving"):
		_visual.set_moving(_moving)


func snapshot() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"hp": hp,
		"mp": mp,
		"cp": cp,
		"alive": alive,
		"equipped": equipped.duplicate(),
		"inventory": inventory.duplicate(),
		"quests": quests.duplicate(true),
		"stats": stats.duplicate(),
		"target_mob_id": target_mob_id,
		"target_npc_id": target_npc_id,
		"engaged": engaged,
		"facing": facing,
		"moving": _moving,
		"display_name": display_name,
		"race": race,
	}


func apply_damage(amount: int) -> void:
	if not alive:
		return
	# CP absorbs first
	var rest := amount
	if cp > 0:
		var absorb: int = mini(cp, rest)
		cp -= absorb
		rest -= absorb
	if rest > 0:
		hp = maxi(0, hp - rest)
	_refresh_hp_bar()
	if hp <= 0:
		alive = false
		engaged = false
		visible = false


func heal_full() -> void:
	hp = int(stats.get("max_hp", hp))
	mp = int(stats.get("max_mp", mp))
	cp = int(stats.get("max_cp", cp))
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
		mp = int(stats.get("max_mp", mp))
		cp = int(stats.get("max_cp", cp))
	set_display_name(display_name)
	_refresh_hp_bar()
	return {"leveled": leveled, "level": level, "xp": xp}


func add_loot_item(item_id: String) -> void:
	inventory.append(item_id)


func _server_equip_item_id(item_id: String) -> void:
	var idx := inventory.find(item_id)
	if idx < 0:
		return
	var it: Dictionary = Items.get_item(item_id)
	var slot: String = str(it.get("slot", ""))
	if slot == "" or slot == "etc":
		return
	_swap_equip(slot, item_id, idx)


func _server_try_equip(slot_or_auto: String) -> void:
	if slot_or_auto == "auto":
		_equip_best_from_inventory()
		return
	for i in range(inventory.size()):
		var id: String = str(inventory[i])
		var it: Dictionary = Items.get_item(id)
		if str(it.get("slot", "")) == slot_or_auto:
			_swap_equip(slot_or_auto, id, i)
			return


func _equip_best_from_inventory() -> void:
	for slot in [Items.SLOT_WEAPON, Items.SLOT_CHEST, Items.SLOT_LEGS, Items.SLOT_HEAD, Items.SLOT_GLOVES, Items.SLOT_FEET, Items.SLOT_NECK]:
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
	var new_mp: int = int(stats.get("max_mp", 40))
	var new_cp: int = int(stats.get("max_cp", 40))
	if reset_hp or hp <= 0:
		hp = new_max
		mp = new_mp
		cp = new_cp
	elif old_max > 0:
		hp = mini(new_max, hp + maxi(0, new_max - old_max))
		mp = mini(new_mp, mp)
		cp = mini(new_cp, cp)
	else:
		hp = new_max
		mp = new_mp
		cp = new_cp
	_refresh_hp_bar()


func _refresh_visual() -> void:
	if _visual and _visual.has_method("apply_gear"):
		_visual.apply_gear(equipped)


func _refresh_hp_bar() -> void:
	if hp_bar and hp_bar.has_method("set_ratio"):
		hp_bar.set_ratio(float(hp), float(stats.get("max_hp", 100)))
		hp_bar.bar_color = Color(0.75, 0.2, 0.18)
		hp_bar.visible = alive


func play_attack_fx() -> void:
	if _visual and _visual.has_method("play_attack_flash"):
		_visual.play_attack_flash()


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		return
	if not is_local_client() and _has_remote_target and alive:
		var prev := position
		position = position.lerp(_remote_target, clampf(12.0 * delta, 0.0, 1.0))
		if _visual and _visual.has_method("set_moving"):
			_visual.set_moving(prev.distance_to(position) > 0.4)


func soft_bound(pos: Vector2) -> Vector2:
	## Soft edge far from play — gentle push, not a wall in the meadow.
	var m := _world_half * 0.98
	return Vector2(clampf(pos.x, -m.x, m.x), clampf(pos.y, -m.y, m.y))
