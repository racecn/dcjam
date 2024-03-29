extends Node3D

# Enumerations for direction and state
enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST
}

enum State {
	EXPLORING,
	PATROLLING,
	MOVING_TO_TARGET
}

# Variables to track the current direction, state, target position, and movement properties
var current_direction = Direction.NORTH
var current_state = State.EXPLORING
var target_position: Vector3
var move_speed = 4.0
var update_interval = 2.0
var is_moving = false
var random_moves_made = 0
var max_random_moves = 5  # Number of random moves before using A*


# Variables for exploration and patrolling logic
var exploring_path = []
var patrol_route = []
var key_points = []
var straight_path_length = 0
var last_direction = null
var hallway_threshold = 5
var current_patrol_point_index = 0

var current_path = [] 

# References to nodes
@onready var raycast = $RayCast3D
@onready var sprite = $Sprite3D
@onready var moveTimer = $moveTimer
@onready var tile_map = $TileMap  # Reference to the TileMap node



# Node class for A* pathfinding
class AStarNode:
	var position: Vector2
	var g_cost: int
	var h_cost: int
	var parent: AStarNode

	func _init(_position: Vector2, _g_cost: int, _h_cost: int, _parent: AStarNode) -> void:
		position = _position
		g_cost = _g_cost
		h_cost = _h_cost
		parent = _parent

	func f_cost() -> int:
		return g_cost + h_cost

# Heuristic function for A* (Manhattan distance)
func heuristic(start: Vector2, end: Vector2) -> int:
	return abs(start.x - end.x) + abs(start.y - end.y)

# A* pathfinding functions
# A* pathfinding functions
func a_star_search(start: Vector2, end: Vector2) -> Array:
	var open_set = [AStarNode.new(start, 0, heuristic(start, end), null)]
	var closed_set = {}  # Make sure this is a Dictionary

	while open_set.size() > 0:
		var current: AStarNode = open_set[0]
		for i in range(open_set.size()):
			if open_set[i].f_cost() < current.f_cost() or (open_set[i].f_cost() == current.f_cost() and open_set[i].h_cost < current.h_cost):
				current = open_set[i]

		open_set.erase(current)
		closed_set[current.position] = true  # Correctly using Dictionary

		if current.position == end:
			return reconstruct_path(current)

		for neighbour_pos in get_neighbour_positions(current.position):
			if closed_set.has(neighbour_pos):
				continue

			var tentative_g_cost: int = current.g_cost + 1
			var neighbour_in_open_set: bool = false
			var neighbour: AStarNode
			for node in open_set:
				if node.position == neighbour_pos:
					neighbour = node
					neighbour_in_open_set = true
					break

			if not neighbour_in_open_set or tentative_g_cost < neighbour.g_cost:
				neighbour = AStarNode.new(neighbour_pos, tentative_g_cost, heuristic(neighbour_pos, end), current)
				neighbour._init(neighbour_pos, tentative_g_cost, heuristic(neighbour_pos, end), current)  # Correctly initializing AStarNode
				if not neighbour_in_open_set:
					open_set.append(neighbour)

	return []

func get_neighbour_positions(pos: Vector2) -> Array:
	var neighbours = []
	var directions: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

	for direction in directions:
		var neighbour_pos: Vector2 = pos + direction
		if can_move_to_grid_pos(neighbour_pos):
			neighbours.append(neighbour_pos)

	return neighbours


func reconstruct_path(current: AStarNode) -> Array:
	var path = []
	while current != null:
		path.append(current.position)
		current = current.parent
	path.reverse()
	return path

# Call this function to start pathfinding from the enemy's current position to a target
func start_pathfinding_to(target_global_position: Vector3):
	var start = to_grid_position(global_transform.origin)
	var end = to_grid_position(target_global_position)
	var path = a_star_search(start, end)
	# Use the returned 'path' to move your enemy

# Initialization function
func _ready():
	target_position = global_transform.origin
	set_process(true)
	moveTimer.wait_time = update_interval
	moveTimer.start()

# Process function to handle movement and state updates
func _process(delta: float):
	tile_map.update_internals()
	match current_state:
		State.EXPLORING:
			if is_moving:
				move_towards_target(delta)
			else:
				start_exploring_movement()
		State.MOVING_TO_TARGET:
			if is_moving:
				move_towards_target(delta)
			else:
				if current_path.size() > 0:
					current_path.pop_front()  # Remove the first element of the path
					if current_path.size() > 0:
						target_position = to_world_position(current_path[0])
						is_moving = true
					else:
						# Reached the target, switch back to exploring
						current_state = State.EXPLORING
						random_moves_made = 0

# Function to check if the entity can move to a specific grid position
func can_move_to_grid_pos(grid_pos: Vector2) -> bool:
	var layer = 0
	var atlas_coords = tile_map.get_cell_atlas_coords(layer, grid_pos)
	return atlas_coords != Vector2i(0, 2)  # Check if the cell is not a wall

func to_world_position(grid_pos: Vector2) -> Vector3:
	var world_x = grid_pos.x + 0.5
	var world_z = grid_pos.y + 0.5
	return Vector3(world_x, 0.5, world_z)  # Assuming the tiles are centered at Y=0.5


# Function to move the entity towards the target position
func move_towards_target(delta: float):
	var current_position = global_transform.origin
	var new_position = current_position.lerp(target_position, move_speed * delta)

	var grid_pos = to_grid_position(new_position)

	if can_move_to_grid_pos(grid_pos):
		global_transform.origin = new_position
	else:
		add_wall_to_tile_map(grid_pos)

	if new_position.distance_to(target_position) < 0.1:
		is_moving = false
		update_tile_map(grid_pos)

# Function to add a wall to the tile map at a specific grid position
func add_wall_to_tile_map(grid_pos: Vector2):
	print("adding wall")
	var layer = 0
	tile_map.set_cell(layer, grid_pos, 3, Vector2i(0, 2))  # Set the cell as a wall
	tile_map.update_internals()

# Function to start the exploring movement
func start_exploring_movement():
	if random_moves_made < max_random_moves:
		# Make a random move
		var direction = choose_random_direction()
		if can_move_in_direction(direction):
			move_in_direction(direction)
			exploring_path.append(target_position)
			update_movement_tracking(direction)
			random_moves_made += 1
	else:
		# Use A* pathfinding to move to an unexplored area
		var unexplored_target = find_unexplored_target()
		if unexplored_target:
			current_state = State.MOVING_TO_TARGET
			current_path = a_star_search(to_grid_position(global_transform.origin), unexplored_target)
			if current_path.size() > 0:
				target_position = to_world_position(current_path[0])
				is_moving = true
				

func find_unexplored_target() -> Vector2:
	# Example logic: Iterate through the tilemap and find the first empty cell
	for y in range(tile_map.get_used_rect().size.y):
		for x in range(tile_map.get_used_rect().size.x):
			var cell_data = tile_map.get_cell_tile_data(0,Vector2i(x,y), false)
			if cell_data == null:  # Assuming null represents an empty cell
				return Vector2(x, y)

	return Vector2.INF  # Return Vector2.INF if no unexplored target is found

# Function to get the directions that have not been explored yet
func get_unexplored_directions() -> Array:
	var unexplored_directions = []
	var directions = [
		{ "dir": Direction.NORTH, "vec": Vector3(0, 0, -1) },
		{ "dir": Direction.SOUTH, "vec": Vector3(0, 0, 1) },
		{ "dir": Direction.EAST,  "vec": Vector3(1, 0, 0) },
		{ "dir": Direction.WEST,  "vec": Vector3(-1, 0, 0) }
	]

	for direction in directions:
		var grid_pos = to_grid_position(global_transform.origin + direction["vec"])
		if can_move_to_grid_pos(grid_pos) and not has_marked_neighbors(grid_pos):
			unexplored_directions.append(direction["dir"])

	return unexplored_directions

func has_marked_neighbors(grid_pos: Vector2) -> bool:
	var neighbors = [
		Vector2(grid_pos.x - 1, grid_pos.y),
		Vector2(grid_pos.x + 1, grid_pos.y),
		Vector2(grid_pos.x, grid_pos.y - 1),
		Vector2(grid_pos.x, grid_pos.y + 1)
	]

	for neighbor in neighbors:
		if tile_map.get_cell_atlas_coords(0, neighbor) != Vector2i(-1, -1):  # Check if the cell is marked
			return true

	return false

func update_movement_tracking(direction: int):
	if last_direction == null or direction != last_direction:
		if straight_path_length >= hallway_threshold:
			key_points.append(exploring_path[exploring_path.size() - straight_path_length - 1])
			key_points.append(exploring_path[exploring_path.size() - 1])
		straight_path_length = 0
	straight_path_length += 1
	last_direction = direction

func choose_random_direction() -> int:
	return randi() % 4

func can_move_in_direction(direction: int) -> bool:
	var raycast_direction = Vector3.ZERO
	match direction:
		Direction.NORTH:
			raycast_direction = Vector3(0, 0, -1)
		Direction.SOUTH:
			raycast_direction = Vector3(0, 0, 1)
		Direction.EAST:
			raycast_direction = Vector3(1, 0, 0)
		Direction.WEST:
			raycast_direction = Vector3(-1, 0, 0)

	raycast.target_position = raycast_direction
	raycast.force_raycast_update()

	if raycast.is_colliding():
		return false

	return true



func map_walls():
	var directions = [
		Vector3(0, 0, -1),  # North
		Vector3(0, 0, 1),   # South
		Vector3(1, 0, 0),   # East
		Vector3(-1, 0, 0)   # West
	]

	for direction in directions:
		raycast.target_position = direction
		raycast.force_raycast_update()
		if raycast.is_colliding():
			var wall_grid_pos = to_grid_position(global_transform.origin + direction)
			tile_map.set_cell(0, wall_grid_pos, 3, Vector2i(2, 0))
			tile_map.update_internals()
		
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
	# Update memory map and TileMap
	var grid_pos = to_grid_position(target_position)
	update_tile_map(grid_pos)

func generate_patrol_route():
	patrol_route = key_points
	current_state = State.PATROLLING

func move_to_next_patrol_point():
	if patrol_route.size() == 0:
		return
	var target_patrol_point = patrol_route[current_patrol_point_index]
	target_position = target_patrol_point
	is_moving = true
	current_patrol_point_index = (current_patrol_point_index + 1) % patrol_route.size()

func _on_move_timer_timeout():
	match current_state:
		State.EXPLORING:
			start_exploring_movement()
		State.PATROLLING:
			move_to_next_patrol_point()

func to_grid_position(world_position: Vector3) -> Vector2:
	# Convert world position to grid position
	return Vector2(floor(world_position.x), floor(world_position.z))

func update_tile_map(grid_pos: Vector2i):
	var layer = 0 
	var atlas_coords = tile_map.get_cell_atlas_coords(layer, grid_pos)
	if atlas_coords == Vector2i(-1, -1):  # Cell does not exist
		tile_map.set_cell(layer, grid_pos, 3, Vector2i(0, 0))  # Add the cell with atlas coords (0, 0)
		tile_map.update_internals()
	elif atlas_coords == Vector2i(0, 0):  # Cell is visited
		# print("TileMap - Cell is visited.")
		# Do something if needed
		pass
	elif atlas_coords == Vector2i(0, 1):  # Cell is a key point
		print("TileMap - Cell is a key point.")
		
	
	tile_map.update_internals()

