extends Node3D

const Cell = preload("res://scenes/Cell.tscn")
const DoorCell = preload("res://scenes/DoorCell.tscn")
var Globals = preload("res://Globals.gd")
const Detail = preload("res://entities/Detail.tscn")
const Torch = preload("res://entities/Torch.tscn")
const Enemy = preload("res://entities/Enemy.tscn")

@export var Map: PackedScene

var cells: Array = []
var enemies: Array = []
const DOOR_SOURCE_ID = 1

signal combat_start
signal combat_end

var is_combat_active: bool = false

func _ready() -> void:
	print_debug("World generator initializing...")
	_setup_environment()
	generate_map()
	
func _setup_environment() -> void:
	var world_environment = get_node("WorldEnvironment")
	if not world_environment:
		push_error("WorldEnvironment node not found")
		return
		
	var environment = world_environment.environment
	if environment:
		environment.background_mode = Environment.BG_COLOR
		print_debug("Environment setup complete")
	else:
		push_error("Environment is not set")

func generate_map() -> void:
	print_debug("Starting map generation")
	
	if not Map is PackedScene:
		push_error("No valid Map scene provided")
		return

	var map_instance = Map.instantiate()
	add_child(map_instance)
	
	var tileMap = map_instance.get_tilemap()
	var detail_map = map_instance.get_detailmap()
	
	if not tileMap:
		push_error("TileMap not found in map instance")
		return
		
	_generate_cells(tileMap)
	
	if detail_map:
		_generate_details(detail_map)
	else:
		push_error("DetailMap not found in map instance")

func _generate_cells(tileMap: TileMap) -> void:
	print_debug("Generating cells...")
	var used_tiles = tileMap.get_used_cells(0)
	
	for tile in used_tiles:
		var cell_instance = Cell.instantiate()
		add_child(cell_instance)
		cell_instance.position = Vector3(tile.x * Globals.GRID_SIZE, 0, tile.y * Globals.GRID_SIZE)
		cells.append(cell_instance)

		var source_id = tileMap.get_cell_source_id(0, tile)
		if source_id == DOOR_SOURCE_ID:
			var door_cell = DoorCell.instantiate()
			add_child(door_cell)
			door_cell.position = cell_instance.position

	for cell_instance in cells:
		cell_instance.update_faces(used_tiles, tileMap)
	
	print_debug("Cell generation complete. Total cells: ", cells.size())

func _generate_details(detail_map: TileMap) -> void:
	print_debug("Generating details...")
	var used_detail_tiles = detail_map.get_used_cells(0)
	var enemy_count = 0
	
	for tile_pos in used_detail_tiles:
		var tile_id = detail_map.get_cell_atlas_coords(0, tile_pos, false)
		if tile_id == Vector2i(-1, -1):
			continue

		var world_position = map_to_world(tile_pos, Vector2(1, 1), Vector2(4, 4))
		
		match tile_id:
			Vector2i(0, 0):  # Detail
				var detail_instance = Detail.instantiate()
				add_child(detail_instance)
				detail_instance.position = world_position
				print_debug("Detail created at: ", world_position)
				
			Vector2i(1, 0):  # Enemy
				var enemy_instance = Enemy.instantiate()
				add_child(enemy_instance)
				enemy_instance.position = world_position
				enemy_instance.position.y = 0.5
				
				# Ensure enemy is in group
				if not enemy_instance.is_in_group("enemies"):
					enemy_instance.add_to_group("enemies")
				
				enemies.append(enemy_instance)
				enemy_count += 1
				print_debug("Enemy created at: ", world_position)
				
			Vector2i(2, 0):  # Torch
				var torch_instance = Torch.instantiate()
				add_child(torch_instance)
				torch_instance.position = world_position
				torch_instance.position.y = 0.5
				print_debug("Torch created at: ", world_position)
	
	print_debug("Detail generation complete. Enemies created: ", enemy_count)
	_verify_enemies()

func _verify_enemies() -> void:
	var enemies_in_group = get_tree().get_nodes_in_group("enemies")
	print_debug("Verifying enemies...")
	print_debug("Enemies tracked: ", enemies.size())
	print_debug("Enemies in 'enemies' group: ", enemies_in_group.size())
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			print_debug("Enemy valid: ", enemy.name, " In group: ", enemy.is_in_group("enemies"))
		else:
			push_warning("Invalid enemy reference found")

func map_to_world(detail_pos: Vector2, cell_size: Vector2, detail_scale: Vector2) -> Vector3:
	var world_x = detail_pos.x * cell_size.x / detail_scale.x
	var world_z = detail_pos.y * cell_size.y / detail_scale.y
	var offset_x = (cell_size.x / detail_scale.x) / 2
	var offset_z = (cell_size.y / detail_scale.y) / 2
	return Vector3(world_x + offset_x, 0.1, world_z + offset_z)

func match_detail_id_to_atlas_coordinate(detail_id: int) -> Vector2:
	var atlas_coordinates = {
		0: Vector2(0, 0),  # Key
		1: Vector2(0, 1),  # Enemy spawn point
		2: Vector2(0, 2)   # Torch
	}
	return atlas_coordinates.get(detail_id, Vector2(-1, -1))

func handle_combat_start() -> void:
	print_debug("Combat starting...")
	is_combat_active = true
	emit_signal("combat_start")

func handle_combat_end() -> void:
	print_debug("Combat ending...")
	is_combat_active = false
	emit_signal("combat_end")

func _process(_delta: float) -> void:
	if is_combat_active:
		return
