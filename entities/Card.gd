extends Control

@export_category("Card Attributes")
@export var cardname: String
@export var type: String
@export var mana_cost: int
@export var description: String
@export var effects: Array
@export var area_of_effect : Array
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

signal card_marker_enabled(pos)

func _process(delta):
	if not dragging:
		position = position.lerp(original_position, delta * 5)  # Adjust speed as needed

func _ready():
	player = get_tree().get_nodes_in_group("player")[0]
	original_position = position
	original_scale = scale
	update_card_visuals()


func set_card_data(card_data: Dictionary):
	cardname = card_data["name"]
	type = card_data["type"]
	mana_cost = card_data["mana_cost"]
	description = card_data["description"]
	effects = card_data["effects"]
	area_of_effect = card_data["area_of_effect"]["shape"]
	call_deferred("update_card_visuals")


func update_card_visuals():
	# Update the card's texture and name based on the card attributes
	var texture_path = "res://assets/textures/cards/" + cardname + ".png"
	var texture: Texture = load(texture_path)
	if texture:
		if sprite:
			sprite.texture = texture
		else:
			print("sprite is Nil")
	print("card name passed to update visuals ", cardname)
	if nameLabel:
		nameLabel.text = cardname
	else:
		print("nameLabel is Nil")

func _on_mouse_entered():
	var affected_cells = calculate_affected_cells()
	emit_signal("card_marker_enabled", affected_cells, true)

func _on_mouse_exited():
	emit_signal("card_marker_enabled", [], false)

func get_player_orientation() -> int:
	return player.orientation

func calculate_affected_cells() -> Array:
	var affected_positions = []
	var player_orientation = get_player_orientation()
	var player_position = get_player_position()
	for relative_pos_array in area_of_effect:
		var relative_pos_vector = Vector2(relative_pos_array[0], relative_pos_array[1])
		var transformed_offset = transform_offset_by_orientation(relative_pos_vector, player_orientation)
		var affected_position = player_position + transformed_offset
		affected_positions.append(Vector2(floor(affected_position.x), floor(affected_position.y)))
	return affected_positions

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
		audio.stream = pickup_stream
		audio.play()
		if event.pressed:
			dragging = true
			drag_offset = global_position - get_global_mouse_position()
			move_to_front()  # Ensure the card is rendered on top while dragging
		else:
			dragging = false
	elif dragging and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + drag_offset

