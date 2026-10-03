extends Node2D

const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4
const PLAYER_SPEED := 245.0
const ENEMY_SPEED := 72.0
const AUTO_ATTACK_RANGE := 170.0
const ARENA := Rect2(36.0, 92.0, 1208.0, 584.0)
const PLAYER_COLORS: Array[Color] = [
	Color("59d7a0"), Color("ffcc66"), Color("70a5ff"), Color("ff7096")
]
const SKILL_COOLDOWNS: Array[float] = [1.4, 3.0, 4.5, 8.0]

var _peer := ENetMultiplayerPeer.new()
var _players: Dictionary = {}
var _enemies: Dictionary = {}
var _next_enemy_id := 1
var _snapshot_accumulator := 0.0
var _spawn_accumulator := 0.0
var _test_duration := 0.0
var _session_active := false
var _local_target := Vector2.ZERO
var _status := "Escolha como iniciar a sessao"
var _feedback := ""
var _feedback_time := 0.0

var _menu: PanelContainer
var _address_input: LineEdit
var _port_input: SpinBox
var _host_button: Button
var _join_button: Button
var _menu_status: Label


func _ready() -> void:
	_build_interface()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_parse_command_line()
	queue_redraw()


func _process(delta: float) -> void:
	_feedback_time = maxf(0.0, _feedback_time - delta)
	if _test_duration > 0.0:
		_test_duration -= delta
		if _test_duration <= 0.0:
			print("NETWORK_TEST_DONE peer=%d players=%d" % [multiplayer.get_unique_id(), _players.size()])
			get_tree().quit()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _session_active or not multiplayer.is_server():
		return

	_simulate_players(delta)
	_simulate_enemies(delta)
	_simulate_auto_attacks(delta)
	_spawn_accumulator += delta
	if _spawn_accumulator >= 0.65 and _enemies.size() < 28:
		_spawn_accumulator = 0.0
		_spawn_enemy()

	_snapshot_accumulator += delta
	if _snapshot_accumulator >= 0.05:
		_snapshot_accumulator = 0.0
		receive_snapshot.rpc(_players, _enemies)


func _unhandled_input(event: InputEvent) -> void:
	if not _session_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_local_target = _clamp_to_arena(event.position)
			_send_move_target(_local_target)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_local_target = _clamp_to_arena(event.position)
		_send_move_target(_local_target)
	elif event is InputEventKey and event.pressed and not event.echo:
		var slot := _skill_slot_for_key(event.keycode)
		if slot >= 0:
			_send_skill(slot, _clamp_to_arena(get_viewport().get_mouse_position()))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_leave_session()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color("10151c"))
	draw_rect(ARENA, Color("19232b"), true)
	draw_rect(ARENA, Color("3d5261"), false, 2.0)

	for enemy_value: Variant in _enemies.values():
		var enemy := enemy_value as Dictionary
		var enemy_position := enemy.get("position", Vector2.ZERO) as Vector2
		draw_circle(enemy_position, 11.0, Color("e5524a"))
		draw_circle(enemy_position, 5.0, Color("722f37"))

	for peer_value: Variant in _players.keys():
		var peer_id := int(peer_value)
		var state := _players[peer_id] as Dictionary
		var player_position := state.get("position", Vector2.ZERO) as Vector2
		var color := Color(state.get("color", PLAYER_COLORS[0]))
		var pulse := float(state.get("pulse", 0.0))
		if pulse > 0.0:
			draw_arc(player_position, 28.0 + pulse * 18.0, 0.0, TAU, 32, color, 3.0)
		draw_circle(player_position, 17.0, color)
		draw_circle(player_position, 7.0, Color("f5f7fa"))
		if peer_id == multiplayer.get_unique_id():
			draw_arc(player_position, 23.0, 0.0, TAU, 32, Color.WHITE, 2.0)
			draw_line(player_position, state.get("target", player_position), Color(color, 0.25), 1.0)
		draw_string(ThemeDB.fallback_font, player_position + Vector2(-22.0, -27.0), "P%d" % peer_id, HORIZONTAL_ALIGNMENT_CENTER, 44.0, 14, Color.WHITE)

	if _session_active:
		draw_string(ThemeDB.fallback_font, Vector2(38.0, 38.0), "ARESTA // PROVA ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("eaf2f7"))
		draw_string(ThemeDB.fallback_font, Vector2(38.0, 66.0), _status, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("a9bbc7"))
		draw_string(ThemeDB.fallback_font, Vector2(670.0, 38.0), "Botao direito: mover   Q W E R: habilidades   Esc: sair", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("d6e0e5"))
		if _feedback_time > 0.0:
			draw_string(ThemeDB.fallback_font, Vector2(500.0, 710.0), _feedback, HORIZONTAL_ALIGNMENT_CENTER, 280.0, 18, Color("ffcc66"))


func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Interface"
	add_child(layer)
	_menu = PanelContainer.new()
	_menu.name = "SessionMenu"
	_menu.position = Vector2(410.0, 165.0)
	_menu.size = Vector2(460.0, 486.0)
	layer.add_child(_menu)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	_menu.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)

	var title := Label.new()
	title.text = "PROVA DE COOPERATIVO ONLINE"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)

	var description := Label.new()
	description.text = "O host cria e simula o mundo. Outros jogadores entram pelo endereco IP."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)

	_address_input = LineEdit.new()
	_address_input.name = "Address"
	_address_input.placeholder_text = "Endereco do host"
	_address_input.text = "127.0.0.1"
	column.add_child(_address_input)

	_port_input = SpinBox.new()
	_port_input.name = "Port"
	_port_input.min_value = 1024
	_port_input.max_value = 65535
	_port_input.value = DEFAULT_PORT
	_port_input.prefix = "Porta: "
	column.add_child(_port_input)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	column.add_child(buttons)
	_host_button = Button.new()
	_host_button.name = "Host"
	_host_button.text = "Hospedar"
	_host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host_button.pressed.connect(_host_session)
	buttons.add_child(_host_button)
	_join_button = Button.new()
	_join_button.name = "Join"
	_join_button.text = "Conectar"
	_join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_join_button.pressed.connect(_join_session)
	buttons.add_child(_join_button)
	var build_lab_button := Button.new()
	build_lab_button.name = "BuildLab"
	build_lab_button.text = "Laboratório de Build"
	build_lab_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/prototype/build_lab/build_lab.tscn")
	)
	column.add_child(build_lab_button)
	var village_button := Button.new()
	village_button.name = "VillageExploration"
	village_button.text = "Explorar Aresta"
	village_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/prototype/village/village_exploration.tscn")
	)
	column.add_child(village_button)
	var village_online := HBoxContainer.new()
	village_online.add_theme_constant_override("separation", 10)
	column.add_child(village_online)
	for spec: Array in [["VillageHost", "Aresta co-op: hospedar", &"host"], ["VillageJoin", "Aresta co-op: entrar", &"client"]]:
		var online_button := Button.new()
		online_button.name = spec[0]
		online_button.text = spec[1]
		online_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var session_mode: StringName = spec[2]
		online_button.pressed.connect(func() -> void:
			SessionLaunch.request(session_mode, _address_input.text.strip_edges(), int(_port_input.value))
			get_tree().change_scene_to_file("res://src/prototype/village/village_exploration.tscn")
		)
		village_online.add_child(online_button)
	var npc_button := Button.new()
	npc_button.name = "VillagersAi"
	npc_button.text = "Moradores: modo padrao ou com IA"
	npc_button.pressed.connect(func() -> void:
		var panel := find_child("NpcAiPanel", true, false) as Control
		if panel == null:
			var panel_layer := CanvasLayer.new()
			panel_layer.layer = 5
			add_child(panel_layer)
			panel = (load("res://src/game/npc_ai_panel.gd") as GDScript).new() as Control
			panel.position = Vector2(380.0, 120.0)
			panel_layer.add_child(panel)
		else:
			panel.visible = not panel.visible
	)
	column.add_child(npc_button)
	if DevModeScript.enabled():
		var tools_button := Button.new()
		tools_button.name = "DeveloperTools"
		tools_button.text = "Central de Conteudo"
		tools_button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://src/prototype/dev_tools/content_editor.tscn")
		)
		column.add_child(tools_button)

	if DevModeScript.can_toggle():
		var dev_toggle := Button.new()
		dev_toggle.name = "DevModeToggle"
		dev_toggle.text = "Modo dev: LIGADO  (desligar abre o jogo como para o público)"
		dev_toggle.pressed.connect(func() -> void:
			DevModeScript.set_enabled(false)
			get_tree().change_scene_to_file(DevModeScript.PUBLIC_HOME)
		)
		column.add_child(dev_toggle)

	var note := Label.new()
	note.text = "Prova inicial: LAN ou IP direto. A travessia de roteadores entra em outro marco."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color("a9bbc7")
	column.add_child(note)
	_menu_status = Label.new()
	_menu_status.name = "Status"
	_menu_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu_status.modulate = Color("ff9a8f")
	column.add_child(_menu_status)


func _parse_command_line() -> void:
	var args := OS.get_cmdline_user_args()
	var should_host := false
	var client_address := ""
	for arg in args:
		if arg == "--server":
			should_host = true
		elif arg.begins_with("--client="):
			client_address = arg.trim_prefix("--client=")
		elif arg.begins_with("--port="):
			_port_input.value = int(arg.trim_prefix("--port="))
		elif arg.begins_with("--test-duration="):
			_test_duration = float(arg.trim_prefix("--test-duration="))
	if should_host:
		_host_session()
	elif not client_address.is_empty():
		_address_input.text = client_address
		_join_session()


func _host_session() -> void:
	var error := _peer.create_server(int(_port_input.value), MAX_PLAYERS - 1)
	if error != OK:
		_set_menu_error("Nao foi possivel hospedar: %s" % error_string(error))
		return
	multiplayer.multiplayer_peer = _peer
	_session_active = true
	_menu.hide()
	_add_player(1)
	_status = "HOST autoritativo | porta %d | %d jogador(es)" % [int(_port_input.value), _players.size()]
	print("NETWORK_HOST_READY port=%d" % int(_port_input.value))


func _join_session() -> void:
	var address := _address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var error := _peer.create_client(address, int(_port_input.value))
	if error != OK:
		_set_menu_error("Nao foi possivel conectar: %s" % error_string(error))
		return
	multiplayer.multiplayer_peer = _peer
	_host_button.disabled = true
	_join_button.disabled = true
	_status = "Conectando a %s:%d..." % [address, int(_port_input.value)]
	print("NETWORK_CLIENT_CONNECTING address=%s port=%d" % [address, int(_port_input.value)])


func _leave_session() -> void:
	_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_players.clear()
	_enemies.clear()
	_session_active = false
	_menu.show()
	_host_button.disabled = false
	_join_button.disabled = false
	_status = "Sessao encerrada"


func _on_connected_to_server() -> void:
	_session_active = true
	_menu.hide()
	_status = "CLIENTE %d | host autoritativo" % multiplayer.get_unique_id()
	print("NETWORK_CLIENT_CONNECTED peer=%d" % multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	_leave_session()
	_set_menu_error("Falha ao conectar ao host")
	print("NETWORK_CLIENT_FAILED")


func _on_server_disconnected() -> void:
	_leave_session()
	_set_menu_error("O host encerrou a sessao")
	print("NETWORK_SERVER_DISCONNECTED")


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_add_player(peer_id)
	_status = "HOST autoritativo | porta %d | %d jogador(es)" % [int(_port_input.value), _players.size()]
	receive_snapshot.rpc_id(peer_id, _players, _enemies)
	print("NETWORK_PEER_JOINED peer=%d players=%d" % [peer_id, _players.size()])


func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		_players.erase(peer_id)
		_status = "HOST autoritativo | porta %d | %d jogador(es)" % [int(_port_input.value), _players.size()]
	print("NETWORK_PEER_LEFT peer=%d" % peer_id)


func _add_player(peer_id: int) -> void:
	if _players.has(peer_id):
		return
	var index := _players.size() % PLAYER_COLORS.size()
	var spawn := ARENA.get_center() + Vector2.from_angle(float(index) * TAU / 4.0) * 90.0
	_players[peer_id] = {
		"position": spawn,
		"target": spawn,
		"color": PLAYER_COLORS[index],
		"pulse": 0.0,
		"attack_timer": 0.2 + index * 0.12,
		"cooldowns": [0.0, 0.0, 0.0, 0.0],
	}


func _send_move_target(target: Vector2) -> void:
	if multiplayer.is_server():
		_apply_move_target(multiplayer.get_unique_id(), target)
	else:
		submit_move_target.rpc_id(1, target)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_move_target(target: Vector2) -> void:
	if multiplayer.is_server():
		_apply_move_target(multiplayer.get_remote_sender_id(), target)


func _apply_move_target(peer_id: int, target: Vector2) -> void:
	if _players.has(peer_id):
		var state := _players[peer_id] as Dictionary
		state["target"] = _clamp_to_arena(target)


func _send_skill(slot: int, target: Vector2) -> void:
	if multiplayer.is_server():
		_apply_skill(multiplayer.get_unique_id(), slot, target)
	else:
		submit_skill.rpc_id(1, slot, target)


@rpc("any_peer", "call_remote", "reliable")
func submit_skill(slot: int, target: Vector2) -> void:
	if multiplayer.is_server():
		_apply_skill(multiplayer.get_remote_sender_id(), slot, target)


func _apply_skill(peer_id: int, slot: int, target: Vector2) -> void:
	if not _players.has(peer_id) or slot < 0 or slot >= SKILL_COOLDOWNS.size():
		return
	var state := _players[peer_id] as Dictionary
	var cooldowns := state["cooldowns"] as Array
	if float(cooldowns[slot]) > 0.0:
		return
	cooldowns[slot] = SKILL_COOLDOWNS[slot]
	state["pulse"] = 1.0
	match slot:
		0:
			_damage_enemies(target, 90.0)
		1:
			var origin := state["position"] as Vector2
			state["position"] = _clamp_to_arena(origin + origin.direction_to(target) * 125.0)
			state["target"] = state["position"]
		2:
			_damage_enemies(state["position"], 145.0)
		3:
			_damage_enemies(state["position"], 265.0)
	play_skill.rpc(peer_id, slot)
	play_skill(peer_id, slot)


@rpc("authority", "call_remote", "reliable")
func play_skill(peer_id: int, slot: int) -> void:
	_feedback = "P%d ativou %s" % [peer_id, ["Q", "W", "E", "R"][slot]]
	_feedback_time = 1.1


@rpc("authority", "call_remote", "unreliable_ordered")
func receive_snapshot(players: Dictionary, enemies: Dictionary) -> void:
	if multiplayer.is_server():
		return
	_players = players
	_enemies = enemies
	_status = "CLIENTE %d | %d jogador(es) | host autoritativo" % [multiplayer.get_unique_id(), _players.size()]


func _simulate_players(delta: float) -> void:
	for state_value: Variant in _players.values():
		var state := state_value as Dictionary
		var position := state["position"] as Vector2
		var target := state["target"] as Vector2
		state["position"] = position.move_toward(target, PLAYER_SPEED * delta)
		state["pulse"] = maxf(0.0, float(state["pulse"]) - delta * 2.6)
		var cooldowns := state["cooldowns"] as Array
		for slot in cooldowns.size():
			cooldowns[slot] = maxf(0.0, float(cooldowns[slot]) - delta)


func _simulate_enemies(delta: float) -> void:
	if _players.is_empty():
		return
	for enemy_value: Variant in _enemies.values():
		var enemy := enemy_value as Dictionary
		var position := enemy["position"] as Vector2
		var closest := _closest_player_position(position)
		enemy["position"] = position.move_toward(closest, ENEMY_SPEED * delta)


func _simulate_auto_attacks(delta: float) -> void:
	for state_value: Variant in _players.values():
		var state := state_value as Dictionary
		state["attack_timer"] = float(state["attack_timer"]) - delta
		if float(state["attack_timer"]) > 0.0:
			continue
		state["attack_timer"] = 0.72
		var enemy_id := _closest_enemy_in_range(state["position"], AUTO_ATTACK_RANGE)
		if enemy_id >= 0:
			_enemies.erase(enemy_id)
			state["pulse"] = 0.45


func _spawn_enemy() -> void:
	var side := _next_enemy_id % 4
	var ratio := fmod(float(_next_enemy_id) * 0.37, 1.0)
	var position := Vector2.ZERO
	match side:
		0: position = Vector2(ARENA.position.x, lerpf(ARENA.position.y, ARENA.end.y, ratio))
		1: position = Vector2(ARENA.end.x, lerpf(ARENA.position.y, ARENA.end.y, ratio))
		2: position = Vector2(lerpf(ARENA.position.x, ARENA.end.x, ratio), ARENA.position.y)
		3: position = Vector2(lerpf(ARENA.position.x, ARENA.end.x, ratio), ARENA.end.y)
	_enemies[_next_enemy_id] = {"position": position}
	_next_enemy_id += 1


func _damage_enemies(center: Vector2, radius: float) -> void:
	var defeated: Array[int] = []
	for id_value: Variant in _enemies.keys():
		var enemy := _enemies[id_value] as Dictionary
		if center.distance_to(enemy["position"]) <= radius:
			defeated.append(int(id_value))
	for enemy_id in defeated:
		_enemies.erase(enemy_id)


func _closest_player_position(origin: Vector2) -> Vector2:
	var closest := origin
	var distance := INF
	for state_value: Variant in _players.values():
		var candidate := (state_value as Dictionary)["position"] as Vector2
		var candidate_distance := origin.distance_squared_to(candidate)
		if candidate_distance < distance:
			distance = candidate_distance
			closest = candidate
	return closest


func _closest_enemy_in_range(origin: Vector2, maximum_range: float) -> int:
	var closest_id := -1
	var distance := maximum_range * maximum_range
	for id_value: Variant in _enemies.keys():
		var candidate := (_enemies[id_value] as Dictionary)["position"] as Vector2
		var candidate_distance := origin.distance_squared_to(candidate)
		if candidate_distance < distance:
			distance = candidate_distance
			closest_id = int(id_value)
	return closest_id


func _skill_slot_for_key(keycode: Key) -> int:
	match keycode:
		KEY_Q: return 0
		KEY_W: return 1
		KEY_E: return 2
		KEY_R: return 3
		_: return -1


func _clamp_to_arena(point: Vector2) -> Vector2:
	return Vector2(
		clampf(point.x, ARENA.position.x + 18.0, ARENA.end.x - 18.0),
		clampf(point.y, ARENA.position.y + 18.0, ARENA.end.y - 18.0)
	)


func _set_menu_error(message: String) -> void:
	_status = message
	_menu_status.text = message
	_feedback = message
	_feedback_time = 4.0
	_host_button.disabled = false
	_join_button.disabled = false
