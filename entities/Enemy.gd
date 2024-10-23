extends Node3D

# Enums
enum Direction { NORTH, SOUTH, EAST, WEST }
enum State { EXPLORING, PATROLLING, MOVING_TO_TARGET }
enum EnemyBehavior { STATIC, EXPLORING, PATROLLING }
enum EnemyType { SLIME, GHOUL, GOLEM }

# Node references
@onready var raycast = $RayCast3D
@onready var sprite = $Sprite3D
@onready var moveTimer = $moveTimer
@onready var tile_map = $TileMap
@onready var area3d = $Area3D

# Enemy configuration
@export var enemy_type: EnemyType = EnemyType.SLIME
@export var max_random_moves: int = 5

# Combat-related variables
var CombatHandler: Node
var health: int
var max_health: int
var current_statuses: Array = []

# Movement and state variables
var current_direction = Direction.NORTH
var current_state = State.EXPLORING
var target_position: Vector3
var move_speed: float = 4.0
var update_interval: float = 2.0
var is_moving: bool = false
var random_moves_made: int = 0

# Exploration variables
var exploring_path: Array = []
var patrol_route: Array = []
var key_points: Array = []
var straight_path_length: int = 0
var last_direction = null
var hallway_threshold: int = 5
var current_patrol_point_index: int = 0
var current_path: Array = []

# Enemy attacks configuration
var attacks = {
	EnemyType.SLIME: [{"name": "Acid Splash", "damage": 5, "type": "acid"}],
	EnemyType.GHOUL: [{"name": "Bite", "damage": 10, "type": "physical"}],
	EnemyType.GOLEM: [{"name": "Rock Throw", "damage": 15, "type": "physical"}]
}

# A* Pathfinding Node Class
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

# Add this at the start of Enemy's _ready function
# Add this to your Enemy script
func _ready() -> void:
	# Add to enemies group
	if not is_in_group("enemies"):
		add_to_group("enemies")
	print_debug("Enemy added to 'enemies' group: ", name)
	
	# Get CombatHandler reference
	CombatHandler = get_parent().get_node("CombatHandler")
	if not CombatHandler:
		push_error("Enemy: CombatHandler not found")
	
	# Initialize based on enemy type
	match enemy_type:
		EnemyType.SLIME:
			max_health = 20
			health = max_health
			move_speed = 2.0
			sprite.texture = preload("res://assets/textures/slime/Idle01.png")
		EnemyType.GHOUL:
			max_health = 30
			health = max_health
			move_speed = 3.5
			sprite.texture = preload("res://assets/textures/ghoul/Idle_Animation/0001.png")
		EnemyType.GOLEM:
			max_health = 50
			health = max_health
			move_speed = 1.5
			sprite.texture = preload("res://assets/textures/golem/Golem_Body.png")
	
	# Initialize movement
	target_position = global_transform.origin
	is_moving = false
	set_process(true)
	
	# Setup timer
	if moveTimer:
		moveTimer.wait_time = update_interval
		moveTimer.start()
	else:
		push_error("Enemy: moveTimer node not found")
	
	print_debug("Enemy initialized: ", name, " Type: ", enum_to_string(enemy_type))
	
func _initialize_enemy_stats() -> void:
	match enemy_type:
		EnemyType.SLIME:
			max_health = 20
			move_speed = 2.0
			sprite.texture = preload("res://assets/textures/slime/Idle01.png")
		EnemyType.GHOUL:
			max_health = 30
			move_speed = 3.5
			sprite.texture = preload("res://assets/textures/ghoul/Idle_Animation/0001.png")
		EnemyType.GOLEM:
			max_health = 50
			move_speed = 1.5
			sprite.texture = preload("res://assets/textures/golem/Golem_Body.png")
	
	health = max_health

# Collision Setup
func _setup_collision() -> void:
	if not area3d:
		push_error("Enemy: Area3D node not found")
		return
		
	if not area3d.area_entered.is_connected(_on_area_3d_area_entered):
		area3d.area_entered.connect(_on_area_3d_area_entered)
	if not area3d.body_entered.is_connected(_on_area_3d_body_entered):
		area3d.body_entered.connect(_on_area_3d_body_entered)

# Pathfinding Functions
func heuristic(start: Vector2, end: Vector2) -> int:
	return abs(start.x - end.x) + abs(start.y - end.y)

func a_star_search(start: Vector2, end: Vector2) -> Array:
	var open_set = [AStarNode.new(start, 0, heuristic(start, end), null)]
	var closed_set = {}

	while open_set.size() > 0:
		var current: AStarNode = open_set[0]
		for i in range(open_set.size()):
			if open_set[i].f_cost() < current.f_cost() or \
			   (open_set[i].f_cost() == current.f_cost() and open_set[i].h_cost < current.h_cost):
				current = open_set[i]

		open_set.erase(current)
		closed_set[current.position] = true

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
				neighbour = AStarNode.new(
					neighbour_pos,
					tentative_g_cost,
					heuristic(neighbour_pos, end),
					current
				)
				if not neighbour_in_open_set:
					open_set.append(neighbour)

	return []

func get_neighbour_positions(pos: Vector2) -> Array:
	var neighbours = []
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

	for direction in directions:
		var neighbour_pos = pos + direction
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

# Movement Functions
func _process(delta: float) -> void:
	if !GlobalVars.in_combat:
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
						current_path.pop_front()
						if current_path.size() > 0:
							target_position = to_world_position(current_path[0])
							is_moving = true
						else:
							current_state = State.EXPLORING
							random_moves_made = 0

func move_towards_target(delta: float) -> void:
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

func start_exploring_movement() -> void:
	if random_moves_made < max_random_moves:
		var direction = choose_random_direction()
		if can_move_in_direction(direction):
			move_in_direction(direction)
			exploring_path.append(target_position)
			update_movement_tracking(direction)
			random_moves_made += 1
	else:
		var unexplored_target = find_unexplored_target()
		if unexplored_target:
			current_state = State.MOVING_TO_TARGET
			current_path = a_star_search(to_grid_position(global_transform.origin), unexplored_target)
			if current_path.size() > 0:
				target_position = to_world_position(current_path[0])
				is_moving = true

# Grid and World Position Functions
func to_grid_position(world_position: Vector3) -> Vector2:
	return Vector2(floor(world_position.x), floor(world_position.z))

func to_world_position(grid_pos: Vector2) -> Vector3:
	return Vector3(grid_pos.x + 0.5, 0.5, grid_pos.y + 0.5)

func can_move_to_grid_pos(grid_pos: Vector2) -> bool:
	var layer = 0
	var atlas_coords = tile_map.get_cell_atlas_coords(layer, grid_pos)
	return atlas_coords != Vector2i(0, 2)

func add_wall_to_tile_map(grid_pos: Vector2) -> void:
	var layer = 0
	tile_map.set_cell(layer, grid_pos, 3, Vector2i(0, 2))
	tile_map.update_internals()

# Combat Functions
func _on_area_3d_area_entered(area: Area3D) -> void:
	print("Area entered: ", area.name)
	if area.is_in_group("player"):
		_initiate_combat()

func _on_area_3d_body_entered(body: Node3D) -> void:
	print("Body entered: ", body.name)
	if body.is_in_group("player"):
		_initiate_combat()

func _initiate_combat() -> void:
	if not is_instance_valid(CombatHandler):
		push_error("Enemy: Cannot initiate combat - CombatHandler not found")
		return
	
	if GlobalVars.in_combat:
		print("Already in combat, ignoring collision")
		return
	
	print("Initiating combat with enemy type: ", enum_to_string(enemy_type))
	CombatHandler.start_combat_with_enemy(enum_to_string(enemy_type))

func handle_combat_start() -> void:
	print_debug("Enemy ", name, " entering combat...")
	
	# Stop normal movement and exploration
	is_moving = false
	current_state = State.EXPLORING  # Reset state for after combat
	
	# Initialize combat stats
	health = max_health
	current_statuses.clear()
	
	# Disable normal processing during combat
	set_process(false)
	if moveTimer and moveTimer.is_inside_tree():
		moveTimer.stop()
	
	print_debug("Enemy combat initialization complete")

func handle_combat_end() -> void:
	print_debug("Enemy ", name, " exiting combat...")
	
	# Re-enable normal processing
	set_process(true)
	if moveTimer and moveTimer.is_inside_tree():
		moveTimer.start()
		
	# Reset any combat-specific states
	current_statuses.clear()
	
	print_debug("Enemy returned to normal state")

# Add these helper functions for combat state management
func take_damage(amount: int) -> void:
	if not is_instance_valid(self):
		return
		
	health -= amount
	print_debug("Enemy took ", amount, " damage. Health: ", health, "/", max_health)
	
	if health <= 0:
		handle_death()

func handle_death() -> void:
	print_debug("Enemy defeated")
	if CombatHandler and is_instance_valid(CombatHandler):
		# Let the CombatHandler know the enemy is defeated
		CombatHandler.end_combat(true)
	queue_free()

func get_status_effects() -> Array:
	return current_statuses

func apply_status(status: Dictionary) -> void:
	current_statuses.append(status)
	print_debug("Status applied to enemy: ", status)

# Helper function for status effect processing
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

# Add this to track combat state internally
var in_combat: bool = false:
	set(value):
		in_combat = value
		if value:
			handle_combat_start()
		else:
			handle_combat_end()
	get:
		return in_combat


func take_action() -> void:
	var attack = choose_random_attack()
	perform_attack(attack)
	emit_signal("enemy_action_complete")

func perform_attack(attack: Dictionary) -> void:
	if not is_instance_valid(CombatHandler):
		push_error("Enemy: Cannot perform attack - CombatHandler not found")
		return
	
	CombatHandler.deal_damage_to_player(attack.damage, attack.type)

# Helper Functions
func choose_random_attack() -> Dictionary:
	var enemy_attacks = attacks[enemy_type]
	return enemy_attacks[randi() % enemy_attacks.size()]

func choose_random_direction() -> int:
	return randi() % 4

func enum_to_string(enemyType: EnemyType) -> String:
	match enemyType:
		EnemyType.SLIME:
			return "SLIME"
		EnemyType.GHOUL:
			return "GHOUL"
		EnemyType.GOLEM:
			return "GOLEM"
	return ""



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

func _on_area_3d_area_shape_entered(area_rid, area, area_shape_index, local_shape_index):
	print("area colid")
	if area.get_name() == "PlayerArea":
		print("player found")
		if is_instance_valid(self):
			CombatHandler.start_combat_with_enemy(enum_to_string(enemy_type))

