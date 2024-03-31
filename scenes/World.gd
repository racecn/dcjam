extends Node3D

const Cell = preload("res://scenes/Cell.tscn")
const DoorCell = preload("res://scenes/DoorCell.tscn")
var Globals = preload("res://Globals.gd")
const Detail = preload("res://entities/Detail.tscn")
const Torch = preload("res://entities/Torch.tscn")
const Enemy = preload("res://entities/Enemy.tscn")

@export var Map: PackedScene

var cells = []
var enemies = []
const DOOR_SOURCE_ID = 1  # Replace 1 with the actual source ID of your door tiles

signal combat_start
signal combat_end

var is_combat_active = false  # Flag to indicate if combat is active


func _ready():
	var world_environment = get_node("WorldEnvironment")  # Adjust the path if necessary
	var environment = world_environment.environment
	if environment:
		environment.background_mode = Environment.BG_COLOR
	else:
		print("Environment is not set")
	generate_map()


func handle_combat_start():
	# emit signal to pause other enemies
	start_combat()

func handle_combat_end():
	end_combat()	

func _process(delta: float):
	if is_combat_active:
		return  # Do not allow enemies to move if combat is active

	

func generate_map():
	print(Map)
	if not Map is PackedScene:
		print("Map object not found in PackedScene")
		return

	var map_instance = Map.instantiate()
	add_child(map_instance)  # Add the instanced map to the world
	var tileMap = map_instance.get_tilemap()
	var detail_map = map_instance.get_detailmap()  # Assuming DetailMap is the node containing the detail map tilemap

	if tileMap:
		print("TileMap found")
		var used_tiles = tileMap.get_used_cells(0)
		for tile in used_tiles:
			var cell_instance = Cell.instantiate()  # Always create a normal cell
			add_child(cell_instance)
			cell_instance.position = Vector3(tile.x * Globals.GRID_SIZE, 0, tile.y * Globals.GRID_SIZE)
			cells.append(cell_instance)

			var source_id = tileMap.get_cell_source_id(0, tile)
			if source_id == DOOR_SOURCE_ID:  # Check if the tile is a door
				var door_cell = DoorCell.instantiate()
				add_child(door_cell)
				door_cell.position = cell_instance.position  # Position the door cell at the same location

			elif source_id == 0:  # cell
				# Perform actions for normal cell
				print("Cell created at:", cell_instance.position)

		for cell_instance in cells:
			cell_instance.update_faces(used_tiles, tileMap)

	else:
		print("TileMap node not found in the instanced map")
	
		
	if not detail_map:
		print("DetailMap node not found")
		return
	else:
		print("Detail map collected")

	# Iterate over each tile in the detail map
	# Determine the atlas coordinate
	# if 0 0, torch, if -1 -1 nothing, if 0 1 enemy spawn point
	var used_detail_tiles = detail_map.get_used_cells(0)
	for tile_pos in used_detail_tiles:
		var tile_id = detail_map.get_cell_atlas_coords(0, tile_pos, false)  # Assuming detail map is on layer 0
		if tile_id != Vector2i(-1, -1):
			print("Checking tile at:", tile_pos, "Detail ID:", tile_id)

		if tile_id == Vector2i(0, 0):
			var detail_instance = Detail.instantiate()  # Assuming Detail is the scene for the detail object
			add_child(detail_instance)
			# Convert tile position to world position using the new map_to_world function
			detail_instance.position = map_to_world(tile_pos, Vector2(1, 1), Vector2(4, 4))
			print("Detail instance created at:", detail_instance.position)
		elif tile_id == Vector2i(1,0):
			var detail_instance = Enemy.instantiate()  # Assuming Detail is the scene for the detail object
			add_child(detail_instance)
			# Convert tile position to world position using the new map_to_world function
			detail_instance.position = map_to_world(tile_pos, Vector2(1, 1), Vector2(4, 4))
			detail_instance.position.y = 0.5
			print("Detail instance created at:", detail_instance.position)
		elif tile_id == Vector2i(2, 0):
			var detail_instance = Torch.instantiate()  # Assuming Detail is the scene for the detail object
			add_child(detail_instance)
			# Convert tile position to world position using the new map_to_world function
			detail_instance.position = map_to_world(tile_pos, Vector2(1, 1), Vector2(4, 4))
			detail_instance.position.y = 0.5
			print("Detail instance created at:", detail_instance.position)
		elif tile_id == Vector2i(1, 0):
			pass



func map_to_world(detail_pos: Vector2, cell_size: Vector2, detail_scale: Vector2) -> Vector3:
	# Scale the detail map position up to the world map scale
	var world_x = detail_pos.x * cell_size.x / detail_scale.x
	var world_z = detail_pos.y * cell_size.y / detail_scale.y
	# Offset to center the detail in its corresponding quarter-tile
	# Each quarter-tile is 0.25 units, so the center is at 0.125 units
	var offset_x = (cell_size.x / detail_scale.x) / 2
	var offset_z = (cell_size.y / detail_scale.y) / 2
	# Set the Y-coordinate to a fixed height, e.g., 0.1 units above the ground
	print("Detail pos: " , Vector3(world_x + offset_x, 0.1, world_z + offset_z))
	return Vector3(world_x + offset_x, 0.1, world_z + offset_z)





func match_detail_id_to_atlas_coordinate(detail_id: int) -> Vector2:
	# Define the mapping of detail IDs to atlas coordinates
	var atlas_coordinates = {
		0: Vector2(0, 0),  # Key
		1: Vector2(0, 1),   # Enemy spawn point
		2: Vector2(0, 2)	#torch
		# Add more mappings as needed
	}

	if detail_id in atlas_coordinates:
		return atlas_coordinates[detail_id]
	else:
		return Vector2(-1, -1)


func start_combat():
	is_combat_active = true
	emit_signal("combat_start")

func end_combat():
	is_combat_active = false
	emit_signal("combat_end")
