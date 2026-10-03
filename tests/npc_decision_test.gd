extends SceneTree


func _init() -> void:
	var guard := NpcMind.new(&"guard_alda")
	guard.set_trait(&"caution", 0.6)
	guard.set_value(&"duty", 0.9)
	guard.set_value(&"empathy", 0.5)
	guard.set_value(&"integrity", 0.8)
	guard.set_relation(&"player_eloa", &"trust", 0.0)
	guard.remember(&"witnessed_crime", &"player_eloa", -1.0)

	var report := NpcDecisionOption.new(&"report_crime", 5.0)
	report.required_facts = [&"crime_seen"]
	report.value_weights = {&"duty": 30.0, &"integrity": 12.0}
	report.relation_weights = {&"trust": -20.0}
	report.memory_weights = {&"witnessed_crime": -18.0}
	report.urgency_weight = 8.0
	report.risk = 0.1

	var warn := NpcDecisionOption.new(&"warn_player", 0.0)
	warn.required_facts = [&"crime_seen"]
	warn.value_weights = {&"empathy": 10.0}
	warn.relation_weights = {&"trust": 35.0}
	warn.memory_weights = {&"life_debt": 30.0}
	warn.risk = 0.3
	warn.moral_cost = 0.2

	var conceal := NpcDecisionOption.new(&"conceal_evidence", -3.0)
	conceal.required_facts = [&"crime_seen"]
	conceal.relation_weights = {&"trust": 25.0}
	conceal.memory_weights = {&"life_debt": 18.0}
	conceal.risk = 0.6
	conceal.moral_cost = 0.8

	var options: Array[NpcDecisionOption] = [report, warn, conceal]
	var context := NpcDecisionContext.new(&"player_eloa", 0.7, [&"crime_seen"])
	var first_choice := guard.choose_action(options, context)
	if first_choice == null or first_choice.id != &"report_crime":
		push_error("Expected a dutiful neutral guard to report the crime")
		quit(1)
		return

	guard.set_relation(&"player_eloa", &"trust", 0.95)
	guard.remember(&"life_debt", &"player_eloa", 1.0)
	var second_choice := guard.choose_action(options, context)
	if second_choice == null or second_choice.id != &"warn_player":
		push_error("Expected trust and a life debt to change the decision")
		quit(1)
		return

	var unknown_context := NpcDecisionContext.new(&"player_eloa", 0.7, [])
	if guard.choose_action(options, unknown_context) != null:
		push_error("NPC selected an action that requires unknown information")
		quit(1)
		return

	print("NPC_DECISION_OK: duty reports; trust and memory change the choice to warning")
	quit(0)
