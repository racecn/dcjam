extends Control

var dragging = false
var drag_offset = Vector2()
var rect_min_size = Vector2()
var return_to_pos = Vector2()
var animation_duration = 0.5  # Duration of the animation in seconds
var animation_timer = 0.0  # Timer to track the animation progress

func _ready():
	var panel_container = get_parent()
	rect_min_size = panel_container.size * 0.8  # Reduce the size of the card to 80% of the PanelContainer size
	size = rect_min_size
	position = (panel_container.size - rect_min_size) / 2
	print("PanelContainer size: ", panel_container.size)
	print("Card position: ", position, " Size: ", size)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and global_position.distance_to(get_global_mouse_position()) <= rect_min_size.length():
			dragging = true
			drag_offset = global_position - get_global_mouse_position()
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			dragging = false
			check_bounds()
	elif event is InputEventMouseMotion and dragging:
		var new_position = get_global_mouse_position() + drag_offset
		global_position = new_position

func check_bounds():
	var panel_container = get_parent()
	# Use position and size to create a Rect2 representing the panel_container's area
	var panel_container_rect = Rect2(Vector2.ZERO, panel_container.size)
	var card_rect = Rect2(position, rect_min_size)

	# Check if the card is outside the bounds of the panel_container
	if not panel_container_rect.encloses(card_rect):
		# Determine the closest position within the bounds
		var clamped_x = clamp(position.x, 0, panel_container.size.x - rect_min_size.x)
		var clamped_y = clamp(position.y, 0, panel_container.size.y - rect_min_size.y)
		return_to_pos = Vector2(clamped_x, clamped_y)
		animation_timer = 0.0  # Reset the animation timer
		set_process(true)  # Enable the _process function to run the animation

func _process(delta):
	if animation_timer < animation_duration:
		animation_timer += delta
		var t = animation_timer / animation_duration
		position = position.lerp(return_to_pos, t)
	else:
		set_process(false)  # Disable the _process function once the animation is complete
