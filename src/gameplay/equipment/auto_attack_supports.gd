class_name AutoAttackSupports
extends RefCounted

const Resolver := preload("res://src/gameplay/skills/skill_effect_resolver.gd")
const CAPACITY := 6
const SLOT := 4
const COMMON_FIELDS := ["power", "range", "cooldown", "breath_cost", "critical_chance", "life_steal", "knockback", "breath_per_hit", "barrier_per_hit"]
const PROJECTILE_FIELDS := ["projectile_count", "pierce", "ricochet", "return_projectile", "fork_count", "impact_area"]


static func definition(weapon: Dictionary) -> Dictionary:
	var pattern := String(weapon.get("pattern", "single"))
	var projectile := String(weapon.get("weapon_type", "")) == "focus"
	var tags: Array = ["damage"]
	if projectile:
		tags.append("projectile")
	if pattern in ["line", "cone"]:
		tags.append("area")
	return {"name": "Autoataque", "mechanic": "projectile" if projectile else ("beam" if pattern == "line" else "cone"), "tags": tags}


static func supports(weapon: Dictionary, support: Dictionary) -> bool:
	var base := definition(weapon)
	if not Resolver.new().supports(base, support):
		return false
	for key: String in support.get("modifiers", {}):
		var field := key.trim_suffix("_multiplier").trim_suffix("_add")
		if field in COMMON_FIELDS:
			continue
		if field == "radius" and "area" in base["tags"]:
			continue
		if field in PROJECTILE_FIELDS and "projectile" in base["tags"]:
			continue
		return false
	return true


static func resolve(weapon: Dictionary, attached: Array[Dictionary]) -> Dictionary:
	var base := definition(weapon)
	base.merge({"power": weapon["damage"], "range": weapon["range"], "cooldown": weapon["interval"], "breath_cost": 0.0, "critical_chance": weapon["crit_add"], "knockback": weapon.get("knockback", 0.0), "radius": weapon.get("width", weapon["range"])})
	var active: Array[Dictionary] = []
	var used := 0
	for support in attached:
		var drain := int(support.get("drain", 0))
		if supports(weapon, support) and used + drain <= CAPACITY:
			active.append(support)
			used += drain
	var effect := Resolver.new().resolve(base, active)
	var result := weapon.duplicate(true)
	result.merge(effect, true)
	result["name"] = weapon["name"]
	result["damage"] = effect["power"]
	result["interval"] = effect["cooldown"]
	result["crit_add"] = effect["critical_chance"]
	if weapon["pattern"] == "line":
		result["width"] = effect["radius"]
	elif weapon["pattern"] == "cone":
		result["range"] = float(effect["range"]) * float(effect["radius"]) / float(base["radius"])
	if "projectile" in effect["tags"]:
		result["radius"] = 42.0
	return result
