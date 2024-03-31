extends Control

@export_category("Card Attributes")
@export var hand_pos: int
@export var cardname: String
@export var type: String
@export var mana_cost: int
@export var description: String
@export var effects: Array
@export var area_of_effect: Array
var player: Node

@onready var nameLabel: Label = $Name
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
var pickup_stream = load("res://assets/sound/Card Sounds/CardPlayDry_7.wav")
var setdown_stream = load("res://assets/sound/Card Sounds/CardDiscardDry_5.wav")

var dragging = false
var drag_offset = Vector2()
var original_position = Vector2()
var original_scale: Vector2 = Vector2(1, 1)  # Store the original scale of the card
var is_hovered: bool = false
var target_position: Vector2
var card_handler
var is_in_hand = false
var hand_idx


signal card_mouse_entered(pos)
signal card_mouse_exited
signal card_marker_enabled(pos)

func _process(delta):
	if dragging:
		target_position = get_global_mouse_position() + drag_offset  # Update target position based on the offset
		global_position = global_position.lerp(target_position, delta * 10)  # Smooth dragging
	elif not dragging:
		position = position.lerp(original_position, delta * 5)  # Adjust speed as needed

	if is_hovered and not dragging:
		scale = original_scale.lerp(original_scale * 1.1, delta * 5)  # Smooth hover effect


func _ready():
	card_handler = get_parent().get_parent()
	player = get_tree().get_nodes_in_group("player")[0]
	original_position = position
	original_scale = scale
	update_card_visuals()

func set_hand_pos(cidx):
	hand_pos = cidx

func set_card_data(card_data: Dictionary, isInHand, handIdx):
	cardname = card_data["name"]
	type = card_data["type"]
	mana_cost = card_data["mana_cost"]
	description = card_data["description"]
	effects = card_data["effects"]
	area_of_effect = card_data["area_of_effect"]["shape"]
	is_in_hand = isInHand
	if is_in_hand:
		hand_idx = handIdx
	call_deferred("update_card_visuals")

func update_hand_status(isInHand, handIdx):
	is_in_hand = isInHand
	hand_idx = handIdx

func update_card_visuals():
	# Update the card's texture and name based on the card attributes
	var texture_path = "res://assets/textures/cards/" + cardname + ".png"
	var texture: Texture = load(texture_path)
	if texture:
		if sprite:
			sprite.texture = texture
		else:
			print("Sprite is Nil")
	print("Card name passed to update visuals ", cardname)
	if nameLabel:
		nameLabel.text = cardname
	else:
		print("NameLabel is Nil")

func _on_mouse_entered():
	is_hovered = true
	var affected_cells = calculate_affected_cells()
	print("Affected cells ", affected_cells)
	emit_signal("card_mouse_entered", affected_cells)  # Emit signal with the necessary data

func _on_mouse_exited():
	is_hovered = false
	scale = original_scale  # Reset to original scale
	print("Emit to turn off marker")
	emit_signal("card_mouse_exited")  # Emit signal without data

func get_player_orientation() -> int:
	return player.orientation

func calculate_affected_cells() -> Array:
	var affected_positions = []
	var player_orientation = get_player_orientation()
	var player_position = get_player_position()

	# Calculate the affected positions based on the shape and orientation
	for offset_array in area_of_effect:
		var offset = Vector2(offset_array[0], offset_array[1])
		var transformed_offset = rotate_offset(offset, player_orientation)
		var affected_position = player_position + transformed_offset
		affected_positions.append(affected_position)

	return affected_positions

# Helper function to rotate the offset based on the player's orientation
func rotate_offset(offset: Vector2, orientation: int) -> Vector2:
	var rotations = orientation % 4  # Ensure the rotation is within valid range
	var rotated_offset = offset
	for i in range(rotations):
		rotated_offset = Vector2(rotated_offset.y, -rotated_offset.x)
	return rotated_offset

func is_cell_valid(position: Vector2) -> bool:
	# Add your criteria here to determine if the cell is valid
	# For example, you can check if the cell is within the bounds of the grid
	return true  # Replace with your actual logic

func get_player_position() -> Vector2:
	return player.grid_position

func transform_offset_by_orientation(offset, orientation) -> Vector2:
	match orientation:
		0: return offset
		1: return Vector2(offset.y, -offset.x)
		2: return Vector2(-offset.x, -offset.y)
		3: return Vector2(-offset.y, offset.x)
	return offset

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = global_position - get_global_mouse_position()  # Calculate the offset when dragging starts
			move_to_front()  # Ensure the card is rendered on top while dragging
			audio.stream = pickup_stream
			audio.play()
		else:
			dragging = false
			audio.stream = setdown_stream
			audio.play()
			# Add a bounce effect
			scale = original_scale * 1.2
			var timer = get_tree().create_timer(0.1)
			await timer.timeout  # Wait for 0.1 seconds
			scale = original_scale
			# Check if the mouse is outside the parent container
			var hand_container = get_parent()
			var mouse_position = hand_container.get_global_mouse_position()
			if not hand_container.get_rect().has_point(mouse_position):
				print("Mouse outside hand container") 
				card_handler.play_card(hand_idx)
	elif dragging and event is InputEventMouseMotion:
		target_position = get_global_mouse_position() + drag_offset  # Update target position based on the offset
