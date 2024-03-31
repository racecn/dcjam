extends Node

var card_manager
enum CombatState { NOT_IN_COMBAT, PLAYER_TURN, ENEMY_TURN }
var combat_state = CombatState.NOT_IN_COMBAT
var player
var enemy
var turn_number = 1
@onready var music = $"../Music"
@onready var slime_attack = $slimeAttack

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
var end_turn_button

# Dictionary to store status effects and their durations
var status_effects = {}

func handle_die():
	#player died
	get_tree().quit(0)

func _ready():
	animation_player = get_node("AnimationPlayer")
	card_manager = get_parent().get_node("CardManager")
	player = get_parent().get_node("Player")
	end_turn_button = player.get_node("Control/EndTurn")

func _input(event):
	if event.is_action_pressed("end_turn") and combat_state == CombatState.PLAYER_TURN:
		print("end turn")
		start_enemy_turn()

func start_combat_with_enemy(enemyTypeStr: String):
	combat_state = CombatState.PLAYER_TURN
	music.play()
	# Set can_move to false for all enemies
	GlobalVars.in_combat = true

	var enemyType = match_enemy_type(enemyTypeStr)
	if enemyType == null:
		print("Error: Invalid enemy type string")
		return

	# Start combat with the specified enemy type
	print("Combat started with", enemyTypeStr)
	current_enemy = enemyType
	
	start_player_turn()



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
			slime_attack.play()
			apply_damage_to_player(attack["damage"])
		EnemyType.GHOUL:
			var attack = attacks[EnemyType.GHOUL][randi() % attacks[EnemyType.GHOUL].size()]
			apply_damage_to_player(attack["damage"])
		EnemyType.GOLEM:
			var attack = attacks[EnemyType.GOLEM][randi() % attacks[EnemyType.GOLEM].size()]
			apply_damage_to_player(attack["damage"])
	
	
	if player.health <= 0:
		handle_die()
	
	turn_number += 1
	start_player_turn()
	
func start_player_turn():
	player.mana = player.max_mana
	card_manager.handle_start_of_turn()

func apply_damage_to_player(damage):
	player.health -= damage
	if player.health <= 0:
		player.health = 0
		emit_signal("player_defeated")

func damage_enemy(effect):
	var dmg = effect["value"]
	enemy.health -= dmg

func move_player(effect):
	
	var dir = effect["direction"]
	var dis = int(effect["distance"])
	print( "dir, ", dir , " dis ", dis)

func apply_card_effect_to_enemy(card):
	#based on the effect, apply appropraite for theduration
	pass
