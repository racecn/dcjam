extends Node3D
class_name Cell

enum CellType { NORMAL, DOOR }

var cell_type = CellType.NORMAL
var grid_position

var marker
signal card_marker_enabled
signal card_marker_disabled

@onready var faces = {
	"north": {"face": $NorthFace, "col": $North},
	"east": {"face": $EastFace, "col": $East},
	"south": {"face": $SouthFace, "col": $South},
	"west": {"face": $WestFace, "col": $West}
}

func _ready():
	
	print("Checking marker node...")
	marker = get_node_or_null("MeshInstance3D")
	if marker:
		print("Marker node found!")
		marker.visible = false
	else:
		print("Marker node is null or has been freed.")

	print("mygrid pos ", grid_position)
	update_grid_position()
	add_to_group("cells")

func update_grid_position():
	grid_position = Vector2(floor(global_transform.origin.x / Globals.GRID_SIZE), floor(global_transform.origin.z / Globals.GRID_SIZE))

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

func on_enable_marker(affected_cells):
	if grid_position in affected_cells:
		marker.visible = true

func on_disable_marker():
	marker.visible = false
