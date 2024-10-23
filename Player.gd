extends Node3D

# Movement Constants
const MOVE_SPEED: float = 10.0
const ROTATION_SPEED: float = 20.0
const ORIENTATION_MAP = {
	0: "north",
	1: "east",
	2: "south",
	3: "west"
}
var current_enemy: Node3D = null  # Add this line

# Node References
@onready var ray_forward: RayCast3D = $RayForward
@onready var ray_back: RayCast3D = $RayBack
@onready var ray_left: RayCast3D = $RayLeft
@onready var ray_right: RayCast3D = $RayRight
@onready var camera: Camera3D = $Control/SubViewportContainer/SubViewport/Camera3D
@onready var turn_timer: Timer = $TurnTimer
@onready var playerAudioPlayer: AudioStreamPlayer3D = $Control/SubViewportContainer/SubViewport/Camera3D/playerAudioPlayer
@onready var healthBar: TextureProgressBar = $Control/ProgressBar
@onready var manaBar: TextureProgressBar = $Control/Mana
@onready var manaBarLabel: Label = $Control/Mana/Label
@onready var pause_popup = $PausePopup

# Add this near the top of your script with other constants
const COMBAT_CONFIG = {
	"distance_from_enemy": 3.0,    # How far to stay from enemy
	"combat_height": 0.5,          # Height during combat
	"transition_duration": 1.0,    # How long the transition takes
	"camera_fov_combat": 70.0,     # FOV during combat
	"camera_fov_normal": 75.0,     # Normal FOV
	"position_offset": Vector3(0, 0.5, -2),  # Fine-tune combat position
	"ease_type": 0.5              # Easing for smooth motion
}

# Add this under your Game State section with other state variables
# Combat Transition State
var combat_position: Vector3 = Vector3.ZERO
var combat_rotation: float = 0.0
var original_position: Vector3 = Vector3.ZERO
var original_rotation: float = 0.0
var is_transitioning: bool = false
var transition_time: float = 0.0

# Remove the redundant TRANSITION_DURATION variable since it's in COMBAT_CONFIG
# Use COMBAT_CONFIG.transition_duration directly in your code instead

# Add this helper function to keep the code clean
func get_combat_config(key: String, default_value = null):
	return COMBAT_CONFIG.get(key, default_value)

# Combat UI reference
var combat_ui: Control

# Character Stats
var health: int = 10:
	set(value):
		health = clamp(value, 0, max_health)
		if healthBar:
			healthBar.value = health
		if health <= 0:
			handle_death()

var max_health: int = 10
var mana: int = 5:
	set(value):
		mana = clamp(value, 0, max_mana)
		if manaBar:
			manaBar.value = mana
			manaBarLabel.text = str(mana)

var max_mana: int = 5
var current_statuses: Array = []

# Movement State
var target_position: Vector3
var target_rotation_degrees: float = 0.0
var current_rotation_degrees: float = 0.0
var is_turning: bool = false
var turn_direction: int = 0
var can_move: bool = true
var orientation: int = 0
var grid_position: Vector2

# Game State
var is_paused: bool = false
var is_in_combat: bool = false
var combatHandler: Node

# Signals
signal combat_started
signal combat_ended
signal turn_ended
signal player_died
signal player_moved(new_position: Vector2)
signal player_rotated(new_orientation: String)


func _ready() -> void:
	_initialize_game_state()
	_connect_signals()
	_setup_initial_position()

func _initialize_game_state() -> void:
	print_debug("Initializing player...")
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize combat handler
	combatHandler = get_parent().get_node("CombatHandler")
	if not combatHandler:
		push_error("Player: CombatHandler not found")
	
	# Get CombatUI reference
	combat_ui = get_parent().get_node_or_null("CombatUI")
	if combat_ui:
		print_debug("CombatUI found and connected")
	else:
		push_error("CombatUI not found!")
	
	# Initialize stats
	health = max_health
	mana = max_mana
	
	print_debug("Player initialized with health: ", health, " mana: ", mana)

func _connect_signals() -> void:
	if combatHandler:
		if not combatHandler.combat_started.is_connected(handle_combat_start):
			combatHandler.combat_started.connect(handle_combat_start)
		if not combatHandler.combat_ended.is_connected(handle_combat_end):
			combatHandler.combat_ended.connect(handle_combat_end)
		if not turn_ended.is_connected(combatHandler.end_turn):
			turn_ended.connect(combatHandler.end_turn)
	
	if combat_ui:
		if combat_ui.has_signal("end_turn_pressed"):
			combat_ui.end_turn_pressed.connect(_on_end_turn_pressed)

func _setup_initial_position() -> void:
	target_position = global_transform.origin
	target_rotation_degrees = rotation_degrees.y
	current_rotation_degrees = rotation_degrees.y
	grid_position = Vector2(target_position.x, target_position.z)

func _process(delta: float) -> void:
	if is_paused:
		return
	
	_update_camera()
	
	if can_move and not GlobalVars.in_combat:
		_handle_movement_input()
	
	if not GlobalVars.in_combat:
		_handle_rotation_input()
	
	_update_position(delta)
	_update_rotation(delta)

# Combat Functions
func handle_combat_start(enemy_type: String = "") -> void:
	print_debug("Player entering combat with: ", enemy_type)
	is_in_combat = true
	can_move = false
	GlobalVars.in_combat = true
	
	if combat_ui:
		combat_ui.show_combat_ui()

func handle_combat_end() -> void:
	print_debug("Player exiting combat")
	is_in_combat = false
	can_move = true
	GlobalVars.in_combat = false
	
	if combat_ui:
		combat_ui.hide_combat_ui()

func handle_turn_start() -> void:
	print_debug("Player turn starting")
	mana = max_mana
	process_status_effects()
	
	if combat_ui:
		combat_ui.set_turn_indicator(true)

func handle_turn_end() -> void:
	print_debug("Player turn ending")
	
	if combat_ui:
		combat_ui.set_turn_indicator(false)

func _on_end_turn_pressed() -> void:
	print_debug("End turn triggered")
	
	if not GlobalVars.in_combat:
		push_warning("Cannot end turn - not in combat")
		return
		
	if not combatHandler:
		push_error("Player: Cannot end turn - CombatHandler not found")
		return
	
	if combatHandler.combat_state != combatHandler.CombatState.PLAYER_TURN:
		push_warning("Cannot end turn - not player's turn")
		return
	
	prints("Ending Turn - Emitting Signal")
	emit_signal("turn_ended")


# Update your _handle_combat_transition function to use the config
func _handle_combat_transition(delta: float) -> void:
	transition_time += delta
	var t = clamp(transition_time / get_combat_config("transition_duration"), 0.0, 1.0)
	
	# Use configured ease type
	var ease_t = ease(t, get_combat_config("ease_type"))
	
	# Lerp position and rotation
	global_transform.origin = global_transform.origin.lerp(combat_position, ease_t)
	rotation_degrees.y = lerp_angle(rotation_degrees.y, combat_rotation, ease_t)
	
	# Update camera
	_update_camera()
	
	# Check if transition is complete
	if t >= 1.0:
		is_transitioning = false
		print_debug("Combat transition complete")

# Update the combat position calculation in handle_combat_start
func _calculate_combat_position(enemy_pos: Vector3) -> void:
	var direction_to_enemy = (enemy_pos - global_transform.origin).normalized()
	direction_to_enemy.y = 0
	
	combat_position = enemy_pos - (direction_to_enemy * get_combat_config("distance_from_enemy"))
	combat_position.y = get_combat_config("combat_height")
	combat_position += get_combat_config("position_offset")
	
	combat_rotation = rad_to_deg(atan2(direction_to_enemy.x, direction_to_enemy.z))

# Add this function to your Player script
func _get_current_enemy() -> Node3D:
	if combatHandler and combatHandler.current_enemy:
		current_enemy = combatHandler.current_enemy
		return current_enemy
	
	# Fallback: find closest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var closest_enemy = enemies[0]
	var closest_distance = global_transform.origin.distance_to(closest_enemy.global_transform.origin)
	
	for enemy in enemies:
		var distance = global_transform.origin.distance_to(enemy.global_transform.origin)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	current_enemy = closest_enemy
	return closest_enemy
	
func _ensure_combat_nodes_active() -> void:
	# Make sure necessary nodes remain active during combat
	var combat_nodes = [combat_ui, $Control]
	for node in combat_nodes:
		if node:
			node.process_mode = Node.PROCESS_MODE_ALWAYS
			node.show()


func _update_camera() -> void:
	camera.rotation_degrees.y = rotation_degrees.y
	camera.position = position

func _handle_movement_input() -> void:
	var direction = Vector3.ZERO
	
	if Input.is_action_just_pressed("move_forward") and not ray_forward.is_colliding():
		direction -= camera.global_transform.basis.z
		playerAudioPlayer.play()
	elif Input.is_action_just_pressed("move_backward") and not ray_back.is_colliding():
		direction += camera.global_transform.basis.z
	elif Input.is_action_just_pressed("move_left") and not ray_left.is_colliding():
		direction -= camera.global_transform.basis.x
	elif Input.is_action_just_pressed("move_right") and not ray_right.is_colliding():
		direction += camera.global_transform.basis.x
	
	if direction != Vector3.ZERO:
		_move_to_next_cell(direction)

func _move_to_next_cell(direction: Vector3) -> void:
	direction = direction.normalized()
	target_position += direction.round()
	grid_position = Vector2(target_position.x, target_position.z)
	can_move = false
	$MovementCooldownTimer.start()
	emit_signal("player_moved", grid_position)

func _handle_rotation_input() -> void:
	if Input.is_action_just_pressed("turn_left"):
		start_turning(-1)
	elif Input.is_action_just_pressed("turn_right"):
		start_turning(1)
	elif Input.is_action_just_released("turn_left") or Input.is_action_just_released("turn_right"):
		stop_turning()

func _update_position(delta: float) -> void:
	global_transform.origin = global_transform.origin.lerp(target_position, MOVE_SPEED * delta)

func _update_rotation(delta: float) -> void:
	if is_turning and turn_timer.is_stopped():
		target_rotation_degrees += turn_direction * 90.0
		turn_timer.start()
	
	current_rotation_degrees = lerp(current_rotation_degrees, deg_to_rad(target_rotation_degrees), ROTATION_SPEED * delta)
	rotation_degrees.y = rad_to_deg(current_rotation_degrees)

# Combat Functions
func take_damage(amount: int) -> void:
	print_debug("Player taking damage: ", amount)
	health -= amount

func heal(amount: int) -> void:
	print_debug("Player healing: ", amount)
	health += amount

func handle_death() -> void:
	print_debug("Player died")
	emit_signal("player_died")
	if combatHandler:
		combatHandler.end_combat(false)

# Status Effect Functions
func apply_status(status: Dictionary) -> void:
	current_statuses.append(status)
	print_debug("Status applied to player: ", status)

func get_status_effects() -> Array:
	return current_statuses

func process_status_effects() -> void:
	var statuses_to_remove = []
	
	for status in current_statuses:
		if "duration" in status:
			status.duration -= 1
			if status.duration <= 0:
				statuses_to_remove.append(status)
		
		if "damage_per_turn" in status:
			take_damage(status.damage_per_turn)
	
	for status in statuses_to_remove:
		current_statuses.erase(status)

# Movement Functions
func start_turning(direction: int) -> void:
	is_turning = true
	turn_direction = -direction
	orientation = (orientation + direction) % 4
	target_rotation_degrees += turn_direction * 90.0
	turn_timer.start()
	emit_signal("player_rotated", get_orientation_str())

func stop_turning() -> void:
	is_turning = false
	turn_timer.stop()

func get_orientation_str() -> String:
	return ORIENTATION_MAP.get(orientation, "unknown")

# UI Functions
func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_popup.visible = is_paused

# Signal Handlers
func _on_movement_cooldown_timer_timeout() -> void:
	can_move = true

func _on_quit_button_pressed() -> void:
	get_tree().quit(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):  # Spacebar
		print_debug("\n=== BUTTON DEBUG CHECK ===")
		var end_turn_button = get_node_or_null("Control/EndTurn")
		if end_turn_button:
			print_debug("Button found:")
			print_debug("- Visible: ", end_turn_button.visible)
			print_debug("- Disabled: ", end_turn_button.disabled)
			print_debug("- Position: ", end_turn_button.global_position)
			print_debug("- Size: ", end_turn_button.size)
			print_debug("- Mouse Filter: ", end_turn_button.mouse_filter)
			print_debug("- Focus Mode: ", end_turn_button.focus_mode)
			
			# Test programmatic press
			print_debug("Triggering test press...")
			end_turn_button.emit_signal("pressed")
		else:
			push_error("Button not found in debug check")

func move_to(position: Vector3) -> void:
	target_position = position
	grid_position = Vector2(position.x, position.z)
	emit_signal("player_moved", grid_position)
