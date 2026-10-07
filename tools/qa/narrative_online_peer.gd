extends SceneTree

class Game:
	extends "res://src/prototype/village/village_exploration.gd"
	var elapsed := 0.0
	var completed_at := -1.0
	var last_sent := ""

	func _run_test_hooks(delta: float) -> void:
		elapsed += delta
		if _sim != null:
			var stage := String(_sim.narrative.stage)
			for peer: int in _sim.players:
				if peer == _local_peer or not _sim.player(peer).get("connected", false):
					continue
				var state: Dictionary = _sim.player(peer)
				if stage in ["available", "report_ready"]:
					state["zone"] = &"village"
					state["position"] = _sim.village_life.call("find", "nara_quiral")["position"]
					state["target"] = state["position"]
				elif stage == "active":
					if state["zone"] != &"tower":
						_sim.enter_tower(peer)
					_sim.enemies.clear()
					state["position"] = _sim.narrative_marker()
					state["target"] = state["position"]
				elif stage == "evidence_found" and state["zone"] == &"tower":
					_sim.leave_tower(peer)
			if stage == "completed":
				if int(_sim.banked_loot.get("musgo_de_orientacao", 0)) != 1:
					push_error("Narrative network reward duplicated")
					get_tree().quit(1)
				if completed_at < 0:
					completed_at = elapsed
					print("NARRATIVE_HOST_COMPLETED reward=1")
				if elapsed - completed_at > 6:
					print("NARRATIVE_HOST_OK reward=1")
					get_tree().quit(0)
		else:
			var model := _view.get("narrative", {}) as Dictionary
			var stage := String(model.get("stage", ""))
			if stage != last_sent and not _local().is_empty():
				var action := ""
				if stage in ["available", "report_ready"] and _local_zone() == &"village":
					var npc := _nearest_npc(110)
					if npc.get("id", "") == "nara_quiral":
						action = "accept" if stage == "available" else "report"
				elif stage == "active" and _near_narrative_marker():
					action = "inspect"
				if not action.is_empty():
					_send_intent("narrative", [action])
					_send_intent("narrative", [action])
					last_sent = stage
			if stage == "completed":
				if (model.get("journal", []) as Array).size() != 3:
					push_error("Network journal incomplete")
					get_tree().quit(1)
				print("NARRATIVE_CLIENT_OK stage=completed journal=3")
				get_tree().quit(0)
		if elapsed > 16:
			push_error("Narrative network timed out")
			get_tree().quit(1)

func _init() -> void:
	_start.call_deferred()

func _start() -> void:
	var game := Game.new()
	game.name = "VillageExploration"
	root.add_child(game)
