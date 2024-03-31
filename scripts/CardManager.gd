extends Node

# Load the StaticData script
const Card = preload("res://entities/Card.tscn")
@onready var hand_container = $HandContainer

# Define the card deck, hand, and discard pile
var deck: Array = []
var hand: Array = []
var discard_pile: Array = []
var card_data

# Define the maximum number of cards in the hand
var deck_size: int = 25
var max_hand_size: int = 4

# Signals
signal hand_updated(hand)

func _ready():
	# Initialize the deck with cards from StaticData
	card_data = StaticData.card_data
	print("Data type of card_data ", type_string(typeof(card_data)))
	

	for _i in range(deck_size):
		var random_index = randi() % card_data["cards"].size()
		var card_info = card_data["cards"][random_index]
		var card_instance = Card.instantiate()
		card_instance.set_card_data(card_info)
		deck.append(card_instance)
	shuffle_deck()
	draw_cards(max_hand_size)

func shuffle_deck():
	deck.shuffle()

func draw_card():
	if deck.size() == 0:
		# If the deck is empty, reshuffle the discard pile into the deck
		deck = discard_pile.duplicate()
		discard_pile.clear()
		shuffle_deck()

	if deck.size() != 0 and hand.size() < max_hand_size:
		# Draw the top card from the deck and add it to the hand
		var card = deck.pop_front()
		hand.append(card)
		update_hand()

func draw_cards(number_of_cards: int):
	for _i in range(number_of_cards):
		draw_card()

func discard_card(card_index: int):
	if card_index >= 0 and card_index < hand.size():
		# Remove the card from the hand and add it to the discard pile
		var card = hand.pop_back()
		discard_pile.append(card)
		emit_signal("hand_updated", hand)

func play_card(card_index: int):
	if card_index >= 0 and card_index < hand.size():
		var card = hand[card_index]
		# For demonstration purposes, just print the card being played
		print("Playing card: " + card.name)
		discard_card(card_index)
		# Handle card effects here

func _on_HandDisplay_card_played(card_index: int):
	play_card(card_index)

func update_hand():
	render_hand()

func render_hand():
	hand_container.queue_free()
	hand_container = Control.new()
	self.add_child(hand_container)
	# Set size and position of hand_container here if needed

	var position_step = Vector2(150, 0)  # Adjust this for spacing between cards

	for i in range(hand.size()):
		var card_instance = hand[i]
		if card_instance.get_parent():
			card_instance.get_parent().remove_child(card_instance)

		# Now position_step only affects the x-coordinate relative to hand_container
		card_instance.position = Vector2(position_step.x * i, 0)
		hand_container.add_child(card_instance)
		card_instance.connect("card_mouse_entered", _on_card_mouse_entered)
		card_instance.connect("card_mouse_exited", _on_card_mouse_exited)

func _on_card_mouse_entered(affected_cells):
	print("Parent CardManager reached")
	var all_cells = get_tree().get_nodes_in_group("cells")  # Assuming 'cells' is the group name for your cell nodes

	for cell in all_cells:
		var cell_position = cell.grid_position  # Assuming each cell has a 'grid_position' property
		for affected_position in affected_cells:
			if cell_position == affected_position:
				cell.on_enable_marker()  # Call the method to highlight or indicate the cell is affected


func _on_card_mouse_exited():
	var parent_node = get_parent()
	# Assuming each cell has a method called 'clear_highlight' to remove its affected indication
	for i in range(parent_node.get_child_count()):
		var child = parent_node.get_child(i)
		if "Cell" in child.name:  # Adjust the naming convention as needed
			child.on_disable_marker()
