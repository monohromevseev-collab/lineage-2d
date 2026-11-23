extends CanvasLayer
## L2-inspired HUD: bars, target frame, skill bar, inventory, minimap, full map.

signal attack_pressed
signal skill_pressed(skill_id: String)
signal inventory_toggled
signal map_toggled
signal equip_item(item_id: String)
signal pickup_pressed
signal dialog_choice(choice_id: String)
signal talk_pressed

const ItemIcons := preload("res://scripts/ui/item_icons.gd")
const IconSlot := preload("res://scripts/ui/icon_slot.gd")
const EquipIcon := preload("res://scripts/ui/equip_icon.gd")
const Items := preload("res://data/items.gd")
const Combat := preload("res://data/combat.gd")
const QuestEngine := preload("res://data/quest_engine.gd")

var _root: Control
var _hp: ProgressBar
var _mp: ProgressBar
var _cp: ProgressBar
var _xp: ProgressBar
var _hp_lbl: Label
var _mp_lbl: Label
var _cp_lbl: Label
var _xp_lbl: Label
var _level_lbl: Label
var _target_panel: PanelContainer
var _target_name: Label
var _target_hp: ProgressBar
var _target_hp_lbl: Label
var _inv_panel: PanelContainer
var _inv_grid: GridContainer
var _equip_labels: Dictionary = {}
var _log: RichTextLabel
var _minimap: Control
var _fullmap: Control
var _fullmap_visible: bool = false
var _inv_visible: bool = false
var _skill_attack: Button
var _help: Label
var _quest_lbl: Label
var _dialog_panel: PanelContainer
var _dialog_title: Label
var _dialog_body: RichTextLabel
var _dialog_choices: VBoxContainer
var _dialog_npc_id: String = ""
var _adena_lbl: Label

var _player_ref: WeakRef
var _world_ref: WeakRef
var _last_inv: Array = []


func _ready() -> void:
	layer = 10
	_build()
	_inv_panel.visible = false
	_fullmap.visible = false
	_dialog_panel.visible = false


func bind(world: Node, player: Node) -> void:
	_world_ref = weakref(world)
	_player_ref = weakref(player)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_player_bars()
	_build_target_frame()
	_build_quest_tracker()
	_build_dialog()
	_build_skill_bar()
	_build_inventory()
	_build_minimap()
	_build_fullmap()
	_build_log()
	_help = Label.new()
	_help.text = "WASD · LMB select/NPC talk · F/1 Attack · Tab target · I bag · M map · E pickup · Esc clear"
	_help.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_help.offset_top = -28
	_help.offset_bottom = -6
	_help.offset_left = 12
	_help.add_theme_font_size_override("font_size", 12)
	_help.add_theme_color_override("font_color", Color(0.85, 0.82, 0.7))
	_help.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_help.add_theme_constant_override("outline_size", 3)
	_help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_help)


func _build_player_bars() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(14, 12)
	panel.custom_minimum_size = Vector2(280, 118)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.82)
	style.border_color = Color(0.55, 0.48, 0.28, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)

	_level_lbl = Label.new()
	_level_lbl.text = "Human Fighter  Lv1"
	_level_lbl.add_theme_font_size_override("font_size", 14)
	_level_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
	v.add_child(_level_lbl)

	_cp = _make_bar(Color(0.85, 0.75, 0.25), v)
	_cp_lbl = _make_bar_label("CP", v)
	_hp = _make_bar(Color(0.75, 0.2, 0.18), v)
	_hp_lbl = _make_bar_label("HP", v)
	_mp = _make_bar(Color(0.2, 0.4, 0.85), v)
	_mp_lbl = _make_bar_label("MP", v)
	_xp = _make_bar(Color(0.55, 0.35, 0.75), v)
	_xp.custom_minimum_size = Vector2(0, 8)
	_xp_lbl = _make_bar_label("XP", v)


func _make_bar(col: Color, parent: Control) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 12)
	var fill := StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(2)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	parent.add_child(bar)
	return bar


func _make_bar_label(prefix: String, parent: Control) -> Label:
	var lbl := Label.new()
	lbl.text = prefix
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	# Overlay-style: put label after bar; keep simple.
	parent.add_child(lbl)
	return lbl


func _build_target_frame() -> void:
	_target_panel = PanelContainer.new()
	_target_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_target_panel.position = Vector2(-140, 10)
	_target_panel.custom_minimum_size = Vector2(280, 64)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.06, 0.88)
	style.border_color = Color(0.75, 0.35, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_target_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_target_panel)
	var v := VBoxContainer.new()
	_target_panel.add_child(v)
	_target_name = Label.new()
	_target_name.text = "No target"
	_target_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.55))
	v.add_child(_target_name)
	_target_hp = _make_bar(Color(0.7, 0.18, 0.15), v)
	_target_hp_lbl = Label.new()
	_target_hp_lbl.add_theme_font_size_override("font_size", 10)
	_target_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_target_hp_lbl)
	_target_panel.visible = false


func _build_quest_tracker() -> void:
	_quest_lbl = Label.new()
	_quest_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_quest_lbl.position = Vector2(16, 150)
	_quest_lbl.size = Vector2(360, 48)
	_quest_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest_lbl.add_theme_font_size_override("font_size", 13)
	_quest_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
	_quest_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_quest_lbl.add_theme_constant_override("outline_size", 4)
	_quest_lbl.text = "Quest: speak with the Newbie Helper"
	_root.add_child(_quest_lbl)
	_adena_lbl = Label.new()
	_adena_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_adena_lbl.position = Vector2(16, 198)
	_adena_lbl.add_theme_font_size_override("font_size", 12)
	_adena_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.35))
	_adena_lbl.text = "Adena: 0"
	_root.add_child(_adena_lbl)


func _build_dialog() -> void:
	_dialog_panel = PanelContainer.new()
	_dialog_panel.set_anchors_preset(Control.PRESET_CENTER)
	_dialog_panel.position = Vector2(-220, -40)
	_dialog_panel.custom_minimum_size = Vector2(440, 220)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.1, 0.94)
	style.border_color = Color(0.75, 0.65, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	_dialog_panel.add_theme_stylebox_override("panel", style)
	_dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dialog_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_dialog_panel.add_child(v)
	_dialog_title = Label.new()
	_dialog_title.add_theme_font_size_override("font_size", 16)
	_dialog_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	v.add_child(_dialog_title)
	_dialog_body = RichTextLabel.new()
	_dialog_body.bbcode_enabled = false
	_dialog_body.fit_content = true
	_dialog_body.custom_minimum_size = Vector2(400, 90)
	_dialog_body.scroll_active = true
	_dialog_body.add_theme_color_override("default_color", Color(0.92, 0.9, 0.85))
	v.add_child(_dialog_body)
	_dialog_choices = VBoxContainer.new()
	_dialog_choices.add_theme_constant_override("separation", 4)
	v.add_child(_dialog_choices)


func show_dialog(npc_id: String, npc_name: String, dlg: Dictionary) -> void:
	_dialog_npc_id = npc_id
	_dialog_title.text = npc_name
	_dialog_body.text = str(dlg.get("text", "..."))
	for c in _dialog_choices.get_children():
		c.queue_free()
	var choices: Array = dlg.get("choices", [])
	for ch in choices:
		var btn := Button.new()
		btn.text = str(ch.get("label", "..."))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var cid := str(ch.get("id", "close"))
		btn.pressed.connect(func (): dialog_choice.emit(cid))
		_dialog_choices.add_child(btn)
	_dialog_panel.visible = true


func close_dialog() -> void:
	_dialog_panel.visible = false
	_dialog_npc_id = ""


func _build_skill_bar() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.position = Vector2(-170, -78)
	bar.add_theme_constant_override("separation", 6)
	_root.add_child(bar)

	_skill_attack = _skill_button("attack", "1", true)
	bar.add_child(_skill_attack)
	bar.add_child(_skill_button("power_strike", "2", false))
	bar.add_child(_skill_button("heal", "3", false))

	var inv_btn := Button.new()
	inv_btn.text = "I Bag"
	inv_btn.custom_minimum_size = Vector2(56, 48)
	inv_btn.pressed.connect(func (): inventory_toggled.emit())
	bar.add_child(inv_btn)
	var map_btn := Button.new()
	map_btn.text = "M Map"
	map_btn.custom_minimum_size = Vector2(56, 48)
	map_btn.pressed.connect(func (): map_toggled.emit())
	bar.add_child(map_btn)
	var talk_btn := Button.new()
	talk_btn.text = "Talk"
	talk_btn.custom_minimum_size = Vector2(56, 48)
	talk_btn.pressed.connect(func (): talk_pressed.emit())
	bar.add_child(talk_btn)


func _skill_button(skill_id: String, hotkey: String, enabled: bool) -> Button:
	var b: Button = IconSlot.new()
	b.custom_minimum_size = Vector2(48, 48)
	b.tooltip_text = skill_id.capitalize() + " [" + hotkey + "]"
	b.disabled = not enabled
	b.kind = "skill"
	b.icon_id = skill_id
	b.icon_enabled = enabled
	b.hotkey = hotkey
	if enabled:
		b.pressed.connect(func ():
			if skill_id == "attack":
				attack_pressed.emit()
			else:
				skill_pressed.emit(skill_id)
		)
	return b


func _build_inventory() -> void:
	_inv_panel = PanelContainer.new()
	_inv_panel.anchor_left = 1.0
	_inv_panel.anchor_right = 1.0
	_inv_panel.anchor_top = 0.0
	_inv_panel.anchor_bottom = 0.0
	_inv_panel.offset_left = -400
	_inv_panel.offset_right = -12
	_inv_panel.offset_top = 170
	_inv_panel.offset_bottom = 560
	_inv_panel.custom_minimum_size = Vector2(380, 380)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.1, 0.94)
	style.border_color = Color(0.6, 0.52, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_inv_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_inv_panel)

	var v := VBoxContainer.new()
	_inv_panel.add_child(v)
	var title := Label.new()
	title.text = "Inventory / Equipment"
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	v.add_child(title)

	var eq := GridContainer.new()
	eq.columns = 2
	v.add_child(eq)
	for slot in [Items.SLOT_WEAPON, Items.SLOT_HEAD, Items.SLOT_CHEST, Items.SLOT_LEGS]:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(70, 36)
		lbl.text = slot
		row.add_child(lbl)
		var icon: Control = EquipIcon.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.slot_name = slot
		row.add_child(icon)
		var name_l := Label.new()
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_equip_labels[slot] = {"icon": icon, "name": name_l}
		row.add_child(name_l)
		eq.add_child(row)

	var bag_title := Label.new()
	bag_title.text = "Backpack (click to equip)"
	v.add_child(bag_title)
	_inv_grid = GridContainer.new()
	_inv_grid.columns = 6
	_inv_grid.add_theme_constant_override("h_separation", 6)
	_inv_grid.add_theme_constant_override("v_separation", 6)
	v.add_child(_inv_grid)


func _build_minimap() -> void:
	_minimap = Control.new()
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_minimap.position = Vector2(-168, 12)
	_minimap.custom_minimum_size = Vector2(150, 150)
	_minimap.size = Vector2(150, 150)
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_minimap.draw.connect(_draw_minimap)
	_root.add_child(_minimap)


func _build_fullmap() -> void:
	_fullmap = Control.new()
	_fullmap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fullmap.offset_left = 80
	_fullmap.offset_right = -80
	_fullmap.offset_top = 60
	_fullmap.offset_bottom = -60
	_fullmap.draw.connect(_draw_fullmap)
	_fullmap.gui_input.connect(func (ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_fullmap_visible = false
			_fullmap.visible = false
	)
	_root.add_child(_fullmap)


func _build_log() -> void:
	_log = RichTextLabel.new()
	_log.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_log.position = Vector2(12, -200)
	_log.size = Vector2(360, 110)
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.fit_content = false
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log.add_theme_font_size_override("normal_font_size", 11)
	_root.add_child(_log)


func toggle_inventory() -> void:
	_inv_visible = not _inv_visible
	_inv_panel.visible = _inv_visible
	if _inv_visible:
		_rebuild_inv_grid()


func toggle_map() -> void:
	_fullmap_visible = not _fullmap_visible
	_fullmap.visible = _fullmap_visible
	_fullmap.queue_redraw()


func push_log(line: String) -> void:
	_log.append_text(line + "\n")


func refresh(player: Node, world: Node) -> void:
	if player == null:
		return
	_player_ref = weakref(player)
	_world_ref = weakref(world)
	var st: Dictionary = player.stats
	var max_hp: float = float(st.get("max_hp", 1))
	var max_mp: float = float(st.get("max_mp", 1))
	var max_cp: float = float(st.get("max_cp", 1))
	_hp.max_value = max_hp
	_hp.value = player.hp
	_mp.max_value = max_mp
	_mp.value = player.mp
	_cp.max_value = max_cp
	_cp.value = player.cp
	_xp.max_value = Combat.xp_to_next(player.level)
	_xp.value = player.xp
	_hp_lbl.text = "HP  %d / %d" % [player.hp, int(max_hp)]
	_mp_lbl.text = "MP  %d / %d" % [player.mp, int(max_mp)]
	_cp_lbl.text = "CP  %d / %d" % [player.cp, int(max_cp)]
	_xp_lbl.text = "XP  %d / %d" % [player.xp, int(_xp.max_value)]
	_level_lbl.text = "Human Fighter  Lv%d   P.Atk %d  P.Def %d" % [
		player.level, int(st.get("p_atk", 0)), int(st.get("p_def", 0))
	]

	var t = world._find_mob(player.target_mob_id) if world else null
	if t and t.alive:
		_target_panel.visible = true
		_target_name.text = "%s  Lv%d" % [t.display_name, t.npc_level]
		_target_hp.max_value = t.max_hp
		_target_hp.value = t.hp
		_target_hp_lbl.text = "%d / %d" % [t.hp, t.max_hp]
	elif str(player.target_npc_id) != "" and world and world.npcs:
		var n = world.npcs.get_node_or_null(str(player.target_npc_id))
		if n:
			_target_panel.visible = true
			_target_name.text = n.display_name
			_target_hp.max_value = 1
			_target_hp.value = 1
			_target_hp_lbl.text = "NPC — click again / Talk"
		else:
			_target_panel.visible = false
	else:
		_target_panel.visible = false

	_quest_lbl.text = "Quest: %s" % QuestEngine.objective_text(player)
	_adena_lbl.text = "Adena: %d" % int(player.quests.get("adena", 0))

	for slot in _equip_labels.keys():
		var id: String = str(player.equipped.get(slot, ""))
		_equip_labels[slot].name.text = Items.display_name(id) if id != "" else "—"
		var icon = _equip_labels[slot].icon
		icon.item_id = id
		icon.queue_redraw()

	if _inv_visible and str(player.inventory) != str(_last_inv):
		_rebuild_inv_grid()
	_last_inv = player.inventory.duplicate()
	_minimap.queue_redraw()
	if _fullmap_visible:
		_fullmap.queue_redraw()


func _rebuild_inv_grid() -> void:
	for c in _inv_grid.get_children():
		c.queue_free()
	var p: Node = _player_ref.get_ref() if _player_ref else null
	if p == null:
		return
	for item_id in p.inventory:
		var btn: Button = IconSlot.new()
		btn.custom_minimum_size = Vector2(44, 44)
		btn.kind = "item"
		btn.icon_id = str(item_id)
		var tip := Items.display_name(str(item_id))
		var stack_key := "stack_%s" % str(item_id)
		if p.quests.has(stack_key):
			tip = "%s x%d" % [tip, int(p.quests[stack_key])]
		btn.tooltip_text = tip
		var captured := str(item_id)
		btn.pressed.connect(func (): equip_item.emit(captured))
		_inv_grid.add_child(btn)


func _draw_minimap() -> void:
	var r := Rect2(Vector2.ZERO, _minimap.size)
	_minimap.draw_rect(r, Color(0.05, 0.08, 0.06, 0.85))
	_minimap.draw_rect(r, Color(0.55, 0.5, 0.3), false, 1.5)
	var world: Node = _world_ref.get_ref() if _world_ref else null
	var player: Node = _player_ref.get_ref() if _player_ref else null
	if world == null or player == null:
		return
	var half: Vector2 = world.WORLD_HALF
	for m in world.mobs.get_children():
		if not m.alive:
			continue
		var p := _world_to_mini(m.position, half, r.size)
		_minimap.draw_circle(p, 2.5, Color(0.9, 0.35, 0.25))
	_minimap.draw_circle(_world_to_mini(world.HUMAN_SPAWN, half, r.size), 3.0, Color(0.4, 0.85, 1.0))
	_minimap.draw_circle(_world_to_mini(player.position, half, r.size), 3.5, Color(0.95, 0.9, 0.3))
	_minimap.draw_string(ThemeDB.fallback_font, Vector2(6, 14), "Map", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.85, 0.6))


func _draw_fullmap() -> void:
	var r := Rect2(Vector2.ZERO, _fullmap.size)
	_fullmap.draw_rect(r, Color(0.04, 0.06, 0.05, 0.92))
	_fullmap.draw_rect(r, Color(0.7, 0.6, 0.35), false, 2.0)
	var world: Node = _world_ref.get_ref() if _world_ref else null
	var player: Node = _player_ref.get_ref() if _player_ref else null
	if world == null or player == null:
		return
	var half: Vector2 = world.WORLD_HALF
	# Terrain tint
	_fullmap.draw_colored_polygon(PackedVector2Array([
		_world_to_mini(Vector2(-half.x, 0), half, r.size),
		_world_to_mini(Vector2(0, -half.y), half, r.size),
		_world_to_mini(Vector2(half.x, 0), half, r.size),
		_world_to_mini(Vector2(0, half.y), half, r.size),
	]), Color(0.2, 0.32, 0.18, 0.7))
	for m in world.mobs.get_children():
		if not m.alive:
			continue
		_fullmap.draw_circle(_world_to_mini(m.position, half, r.size), 4.0, Color(0.9, 0.3, 0.2))
	_fullmap.draw_circle(_world_to_mini(world.HUMAN_SPAWN, half, r.size), 6.0, Color(0.45, 0.9, 1.0))
	_fullmap.draw_circle(_world_to_mini(player.position, half, r.size), 6.0, Color(1.0, 0.92, 0.35))
	_fullmap.draw_string(ThemeDB.fallback_font, Vector2(16, 28), "Talking Island Meadow — click to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.95, 0.88, 0.55))


func _world_to_mini(pos: Vector2, half: Vector2, size: Vector2) -> Vector2:
	var nx := (pos.x / half.x) * 0.48 + 0.5
	var ny := (pos.y / half.y) * 0.48 + 0.5
	return Vector2(nx * size.x, ny * size.y)
