class_name KingdomCombatDirector
extends RefCounted

const TROOP_POWER := {"infantry": 10, "archer": 14, "cavalry": 18}

static func resolve_outpost(infantry: int, archers: int, cavalry: int, hero_power: int, combat_research: int, drills: int, keep_level: int, barracks_level: int, threat: int, outpost_index: int, scouted: bool, stance: String = "Balanced") -> Dictionary:
	var total_troops := maxi(0, infantry) + maxi(0, archers) + maxi(0, cavalry)
	var troop_power := maxi(0, infantry) * TROOP_POWER["infantry"] + maxi(0, archers) * TROOP_POWER["archer"] + maxi(0, cavalry) * TROOP_POWER["cavalry"]
	var research_bonus := total_troops * clampi(combat_research, 0, 5) * 2
	var kingdom_power := troop_power + maxi(0, hero_power) + maxi(0, drills) + clampi(keep_level, 1, 10) * 3 + clampi(barracks_level, 0, 5) * 4 + research_bonus
	var trait_id := posmod(outpost_index, 3)
	var trait_name: String = "Warlord's Citadel" if outpost_index >= 9 else ["Fortified Hold", "Longbow Nest", "Mounted Raiders"][trait_id]
	var tactical_bonus := 0
	match trait_id:
		0:
			# Fortified infantry is countered by ranged units; cavalry struggles against the wall.
			tactical_bonus = maxi(0, archers) * 4 - maxi(0, cavalry) * 2
		1:
			# Longbow formations are vulnerable to a fast cavalry charge.
			tactical_bonus = maxi(0, cavalry) * 4 - maxi(0, infantry) * 2
		2:
			# Mounted raiders can be stopped by a disciplined infantry line.
			tactical_bonus = maxi(0, infantry) * 4 - maxi(0, archers) * 2
	var effective_power := maxi(1, kingdom_power + tactical_bonus)
	var enemy_power := 20 + clampi(threat, 1, 10) * 18 + maxi(0, outpost_index) * 5
	if trait_id == 0:
		enemy_power += 12
	elif trait_id == 1:
		enemy_power += 8
	elif trait_id == 2:
		enemy_power += 10
	if outpost_index >= 9:
		enemy_power += 40
	var normalized_stance := stance if stance in ["Balanced", "Aggressive", "Defensive"] else "Balanced"
	var stance_chance_bonus := 0
	var stance_loss_multiplier := 1.0
	match normalized_stance:
		"Aggressive":
			stance_chance_bonus = 8
			stance_loss_multiplier = 1.25
		"Defensive":
			stance_chance_bonus = -5
			stance_loss_multiplier = 0.65
	var chance := clampi(50 + int(round(float(effective_power - enemy_power) * 0.15)) + (12 if scouted else -8) + stance_chance_bonus, 8, 92)
	var loss_ratio := clampf(float(enemy_power) / float(effective_power + enemy_power), 0.08, 0.78)
	var win_losses := clampi(int(ceil(float(total_troops) * loss_ratio * 0.42 * stance_loss_multiplier)), 0, total_troops)
	var loss_losses := clampi(int(ceil(float(total_troops) * loss_ratio * 0.95 * stance_loss_multiplier)), 1 if total_troops > 0 else 0, total_troops)
	return {"chance": chance, "enemy_power": enemy_power, "kingdom_power": effective_power, "trait": trait_name, "stance": normalized_stance, "win_losses": win_losses, "loss_losses": loss_losses}

static func resolve_enemy_army(infantry: int, archers: int, cavalry: int, hero_power: int, combat_research: int, drills: int, keep_level: int, barracks_level: int, enemy_level: int, stance: String = "Balanced") -> Dictionary:
	var total_troops := maxi(0, infantry) + maxi(0, archers) + maxi(0, cavalry)
	var troop_power := maxi(0, infantry) * TROOP_POWER["infantry"] + maxi(0, archers) * TROOP_POWER["archer"] + maxi(0, cavalry) * TROOP_POWER["cavalry"]
	var kingdom_power := troop_power + maxi(0, hero_power) + maxi(0, drills) + clampi(keep_level, 1, 10) * 3 + clampi(barracks_level, 0, 5) * 4 + total_troops * clampi(combat_research, 0, 5) * 2
	var level := clampi(enemy_level, 1, 100000)
	var enemy_power := 35 + level * 18
	var style_id := posmod(level - 1, 3)
	var enemy_style: String = ["Shield Wall", "Bow Line", "Cavalry Wing"][style_id]
	var counter_bonus := 0
	match style_id:
		0:
			counter_bonus = maxi(0, archers) * 4 - maxi(0, cavalry) * 2
		1:
			counter_bonus = maxi(0, cavalry) * 4 - maxi(0, infantry) * 2
		2:
			counter_bonus = maxi(0, infantry) * 4 - maxi(0, archers) * 2
	kingdom_power = maxi(1, kingdom_power + counter_bonus)
	var normalized_stance := stance if stance in ["Balanced", "Aggressive", "Defensive"] else "Balanced"
	var stance_chance_bonus := 0
	var stance_loss_multiplier := 1.0
	match normalized_stance:
		"Aggressive":
			stance_chance_bonus = 8
			stance_loss_multiplier = 1.25
		"Defensive":
			stance_chance_bonus = -5
			stance_loss_multiplier = 0.65
	var chance := clampi(50 + int(round(float(kingdom_power - enemy_power) * 0.8)) + stance_chance_bonus, 5, 100)
	var loss_ratio := clampf(float(enemy_power) / float(kingdom_power + enemy_power), 0.08, 0.82)
	return {"chance": chance, "enemy_power": enemy_power, "kingdom_power": kingdom_power, "trait": enemy_style, "stance": normalized_stance, "win_losses": clampi(int(ceil(float(total_troops) * loss_ratio * 0.38 * stance_loss_multiplier)), 0, total_troops), "loss_losses": clampi(int(ceil(float(total_troops) * loss_ratio * 0.9 * stance_loss_multiplier)), 1 if total_troops > 0 else 0, total_troops)}
