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
					var destination := "alda_serrin" if stage == "available" and not _sim.narrative.opening_known else "nara_quiral"
					state["position"] = _sim.village_life.call("find", destination)["position"]
					state["target"] = state["position"]
				elif stage == "active":
					if state["zone"] != &"tower":
						_sim.enter_tower(peer)
					_sim.enemies.clear()
					state["position"] = _sim.narrative_worker_position() if _sim.narrative.rescue_state == "escorting" else _sim.narrative_marker()
					state["target"] = state["position"]
					# Accelerated host time keeps this network proof short; only domain movement advances rescue.
					for tick in range(10):
						state["position"] = _sim.narrative_worker_position() if _sim.narrative.rescue_state == "escorting" else _sim.narrative_marker()
						state["target"] = state["position"]
						_sim._step_narrative_rescue(0.25)
				elif stage == "evidence_found" and state["zone"] == &"tower":
					_sim.leave_tower(peer)
			if stage == "completed":
				if int(_sim.banked_loot.get("musgo_de_orientacao", 0)) != 1:
					push_error("Narrative network reward duplicated")
					get_tree().quit(1)
				if _sim.narrative.rescue_state != "rescued":
					push_error("Network rescue did not complete")
					get_tree().quit(1)
				if completed_at < 0:
					completed_at = elapsed
					print("NARRATIVE_HOST_COMPLETED reward=1 opening_known=%s" % _sim.narrative.opening_known)
				if elapsed - completed_at > 6:
					print("NARRATIVE_HOST_OK reward=1")
					get_tree().quit(0)
		else:
			var model := _view.get("narrative", {}) as Dictionary
			var stage := String(model.get("stage", ""))
			var phase := stage + (":opening" if stage == "available" and not model.get("opening_known", false) else "")
			if stage == "active":
				phase += ":" + String(model.get("rescue_state", "waiting"))
			if phase != last_sent and not _local().is_empty():
				var action := ""
				if stage in ["available", "report_ready"] and _local_zone() == &"village":
					var npc := _nearest_npc(110)
					if npc.get("id", "") == "alda_serrin" and not model.get("opening_known", false):
						action = "acknowledge_crisis"
					elif npc.get("id", "") == "nara_quiral":
						action = "accept" if stage == "available" else "report"
				elif stage == "active":
					if model.get("rescue_state") == "waiting" and _near_field_worker():
						action = "rescue_worker"
					elif model.get("rescue_state") == "rescued" and _near_narrative_marker():
						action = "inspect"
				if not action.is_empty():
					_send_intent("narrative", [action])
					_send_intent("narrative", [action])
					last_sent = phase
			if stage == "completed":
				if (model.get("journal", []) as Array).size() != 5 or not model.get("opening_known", false) or model.get("rescue_state") != "rescued":
					push_error("Network journal incomplete")
					get_tree().quit(1)
				print("NARRATIVE_CLIENT_OK stage=completed journal=5 rescue=rescued opening_known=true")
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
