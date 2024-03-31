extends Node

var card_manager
enum CombatState { PLAYER_TURN, ENEMY_TURN }
var combat_state = CombatState.PLAYER_TURN
var player
var enemy
var turn_number = 1
@onready var music = $"../Music"

enum EnemyType {
	SLIME,
	GHOUL,
	GOLEM
}


var attacks = {
	EnemyType.SLIME: [{"name": "Acid Splash", "damage": 5}],
	EnemyType.GHOUL: [{"name": "Bite", "damage": 10}],
	EnemyType.GOLEM: [{"name": "Rock Throw", "damage": 15}]
}

var animation_player: AnimationPlayer
var current_enemy = null

# Dictionary to store status effects and their durations
var status_effects = {}

func _ready():
	animation_player = get_node("AnimationPlayer")
	card_manager = get_parent().get_node("CardManager")

func _process(delta):
	if Input.is_action_just_pressed("end_turn") and combat_state == CombatState.PLAYER_TURN:
		start_enemy_turn()

func start_combat_with_enemy(enemyTypeStr: String):
	music.play()
	# Set can_move to false for all enemies
	GlobalVars.in_combat = true

	var enemyType = match_enemy_type(enemyTypeStr)
	if enemyType == null:
		print("Error: Invalid enemy type string")
		return

	# Start combat with the specified enemy type
	print("Combat started with", enemyTypeStr)
	if combat_state != CombatState.PLAYER_TURN:
		return
	
	combat_state = CombatState.ENEMY_TURN
	current_enemy = enemyType



func match_enemy_type(enemyTypeStr: String) -> EnemyType:
	match enemyTypeStr:
		"SLIME":
			return EnemyType.SLIME
		"GHOUL":
			return EnemyType.GHOUL
		"GOLEM":
			return EnemyType.GOLEM
		_:
			return EnemyType.SLIME

func start_enemy_turn():
	match current_enemy:
		EnemyType.SLIME:
			var attack = attacks[EnemyType.SLIME][randi() % attacks[EnemyType.SLIME].size()]
			apply_damage_to_player(attack["damage"])
		EnemyType.GHOUL:
			var attack = attacks[EnemyType.GHOUL][randi() % attacks[EnemyType.GHOUL].size()]
			apply_damage_to_player(attack["damage"])
		EnemyType.GOLEM:
			var attack = attacks[EnemyType.GOLEM][randi() % attacks[EnemyType.GOLEM].size()]
			apply_damage_to_player(attack["damage"])
	
	turn_number += 1
	start_player_turn()
	
func start_player_turn():
	card_manager.handle_start_of_turn()

func apply_damage_to_player(damage):
	player.health -= damage
	if player.health <= 0:
		player.health = 0
		emit_signal("player_defeated")
