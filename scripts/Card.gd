extends Node  # Changed from RefCounted to Node for scene compatibility

class_name Card

var card_name: String = ""
var description: String = ""
var mana_cost: int = 0
var texture_name: String = ""  # Added texture_name for card rendering

func _init(card_data: Dictionary):
	name = card_data["name"]
	description = card_data["description"]
	mana_cost = card_data["mana_cost"]
	texture_name = card_data["texture_name"]  # Initialize texture_name

func use():
	print("Using card: %s" % name)

func set_card_data(card_data: Dictionary):
	name = card_data["name"]
	description = card_data["description"]
	mana_cost = card_data["mana_cost"]
	texture_name = card_data["texture_name"]  # Set texture_name
