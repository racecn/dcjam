extends Node

# Load the StaticData script
const Card = preload("res://entities/Card.tscn")
@onready var hand_container = $HandContainer
@onready var card_sound = $card_sound
@onready var mana_sound = $mana_sound

# Define the card deck, hand, and discard pile
var deck: Array = []
var hand: Array = []
var discard_pile: Array = []
var card_data
var hand_index = 0
var combatHandler 
var player


# Define the maximum number of cards in the hand
var deck_size: int = 25
var max_hand_size: int = 4

@export var position_step = Vector2(150, 0)  # Adjust this for spacing between cards


# Signals
signal hand_updated(hand)
signal enable_marker(affected_cells)  # Add parameter for affected cells
signal disable_marker()

func _ready():
	# Initialize the deck with cards from StaticData
	card_data = StaticData.card_data
	combatHandler = get_parent().get_node("CombatHandler")
	player = get_parent().get_node("Player")
	
	
	# Initialize the hand with null values
	for i in range(max_hand_size):
		hand.append(null)


	# Fill the deck with random cards
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
	print("hand size ", get_hand_size())
	while get_hand_size() < max_hand_size:
		draw_card()
	update_hand()


func get_hand_size():
	var size = 0
	for card in hand:
		if card != null:
			size += 1
	return size


func draw_card():
	if deck.size() == 0:
		# If the deck is empty, reshuffle the discard pile into the deck
		deck = discard_pile.duplicate()
		discard_pile.clear()
		shuffle_deck()
		draw_card()

	#if deck is not empty
	if deck.size() != 0:
		for i in range(hand.size()):
			if hand[i] == null:
				var card = deck.pop_front()
				hand[i] = card
				card.set_hand_position(i)
				print("new hand pos for ", card["name"], " = ", i)
				update_hand()
				break

func draw_cards(number_of_cards: int):
	for _i in range(number_of_cards):
		draw_card()

func discard_card(hand_pos):
	# Remove the card from the hand and add it to the discard pile
	var card = hand[hand_pos]
	discard_pile.append(card)
	hand[hand_pos] = null
	update_hand()



func play_card(hand_index):
	# Check if it's the player's turn and if you're in combat
	if combatHandler.combat_state == combatHandler.CombatState.NOT_IN_COMBAT:
		print("Cannot play card right now")
		return
	
	var card = hand[hand_index]
	
	# Check if the card is not null and has a "mana_cost" property
	if card != null and "mana_cost" in card:
		if player.mana < card["mana_cost"]:
			print("Cannot play card, not enough mana")
			mana_sound.play()
			return
		
		print("Subtracting mana")
		player.mana -= card["mana_cost"]
	else:
		print("Invalid card data")
		return

	# Print the card name to the console
	print("Play card: ", card)
	
	# Play the appropriate sound for playing a card
	# For example, if you have a sound node named "card_play_sound" attached to the CardManager node:
	match card.cardname:
		"Fireball":
			card_sound.play()
		"Slash":
			card_sound.play()
		"Shield":
			card_sound.play()
		"Evade":
			card_sound.play()

	# Perform the card action (you'll need to define this based on your game's logic)
	# For example, if the card has an effect on the enemy, you might call a function like:
	combatHandler.apply_card_effect_to_enemy(card)

	# Update enemy stats (if applicable)
	# For example, if the card deals damage to the enemy, you might call a function like:
	for effect in card["effects"]:
		if "type" in effect and effect["type"] == "Damage":
			combatHandler.damage_enemy(effect)

	# Update player stats (if applicable)
	# For example, if the card provides a buff to the player, you might call a function like:
	if "Apply" in card["effects"]:
		combatHandler.apply_status_to_enemy(card["effects"]["Apply"])
	
	for effect in card["effects"]:
		if "type" in effect and effect["type"] == "Move":
			combatHandler.move_player(effect)
	# Remove the card from the hand and play it
	hand[hand_index] = null
	discard_pile.append(card)
	update_hand()





func _on_HandDisplay_card_played(hand_index):
	play_card(hand_index)

func update_hand():
	render_hand()

func render_hand():
	hand_container.queue_free()
	hand_container = Control.new()
	self.add_child(hand_container)
	# Set size and position of hand_container here if needed

	for i in range(hand.size()):
		if hand[i] != null:
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
