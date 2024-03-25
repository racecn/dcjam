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

# Raycasts
@onready var ray_forward: RayCast3D = $RayForward
@onready var ray_back: RayCast3D = $RayBack
@onready var ray_left: RayCast3D = $RayLeft
@onready var ray_right: RayCast3D = $RayRight
# Camera
@onready var camera: Camera3D = $Control/SubViewportContainer/SubViewport/Camera3D
# Timer for continuous turning
@onready var turn_timer: Timer = $TurnTimer
# audio
@onready var audioPlayer: AudioStreamPlayer3D = $Control/SubViewportContainer/SubViewport/AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time
func _ready():
	target_position = global_transform.origin
	target_rotation_degrees = rotation_degrees.y
	current_rotation_degrees = rotation_degrees.y

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	
	camera.rotation_degrees.y = rotation_degrees.y
	camera.position = position
	
	if can_move:
		var direction = Vector3.ZERO

		# Get input for movement
		if Input.is_action_just_pressed("move_forward") and not ray_forward.is_colliding():
			direction -= camera.global_transform.basis.z
			audioPlayer.play()
		elif Input.is_action_just_pressed("move_backward") and not ray_back.is_colliding():
			direction += camera.global_transform.basis.z
		elif Input.is_action_just_pressed("move_left") and not ray_left.is_colliding():
			direction -= camera.global_transform.basis.x
		elif Input.is_action_just_pressed("move_right") and not ray_right.is_colliding():
			direction += camera.global_transform.basis.x

		# Snap to the next cell if a movement key was pressed
		if direction != Vector3.ZERO:
			direction = direction.normalized()
			target_position += direction.round()
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

# Starts the turning process
func start_turning(direction: int):
	is_turning = true
	turn_direction = -direction
	target_rotation_degrees += turn_direction * 90.0  # Initial turn
	turn_timer.start()

# Stops the turning process
func stop_turning():
	is_turning = false
	turn_timer.stop()


func _on_movement_cooldown_timer_timeout():
	can_move = true
