extends Node3D

func _ready():
	get_node_or_null("MapCreator").visible = false
	get_node_or_null("DetailMap").visible = false

func get_tilemap():
	var map_creator = get_node_or_null("MapCreator")
	if map_creator and map_creator is TileMap:
		return map_creator
	else:
		print("TileMap node not found or MapCreator is not a TileMap")
		return null

func get_detailmap():
	var detail_map = get_node_or_null("DetailMap")
	if detail_map and detail_map is TileMap:
		return detail_map
	else:
		print("DetailMap node not found, or invalid")
		return null
