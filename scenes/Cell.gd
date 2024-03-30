extends Node3D
class_name Cell

enum CellType { NORMAL, DOOR }

var cell_type = CellType.NORMAL

@onready var marker: MeshInstance3D = $MeshInstance3D


@onready var faces = {
	"north": {"face": $NorthFace, "col": $North},
	"east": {"face": $EastFace, "col": $East},
	"south": {"face": $SouthFace, "col": $South},
	"west": {"face": $WestFace, "col": $West}
}

func _ready():
	connect("card_marker_enabled", on_enable_marker)
	connect("card_marker_disabled", on_disable_marker)
	add_to_group("cells")
	if marker:
		marker.visible = false
	else:
		print("Marker node is null!")

func update_faces(cell_list, tileMap) -> void:
	var my_grid_position = Vector2(position.x / Globals.GRID_SIZE, position.z)
	var atlas_coords = tileMap.get_cell_atlas_coords(0, Vector2i(my_grid_position))
	if atlas_coords == Vector2i(1, 0):  # Assuming atlas 1, coords 0 represents the door
		cell_type = CellType.DOOR
		return  # Skip the rest of the function for doors
	var directions = {"east": Vector2.RIGHT, "west": Vector2.LEFT, "south": Vector2.DOWN, "north": Vector2.UP}
	for direction in directions.keys():
		var offset = directions[direction]
		if cell_list.has(Vector2i(my_grid_position + offset)):
			var face_and_col = faces[direction]
			if face_and_col["face"]:
				face_and_col["face"].queue_free()
			if face_and_col["col"]:
				face_and_col["col"].queue_free()

func on_enable_marker(pos):
	var my_grid_position = Vector2(floor(position.x / Globals.GRID_SIZE), floor(position.z / Globals.GRID_SIZE))
	if pos == my_grid_position:
		marker.visible = true

func on_disable_marker(pos):
	if pos == Vector2(position.x / Globals.GRID_SIZE, position.z):
		marker.visible = false
