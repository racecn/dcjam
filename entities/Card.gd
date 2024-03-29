extends Control

@onready var nameLabel: Label = $Name

var card_data: Dictionary = {}

func _ready():
	# Set the size and position of the card based on its parent container
	var parent_size: Vector2 = get_parent().custom_minimum_size
	custom_minimum_size = parent_size * 0.8
	position = (parent_size - custom_minimum_size) / 2

func set_card_data(data: Dictionary):
	card_data = data
	update_card_visuals()

func update_card_visuals():
	# Update the card's texture and name based on the card data provided
	if "texture_path" in card_data:
		var texture: Texture = load(card_data["texture_path"])
		if texture:
			$Sprite2D.texture = texture
	if "name" in card_data:
		$Name.text = card_data["name"]
