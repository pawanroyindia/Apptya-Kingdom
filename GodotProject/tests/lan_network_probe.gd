extends SceneTree

class ProbeKingdom:
	extends Node

	var gold := 300
	var battle_stance := "Balanced"
	var tiles: Array[String] = ["Empty", "Farm", "Empty", "Mine", "Keep", "Empty", "Lumber Camp", "Barracks", "Quarry"]
	var levels := PackedInt32Array([1, 1, 1, 1, 1, 1, 1, 1, 1])
	var defeated := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var scouted := PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	var network_session: Node

	func _export_multiplayer_snapshot() -> Dictionary:
		return {
			"gold": gold, "wood": 150, "food": 120, "stone": 80,
			"guards": 4, "infantry": 4, "archers": 0, "cavalry": 0,
			"keep_level": 1, "hero_level": 1, "battle_stance": battle_stance, "tiles": tiles.duplicate(),
			"tile_levels": Array(levels), "outpost_defeated": Array(defeated),
			"region_scouted": Array(scouted), "selected_tile": 4, "selected_outpost": 0
		}

	func _apply_network_action(action: String, payload: Dictionary) -> void:
		if action == "gather" and payload.get("resource", "") == "gold":
			gold += int(payload.get("amount", 0))
		elif action == "set_stance" and str(payload.get("stance", "")) in ["Balanced", "Aggressive", "Defensive"]:
			battle_stance = str(payload["stance"])

	func _apply_multiplayer_snapshot(snapshot: Dictionary) -> void:
		gold = int(snapshot.get("gold", gold))
		battle_stance = str(snapshot.get("battle_stance", battle_stance))

	func _persist_game() -> int:
		# Mirror the production main.gd contract: a successful host save publishes
		# local UI/timer changes, not just changes initiated by a guest RPC.
		if is_instance_valid(network_session) and network_session.is_network_active() and network_session.multiplayer.is_server():
			network_session.publish_snapshot()
		return OK

func _initialize() -> void:
	call_deferred("_run_probe")

func _run_probe() -> void:
	var args := OS.get_cmdline_user_args()
	var role := str(args[0]) if not args.is_empty() else ""
	var kingdom := ProbeKingdom.new()
	kingdom.name = "ProbeKingdom"
	root.add_child(kingdom)
	var session := preload("res://network_session.gd").new()
	session.name = "NetworkSession"
	kingdom.add_child(session)
	kingdom.network_session = session
	session.configure(kingdom)

	if role == "--host":
		var host_result: int = session.host_game()
		if host_result != OK:
			printerr("LAN_HOST_FAIL: could not create ENet server, error %d" % host_result)
			quit(1)
			return
		print("LAN_HOST_READY")
		for attempt in range(100):
			if kingdom.gold == 320 and kingdom.battle_stance == "Defensive":
				# Simulate a host-side UI/timer update after the guest's last action.
				kingdom.gold += 5
				kingdom._persist_game()
				await create_timer(0.8).timeout
				print("LAN_HOST_PASS: guest actions and host-side snapshot publication passed; gold=%d stance=%s" % [kingdom.gold, kingdom.battle_stance])
				quit(0)
				return
			await create_timer(0.1).timeout
		printerr("LAN_HOST_FAIL: no validated guest action received.")
		quit(1)
		return

	if role == "--client":
		var join_result: int = session.join_game("127.0.0.1")
		if join_result != OK:
			printerr("LAN_CLIENT_FAIL: could not create ENet client, error %d" % join_result)
			quit(1)
			return
		for attempt in range(60):
			if session.is_client_connected():
				break
			await create_timer(0.1).timeout
		if not session.is_client_connected():
			printerr("LAN_CLIENT_FAIL: timed out connecting to local host.")
			quit(1)
			return
		# Malformed client requests must be rejected without changing host state.
		session.request_host_action("gather", {"resource": "gold", "amount": 999, "tile": 4, "outpost": 0})
		session.request_host_action("gather", {"resource": "gold", "amount": 20, "tile": 99, "outpost": 0})
		session.request_host_action("unknown_action", {"tile": 4, "outpost": 0})
		# Valid actions still succeed after rejected requests.
		session.request_host_action("gather", {"resource": "gold", "amount": 20, "tile": 4, "outpost": 0})
		session.request_host_action("set_stance", {"stance": "Defensive", "tile": 4, "outpost": 0})
		var received_guest_action_snapshot := false
		for attempt in range(60):
			if kingdom.gold == 320 and kingdom.battle_stance == "Defensive":
				received_guest_action_snapshot = true
				break
			await create_timer(0.1).timeout
		if received_guest_action_snapshot:
			for attempt in range(60):
				if kingdom.gold == 325 and kingdom.battle_stance == "Defensive":
					print("LAN_CLIENT_PASS: received guest-action and host-local snapshots; gold=%d stance=%s" % [kingdom.gold, kingdom.battle_stance])
					session.disconnect_game()
					quit(0)
					return
				await create_timer(0.1).timeout
		printerr("LAN_CLIENT_FAIL: did not receive both guest-action and host-local snapshots.")
		session.disconnect_game()
		quit(1)
		return

	printerr("LAN_PROBE_FAIL: expected --host or --client argument.")
	quit(2)
