extends Node2D

@onready var camera = $Viewport/Camera
var tilemap_instance

@export var Map: PackedScene

var player_position = Vector2(0, 0)  # Default player position

func _ready():
	var map_instance = Map.instantiate()
	$Viewport.add_child(map_instance)
	tilemap_instance = find_tilemap(map_instance)

	camera.rotation_degrees = 45
	camera.zoom = Vector2(0.5, 0.5)

	if tilemap_instance:
		# Center the TileMap in the Viewport
		var viewport_size = $Viewport.get_visible_rect().size
		var tilemap_size = tilemap_instance.get_used_rect().size
		tilemap_instance.position = (viewport_size - Vector2(tilemap_size.x, tilemap_size.y)) / 2

		# Add a big white square background to the Viewport
		var background = ColorRect.new()
		background.color = Color(1, 1, 1)
		background.size = viewport_size  # Use size property instead of rect_size
		$Viewport.add_child(background)


func find_tilemap(node):
	if node is TileMap:
		return node
	for child in node.get_children():
		var result = find_tilemap(child)
		if result:
			return result
	return null

func update_minimap(new_player_position):
	player_position = new_player_position
	var tilemap = find_tilemap(tilemap_instance)
	if tilemap:
		var minimap_position = tilemap.world_to_map(player_position)
		camera.position = minimap_position

