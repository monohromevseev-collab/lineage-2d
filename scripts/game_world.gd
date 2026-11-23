extends Node2D
## Shared zone: hosts ENet, spawns players, keeps server as authority.
## Movement RPCs live here (stable node path) so late joiners sync cleanly.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const NetConfig := preload("res://scripts/net_config.gd")
const SYNC_HZ := 20.0

@export var net_cfg: Dictionary = {}

@onready var players: Node2D = $Players
@onready var hud: CanvasLayer = $HUD
@onready var status_label: Label = $HUD/Status
@onready var help_label: Label = $HUD/Help

var _peer: ENetMultiplayerPeer
var _spawn_index: int = 0
## peer_id -> display name requested before spawn finished
var _pending_names: Dictionary = {}
var _sync_accum: float = 0.0

## Approximate Talking-Island-like meadow extents (world space).
const ZONE_HALF := Vector2(420, 280)
const SPAWN_POINTS := [
	Vector2(-80, 40),
	Vector2(80, 40),
	Vector2(0, -40),
	Vector2(-140, -20),
	Vector2(140, -20),
]


func _ready() -> void:
	if net_cfg.is_empty():
		net_cfg = NetConfig.from_cmdline()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	help_label.text = "WASD / arrows to move · server authoritative · slice 0 (no combat)"
	_start_network()


func _physics_process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	if multiplayer.is_server():
		for child in players.get_children():
			child.server_tick(delta)
		_sync_accum += delta
		if _sync_accum >= 1.0 / SYNC_HZ:
			_sync_accum = 0.0
			for child in players.get_children():
				_sync_player.rpc(int(str(child.name)), child.position)
		return

	# Local client: collect input and send to server.
	var my_id := multiplayer.get_unique_id()
	var me := players.get_node_or_null(str(my_id))
	if me == null:
		return
	var dir: Vector2 = me.poll_input(delta)
	_submit_input.rpc_id(1, dir)
	me.predict_local(dir, delta)


func _start_network() -> void:
	_peer = ENetMultiplayerPeer.new()
	if net_cfg.mode == "server":
		var err := _peer.create_server(int(net_cfg.port), NetConfig.MAX_CLIENTS)
		if err != OK:
			_set_status("Server failed to bind port %s (err %s)" % [net_cfg.port, err])
			push_error(status_label.text)
			return
		multiplayer.multiplayer_peer = _peer
		_set_status("Dedicated server listening on :%s" % net_cfg.port)
		print("[net] server ready, waiting for clients")
	else:
		var err := _peer.create_client(str(net_cfg.host), int(net_cfg.port))
		if err != OK:
			_set_status("Client create failed (err %s)" % err)
			return
		multiplayer.multiplayer_peer = _peer
		_set_status("Connecting to %s:%s …" % [net_cfg.host, net_cfg.port])


func _on_peer_connected(id: int) -> void:
	print("[net] peer connected: %s" % id)
	if not multiplayer.is_server():
		return
	# Existing players for the new peer + new player for everyone.
	for child in players.get_children():
		var pid := int(str(child.name))
		_spawn_player.rpc_id(id, pid, child.position, child.display_name)
	var pos := _next_spawn()
	var pname: String = str(_pending_names.get(id, "Player-%s" % id))
	_spawn_player.rpc(id, pos, pname)


func _on_peer_disconnected(id: int) -> void:
	print("[net] peer disconnected: %s" % id)
	_pending_names.erase(id)
	if multiplayer.is_server():
		_despawn_player.rpc(id)
	else:
		_remove_player_local(id)


func _on_connected_to_server() -> void:
	_set_status("Connected — peer id %s" % multiplayer.get_unique_id())
	var preferred: String = str(net_cfg.get("display_name", ""))
	if preferred == "":
		preferred = "Player-%s" % multiplayer.get_unique_id()
	_register_name.rpc_id(1, preferred)


func _on_connection_failed() -> void:
	_set_status("Connection failed — is the server running?")


func _on_server_disconnected() -> void:
	_set_status("Server disconnected")
	for child in players.get_children():
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
func _spawn_player(peer_id: int, pos: Vector2, display_name: String) -> void:
	if players.get_node_or_null(str(peer_id)):
		return
	var p: Node2D = PLAYER_SCENE.instantiate()
	p.name = str(peer_id)
	p.position = pos
	players.add_child(p, true)
	p.setup(peer_id, display_name, ZONE_HALF)
	if typeof(net_cfg) == TYPE_DICTIONARY and bool(net_cfg.get("bot", false)) \
			and multiplayer.has_multiplayer_peer() \
			and multiplayer.get_unique_id() == peer_id:
		p.bot_mode = true
	print("[world] spawned peer %s (%s) at %s" % [peer_id, display_name, pos])


@rpc("authority", "call_local", "reliable")
func _despawn_player(peer_id: int) -> void:
	_remove_player_local(peer_id)


func _remove_player_local(peer_id: int) -> void:
	var node := players.get_node_or_null(str(peer_id))
	if node:
		node.queue_free()


@rpc("any_peer", "unreliable")
func _submit_input(dir: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var node := players.get_node_or_null(str(sender))
	if node:
		node.receive_input(dir)


@rpc("authority", "unreliable", "call_remote")
func _sync_player(peer_id: int, pos: Vector2) -> void:
	if multiplayer.is_server():
		return
	var node := players.get_node_or_null(str(peer_id))
	if node:
		node.apply_authoritative(pos)


func _next_spawn() -> Vector2:
	var pos: Vector2 = SPAWN_POINTS[_spawn_index % SPAWN_POINTS.size()]
	_spawn_index += 1
	return pos


func _set_status(text: String) -> void:
	status_label.text = text
	print("[status] %s" % text)
