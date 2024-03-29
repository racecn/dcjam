extends Node3D

const Cell = preload("res://scenes/Cell.tscn")
const DoorCell = preload("res://scenes/DoorCell.tscn")
var Globals = preload("res://Globals.gd")

@export var Map: PackedScene

var cells = []

func _ready():
	var world_environment = get_node("WorldEnvironment")  # Adjust the path if necessary
	var environment = world_environment.environment
	if environment:
		environment.background_mode = Environment.BG_COLOR
	else:
		print("Environment is not set")

	generate_map()
	spawn_enemy()
	
const DOOR_SOURCE_ID = 1  # Replace 1 with the actual source ID of your door tiles

func generate_map():
	print(Map)
	if not Map is PackedScene:
		print("Map object not found in PackedScene")
		return

	var map_instance = Map.instantiate()
	add_child(map_instance)  # Add the instanced map to the world
	var tileMap = map_instance.get_tilemap()  # Adjust the path to your TileMap node

	if tileMap:
		var used_tiles = tileMap.get_used_cells(0)
		for tile in used_tiles:
			var cell = Cell.instantiate()  # Always create a normal cell
			add_child(cell)
			cell.position = Vector3(tile.x * Globals.GRID_SIZE, 0, tile.y * Globals.GRID_SIZE)
			cells.append(cell)

			var source_id = tileMap.get_cell_source_id(0, tile)
			if source_id == DOOR_SOURCE_ID:  # Check if the tile is a door
				var door_cell = DoorCell.instantiate()
				add_child(door_cell)
				door_cell.position = cell.position  # Position the door cell at the same location
				cells.append(door_cell)  # Optionally, add the door cell to the cells array if needed


		for cell in cells:
			cell.update_faces(used_tiles, tileMap)

	else:
		print("TileMap node not found in the instanced map")

func spawn_enemy():
	var enemy_scene = preload("res://entities/Enemy.tscn")  # Adjust the path to your enemy scene
	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)
	# Optionally, set the enemy's initial position
	enemy_instance.global_transform.origin = Vector3(0.5, 0.5, 0.5)  # Adjust the position as needed
