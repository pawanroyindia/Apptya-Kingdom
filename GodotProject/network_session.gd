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
	match action:
		"gather":
			return str(payload.get("resource", "")) in ["wood", "food", "stone", "gold"] and int(payload.get("amount", 0)) in [15, 20, 25, 30]
		"build_farm", "build_mine", "build_lumber_camp", "build_quarry", "build_academy", "build_barracks", "upgrade_keep", "collect", "upgrade_building", "train_infantry", "train_archers", "train_cavalry", "scout", "attack", "explore", "practice", "train_hero", "upgrade_hero_skill", "claim_daily", "army_battle":
			return true
		"claim_reward":
			return str(payload.get("reward_id", "")) in ["first_victory", "explorer", "keep_builder"]
		"claim_quest":
			return str(payload.get("quest_id", "")) in ["builder", "stronghold", "conqueror"]
		"research":
			return str(payload.get("type", "")) in ["combat", "economy", "scouting"]
		"select_tile":
			return int(payload.get("tile", -1)) >= 0 and int(payload.get("tile", -1)) < 9
		"select_outpost":
			return int(payload.get("outpost", -1)) >= 0 and int(payload.get("outpost", -1)) < 10
		_:
			return false

func _valid_snapshot(snapshot: Dictionary) -> bool:
	for key in ["gold", "wood", "food", "stone", "guards", "infantry", "archers", "cavalry", "keep_level", "hero_level", "tiles", "tile_levels", "outpost_defeated", "region_scouted"]:
		if not snapshot.has(key):
			return false
	for key in ["gold", "wood", "food", "stone", "guards", "infantry", "archers", "cavalry"]:
		if int(snapshot[key]) < 0 or int(snapshot[key]) > 2000000000:
			return false
	if int(snapshot["keep_level"]) < 1 or int(snapshot["keep_level"]) > 10 or int(snapshot["hero_level"]) < 1 or int(snapshot["hero_level"]) > 20:
		return false
	if not (snapshot["tiles"] is Array) or snapshot["tiles"].size() != 9:
		return false
	if not (snapshot["tile_levels"] is Array) or snapshot["tile_levels"].size() != 9:
		return false
	if not (snapshot["outpost_defeated"] is Array) or snapshot["outpost_defeated"].size() != 10:
		return false
	if not (snapshot["region_scouted"] is Array) or snapshot["region_scouted"].size() != 10:
		return false
	var valid_buildings := ["Empty", "Farm", "Mine", "Keep", "Lumber Camp", "Quarry", "Academy", "Barracks"]
	for tile in snapshot["tiles"]:
		if str(tile) not in valid_buildings:
			return false
	if snapshot["tiles"].count("Keep") != 1 or snapshot["tiles"].count("Academy") > 1:
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
