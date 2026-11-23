extends Node2D
## Slice 1 world: Human spawn at talking stone, mobs, AA combat, XP, loot, equip.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const MOB_SCENE := preload("res://scenes/mob.tscn")
const LOOT_SCENE := preload("res://scenes/loot_drop.tscn")
const NetConfig := preload("res://scripts/net_config.gd")
const MobData := preload("res://data/mobs.gd")
const Items := preload("res://data/items.gd")
const Combat := preload("res://data/combat.gd")
const SYNC_HZ := 20.0
const ATTACK_RANGE := 52.0
const PICKUP_RANGE := 48.0
const MOB_RESPAWN := 12.0

@export var net_cfg: Dictionary = {}

@onready var players: Node2D = $Players
@onready var mobs: Node2D = $Mobs
@onready var loot: Node2D = $Loot
@onready var hud: CanvasLayer = $HUD
@onready var status_label: Label = $HUD/Status
@onready var help_label: Label = $HUD/Help
@onready var title_label: Label = $HUD/Title
@onready var stats_label: Label = $HUD/StatsPanel
@onready var inv_label: Label = $HUD/InvPanel
@onready var target_label: Label = $HUD/TargetPanel
@onready var log_label: Label = $HUD/CombatLog

var _peer: ENetMultiplayerPeer
var _spawn_index: int = 0
var _pending_names: Dictionary = {}
var _sync_accum: float = 0.0
var _next_mob_id: int = 1
var _next_drop_id: int = 1
var _respawn_timers: Dictionary = {}  # mob_id -> time left
var _combat_log: PackedStringArray = PackedStringArray()

const ZONE_HALF := Vector2(460, 300)
## Human newbie meadow — near talking stone.
const HUMAN_SPAWN := Vector2(-40, 70)
const SPAWN_JITTER := [
	Vector2(0, 0),
	Vector2(36, 12),
	Vector2(-30, 18),
	Vector2(20, -16),
	Vector2(-45, -8),
]


func _ready() -> void:
	if net_cfg.is_empty():
		net_cfg = NetConfig.from_cmdline()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	title_label.text = "Lineage 2d · Slice 1"
	help_label.text = "WASD move · F / LMB attack (auto) · E pickup · R equip best · Tab cycle target"
	_start_network()
	if multiplayer.is_server() or net_cfg.mode == "server":
		# Mobs created after peer assigned in _start_network.
		pass


func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	if multiplayer.is_server():
		_server_simulate(delta)
		_sync_accum += delta
		if _sync_accum >= 1.0 / SYNC_HZ:
			_sync_accum = 0.0
			_broadcast_snapshots()
		return

	var my_id := multiplayer.get_unique_id()
	var me := players.get_node_or_null(str(my_id))
	if me == null:
		return
	_client_handle_targeting(me)
	var pkt: Dictionary = me.poll_input(delta)
	_submit_input.rpc_id(
		1,
		pkt.dir,
		bool(pkt.attack),
		bool(pkt.pickup),
		str(pkt.equip_slot)
	)
	me.predict_local(pkt.dir, delta)
	_refresh_local_hud(me)


func _server_simulate(delta: float) -> void:
	for child in players.get_children():
		child.server_tick(delta, self)
	for m in mobs.get_children():
		m.server_ai(delta, players, Callable(self, "_on_mob_hit_player"))
	# Respawn timers
	var done: Array = []
	for mid in _respawn_timers.keys():
		_respawn_timers[mid] = float(_respawn_timers[mid]) - delta
		if float(_respawn_timers[mid]) <= 0.0:
			done.append(mid)
	for mid2 in done:
		_respawn_timers.erase(mid2)
		_respawn_mob(int(mid2))


func _start_network() -> void:
	_peer = ENetMultiplayerPeer.new()
	if net_cfg.mode == "server":
		var err := _peer.create_server(int(net_cfg.port), NetConfig.MAX_CLIENTS)
		if err != OK:
			_set_status("Server failed to bind port %s (err %s)" % [net_cfg.port, err])
			return
		multiplayer.multiplayer_peer = _peer
		_set_status("Dedicated server listening on :%s" % net_cfg.port)
		_spawn_all_mobs()
		print("[net] server ready, waiting for clients")
	else:
		var err := _peer.create_client(str(net_cfg.host), int(net_cfg.port))
		if err != OK:
			_set_status("Client create failed (err %s)" % err)
			return
		multiplayer.multiplayer_peer = _peer
		_set_status("Connecting to %s:%s …" % [net_cfg.host, net_cfg.port])


func _spawn_all_mobs() -> void:
	for entry in MobData.SPAWNS:
		_create_mob_local(str(entry.template), entry.pos)


func _create_mob_local(template_id: String, pos: Vector2) -> Node:
	var id := _next_mob_id
	_next_mob_id += 1
	var m: Node = MOB_SCENE.instantiate()
	m.name = "mob_%s" % id
	mobs.add_child(m, true)
	m.setup(id, template_id, pos)
	return m


func _on_peer_connected(id: int) -> void:
	print("[net] peer connected: %s" % id)
	if not multiplayer.is_server():
		return
	# Sync existing world to late joiner.
	for child in players.get_children():
		var pid := int(str(child.name))
		_spawn_player.rpc_id(id, pid, child.position, child.display_name, child.snapshot())
	for m in mobs.get_children():
		_spawn_mob.rpc_id(id, m.mob_id, m.template_id, m.position, m.hp, m.alive)
	for d in loot.get_children():
		_spawn_loot.rpc_id(id, d.drop_id, d.item_id, d.position)
	var pos := _next_spawn()
	var pname: String = str(_pending_names.get(id, "Player-%s" % id))
	_spawn_player.rpc(id, pos, pname, {})


func _on_peer_disconnected(id: int) -> void:
	print("[net] peer disconnected: %s" % id)
	_pending_names.erase(id)
	if multiplayer.is_server():
		_despawn_player.rpc(id)
	else:
		_remove_player_local(id)


func _on_connected_to_server() -> void:
	_set_status("Connected — Human Fighter @ Talking Stone")
	var preferred: String = str(net_cfg.get("display_name", ""))
	if preferred == "":
		preferred = "Player-%s" % multiplayer.get_unique_id()
	_register_name.rpc_id(1, preferred)


func _on_connection_failed() -> void:
	_set_status("Connection failed — is the server running?")


func _on_server_disconnected() -> void:
	_set_status("Server disconnected")
	for n in [players, mobs, loot]:
		for child in n.get_children():
			child.queue_free()


@rpc("any_peer", "reliable")
func _register_name(display_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	_pending_names[sender] = display_name
	var node := players.get_node_or_null(str(sender))
	if node:
		node.set_display_name(display_name)
		_set_player_name.rpc(sender, display_name)


@rpc("authority", "call_local", "reliable")
func _set_player_name(peer_id: int, display_name: String) -> void:
	var node := players.get_node_or_null(str(peer_id))
	if node:
		node.set_display_name(display_name)


@rpc("authority", "call_local", "reliable")
func _spawn_player(peer_id: int, pos: Vector2, display_name: String, state: Dictionary) -> void:
	if players.get_node_or_null(str(peer_id)):
		return
	var p: Node2D = PLAYER_SCENE.instantiate()
	p.name = str(peer_id)
	p.position = pos
	players.add_child(p, true)
	p.setup(peer_id, display_name, ZONE_HALF)
	if not state.is_empty():
		p.apply_full_state(state)
	if typeof(net_cfg) == TYPE_DICTIONARY and bool(net_cfg.get("bot", false)) \
			and multiplayer.has_multiplayer_peer() \
			and multiplayer.get_unique_id() == peer_id:
		p.bot_mode = true
	print("[world] spawned Human %s (%s) at %s" % [peer_id, display_name, pos])


@rpc("authority", "call_local", "reliable")
func _despawn_player(peer_id: int) -> void:
	_remove_player_local(peer_id)


func _remove_player_local(peer_id: int) -> void:
	var node := players.get_node_or_null(str(peer_id))
	if node:
		node.queue_free()


@rpc("authority", "call_local", "reliable")
func _spawn_mob(mob_id: int, template_id: String, pos: Vector2, hp: int, is_alive: bool) -> void:
	var key := "mob_%s" % mob_id
	if mobs.get_node_or_null(key):
		return
	var m: Node = MOB_SCENE.instantiate()
	m.name = key
	mobs.add_child(m, true)
	m.setup(mob_id, template_id, pos)
	m.hp = hp
	m.alive = is_alive
	m.visible = is_alive
	m._refresh_hp()


@rpc("authority", "call_local", "reliable")
func _spawn_loot(drop_id: int, item_id: String, pos: Vector2) -> void:
	var key := "drop_%s" % drop_id
	if loot.get_node_or_null(key):
		return
	var d: Node = LOOT_SCENE.instantiate()
	d.name = key
	loot.add_child(d, true)
	d.setup(drop_id, item_id, pos)


@rpc("authority", "call_local", "reliable")
func _remove_loot(drop_id: int) -> void:
	var node := loot.get_node_or_null("drop_%s" % drop_id)
	if node:
		node.queue_free()


@rpc("any_peer", "unreliable")
func _submit_input(dir: Vector2, attack: bool, pickup: bool, equip_slot: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var node := players.get_node_or_null(str(sender))
	if node:
		node.receive_input_packet(dir, attack, pickup, equip_slot)


@rpc("authority", "unreliable", "call_remote")
func _sync_snapshot(player_states: Dictionary, mob_states: Dictionary) -> void:
	if multiplayer.is_server():
		return
	for pid in player_states.keys():
		var node := players.get_node_or_null(str(pid))
		if node == null:
			continue
		var st: Dictionary = player_states[pid]
		node.apply_authoritative(st.get("pos", node.position))
		node.apply_full_state(st)
	for mid in mob_states.keys():
		var m := mobs.get_node_or_null("mob_%s" % mid)
		if m == null:
			continue
		var ms: Dictionary = mob_states[mid]
		m.apply_state(ms.get("pos", m.position), int(ms.get("hp", m.hp)), bool(ms.get("alive", true)))
	var me := players.get_node_or_null(str(multiplayer.get_unique_id()))
	if me:
		_refresh_local_hud(me)


@rpc("authority", "call_local", "reliable")
func _fx_miss(peer_id: int, mob_id: int) -> void:
	var p := players.get_node_or_null(str(peer_id))
	if p and p.has_method("play_attack_fx"):
		p.play_attack_fx()
	_push_log("%s missed mob #%s" % [_name_of(peer_id), mob_id])


@rpc("authority", "call_local", "reliable")
func _fx_attack(peer_id: int, mob_id: int, damage: int, remaining_hp: int) -> void:
	var p := players.get_node_or_null(str(peer_id))
	if p and p.has_method("play_attack_fx"):
		p.play_attack_fx()
	var m := mobs.get_node_or_null("mob_%s" % mob_id)
	if m:
		m.hp = remaining_hp
		m._hurt_flash = 1.0
		m._refresh_hp()
	_push_log("%s hits %s for %d" % [_name_of(peer_id), _mob_name(mob_id), damage])


@rpc("authority", "call_local", "reliable")
func _fx_player_hit(peer_id: int, damage: int, remaining_hp: int) -> void:
	var p := players.get_node_or_null(str(peer_id))
	if p:
		p.hp = remaining_hp
		p._refresh_hp_bar()
	_push_log("Mob hits %s for %d" % [_name_of(peer_id), damage])


@rpc("authority", "call_local", "reliable")
func _fx_level_up(peer_id: int, new_level: int) -> void:
	_push_log("%s reached level %d!" % [_name_of(peer_id), new_level])


@rpc("authority", "call_local", "reliable")
func _fx_loot(peer_id: int, item_id: String) -> void:
	_push_log("%s looted %s" % [_name_of(peer_id), Items.display_name(item_id)])


@rpc("authority", "call_local", "reliable")
func _fx_equip(peer_id: int, item_id: String) -> void:
	_push_log("%s equipped %s" % [_name_of(peer_id), Items.display_name(item_id)])


func _broadcast_snapshots() -> void:
	var pst := {}
	for child in players.get_children():
		var st: Dictionary = child.snapshot()
		st["pos"] = child.position
		pst[int(str(child.name))] = st
	var mst := {}
	for m in mobs.get_children():
		mst[m.mob_id] = {"pos": m.position, "hp": m.hp, "alive": m.alive}
	_sync_snapshot.rpc(pst, mst)


func server_player_auto_attack(player: Node, _delta: float) -> void:
	if not player.alive:
		return
	# Acquire / keep target
	var target := _find_mob(player.target_mob_id)
	if target == null or not target.alive:
		target = _nearest_alive_mob(player.position)
		player.target_mob_id = target.mob_id if target else 0
	if target == null:
		return
	var dist: float = player.position.distance_to(target.position)
	if dist > ATTACK_RANGE:
		return
	if player._attack_cd > 0.0:
		return
	player._attack_cd = float(player.stats.get("atk_interval", 1.0))
	var chance := Combat.hit_chance(
		float(player.stats.get("accuracy", 30)),
		10.0,
		player.level,
		1
	)
	if randf() > chance:
		_fx_miss.rpc(player.peer_id, target.mob_id)
		return
	var dmg := Combat.phys_damage(
		float(player.stats.get("p_atk", 10)),
		float(target.p_def),
		player.level
	)
	# Crit sprinkle
	if randf() < 0.08 + float(player.stats.get("dex", 30)) * 0.001:
		dmg *= 2
	target.apply_damage(dmg, player.peer_id)
	_fx_attack.rpc(player.peer_id, target.mob_id, dmg, target.hp)
	if not target.alive:
		_on_mob_killed(player, target)


func _on_mob_killed(player: Node, mob: Node) -> void:
	var xp_info: Dictionary = player.grant_xp(mob.xp_reward)
	if bool(xp_info.get("leveled", false)):
		_fx_level_up.rpc(player.peer_id, int(xp_info.level))
	_roll_loot(mob)
	_respawn_timers[mob.mob_id] = MOB_RESPAWN
	_push_log("%s slew %s (+%d XP)" % [player.display_name, mob.display_name, mob.xp_reward])


func _roll_loot(mob: Node) -> void:
	var t: Dictionary = MobData.get_template(mob.template_id)
	var table: Array = t.get("loot", [])
	for entry in table:
		if randf() > float(entry.get("chance", 0.0)):
			continue
		var item_id: String = str(entry.get("item_id", ""))
		if item_id == "":
			continue
		var drop_id := _next_drop_id
		_next_drop_id += 1
		var jitter := Vector2(randf_range(-18, 18), randf_range(-12, 12))
		var pos: Vector2 = mob.position + jitter
		_spawn_loot.rpc(drop_id, item_id, pos)


func server_try_pickup(peer_id: int) -> void:
	var player := players.get_node_or_null(str(peer_id))
	if player == null or not player.alive:
		return
	var best: Node = null
	var best_d := PICKUP_RANGE
	for d in loot.get_children():
		var dist: float = player.position.distance_to(d.position)
		if dist <= best_d:
			best_d = dist
			best = d
	if best == null:
		return
	player.add_loot_item(best.item_id)
	_fx_loot.rpc(peer_id, best.item_id)
	_remove_loot.rpc(best.drop_id)


func _on_mob_hit_player(peer_id: int, damage: int, _mob_id: int) -> void:
	var player := players.get_node_or_null(str(peer_id))
	if player == null or not player.alive:
		return
	player.apply_damage(damage)
	_fx_player_hit.rpc(peer_id, damage, player.hp)
	if not player.alive:
		var pref := peer_id
		get_tree().create_timer(3.0).timeout.connect(func () -> void:
			var p := players.get_node_or_null(str(pref))
			if p:
				p.position = _next_spawn()
				p.heal_full()
		, CONNECT_ONE_SHOT)


func _respawn_mob(mob_id: int) -> void:
	var m := _find_mob(mob_id)
	if m:
		m.revive_at_spawn()


func _find_mob(mob_id: int) -> Node:
	if mob_id <= 0:
		return null
	return mobs.get_node_or_null("mob_%s" % mob_id)


func _nearest_alive_mob(from: Vector2) -> Node:
	var best: Node = null
	var best_d := INF
	for m in mobs.get_children():
		if not m.alive:
			continue
		var d: float = from.distance_to(m.position)
		if d < best_d:
			best_d = d
			best = m
	return best


func _client_handle_targeting(me: Node) -> void:
	if Input.is_action_just_pressed("cycle_target"):
		_cycle_target(me)
	if Input.is_action_just_pressed("attack_click"):
		# Nearest in a cone / simply nearest.
		var n := _nearest_alive_mob(me.position)
		if n:
			me.target_mob_id = n.mob_id
			me.auto_attack = true
			_request_target.rpc_id(1, n.mob_id)


@rpc("any_peer", "reliable")
func _request_target(mob_id: int) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var p := players.get_node_or_null(str(sender))
	if p:
		p.target_mob_id = mob_id
		p.auto_attack = true


func _cycle_target(me: Node) -> void:
	var alive_mobs: Array = []
	for m in mobs.get_children():
		if m.alive:
			alive_mobs.append(m)
	if alive_mobs.is_empty():
		me.target_mob_id = 0
		return
	alive_mobs.sort_custom(func(a, b): return a.mob_id < b.mob_id)
	var idx := 0
	for i in range(alive_mobs.size()):
		if alive_mobs[i].mob_id == me.target_mob_id:
			idx = (i + 1) % alive_mobs.size()
			break
	me.target_mob_id = alive_mobs[idx].mob_id
	me.auto_attack = true
	_request_target.rpc_id(1, me.target_mob_id)


func _next_spawn() -> Vector2:
	var jitter: Vector2 = SPAWN_JITTER[_spawn_index % SPAWN_JITTER.size()]
	_spawn_index += 1
	return HUMAN_SPAWN + jitter


func _refresh_local_hud(me: Node) -> void:
	var st: Dictionary = me.stats
	stats_label.text = "Human Fighter  Lv%d\nHP %d/%d   XP %d/%d\nP.Atk %d   P.Def %d\nWeapon+%d  Armor+%d" % [
		me.level,
		me.hp, int(st.get("max_hp", 0)),
		me.xp, Combat.xp_to_next(me.level),
		int(st.get("p_atk", 0)), int(st.get("p_def", 0)),
		int(st.get("weapon_patk", 0)), int(st.get("armor_pdef", 0)),
	]
	var eq_lines: PackedStringArray = PackedStringArray()
	eq_lines.append("Equipped:")
	for slot in [Items.SLOT_WEAPON, Items.SLOT_HEAD, Items.SLOT_CHEST, Items.SLOT_LEGS]:
		var id: String = str(me.equipped.get(slot, ""))
		eq_lines.append("  %s: %s" % [slot, Items.display_name(id) if id != "" else "—"])
	eq_lines.append("Bag:")
	if me.inventory.is_empty():
		eq_lines.append("  (empty — press E near glow)")
	else:
		for id2 in me.inventory:
			eq_lines.append("  • %s" % Items.display_name(str(id2)))
	inv_label.text = "\n".join(eq_lines)

	var t := _find_mob(me.target_mob_id)
	if t and t.alive:
		target_label.text = "Target: %s\nHP %d/%d" % [t.display_name, t.hp, t.max_hp]
	else:
		target_label.text = "Target: none\n(Tab / F to engage)"


func _push_log(line: String) -> void:
	_combat_log.append(line)
	while _combat_log.size() > 6:
		_combat_log.remove_at(0)
	if log_label:
		log_label.text = "\n".join(_combat_log)
	print("[combat] %s" % line)


func _name_of(peer_id: int) -> String:
	var p := players.get_node_or_null(str(peer_id))
	if p:
		return p.display_name
	return "Player-%s" % peer_id


func _mob_name(mob_id: int) -> String:
	var m := _find_mob(mob_id)
	if m:
		return m.display_name
	return "mob #%s" % mob_id


func _set_status(text: String) -> void:
	status_label.text = text
	print("[status] %s" % text)
