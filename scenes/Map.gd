extends Node3D

func get_tilemap():
	var map_creator = get_node_or_null("MapCreator")
	if map_creator and map_creator is TileMap:
		return map_creator
	else:
		print("TileMap node not found or MapCreator is not a TileMap")
		return null
