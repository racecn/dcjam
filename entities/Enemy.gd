extends Node3D

enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

var current_direction = Direction.NORTH
var target_position: Vector3
var move_speed = 4.0
var update_interval = 2.0
var is_moving = false

@onready var raycast = $RayCast3D
@onready var moveTimer = $moveTimer

func _ready():
	target_position = global_transform.origin
	set_process(true)
	moveTimer.wait_time = update_interval
	moveTimer.start()

func _process(delta: float):
	if is_moving:
		var current_position = global_transform.origin
		var new_position = current_position.lerp(target_position, move_speed * delta)
		global_transform.origin = new_position

		if new_position.distance_to(target_position) < 0.1:
			is_moving = false

func start_movement():
	choose_direction()
	if can_move_in_direction(current_direction):
		move_in_direction(current_direction)
	else:
		start_movement()

func choose_direction():
	current_direction = randi() % 4

func can_move_in_direction(direction: int) -> bool:
	match direction:
		Direction.NORTH:
			raycast.rotation_degrees = Vector3(0, 0, 0)
		Direction.SOUTH:
			raycast.rotation_degrees = Vector3(0, 180, 0)
		Direction.EAST:
			raycast.rotation_degrees = Vector3(0, -90, 0)
		Direction.WEST:
			raycast.rotation_degrees = Vector3(0, 90, 0)

	raycast.force_raycast_update()
	return !raycast.is_colliding()

func move_in_direction(direction: int):
	match direction:
		Direction.NORTH:
			target_position += Vector3(0, 0, -1)
		Direction.SOUTH:
			target_position += Vector3(0, 0, 1)
		Direction.EAST:
			target_position += Vector3(1, 0, 0)
		Direction.WEST:
			target_position += Vector3(-1, 0, 0)

	is_moving = true
	moveTimer.start()


func _on_move_timer_timeout():
	start_movement()
