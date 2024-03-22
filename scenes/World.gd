extends Node3D

const Cell = preload("res://scenes/Cell.tscn")
var Globals = preload("res://Globals.gd")

@export var Map: PackedScene

var cells = []

func _ready():
	var environment = get_tree().root.world.fallback_environment
	environment.background_mode = Environment.BG_COLOR
	
	
	generate_map()
	
func generate_map():
	
	if not Map is PackedScene: return
	var map = Map.instance()
	var tileMap = map.get_tilemap()
	var used_tiles = tileMap.get_used_cells()
	map.free()
	
	for tile in used_tiles:
		var cell = Cell.instance()
		add_child(cell)
		cell.position = Vector3(tile.x * Globals.GRID_SIZE, 0, tile.y * Globals.GRID_SIZE)
		cells.append(cell)
	for cell in cells:
		cell.update_faces(used_tiles)
	
