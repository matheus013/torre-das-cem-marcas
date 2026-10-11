extends SceneTree

class Game:
	extends "res://src/prototype/village/village_exploration.gd"
	var elapsed := 0.0
	var completed_at := -1.0
	var last_sent := ""
	var cicatrization_started := false
	var saw_warning := false

	func _run_test_hooks(delta: float) -> void:
		elapsed += delta
		if "--cicatrization-proof" in OS.get_cmdline_user_args():
			_run_cicatrization_proof()
			return
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
					if _sim.narrative.rescue_state == "rescued" and not _sim.narrative.fissure_found:
						var markers: Array = _sim.narrative_route_markers()
						state["position"] = markers[0]["position"]
						state["target"] = state["position"]
				elif stage == "evidence_found" and state["zone"] == &"tower":
					_sim.leave_tower(peer)
			if stage == "completed":
				if int(_sim.banked_loot.get("musgo_de_orientacao", 0)) != 1:
					push_error("Narrative network reward duplicated")
					get_tree().quit(1)
				if _sim.narrative.rescue_state != "rescued":
					push_error("Network rescue did not complete")
					get_tree().quit(1)
				if not _sim.narrative.fissure_found:
					push_error("Network fissure discovery did not complete")
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
				phase += ":%s:%s" % [model.get("route_choice", ""), model.get("fissure_found", false)]
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
					elif model.get("rescue_state") == "rescued":
						if not model.get("fissure_found", false) and not _near_route_marker().is_empty():
							action = String(_near_route_marker()["action"])
						elif model.get("fissure_found", false) and _near_narrative_marker():
							action = "inspect"
				if not action.is_empty():
					_send_intent("narrative", [action])
					_send_intent("narrative", [action])
					last_sent = phase
			if stage == "completed":
				if (model.get("journal", []) as Array).size() != 7 or not model.get("opening_known", false) or model.get("rescue_state") != "rescued" or not model.get("fissure_found", false):
					push_error("Network journal incomplete")
					get_tree().quit(1)
				print("NARRATIVE_CLIENT_OK stage=completed journal=7 rescue=rescued fissure_found=true opening_known=true")
				get_tree().quit(0)
		if elapsed > 16:
			push_error("Narrative network timed out")
			get_tree().quit(1)

	func _run_cicatrization_proof() -> void:
		if _sim != null:
			if not cicatrization_started:
				_sim.narrative.accept()
				_sim.start_floor(2)
				_sim.enemies.clear()
				_sim.player(_local_peer)["zone"] = &"tower"
				_sim.player(_local_peer)["position"] = _sim.floor_layout["entry"]
				_sim.player(_local_peer)["target"] = _sim.floor_layout["entry"]
				cicatrization_started = true
			for peer: int in _sim.players:
				if peer == _local_peer or not _sim.player(peer).get("connected", false):
					continue
				_sim.player(peer)["zone"] = &"tower"
				_sim.player(peer)["position"] = _sim.cicatrization_marker()
				_sim.player(peer)["target"] = _sim.cicatrization_marker()
			if _sim.narrative.cicatrization_state == "closed":
				if completed_at < 0:
					completed_at = elapsed
					print("NARRATIVE_HOST_COMPLETED cicatrization=closed")
				if elapsed - completed_at > 6:
					print("NARRATIVE_HOST_OK cicatrization=closed")
					get_tree().quit(0)
		else:
			var model: Dictionary = _view.get("narrative", {})
			var phase := String(model.get("cicatrization_state", ""))
			_sync_floor()
			if phase == "unseen" and last_sent.is_empty() and not _near_route_marker().is_empty():
				_send_intent("narrative", ["observe_cicatrization"])
				_send_intent("narrative", ["observe_cicatrization"])
				last_sent = "observe_cicatrization"
			if phase == "warning":
				saw_warning = true
				if _floor_cicatrized:
					push_error("Client closed geometry before confirmed warning ended")
					get_tree().quit(1)
			if phase == "closed":
				var center: Vector2 = _floor_layout.get("cicatrization_center", Vector2.ZERO)
				if not _floor_cicatrized or FloorLayoutScript.can_stand(_floor_layout, center, 24) or (model.get("journal", []) as Array).size() != 1:
					push_error("Client layout/journal differs from confirmed closure")
					get_tree().quit(1)
				print("NARRATIVE_CLIENT_OK cicatrization=closed warning_seen=%s" % saw_warning)
				get_tree().quit(0)
		if elapsed > 16:
			push_error("Cicatrization network timed out")
			get_tree().quit(1)

func _init() -> void:
	_start.call_deferred()

func _start() -> void:
	var game := Game.new()
	game.name = "VillageExploration"
	root.add_child(game)
