extends Node

# Combat state management
enum CombatState {
	NOT_IN_COMBAT,
	IN_COMBAT,
	PLAYER_TURN,
	ENEMY_TURN,
	COMBAT_ENDED
}

# Signals for combat events
signal combat_started(enemy_type: String)
signal combat_ended(victory: bool)
signal player_turn_started
signal enemy_turn_started
signal damage_dealt(amount: int, target: String)
signal status_applied(status: Dictionary, target: String)

# Current state tracking
var combat_state: CombatState = CombatState.NOT_IN_COMBAT
var current_enemy: Node = null
var current_enemy_type: String = ""
var turn_count: int = 0

# Node references
@onready var player = get_parent().get_node("Player")

# Combat configuration
const PLAYER_TURN_FIRST = true
const MAX_TURNS = 50

func _ready() -> void:
	if not player:
		push_error("CombatHandler: Player node not found")
		return
	print_debug("CombatHandler initialized successfully")
func start_combat_with_enemy(enemy_type: String) -> void:
	if combat_state != CombatState.NOT_IN_COMBAT:
		push_warning("CombatHandler: Combat already in progress")
		return
	
	print_debug("Starting combat with enemy type: ", enemy_type)
	# Find the enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.enum_to_string(enemy.enemy_type) == enemy_type:
			current_enemy = enemy
			break
	
	if not current_enemy:
		push_error("CombatHandler: Enemy not found for type: " + enemy_type)
		return
	
	# Initialize combat
	combat_state = CombatState.IN_COMBAT
	current_enemy_type = enemy_type
	turn_count = 0
	GlobalVars.in_combat = true
	
	emit_signal("combat_started", enemy_type)
	
	# Notify entities
	if is_instance_valid(current_enemy):
		current_enemy.handle_combat_start()
	if is_instance_valid(player):
		player.handle_combat_start()
		# Make sure cards are playable
		var card_manager = get_parent().get_node_or_null("CardManager")
		if card_manager:
			card_manager.handle_combat_start()
	
	# Start first turn
	if PLAYER_TURN_FIRST:
		start_player_turn()
	else:
		start_enemy_turn()

func start_player_turn() -> void:
	if combat_state != CombatState.IN_COMBAT:
		return
	
	print_debug("Starting player turn")
	combat_state = CombatState.PLAYER_TURN
	turn_count += 1
	
	if turn_count > MAX_TURNS:
		push_warning("CombatHandler: Maximum turn limit reached")
		end_combat()
		return
	
	emit_signal("player_turn_started")
	if is_instance_valid(player):
		player.handle_turn_start()
		# Make sure cards are enabled
		var card_manager = get_parent().get_node_or_null("CardManager")
		if card_manager:
			card_manager.handle_turn_start()
			
			
func apply_card_effect_to_enemy(card: Node) -> void:
	if not is_instance_valid(current_enemy):
		push_error("CombatHandler: Cannot apply card effect - no current enemy")
		return
	
	print_debug("Applying card effect: ", card.name if card.has_method("get_name") else "Unknown card")
	if "immediate_effect" in card:
		_process_immediate_effect(card.immediate_effect)

func damage_enemy(effect: Dictionary) -> void:
	if not is_instance_valid(current_enemy):
		push_error("CombatHandler: Cannot damage enemy - no current enemy")
		return
	
	var damage = effect.get("amount", 0)
	print_debug("Processing damage effect: ", effect)
	if damage > 0:
		deal_damage_to_enemy(damage)

func apply_status_to_enemy(status: Dictionary) -> void:
	if not is_instance_valid(current_enemy):
		push_error("CombatHandler: Cannot apply status - no current enemy")
		return
	
	print_debug("Applying status effect to enemy: ", status)
	apply_status_effect(status, "enemy")

func move_player(effect: Dictionary) -> void:
	if not is_instance_valid(player):
		push_error("CombatHandler: Cannot move player - player not found")
		return
	
	print_debug("Processing move effect: ", effect)
	if player.has_method("move_to"):
		var target_position = effect.get("target_position")
		if target_position:
			player.move_to(target_position)

func end_combat(player_victory: bool = false) -> void:
	print_debug("Ending combat. Player victory: ", player_victory)
	
	if combat_state == CombatState.NOT_IN_COMBAT:
		return
	
	combat_state = CombatState.COMBAT_ENDED
	GlobalVars.in_combat = false
	
	if is_instance_valid(current_enemy):
		current_enemy.handle_combat_end()
	if is_instance_valid(player):
		player.handle_combat_end()
	
	emit_signal("combat_ended", player_victory)
	
	combat_state = CombatState.NOT_IN_COMBAT
	current_enemy = null
	current_enemy_type = ""
	turn_count = 0
	print_debug("Combat ended successfully")

func start_enemy_turn() -> void:
	if combat_state != CombatState.IN_COMBAT:
		return
	
	print_debug("Starting enemy turn ", turn_count)
	combat_state = CombatState.ENEMY_TURN
	
	emit_signal("enemy_turn_started")
	if is_instance_valid(current_enemy):
		current_enemy.take_action()

func deal_damage_to_player(damage: int, attack_type: String = "") -> void:
	if not is_instance_valid(player):
		push_error("CombatHandler: Cannot deal damage - player not found")
		return
	
	print_debug("Dealing ", damage, " damage to player with attack type: ", attack_type)
	var final_damage = calculate_damage(damage, attack_type, player)
	player.take_damage(final_damage)
	emit_signal("damage_dealt", final_damage, "player")
	
	if player.health <= 0:
		print_debug("Player defeated")
		end_combat(false)

func deal_damage_to_enemy(damage: int, attack_type: String = "") -> void:
	if not is_instance_valid(current_enemy):
		push_error("CombatHandler: Cannot deal damage - no current enemy")
		return
	
	print_debug("Dealing ", damage, " damage to enemy with attack type: ", attack_type)
	var final_damage = calculate_damage(damage, attack_type, current_enemy)
	current_enemy.take_damage(final_damage)
	emit_signal("damage_dealt", final_damage, "enemy")
	
	if current_enemy.health <= 0:
		print_debug("Enemy defeated")
		end_combat(true)

func calculate_damage(base_damage: int, attack_type: String, target: Node) -> int:
	var final_damage = base_damage
	
	if target.has_method("get_status_effects"):
		var statuses = target.get_status_effects()
		for status in statuses:
			if "damage_modifier" in status:
				final_damage = final_damage * status.damage_modifier
				print_debug("Damage modified by status effect: ", final_damage)
	
	return int(round(final_damage))

func _process_immediate_effect(effect: Dictionary) -> void:
	print_debug("Processing immediate effect: ", effect)
	match effect.get("type"):
		"damage":
			deal_damage_to_enemy(effect.get("amount", 0))
		"status":
			apply_status_effect(effect.get("status", {}), "enemy")
		"heal":
			if is_instance_valid(player):
				player.heal(effect.get("amount", 0))

func apply_status_effect(status: Dictionary, target: String) -> void:
	var target_node = null
	
	match target:
		"player":
			target_node = player
		"enemy":
			target_node = current_enemy
	
	if not is_instance_valid(target_node):
		push_error("CombatHandler: Cannot apply status - target not found: " + target)
		return
	
	print_debug("Applying status effect to ", target, ": ", status)
	if target_node.has_method("apply_status"):
		target_node.apply_status(status)
		emit_signal("status_applied", status, target)

func end_turn() -> void:
	print_debug("Ending turn in state: ", combat_state)
	match combat_state:
		CombatState.PLAYER_TURN:
			combat_state = CombatState.IN_COMBAT
			start_enemy_turn()
		CombatState.ENEMY_TURN:
			combat_state = CombatState.IN_COMBAT
			start_player_turn()

func is_in_combat() -> bool:
	return combat_state != CombatState.NOT_IN_COMBAT

func get_current_enemy_type() -> String:
	return current_enemy_type
