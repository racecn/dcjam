extends Node3D

# Movement speed (units per second)
var speed = 5.0
# Current target position for snapping
var target_position: Vector3

# Raycasts
@onready var ray_forward: RayCast3D = $RayForward
@onready var ray_back: RayCast3D = $RayBack
@onready var ray_left: RayCast3D = $RayLeft
@onready var ray_right: RayCast3D = $RayRight

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize the target position to the current position
	target_position = global_transform.origin
	# Make sure the raycasts are enabled
	ray_forward.enabled = true
	ray_back.enabled = true
	ray_left.enabled = true
	ray_right.enabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame
func _process(delta):
	var direction = Vector3.ZERO

	# Get input for movement
	if Input.is_action_just_pressed("move_forward"):
		direction -= $Camera3D.global_transform.basis.z
	if Input.is_action_just_pressed("move_backward"):
		direction += $Camera3D.global_transform.basis.z
	if Input.is_action_just_pressed("move_left"):
		direction -= $Camera3D.global_transform.basis.x
	if Input.is_action_just_pressed("move_right"):
		direction += $Camera3D.global_transform.basis.x

	# Snap to the next cell if a movement key was pressed
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		target_position += direction.round()

	# Move towards the target position
	global_transform.origin = global_transform.origin.lerp(target_position, speed * delta)

	# Check for wall collisions using raycasts
	if ray_forward.is_colliding():
		print("Collided with a wall in front!")
	if ray_back.is_colliding():
		print("Collided with a wall behind!")
	if ray_left.is_colliding():
		print("Collided with a wall on the left!")
	if ray_right.is_colliding():
		print("Collided with a wall on the right!")
