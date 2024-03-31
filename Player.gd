extends Node3D

# Movement speed (units per second)
var speed = 10.0
# Turn speed (degrees per second)
var rotation_speed = 20.0
# Current target position for snapping
var target_position: Vector3
# Current target rotation for snapping (in degrees)
var target_rotation_degrees: float = 0.0
# Current rotation (in degrees)
var current_rotation_degrees: float = 0.0

# Turning control variables
var is_turning = false
var turn_direction = 0
var can_move = true
var is_paused = false
var is_in_combat = false
var health = 10
var maxHealth = 10
var mana = 5
var maxMana = 5
var orientation: int = 0  # 0: north, 1: east, 2: south, 3: west
var grid_position: Vector2  # Grid position in 2D space

# Raycasts
@onready var ray_forward: RayCast3D = $RayForward
@onready var ray_back: RayCast3D = $RayBack
@onready var ray_left: RayCast3D = $RayLeft
@onready var ray_right: RayCast3D = $RayRight
@onready var pause_popup = $PausePopup  # Adjust the path to your pause popup node

# Camera
@onready var camera: Camera3D = $Control/SubViewportContainer/SubViewport/Camera3D
# Timer for continuous turning
@onready var turn_timer: Timer = $TurnTimer
# Audio
@onready var musicPlayer: AudioStreamPlayer3D = $Control/SubViewportContainer/SubViewport/Camera3D/MusicPlayer
@onready var playerAudioPlayer: AudioStreamPlayer3D = $Control/SubViewportContainer/SubViewport/Camera3D/playerAudioPlayer

@onready var healthBar: TextureProgressBar = $Control/ProgressBar
@onready var manaBar: TextureProgressBar = $Control/Mana

# Combat
signal combat_started
signal combat_ended

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	target_position = global_transform.origin
	target_rotation_degrees = rotation_degrees.y
	current_rotation_degrees = rotation_degrees.y
	grid_position = Vector2(target_position.x, target_position.z)  # Initialize grid_position

	var enemy = get_node("Enemy")
	if enemy:
		enemy.enter_combat.connect("enter_combat")
		print("COMBAT MODE")
	else:
		print("Enemy node not found")

func _process(delta):
	manaBar.value = mana
	healthBar.value = health
	if is_paused:
		return
	camera.rotation_degrees.y = rotation_degrees.y
	camera.position = position

	if can_move and not is_in_combat:
		var direction = Vector3.ZERO

		# Get input for movement
		if Input.is_action_just_pressed("move_forward") and not ray_forward.is_colliding():
			direction -= camera.global_transform.basis.z
			playerAudioPlayer.play()
		elif Input.is_action_just_pressed("move_backward") and not ray_back.is_colliding():
			direction += camera.global_transform.basis.z
			playerAudioPlayer.play()
		elif Input.is_action_just_pressed("move_left") and not ray_left.is_colliding():
			direction -= camera.global_transform.basis.x
			playerAudioPlayer.play()
		elif Input.is_action_just_pressed("move_right") and not ray_right.is_colliding():
			direction += camera.global_transform.basis.x
			playerAudioPlayer.play()

		# Snap to the next cell if a movement key was pressed
		if direction != Vector3.ZERO:
			direction = direction.normalized()
			target_position += direction.round()
			grid_position = Vector2(target_position.x, target_position.z)  # Update grid_position
			can_move = false
			$MovementCooldownTimer.start()

	# Check for turn input
	if Input.is_action_just_pressed("turn_left"):
		start_turning(-1)
	elif Input.is_action_just_pressed("turn_right"):
		start_turning(1)
	elif Input.is_action_just_released("turn_left") or Input.is_action_just_released("turn_right"):
		stop_turning()

	# Move towards the target position
	global_transform.origin = global_transform.origin.lerp(target_position, speed * delta)

	# Smoothly rotate the player if turning
	if is_turning and turn_timer.is_stopped():
		target_rotation_degrees += turn_direction * 90.0
		turn_timer.start()  # Restart the timer for continuous turning
	current_rotation_degrees = lerp(current_rotation_degrees, deg_to_rad(target_rotation_degrees), rotation_speed * delta)
	rotation_degrees.y = rad_to_deg(current_rotation_degrees)

func start_turning(direction: int):
	is_turning = true
	turn_direction = -direction
	orientation = (orientation + direction) % 4  # Update orientation
	target_rotation_degrees += turn_direction * 90.0  # Initial turn
	turn_timer.start()

func get_orientation_str() -> String:
	match orientation:
		0: return "north"
		1: return "east"
		2: return "south"
		3: return "west"
	return "unknown"

func stop_turning():
	is_turning = false
	turn_timer.stop()

func _on_movement_cooldown_timer_timeout():
	can_move = true

func _input(event):
	if event.is_action_pressed("pause"):  # Adjust the action name as needed
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		pause_popup.show()
	else:
		pause_popup.hide()

func enter_combat():
	emit_signal("combat_started")
	is_in_combat = true
	# Additional actions for entering combat, e.g., switching to a combat UI

func exit_combat():
	emit_signal("combat_ended")
	is_in_combat = false
	# Additional actions for exiting combat, e.g., switching back to normal UI

# Connect this function to the enemy's collision signal
func _on_enemy_collision(enemy):
	enter_combat()

func _on_quit_button_pressed():
	get_tree().quit(0)
