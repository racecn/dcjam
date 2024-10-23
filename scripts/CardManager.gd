extends Node

const Card = preload("res://entities/Card.tscn")

# Node references with error checking
@onready var hand_container: Control = $HandContainer
@onready var card_sound: AudioStreamPlayer = $card_sound
@onready var mana_sound: AudioStreamPlayer = $mana_sound

# Game state
var deck: Array[Node] = []
var hand: Array[Node] = []
var discard_pile: Array[Node] = []
var card_data: Dictionary
var hand_index: int = 0
var combatHandler: Node
var player: Node

# Configuration
@export_range(1, 100) var deck_size: int = 25
@export_range(1, 10) var max_hand_size: int = 4
@export var position_step: Vector2 = Vector2(150, 0)

# Signals
signal hand_updated(hand: Array[Node])
signal enable_marker(affected_cells: Array)
signal disable_marker
signal card_play_failed(reason: String)
signal deck_shuffled

func _ready() -> void:
	_initialize_game_state()
	_setup_initial_hand()
	_connect_signals()
	
func handle_combat_start() -> void:
	print_debug("CardManager: Combat starting")
	# Make sure hand is properly initialized
	draw_cards(max_hand_size)
	update_hand()
	# Ensure the hand container is visible and interactive
	if hand_container:
		hand_container.process_mode = Node.PROCESS_MODE_ALWAYS
		hand_container.visible = true
		hand_container.mouse_filter = Control.MOUSE_FILTER_STOP

func handle_turn_start() -> void:
	print_debug("CardManager: Player turn starting")
	# Draw up to max hand size
	while get_hand_size() < max_hand_size:
		draw_card()
	update_hand()
	# Make sure cards are interactive
	for card in hand:
		if card:
			card.process_mode = Node.PROCESS_MODE_ALWAYS
			card.mouse_filter = Control.MOUSE_FILTER_STOP


# Update update_hand to ensure cards remain interactive
func update_hand() -> void:
	render_hand()
	# Make sure cards are interactive
	for card in hand:
		if card:
			card.process_mode = Node.PROCESS_MODE_ALWAYS
			card.mouse_filter = Control.MOUSE_FILTER_STOP
	emit_signal("hand_updated", hand)
	

func _clear_hand() -> void:
	print_debug("Clearing hand")
	for i in range(hand.size()):
		if hand[i] != null:
			discard_pile.append(hand[i])
			hand[i] = null
	update_hand()

func draw_card() -> bool:
	if deck.is_empty() and not discard_pile.is_empty():
		_reshuffle_discard_into_deck()
	
	if deck.is_empty():
		push_warning("CardManager: Cannot draw card - deck and discard pile are empty")
		return false
	
	var empty_slot = hand.find(null)
	if empty_slot == -1:
		push_warning("CardManager: Cannot draw card - hand is full")
		return false
	
	print_debug("Drawing card to slot: ", empty_slot)
	var card = deck.pop_front()
	hand[empty_slot] = card
	if card:
		card.set_hand_position(empty_slot)
	update_hand()
	return true

func draw_cards(number_of_cards: int) -> void:
	print_debug("Attempting to draw ", number_of_cards, " cards")
	var cards_drawn = 0
	for _i in range(number_of_cards):
		if draw_card():
			cards_drawn += 1
	print_debug("Successfully drew ", cards_drawn, " cards")

func get_hand_size() -> int:
	var size = 0
	for card in hand:
		if card != null:
			size += 1
	return size


func _initialize_game_state() -> void:
	if not _validate_dependencies():
		push_error("CardManager: Failed to initialize due to missing dependencies")
		return
		
	# Initialize hand with null values
	hand.resize(max_hand_size)
	hand.fill(null)
	
	# Load and validate card data
	_load_card_data()
	_initialize_deck()

func _validate_dependencies() -> bool:
	if not is_instance_valid(hand_container):
		push_error("CardManager: HandContainer node not found")
		return false
	if not is_instance_valid(card_sound):
		push_warning("CardManager: card_sound node not found - sound effects disabled")
	if not is_instance_valid(mana_sound):
		push_warning("CardManager: mana_sound node not found - mana sound effects disabled")
		
	# Get required nodes from parent
	var parent = get_parent()
	if not parent:
		push_error("CardManager: No parent node found")
		return false
		
	combatHandler = parent.get_node("CombatHandler")
	player = parent.get_node("Player")
	
	if not is_instance_valid(combatHandler):
		push_error("CardManager: CombatHandler not found")
		return false
	if not is_instance_valid(player):
		push_error("CardManager: Player not found")
		return false
		
	return true

func _load_card_data() -> void:
	if not "card_data" in StaticData:
		push_error("CardManager: card_data not found in StaticData")
		return
	card_data = StaticData.card_data

func _initialize_deck() -> void:
	if not card_data or not "cards" in card_data:
		push_error("CardManager: Invalid card data format")
		return
		
	for _i in range(deck_size):
		var card_instance = _create_random_card()
		if card_instance:
			deck.append(card_instance)
	
	shuffle_deck()

func _create_random_card() -> Node:
	if not card_data or not "cards" in card_data:
		push_error("CardManager: Cannot create card - invalid card data")
		return null
		
	var cards = card_data["cards"]
	if cards.size() == 0:
		push_error("CardManager: No cards defined in card data")
		return null
		
	var random_index = randi() % cards.size()
	var card_info = cards[random_index]
	
	var card_instance = Card.instantiate()
	if not card_instance:
		push_error("CardManager: Failed to instantiate card scene")
		return null
		
	card_instance.set_card_data(card_info, false, 0)
	return card_instance

func _setup_initial_hand() -> void:
	draw_cards(max_hand_size)
	print_debug("Initial hand setup complete: ", hand)

func _connect_signals() -> void:
	for cell in get_tree().get_nodes_in_group("cells"):
		if not cell.is_connected("enable_marker", cell.on_enable_marker):
			enable_marker.connect(cell.on_enable_marker)
		if not cell.is_connected("disable_marker", cell.on_disable_marker):
			disable_marker.connect(cell.on_disable_marker)

func shuffle_deck() -> void:
	if deck.size() > 0:
		deck.shuffle()
		emit_signal("deck_shuffled")

func handle_start_of_turn() -> void:
	var cards_to_draw = max_hand_size - get_hand_size()
	if cards_to_draw > 0:
		draw_cards(cards_to_draw)

func _reshuffle_discard_into_deck() -> void:
	deck = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_deck()

func discard_card(hand_pos: int) -> void:
	if not _is_valid_hand_position(hand_pos):
		push_error("CardManager: Invalid hand position for discard: " + str(hand_pos))
		return
	
	var card = hand[hand_pos]
	if card:
		discard_pile.append(card)
		hand[hand_pos] = null
		update_hand()

func _is_valid_hand_position(pos: int) -> bool:
	return pos >= 0 and pos < hand.size()

func play_card(hand_index: int) -> bool:
	if not GlobalVars.in_combat:
		print_debug("Cannot play card outside of combat")
		return false

	print_debug("Attempting to play card at index: ", hand_index)
	if not combatHandler or combatHandler.combat_state != combatHandler.CombatState.PLAYER_TURN:
		print_debug("Cannot play card - not player's turn")
		return false
	
	var card = hand[hand_index]
	if not _validate_card_data(card):
		return false
	
	if not _check_mana_cost(card):
		return false
	
	_play_card_sound(card)
	_apply_card_effects(card)
	_move_card_to_discard(hand_index)
	
	return true

func _can_play_card(hand_index: int) -> bool:
	if combatHandler.combat_state == combatHandler.CombatState.NOT_IN_COMBAT:
		emit_signal("card_play_failed", "Cannot play cards outside of combat")
		return false
	
	if not _is_valid_hand_position(hand_index):
		emit_signal("card_play_failed", "Invalid hand position")
		return false
	
	return true

func _validate_card_data(card: Node) -> bool:
	if not card or not "mana_cost" in card:
		emit_signal("card_play_failed", "Invalid card data")
		return false
	return true

func _check_mana_cost(card: Node) -> bool:
	if player.mana < card["mana_cost"]:
		emit_signal("card_play_failed", "Not enough mana")
		if is_instance_valid(mana_sound):
			mana_sound.play()
		return false
	
	player.mana -= card["mana_cost"]
	return true

func _play_card_sound(card: Node) -> void:
	if is_instance_valid(card_sound):
		match card.cardname:
			"Fireball", "Slash", "Shield", "Evade":
				card_sound.play()

func _apply_card_effects(card: Node) -> void:
	combatHandler.apply_card_effect_to_enemy(card)
	
	for effect in card["effects"]:
		if not effect is Dictionary:
			continue
			
		match effect.get("type"):
			"Damage":
				combatHandler.damage_enemy(effect)
			"Move":
				combatHandler.move_player(effect)
	
	if "Apply" in card["effects"]:
		combatHandler.apply_status_to_enemy(card["effects"]["Apply"])

func _move_card_to_discard(hand_index: int) -> void:
	var card = hand[hand_index]
	hand[hand_index] = null
	discard_pile.append(card)
	update_hand()

func render_hand() -> void:
	# Remove old hand container
	if is_instance_valid(hand_container):
		hand_container.queue_free()
	
	# Create new hand container
	hand_container = Control.new()
	add_child(hand_container)
	
	# Render cards
	for i in range(hand.size()):
		var card_instance = hand[i]
		if is_instance_valid(card_instance):
			if card_instance.get_parent():
				card_instance.get_parent().remove_child(card_instance)
			
			card_instance.position = Vector2(position_step.x * i, 0)
			hand_container.add_child(card_instance)

# Signal handlers for card hover
func _on_Card_mouse_entered(affected_cells: Array) -> void:
	print_debug("CardManager: Card mouse entered, affected cells: ", affected_cells)
	emit_signal("enable_marker", affected_cells)

func _on_Card_mouse_exited() -> void:
	print_debug("CardManager: Card mouse exited")
	emit_signal("disable_marker")
