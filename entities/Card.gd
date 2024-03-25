extends Control

var dragging = false
var drag_offset = Vector2()
var rect_min_size = Vector2()
var return_to_pos = Vector2()
var return_speed = 5.0

func _ready():
	rect_min_size = get_viewport().size * 0.25
	size = rect_min_size
	position = Vector2.ZERO

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and global_position.distance_to(get_global_mouse_position()) <= rect_min_size.length():
			dragging = true
			drag_offset = global_position - get_global_mouse_position()
			return_to_pos = global_position
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		var new_position = get_global_mouse_position() + drag_offset
		global_position = new_position
		check_bounds()

func _process(delta):
	if not dragging and global_position != return_to_pos:
		global_position =global_position.lerp(return_to_pos, return_speed * delta)
	
func check_bounds():
	var panel_container = get_parent()
	# Use rect_global_position and rect_size to create a Rect2 representing the panel_container's area
	var panel_container_rect = Rect2(panel_container.global_position, panel_container.size)
	var card_rect = Rect2(global_position, rect_min_size)

	# Check if the card is outside the bounds of the panel_container
	if not panel_container_rect.encloses(card_rect):
		dragging = false
		# Determine the closest position within the bounds
		var clamped_x = clamp(global_position.x, panel_container_rect.position.x, panel_container_rect.end.x - rect_min_size.x)
		var clamped_y = clamp(global_position.y, panel_container_rect.position.y, panel_container_rect.end.y - rect_min_size.y)
		return_to_pos = Vector2(clamped_x, clamped_y)
