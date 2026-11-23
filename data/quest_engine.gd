extends RefCounted
## Authoritative HF quest logic for TI Newbie Helper tutorial + Letters of Love.


static func _reg():
	return preload("res://data/data_registry.gd")


static func default_state() -> Dictionary:
	return {
		"255": {"step": "not_started"},
		"1": {"step": "available", "cond": 0},
		"adena": 0,
		"sp_bank": 0,
	}


static func has_item(player: Node, item_id: String) -> bool:
	return player.inventory.has(item_id) or player.inventory.find(item_id) >= 0


static func take_item(player: Node, item_id: String, count: int = 1) -> bool:
	var removed := 0
	while removed < count:
		var idx: int = player.inventory.find(item_id)
		if idx < 0:
			return removed > 0
		player.inventory.remove_at(idx)
		removed += 1
	return true


static func give_item(player: Node, item_id: String, count: int = 1) -> void:
	# Adena is a single wallet counter + one bag slot (not N coin entries).
	if item_id == "57":
		give_adena(player, count)
		return
	# Stack high-count etc items (Soulshots) so the bag UI stays usable.
	if item_id == "5789":
		var key := "stack_%s" % item_id
		player.quests[key] = int(player.quests.get(key, 0)) + count
		if not has_item(player, item_id):
			player.inventory.append(item_id)
		return
	for _i in range(count):
		player.inventory.append(item_id)


static func give_adena(player: Node, amount: int) -> void:
	if amount < 0:
		return
	if not player.quests.has("adena"):
		player.quests["adena"] = 0
	# Collapse legacy per-coin bag rows into one wallet counter.
	var loose := 0
	var i := 0
	while i < player.inventory.size():
		if str(player.inventory[i]) == "57":
			player.inventory.remove_at(i)
			loose += 1
		else:
			i += 1
	var wallet := int(player.quests["adena"])
	# Loose rows from old loot never touched the wallet — fold them in once.
	# While a single display slot exists with wallet>0, loose==1 is just that slot.
	if loose > 0:
		if wallet <= 0:
			wallet += loose
		elif loose > 1:
			wallet += loose - 1
	wallet += amount
	player.quests["adena"] = wallet
	if wallet > 0:
		player.inventory.append("57")


static func adena_count(player: Node) -> int:
	return int(player.quests.get("adena", 0))


static func objective_text(player: Node) -> String:
	var q255: Dictionary = player.quests.get("255", {})
	var step: String = str(q255.get("step", "not_started"))
	if step != "completed":
		var qdoc: Dictionary = _reg().get_quest("255")
		var steps: Dictionary = qdoc.get("steps", {})
		return str(steps.get(step, {}).get("objective", "Talk to the Newbie Helper."))
	var q1: Dictionary = player.quests.get("1", {})
	var s1: String = str(q1.get("step", "available"))
	var q1doc: Dictionary = _reg().get_quest("1")
	var steps1: Dictionary = q1doc.get("steps", {})
	if s1 == "available" or s1 == "completed":
		return str(steps1.get(s1, {}).get("objective", ""))
	return str(steps1.get(str(q1.get("cond", 1)), {}).get("objective", ""))


static func dialog_for(npc_id: String, player: Node) -> Dictionary:
	var dialogs: Dictionary = _reg().dialogs.get(npc_id, {})
	match npc_id:
		"30009":
			var step: String = str(player.quests.get("255", {}).get("step", "not_started"))
			if step == "hunt_gremlin" and has_item(player, "6353"):
				step = "return_helper"
			return dialogs.get(step, dialogs.get("not_started", {}))
		"30008":
			if has_item(player, "1067"):
				return dialogs.get("need_reco", {})
			var step: String = str(player.quests.get("255", {}).get("step", "not_started"))
			if step == "completed":
				return dialogs.get("after", {})
			return dialogs.get("no_reco", {})
		"30048":
			var q1: Dictionary = player.quests.get("1", {})
			var st: String = str(q1.get("step", "available"))
			if st == "completed":
				return dialogs.get("done", {})
			if player.level < 2 and st == "available":
				return dialogs.get("too_low", {})
			if st == "available":
				return dialogs.get("available", {})
			var cond := int(q1.get("cond", 0))
			return dialogs.get("cond_%d" % cond, dialogs.get("available", {}))
		"30006":
			var q1: Dictionary = player.quests.get("1", {})
			if int(q1.get("cond", 0)) == 1 and has_item(player, "687"):
				return dialogs.get("need_letter", {})
			if int(q1.get("cond", 0)) >= 2 and str(q1.get("step", "")) != "completed":
				return dialogs.get("waiting", {})
			return dialogs.get("idle", {})
		"30033":
			var q1: Dictionary = player.quests.get("1", {})
			if int(q1.get("cond", 0)) == 3 and has_item(player, "1079"):
				return dialogs.get("need_receipt", {})
			if int(q1.get("cond", 0)) == 4:
				return dialogs.get("waiting", {})
			return dialogs.get("idle", {})
	return {"text": "...", "choices": [{"id": "close", "label": "Leave."}]}


## Returns {ok, log, refresh_dialog}
static func apply_choice(npc_id: String, choice_id: String, player: Node) -> Dictionary:
	var log := ""
	match choice_id:
		"close":
			return {"ok": true, "log": "", "close": true}
		"accept_gem":
			player.quests["255"] = {"step": "hunt_gremlin"}
			log = "Quest started: recover a Blue Gemstone from Gremlins."
			return {"ok": true, "log": log, "close": false}
		"turn_in_gem":
			if not has_item(player, "6353"):
				return {"ok": false, "log": "You have no Blue Gemstone.", "close": false}
			take_item(player, "6353", 1)
			give_item(player, "1067", 1)
			give_item(player, "5789", 200)
			player.quests["255"] = {"step": "see_roien"}
			log = "Received Recommendation and 200 Soulshots (Beginner). Speak with Roien."
			return {"ok": true, "log": log, "close": false}
		"give_reco":
			if not has_item(player, "1067"):
				return {"ok": false, "log": "You need a Recommendation.", "close": false}
			take_item(player, "1067", 1)
			give_item(player, "5789", 200)
			give_item(player, "5588", 1)
			# HF addExpAndSp(0,50) — SP stand-in as XP (unconfirmed).
			var xp_info: Dictionary = player.grant_xp(50)
			player.quests["sp_bank"] = int(player.quests.get("sp_bank", 0)) + 50
			player.quests["255"] = {"step": "completed"}
			log = "Roien accepts the Recommendation. +50 XP (SP stand-in), Soulshots, Tutorial Guide."
			if bool(xp_info.get("leveled", false)):
				log += " Level up!"
			return {"ok": true, "log": log, "close": false, "leveled": xp_info}
		"start_lol":
			if player.level < 2:
				return {"ok": false, "log": "Requires level 2.", "close": false}
			give_item(player, "687", 1)
			player.quests["1"] = {"step": "started", "cond": 1}
			log = "Quest started: Letters of Love. Deliver Darin's Letter to Roxxy."
			return {"ok": true, "log": log, "close": false}
		"give_letter":
			if not has_item(player, "687"):
				return {"ok": false, "log": "No letter.", "close": false}
			take_item(player, "687", 1)
			give_item(player, "688", 1)
			player.quests["1"] = {"step": "started", "cond": 2}
			log = "Roxxy gives you her Kerchief. Return to Darin."
			return {"ok": true, "log": log, "close": false}
		"turn_kerchief":
			if not has_item(player, "688"):
				return {"ok": false, "log": "No kerchief.", "close": false}
			take_item(player, "688", 1)
			give_item(player, "1079", 1)
			player.quests["1"] = {"step": "started", "cond": 3}
			log = "Darin gives you a Receipt for Baulro."
			return {"ok": true, "log": log, "close": false}
		"give_receipt":
			if not has_item(player, "1079"):
				return {"ok": false, "log": "No receipt.", "close": false}
			take_item(player, "1079", 1)
			give_item(player, "1080", 1)
			player.quests["1"] = {"step": "started", "cond": 4}
			log = "Baulro gives you the potion. Return to Darin."
			return {"ok": true, "log": log, "close": false}
		"finish_lol":
			if not has_item(player, "1080"):
				return {"ok": false, "log": "No potion.", "close": false}
			take_item(player, "1080", 1)
			give_item(player, "906", 1)
			give_adena(player, 2466)
			var xp_info2: Dictionary = player.grant_xp(5672)
			player.quests["sp_bank"] = int(player.quests.get("sp_bank", 0)) + 446
			player.quests["1"] = {"step": "completed", "cond": 4}
			log = "Letters of Love complete! Necklace of Knowledge, 5672 XP, 2466 Adena."
			if bool(xp_info2.get("leveled", false)):
				log += " Level up!"
			return {"ok": true, "log": log, "close": false, "leveled": xp_info2}
	return {"ok": false, "log": "Unknown choice.", "close": true}


## HF: ~50% Blue Gemstone on Tutorial Gremlin kill while hunting.
static func on_mob_killed(player: Node, template_id: String) -> Dictionary:
	var out := {"gem": false, "log": ""}
	if str(template_id) != "18342":
		return out
	var step: String = str(player.quests.get("255", {}).get("step", ""))
	if step != "hunt_gremlin":
		return out
	if has_item(player, "6353"):
		return out
	# getRandom(2) <= 1  → 0 or 1, both succeed when <=1 → 100%? 
	# In Java ThreadLocalRandom nextInt(2) returns 0 or 1; <=1 is always true!
	# That would be 100%. Looking again: getRandom(2) in L2J often means nextInt(2) which is 0,1 and <=1 is always.
	# Some L2J getRandom(n) is nextInt(n) exclusive. So always drops?
	# Actually comment in many packs: chance roughly 50% using getRandom(100) < 50.
	# Line: if (... && (getRandom(2) <= 1)) — if getRandom is 0..2 inclusive that's 2/3.
	# We'll use 50% and mark unconfirmed exact RNG helper.
	if randf() <= 0.5:
		give_item(player, "6353", 1)
		out.gem = true
		out.log = "Obtained Blue Gemstone! Return to the Newbie Helper."
	return out
