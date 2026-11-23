extends RefCounted
## Simplified High-Five–flavored combat + progression helpers.


static func hit_chance(acc: float, eva: float, atk_lvl: int, def_lvl: int) -> float:
	var raw := 0.8 + (acc - eva) * 0.01 + float(atk_lvl - def_lvl) * 0.02
	return clampf(raw, 0.3, 0.98)


static func phys_damage(p_atk: float, p_def: float, atk_lvl: int, skill_power: float = 1.0) -> int:
	var level_mod := 1.0 + float(atk_lvl - 1) * 0.02
	var roll := randf_range(0.95, 1.05)
	var dmg := (p_atk * skill_power) * level_mod / maxf(1.0, p_def) * roll
	return maxi(1, int(round(dmg)))


static func xp_to_next(level: int) -> int:
	return 40 + level * 35


static func human_fighter_base() -> Dictionary:
	return {
		"race": "human",
		"class_id": "human_fighter",
		"str": 40,
		"dex": 30,
		"con": 43,
		"int": 21,
		"wit": 11,
		"men": 25,
		"base_speed": 180.0,
	}


static func derived_stats(base: Dictionary, level: int, gear: Dictionary) -> Dictionary:
	var Items := preload("res://data/items.gd")
	var str_v: int = int(base.get("str", 40)) + (level - 1) * 2
	var dex_v: int = int(base.get("dex", 30)) + (level - 1)
	var con_v: int = int(base.get("con", 43)) + (level - 1) * 2

	var weapon_patk := 0
	var armor_pdef := 0
	for slot in gear.keys():
		var item_id: String = str(gear[slot])
		if item_id == "" or item_id == "null":
			continue
		var it: Dictionary = Items.get_item(item_id)
		weapon_patk += int(it.get("p_atk", 0))
		armor_pdef += int(it.get("p_def", 0))

	var max_hp := 80 + con_v * 4 + level * 18
	var p_atk := 4 + int(str_v * 0.55) + weapon_patk
	var p_def := 3 + int(con_v * 0.25) + armor_pdef
	var accuracy := 20.0 + dex_v * 0.6 + level
	var evasion := 15.0 + dex_v * 0.5 + level * 0.5
	var atk_interval := clampf(1.15 - dex_v * 0.004 - weapon_patk * 0.004, 0.55, 1.4)
	var speed: float = float(base.get("base_speed", 180.0)) + dex_v * 0.4

	return {
		"str": str_v,
		"dex": dex_v,
		"con": con_v,
		"max_hp": max_hp,
		"p_atk": p_atk,
		"p_def": p_def,
		"accuracy": accuracy,
		"evasion": evasion,
		"atk_interval": atk_interval,
		"speed": speed,
		"weapon_patk": weapon_patk,
		"armor_pdef": armor_pdef,
	}
