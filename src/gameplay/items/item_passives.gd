class_name ItemPassives
extends RefCounted

## Passivas exclusivas de itens lendários e armas únicas (decisão 580). Cada passiva vem dos dados
## do item (`passive`): modificadores fixos (`mods`, somados aos marcos em `_mod`) e gatilhos
## (`triggers`) com filtros e ações. A simulação chama os ganchos; aqui ficam filtros e ações.
## Dano, lançamento e cura causados por passiva não disparam outros gatilhos de acerto e abate,
## para que nenhuma combinação vire uma cadeia infinita.

## "volley": cada volta completa da Saraivada de Flechas (decisão 596).
const TRIGGERS: Array[String] = ["cast", "hit", "kill", "hurt", "lethal", "interval", "volley"]
const ACTIONS: Array[String] = [
	"cast", "burst", "burn", "freeze", "vulnerable", "heal", "barrier", "breath",
	"refund", "buff", "invulnerable", "recast", "execute", "revive", "spread_burn", "poison", "break",
]
const FILTERS: Array[String] = [
	"on", "actions", "gem", "element", "tag", "source", "mechanic", "crit", "chance", "every",
	"cooldown", "burning", "below", "seconds", "poisoned", "moving",
]
## Chaves de `mods` e de bônus temporários: as mesmas lidas por `_mod` na simulação.
const MOD_KEYS: Array[String] = [
	"power_mult", "auto_damage_mult", "auto_rate_mult", "damage_taken_mult", "breath_regen_mult",
	"move_speed_mult", "cooldown_mult", "radius_mult", "barrier_mult", "duration_mult", "breath_cost_mult",
	"crit_chance_add", "crit_damage_add", "max_health_add", "max_breath_add", "life_steal_add",
	"heal_on_kill_add", "breath_on_kill_add", "healing_mult", "barrier_on_skill_add", "poison_spread_mult",
	"power_physical_mult", "power_magic_mult", "power_fire_mult", "power_ice_mult",
	"power_lightning_mult", "power_acid_mult", "power_nature_mult", "power_dark_mult",
	"power_holy_mult", "power_earth_mult", "power_arcane_mult", "power_summon_mult",
	# Regras (decisão 598): chaves lidas em pontos fixos da simulação, não multiplicadores comuns.
	"burn_lasting", "breath_cost_lightning_mult", "health_cost_dark", "health_cost_all", "overheal_barrier",
	"still_damage_reduction", "crit_cadence", "strength_physical_conversion", "max_health_mult", "slot_locked_q",
	"summon_duration_mult", "cooldown_kill_only", "moving_free_cast", "contact_immunity", "no_healing",
	"penetration_add", "resist_all_add", "resist_cap_add", "light_radius_mult",
	# Regras dos divinos (decisão 608).
	"no_cooldown", "cast_health_ratio", "element_cycle", "poison_eternal", "summon_limit_mult", "auto_hits_all",
	"damage_cap_ratio", "barrier_permanent", "lit_damage_bonus",
]
const ItemAffixesScript := preload("res://src/gameplay/items/item_affixes.gd")
const BURN_TICK := 0.5
## Chefes sentem metade do congelamento: controle total trivializaria as lutas.
const BOSS_CONTROL := 0.5


## Passivas dos itens equipados, com o item de origem e a gema da arma única.
static func active(sim: RefCounted, peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var gear := sim.call("_gear", peer_id) as Dictionary
	if gear.is_empty():
		return result
	var equipment := gear["equipment"] as EquipmentLoadout
	var key := ""
	var items: Array[EquipmentItemInstance] = []
	for item in equipment._all_items():
		items.append(item)
		key += String(item.instance_id) + ";"
	# Tabuleiro de Paragon (decisão 607): entra no mesmo cache, com a alocação na chave.
	key += "|" + String(sim.call("paragon_signature", peer_id)) if sim.has_method("paragon_signature") else ""
	key += "|" + ",".join(PackedStringArray(sim.call("active_pacts") as Array)) if sim.has_method("active_pacts") else ""
	var cache := sim.get("_passive_cache") as Dictionary
	var cached := cache.get(peer_id, {}) as Dictionary
	if String(cached.get("key", "-")) == key:
		return cached["passives"] as Array[Dictionary]
	var data := _loadout_data(sim, items)
	if sim.has_method("paragon_passives"):
		(data["passives"] as Array).append_array(sim.call("paragon_passives", peer_id) as Array)
	if sim.has_method("pact_passives"):
		(data["passives"] as Array).append_array(sim.call("pact_passives") as Array)
	cache[peer_id] = {"key": key, "passives": data["passives"], "affix_mods": data["affix_mods"]}
	return data["passives"]


static func _loadout_data(sim: RefCounted, items: Array[EquipmentItemInstance]) -> Dictionary:
	var result: Array[Dictionary] = []
	# Afixos de modificador (decisão 583) entram junto, no mesmo cache por peças equipadas.
	var affix_mods := {}
	for item in items:
		ItemAffixesScript.combine(affix_mods, ItemAffixesScript.mods(item.affixes))
	for item in items:
		var data := sim.call("item_data", String(item.definition.id)) as Dictionary
		# Divinos (decisão 608) trazem 1 ou 2 linhas em `passives`; lendários e únicas, uma em `passive`.
		var lines: Array = (data.get("passives", []) as Array).duplicate()
		if not (data.get("passive", {}) as Dictionary).is_empty():
			lines.push_front(data["passive"])
		for passive: Dictionary in lines:
			var entry := passive.duplicate(true)
			entry["item_id"] = String(item.definition.id)
			entry["unique_gem"] = String(data.get("unique_gem", ""))
			result.append(entry)
	return {"passives": result, "affix_mods": affix_mods}


## Modificador fixo das passivas e bônus temporários ativos: `_mult` multiplica, o resto soma.
static func modifier(sim: RefCounted, peer_id: int, key: String, equipment_override: EquipmentLoadout = null) -> float:
	var multiply := key.ends_with("_mult")
	var value := 1.0 if multiply else 0.0
	var passives: Array[Dictionary] = []
	var affix_mods := {}
	if equipment_override != null:
		var data := _loadout_data(sim, equipment_override._all_items())
		passives = data["passives"]
		affix_mods = data["affix_mods"]
	else:
		passives = active(sim, peer_id)
		affix_mods = ((sim.get("_passive_cache") as Dictionary).get(peer_id, {}) as Dictionary).get("affix_mods", {}) as Dictionary
	if affix_mods.has(key):
		value = value * float(affix_mods[key]) if multiply else value + float(affix_mods[key])
	for passive in passives:
		var mods := passive.get("mods", {}) as Dictionary
		if mods.has(key):
			value = value * float(mods[key]) if multiply else value + float(mods[key])
	var state := sim.call("player", peer_id) as Dictionary
	var buffs := (state.get("item_passive", {}) as Dictionary).get("buffs", {}) as Dictionary
	for buff: Dictionary in buffs.values():
		var mods := buff.get("mods", {}) as Dictionary
		if mods.has(key):
			var stacks := float(buff.get("stacks", 1))
			value = value * (1.0 + (float(mods[key]) - 1.0) * stacks) if multiply else value + float(mods[key]) * stacks
	return value


## Bônus ativos e recargas longas das passivas para a faixa de efeitos da HUD (decisão 581).
## Recargas curtas (menos de 5 s) ficam de fora: piscariam o tempo todo sem informar nada.
static func status_effects(sim: RefCounted, peer_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var state := sim.call("player", peer_id) as Dictionary
	if not state.has("item_passive"):
		return result
	var memory := state["item_passive"] as Dictionary
	for buff_id: Variant in memory["buffs"]:
		var buff := (memory["buffs"] as Dictionary)[buff_id] as Dictionary
		result.append({"id": "buff:" + String(buff_id), "kind": "buff", "name": String(buff.get("name", "")),
			"texture": _status_texture(buff, buff.get("mods", {}) as Dictionary), "remaining": float(buff["time"]),
			"duration": float(buff.get("duration", buff["time"])), "stacks": int(buff.get("stacks", 1)), "max_stacks": int(buff.get("max_stacks", 1)),
			"description": _describe_mods(buff.get("mods", {}) as Dictionary, int(buff.get("stacks", 1)))})
	for passive in active(sim, peer_id):
		var triggers := passive.get("triggers", []) as Array
		for index in range(triggers.size()):
			var trigger := triggers[index] as Dictionary
			var total := float(trigger.get("cooldown", 0.0))
			var remaining := float((memory["cooldowns"] as Dictionary).get("%s:%d" % [passive["item_id"], index], 0.0))
			if total >= 5.0 and remaining > 0.0:
				result.append({"id": "cooldown:%s:%d" % [passive["item_id"], index], "kind": "cooldown", "name": String(passive.get("name", "")),
					"texture": _status_texture(passive, {}), "remaining": remaining, "duration": total, "stacks": 1, "max_stacks": 1,
					"description": "Recarregando: volta a agir quando o tempo acabar."})
	return result


static func _status_texture(source: Dictionary, mods: Dictionary) -> String:
	var item_id := String(source.get("item_id", ""))
	if ResourceLoader.exists("res://assets/sprites/items/%s.png" % item_id):
		return "items/" + item_id
	if not String(source.get("unique_gem", "")).is_empty():
		return "icons/" + String(source["unique_gem"])
	if mods.has("damage_taken_mult"):
		return "icons/muralha_refeita"
	if mods.has("move_speed_mult") and not mods.has("power_mult"):
		return "icons/passo_vetorial"
	return "icons/sobrecarga_instavel"


static func _describe_mods(mods: Dictionary, stacks: int) -> String:
	var labels := {"power_mult": "potencia", "damage_taken_mult": "dano recebido", "move_speed_mult": "velocidade",
		"auto_damage_mult": "dano do autoataque", "auto_rate_mult": "cadencia"}
	var parts := PackedStringArray()
	for key: Variant in mods:
		var change := (float(mods[key]) - 1.0) * float(stacks) if String(key).ends_with("_mult") else float(mods[key]) * float(stacks)
		parts.append("%s %s%.0f%%" % [labels.get(key, String(key)), "+" if change >= 0.0 else "", change * 100.0])
	return ", ".join(parts) + (" (%d acumulos)" % stacks if stacks > 1 else "")


# ---------------------------------------------------------------- ganchos

static func on_cast(sim: RefCounted, peer_id: int, effect: Dictionary, target: Vector2, slot: int) -> void:
	var gem_id := String(effect.get("gem_id", ""))
	_fire(sim, peer_id, "cast", {"gem_id": gem_id, "source": "gem", "effect": effect, "target": target, "slot": slot, "position": target})


static func on_hit(sim: RefCounted, peer_id: int, enemy: Dictionary, damage: float, hit: Dictionary, critical: bool) -> void:
	if bool(hit.get("passive", false)):
		return
	_fire(sim, peer_id, "hit", _hit_context(enemy, damage, hit, critical))


static func on_kill(sim: RefCounted, peer_id: int, enemy: Dictionary, damage: float, hit: Dictionary) -> void:
	if bool(hit.get("passive", false)):
		return
	_fire(sim, peer_id, "kill", _hit_context(enemy, damage, hit, false))


## Volta completa da Saraivada de Flechas (cada `arrow_count` flechas).
static func on_volley_turn(sim: RefCounted, peer_id: int, effect: Dictionary) -> void:
	var state := sim.call("player", peer_id) as Dictionary
	_fire(sim, peer_id, "volley", {"gem_id": String(effect.get("gem_id", "")), "source": "gem", "position": state["position"], "target": state["position"]})


static func on_hurt(sim: RefCounted, peer_id: int, amount: float) -> void:
	var state := sim.call("player", peer_id) as Dictionary
	_fire(sim, peer_id, "hurt", {"damage": amount, "position": state["position"], "source": ""})


## Golpe letal: verdadeiro se alguma passiva (`revive`) manteve a personagem de pé.
static func on_lethal(sim: RefCounted, peer_id: int) -> bool:
	var state := sim.call("player", peer_id) as Dictionary
	return _fire(sim, peer_id, "lethal", {"damage": 0.0, "position": state["position"], "source": ""})


## Recargas internas, bônus temporários e gatilhos por intervalo; só dentro da Torre.
static func tick(sim: RefCounted, peer_id: int, delta: float) -> void:
	var memory := _memory(sim, peer_id)
	for table: String in ["cooldowns", "timers"]:
		var values := memory[table] as Dictionary
		for key: Variant in values.keys():
			values[key] = float(values[key]) - delta
	var buffs := memory["buffs"] as Dictionary
	for buff_id: Variant in buffs.keys():
		var buff := buffs[buff_id] as Dictionary
		buff["time"] = float(buff["time"]) - delta
		if float(buff["time"]) <= 0.0:
			buffs.erase(buff_id)
	var passives := active(sim, peer_id)
	for passive_index in range(passives.size()):
		var triggers := passives[passive_index].get("triggers", []) as Array
		for trigger_index in range(triggers.size()):
			var trigger := triggers[trigger_index] as Dictionary
			if String(trigger.get("on", "")) != "interval":
				continue
			var key := "%s:%d" % [passives[passive_index]["item_id"], trigger_index]
			var timers := memory["timers"] as Dictionary
			if float(timers.get(key, 0.0)) > 0.0:
				continue
			timers[key] = float(trigger.get("seconds", 5.0))
			var state := sim.call("player", peer_id) as Dictionary
			if bool(trigger.get("moving", false)) and not bool(state.get("moving", false)):
				timers[key] = 0.1
				continue
			var nearest := int(sim.call("nearest_enemy_to", state["position"], 420.0))
			if nearest < 0:
				timers[key] = 0.5
				continue
			var context := {"position": state["position"], "target": (sim.get("enemies") as Array)[nearest]["position"], "damage": 0.0, "source": ""}
			_run_actions(sim, peer_id, passives[passive_index], trigger, context)


## Queimadura: dano por segundo acumulado, aplicado a cada meio segundo por quem acendeu.
static func step_burns(sim: RefCounted, delta: float) -> void:
	var enemies := sim.get("enemies") as Array
	for index in range(enemies.size() - 1, -1, -1):
		if index >= enemies.size():
			continue
		var enemy := enemies[index] as Dictionary
		if float(enemy.get("burn_timer", 0.0)) <= 0.0:
			continue
		enemy["burn_timer"] = float(enemy["burn_timer"]) - delta
		enemy["burn_tick"] = float(enemy.get("burn_tick", BURN_TICK)) - delta
		if float(enemy["burn_tick"]) > 0.0:
			continue
		enemy["burn_tick"] = BURN_TICK
		var peer_id := int(enemy.get("burn_peer", 0))
		if (sim.get("players") as Dictionary).has(peer_id):
			sim.call("damage_enemy", peer_id, index, float(enemy.get("burn_dps", 0.0)) * BURN_TICK, {"passive": true, "dot": true, "damage_type": "arcane", "element": "fire"})


# ---------------------------------------------------------------- regras

static func _hit_context(enemy: Dictionary, damage: float, hit: Dictionary, critical: bool) -> Dictionary:
	return {
		"enemy": enemy, "position": enemy["position"], "target": enemy["position"], "damage": damage, "critical": critical,
		"gem_id": String(hit.get("gem_id", "")), "source": "gem" if bool(hit.get("gem", false)) else "auto",
		"damage_type": String(hit.get("damage_type", "physical")),
	}


static func _memory(sim: RefCounted, peer_id: int) -> Dictionary:
	var state := sim.call("player", peer_id) as Dictionary
	if not state.has("item_passive"):
		state["item_passive"] = {"cooldowns": {}, "timers": {}, "counters": {}, "buffs": {}}
	return state["item_passive"] as Dictionary


## Dispara os gatilhos do tipo pedido. Verdadeiro se algum `revive` aconteceu.
static func _fire(sim: RefCounted, peer_id: int, kind: String, context: Dictionary) -> bool:
	context["peer"] = peer_id
	var revived := false
	var passives := active(sim, peer_id)
	if passives.is_empty():
		return false
	var memory := _memory(sim, peer_id)
	for passive in passives:
		var triggers := passive.get("triggers", []) as Array
		for trigger_index in range(triggers.size()):
			var trigger := triggers[trigger_index] as Dictionary
			if String(trigger.get("on", "")) != kind or not _matches(sim, trigger, context):
				continue
			var key := "%s:%d" % [passive["item_id"], trigger_index]
			if float((memory["cooldowns"] as Dictionary).get(key, 0.0)) > 0.0:
				continue
			if trigger.has("every"):
				var counters := memory["counters"] as Dictionary
				counters[key] = int(counters.get(key, 0)) + 1
				if int(counters[key]) % maxi(1, int(trigger["every"])) != 0:
					continue
			if trigger.has("chance") and (sim.get("_crit_random") as RandomNumberGenerator).randf() >= float(trigger["chance"]):
				continue
			if trigger.has("cooldown"):
				(memory["cooldowns"] as Dictionary)[key] = float(trigger["cooldown"])
			revived = _run_actions(sim, peer_id, passive, trigger, context) or revived
	return revived


static func _matches(sim: RefCounted, trigger: Dictionary, context: Dictionary) -> bool:
	var gem_id := String(context.get("gem_id", ""))
	var gem := sim.call("gem_definition", gem_id) as Dictionary if not gem_id.is_empty() else {}
	if trigger.has("source") and String(trigger["source"]) != String(context.get("source", "")):
		return false
	if trigger.has("gem") and String(trigger["gem"]) != gem_id:
		return false
	if trigger.has("element") and String(gem.get("element", "")) != String(trigger["element"]):
		return false
	if trigger.has("mechanic") and String(gem.get("mechanic", "")) != String(trigger["mechanic"]):
		return false
	if trigger.has("tag"):
		var tag := String(trigger["tag"])
		var tags := gem.get("tags", []) as Array
		if String(context.get("source", "")) == "auto":
			tags = ["physical" if String(context.get("damage_type", "physical")) == "physical" else "magic"]
		if tag not in tags:
			return false
	if bool(trigger.get("crit", false)) and not bool(context.get("critical", false)):
		return false
	if bool(trigger.get("moving", false)) and not bool((sim.call("player", int(context.get("peer", 0))) as Dictionary).get("moving", false)):
		return false
	var enemy := context.get("enemy", {}) as Dictionary
	if bool(trigger.get("burning", false)) and float(enemy.get("burn_timer", 0.0)) <= 0.0:
		return false
	if bool(trigger.get("poisoned", false)) and (enemy.get("poisons", {}) as Dictionary).is_empty():
		return false
	if trigger.has("below") and (enemy.is_empty() or float(enemy.get("health", 0.0)) > float(enemy.get("max_health", 1.0)) * float(trigger["below"])):
		return false
	return true


static func _run_actions(sim: RefCounted, peer_id: int, passive: Dictionary, trigger: Dictionary, context: Dictionary) -> bool:
	var revived := false
	for action: Dictionary in trigger.get("actions", []) as Array:
		revived = _act(sim, peer_id, passive, action, context) or revived
	return revived


static func _act(sim: RefCounted, peer_id: int, passive: Dictionary, action: Dictionary, context: Dictionary) -> bool:
	var state := sim.call("player", peer_id) as Dictionary
	if state.is_empty():
		return false
	var zone := state["zone"] as StringName
	var enemy := context.get("enemy", {}) as Dictionary
	var maximum := float(sim.call("max_health", peer_id))
	match String(action.get("do", "")):
		"cast":
			_cast(sim, peer_id, action, context)
		"burst":
			var center := state["position"] as Vector2 if String(action.get("at", "victim")) == "self" else context.get("position", state["position"]) as Vector2
			var radius := float(action.get("radius", 80.0)) * float((sim.call("derived_stats", peer_id) as Dictionary).get("area_multiplier", 1.0))
			if bool(action.get("spread_scaled", false)):
				radius *= modifier(sim, peer_id, "poison_spread_mult")
			var damage := _amount(sim, peer_id, passive, action, context)
			var previous := String(sim.get("_vfx_theme"))
			sim.set("_vfx_theme", "element:" + String(action.get("element", "arcane")))
			sim.call("_vfx", zone, "strike", [center, radius])
			sim.set("_vfx_theme", previous)
			var hit := {"passive": true, "damage_type": "arcane"}
			for key: String in ["slow", "slow_duration", "vulnerable", "vulnerable_duration"]:
				if action.has(key):
					hit[key] = float(action[key])
			sim.call("damage_enemies", peer_id, center, radius, damage, hit)
		"burn":
			if not enemy.is_empty():
				var duration := float(action.get("duration", 3.0))
				var dps := _amount(sim, peer_id, passive, action, context) / duration
				if float(enemy.get("burn_timer", 0.0)) <= 0.0 or dps >= float(enemy.get("burn_dps", 0.0)):
					enemy["burn_dps"] = dps
					enemy["burn_peer"] = peer_id
				# Fogo que Não Apaga: com a regra, a queimadura não expira.
				enemy["burn_timer"] = 3600.0 if modifier(sim, peer_id, "burn_lasting") > 0.0 else maxf(float(enemy.get("burn_timer", 0.0)), duration)
		"freeze":
			if not enemy.is_empty():
				var strength := float(action.get("slow", 0.8)) * (BOSS_CONTROL if bool(enemy.get("floor_boss", false)) else 1.0)
				enemy["slow_amount"] = maxf(float(enemy.get("slow_amount", 0.0)) if float(enemy.get("slow_timer", 0.0)) > 0.0 else 0.0, strength)
				enemy["slow_timer"] = maxf(float(enemy.get("slow_timer", 0.0)), float(action.get("duration", 1.5)))
		"vulnerable":
			if not enemy.is_empty():
				enemy["vulnerable_amount"] = maxf(float(enemy.get("vulnerable_amount", 0.0)) if float(enemy.get("vulnerable_timer", 0.0)) > 0.0 else 0.0, float(action.get("amount", 0.25)))
				enemy["vulnerable_timer"] = maxf(float(enemy.get("vulnerable_timer", 0.0)), float(action.get("duration", 3.0)))
		"heal":
			sim.call("heal_player", peer_id, maximum * float(action.get("ratio", 0.05)))
		"barrier":
			sim.call("_add_barrier", peer_id, maximum * float(action.get("ratio", 0.1)), float(action.get("duration", 4.0)), false)
		"breath":
			state["breath"] = minf(float(sim.call("max_breath", peer_id)), float(state["breath"]) + float(action.get("amount", 5.0)))
		"refund":
			var cooldowns := state["cooldowns"] as Array[float]
			var slots: Array[int] = []
			var scope := String(action.get("scope", "trigger"))
			if scope == "all":
				slots = [0, 1, 2, 3]
			elif scope == "trigger" and int(context.get("slot", -1)) >= 0:
				slots = [int(context["slot"])]
			else:
				var gem_id := String(context.get("gem_id", "")) if scope == "trigger" else scope
				var equipped := (sim.call("_gem_state", peer_id) as Dictionary).get("slots", []) as Array
				if equipped.has(gem_id):
					slots = [equipped.find(gem_id)]
			for slot in slots:
				if slot < cooldowns.size() and cooldowns[slot] > 0.0:
					# Fica um resto mínimo: o passo seguinte devolve a carga pelo caminho normal.
					cooldowns[slot] = maxf(0.001, cooldowns[slot] - float(action.get("seconds", 1.0)))
		"buff":
			var buffs := _memory(sim, peer_id)["buffs"] as Dictionary
			var buff_id := String(action.get("id", passive.get("item_id", "")))
			var current := buffs.get(buff_id, {}) as Dictionary
			buffs[buff_id] = {"mods": action.get("mods", {}), "time": float(action.get("duration", 4.0)), "duration": float(action.get("duration", 4.0)),
				"stacks": mini(int(action.get("stacks", 1)), int(current.get("stacks", 0)) + 1), "max_stacks": int(action.get("stacks", 1)),
				"name": String(passive.get("name", "")), "item_id": String(passive.get("item_id", "")), "unique_gem": String(passive.get("unique_gem", ""))}
		"invulnerable":
			state["invulnerable"] = maxf(float(state["invulnerable"]), float(action.get("seconds", 1.0)))
		"recast":
			var effect := (context.get("effect", {}) as Dictionary).duplicate(true)
			if effect.is_empty() or String(effect.get("mechanic", "")) in ["volley", "dash"]:
				return false
			_scale(effect, float(action.get("power", 0.6)))
			effect["passive_cast"] = true
			effect.erase("repeat_count")
			var scatter := float(action.get("scatter", 0.0))
			for index in range(int(action.get("count", 1))):
				var offset := Vector2.RIGHT.rotated(TAU * float(index) / maxf(1.0, float(action.get("count", 1)))) * scatter
				(sim.get("_scheduled") as Array).append({"time": float(action.get("delay", 0.3)) * float(index + 1), "peer": peer_id, "effect": effect,
					"target": (context.get("target", state["position"]) as Vector2) + offset, "zone": zone, "floor": sim.get("current_floor")})
		"execute":
			if not enemy.is_empty() and not bool(enemy.get("floor_boss", false)) and not bool(enemy.get("champion", false)):
				var index := (sim.get("enemies") as Array).find(enemy)
				if index >= 0 and float(enemy["health"]) > 0.0 and float(enemy["health"]) <= float(enemy.get("max_health", 1.0)) * float(action.get("below", 0.2)):
					sim.call("_vfx", zone, "label", [enemy["position"], "EXECUTADO", Color("e87a6a"), ""])
					# Conta como abate da gema (gatilhos de abate disparam), mas não como novo acerto.
					sim.call("damage_enemy", peer_id, index, float(enemy["health"]) + 1.0, {"dot": true, "gem": true, "gem_id": String(context.get("gem_id", "")), "execute": true})
		"spread_burn":
			# A queimadura de quem morreu passa para os vizinhos, com o mesmo dano por segundo.
			if not enemy.is_empty() and float(enemy.get("burn_dps", 0.0)) > 0.0:
				var radius := float(action.get("radius", 120.0))
				for other: Dictionary in sim.get("enemies") as Array:
					if other != enemy and (other["position"] as Vector2).distance_to(enemy["position"]) <= radius:
						other["burn_dps"] = maxf(float(other.get("burn_dps", 0.0)), float(enemy["burn_dps"]))
						other["burn_peer"] = peer_id
						other["burn_timer"] = maxf(float(other.get("burn_timer", 0.0)), float(enemy.get("burn_timer", 3.0)))
		"break":
			# Quebra elemental: reduz a resistência do alvo a um tipo por alguns segundos.
			if not enemy.is_empty():
				var element := String(action.get("element", "physical"))
				# "hit": o elemento da gema que acertou (físico se não tiver).
				if element == "hit":
					element = String((sim.call("gem_definition", String(context.get("gem_id", ""))) as Dictionary).get("element", ""))
					element = element if not element.is_empty() else "physical"
				Resistances.apply_break(enemy, element, float(action.get("amount", 0.2)), float(action.get("duration", 4.0)))
		"poison":
			# Toxina a partir do acerto: `ratio` do golpe ao longo de `duration` segundos.
			if not enemy.is_empty():
				var duration := maxf(0.5, float(action.get("duration", 3.0)))
				var per_tick := float(context.get("damage", 0.0)) * float(action.get("ratio", 0.3)) * 0.5 / duration
				sim.call("apply_poison", peer_id, enemy, "toxina", {"damage": per_tick, "interval": 0.5, "remaining": duration, "gem_id": String(context.get("gem_id", ""))})
		"revive":
			state["health"] = maxf(1.0, maximum * float(action.get("ratio", 0.5)))
			state["invulnerable"] = maxf(float(state["invulnerable"]), float(action.get("invulnerable", 2.0)))
			sim.call("_vfx", zone, "label", [state["position"], String(passive.get("name", "")).to_upper(), Color("f08a3c"), "levelup"])
			return true
	return false


## Dano de explosão e queimadura: fração do golpe que disparou (`ratio`), da potência da gema da
## arma única (`gem_power`, com a escala da personagem) ou valor fixo escalado pelo nível (`power`).
static func _amount(sim: RefCounted, peer_id: int, passive: Dictionary, action: Dictionary, context: Dictionary) -> float:
	var amount := float(context.get("damage", 0.0)) * float(action.get("ratio", 0.0))
	var victim := context.get("enemy", {}) as Dictionary
	if action.has("victim_health_ratio") and not victim.is_empty():
		amount += float(victim.get("max_health", 0.0)) * float(action["victim_health_ratio"])
	if action.has("gem_power"):
		var gem_id := String(action.get("gem", passive.get("unique_gem", "")))
		var gem := sim.call("gem_definition", gem_id) as Dictionary
		var model := {"gem_id": gem_id, "tags": gem.get("tags", [])}
		amount += float(gem.get("power", 0.0)) * float(sim.call("_skill_power_multiplier", peer_id, model)) * float(action["gem_power"])
	if action.has("power"):
		amount += float(action["power"]) * float(sim.call("level_power", peer_id)) * float(sim.call("_mod", peer_id, "power_mult"))
	return amount


## Lança uma gema de graça: a do encaixe (`slot`, com evoluções e suportes) ou a base do catálogo.
static func _cast(sim: RefCounted, peer_id: int, action: Dictionary, context: Dictionary) -> void:
	var effect: Dictionary
	var equipped := (sim.call("_gem_state", peer_id) as Dictionary).get("slots", []) as Array
	if action.has("slot"):
		effect = (sim.call("resolve_slot", peer_id, int(action["slot"])) as Dictionary).duplicate(true)
	elif bool(action.get("use_slot", false)) and equipped.has(String(action.get("gem", ""))):
		# Gema equipada: lança com evoluções e suportes do encaixe (Presa da Serpente).
		effect = (sim.call("resolve_slot", peer_id, equipped.find(String(action["gem"]))) as Dictionary).duplicate(true)
	else:
		effect = (sim.call("gem_definition", String(action.get("gem", ""))) as Dictionary).duplicate(true)
		effect["gem_id"] = String(action.get("gem", ""))
	if effect.is_empty() or String(effect.get("mechanic", "")) in ["volley", "dash"]:
		return
	_scale(effect, float(sim.call("_skill_power_multiplier", peer_id, effect)) * float(action.get("power", 1.0)))
	var area := float((sim.call("derived_stats", peer_id) as Dictionary).get("area_multiplier", 1.0))
	for key: String in ["radius", "impact_area", "collision_radius", "width", "arrival_area"]:
		if effect.has(key):
			effect[key] = float(effect[key]) * area
	# `override`: campos trocados no lançamento (ex.: poça de esporos dos Cogumelos).
	for key: String in action.get("override", {}) as Dictionary:
		effect[key] = (action["override"] as Dictionary)[key]
	if bool(action.get("spread_scaled", false)) and effect.has("radius"):
		effect["radius"] = float(effect["radius"]) * modifier(sim, peer_id, "poison_spread_mult")
	effect["passive_cast"] = true
	var state := sim.call("player", peer_id) as Dictionary
	var origin := state["position"] as Vector2
	var targets: Array[Vector2] = []
	match String(action.get("at", "target")):
		"self":
			targets.append(origin)
		"nearest":
			# Os mais próximos primeiro, um alvo diferente por lançamento enquanto houver.
			var nearby: Array[Vector2] = []
			# `skip_target`: os lançamentos extras vão para outros inimigos, não para o alvo original.
			var skipped := context.get("target", Vector2.INF) as Vector2 if bool(action.get("skip_target", false)) else Vector2.INF
			for enemy: Dictionary in sim.get("enemies") as Array:
				if (enemy["position"] as Vector2).distance_to(origin) <= 520.0 and (enemy["position"] as Vector2).distance_to(skipped) > 40.0:
					nearby.append(enemy["position"] as Vector2)
			if nearby.is_empty():
				return
			nearby.sort_custom(func(left: Vector2, right: Vector2) -> bool: return left.distance_to(origin) < right.distance_to(origin))
			for index in range(int(action.get("count", 1))):
				targets.append(nearby[index % nearby.size()])
		_:
			targets.append(context.get("target", origin) as Vector2)
	for target in targets:
		sim.call("execute_gem_effect", peer_id, effect.duplicate(true), target)


static func _scale(effect: Dictionary, ratio: float) -> void:
	for key: String in ["power", "barrier", "healing", "trail_damage", "arrival_damage", "expire_damage", "expire_nova_damage"]:
		if effect.has(key):
			effect[key] = float(effect[key]) * ratio


## Erros de dados de uma passiva (catálogo e testes).
static func validate(passive: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var name := String(passive.get("name", ""))
	if name.is_empty() or String(passive.get("description", "")).length() < 20:
		errors.append("passiva sem nome ou descricao: %s" % name)
	for key: Variant in passive.get("mods", {}) as Dictionary:
		if String(key) not in MOD_KEYS:
			errors.append("%s: modificador desconhecido %s" % [name, key])
	var triggers := passive.get("triggers", []) as Array
	if triggers.is_empty() and (passive.get("mods", {}) as Dictionary).is_empty() and (passive.get("transform", {}) as Dictionary).is_empty() and (passive.get("transform_from", {}) as Dictionary).is_empty() and (passive.get("gem_transforms", {}) as Dictionary).is_empty():
		errors.append("%s: sem gatilhos nem modificadores" % name)
	for trigger: Dictionary in triggers:
		if String(trigger.get("on", "")) not in TRIGGERS:
			errors.append("%s: gatilho desconhecido %s" % [name, trigger.get("on", "")])
		for key: Variant in trigger:
			if String(key) not in FILTERS:
				errors.append("%s: filtro desconhecido %s" % [name, key])
		if (trigger.get("actions", []) as Array).is_empty():
			errors.append("%s: gatilho sem acoes" % name)
		for action: Dictionary in trigger.get("actions", []) as Array:
			if String(action.get("do", "")) not in ACTIONS:
				errors.append("%s: acao desconhecida %s" % [name, action.get("do", "")])
			if String(action.get("do", "")) == "buff":
				for key: Variant in action.get("mods", {}) as Dictionary:
					if String(key) not in MOD_KEYS:
						errors.append("%s: bonus desconhecido %s" % [name, key])
	return errors
