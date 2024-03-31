extends Node

enum CombatState { IDLE, PLAYER_TURN, ENEMY_TURN }
var combat_state = CombatState.IDLE
var player
var enemy

signal combat_started
signal combat_ended
signal turn_transition(from, to)

func _ready():
	# It's safe to get nodes in the scene tree within _ready, 
	# as it is called when the node is added to the active scene.
	player = get_parent().get_node("Player")
	enemy = get_parent().get_node("Enemy")

func initialize_combat():
	# Position the player and enemy
	player.position = Vector2(100, 200)  # Adjust these values as needed
	enemy.position = Vector2(300, 200)  # Adjust these values as needed

	# Reset health
	player.health = player.max_health
	enemy.health = enemy.max_health

	# Reset any other necessary states


func start_combat():
	initialize_combat()
	combat_state = CombatState.PLAYER_TURN
	emit_signal("combat_started")
	emit_signal("player_turn")
	player.draw_cards(player.starting_hand_size)

func _on_player_turn():
	if combat_state != CombatState.PLAYER_TURN:
		return
	player.enable_card_selection(true)

func _on_enemy_turn():
	if combat_state != CombatState.ENEMY_TURN:
		return
	player.enable_card_selection(false)
	enemy.take_action()  # Implement this method in the enemy's script

func _on_player_end_turn():
	if combat_state == CombatState.PLAYER_TURN:
		combat_state = CombatState.ENEMY_TURN
		emit_signal("turn_transition", "player", "enemy")
		emit_signal("enemy_turn")

func _on_enemy_action_complete():
	if combat_state == CombatState.ENEMY_TURN:
		combat_state = CombatState.PLAYER_TURN
		emit_signal("turn_transition", "enemy", "player")
		emit_signal("player_turn")

func end_combat():
	combat_state = CombatState.IDLE
	emit_signal("combat_ended")
	player.discard_hand()
	cleanup_combat()

func cleanup_combat():
	# Remove temporary effects
	player.remove_temporary_effects()
	enemy.remove_temporary_effects()

	# Update game state or reset variables if necessary
func deal_damage_to_player(damage: int):
	# Access the player node and reduce health.
	var player = get_node("/root/World/Player") # Adjust the path to the player node
	player.health -= damage
	if player.health <= 0:
		# Handle player defeat if needed.
		player.emit_signal("defeated")

# In the Player script, emit "end_turn" signal when the player ends their turn
# In the Enemy script, emit "enemy_action_complete" signal when the enemy completes their action
