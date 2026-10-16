extends Node

signal status_changed(message: String)

const PORT := 24567
const MAX_CLIENTS := 1

var game_root: Node
var status_message := "Offline"

func configure(root: Node) -> void:
	game_root = root
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_server(PORT, MAX_CLIENTS)
	if result != OK:
		_set_status("Could not host LAN co-op (error %d)." % result)
		return result
	multiplayer.multiplayer_peer = peer
	_set_status("Hosting LAN co-op on port %d. Share your Wi-Fi IP with one player." % PORT)
	return OK

func join_game(address: String) -> Error:
	var clean_address := address.strip_edges()
	if clean_address.is_empty():
		_set_status("Enter the host's local IP address first.")
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var result := peer.create_client(clean_address, PORT)
	if result != OK:
		_set_status("Could not connect to %s (error %d)." % [clean_address, result])
		return result
	multiplayer.multiplayer_peer = peer
	_set_status("Connecting to %s:%d…" % [clean_address, PORT])
	return OK

func disconnect_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_set_status("LAN co-op disconnected. Local kingdom is still saved.")

func is_network_active() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and not (peer is OfflineMultiplayerPeer)

func is_client_connected() -> bool:
	return is_network_active() and not multiplayer.is_server() and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED

func request_host_action(action: String, payload: Dictionary = {}) -> void:
	if not is_client_connected():
		_set_status("Not connected to a host.")
		return
	request_action.rpc_id(1, action, payload)

func publish_snapshot() -> void:
	if not is_network_active() or not multiplayer.is_server() or not is_instance_valid(game_root):
		return
	var snapshot: Dictionary = game_root._export_multiplayer_snapshot()
	for peer_id in multiplayer.get_peers():
		_receive_snapshot.rpc_id(peer_id, snapshot)

@rpc("any_peer", "call_remote", "reliable")
func request_action(action: String, payload: Dictionary = {}) -> void:
	if not multiplayer.is_server() or not is_instance_valid(game_root):
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id <= 1 or not multiplayer.get_peers().has(sender_id):
		return
	if not _is_allowed_action(action, payload):
		_set_status("Rejected an invalid co-op action.")
		return
	game_root._apply_network_action(action, payload)
	game_root._persist_game()
	publish_snapshot()

@rpc("authority", "call_remote", "reliable")
func _receive_snapshot(snapshot: Dictionary) -> void:
	if multiplayer.is_server() or not is_instance_valid(game_root):
		return
	if not _valid_snapshot(snapshot):
		_set_status("Host sent an invalid kingdom update; ignored.")
		return
	game_root._apply_multiplayer_snapshot(snapshot)

func _is_allowed_action(action: String, payload: Dictionary) -> bool:
	# All normal UI requests include the client's current selection. Validate it
	# before _apply_network_action can mutate shared selection state.
	if not payload.has("tile") or not payload.has("outpost"):
		return false
	if not (payload["tile"] is int) or not (payload["outpost"] is int):
		return false
	if int(payload["tile"]) < 0 or int(payload["tile"]) >= 9:
		return false
	if int(payload["outpost"]) < 0 or int(payload["outpost"]) >= 10:
		return false

	match action:
		"gather":
			return payload.get("resource", null) is String and payload.get("resource", "") in ["wood", "food", "stone", "gold"] and payload.get("amount", null) is int and int(payload.get("amount", 0)) in [15, 20, 25, 30]
		"set_stance":
			return payload.get("stance", null) is String and payload.get("stance", "") in ["Balanced", "Aggressive", "Defensive"]
		"claim_reward":
			return payload.get("reward_id", null) is String and payload.get("reward_id", "") in ["first_victory", "explorer", "keep_builder"]
		"claim_quest":
			return payload.get("quest_id", null) is String and payload.get("quest_id", "") in ["builder", "stronghold", "conqueror"]
		"research":
			return payload.get("type", null) is String and payload.get("type", "") in ["combat", "economy", "scouting"]
		"select_tile":
			return true
		"select_outpost":
			return true
		"build_farm", "build_mine", "build_lumber_camp", "build_quarry", "build_academy", "build_barracks", "upgrade_keep", "collect", "upgrade_building", "train_infantry", "train_archers", "train_cavalry", "scout", "attack", "explore", "practice", "train_hero", "upgrade_hero_skill", "claim_daily", "army_battle":
			return true
		_:
			return false

func _valid_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.has("battle_stance") and str(snapshot["battle_stance"]) not in ["Balanced", "Aggressive", "Defensive"]:
		return false
	# Validate optional persisted counters/timers before they can be applied and saved.
	var now_unix := int(Time.get_unix_time_from_system())
	var current_utc_day := int(floor(float(now_unix) / 86400.0))
	var numeric_ranges := {
		"day": [1, 1000000],
		"daily_reward_claim_day": [-1, current_utc_day],
		"daily_reward_streak": [0, 7],
		"explored_regions": [0, 1000000],
		"victories": [0, 1000000],
		"defeats": [0, 1000000],
		"practice_drills": [0, 20],
		"tutorial_step": [0, 4],
		"troop_training_finish_unix": [0, now_unix + 120],
		"keep_upgrade_finish_unix": [0, now_unix + 120],
		"building_upgrade_finish_unix": [0, now_unix + 120],
		"building_upgrade_tile": [-1, 8]
	}
	# Reject malformed scalar types before any int()/bool()/str() coercion.
	# Coercion can silently turn bad network data into valid-looking zeroes.
	var integer_fields := [
		"gold", "wood", "food", "stone", "guards", "infantry", "archers", "cavalry",
		"keep_level", "day", "daily_reward_claim_day", "daily_reward_streak", "enemy_level",
		"explored_regions", "victories", "defeats", "combat_research", "economy_research",
		"scouting_research", "practice_drills", "hero_level", "hero_xp", "hero_skill_level",
		"selected_tile", "selected_outpost", "keep_upgrade_finish_unix",
		"building_upgrade_finish_unix", "building_upgrade_tile", "tutorial_step",
		"troop_training_finish_unix", "queued_troop_count"
	]
	for key in integer_fields:
		if snapshot.has(key) and not (snapshot[key] is int):
			return false
	if snapshot.has("battle_stance") and not (snapshot["battle_stance"] is String):
		return false
	if snapshot.has("queued_troop_type") and not (snapshot["queued_troop_type"] is String):
		return false
	for key in numeric_ranges:
		if snapshot.has(key):
			if not (snapshot[key] is int) or int(snapshot[key]) < int(numeric_ranges[key][0]) or int(snapshot[key]) > int(numeric_ranges[key][1]):
				return false
	for key in ["sound_enabled", "music_enabled", "reward_first_victory_claimed", "reward_explorer_claimed", "reward_keep_claimed", "quest_builder_claimed", "quest_stronghold_claimed", "quest_conqueror_claimed"]:
		if snapshot.has(key) and not (snapshot[key] is bool):
			return false
	if snapshot.has("achievements"):
		if not (snapshot["achievements"] is Array or snapshot["achievements"] is PackedStringArray):
			return false
		for achievement in snapshot["achievements"]:
			if not (achievement is String):
				return false
	for key in ["gold", "wood", "food", "stone", "guards", "infantry", "archers", "cavalry", "keep_level", "hero_level", "tiles", "tile_levels", "outpost_defeated", "region_scouted"]:
		if not snapshot.has(key):
			return false
	for key in ["gold", "wood", "food", "stone"]:
		if int(snapshot[key]) < 0 or int(snapshot[key]) > 2000000000:
			return false
	for key in ["guards", "infantry", "archers", "cavalry"]:
		if int(snapshot[key]) < 0 or int(snapshot[key]) > 100000:
			return false
	if int(snapshot["guards"]) != int(snapshot["infantry"]) + int(snapshot["archers"]) + int(snapshot["cavalry"]):
		return false
	if int(snapshot["keep_level"]) < 1 or int(snapshot["keep_level"]) > 10 or int(snapshot["hero_level"]) < 1 or int(snapshot["hero_level"]) > 20:
		return false
	if snapshot.has("keep_upgrade_finish_unix") and int(snapshot["keep_upgrade_finish_unix"]) > 0 and int(snapshot["keep_level"]) >= 10:
		return false
	if snapshot.has("hero_xp") and (int(snapshot["hero_xp"]) < 0 or int(snapshot["hero_xp"]) > 1000000):
		return false
	if snapshot.has("hero_skill_level") and (int(snapshot["hero_skill_level"]) < 1 or int(snapshot["hero_skill_level"]) > 5):
		return false
	if snapshot.has("enemy_level") and (int(snapshot["enemy_level"]) < 1 or int(snapshot["enemy_level"]) > 100000):
		return false
	if snapshot.has("queued_troop_count"):
		var queued_count := int(snapshot["queued_troop_count"])
		var queued_type := str(snapshot.get("queued_troop_type", ""))
		if queued_count < 0 or queued_count > 5 or queued_type not in ["", "infantry", "archer", "cavalry"]:
			return false
		if (queued_count == 0) != (queued_type == ""):
			return false
		if queued_count > 0 and (not snapshot.has("troop_training_finish_unix") or int(snapshot["troop_training_finish_unix"]) <= 0):
			return false
	for key in ["combat_research", "economy_research", "scouting_research"]:
		if snapshot.has(key) and (int(snapshot[key]) < 0 or int(snapshot[key]) > 5):
			return false
	if not (snapshot["tiles"] is Array) or snapshot["tiles"].size() != 9:
		return false
	if not (snapshot["tile_levels"] is Array) or snapshot["tile_levels"].size() != 9:
		return false
	for building in snapshot["tiles"]:
		if not (building is String):
			return false
	for level in snapshot["tile_levels"]:
		if not (level is int):
			return false
	if snapshot.has("building_upgrade_finish_unix") and int(snapshot["building_upgrade_finish_unix"]) > 0:
		if not snapshot.has("building_upgrade_tile"):
			return false
		var upgrade_tile := int(snapshot["building_upgrade_tile"])
		if upgrade_tile < 0 or upgrade_tile >= 9:
			return false
		if str(snapshot["tiles"][upgrade_tile]) not in ["Farm", "Mine", "Barracks", "Lumber Camp", "Quarry", "Academy"]:
			return false
		if int(snapshot["tile_levels"][upgrade_tile]) >= 5:
			return false
	if not (snapshot["outpost_defeated"] is Array) or snapshot["outpost_defeated"].size() != 10:
		return false
	if not (snapshot["region_scouted"] is Array) or snapshot["region_scouted"].size() != 10:
		return false
	for value in snapshot["outpost_defeated"]:
		if not (value is int):
			return false
	for value in snapshot["region_scouted"]:
		if not (value is int):
			return false
	var valid_buildings := ["Empty", "Farm", "Mine", "Keep", "Lumber Camp", "Quarry", "Academy", "Barracks"]
	for tile in snapshot["tiles"]:
		if str(tile) not in valid_buildings:
			return false
	if snapshot["tiles"].count("Keep") != 1 or snapshot["tiles"].count("Academy") > 1 or str(snapshot["tiles"][4]) != "Keep":
		return false
	var barracks_capacity := 0
	for i in range(9):
		if str(snapshot["tiles"][i]) == "Barracks":
			barracks_capacity = maxi(barracks_capacity, int(snapshot["tile_levels"][i]) * 5)
	if int(snapshot["guards"]) > barracks_capacity:
		return false
	if snapshot.has("queued_troop_count") and int(snapshot["guards"]) + int(snapshot["queued_troop_count"]) > barracks_capacity:
		return false
	for level in snapshot["tile_levels"]:
		if int(level) < 1 or int(level) > 5:
			return false
	for value in snapshot["outpost_defeated"]:
		if int(value) not in [0, 1]:
			return false
	for value in snapshot["region_scouted"]:
		if int(value) not in [0, 1]:
			return false
	for i in range(1, 10):
		if int(snapshot["outpost_defeated"][i - 1]) != 1 and (int(snapshot["outpost_defeated"][i]) == 1 or int(snapshot["region_scouted"][i]) == 1):
			return false
	if int(snapshot.get("selected_tile", 4)) < 0 or int(snapshot.get("selected_tile", 4)) > 8:
		return false
	if int(snapshot.get("selected_outpost", 0)) < 0 or int(snapshot.get("selected_outpost", 0)) > 9:
		return false
	return true

func _on_peer_connected(peer_id: int) -> void:
	_set_status("Player %d joined the LAN kingdom." % peer_id)
	if multiplayer.is_server():
		call_deferred("_send_snapshot_to_peer", peer_id)

func _send_snapshot_to_peer(peer_id: int) -> void:
	if multiplayer.is_server() and multiplayer.get_peers().has(peer_id) and is_instance_valid(game_root):
		_receive_snapshot.rpc_id(peer_id, game_root._export_multiplayer_snapshot())

func _on_peer_disconnected(peer_id: int) -> void:
	_set_status("Player %d left the LAN kingdom." % peer_id)

func _on_connected_to_server() -> void:
	_set_status("Connected to the host. Shared kingdom state is syncing.")

func _on_connection_failed() -> void:
	disconnect_game()
	_set_status("Connection failed. Check both phones are on the same Wi-Fi and the host IP is correct.")

func _on_server_disconnected() -> void:
	disconnect_game()
	_set_status("Host disconnected. Your local kingdom remains available.")

func _set_status(message: String) -> void:
	status_message = message
	status_changed.emit(message)
