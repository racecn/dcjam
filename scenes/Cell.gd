extends Node3D
class_name Cell

enum CellType { NORMAL, DOOR }

var cell_type = CellType.NORMAL

@onready var faces = {
	"north": {"face": $NorthFace, "col": $North},
	"east": {"face": $EastFace, "col": $East},
	"south": {"face": $SouthFace, "col": $South},
	"west": {"face": $WestFace, "col": $West}
}

func update_faces(cell_list, tileMap) -> void:
	var my_grid_position = Vector2(position.x / Globals.GRID_SIZE, position.z)
	var atlas_coords = tileMap.get_cell_atlas_coords(0, Vector2i(my_grid_position))

	if atlas_coords == Vector2i(1, 0):  # Assuming atlas 1, coords 0 represents the door
		cell_type = CellType.DOOR
		# Handle door-specific logic here, e.g., don't remove faces, add a door mesh, etc.
		return  # Skip the rest of the function for doors

	var directions = {
		"east": Vector2.RIGHT,
		"west": Vector2.LEFT,
		"south": Vector2.DOWN,
		"north": Vector2.UP
	}

	for direction in directions.keys():
		var offset = directions[direction]
		if cell_list.has(Vector2i(my_grid_position + offset)):
			var face_and_col = faces[direction]
			if face_and_col["face"]:
				face_and_col["face"].queue_free()
			if face_and_col["col"]:
				face_and_col["col"].queue_free()
