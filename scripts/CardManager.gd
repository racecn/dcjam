extends Node

# Load the StaticData script
const Card = preload("res://entities/Card.tscn")
@onready var hand_container = $HandContainer

# Define the card deck, hand, and discard pile
var deck: Array = []
var hand: Array = []
var discard_pile: Array = []
var card_data
var hand_index = 0

# Define the maximum number of cards in the hand
var deck_size: int = 25
var max_hand_size: int = 4


# Signals
signal hand_updated(hand)
signal enable_marker(affected_cells)  # Add parameter for affected cells
signal disable_marker()

func _ready():
	# Initialize the deck with cards from StaticData
	card_data = StaticData.card_data
	print("CardManager: Data type of card_data ", type_string(typeof(card_data)))

	#fillinf the deck w random cards
	for _i in range(deck_size):
		var random_index = randi() % card_data["cards"].size()
		var card_info = card_data["cards"][random_index]
		var card_instance = Card.instantiate()
		card_instance.set_card_data(card_info, false, 0)
		deck.append(card_instance)
	
	shuffle_deck()
	draw_cards(max_hand_size)
	print("Hand                         ", hand)
	

	# Connect signals to cells
	var cells = get_tree().get_nodes_in_group("cells")
	for cell in cells:
		enable_marker.connect(cell.on_enable_marker)  # Connect to the method in the Cell script
		disable_marker.connect(cell.on_disable_marker)  # Connect to the method in the Cell script

func shuffle_deck():
	deck.shuffle()

func handle_start_of_turn():
	# if the player has a hand size less than max_hand_size, draw cards until hand_size == max_hand_size
	pass


func draw_card():
	if deck.size() == 0:
		# If the deck is empty, reshuffle the discard pile into the deck
		deck = discard_pile.duplicate()
		discard_pile.clear()
		shuffle_deck()

	if deck.size() != 0 and hand.size() < max_hand_size:
		var card = deck.pop_front()
		hand.append(card)  # Add the drawn card to the hand
		card.update_hand_status(true, hand.size() - 1)
		update_hand()


func draw_cards(number_of_cards: int):
	for _i in range(number_of_cards):
		draw_card()

func discard_card(card_index: int):
	if card_index >= 0 and card_index < hand.size():
		# Remove the card from the hand and add it to the discard pile
		var card = hand.pop_back()
		discard_pile.append(card)
		
		# Shift cards to the left to fill the gap
		for i in hand.size() - 1:
			hand[i] = hand[i + 1] if i + 1 < hand.size() else null



func play_card(hand_index):
	# Remove the last card from the hand and play it
	var card = hand[hand_index]
	hand[hand_index].queue_free()
	# For demonstration purposes, just print the card being play
	draw_card()
	update_hand()
  # Use card.cardname to access the card's name
	# No need to shift cards in this implementation


func _on_HandDisplay_card_played(hand_index):
	play_card(hand_index)

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
		card_instance.mouse_entered.connect(Callable(self, "_on_card_mouse_entered"))  # Corrected syntax
		card_instance.mouse_exited.connect(Callable(self, "_on_card_mouse_exited"))  # Corrected syntax

func _on_card_mouse_entered(affected_cells):
	print("CardManager: Card mouse entered, affected cells: ", affected_cells)
	emit_signal("enable_marker", affected_cells)  # Emit signal to enable marker on affected cells

func _on_card_mouse_exited():
	print("CardManager: Card mouse exited")
	# Emit a signal to disable the marker on all cells
	emit_signal("disable_marker")  # Assuming you have a signal to disable markers
