extends Area3D

class_name Cell

var Globals = preload("res://Globals.gd")

@onready var eastFace = $EastFace

func update_faces(cell_list: Dictionary) -> void:
	var grid_position := Vector2(position.x / Globals.GRID_SIZE, position.z / Globals.GRID_SIZE)
	if cell_list.has(grid_position + Vector2.RIGHT):
		eastFace.visible = false
