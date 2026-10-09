extends Node2D

## Apresentação e sessão de Aresta. Solo e host executam WorldSimulation; clientes enviam
## intenções e desenham snapshots do host (ADR 0004 e 0018).

const CombatHudScript := preload("res://src/prototype/village/combat_hud.gd")
const PlayerMenuScript := preload("res://src/prototype/village/player_menu.gd")
const MilestoneChoiceScript := preload("res://src/prototype/village/milestone_choice.gd")
const SpriteLibraryScript := preload("res://src/presentation/art/sprite_library.gd")
const VfxLayerScript := preload("res://src/presentation/vfx/vfx_layer.gd")
const SkillThemesScript := preload("res://src/presentation/vfx/skill_themes.gd")
const CombatAudioScript := preload("res://src/presentation/audio/combat_audio.gd")
const DevModeScript := preload("res://src/core/app/dev_mode.gd")
const SettingsDialogScript := preload("res://src/game/settings_dialog.gd")
const BindingsScript := preload("res://src/core/app/input_bindings.gd")
const SettingsScript := preload("res://src/core/app/game_settings.gd")
const JsonStoreScript := preload("res://src/core/persistence/json_store.gd")
const SaveSchemaScript := preload("res://src/core/persistence/world_save_schema.gd")
const SimulationScript := preload("res://src/gameplay/world/world_simulation.gd")
const LayoutScript := preload("res://src/gameplay/world/world_layout.gd")
const SessionLaunchScript := preload("res://src/core/net/session_launch.gd")
const ProfileIdentityScript := preload("res://src/core/net/profile_identity.gd")
const TowerContentScript := preload("res://src/gameplay/world/tower_content.gd")
const FloorLayoutScript := preload("res://src/gameplay/world/floor_layout.gd")
const TelegraphScript := preload("res://src/gameplay/encounters/telegraph.gd")
const RECORDS_PATH := "user://aresta_floor_records.json"
const NpcAiConfigScript := preload("res://src/core/ai/npc_ai_config.gd")
const NpcModelClientScript := preload("res://src/core/ai/npc_model_client.gd")
const PERIOD_AMBIENT := {
	"manha": Color(1.0, 0.97, 0.9), "tarde": Color(1.0, 0.93, 0.82),
	"entardecer": Color(0.95, 0.72, 0.58), "noite": Color(0.42, 0.47, 0.72),
}
const PERIOD_NAMES := {"manha": "MANHA", "tarde": "TARDE", "entardecer": "ENTARDECER", "noite": "NOITE"}

const SAVE_PATH := SaveSlot.DEFAULT_PATH
## Salvamento automático (decisão 582): a cada minuto, ao entrar ou sair da Torre, ao trocar de
## andar e ao fechar a janela. Desligado em cliente de co-op e em execução sem janela (testes),
## salvo quando um teste liga `autosave_forced`.
const AUTOSAVE_INTERVAL := 60.0
var autosave_forced := false
var _autosave_timer := 0.0
var _autosave_key := ""
var _autosave_flash := 0.0
var _autosave_label: Label
const SNAPSHOT_INTERVAL := 0.05
const SNAPSHOT_MAX_BYTES := 1 << 20
const PLAYER_RADIUS := 14.0
const PLAYER_COLORS: Array[Color] = [Color("e8b84a"), Color("7fd6e0"), Color("93a75a"), Color("d9824a")]
const CHARACTER_IDS: Array[String] = ["eloa", "sena", "cira", "rui"]

var _sim: RefCounted
var _mode: StringName = &"solo"
var _local_peer := 1
var _view: Dictionary = {}
var _display: Dictionary = {}
var _snapshot_timer := 0.0
var _status := "Explore Aresta e entre na casa de teto vermelho."
var _anim_time := 0.0
var _locomotion := preload("res://src/presentation/art/actor_locomotion.gd").new()
var _road_edges: Array[PackedVector2Array] = []
var _road_edge_mesh: ArrayMesh
var _last_zone: StringName = &""
var _last_gem_key := ""
var _session_port := SessionLaunchScript.DEFAULT_PORT
var _test_duration := 0.0
var _test_elapsed := 0.0
var _autopilot := false
var _autopilot_timer := 0.0
var _autopilot_casts := 0
var _requested_character := ""
var _peak_characters: Array[String] = []
var _session_address := "127.0.0.1"
var _reconnect_at := -1.0
var _reconnecting := false
var _reconnections := 0
var _first_character := ""
var _floor_number := 0
var _floor_layout: Dictionary = {}
var _light_texture: Texture2D
var _floor_label: Label
var _boss_bar: Control
var _start_floor_arg := 0
var _agent_model: Dictionary = {}
var _agent_build_timer := 1.0
var _agent_choices: Array[String] = []
var _npc_client: Node
var _npc_settings: Dictionary = {}
var _village_lights: Node2D
var _talk_hint: Label
var _service_menu: Control
var _shop_menu: Control
## Último modelo de menu recebido (a loja abre com ele).
var _menu_model: Dictionary = {}
var _narrative_menu: Control
var _objective_label: Label
var _village_log_label: Label
var _interface_layer: CanvasLayer
var _top_bar: Panel
var _settings_dialog: ConfirmationDialog

var _camera: Camera2D
var _ambient: CanvasModulate
var _player_light: PointLight2D
var _tower_lights: Node2D
var _vfx: Node2D
var _audio: Node2D
var _location_label: Label
var _status_label: Label
var _session_label: Label
var _combat_label: Label
var _combat_hud: Control
var _player_menu: Control
var _milestone_choice: Control
var _character_panel: Control
var _character_cards: Dictionary = {}
var _character_hint: Label
var _pad_aim := Vector2.RIGHT
var _trigger_held: Dictionary = {}
var _pad_was_moving := false
## Ataque normal no clique: segurar o botão (ou a tecla) renova o pedido a cada ATTACK_RESEND s.
const ATTACK_RESEND := 0.1
var _attack_held := false
var _attack_send_timer := 0.0
## A preferência de ataque automático vai ao host sempre que a personagem entra na Torre.
var _auto_attack_synced := false


func _ready() -> void:
	BindingsScript.ensure()
	Input.joy_connection_changed.connect(_on_pad_connection_changed)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_ambient = CanvasModulate.new()
	_ambient.name = "Ambient"
	add_child(_ambient)
	_build_lights()
	var vfx_canvas := CanvasLayer.new()
	vfx_canvas.name = "VfxCanvas"
	vfx_canvas.layer = 1
	vfx_canvas.follow_viewport_enabled = true
	add_child(vfx_canvas)
	_vfx = VfxLayerScript.new() as Node2D
	_vfx.name = "Vfx"
	vfx_canvas.add_child(_vfx)
	_audio = CombatAudioScript.new() as Node2D
	_audio.name = "CombatAudio"
	add_child(_audio)
	_vfx.set("audio", _audio)
	_build_road_edges()
	_camera = Camera2D.new()
	_camera.name = "PlayerCamera"
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	add_child(_camera)
	_parse_test_arguments()
	_build_interface()
	get_viewport().size_changed.connect(_layout_interface)
	_layout_interface.call_deferred()
	_start_session(SessionLaunchScript.consume())
	queue_redraw()


func _parse_test_arguments() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test-duration="):
			_test_duration = float(arg.trim_prefix("--test-duration="))
		elif arg == "--autopilot":
			_autopilot = true
		elif arg.begins_with("--character="):
			_requested_character = arg.trim_prefix("--character=")
		elif arg.begins_with("--start-floor="):
			_start_floor_arg = int(arg.trim_prefix("--start-floor="))
		elif arg.begins_with("--reconnect-at="):
			_reconnect_at = float(arg.trim_prefix("--reconnect-at="))


# ---------------------------------------------------------------- sessão

func _start_session(session: Dictionary) -> void:
	_mode = session.get("mode", &"solo") as StringName
	_session_port = int(session.get("port", SessionLaunchScript.DEFAULT_PORT))
	match _mode:
		&"host":
			var peer := ENetMultiplayerPeer.new()
			var error := peer.create_server(_session_port, SimulationScript.MAX_PLAYERS - 1)
			if error != OK:
				_status = "Nao foi possivel hospedar na porta %d: %s. Jogando sozinho." % [_session_port, error_string(error)]
				_mode = &"solo"
				_start_authority()
				return
			multiplayer.multiplayer_peer = peer
			multiplayer.peer_connected.connect(_on_peer_connected)
			multiplayer.peer_disconnected.connect(_on_peer_disconnected)
			_start_authority()
			print("VILLAGE_HOST_READY port=%d" % _session_port)
		&"client":
			_session_address = String(session.get("address", "127.0.0.1"))
			multiplayer.connected_to_server.connect(_on_connected_to_server)
			multiplayer.connection_failed.connect(_on_connection_lost.bind("Falha ao conectar ao host."))
			multiplayer.server_disconnected.connect(_on_connection_lost.bind("O host encerrou a sessao."))
			_show_character_panel(false)
			_connect_client()
		_:
			_start_authority()
	if _mode != &"client" and bool(session.get("resume", false)) and SaveSlot.exists():
		if _load_world():
			_show_character_panel(false)
			_status = "Jogo continuado do ultimo salvamento."


func _connect_client() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(_session_address, _session_port)
	if error != OK:
		_status = "Nao foi possivel conectar: %s" % error_string(error)
		return
	multiplayer.multiplayer_peer = peer
	_status = "Conectando a %s:%d..." % [_session_address, _session_port]


## Teste de reconexão: fecha a conexão e abre outra com o mesmo perfil.
func _reconnect_client() -> void:
	_reconnecting = true
	multiplayer.multiplayer_peer.close()
	_view = {}
	_connect_client()


## Modo dos moradores: padrão (Utility AI) ou com IA (modelo configurado). Só o host decide.
func _setup_npc_ai() -> void:
	_npc_settings = NpcAiConfigScript.load_settings()
	(_sim.get("village_life") as RefCounted).set("mode", String(_npc_settings["mode"]))
	_npc_client = NpcModelClientScript.new()
	_npc_client.name = "NpcModelClient"
	add_child(_npc_client)
	_npc_client.call("configure", _npc_settings)
	_npc_client.connect("answered", func(request_id: int, action_id: String, speech: String) -> void:
		_sim.call("resolve_npc_request", request_id, action_id, speech))
	_npc_client.connect("failed", func(_request_id: int, reason: String) -> void:
		print("NPC_AI_FAILED %s" % reason))


func _toggle_npc_mode() -> void:
	if _sim == null:
		_status = "Somente o host escolhe o modo dos moradores."
		return
	var pending := _npc_settings.duplicate()
	pending["mode"] = "padrao" if String(pending.get("mode", "padrao")) == "ia" else "ia"
	var error := NpcAiConfigScript.save_settings(pending)
	if error != OK:
		_status = "Falha ao salvar modo dos moradores (%d). Modo anterior mantido." % error
		return
	_npc_settings = pending
	(_sim.get("village_life") as RefCounted).set("mode", String(_npc_settings["mode"]))
	_status = "Moradores no modo %s (%s %s)." % ["COM IA" if _npc_settings["mode"] == "ia" else "PADRAO", _npc_settings["provider"], _npc_settings["model"]]


func _load_records() -> Dictionary:
	var result := JsonStoreScript.read(RECORDS_PATH, SaveSchemaScript.validate_records)
	if result["recovered"]:
		_status = "Recordes recuperados do backup."
	elif result["error"] not in [OK, ERR_FILE_NOT_FOUND]:
		_status = "Falha ao carregar recordes. Arquivos preservados."
	return result["data"]


func _save_records() -> void:
	if JsonStoreScript.write(RECORDS_PATH, _sim.get("records"), SaveSchemaScript.validate_records) != OK:
		_status = "Falha ao salvar recordes. O arquivo anterior foi preservado."


func _start_authority() -> void:
	_sim = SimulationScript.new()
	_sim.call("setup", 7301)
	_local_peer = multiplayer.get_unique_id()
	_sim.call("add_player", _local_peer, StringName(_requested_character))
	_sim.set("records", _load_records())
	_setup_npc_ai()
	if _start_floor_arg > 0:
		_sim.set("deepest_floor", maxi(int(_sim.get("deepest_floor")), _start_floor_arg))
		_sim.set("tower_start_floor", _start_floor_arg)
	if "--inside" in OS.get_cmdline_user_args():
		_sim.call("enter_house", _local_peer)
	elif "--tower" in OS.get_cmdline_user_args():
		_sim.call("enter_tower", _local_peer)
	_view = _sim.call("view_snapshot")
	_apply_events(_sim.call("drain_events") as Array)


## O peer só vira jogador depois do "hello" com o perfil: assim o host distingue entrada nova de reconexão.
func _on_peer_connected(_peer_id: int) -> void:
	pass


func _on_peer_disconnected(peer_id: int) -> void:
	_sim.call("disconnect_player", peer_id)


func _admit_peer(peer_id: int, profile_id: String, character_id: String) -> void:
	if (_sim.get("players") as Dictionary).has(peer_id):
		return
	var reconnected := bool(_sim.call("reconnect_player", profile_id, peer_id))
	if reconnected:
		print("VILLAGE_PEER_RECONNECTED peer=%d profile=%s" % [peer_id, profile_id])
	elif not bool(_sim.call("add_player", peer_id, StringName(character_id) if character_id in CHARACTER_IDS else &"", profile_id)):
		(multiplayer.multiplayer_peer as ENetMultiplayerPeer).disconnect_peer(peer_id)
		return
	else:
		print("VILLAGE_PEER_JOINED peer=%d players=%d" % [peer_id, (_sim.get("players") as Dictionary).size()])
	_send_snapshot(peer_id)


func _on_connected_to_server() -> void:
	_local_peer = multiplayer.get_unique_id()
	_status = "Conectado ao host. Aguardando o mundo..."
	submit_intent.rpc_id(1, "hello", [ProfileIdentityScript.id(), _requested_character])
	if _reconnecting:
		_reconnecting = false
		_reconnections += 1
		print("VILLAGE_CLIENT_RECONNECTED peer=%d" % _local_peer)
		return
	print("VILLAGE_CLIENT_CONNECTED peer=%d" % _local_peer)
	if _requested_character.is_empty() and "--skip-character-select" not in OS.get_cmdline_user_args() and _test_duration <= 0.0:
		_show_character_panel(true)


func _on_connection_lost(message: String) -> void:
	if _reconnecting:
		return
	_status = message
	print("VILLAGE_CLIENT_LOST %s" % message)
	if _test_duration > 0.0:
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_file(DevModeScript.home_scene())


func _leave_session() -> void:
	if _sim != null and _mode != &"client":
		if not _save_world():
			return
	if multiplayer.multiplayer_peer != null and not multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_file(DevModeScript.home_scene())


# ---------------------------------------------------------------- rede

@rpc("any_peer", "call_remote", "unreliable_ordered")
func submit_move(target: Variant) -> void:
	if _sim == null or not target is Vector2:
		return
	_sim.call("set_move_target", multiplayer.get_remote_sender_id(), target)


@rpc("any_peer", "call_remote", "reliable")
func submit_intent(kind: Variant, args: Variant) -> void:
	if _sim == null or not kind is String or not args is Array:
		return
	_apply_intent(multiplayer.get_remote_sender_id(), kind, args)


## Snapshot serializado e comprimido com zstd (cerca de 20× menor com hordas; ADR 0018).
@rpc("authority", "call_remote", "unreliable_ordered")
func receive_snapshot(packed: PackedByteArray, raw_size: int) -> void:
	if raw_size <= 0 or raw_size > SNAPSHOT_MAX_BYTES:
		return
	var decoded: Variant = bytes_to_var(packed.decompress(raw_size, FileAccess.COMPRESSION_ZSTD))
	if decoded is Dictionary:
		_view = decoded


func _send_snapshot(peer_id: int = 0) -> void:
	var raw := var_to_bytes(_view)
	var packed := raw.compress(FileAccess.COMPRESSION_ZSTD)
	if peer_id == 0:
		receive_snapshot.rpc(packed, raw.size())
	else:
		receive_snapshot.rpc_id(peer_id, packed, raw.size())


@rpc("authority", "call_remote", "reliable")
func receive_events(events: Array) -> void:
	_apply_events(events)


@rpc("authority", "call_remote", "reliable")
func receive_menu_model(model: Dictionary) -> void:
	_agent_model = model
	_refresh_menus(model)


func _send_move(target: Vector2) -> void:
	if _sim != null:
		_sim.call("set_move_target", _local_peer, target)
	elif _is_connected():
		submit_move.rpc_id(1, target)


func _send_intent(kind: String, args: Array) -> void:
	if _sim != null:
		_apply_intent(_local_peer, kind, args)
	elif _is_connected():
		submit_intent.rpc_id(1, kind, args)


func _is_connected() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Valida tipos vindos da rede antes de qualquer chamada à simulação.
func _apply_intent(peer_id: int, kind: String, args: Array) -> void:
	if kind == "hello":
		if peer_id != _local_peer and args.size() == 2 and args[0] is String and args[1] is String and String(args[0]).length() <= 64:
			_admit_peer(peer_id, String(args[0]), String(args[1]))
		return
	if not bool(_sim.call("is_connected_player", peer_id)):
		return
	if bool(_sim.call("is_milestone_paused")) and kind not in ["milestone", "menu"]:
		return
	var refresh_menu := true
	match kind:
		"skill":
			if args.size() == 2 and args[0] is int and args[1] is Vector2 and int(args[0]) >= 0 and int(args[0]) < 4:
				_sim.call("use_skill", peer_id, int(args[0]), args[1])
			refresh_menu = false
		"quick":
			_sim.call("use_quick_item", peer_id)
			refresh_menu = false
		"attack":
			if args.size() == 1 and args[0] is Vector2:
				_sim.call("request_attack", peer_id, args[0])
			refresh_menu = false
		"auto_attack":
			if args.size() == 1 and args[0] is bool:
				_sim.call("set_auto_attack", peer_id, bool(args[0]))
			refresh_menu = false
		"character":
			if args.size() == 1 and args[0] is String and String(args[0]) in CHARACTER_IDS:
				_sim.call("select_character", peer_id, StringName(String(args[0])))
		"stat":
			if args.size() == 1 and args[0] is String:
				_sim.call("allocate_stat", peer_id, StringName(String(args[0])))
		"milestone":
			if args.size() == 1 and args[0] is String:
				_sim.call("choose_milestone", peer_id, StringName(String(args[0])))
		"equip":
			if args.size() == 1 and args[0] is String:
				_sim.call("equip_item", peer_id, StringName(String(args[0])))
		"unequip":
			if args.size() == 2 and args[0] is int and args[1] is int:
				_sim.call("unequip_item", peer_id, int(args[0]), int(args[1]))
		"sell":
			if args.size() == 1 and args[0] is String:
				_sim.call("sell_item", peer_id, StringName(String(args[0])))
		"sell_all":
			_sim.call("sell_all", peer_id)
		"reset_stats":
			_sim.call("reset_stats", peer_id)
		"shop_buy":
			if args.size() == 1 and args[0] is int:
				_sim.call("buy_shop_item", peer_id, int(args[0]))
		"shop_reroll":
			_sim.call("reroll_shop", peer_id)
		"loot_filter":
			if args.size() == 1 and args[0] is String:
				_sim.call("set_loot_filter", peer_id, String(args[0]))
		"auto_sell":
			if args.size() == 1 and args[0] is String:
				_sim.call("set_auto_sell", peer_id, String(args[0]))
		"gem_slot":
			if args.size() == 2 and args[0] is int and args[1] is String:
				_sim.call("set_gem_slot", peer_id, int(args[0]), String(args[1]))
		"support_add":
			if args.size() == 2 and args[0] is int and args[1] is String:
				_sim.call("attach_support", peer_id, int(args[0]), String(args[1]))
		"support_remove":
			if args.size() == 2 and args[0] is int and args[1] is String:
				_sim.call("detach_support", peer_id, int(args[0]), String(args[1]))
		"gem_evolution":
			if args.size() == 2 and args[0] is String and args[1] is String:
				_sim.call("choose_gem_evolution", peer_id, String(args[0]), String(args[1]))
		"talk":
			if args.size() == 1 and args[0] is String and String(args[0]).length() <= 64:
				_sim.call("talk_to_npc", peer_id, String(args[0]))
			refresh_menu = false
		"service":
			if args.size() == 2 and args[0] is String and args[1] is String and String(args[0]).length() <= 64 and String(args[1]).length() <= 64:
				_sim.call("use_village_service", peer_id, String(args[0]), String(args[1]))
		"narrative":
			if args.size() == 1 and args[0] is String and String(args[0]).length() <= 64:
				_sim.call("narrative_action", peer_id, String(args[0]))
		"start_floor":
			if args.size() == 1 and args[0] is int:
				_sim.call("set_start_floor", peer_id, int(args[0]))
		"menu":
			pass
		_:
			return
	if refresh_menu:
		_send_menu_model(peer_id)


func _refresh_menus(model: Dictionary) -> void:
	_menu_model = model
	_player_menu.call("refresh", model)
	if _shop_menu != null:
		_shop_menu.call("refresh", model.get("shop", {}))


func _open_shop() -> void:
	if _menu_model.is_empty() and _sim != null:
		_menu_model = _sim.call("menu_model", _local_peer)
	_shop_menu.call("open", _menu_model.get("shop", {}))


func _send_menu_model(peer_id: int) -> void:
	var model: Dictionary = _sim.call("menu_model", peer_id)
	if peer_id == _local_peer:
		_refresh_menus(model)
	elif _is_connected():
		receive_menu_model.rpc_id(peer_id, model)


func _apply_events(events: Array) -> void:
	var zone := String(_local_zone())
	for event: Variant in events:
		if not event is Dictionary:
			continue
		var entry := event as Dictionary
		match String(entry.get("type", "")):
			"vfx":
				if String(entry.get("zone", "")) == zone and entry.get("args") is Array:
					_vfx.set("theme", String(entry.get("theme", "")))
					_vfx.callv(String(entry.get("call", "")), entry["args"] as Array)
					_vfx.set("theme", "")
			"status":
				if int(entry.get("peer", 0)) in [0, _local_peer]:
					_status = String(entry.get("text", ""))
					if _status == "Folego insuficiente." and _combat_hud != null:
						_combat_hud.call("announce", "FOLEGO INSUFICIENTE", "breath")
						_audio.call("play", "denied")
			"clear_vfx":
				if int(entry.get("peer", 0)) == _local_peer:
					_vfx.call("clear")
			"record":
				if _sim != null:
					_save_records()


# ---------------------------------------------------------------- quadro

func _physics_process(delta: float) -> void:
	if (_view.get("milestone_peers", []) as Array).is_empty():
		_anim_time += delta
	_attack_send_timer = maxf(0.0, _attack_send_timer - delta)
	_gather_keyboard()
	_sync_auto_attack()
	if _sim != null:
		_sim.call("step", delta)
		if _npc_client != null:
			for request: Dictionary in (_sim.get("village_life") as RefCounted).call("drain_requests"):
				_npc_client.call("enqueue", request)
		var events: Array = _sim.call("drain_events")
		_apply_events(events)
		_view = _sim.call("view_snapshot")
		if _mode == &"host" and not multiplayer.get_peers().is_empty():
			if not events.is_empty():
				receive_events.rpc(events)
			_snapshot_timer -= delta
			if _snapshot_timer <= 0.0:
				_snapshot_timer = SNAPSHOT_INTERVAL
				_send_snapshot()
	_update_display(delta)
	_sync_floor()
	_step_autosave(delta)
	_run_test_hooks(delta)
	var local := _local()
	var zone := _local_zone()
	if zone != _last_zone:
		_last_zone = zone
		_update_camera_limits()
	if not local.is_empty():
		_camera.position = _display_position(_local_peer)
		_player_light.position = _camera.position
	for light: Node in _tower_lights.get_children():
		var torch := light as PointLight2D
		torch.energy = 0.8 + 0.12 * sin(_anim_time * 9.0 + torch.position.x) + 0.08 * sin(_anim_time * 23.0 + torch.position.y)
	_update_interface()
	if _narrative_menu != null and _narrative_menu.visible:
		var selected_npc := String(_narrative_menu.get("npc_id"))
		var in_range := false
		for npc: Dictionary in _view.get("npcs", []):
			if String(npc["id"]) == selected_npc and zone == &"village":
				in_range = _display_position(_local_peer).distance_to(npc["position"] as Vector2) <= 110.0
		if not selected_npc.is_empty() and zone != &"village":
			_narrative_menu.call("close")
		else:
			_narrative_menu.call("refresh", _conversation_model(selected_npc), in_range or selected_npc.is_empty())
	if _service_menu != null and _service_menu.visible:
		var service_npc := {}
		for npc: Dictionary in _view.get("npcs", []):
			if String(npc["id"]) == String(_service_menu.get("npc_id")):
				service_npc = npc
		if zone != &"village" or service_npc.is_empty() or _display_position(_local_peer).distance_to(service_npc["position"] as Vector2) > 110:
			_service_menu.call("close")
		else:
			_service_menu.call("refresh", local, _view.get("warehouse", {}), _status, _conversation_model(String(service_npc["id"])))
	_update_milestone_choice()
	queue_redraw()


func _update_milestone_choice() -> void:
	var pending := _view.get("milestone_peers", []) as Array
	if not pending.is_empty():
		_player_menu.call("close")
		_character_panel.hide()
	_vfx.set_process(pending.is_empty())
	_milestone_choice.call("refresh", _local(), pending)


func _gather_keyboard() -> void:
	if _input_blocked():
		return
	if DisplayServer.get_name() != "headless" and not get_window().has_focus():
		return
	var aim := Input.get_vector("aresta_aim_left", "aresta_aim_right", "aresta_aim_up", "aresta_aim_down", 0.25)
	if aim != Vector2.ZERO:
		_pad_aim = aim.normalized()
	if (_attack_held or Input.is_action_pressed("aresta_attack")) and _in_arena(_local_zone()) and _attack_send_timer <= 0.0:
		_send_attack()
	var direction := Input.get_vector("aresta_move_left", "aresta_move_right", "aresta_move_up", "aresta_move_down")
	var local := _local()
	if direction != Vector2.ZERO and not local.is_empty():
		_send_move((local["position"] as Vector2) + direction * 48.0)
		_pad_was_moving = BindingsScript.pad_device >= 0
	elif _pad_was_moving and not local.is_empty():
		_send_move(local["position"] as Vector2)
		_pad_was_moving = false


func _on_pad_connection_changed(device: int, connected: bool) -> void:
	if not connected and BindingsScript.pad_device == device:
		BindingsScript.pad_device = -1
		_pad_was_moving = false
		_trigger_held.erase(device)
		if not _local().is_empty():
			_send_move(_local()["position"] as Vector2)


func _input_blocked() -> bool:
	if _narrative_menu != null and _narrative_menu.visible:
		return true
	return (_service_menu != null and _service_menu.visible) or (_shop_menu != null and _shop_menu.visible) or (_milestone_choice != null and _milestone_choice.visible) or (_player_menu != null and _player_menu.visible) or (_character_panel != null and _character_panel.visible) or (_settings_dialog != null and _settings_dialog.visible)


func _update_display(delta: float) -> void:
	var players := _view.get("players", {}) as Dictionary
	var actor_keys: Array[String] = []
	for peer_id: Variant in players:
		var target := (players[peer_id] as Dictionary)["position"] as Vector2
		if _sim != null or not _display.has(peer_id) or (_display[peer_id] as Vector2).distance_to(target) > 160.0:
			_display[peer_id] = target
		else:
			_display[peer_id] = (_display[peer_id] as Vector2).lerp(target, clampf(delta * 14.0, 0.0, 1.0))
		var state := players[peer_id] as Dictionary
		var key := "player:%s" % peer_id
		actor_keys.append(key)
		_locomotion.update(key, _display[peer_id], bool(state.get("moving", false)), 24.0, String(state.get("character_id", "")) + String(state.get("zone", "")))
	for peer_id: Variant in _display.keys():
		if not players.has(peer_id):
			_display.erase(peer_id)
	for actor: Dictionary in _view.get("npcs", []):
		var key := "npcs:%s" % actor.get("id", "")
		actor_keys.append(key)
		_locomotion.update(key, actor["position"], bool(actor.get("moving", false)), 10.0)
	_locomotion.retain(actor_keys)


func _display_position(peer_id: Variant) -> Vector2:
	if _display.has(peer_id):
		return _display[peer_id] as Vector2
	var state := (_view.get("players", {}) as Dictionary).get(peer_id, {}) as Dictionary
	return state.get("position", LayoutScript.WORLD_SPAWN) as Vector2


func _local() -> Dictionary:
	return (_view.get("players", {}) as Dictionary).get(_local_peer, {}) as Dictionary


func _local_zone() -> StringName:
	return StringName(String(_local().get("zone", "village")))


func _in_arena(zone: StringName) -> bool:
	return zone == &"tower"


## Acompanha o andar do snapshot e gera localmente o mesmo layout do host.
func _sync_floor() -> void:
	var number := int((_view.get("floor", {}) as Dictionary).get("number", 0))
	if number == _floor_number:
		return
	_floor_number = number
	_floor_layout = FloorLayoutScript.generate(number) if number > 0 else {}
	_rebuild_floor_lights()
	_update_camera_limits()


# ---------------------------------------------------------------- entrada

func _input(event: InputEvent) -> void:
	BindingsScript.track(event)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_attack_held = false
	if BindingsScript.pad_device >= 0 and event is InputEventJoypadMotion and event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		var aim := Input.get_vector("aresta_aim_left", "aresta_aim_right", "aresta_aim_up", "aresta_aim_down", 0.25)
		if aim != Vector2.ZERO:
			_pad_aim = aim.normalized()


func _command_event(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_TRIGGER_RIGHT:
		var held: bool = event.axis_value > 0.5
		var was_held := bool(_trigger_held.get(event.device, false))
		_trigger_held[event.device] = held
		return held and not was_held
	return false


func _skill_target() -> Vector2:
	if SettingsScript.auto_aim:
		var target := _nearest_enemy()
		if not target.is_empty():
			return target["position"] as Vector2
	if BindingsScript.pad_device >= 0:
		return _display_position(_local_peer) + _pad_aim * 300.0
	return _screen_to_world(get_viewport().get_mouse_position())


func _nearest_enemy() -> Dictionary:
	var nearest := {}
	var distance := INF
	var position := _display_position(_local_peer)
	for enemy: Dictionary in _view.get("enemies", []) as Array:
		if float(enemy.get("health", 0.0)) <= 0.0 or StringName(String(enemy.get("zone", "tower"))) != _local_zone():
			continue
		var squared := position.distance_squared_to(enemy["position"] as Vector2)
		if squared < distance:
			distance = squared
			nearest = enemy
	return nearest


func _send_attack() -> void:
	_attack_send_timer = ATTACK_RESEND
	_send_intent("attack", [_skill_target()])


func _toggle_auto_attack(path: String = SettingsScript.PATH) -> void:
	var error := SettingsScript.toggle_auto_attack(path)
	_status = "Ataque automático ligado." if SettingsScript.auto_attack else "Ataque automático desligado: ataque com clique esquerdo ou %s." % BindingsScript.label("attack")
	if error != OK:
		_status += " Não foi possível guardar a preferência."
	_auto_attack_synced = false
	_sync_auto_attack()


## Envia a preferência de ataque automático ao entrar na Torre ou ao trocá-la.
func _sync_auto_attack() -> void:
	if not _in_arena(_local_zone()):
		_auto_attack_synced = false
		return
	if not _auto_attack_synced and not _local().is_empty():
		_send_intent("auto_attack", [SettingsScript.auto_attack])
		_auto_attack_synced = true


func _toggle_auto_aim(path: String = SettingsScript.PATH) -> void:
	var error := SettingsScript.toggle_auto_aim(path)
	_status = "Mira automática ligada." if SettingsScript.auto_aim else "Mira automática desligada."
	if error != OK:
		_status += " Não foi possível guardar a preferência."

func _unhandled_input(event: InputEvent) -> void:
	if DisplayServer.get_name() != "headless" and not get_window().has_focus():
		return
	var command := _command_event(event)
	if command and BindingsScript.pressed(event, "auto_aim"):
		_toggle_auto_aim()
		get_viewport().set_input_as_handled()
		return
	if command and BindingsScript.pressed(event, "auto_attack"):
		_toggle_auto_attack()
		get_viewport().set_input_as_handled()
		return
	if _milestone_choice != null and _milestone_choice.visible:
		return
	if command and _narrative_menu != null and _narrative_menu.visible:
		if event.is_action_pressed("ui_cancel") or BindingsScript.pressed(event, "pause"):
			_narrative_menu.call("close")
			get_viewport().set_input_as_handled()
		return
	if command and _service_menu != null and _service_menu.visible:
		if event.is_action_pressed("ui_cancel") or BindingsScript.pressed(event, "pause"):
			_service_menu.call("close")
			get_viewport().set_input_as_handled()
		return
	if command and _shop_menu != null and _shop_menu.visible:
		if event.is_action_pressed("ui_cancel") or BindingsScript.pressed(event, "pause"):
			_shop_menu.call("close")
			get_viewport().set_input_as_handled()
		return
	if command and _player_menu != null and _player_menu.visible:
		if event.is_action_pressed("ui_cancel") or BindingsScript.pressed(event, "pause") or BindingsScript.pressed(event, "inventory") or BindingsScript.pressed(event, "character") or BindingsScript.pressed(event, "skills") or BindingsScript.pressed(event, "tower") or BindingsScript.pressed(event, "bestiary"):
			_player_menu.call("close")
		get_viewport().set_input_as_handled()
		return
	if _input_blocked():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _in_arena(_local_zone()):
		_attack_held = true
		_send_attack()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_send_move(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_send_move(_screen_to_world(event.position))
	elif command:
		var slot := _skill_slot_for_event(event)
		if slot >= 0 and _in_arena(_local_zone()):
			_send_intent("skill", [slot, _skill_target()])
			get_viewport().set_input_as_handled()
		elif BindingsScript.pressed(event, "save"):
			_save_world()
			get_viewport().set_input_as_handled()
		elif BindingsScript.pressed(event, "load"):
			_load_world()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.keycode == KEY_F7 and _sim != null and DevModeScript.enabled():
			var build := _sim.call("character_build", _local_peer) as CharacterBuild
			if build != null:
				_sim.call("add_experience", _local_peer, int(_sim.call("experience_required", build.level)))
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.keycode == KEY_F8 and _sim != null and DevModeScript.enabled():
			_sim.call("unlock_all_gems", _local_peer)
			get_viewport().set_input_as_handled()
		elif BindingsScript.pressed(event, "inventory"):
			_open_player_menu("inventory")
		elif BindingsScript.pressed(event, "character"):
			_open_player_menu("character")
		elif BindingsScript.pressed(event, "skills"):
			_open_player_menu("skills")
		elif BindingsScript.pressed(event, "tower"):
			_open_player_menu("tower")
		elif BindingsScript.pressed(event, "bestiary"):
			_open_player_menu("bestiary")
		elif BindingsScript.pressed(event, "interact") and _local_zone() == &"village":
			var npc := _nearest_npc(110.0)
			if not npc.is_empty():
				var npc_id := String(npc["id"])
				if npc_id == "nara_quiral" or ((_view.get("narrative", {}) as Dictionary).get("conversations", {}) as Dictionary).has(npc_id) and preload("res://src/gameplay/world/village_services.gd").offers(npc_id).is_empty():
					_send_move(_local()["position"] as Vector2)
					_narrative_menu.call("open", _conversation_model(npc_id), true)
				elif not preload("res://src/gameplay/world/village_services.gd").offers(String(npc["id"])).is_empty():
					_send_move(_local()["position"] as Vector2)
					_service_menu.call("open", npc, _local(), _view.get("warehouse", {}), _conversation_model(npc_id))
				else:
					_send_intent("talk", [String(npc["id"])])
		elif BindingsScript.pressed(event, "interact") and _near_narrative_marker():
			_send_intent("narrative", ["inspect"])
		elif BindingsScript.pressed(event, "npc_mode"):
			_toggle_npc_mode()
		elif BindingsScript.pressed(event, "switch_character") and not _in_arena(_local_zone()):
			_show_character_panel(true)
		elif BindingsScript.pressed(event, "quick_item") and _in_arena(_local_zone()):
			_send_intent("quick", [])
		elif BindingsScript.pressed(event, "pause"):
			_open_settings()


func _open_settings() -> void:
	_settings_dialog.call("set_authority", _sim != null)
	_settings_dialog.title = "Pausa - Opções" if _mode == &"solo" else "Opções - Sessão online"
	_settings_dialog.call("open", _mode == &"solo")


func _session_action(action: String) -> void:
	match action:
		"save": _save_world()
		"load": _load_world()
		"npc_mode": _toggle_npc_mode()


func _nearest_npc(radius: float) -> Dictionary:
	var position := _display_position(_local_peer)
	var best := {}
	var best_distance := radius
	for npc: Dictionary in _view.get("npcs", []) as Array:
		var distance := position.distance_to(npc["position"] as Vector2)
		if distance <= best_distance:
			best_distance = distance
			best = npc
	return best


func _skill_slot_for_event(event: InputEvent) -> int:
	for slot in range(4):
		if BindingsScript.pressed(event, "skill_%d" % (slot + 1)):
			return slot
	return -1


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


# ---------------------------------------------------------------- salvamento

func _save_world(path: String = "") -> bool:
	path = SaveSlot.path if path.is_empty() else path
	if _sim == null:
		_status = "Somente o host salva o mundo."
		return false
	var error := JsonStoreScript.write(path, _sim.call("save_data", _local_peer), SimulationScript.validate_save)
	if error != OK:
		_status = "Falha ao salvar o mundo (%d). O arquivo anterior foi preservado." % error
		return false
	_status = "Mundo salvo."
	return true


func _load_world(path: String = "") -> bool:
	path = SaveSlot.path if path.is_empty() else path
	if _sim == null:
		_status = "Somente o host carrega o mundo."
		return false
	var result := JsonStoreScript.read(path, SimulationScript.validate_save)
	if result["error"] != OK:
		if result["error"] == ERR_FILE_NOT_FOUND:
			_status = "Nenhum salvamento encontrado."
		elif result["error"] == ERR_UNAVAILABLE:
			_status = "Save de uma versao mais nova. Atualize o jogo para carregar."
		else:
			_status = "Falha ao carregar save (%d). Arquivos preservados." % result["error"]
		return false
	if not bool(_sim.call("load_data", result["data"], _local_peer)):
		_status = "Salvamento invalido. Arquivos preservados."
		return false
	_vfx.call("clear")
	_view = _sim.call("view_snapshot")
	_apply_events(_sim.call("drain_events") as Array)
	if result["recovered"]:
		_status = "Mundo recuperado do backup; progresso da ultima gravacao pode faltar."
	if _mode == &"host" and not multiplayer.get_peers().is_empty():
		_send_snapshot()
	return true


func autosave_enabled() -> bool:
	if _sim == null or _mode == &"client":
		return false
	return autosave_forced or (DisplayServer.get_name() != "headless" and _test_duration <= 0.0 and not _autopilot)


## Chamado a cada quadro: grava ao trocar de zona ou andar e a cada AUTOSAVE_INTERVAL.
func _step_autosave(delta: float) -> void:
	_autosave_flash = maxf(0.0, _autosave_flash - delta)
	if _autosave_label != null:
		_autosave_label.visible = _autosave_flash > 0.0
		_autosave_label.modulate.a = clampf(_autosave_flash, 0.0, 1.0)
	if not autosave_enabled():
		return
	var local := (_view.get("players", {}) as Dictionary).get(_local_peer, {}) as Dictionary
	var key := "%s:%d" % [local.get("zone", ""), int((_view.get("floor", {}) as Dictionary).get("number", 0))]
	_autosave_timer += delta
	if _autosave_key.is_empty():
		_autosave_key = key
	elif key != _autosave_key or _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_key = key
		autosave()


## Grava sem trocar a mensagem de status do jogador; mostra "Salvo" no canto por 2 s.
func autosave() -> bool:
	var previous := _status
	var saved := _save_world()
	if saved:
		_status = previous
		_autosave_flash = 2.0
	_autosave_timer = 0.0
	return saved


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave_enabled():
		_save_world()


# ---------------------------------------------------------------- testes automatizados

func _run_test_hooks(delta: float) -> void:
	if _autopilot:
		_drive_autopilot(delta)
	if _test_duration <= 0.0:
		return
	if _reconnect_at >= 0.0 and _test_elapsed >= _reconnect_at and _sim == null:
		_reconnect_at = -1.0
		_reconnect_client()
	var players_now := _view.get("players", {}) as Dictionary
	if _first_character.is_empty() and not _local().is_empty():
		_first_character = String(_local()["character_id"])
	if players_now.size() > _peak_characters.size():
		_peak_characters.clear()
		for state: Variant in players_now.values():
			_peak_characters.append(String((state as Dictionary)["character_id"]))
		_peak_characters.sort()
	_test_elapsed += delta
	if _test_elapsed < _test_duration:
		return
	_test_duration = 0.0
	var players := _view.get("players", {}) as Dictionary
	if _sim != null:
		var before: Dictionary = JSON.parse_string(JSON.stringify(_sim.call("save_data", _local_peer)))
		var reloaded: RefCounted = SimulationScript.new()
		reloaded.call("setup", 1)
		reloaded.call("add_player", _local_peer)
		var roundtrip := bool(reloaded.call("load_data", before, _local_peer))
		var after: Dictionary = JSON.parse_string(JSON.stringify(reloaded.call("save_data", _local_peer)))
		var same := roundtrip and JSON.stringify(before["enemies"]) == JSON.stringify(after["enemies"]) and JSON.stringify(before["character_gems"]) == JSON.stringify(after["character_gems"])
		if not same:
			for key: String in ["enemies", "character_gems"]:
				if JSON.stringify(before[key]) != JSON.stringify(after[key]):
					var left := JSON.stringify(before[key])
					var right := JSON.stringify(after[key])
					var at := 0
					while at < mini(left.length(), right.length()) and left[at] == right[at]:
						at += 1
					print("VILLAGE_ROUNDTRIP_DIFF %s at %d: %s | %s" % [key, at, left.substr(maxi(0, at - 80), 160), right.substr(maxi(0, at - 80), 160)])
		print("VILLAGE_HOST_DONE peak_players=%d characters=%s enemies=%d experience=%s save_roundtrip=%s" % [
			_peak_characters.size(), ",".join(_peak_characters), (_view.get("enemies", []) as Array).size(),
			JSON.stringify(_sim.get("character_experience")), "ok" if same else "diverged",
		])
		if multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	else:
		var local := _local()
		print("VILLAGE_CLIENT_DONE peer=%d character=%s zone=%s players=%d enemies=%d casts=%d reconnections=%d first_character=%s" % [
			_local_peer, String(local.get("character_id", "")), String(local.get("zone", "")),
			players.size(), (_view.get("enemies", []) as Array).size(), _autopilot_casts, _reconnections,
			_first_character,
		])
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().quit(0)


## Agente de teste (`--autopilot`): usa só o snapshot e envia as mesmas intenções de um jogador.
## Persegue e contorna o inimigo mais próximo, recua com o dash, usa defesa com Vida baixa,
## bebe o item rápido e volta a Aresta para entregar pedra antes de subir de novo.
const AGENT_DEFENSIVE_GEMS: Array[String] = ["muralha_refeita", "semeadura_vital"]
const AGENT_DASH_GEMS: Array[String] = ["passo_vetorial"]
const AGENT_DELIVERY := 3


func _nearest_drop(position: Vector2, zone: StringName) -> Vector2:
	var best := Vector2(INF, INF)
	for drop: Dictionary in _view.get("drops", []) as Array:
		if StringName(String(drop.get("zone", ""))) != zone:
			continue
		var spot := drop["position"] as Vector2
		if best.x == INF or position.distance_to(spot) < position.distance_to(best):
			best = spot
	return best


func _drive_autopilot(delta: float) -> void:
	var local := _local()
	if local.is_empty() or not bool(local.get("connected", true)):
		return
	_agent_build_timer -= delta
	if _agent_build_timer <= 0.0:
		_agent_build_timer = 1.5
		_agent_manage_build()
	_autopilot_timer -= delta
	if _autopilot_timer > 0.0:
		return
	_autopilot_timer = 0.25
	var zone := StringName(String(local["zone"]))
	var position := local["position"] as Vector2
	if zone == &"village":
		_send_move(LayoutScript.TOWER_DOOR.get_center())
		return
	if zone == &"house":
		_send_move(LayoutScript.INTERIOR_EXIT.get_center())
		return
	if _floor_layout.is_empty():
		return
	var floor_view := _view.get("floor", {}) as Dictionary
	var health_ratio := float(local.get("health", 0.0)) / maxf(1.0, float(local.get("max_health", 1.0)))
	if health_ratio < 0.4 and int(local.get("quick_items", 0)) > 0:
		_send_intent("quick", [])
	var enemies := _view.get("enemies", []) as Array
	# Foge das áreas anunciadas no chão antes de qualquer outra decisão.
	for telegraph: Dictionary in _view.get("telegraphs", []) as Array:
		if TelegraphScript.contains(telegraph, position, 20.0):
			var away := (position - (telegraph["position"] as Vector2)).normalized()
			if String(telegraph.get("shape", "")) == "ring":
				away = -away
			elif String(telegraph.get("shape", "")) == "rect":
				away = Vector2.DOWN.rotated(float(telegraph["angle"]))
			_send_move(position + (away if away != Vector2.ZERO else Vector2.LEFT) * 160.0)
			return
	for peer_id: Variant in _view.get("players", {}) as Dictionary:
		var other := (_view["players"] as Dictionary)[peer_id] as Dictionary
		if int(peer_id) != _local_peer and bool(other.get("downed", false)) and String(other.get("zone", "")) == "tower":
			_send_move(other["position"] as Vector2)
			return
	var boss_floor := String(floor_view.get("kind", "")) == "boss"
	var retreating := not boss_floor and (int(local.get("carried_stone", 0)) >= AGENT_DELIVERY * 2 or (health_ratio < 0.25 and int(local.get("quick_items", 0)) == 0))
	if retreating:
		_send_move((_floor_layout["return_portal"] as Rect2).get_center())
		return
	if bool(floor_view.get("stairs_open", false)) and (boss_floor or enemies.is_empty() or _agent_should_descend()):
		_send_move((_floor_layout["stairs"] as Rect2).get_center())
		return
	var nearest := Vector2(INF, INF)
	for enemy: Dictionary in enemies:
		var spot := enemy["position"] as Vector2
		if nearest.x == INF or position.distance_to(spot) < position.distance_to(nearest):
			nearest = spot
	var loot := _nearest_drop(position, zone)
	if loot.x < INF and position.distance_to(loot) < 260.0 and (nearest.x == INF or position.distance_to(nearest) > 160.0):
		_send_move(loot)
		return
	if nearest.x == INF:
		_agent_roam(position)
		return
	var distance := position.distance_to(nearest)
	if distance > 600.0:
		_send_move(nearest)
		return
	var away := (position - nearest).normalized() if distance > 0.1 else Vector2.LEFT
	var orbit := away.rotated(0.6 if _local_peer % 2 == 0 else -0.6)
	_send_move(nearest + orbit * 130.0)
	var cooldowns := local.get("cooldowns", []) as Array
	var gem_ids := local.get("gem_ids", []) as Array
	for slot in range(mini(cooldowns.size(), gem_ids.size())):
		if float(cooldowns[slot]) > 0.0:
			continue
		var gem_id := String(gem_ids[slot])
		if gem_id.is_empty():
			continue
		if gem_id in AGENT_DASH_GEMS:
			if distance < 80.0:
				_send_intent("skill", [slot, position + away * 140.0])
				_autopilot_casts += 1
				return
		elif gem_id in AGENT_DEFENSIVE_GEMS:
			if health_ratio < 0.7 or distance < 110.0:
				_send_intent("skill", [slot, position])
				_autopilot_casts += 1
				return
		elif distance < 300.0:
			_send_intent("skill", [slot, nearest])
			_autopilot_casts += 1
			return


## Preferência de atributos de cada personagem do agente (a cada terceiro ponto vai para Vitalidade).
const AGENT_STAT_PLAN := {
	"eloa": ["intelligence", "wisdom"], "sena": ["agility", "strength"],
	"cira": ["intelligence", "vitality"], "rui": ["strength", "vitality"],
}
## Ordem de linhas que o agente segue nos marcos, por personagem.
const AGENT_BRANCH_PLAN := {
	"eloa": ["essence", "convergence", "adaptation"], "sena": ["essence", "adaptation", "convergence"],
	"cira": ["adaptation", "essence", "convergence"], "rui": ["essence", "adaptation", "convergence"],
}


## O agente cuida da build como um jogador: distribui pontos, escolhe marcos, encaixa suportes,
## escolhe evoluções de gema (em Aresta) e equipa a melhor peça recolhida. Tudo por intenções.
func _agent_manage_build() -> void:
	var model := _agent_model
	if _sim != null:
		model = _sim.call("menu_model", _local_peer)
	else:
		_send_intent("menu", [])
	if model.is_empty():
		return
	var character := String(_local().get("character_id", "eloa"))
	var milestones := model.get("milestone_choices", []) as Array
	if not milestones.is_empty():
		var level := int(model.get("level", 10))
		var branches := AGENT_BRANCH_PLAN.get(character, ["essence", "adaptation", "convergence"]) as Array
		var wanted := String(branches[(level / 10 - 1) % branches.size()])
		var picked := milestones[0] as Dictionary
		var seen := 0
		for choice: Dictionary in milestones:
			if String(choice.get("branch", "")) == wanted:
				picked = choice
				if seen == (level / 10) % 2:
					break
				seen += 1
		_send_intent("milestone", [String(picked["id"])])
		_agent_note("marco do nivel %d: %s" % [level, String(picked.get("name", ""))])
	var points := int(model.get("unspent_stat_points", 0))
	var plan := AGENT_STAT_PLAN.get(character, ["vitality", "strength"]) as Array
	for index in range(mini(points, 5)):
		var spent := 0
		for value: Variant in (model.get("stats", {}) as Dictionary).values():
			spent += int(value)
		var stat := "vitality" if (spent + index) % 3 == 2 else String(plan[(spent + index) % 2])
		_send_intent("stat", [stat])
	if bool(model.get("in_safe_area", false)):
		var used := {}
		var unslotted: Array[String] = []
		for option: Dictionary in model.get("gem_options", []) as Array:
			if not bool(option.get("equipped", false)):
				unslotted.append(String(option["id"]))
		for skill: Dictionary in model.get("skills", []) as Array:
			var slot := int(skill.get("slot", 0))
			if bool(skill.get("empty", false)):
				if not unslotted.is_empty():
					var gem_id: String = unslotted.pop_front()
					_send_intent("gem_slot", [slot, gem_id])
					_agent_note("gema %s em %s" % [gem_id, String(skill.get("key", ""))])
				continue
			var pending := skill.get("pending_choices", []) as Array
			if not pending.is_empty():
				var option := pending[(int(skill.get("level", 1)) + slot) % pending.size()] as Dictionary
				_send_intent("gem_evolution", [String(skill["id"]), String(option["id"])])
				_agent_note("evolucao de %s: %s" % [String(skill.get("name", "")), String(option.get("name", ""))])
			var free := int(skill.get("capacity", 0)) - int(skill.get("capacity_used", 0))
			if int(skill.get("support_count", 0)) < 2:
				for support: Dictionary in skill.get("available_supports", []) as Array:
					if int(support.get("drain", 1)) <= free and not used.has(String(support["id"])):
						used[String(support["id"])] = true
						_send_intent("support_add", [slot, String(support["id"])])
						_agent_note("suporte %s em %s" % [String(support.get("name", "")), String(skill.get("name", ""))])
						break
	var best_by_slot := {}
	for entry: Dictionary in model.get("equipment_slots", []) as Array:
		var slot_id := int(entry.get("slot_id", -1))
		var current := float(entry.get("score", -1.0))
		if not best_by_slot.has(slot_id) or current < float(best_by_slot[slot_id]):
			best_by_slot[slot_id] = current
	for item: Dictionary in model.get("inventory_equipment", []) as Array:
		var slot_id := int(item.get("slot_id", -1))
		if float(item.get("score", 0.0)) > float(best_by_slot.get(slot_id, -1.0)):
			_send_intent("equip", [String(item["instance_id"])])
			_agent_note("equipou %s (%s, %s)" % [String(item.get("name", "")), String(item.get("tier", "")), String(item.get("fabrication", ""))])
			break


func _agent_note(text: String) -> void:
	_agent_choices.append(text)
	_status = "Agente: " + text
	print("AGENT_CHOICE peer=%d %s" % [_local_peer, text])


## Agentes descem quando a escada abre e já limparam por perto (ou após um tempo no andar).
func _agent_should_descend() -> bool:
	return float((_view.get("floor", {}) as Dictionary).get("time", 0.0)) > 90.0


func _agent_roam(position: Vector2) -> void:
	var points := _floor_layout.get("spawn_points", []) as Array
	if points.is_empty():
		return
	if not _floor_layout.has("agent_goal") or position.distance_to(_floor_layout["agent_goal"] as Vector2) < 60.0:
		_floor_layout["agent_goal"] = points[(_local_peer + _autopilot_casts + int(_anim_time)) % points.size()]
	_send_move(_floor_layout["agent_goal"] as Vector2)


# ---------------------------------------------------------------- desenho

func _draw() -> void:
	var zone := _local_zone()
	_draw_ground(zone)
	var story := _view.get("narrative", {}) as Dictionary
	if zone == &"tower" and story.has("marker_position"):
		var marker := story["marker_position"] as Vector2
		_draw_sprite("props/rocks", marker, false, Color("b7d8d1"))
		draw_arc(marker, 38.0, 0, TAU, 32, Color("e8b84a"), 2.0)
	var arena := StringName(String(_view.get("arena_zone", "tower")))
	var in_arena := zone == arena and _in_arena(zone)
	if _in_arena(zone):
		for drop: Dictionary in _view.get("drops", []) as Array:
			if StringName(String(drop.get("zone", ""))) == zone:
				_draw_drop(drop)
	var visible_rect := _visible_world_rect().grow(220.0)
	if in_arena:
		for zone_view: Dictionary in _view.get("hazard_zones", []) as Array:
			_draw_hazard_zone(zone_view)
		for effect: Dictionary in _view.get("effects", []) as Array:
			if String(effect.get("mechanic", "")) != "summon":
				_draw_ground_effect(effect)
		for telegraph: Dictionary in _view.get("telegraphs", []) as Array:
			_draw_telegraph(telegraph)
	var players := _view.get("players", {}) as Dictionary
	var drawables: Array[Dictionary] = []
	var pieces: Array = (_floor_layout.get("props", []) as Array) if zone == &"tower" else LayoutScript.pieces(zone, int(_view.get("village_progress", 0)))
	for piece: Dictionary in pieces:
		if zone == &"house" or visible_rect.has_point(piece["base"] as Vector2):
			drawables.append({"y": (piece["base"] as Vector2).y, "piece": piece})
	if zone == &"village":
		for npc: Dictionary in _view.get("npcs", []) as Array:
			if visible_rect.has_point(npc["position"] as Vector2):
				drawables.append({"y": (npc["position"] as Vector2).y + 12.0, "npc": npc})
	for peer_id: Variant in players:
		var state := players[peer_id] as Dictionary
		if StringName(String(state["zone"])) != zone:
			continue
		if _in_arena(zone):
			_draw_passive_markers(state.get("passive_markers", []) as Array)
		drawables.append({"y": _display_position(peer_id).y + 12.0, "player": state, "peer": peer_id})
	if in_arena:
		for enemy: Dictionary in _view.get("enemies", []) as Array:
			if visible_rect.has_point(enemy["position"] as Vector2):
				drawables.append({"y": (enemy["position"] as Vector2).y, "enemy": enemy})
		for effect: Dictionary in _view.get("effects", []) as Array:
			if String(effect.get("mechanic", "")) == "summon":
				drawables.append({"y": (effect["position"] as Vector2).y, "summon": effect})
	drawables.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["y"]) < float(right["y"]))
	for drawable in drawables:
		if drawable.has("piece"):
			_draw_piece(drawable["piece"] as Dictionary, zone)
		elif drawable.has("enemy"):
			_draw_enemy(drawable["enemy"] as Dictionary)
		elif drawable.has("summon"):
			_draw_summon(drawable["summon"] as Dictionary)
		elif drawable.has("npc"):
			_draw_npc(drawable["npc"] as Dictionary)
		else:
			_draw_player(drawable["player"] as Dictionary, drawable["peer"])
	if zone == &"village":
		_draw_village_life_overlay(visible_rect)
	if (BindingsScript.pad_device >= 0 or SettingsScript.auto_aim) and in_arena and not _input_blocked():
		var aim_position := _skill_target()
		var selected := SettingsScript.auto_aim and not _nearest_enemy().is_empty()
		var aim_color := Color("e8b84a") if selected else Color("7fd6e0")
		draw_arc(aim_position, 18.0 if selected else 8.0, 0.0, TAU, 24, aim_color, 2.0)
		draw_line(aim_position - Vector2(12.0, 0.0), aim_position + Vector2(12.0, 0.0), aim_color, 1.0)
		draw_line(aim_position - Vector2(0.0, 12.0), aim_position + Vector2(0.0, 12.0), aim_color, 1.0)
	if in_arena:
		for projectile: Dictionary in _view.get("projectiles", []) as Array:
			var position := projectile["position"] as Vector2
			draw_circle(position, 9.0, Color(0.85, 0.51, 0.29, 0.3))
			draw_circle(position, 5.0, Color("e8b84a"))
			draw_line(position, position - (projectile["velocity"] as Vector2).normalized() * 14.0, Color("d9824a"), 3.0)


func _draw_ground(zone: StringName) -> void:
	match zone:
		&"village":
			_draw_tiled("tiles/grass", Rect2(Vector2.ZERO, LayoutScript.WORLD_SIZE), Color("5f7f45"))
			for district: Dictionary in LayoutScript.VillagePlan.DISTRICTS:
				_draw_tiled(String(district["tile"]), district["rect"] as Rect2, Color("8f7a6a"))
			for road in LayoutScript.VILLAGE_ROADS:
				_draw_tiled("tiles/road", road, Color("8f7a6a"))
			if _road_edge_mesh != null:
				draw_mesh(_road_edge_mesh, SpriteLibraryScript.texture("tiles/grass"))
			_draw_door_hint(LayoutScript.HOUSE_DOOR)
			_draw_door_hint(LayoutScript.TOWER_DOOR)
		&"house":
			var room := LayoutScript.HOUSE_ROOM
			draw_rect(Rect2(Vector2.ZERO, LayoutScript.INTERIOR_SIZE), Color("1b1a1f"))
			_draw_tiled("tiles/floor_wood", room, Color("8f7a6a"))
			var wall := Rect2(room.position.x, room.position.y - 70.0, room.size.x, 70.0)
			draw_rect(wall, Color("6b5a5e"))
			for x in range(int(wall.position.x), int(wall.end.x), 32):
				draw_line(Vector2(x, wall.position.y), Vector2(x, wall.end.y), Color("4a3f4f"), 2.0)
			draw_rect(Rect2(wall.position.x, wall.end.y - 8.0, wall.size.x, 8.0), Color("2f2a35"))
			draw_rect(Rect2(wall.position.x + 200.0, wall.position.y + 14.0, 60.0, 36.0), Color("c8f2f0"))
			draw_rect(Rect2(wall.position.x + 200.0, wall.position.y + 14.0, 60.0, 36.0), Color("2f2a35"), false, 4.0)
			draw_rect(room.grow(6.0), Color("2f2a35"), false, 12.0)
			draw_rect(LayoutScript.INTERIOR_EXIT, Color("7a2e2e"))
			draw_rect(LayoutScript.INTERIOR_EXIT.grow(-6.0), Color("b04a3a"), false, 2.0)
			draw_string(ThemeDB.fallback_font, LayoutScript.INTERIOR_EXIT.position + Vector2(0.0, 38.0), "SAIDA", HORIZONTAL_ALIGNMENT_CENTER, LayoutScript.INTERIOR_EXIT.size.x, 15, Color("f2e6c9"))
		&"tower":
			_draw_floor_ground()
		&"boss_room":
			_draw_tiled("tiles/floor_tower", Rect2(Vector2.ZERO, LayoutScript.INTERIOR_SIZE), Color("5c5a5e"))
			_draw_door_hint(LayoutScript.BOSS_ROOM_EXIT)


## Chão do andar: tile do bioma, borda escurecida, arena circular nos andares de chefe,
## portal de retorno (selado durante o chefe) e escada para o próximo andar (fechada até o grupo sobreviver 10 minutos).
func _draw_floor_ground() -> void:
	if _floor_layout.is_empty():
		return
	var size := _floor_layout["size"] as Vector2
	var biome := TowerContentScript.biome(String(_floor_layout.get("biome", "galerias")))
	var floor_view := _view.get("floor", {}) as Dictionary
	var tile_key := String(biome.get("tile", "tiles/floor_tower"))
	if _floor_layout.has("arena_center"):
		var center := _floor_layout["arena_center"] as Vector2
		var radius := float(_floor_layout["arena_radius"])
		draw_rect(Rect2(Vector2.ZERO, size), Color("141218"))
		var texture := SpriteLibraryScript.texture(tile_key)
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for index in range(64):
			var point := center + Vector2.RIGHT.rotated(TAU * float(index) / 64.0) * radius
			points.append(point)
			uvs.append(point / (texture.get_size() if texture != null else Vector2.ONE * 128.0))
		draw_colored_polygon(points, Color.WHITE if texture != null else Color("46434d"), uvs, texture)
		for band in range(4):
			draw_arc(center, radius - 8.0 - float(band) * 14.0, 0.0, TAU, 72, Color(0.07, 0.06, 0.09, 0.28 - 0.06 * float(band)), 10.0)
		draw_arc(center, radius, 0.0, TAU, 96, Color(0.91, 0.72, 0.29, 0.35 + 0.15 * sin(_anim_time * 2.0)), 4.0)
	else:
		_draw_tiled(tile_key, Rect2(Vector2.ZERO, size), Color("5c5a5e"))
		var route := _floor_layout.get("route", []) as Array
		for index in range(route.size() - 1):
			draw_line(route[index], route[index + 1], Color(0.8, 0.83, 0.75, 0.07), 180.0)
		for band in range(5):
			var inset := float(band) * 22.0
			draw_rect(Rect2(Vector2.ONE * inset, size - Vector2.ONE * inset * 2.0), Color(0.07, 0.06, 0.09, 0.25), false, 22.0)
	var portal := _floor_layout["return_portal"] as Rect2
	var sealed := float(floor_view.get("boss_ratio", -1.0)) > 0.0
	_draw_portal(portal, sealed)
	var stairs := _floor_layout["stairs"] as Rect2
	var open := bool(floor_view.get("stairs_open", false))
	if open or not _floor_layout.has("arena_center"):
		_draw_stairs(stairs, open, floor_view)


## Portal de retorno: arco de pedra (PixelForge) com redemoinho animado; vermelho quando selado.
func _draw_portal(portal: Rect2, sealed: bool) -> void:
	var base := Vector2(portal.get_center().x, portal.end.y + 6.0)
	var glow := Color(0.85, 0.25, 0.22) if sealed else Color(0.5, 0.84, 0.88)
	var pulse := 0.5 + 0.5 * sin(_anim_time * 3.0)
	draw_circle(base + Vector2(0.0, -10.0), 46.0, Color(glow, 0.12 + 0.08 * pulse))
	if not _draw_sprite("props/portal_retorno", base, false, Color(1.0, 0.7, 0.7) if sealed else Color.WHITE):
		draw_rect(portal, Color("1b1a1f"))
	var heart := base + Vector2(0.0, -52.0)
	for ring in range(4):
		var radius := 8.0 + float(ring) * 6.0 + pulse * 3.0
		draw_arc(heart, radius, _anim_time * (2.0 + float(ring)), _anim_time * (2.0 + float(ring)) + PI * 1.3, 18, Color(glow, 0.75 - 0.15 * float(ring)), 2.0)
	if sealed:
		for bar in range(3):
			var x := heart.x - 20.0 + float(bar) * 20.0
			draw_line(Vector2(x, heart.y - 30.0), Vector2(x, heart.y + 40.0), Color(0.9, 0.2, 0.18, 0.6 + 0.3 * pulse), 3.0)
	draw_string(ThemeDB.fallback_font, base + Vector2(-80.0, -118.0), "SELADO" if sealed else "VOLTAR A ARESTA", HORIZONTAL_ALIGNMENT_CENTER, 160.0, 12, Color("e8b84a") if not sealed else Color("e87a6a"))


## Escada para o próximo andar: escadaria (PixelForge); fechada, recebe uma barreira de runas vermelhas.
func _draw_stairs(stairs: Rect2, open: bool, floor_view: Dictionary) -> void:
	var base := Vector2(stairs.get_center().x, stairs.end.y + 20.0)
	var pulse := 0.5 + 0.5 * sin(_anim_time * 4.0)
	var glow := Color(0.5, 0.84, 0.88) if open else Color(0.85, 0.25, 0.22)
	draw_circle(stairs.get_center(), 60.0, Color(glow, 0.1 + 0.08 * pulse))
	if not _draw_sprite("props/escada_aberta", base, false, Color.WHITE if open else Color(0.75, 0.6, 0.6)):
		draw_rect(stairs, Color("1b1a1f"))
	var frame := Rect2(base + Vector2(-58.0, -118.0), Vector2(116.0, 108.0))
	if open:
		for spark in range(6):
			var phase := fmod(_anim_time * 0.6 + float(spark) / 6.0, 1.0)
			draw_circle(frame.get_center() + Vector2(sin(float(spark) * 2.1) * 40.0, 30.0 - phase * 70.0), 2.0, Color(glow, 1.0 - phase))
	else:
		draw_rect(frame.grow(-8.0), Color(0.85, 0.2, 0.18, 0.18 + 0.12 * pulse))
		for rune in range(5):
			var spot := frame.position + Vector2(18.0 + float(rune) * 20.0, frame.size.y * 0.5 + sin(_anim_time * 2.0 + float(rune)) * 6.0)
			draw_colored_polygon(PackedVector2Array([spot + Vector2(0.0, -6.0), spot + Vector2(5.0, 0.0), spot + Vector2(0.0, 6.0), spot + Vector2(-5.0, 0.0)]), Color(0.95, 0.35, 0.3, 0.7 + 0.3 * pulse))
		draw_rect(frame.grow(-8.0), Color(0.95, 0.3, 0.25, 0.7), false, 2.0)
	var caption := "DESCER AO ANDAR %d" % mini(_floor_number + 1, TowerContentScript.MAX_FLOOR) if open else "ESCADA SELADA  %d/%d" % [int(floor_view.get("kills", 0)), int(floor_view.get("quota", 0))]
	draw_string(ThemeDB.fallback_font, frame.position + Vector2(-40.0, -10.0), caption, HORIZONTAL_ALIGNMENT_CENTER, frame.size.x + 80.0, 12, Color("c8f2f0") if open else Color("e87a6a"))


## Aviso de área: contorno forte e preenchimento que cresce até o golpe.
func _draw_telegraph(telegraph: Dictionary) -> void:
	var progress := clampf(float(telegraph.get("progress", 0.0)), 0.0, 1.0)
	var hazard := String(telegraph.get("source", "")) == "hazard"
	var edge := Color(0.93, 0.62, 0.25, 0.85) if hazard else Color(0.9, 0.25, 0.22, 0.9)
	var fill := Color(edge, 0.12 + 0.3 * progress)
	var origin := telegraph["position"] as Vector2
	match String(telegraph.get("shape", "circle")):
		"circle":
			var radius := float(telegraph["radius"])
			draw_circle(origin, radius, Color(edge, 0.1))
			draw_circle(origin, radius * progress, fill)
			draw_arc(origin, radius, 0.0, TAU, 48, edge, 2.5)
		"ring":
			var inner := float(telegraph["inner"])
			var radius := float(telegraph["radius"])
			var middle := (inner + radius) * 0.5
			draw_arc(origin, middle, 0.0, TAU, 72, Color(edge, 0.1 + 0.25 * progress), radius - inner)
			draw_arc(origin, inner, 0.0, TAU, 64, edge, 2.5)
			draw_arc(origin, radius, 0.0, TAU, 72, edge, 2.5)
			draw_arc(origin, inner * 0.6, 0.0, TAU, 32, Color(0.5, 0.84, 0.88, 0.5), 2.0)
		"rect":
			var angle := float(telegraph["angle"])
			var length := float(telegraph["length"])
			var half := float(telegraph["width"]) * 0.5
			var forward := Vector2.RIGHT.rotated(angle)
			var side := Vector2.DOWN.rotated(angle) * half
			var outline := PackedVector2Array([origin + side, origin + forward * length + side, origin + forward * length - side, origin - side])
			draw_colored_polygon(outline, Color(edge, 0.1))
			draw_colored_polygon(PackedVector2Array([origin + side, origin + forward * length * progress + side, origin + forward * length * progress - side, origin - side]), fill)
			outline.append(origin + side)
			draw_polyline(outline, edge, 2.5)
	if telegraph.has("label") and progress < 0.4:
		draw_string(ThemeDB.fallback_font, origin + Vector2(-80.0, -float(telegraph.get("radius", 40.0)) - 8.0), String(telegraph["label"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 11, edge)


func _draw_hazard_zone(zone_view: Dictionary) -> void:
	var origin := zone_view["position"] as Vector2
	var radius := float(zone_view["radius"])
	var fade := clampf(float(zone_view.get("remaining", 1.0)), 0.0, 1.0)
	var color := Color(0.5, 0.75, 0.95) if float(zone_view.get("slow", 0.0)) > 0.0 else Color(0.62, 0.85, 0.35)
	draw_circle(origin, radius, Color(color, 0.22 * fade))
	draw_arc(origin, radius * (0.85 + 0.1 * sin(_anim_time * 5.0)), 0.0, TAU, 40, Color(color, 0.6 * fade), 2.0)


func _visible_world_rect() -> Rect2:
	var transform := get_viewport().get_canvas_transform().affine_inverse()
	var viewport := get_viewport_rect().size
	return Rect2(transform * Vector2.ZERO, transform.basis_xform(viewport))


func _draw_tiled(key: String, rect: Rect2, fallback: Color) -> void:
	var texture := SpriteLibraryScript.texture(key)
	if texture == null:
		draw_rect(rect, fallback)
	else:
		draw_texture_rect(texture, rect, true)


func _draw_door_hint(door: Rect2) -> void:
	if door.grow(70.0).has_point(_display_position(_local_peer)):
		var center := Vector2(door.get_center().x, door.end.y + 6.0)
		var pulse := 0.5 + 0.5 * sin(_anim_time * 5.0)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -7.0), center + Vector2(7.0, 0.0),
			center + Vector2(0.0, 7.0), center + Vector2(-7.0, 0.0),
		]), Color(0.91, 0.72, 0.29, 0.5 + 0.5 * pulse))


func _draw_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for index in range(14):
		var angle := TAU * float(index) / 14.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, Color(0.06, 0.05, 0.08, 0.32))


func _draw_sprite(key: String, base: Vector2, flip: bool, tint: Color, lift: float = 0.0) -> bool:
	var texture := SpriteLibraryScript.texture(key)
	if texture == null:
		return false
	var size := texture.get_size()
	draw_set_transform(base.round(), 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	draw_texture(texture, Vector2(-floorf(size.x * 0.5), -size.y - roundf(lift)), tint)
	draw_set_transform(Vector2.ZERO)
	return true


func _draw_piece(piece: Dictionary, zone: StringName) -> void:
	var base := piece["base"] as Vector2
	var scale_factor := float(piece.get("visual_scale", 1.0))
	var rendered := false
	if scale_factor != 1.0:
		var texture := SpriteLibraryScript.texture(String(piece["sprite"]))
		if texture != null:
			var dimensions := texture.get_size() * scale_factor
			draw_texture_rect(texture, Rect2(base - Vector2(dimensions.x * 0.5, dimensions.y), dimensions), false)
			rendered = true
	else:
		rendered = _draw_sprite(String(piece["sprite"]), base, false, Color.WHITE)
	if not rendered and piece.has("solid"):
		var solid := piece["solid"] as Rect2
		draw_rect(Rect2(base + solid.position, solid.size), Color("6b5a5e"))
	if zone == &"tower" and String(piece["sprite"]) == "props/pillar":
		var flame := base - Vector2(0.0, 112.0)
		var flicker := sin(_anim_time * 12.0 + base.x) * 1.5
		draw_circle(flame, 6.0 + flicker * 0.5, Color(0.85, 0.51, 0.29, 0.9))
		draw_circle(flame + Vector2(0.0, -3.0), 3.5 + flicker * 0.3, Color("e8b84a"))
		draw_circle(flame + Vector2(0.0, -5.0), 1.5, Color("f2e6c9"))
	if piece.has("label"):
		draw_string(ThemeDB.fallback_font, base + Vector2(-130.0, 18.0), String(piece["label"]), HORIZONTAL_ALIGNMENT_CENTER, 260.0, 12, Color("f2e6c9"))


func _player_color(peer_id: Variant) -> Color:
	var peers := (_view.get("players", {}) as Dictionary).keys()
	peers.sort()
	return PLAYER_COLORS[maxi(0, peers.find(peer_id)) % PLAYER_COLORS.size()]


## Morador: sprite com passo, nome (nomeados ou perto), balão de fala e reticências enquanto pensa.
func _draw_npc(npc: Dictionary) -> void:
	var position := npc["position"] as Vector2
	var feet := position + Vector2(0.0, 12.0)
	if String((_view.get("narrative", {}) as Dictionary).get("target_npc", "")) == String(npc.get("id", "")):
		draw_arc(feet, 22.0, 0.0, TAU, 24, Color("e8b84a"), 2.0)
	_draw_shadow(feet, Vector2(11.0, 4.0))
	var lift := absf(sin(_anim_time * 12.0 + position.x)) * 2.0 if bool(npc.get("moving", false)) else (sin(_anim_time * 2.0 + position.y) + 1.0) * 0.4
	var frame := SpriteLibraryScript.actor_frame(String(npc.get("sprite", "")), npc.get("facing_direction", Vector2.DOWN) as Vector2, bool(npc.get("moving", false)), _locomotion.elapsed("npcs:%s" % npc.get("id", "")))
	if frame != null:
		draw_texture(frame, (feet - SpriteLibraryScript.CHARACTER_FOOT_ANCHOR).round())
	elif not _draw_sprite(String(npc.get("sprite", "")), feet, bool(npc.get("facing_left", false)), Color.WHITE, lift):
		draw_circle(position, 10.0, Color("d9c2a0"))
	var near := position.distance_to(_display_position(_local_peer)) <= 160.0
	var named := bool(npc.get("named", false))
	var top := feet + Vector2(0.0, -58.0)
	if named or near:
		draw_string(ThemeDB.fallback_font, top + Vector2(-80.0, 0.0), String(npc.get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 11, Color("e8b84a") if named else Color("d9c2a0"))
		if near and named:
			draw_string(ThemeDB.fallback_font, top + Vector2(-80.0, 11.0), String(npc.get("title", "")), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 9, Color("aaa59a"))
	if near and not String(npc.get("resource", "")).is_empty():
		draw_string(ThemeDB.fallback_font, feet + Vector2(-110, 18), String(npc.get("label", "")), HORIZONTAL_ALIGNMENT_CENTER, 220, 10, Color("f2e6c9"))
	if bool(npc.get("thinking", false)) and String(npc.get("speech", "")) in ["", "..."]:
		for dot in range(3):
			draw_circle(top + Vector2(-8.0 + float(dot) * 8.0, -12.0), 2.5 if int(_anim_time * 3.0) % 3 == dot else 1.6, Color("f2e6c9"))
		return
	var speech := String(npc.get("speech", ""))
	if speech.is_empty() or speech == "...":
		return
	var font := ThemeDB.fallback_font
	var width := minf(260.0, font.get_string_size(speech, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 16.0)
	var lines := ceili(font.get_string_size(speech, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x / maxf(1.0, width - 16.0))
	var height := 16.0 * float(lines) + 10.0
	var box := Rect2(top + Vector2(-width * 0.5, -height - 16.0), Vector2(width, height))
	draw_rect(box, Color("f2e6c9f0"))
	draw_rect(box, Color("1b1a1f"), false, 1.5)
	draw_colored_polygon(PackedVector2Array([box.position + Vector2(width * 0.5 - 6.0, height), box.position + Vector2(width * 0.5 + 6.0, height), top + Vector2(0.0, -10.0)]), Color("f2e6c9f0"))
	draw_multiline_string(font, box.position + Vector2(8.0, 16.0), speech, HORIZONTAL_ALIGNMENT_LEFT, width - 16.0, 12, -1, Color("1b1a1f"))


## Vida no ar da vila: fumaça das chaminés, pássaros de dia, vaga-lumes e janelas acesas à noite,
## galinhas ciscando nas plantações.
func _draw_village_life_overlay(visible_rect: Rect2) -> void:
	var warehouse := _view.get("warehouse", {}) as Dictionary
	var warehouse_position := warehouse.get("position", Vector2.ZERO) as Vector2
	if not warehouse.is_empty() and _display_position(_local_peer).distance_to(warehouse_position) < 250:
		var stock := warehouse.get("stock", {}) as Dictionary
		var board := Rect2(warehouse_position + Vector2(-130, 75), Vector2(260, 92))
		draw_rect(board, Color("202923ed"))
		draw_rect(board, Color("829382"), false, 1)
		draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 20), "RESERVAS DA VILA", HORIZONTAL_ALIGNMENT_LEFT, 236, 13, Color("f2e6c9"))
		for index in range(3):
			var resource := ["madeira", "minerio", "alimentos"][index] as String
			draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 39 + index * 19), "%s: %d / %d" % [resource.capitalize(), int(stock.get(resource, 0)), int(warehouse.get("capacity", 0))], HORIZONTAL_ALIGNMENT_LEFT, 236, 12, Color("f2e6c9"))
	var period := String(_view.get("village_period", "manha"))
	var night := period == "noite"
	var dusk := period == "entardecer"
	var chimneys: Array[Vector2] = []
	for building in LayoutScript.VILLAGE_PIECES:
		if String(building["sprite"]).begins_with("buildings/") and String(building["sprite"]) != "buildings/torre":
			chimneys.append((building["base"] as Vector2) + Vector2(20, -90))
	for chimney in chimneys:
		if not visible_rect.has_point(chimney):
			continue
		for puff in range(6):
			var phase := fmod(_anim_time * 0.35 + float(puff) / 6.0 + chimney.x * 0.001, 1.0)
			var spot := chimney + Vector2(sin(phase * 6.0 + chimney.y) * 8.0 + phase * 18.0, -phase * 90.0)
			draw_circle(spot, 4.0 + phase * 9.0, Color(0.85, 0.83, 0.8, 0.35 * (1.0 - phase)))
	if night or dusk:
		for piece in LayoutScript.VILLAGE_PIECES:
			var sprite := String(piece["sprite"])
			var base := piece["base"] as Vector2
			if sprite.begins_with("buildings/") and sprite != "buildings/torre" and visible_rect.has_point(base):
				for window in [Vector2(-24.0, -60.0), Vector2(20.0, -58.0)]:
					var flicker := 0.75 + 0.25 * sin(_anim_time * 3.0 + base.x + window.x)
					draw_rect(Rect2(base + window, Vector2(8.0, 8.0)), Color(1.0, 0.82, 0.45, 0.85 * flicker))
	if night:
		for firefly in range(40):
			var origin := Vector2(fmod(float(firefly) * 397.0, LayoutScript.WORLD_SIZE.x), fmod(float(firefly) * 251.0, LayoutScript.WORLD_SIZE.y))
			var spot := origin + Vector2(sin(_anim_time * 0.7 + float(firefly)) * 40.0, cos(_anim_time * 0.5 + float(firefly) * 1.3) * 30.0)
			if visible_rect.has_point(spot):
				draw_circle(spot, 2.0, Color(0.85, 1.0, 0.5, 0.5 + 0.5 * sin(_anim_time * 4.0 + float(firefly))))
	else:
		for bird in range(5):
			var travel := fmod(_anim_time * 60.0 + float(bird) * 700.0, LayoutScript.WORLD_SIZE.x + 400.0) - 200.0
			var spot := Vector2(travel, 180.0 + float(bird) * 230.0 + sin(_anim_time + float(bird)) * 20.0)
			if visible_rect.has_point(spot):
				var flap := sin(_anim_time * 10.0 + float(bird)) * 4.0
				draw_polyline(PackedVector2Array([spot + Vector2(-7.0, -flap), spot, spot + Vector2(7.0, -flap)]), Color("2f2a35"), 1.5)
	var chicken := SpriteLibraryScript.texture("props/galinha")
	if chicken != null:
		for hen in range(5):
			var home := Vector2(200.0 + float(hen) * 60.0, 2000.0 + float(hen % 2) * 20.0)
			var spot := home + Vector2(sin(_anim_time * 0.4 + float(hen) * 2.0) * 50.0, cos(_anim_time * 0.3 + float(hen)) * 18.0)
			if visible_rect.has_point(spot):
				draw_set_transform(spot.round(), 0.0, Vector2(-1.0 if cos(_anim_time * 0.4 + float(hen) * 2.0) < 0.0 else 1.0, 1.0))
				draw_texture(chicken, Vector2(-chicken.get_size().x * 0.5, -chicken.get_size().y - absf(sin(_anim_time * 8.0 + float(hen))) * 2.0))
				draw_set_transform(Vector2.ZERO)


func _draw_player(state: Dictionary, peer_id: Variant) -> void:
	var position := _display_position(peer_id)
	var feet := position + Vector2(0.0, 12.0)
	var is_local := int(peer_id) == _local_peer
	var color := _player_color(peer_id)
	var players_online := (_view.get("players", {}) as Dictionary).size() > 1
	if players_online:
		draw_arc(feet, 15.0, 0.0, TAU, 24, Color(color, 0.85), 2.0)
	_draw_shadow(feet, Vector2(13.0, 5.0))
	if bool(state.get("downed", false)):
		_draw_downed(state, position, feet)
		return
	var lift := absf(sin(_anim_time * 14.0)) * 3.0 if bool(state.get("moving", false)) else (sin(_anim_time * 2.5) + 1.0) * 0.5
	var tint := Color.WHITE
	var connected := bool(state.get("connected", true))
	if not connected:
		tint = Color(0.7, 0.75, 0.85, 0.45)
		draw_string(ThemeDB.fallback_font, feet + Vector2(-60.0, -72.0), "RECONECTANDO %d s" % int(ceil(float(state.get("reconnect_timer", 0.0)))), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color("aaa59a"))
	elif float(state.get("hurt_flash", 0.0)) > 0.0:
		tint = Color(1.0, 0.45, 0.42)
	elif bool(state.get("invulnerable", false)):
		tint = Color(0.8, 1.0, 1.0, 0.55)
	var character_id := String(state.get("character_id", "eloa"))
	var direction := state.get("facing_direction", Vector2.LEFT if bool(state.get("facing_left", false)) else Vector2.DOWN) as Vector2
	var spin := state.get("volley_spin", {}) as Dictionary
	var animation_time := _locomotion.elapsed("player:%s" % peer_id)
	if not spin.is_empty():
		direction = Vector2.RIGHT.rotated(float(spin["phase"]))
		animation_time = float(spin["elapsed"])
		# Turn through the directional poses rather than rotating the whole sprite flat.
		draw_arc(feet, 20.0, float(spin["phase"]) - 1.1, float(spin["phase"]), 12, Color("c8f2f0", 0.55), 2.0)
	var frame := SpriteLibraryScript.character_frame(character_id, direction, bool(state.get("moving", false)) or not spin.is_empty(), animation_time)
	if frame != null:
		draw_texture(frame, (feet - SpriteLibraryScript.CHARACTER_FOOT_ANCHOR).round(), tint)
	elif not _draw_sprite("characters/" + character_id, feet, bool(state.get("facing_left", false)), tint, lift):
		draw_circle(position, PLAYER_RADIUS, Color("eeeeee"))
	if players_online and not is_local:
		draw_string(ThemeDB.fallback_font, feet + Vector2(-60.0, -58.0), String(state.get("character_name", "")), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 12, color)
	if _in_arena(StringName(String(state.get("zone", "")))):
		var bar_origin := feet + Vector2(-18.0, 8.0)
		var max_health := maxf(1.0, float(state.get("max_health", 100.0)))
		var max_breath := maxf(1.0, float(state.get("max_breath", 100.0)))
		draw_rect(Rect2(bar_origin, Vector2(36.0, 4.0)), Color("1b1a1f"))
		draw_rect(Rect2(bar_origin, Vector2(36.0 * float(state.get("health", 0.0)) / max_health, 4.0)), Color("b04a3a"))
		draw_rect(Rect2(bar_origin + Vector2(0.0, 5.0), Vector2(36.0, 3.0)), Color("1b1a1f"))
		draw_rect(Rect2(bar_origin + Vector2(0.0, 5.0), Vector2(36.0 * float(state.get("breath", 0.0)) / max_breath, 3.0)), Color("7fd6e0"))
		if float(state.get("barrier", 0.0)) > 0.0:
			var plate := SpriteLibraryScript.texture("vfx/stone")
			for index in range(3):
				var angle := _anim_time * 2.2 + TAU * float(index) / 3.0
				var orbit := position + Vector2(cos(angle) * 26.0, sin(angle) * 14.0 - 6.0)
				if plate != null:
					draw_texture(plate, (orbit - plate.get_size() * 0.5).round())
				else:
					draw_rect(Rect2(orbit - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Color("aaa59a"))


## Personagem caída: deitada e acinzentada, anel com o tempo restante e barra de estabilização.
func _draw_downed(state: Dictionary, position: Vector2, feet: Vector2) -> void:
	var texture := SpriteLibraryScript.texture("characters/" + String(state.get("character_id", "eloa")))
	draw_circle(feet, 26.0, Color(0.69, 0.29, 0.23, 0.25 + 0.1 * sin(_anim_time * 6.0)))
	if texture != null:
		draw_set_transform(feet.round(), -PI * 0.5, Vector2.ONE)
		draw_texture(texture, Vector2(-texture.get_size().x * 0.5, -texture.get_size().y * 0.5), Color(0.65, 0.6, 0.65))
		draw_set_transform(Vector2.ZERO)
	var window := maxf(1.0, float(state.get("downed_timer", 0.0)))
	var ring := clampf(float(state.get("downed_timer", 0.0)) / 20.0, 0.0, 1.0)
	draw_arc(feet + Vector2(0.0, -36.0), 14.0, -PI * 0.5, -PI * 0.5 + TAU * ring, 32, Color("e87a6a"), 3.0)
	draw_string(ThemeDB.fallback_font, feet + Vector2(-20.0, -31.0), "%d" % int(ceil(window)), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 11, Color("f2e6c9"))
	var progress := clampf(float(state.get("stabilize_progress", 0.0)), 0.0, 1.0)
	var bar := Rect2(feet + Vector2(-26.0, 14.0), Vector2(52.0, 6.0))
	draw_rect(bar, Color("1b1a1f"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * progress, bar.size.y)), Color("93c25a"))
	draw_string(ThemeDB.fallback_font, feet + Vector2(-70.0, 34.0), "FIQUE AO LADO PARA ESTABILIZAR", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 9, Color("e8b84a"))


func _draw_passive_markers(markers: Array) -> void:
	for marker: Variant in markers:
		var entry := marker as Dictionary
		var position := entry["position"] as Vector2
		var fade := clampf(float(entry["ttl"]), 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(_anim_time * 6.0 + position.x)
		if String(entry["kind"]) == "residue":
			draw_circle(position, 10.0 + pulse * 3.0, Color(0.5, 0.84, 0.88, 0.35 * fade))
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -6.0), position + Vector2(4.0, 0.0),
				position + Vector2(0.0, 6.0), position + Vector2(-4.0, 0.0),
			]), Color(0.78, 0.95, 0.94, fade))
		else:
			draw_circle(position, 16.0, Color(0.85, 0.51, 0.29, 0.18 * fade))
			draw_arc(position, 14.0 + pulse * 2.0, 0.0, TAU, 24, Color(0.91, 0.72, 0.29, fade), 2.0)
			draw_colored_polygon(PackedVector2Array([
				position + Vector2(0.0, -8.0), position + Vector2(7.0, 5.0), position + Vector2(-7.0, 5.0),
			]), Color(0.85, 0.51, 0.29, fade))


## Saque no chão: pedra usa o sprite de pedra; materiais e equipamentos usam um losango na cor do tier.
## Equipamentos e itens raros ganham facho de luz e nome para leitura em meio à horda.
func _draw_drop(drop: Dictionary) -> void:
	var position := drop["position"] as Vector2
	var tier := String(drop.get("tier", "common"))
	var color := ItemTier.color(tier)
	var pulse := 0.5 + 0.5 * sin(_anim_time * 4.0 + position.x * 0.07)
	var bob := sin(_anim_time * 3.0 + position.x * 0.05) * 2.0
	var notable := bool(drop.get("equipment", false)) or tier in ["rare", "epic", "legendary"]
	var stone_drop := String(drop.get("item_id", "")) == "pedra_regenerativa"
	var filter := String((_local() as Dictionary).get("loot_filter", "common"))
	if bool(drop.get("equipment", false)) and ItemTier.TIER_KEYS_ORDER.find(tier) < ItemTier.TIER_KEYS_ORDER.find(filter):
		# Abaixo do filtro: fica no chão, apagado e sem nome, para não disputar atenção.
		var faded := SpriteLibraryScript.texture("items/" + String(drop.get("item_id", "")))
		if faded != null:
			var fit := 16.0 / maxf(faded.get_width(), faded.get_height())
			var extent := faded.get_size() * fit
			draw_texture_rect(faded, Rect2((position - extent * 0.5).round(), extent.round()), false, Color(1.0, 1.0, 1.0, 0.3))
		else:
			draw_circle(position, 4.0, Color(color, 0.3))
		return
	if stone_drop:
		color = Color("7fd6e0")
	_draw_shadow(position + Vector2(0.0, 7.0), Vector2(10.0, 4.0))
	draw_circle(position, 13.0 + pulse * 3.0, Color(color, 0.18 + 0.12 * pulse))
	if notable:
		draw_rect(Rect2(position + Vector2(-2.0, -54.0), Vector2(4.0, 54.0)), Color(color, 0.25 + 0.15 * pulse))
	var size := 9.0 if notable else 7.0
	var center := position + Vector2(0.0, bob - 5.0)
	var icon := SpriteLibraryScript.texture("items/" + String(drop.get("item_id", "")))
	if icon != null:
		var fit := (26.0 if notable else 22.0) / maxf(icon.get_width(), icon.get_height())
		var extent := icon.get_size() * fit
		draw_texture_rect(icon, Rect2((center - extent * 0.5).round(), extent.round()), false)
		_draw_drop_label(drop, position, color, notable)
		return
	var outline := PackedVector2Array([
		center + Vector2(0.0, -size - 2.0), center + Vector2(size + 2.0, 0.0), center + Vector2(0.0, size + 2.0), center + Vector2(-size - 2.0, 0.0),
	])
	draw_colored_polygon(outline, Color("1b1a1f"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -size), center + Vector2(size, 0.0), center + Vector2(0.0, size), center + Vector2(-size, 0.0),
	]), color)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -size), center + Vector2(size * 0.5, -size * 0.5), center + Vector2(0.0, 0.0), center + Vector2(-size * 0.5, -size * 0.5),
	]), Color(1.0, 1.0, 1.0, 0.35))
	_draw_drop_label(drop, position, color, notable)


func _draw_drop_label(drop: Dictionary, position: Vector2, color: Color, notable: bool) -> void:
	var quantity := int(drop.get("quantity", 1))
	var near := position.distance_to(_display_position(_local_peer)) <= 180.0
	if notable or near or quantity > 1:
		var text := String(drop.get("name", "")) if notable or near else ""
		if quantity > 1:
			text = ("%s x%d" % [text, quantity]).strip_edges()
		draw_string(ThemeDB.fallback_font, position + Vector2(-80.0, -24.0), text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 12, color)


func _draw_ground_effect(effect: Dictionary) -> void:
	var position := effect.get("position", Vector2.ZERO) as Vector2
	var radius := float(effect.get("radius", 40.0))
	var gem_id := String(effect.get("gem_id", ""))
	if String(effect.get("mechanic", "")) == "orbit":
		var orbit := String(SkillThemesScript.for_gem(gem_id).get("orbit", "sh_star"))
		var star := VfxLayerScript.sheet_frame(orbit, gem_id, _anim_time)
		for point: Vector2 in effect.get("points", []) as Array:
			if star.is_empty():
				_draw_sprite("vfx/needle", point, false, Color("c8f2f0"))
				continue
			var extent := float(effect.get("collision_radius", 20.0)) * 2.4
			draw_set_transform(point.round(), _anim_time * 9.0, Vector2.ONE * extent / 64.0)
			draw_texture_rect_region(star["texture"] as Texture2D, Rect2(Vector2(-32.0, -32.0), Vector2(64.0, 64.0)), star["region"] as Rect2, star["tint"] as Color)
			draw_set_transform(Vector2.ZERO)
		return
	if String(effect.get("mechanic", "")) == "volley":
		# Saraivada: runa girando nos pés, trocando de elemento como as flechas, e o alcance tênue.
		var element := "element:" + String(["fire", "ice", "lightning"][int(_anim_time * 2.5) % 3])
		var rune := VfxLayerScript.sheet_frame("sh_rune", element, _anim_time)
		if not rune.is_empty():
			draw_set_transform(position.round() + Vector2(0.0, 10.0), _anim_time * 1.5, Vector2(1.1, 0.55))
			draw_texture_rect_region(rune["texture"] as Texture2D, Rect2(Vector2(-32.0, -32.0), Vector2(64.0, 64.0)), rune["region"] as Rect2, Color(rune["tint"] as Color, 0.85))
			draw_set_transform(Vector2.ZERO)
		draw_arc(position, radius, 0.0, TAU, 48, Color(SkillThemesScript.tint(element, Color("e8e070")), 0.18), 1.0)
		return
	if String(effect.get("mechanic", "")) == "mine":
		var armed := bool(effect.get("armed", false))
		var pulse := VfxLayerScript.sheet_frame("sh_pulse", gem_id, _anim_time)
		if pulse.is_empty():
			_draw_sprite("vfx/impact", position, false, Color("e8b84a") if armed else Color("aaa59a"))
		else:
			# Núcleo pulsante: apagado enquanto arma, aceso quando pronto para detonar.
			draw_set_transform(position.round(), 0.0, Vector2.ONE * 0.8)
			draw_texture_rect_region(pulse["texture"] as Texture2D, Rect2(Vector2(-32.0, -32.0), Vector2(64.0, 64.0)), pulse["region"] as Rect2, Color(pulse["tint"] as Color, 1.0 if armed else 0.45))
			draw_set_transform(Vector2.ZERO)
		draw_arc(position, radius, 0, TAU, 32, Color(SkillThemesScript.tint(gem_id, Color("e8b84a")), 0.6 if armed else 0.25), 1.5)
		return
	var sanctuary := String(effect.get("mechanic", "")) == "sanctuary"
	var remaining := clampf(float(effect.get("duration", 1.0)), 0.0, 1.0)
	var tint := SkillThemesScript.tint(String(effect.get("gem_id", "")), Color("93c25a") if sanctuary else Color("b05ad9"))
	var ground := String(SkillThemesScript.for_gem(gem_id).get("ground", ""))
	var field := VfxLayerScript.sheet_frame(ground, gem_id, _anim_time) if not ground.is_empty() else {}
	var circle := SpriteLibraryScript.texture("vfx/anim/el_magic_circle")
	var texture := SpriteLibraryScript.texture("vfx/sanctuary" if sanctuary else "vfx/gravity")
	if not field.is_empty():
		# Keep the field inside its gameplay radius; its own palette conveys the mechanic.
		draw_set_transform(position.round(), 0.0, Vector2.ONE * radius * 2.0 / 64.0)
		draw_texture_rect_region(field["texture"] as Texture2D, Rect2(-32.0, -32.0, 64.0, 64.0), field["region"] as Rect2, Color(1.0, 1.0, 1.0, 0.65 * remaining))
		draw_set_transform(Vector2.ZERO)
	elif circle != null:
		# Círculo mágico animado, girando devagar, na cor do elemento da gema.
		var side := float(circle.get_height())
		var frame := int(_anim_time * 10.0) % maxi(1, int(circle.get_width() / side))
		draw_set_transform(position.round(), _anim_time * (0.4 if sanctuary else -0.6), Vector2.ONE * radius * 2.0 / (side * 0.9))
		draw_texture_rect_region(circle, Rect2(Vector2.ONE * -side * 0.5, Vector2(side, side)), Rect2(frame * side, 0.0, side, side), Color(tint, 0.9 * remaining))
		draw_set_transform(Vector2.ZERO)
		draw_circle(position, radius, Color(tint, 0.08 * remaining))
	elif texture != null:
		draw_set_transform(position.round(), _anim_time * (0.6 if sanctuary else -2.4), Vector2.ONE * radius * 2.0 / texture.get_size().x)
		draw_texture(texture, -texture.get_size() * 0.5, Color(1.0, 1.0, 1.0, 0.85 * remaining))
		draw_set_transform(Vector2.ZERO)
	else:
		draw_circle(position, radius, Color(0.5, 0.84, 0.88, 0.14 * remaining))
	draw_arc(position, radius, 0.0, TAU, 40, Color(tint, 0.8 * remaining), 2.0)


func _draw_enemy(enemy: Dictionary) -> void:
	var position := enemy["position"] as Vector2
	var mechanic := String(enemy.get("base_mechanic", ""))
	var distance := position.distance_to(_display_position(_local_peer))
	var texture := SpriteLibraryScript.texture("enemies/" + String(enemy.get("definition_id", "")))
	var frame := SpriteLibraryScript.actor_frame("enemies/" + String(enemy.get("definition_id", "")), enemy.get("facing_direction", Vector2.DOWN) as Vector2, bool(enemy.get("moving", false)), _anim_time)
	var visual_scale := 1.75 if frame != null and bool(enemy.get("boss", false)) else 1.0
	var height := texture.get_size().y if texture != null else 26.0
	height *= visual_scale
	var feet := position + Vector2(0.0, height * 0.5 - 4.0)
	if mechanic == "loot_mimic" and not bool(enemy.get("awakened", false)):
		_draw_sprite("props/crates", feet, false, Color.WHITE)
		return
	var alpha := 1.0
	if (mechanic == "wall_ambush" or String(enemy.get("race_trait", "")) == "wall_camouflage") and distance > 170.0:
		alpha = 0.3
	_draw_shadow(feet, Vector2(maxf(10.0, height * 0.4), 5.0))
	var lift := absf(sin(_anim_time * 9.0 + float(int(position.x) % 7))) * 2.0
	var tint := Color(1.0, 1.0, 1.0, alpha)
	if float(enemy.get("flash", 0.0)) > 0.0:
		tint = Color(1.0, 0.55, 0.5, alpha)
	var poisons := enemy.get("poisons", []) as Array
	if not poisons.is_empty():
		# Envenenado (decisão 586): tom verde e bolhas subindo, mais rápidas com esporos.
		tint = Color(tint.r * 0.7, minf(1.0, tint.g * 1.05), tint.b * 0.6, tint.a)
	if frame != null:
		draw_set_transform(feet.round(), 0.0, Vector2.ONE * visual_scale)
		draw_texture(frame, -SpriteLibraryScript.CHARACTER_FOOT_ANCHOR, tint)
		draw_set_transform(Vector2.ZERO)
	elif not _draw_sprite("enemies/" + String(enemy.get("definition_id", "")), feet, _display_position(_local_peer).x < position.x, tint, lift):
		draw_circle(position, {"nascente": 10.0, "maduro": 13.0, "evoluido": 16.0, "alfa": 19.0, "apice": 24.0}.get(String(enemy.get("rank_id", "maduro")), 13.0) as float, Color("9b9b9b"))
	var top := feet - Vector2(0.0, height + 8.0)
	if not String(enemy.get("prefix_id", "")).is_empty():
		draw_colored_polygon(PackedVector2Array([top + Vector2(-8.0, -6.0), top + Vector2(-2.0, -6.0), top + Vector2(-5.0, 0.0)]), Color("e8b84a"))
	if not String(enemy.get("suffix_id", "")).is_empty():
		draw_circle(top + Vector2(6.0, -3.0), 3.5, Color("8a5f9e"))
	var health := float(enemy["health"])
	var maximum := float(enemy.get("max_health", 60.0))
	if health < maximum:
		var bar_width := clampf(height, 24.0, 48.0)
		draw_rect(Rect2(top + Vector2(-bar_width * 0.5, 4.0), Vector2(bar_width, 4.0)), Color("1b1a1f"))
		draw_rect(Rect2(top + Vector2(-bar_width * 0.5, 4.0), Vector2(bar_width * health / maximum, 4.0)), Color("b04a3a"))
	if int(enemy.get("shield_hits", 0)) > 0:
		draw_arc(position, height * 0.6, 0.0, TAU, 28, Color(0.79, 0.83, 0.84, 0.8), 2.0)
	if not poisons.is_empty():
		var spores := poisons.any(func(entry: Dictionary) -> bool: return String(entry.get("type", "")) == "esporo")
		for bubble in range(3):
			var phase := fmod(_anim_time * (1.6 if spores else 1.0) + bubble * 0.37 + position.x * 0.013, 1.0)
			var spot := top + Vector2((bubble - 1) * 7.0, 10.0 - phase * 16.0)
			draw_circle(spot, 2.0 + bubble % 2, Color("b4f05a" if spores else "8fe05a", 1.0 - phase))


func _draw_summon(effect: Dictionary) -> void:
	var position := effect.get("position", Vector2.ZERO) as Vector2
	var feet := position + Vector2(0.0, 12.0)
	_draw_shadow(feet, Vector2(10.0, 4.0))
	if not _draw_sprite("enemies/molde_vigilante", feet, false, Color(0.85, 1.0, 1.0)):
		var body := float(effect.get("collision_radius", 12.0))
		draw_rect(Rect2(position - Vector2.ONE * body, Vector2.ONE * body * 2.0), Color("bdbdbd"))
	draw_arc(feet, 14.0, 0.0, TAU, 20, Color(0.5, 0.84, 0.88, 0.6), 1.5)


# ---------------------------------------------------------------- cenário e luz

func _build_lights() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 256
	texture.height = 256
	_player_light = PointLight2D.new()
	_player_light.name = "PlayerLight"
	_player_light.texture = texture
	_player_light.texture_scale = 2.6
	_player_light.color = Color(0.85, 0.97, 1.0)
	_player_light.energy = 0.9
	add_child(_player_light)
	_light_texture = texture
	_village_lights = Node2D.new()
	_village_lights.name = "VillageLights"
	add_child(_village_lights)
	for piece in LayoutScript.VILLAGE_PIECES:
		if String(piece["sprite"]) in ["props/lamp", "buildings/forja"]:
			var lamp := PointLight2D.new()
			lamp.texture = texture
			lamp.texture_scale = 1.6 if String(piece["sprite"]) == "props/lamp" else 2.4
			lamp.energy = 1.5
			lamp.color = Color(1.0, 0.78, 0.45)
			lamp.position = (piece["base"] as Vector2) - Vector2(0.0, 30.0)
			_village_lights.add_child(lamp)
	_tower_lights = Node2D.new()
	_tower_lights.name = "TowerLights"
	add_child(_tower_lights)


## Orçamento de luzes (regressão de 2026-10-07): no renderizador de compatibilidade cada luz 2D
## redesenha tudo o que alcança; com os ~43 postes da vila acesos à noite o quadro passava de
## 140 ms. Só ficam acesas as luzes que alcançam a tela, no máximo LIGHT_BUDGET, as mais próximas.
const LIGHT_BUDGET := 8


func _cull_lights(container: Node2D) -> void:
	if not container.visible:
		return
	var view := _visible_world_rect()
	var center := view.get_center()
	var candidates: Array[PointLight2D] = []
	for child in container.get_children():
		var light := child as PointLight2D
		if light == null:
			continue
		light.enabled = false
		var reach := float(light.texture.get_width() if light.texture != null else 256) * 0.5 * light.texture_scale
		if view.grow(reach).has_point(light.position):
			candidates.append(light)
	candidates.sort_custom(func(left: PointLight2D, right: PointLight2D) -> bool: return left.position.distance_squared_to(center) < right.position.distance_squared_to(center))
	for index in range(mini(LIGHT_BUDGET, candidates.size())):
		candidates[index].enabled = true


## Luzes do andar: pontos do layout na cor do bioma, portal e escada.
func _rebuild_floor_lights() -> void:
	for child in _tower_lights.get_children():
		child.queue_free()
	if _floor_layout.is_empty():
		return
	var tint := Color(String(TowerContentScript.biome(String(_floor_layout.get("biome", ""))).get("ambient", "5c6680"))).lightened(0.55)
	var spots: Array = (_floor_layout.get("lights", []) as Array).duplicate()
	spots.append((_floor_layout["return_portal"] as Rect2).get_center())
	spots.append((_floor_layout["stairs"] as Rect2).get_center())
	for spot: Vector2 in spots:
		var torch := PointLight2D.new()
		torch.texture = _light_texture
		torch.texture_scale = 1.8
		torch.color = Color(1.0, 0.68, 0.36) if String(_floor_layout.get("biome", "")) == "galerias" else tint
		torch.position = spot - Vector2(0.0, 40.0)
		_tower_lights.add_child(torch)


func _build_road_edges() -> void:
	_road_edges.clear()
	var random := RandomNumberGenerator.new()
	random.seed = 77
	for road in LayoutScript.VILLAGE_ROADS:
		var horizontal := road.size.x > road.size.y
		var length := road.size.x if horizontal else road.size.y
		for side in [0.0, 1.0]:
			var distance := 0.0
			while distance < length:
				var along := road.position.x + distance if horizontal else road.position.y + distance
				var center := Vector2(along, road.position.y + road.size.y * side) if horizontal else Vector2(road.position.x + road.size.x * side, along)
				distance += random.randf_range(14.0, 30.0)
				var inside_other := false
				for other in LayoutScript.VILLAGE_ROADS:
					if other != road and other.grow(-4.0).has_point(center):
						inside_other = true
				if inside_other:
					continue
				var radius := random.randf_range(6.0, 15.0)
				var blob := PackedVector2Array()
				for index in range(8):
					var angle := TAU * float(index) / 8.0
					blob.append((center + Vector2(cos(angle), sin(angle)) * radius * random.randf_range(0.7, 1.15)).round())
				_road_edges.append(blob)
	_build_road_edge_mesh()


## Regressão (2026-10-07): as ~1.600 bordas de grama eram desenhadas como polígonos soltos, triangulados
## a cada quadro (52 ms de CPU e 1.600 chamadas de desenho; a vila rodava a ~7 FPS). Agora viram uma
## só malha triangulada uma vez, desenhada com uma chamada.
func _build_road_edge_mesh() -> void:
	_road_edge_mesh = null
	var grass := SpriteLibraryScript.texture("tiles/grass")
	if grass == null or _road_edges.is_empty():
		return
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	for blob in _road_edges:
		for index in range(1, blob.size() - 1):
			for point in [blob[0], blob[index], blob[index + 1]]:
				vertices.append(point)
				uvs.append(point / grass.get_size())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	_road_edge_mesh = ArrayMesh.new()
	_road_edge_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _update_camera_limits() -> void:
	var map_size: Vector2 = (_floor_layout["size"] as Vector2) if _local_zone() == &"tower" and not _floor_layout.is_empty() else LayoutScript.map_size(_local_zone())
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = int(map_size.x)
	_camera.limit_bottom = int(map_size.y)
	_camera.reset_smoothing()


# ---------------------------------------------------------------- interface

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	_interface_layer = layer
	layer.name = "Interface"
	layer.layer = 2
	add_child(layer)
	_autosave_label = Label.new()
	_autosave_label.name = "AutosaveLabel"
	_autosave_label.text = "Jogo salvo"
	_autosave_label.add_theme_color_override("font_color", Color("e8b84a"))
	_autosave_label.add_theme_color_override("font_outline_color", Color("12111a"))
	_autosave_label.add_theme_constant_override("outline_size", 4)
	_autosave_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_autosave_label.offset_left = 20.0
	_autosave_label.offset_top = -44.0
	_autosave_label.offset_right = 220.0
	_autosave_label.offset_bottom = -20.0
	_autosave_label.visible = false
	_autosave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_autosave_label)
	var bar := Panel.new()
	bar.name = "TopBar"
	bar.position = Vector2(18.0, 18.0)
	bar.size = Vector2(420.0, 58.0)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar = bar
	# Mesmo acabamento da HUD de combate: painel escuro arredondado, sombra e fio dourado.
	var style := StyleBoxFlat.new()
	style.bg_color = Color("12111aee")
	style.border_color = Color(0.79, 0.66, 0.42, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 8
	style.anti_aliasing = true
	bar.add_theme_stylebox_override("panel", style)
	var accent := ColorRect.new()
	accent.position = Vector2(7.0, 11.0)
	accent.size = Vector2(2.0, 36.0)
	accent.color = Color("e8c27a")
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(accent)
	layer.add_child(bar)
	var settings_button := Button.new()
	settings_button.name = "Settings"
	settings_button.focus_mode = Control.FOCUS_NONE
	settings_button.text = "Opções"
	settings_button.position = Vector2(448.0, 18.0)
	settings_button.size = Vector2(96.0, 40.0)
	settings_button.pressed.connect(_open_settings)
	layer.add_child(settings_button)
	_settings_dialog = SettingsDialogScript.new()
	add_child(_settings_dialog)
	_settings_dialog.call("enable_session_exit")
	_settings_dialog.connect("leave_requested", _leave_session)
	_settings_dialog.connect("session_action_requested", _session_action)
	_location_label = Label.new()
	_location_label.name = "Location"
	_location_label.position = Vector2(16.0, 6.0)
	_location_label.add_theme_font_size_override("font_size", 17)
	_location_label.add_theme_color_override("font_color", Color("f2e6c9"))
	bar.add_child(_location_label)
	_status_label = Label.new()
	_status_label.name = "Status"
	_status_label.position = Vector2(16.0, 40.0)
	_status_label.size = Vector2(396.0, 22.0)
	_status_label.position = Vector2(16.0, 31.0)
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.clip_text = true
	_status_label.modulate = Color("d9c2a0")
	bar.add_child(_status_label)
	_session_label = Label.new()
	_session_label.name = "Session"
	_session_label.position = Vector2(20.0, 96.0)
	_session_label.add_theme_font_size_override("font_size", 13)
	_session_label.add_theme_color_override("font_color", Color("aaa59a"))
	layer.add_child(_session_label)
	_talk_hint = Label.new()
	_talk_hint.name = "TalkHint"
	_talk_hint.position = Vector2(500.0, 560.0)
	_talk_hint.size = Vector2(280.0, 24.0)
	_talk_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_talk_hint.add_theme_color_override("font_color", Color("e8b84a"))
	_talk_hint.add_theme_color_override("font_shadow_color", Color.BLACK)
	_talk_hint.visible = false
	layer.add_child(_talk_hint)
	_service_menu = preload("res://src/prototype/village/service_menu.gd").new()
	_service_menu.name = "VillageServices"
	layer.add_child(_service_menu)
	_service_menu.connect("purchase_requested", func(npc_id: String, offer_id: String) -> void: _send_intent("service", [npc_id, offer_id]))
	_service_menu.connect("shop_requested", func() -> void:
		_service_menu.call("close")
		_open_shop())
	_shop_menu = preload("res://src/prototype/village/shop_menu.gd").new()
	_shop_menu.name = "VillageShop"
	layer.add_child(_shop_menu)
	_shop_menu.connect("buy_requested", func(index: int) -> void: _send_intent("shop_buy", [index]))
	_shop_menu.connect("reroll_requested", func() -> void: _send_intent("shop_reroll", []))
	_service_menu.connect("talk_requested", func(npc_id: String) -> void:
		if ((_view.get("narrative", {}) as Dictionary).get("conversations", {}) as Dictionary).has(npc_id):
			_narrative_menu.call("open", _conversation_model(npc_id), true)
		else:
			_send_intent("talk", [npc_id]))
	_narrative_menu = preload("res://src/prototype/village/narrative_menu.gd").new()
	_narrative_menu.name = "NarrativeJournal"
	layer.add_child(_narrative_menu)
	_narrative_menu.connect("action_requested", func(action: String) -> void: _send_intent("narrative", [action]))
	_objective_label = Label.new()
	_objective_label.name = "NarrativeObjective"
	_objective_label.position = Vector2(20, 170)
	_objective_label.size = Vector2(360, 60)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_label.add_theme_font_size_override("font_size", 14)
	_objective_label.add_theme_color_override("font_color", Color("b7d8d1"))
	_objective_label.add_theme_color_override("font_outline_color", Color("12111a"))
	_objective_label.add_theme_constant_override("outline_size", 3)
	layer.add_child(_objective_label)
	_village_log_label = Label.new()
	_village_log_label.name = "VillageLog"
	_village_log_label.position = Vector2(20.0, 560.0)
	_village_log_label.size = Vector2(620.0, 110.0)
	_village_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_village_log_label.add_theme_font_size_override("font_size", 12)
	_village_log_label.add_theme_color_override("font_color", Color("f2e6c9"))
	_village_log_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_village_log_label.visible = false
	layer.add_child(_village_log_label)
	_floor_label = Label.new()
	_floor_label.name = "FloorStatus"
	_floor_label.position = Vector2(20.0, 116.0)
	_floor_label.add_theme_font_size_override("font_size", 13)
	_floor_label.add_theme_color_override("font_color", Color("e8b84a"))
	_floor_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_floor_label.visible = false
	layer.add_child(_floor_label)
	_boss_bar = Control.new()
	_boss_bar.name = "BossBar"
	_boss_bar.position = Vector2(340.0, 140.0)
	_boss_bar.size = Vector2(600.0, 40.0)
	_boss_bar.visible = false
	layer.add_child(_boss_bar)
	var boss_back := ColorRect.new()
	boss_back.color = Color("1b1a1fe0")
	boss_back.position = Vector2(0.0, 18.0)
	boss_back.size = Vector2(600.0, 16.0)
	_boss_bar.add_child(boss_back)
	var boss_fill := ColorRect.new()
	boss_fill.name = "Fill"
	boss_fill.color = Color("b04a3a")
	boss_fill.position = Vector2(2.0, 20.0)
	boss_fill.size = Vector2(596.0, 12.0)
	_boss_bar.add_child(boss_fill)
	var boss_name := Label.new()
	boss_name.name = "Name"
	boss_name.size = Vector2(600.0, 18.0)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name.add_theme_color_override("font_color", Color("f2e6c9"))
	boss_name.add_theme_color_override("font_shadow_color", Color.BLACK)
	_boss_bar.add_child(boss_name)
	_combat_label = Label.new()
	_combat_label.name = "CombatStatus"
	_combat_label.position = Vector2(18.0, 674.0)
	_combat_label.size = Vector2(1244.0, 28.0)
	_combat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_combat_label.add_theme_constant_override("shadow_offset_x", 2)
	_combat_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(_combat_label)
	_combat_hud = CombatHudScript.new() as Control
	_combat_hud.name = "CombatHud"
	_combat_hud.visible = false
	layer.add_child(_combat_hud)
	_build_character_panel(layer)
	_player_menu = PlayerMenuScript.new() as Control
	_player_menu.name = "PlayerMenu"
	_player_menu.stat_requested.connect(func(stat: StringName) -> void: _send_intent("stat", [String(stat)]))
	_player_menu.milestone_requested.connect(func(choice: StringName) -> void: _send_intent("milestone", [String(choice)]))
	_player_menu.equip_requested.connect(func(instance_id: StringName) -> void: _send_intent("equip", [String(instance_id)]))
	_player_menu.unequip_requested.connect(func(slot: int, index: int) -> void: _send_intent("unequip", [slot, index]))
	_player_menu.sell_requested.connect(func(instance_id: StringName) -> void: _send_intent("sell", [String(instance_id)]))
	_player_menu.sell_all_requested.connect(func() -> void: _send_intent("sell_all", []))
	_player_menu.stats_reset_requested.connect(func() -> void: _send_intent("reset_stats", []))
	_player_menu.loot_filter_requested.connect(func(tier: String) -> void: _send_intent("loot_filter", [tier]))
	_player_menu.auto_sell_requested.connect(func(tier: String) -> void: _send_intent("auto_sell", [tier]))
	_player_menu.gem_slot_requested.connect(func(slot: int, gem_id: String) -> void: _send_intent("gem_slot", [slot, gem_id]))
	_player_menu.support_attach_requested.connect(func(slot: int, support_id: String) -> void: _send_intent("support_add", [slot, support_id]))
	_player_menu.support_detach_requested.connect(func(slot: int, support_id: String) -> void: _send_intent("support_remove", [slot, support_id]))
	_player_menu.start_floor_requested.connect(func(floor_number: int) -> void: _send_intent("start_floor", [floor_number]))
	_player_menu.journal_requested.connect(_open_journal)
	_player_menu.gem_evolution_requested.connect(func(gem_id: String, choice_id: String) -> void: _send_intent("gem_evolution", [gem_id, choice_id]))
	layer.add_child(_player_menu)
	layer.move_child(_narrative_menu, layer.get_child_count() - 1)
	_milestone_choice = MilestoneChoiceScript.new() as Control
	_milestone_choice.name = "MilestoneChoice"
	_milestone_choice.choice_requested.connect(func(choice: StringName) -> void: _send_intent("milestone", [String(choice)]))
	# The modal uses viewport coordinates, independent of the scaled combat HUD.
	var milestone_layer := CanvasLayer.new()
	milestone_layer.name = "MilestoneLayer"
	milestone_layer.layer = 10
	add_child(milestone_layer)
	milestone_layer.add_child(_milestone_choice)


func _build_character_panel(layer: CanvasLayer) -> void:
	_character_panel = ColorRect.new()
	_character_panel.name = "CharacterPanel"
	(_character_panel as ColorRect).color = Color("1b1a1fd0")
	_character_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_character_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_character_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_character_panel.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var title := Label.new()
	title.text = "QUEM ENTRA NA TORRE?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("e8b84a"))
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	column.add_child(row)
	var beta := JSON.parse_string(FileAccess.get_file_as_string("res://data/beta/beta_content.json")) as Dictionary
	for definition: Dictionary in beta.get("playable_characters", []) as Array:
		var character_id := String(definition.get("id", ""))
		var passive := definition.get("passive", {}) as Dictionary
		var card := Button.new()
		card.name = "Pick_%s" % character_id
		card.custom_minimum_size = Vector2(250.0, 360.0)
		card.pressed.connect(func() -> void:
			_send_intent("character", [character_id])
			_show_character_panel(false)
		)
		row.add_child(card)
		_character_cards[character_id] = card
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_theme_constant_override("separation", 6)
		card.add_child(content)
		var portrait := TextureRect.new()
		portrait.texture = SpriteLibraryScript.texture("characters/" + character_id)
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.custom_minimum_size = Vector2(0.0, 150.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(portrait)
		for text_spec: Array in [
			[String(definition.get("name", "")), 18, Color("f2e6c9")],
			[String(passive.get("name", "")).to_upper(), 13, Color("e8b84a")],
			[String(passive.get("description", "")), 12, Color("d9c2a0")],
		]:
			var label := Label.new()
			label.text = text_spec[0]
			label.add_theme_font_size_override("font_size", text_spec[1])
			label.add_theme_color_override("font_color", text_spec[2])
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = 226.0
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(label)
	var hint := Label.new()
	_character_hint = hint
	hint.text = "Troque de personagem com %s fora da Torre. Personagens ja em jogo ficam indisponiveis." % BindingsScript.label("switch_character")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color("8f7a6a"))
	column.add_child(hint)
	_show_character_panel("--skip-character-select" not in OS.get_cmdline_user_args() and _requested_character.is_empty() and _test_duration <= 0.0)


func _show_character_panel(visible_now: bool) -> void:
	if visible_now:
		_character_hint.text = "Troque de personagem com %s fora da Torre. Personagens ja em jogo ficam indisponiveis." % BindingsScript.label("switch_character")
		var taken := {}
		for peer_id: Variant in (_view.get("players", {}) as Dictionary):
			if int(peer_id) != _local_peer:
				taken[String(((_view["players"] as Dictionary)[peer_id] as Dictionary).get("character_id", ""))] = true
		for character_id: String in _character_cards:
			(_character_cards[character_id] as Button).disabled = taken.has(character_id)
		for card: Button in _character_cards.values():
			if not card.disabled:
				card.grab_focus.call_deferred()
				break
	_character_panel.visible = visible_now


func _open_player_menu(tab: String) -> void:
	if _sim != null:
		_refresh_menus(_sim.call("menu_model", _local_peer))
	else:
		_send_intent("menu", [])
	_player_menu.call("open", tab)


## Dica de conversa, registro das falas recentes e período do dia na vila.
func _update_village_panel(zone: StringName, period: String) -> void:
	var in_village := zone == &"village"
	_talk_hint.visible = false
	_village_log_label.visible = in_village
	if not in_village:
		if _near_narrative_marker() and not _input_blocked():
			_talk_hint.visible = true
			_talk_hint.text = "%s: Examinar marca de rota" % BindingsScript.label("interact")
		return
	var npc := _nearest_npc(110.0)
	if not npc.is_empty() and not _input_blocked():
		_talk_hint.visible = true
		var has_service := String(npc["id"]) == "nara_quiral" or not preload("res://src/gameplay/world/village_services.gd").offers(String(npc["id"])).is_empty()
		_talk_hint.text = "%s: %s · %s" % [BindingsScript.label("interact"), String(npc["name"]), String(npc["title"]) if has_service else "Conversar"]
	var lines: Array[String] = ["%s  ·  MORADORES: %s%s" % [PERIOD_NAMES.get(period, period.to_upper()), "COM IA" if String(_view.get("npc_mode", "padrao")) == "ia" else "PADRAO", "  (%s alterna)" % BindingsScript.label("npc_mode") if _sim != null else ""]]
	var log := _view.get("village_log", []) as Array
	for index in range(maxi(0, log.size() - 4), log.size()):
		var entry := log[index] as Dictionary
		lines.append("%s: %s" % [String(entry.get("npc", "")), String(entry.get("text", ""))])
	_village_log_label.text = "\n".join(PackedStringArray(lines))


## Painel do andar (tempo, contagem da escada, recorde do modo e respawn) e barra do chefe.
func _update_floor_panel(zone: StringName, floor_view: Dictionary) -> void:
	var in_tower := zone == &"tower" and not floor_view.is_empty()
	_floor_label.visible = in_tower
	_boss_bar.visible = in_tower and float(floor_view.get("boss_ratio", -1.0)) >= 0.0
	if not in_tower:
		return
	var best := float(floor_view.get("best", -1.0))
	var mode := String(floor_view.get("mode", "solo")).to_upper()
	var goal := "CHEFE" if String(floor_view.get("kind", "")) == "boss" else "SOBREVIVA %s" % _format_countdown(float(floor_view.get("survival_left", 0.0)))
	if bool(floor_view.get("stairs_open", false)):
		goal = "ESCADA ABERTA"
	_floor_label.text = "%s   TEMPO %s   RECORDE %s %s   ·   %s   ·   RESPAWN %.1f s" % [
		String(TowerContentScript.biome(String(floor_view.get("biome", ""))).get("name", "")).to_upper(),
		_format_time(float(floor_view.get("time", 0.0))), mode, _format_time(best) if best >= 0.0 else "--",
		goal, float(floor_view.get("respawn_interval", 0.0)),
	]
	_combat_hud.set("minimap_title", "ANDAR %d" % int(floor_view.get("number", 0)))
	_combat_hud.set("minimap_hint", "ESCADA ABERTA" if bool(floor_view.get("stairs_open", false)) else ("DERROTE O GUARDIAO" if String(floor_view.get("kind", "")) == "boss" else "ESCADA EM %s" % _format_countdown(float(floor_view.get("survival_left", 0.0)))))
	if _boss_bar.visible:
		(_boss_bar.get_node("Fill") as ColorRect).size.x = float(_boss_bar.get_meta("fill_width", 596.0)) * clampf(float(floor_view["boss_ratio"]), 0.0, 1.0)
		(_boss_bar.get_node("Name") as Label).text = String(floor_view.get("boss_name", "")).to_upper()


func _format_time(seconds: float) -> String:
	return "%d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]

func _format_countdown(seconds: float) -> String:
	var whole := int(ceil(seconds))
	return "%d:%02d" % [whole / 60, whole % 60]



## Interface proporcional à tela: a camada escala pela menor razão em relação a 1280×720 e cada
## bloco se prende à sua borda no espaço resultante (decisão 564).
func _near_narrative_marker() -> bool:
	var model := _view.get("narrative", {}) as Dictionary
	return _local_zone() == &"tower" and model.has("marker_position") and not _local().is_empty() and (_local()["position"] as Vector2).distance_to(model["marker_position"] as Vector2) <= 90.0


func _open_journal() -> void:
	_player_menu.call("close")
	_send_move(_local().get("position", Vector2.ZERO) as Vector2)
	_narrative_menu.call("open", _conversation_model(""), false)


func _conversation_model(npc_id: String) -> Dictionary:
	var model := (_view.get("narrative", {}) as Dictionary).duplicate(true)
	var conversations := model.get("conversations", {}) as Dictionary
	if npc_id == "nara_quiral":
		model["objective"] = model.get("contract_objective", model.get("objective", ""))
		model["secondary_enabled"] = int(_view.get("tower_start_floor", 1)) != 1
		if model.has("secondary_action") and not model["secondary_enabled"]:
			model["secondary_action_label"] = "Andar 1 selecionado"
	if npc_id != "nara_quiral" and not npc_id.is_empty():
		if not conversations.has(npc_id):
			return {}
		model.erase("action")
		model.erase("action_label")
		model.erase("secondary_action")
		model.erase("secondary_action_label")
		model.merge(conversations.get(npc_id, {}) as Dictionary, true)
	if npc_id in ["alda_serrin", "nara_quiral"]:
		model["reaction"] = (model.get("reactions", {}) as Dictionary).get(String(_local().get("character_id", "")), "")
	model["preparation"] = _local().get("expedition_preparation", [])
	return model


func _layout_interface() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var ui_scale := clampf(minf(viewport.x / 1280.0, viewport.y / 720.0), 0.75, 2.0)
	_interface_layer.scale = Vector2.ONE * ui_scale
	var size := viewport / ui_scale
	_top_bar.position = Vector2(16.0, 16.0)
	_session_label.position = Vector2(20.0, 78.0)
	_floor_label.position = Vector2(20.0, 96.0)
	var boss_width := minf(480.0, size.x - 900.0) if size.x > 1380.0 else 440.0
	_boss_bar.position = Vector2((size.x - boss_width) * 0.5, 118.0 if size.x < 1380.0 else 18.0)
	_boss_bar.size = Vector2(boss_width, 40.0)
	(_boss_bar.get_child(0) as Control).size.x = boss_width
	(_boss_bar.get_node("Name") as Control).size.x = boss_width
	_boss_bar.set_meta("fill_width", boss_width - 4.0)
	_combat_label.position = Vector2(16.0, size.y - 32.0)
	_combat_label.size = Vector2(size.x - 32.0, 24.0)
	_village_log_label.size = Vector2(minf(620.0, size.x * 0.5), 96.0)
	_village_log_label.position = Vector2(16.0, size.y - 136.0)
	_talk_hint.position = Vector2((size.x - 280.0) * 0.5, size.y - 170.0)
	_combat_hud.position = Vector2.ZERO
	var window_size := Vector2(get_window().size)
	var screen_scale := maxf(0.01, minf(window_size.x / viewport.x, window_size.y / viewport.y))
	var hud_scale := maxf(1.0, 0.75 / (ui_scale * screen_scale))
	_combat_hud.scale = Vector2.ONE * hud_scale
	_combat_hud.size = size / hud_scale
	_objective_label.size.x = minf(360.0, size.x - 40.0)
	for full in [_player_menu, _character_panel, _narrative_menu, _service_menu, _shop_menu]:
		(full as Control).set_anchors_preset(Control.PRESET_TOP_LEFT)
		(full as Control).position = Vector2.ZERO
		(full as Control).size = size


func _update_interface() -> void:
	var zone := _local_zone()
	var story := _view.get("narrative", {}) as Dictionary
	_objective_label.text = String(story.get("objective", ""))
	if zone == &"village":
		for npc: Dictionary in _view.get("npcs", []):
			if String(npc["id"]) == String(story.get("target_npc", "")):
				var offset := (npc["position"] as Vector2) - _display_position(_local_peer)
				var direction := "leste" if absf(offset.x) > absf(offset.y) and offset.x > 0 else "oeste" if absf(offset.x) > absf(offset.y) else "sul" if offset.y > 0 else "norte"
				_objective_label.text += "\n%s · %s" % [String(npc["name"]), direction]
	_objective_label.visible = story.get("stage", "") != "completed"
	var arena := _in_arena(zone)
	_ambient.color = {&"village": Color(1.0, 0.97, 0.9), &"house": Color(0.78, 0.7, 0.62)}.get(zone, Color(0.36, 0.38, 0.5)) as Color
	var period := String(_view.get("village_period", "manha"))
	if zone == &"village":
		_ambient.color = PERIOD_AMBIENT.get(period, Color(1.0, 0.97, 0.9)) as Color
	_village_lights.visible = zone == &"village" and period in ["entardecer", "noite"]
	_update_village_panel(zone, period)
	var floor_view := _view.get("floor", {}) as Dictionary
	if zone == &"tower" and not _floor_layout.is_empty():
		_ambient.color = Color(String(TowerContentScript.biome(String(_floor_layout.get("biome", ""))).get("ambient", "5c6680"))).lightened(0.12)
	_player_light.enabled = zone != &"village" or period == "noite"
	_player_light.color = Color(1.0, 0.85, 0.6) if zone == &"house" else Color(0.85, 0.97, 1.0)
	_tower_lights.visible = zone == &"tower"
	_cull_lights(_village_lights)
	_cull_lights(_tower_lights)
	for light: Node in _tower_lights.get_children():
		(light as PointLight2D).enabled = zone == &"tower"
	_location_label.text = {
		&"village": "ARESTA // VILA", &"house": "ARESTA // CASA DE ELEN",
	}.get(zone, "TORRE // ANDAR %d  %s" % [int(floor_view.get("number", 0)), String(floor_view.get("name", "")).to_upper()]) as String
	_update_floor_panel(zone, floor_view)
	_status_label.text = _status
	var players := _view.get("players", {}) as Dictionary
	_session_label.text = {
		&"solo": "", &"host": "HOST porta %d  ·  %d/4 jogadores" % [_session_port, players.size()],
		&"client": "CONECTADO AO HOST  ·  %d/4 jogadores" % players.size(),
	}.get(_mode, "") as String
	if arena and players.size() > 1:
		_session_label.text += "  ·  GRUPO NA TORRE %d  ·  AMEACA %d%%" % [int(_view.get("party_size", 1)), int(round(float(_view.get("party_budget", 1.0)) * 100.0))]
	var local := _local()
	if not arena or local.is_empty():
		_combat_hud.visible = false
		_combat_hud.call("clear_context")
		_combat_label.visible = true
		_combat_label.text = "Pedra armazenada: %d   Progresso da vila: %d   ·   Proxima entrada na Torre: andar %d (%s: mapa e recordes)" % [int(_view.get("banked_stone", 0)), int(_view.get("village_progress", 0)), int(_view.get("tower_start_floor", 1)), BindingsScript.label("tower")]
		return
	_combat_label.visible = false
	_combat_hud.visible = true
	_combat_hud.set("auto_attack", SettingsScript.auto_attack)
	_combat_hud.call("set_context", local, players, _local_peer, SettingsScript.auto_aim, _nearest_enemy() if SettingsScript.auto_aim else {}, floor_view)
	var gem_ids := local.get("gem_ids", []) as Array
	var gem_key := ",".join(PackedStringArray(gem_ids))
	if gem_key != _last_gem_key:
		_last_gem_key = gem_key
		var icons: Array[Texture2D] = []
		var empty: Array[bool] = []
		for gem_id: Variant in gem_ids:
			icons.append(null if String(gem_id).is_empty() else SpriteLibraryScript.texture("icons/" + String(gem_id)))
			empty.append(String(gem_id).is_empty())
		_combat_hud.call("set_skill_icons", icons, empty)
	var cooldowns: Array[float] = []
	for value: Variant in local.get("cooldowns", []) as Array:
		cooldowns.append(float(value))
	var max_cooldowns: Array[float] = []
	for value: Variant in local.get("max_cooldowns", []) as Array:
		max_cooldowns.append(maxf(0.1, float(value)))
	var enemy_positions: Array[Vector2] = []
	for enemy: Dictionary in _view.get("enemies", []) as Array:
		enemy_positions.append(enemy["position"] as Vector2)
	var charges: Array[int] = []
	for value: Variant in local.get("charges", [1, 1, 1, 1]) as Array:
		charges.append(int(value))
	var charge_caps: Array[int] = []
	for value: Variant in local.get("charge_caps", [1, 1, 1, 1]) as Array:
		charge_caps.append(int(value))
	_combat_hud.call("set_skill_charges", charges, charge_caps)
	_combat_hud.call("set_skill_tooltips", local.get("skill_tooltips", []) as Array)
	_combat_hud.call("set_passive", local.get("passive_display", {}))
	_combat_hud.call("configure",
		float(local.get("health", 0.0)), float(local.get("max_health", 100.0)),
		float(local.get("breath", 0.0)), float(local.get("max_breath", 100.0)),
		cooldowns, max_cooldowns,
		int(local.get("carried_stone", 0)), enemy_positions.size(), int(local.get("quick_items", 0)),
		_display_position(_local_peer), enemy_positions, (_floor_layout.get("size", Vector2(1280.0, 720.0)) as Vector2),
		(story["marker_position"] as Vector2) if story.has("marker_position") else ((_floor_layout["stairs"] as Rect2).get_center() if bool(floor_view.get("stairs_open", false)) and not _floor_layout.is_empty() else ((_floor_layout["return_portal"] as Rect2).get_center() if not _floor_layout.is_empty() else Vector2.ZERO)),
		int(local.get("level", 1)), int(local.get("experience", 0)), int(local.get("experience_required", 60)),
		bool(local.get("pending_milestone", false))
	)
