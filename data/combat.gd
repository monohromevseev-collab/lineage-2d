extends RefCounted
## High Five–flavored combat + progression. Formulas marked unconfirmed where not full L2J.


static func _reg():
	return preload("res://data/data_registry.gd")


static func hit_chance(acc: float, eva: float, atk_lvl: int, def_lvl: int) -> float:
	# Unconfirmed simplified hit model (not full L2J Formulas.getHitChance).
	var raw := 0.8 + (acc - eva) * 0.01 + float(atk_lvl - def_lvl) * 0.02
	return clampf(raw, 0.3, 0.98)


static func phys_damage(p_atk: float, p_def: float, atk_lvl: int, skill_power: float = 1.0) -> int:
	## Unconfirmed HF-lite: community-style 70 * pAtk / pDef (not Formulas.calcPhysDam).
	var level_mod := 1.0 + float(atk_lvl - 1) * 0.02
	var roll := randf_range(0.90, 1.10)
	var dmg := (70.0 * p_atk * skill_power) / maxf(1.0, p_def) * level_mod * roll
	return maxi(1, int(round(dmg)))


static func xp_to_next(level: int) -> int:
	return _reg().xp_to_next(level)


static func human_fighter_base() -> Dictionary:
	var cls: Dictionary = _reg().get_char_class("0")
	return {
		"race": str(cls.get("race", "human")),
		"class_id": "human_fighter",
		"str": int(cls.get("str", 40)),
		"dex": int(cls.get("dex", 30)),
		"con": int(cls.get("con", 43)),
		"int": int(cls.get("int", 21)),
		"wit": int(cls.get("wit", 11)),
		"men": int(cls.get("men", 25)),
		"base_p_atk": int(cls.get("base_p_atk", 4)),
		"base_p_def_parts": cls.get("base_p_def_parts", {}),
		"base_speed": float(cls.get("base_speed_px", 180.0)),
		"level_gains": cls.get("level_gains", {}),
	}


static func derived_stats(base: Dictionary, level: int, gear: Dictionary) -> Dictionary:
	var Items := preload("res://data/items.gd")
	var str_v: int = int(base.get("str", 40))
	var dex_v: int = int(base.get("dex", 30))
	var con_v: int = int(base.get("con", 43))
	var men_v: int = int(base.get("men", 25))

	var weapon_patk := 0
	var armor_pdef := 0
	var covered: Dictionary = {}
	for slot in gear.keys():
		var item_id: String = str(gear[slot])
		if item_id == "" or item_id == "null":
			continue
		var it: Dictionary = Items.get_item(item_id)
		weapon_patk += int(it.get("p_atk", 0))
		armor_pdef += int(it.get("p_def", 0))
		covered[str(slot)] = true

	# Unequipped body parts keep HF basePDef (confirmed from HumanFighter.xml).
	var parts: Dictionary = base.get("base_p_def_parts", {})
	var slot_to_part := {
		"chest": "chest",
		"legs": "legs",
		"head": "head",
		"gloves": "gloves",
		"feet": "feet",
	}
	var base_armor := 0
	for slot_name in ["chest", "legs", "head", "gloves", "feet", "underwear", "cloak"]:
		var equipped_slot := ""
		for s in slot_to_part.keys():
			if slot_to_part[s] == slot_name:
				equipped_slot = s
				break
		if equipped_slot != "" and covered.get(equipped_slot, false):
			continue
		base_armor += int(parts.get(slot_name, 0))

	var gains: Dictionary = base.get("level_gains", {})
	var g: Dictionary = gains.get(str(level), {})
	var max_hp: int
	var max_mp: int
	var max_cp: int
	if not g.is_empty():
		max_hp = maxi(1, int(round(float(g.get("hp", 80)))))
		max_mp = maxi(1, int(round(float(g.get("mp", 30)))))
		max_cp = maxi(1, int(round(float(g.get("cp", 32)))))
	else:
		# Fallback if level beyond ingested table — unconfirmed.
		max_hp = 80 + con_v * 4 + level * 18
		max_mp = 30 + men_v * 2 + level * 6
		max_cp = 32 + con_v + level * 8

	var base_patk: int = int(base.get("base_p_atk", 4))
	var p_atk := base_patk + weapon_patk
	var p_def := base_armor + armor_pdef
	var accuracy := 20.0 + dex_v * 0.6 + level
	var evasion := 15.0 + dex_v * 0.5 + level * 0.5
	# Unconfirmed atk interval from dex (HF uses weapon pAtkSpd separately).
	var atk_interval := clampf(1.15 - dex_v * 0.004 - weapon_patk * 0.002, 0.55, 1.4)
	var speed: float = float(base.get("base_speed", 180.0)) + dex_v * 0.4

	return {
		"str": str_v,
		"dex": dex_v,
		"con": con_v,
		"men": men_v,
		"max_hp": max_hp,
		"max_mp": max_mp,
		"max_cp": max_cp,
		"p_atk": p_atk,
		"p_def": p_def,
		"accuracy": accuracy,
		"evasion": evasion,
		"atk_interval": atk_interval,
		"speed": speed,
		"weapon_patk": weapon_patk,
		"armor_pdef": armor_pdef + base_armor,
	}


## Require roughly facing the target (dot > ~0.15) and within range.
static func can_melee(attacker_pos: Vector2, facing: Vector2, target_pos: Vector2, range_px: float) -> Dictionary:
	var to := target_pos - attacker_pos
	var dist := to.length()
	if dist > range_px:
		return {"ok": false, "reason": "range"}
	var face := facing
	if face.length_squared() < 0.01:
		face = to.normalized()
	else:
		face = face.normalized()
	var dir := to.normalized()
	if face.dot(dir) < 0.15:
		return {"ok": false, "reason": "facing"}
	return {"ok": true, "reason": ""}
