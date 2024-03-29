extends Node3D

# Movement speed (units per second)
var speed = 10.0
# Turn speed (degrees per second)
var rotation_speed = 20.0
# Current target position for snapping
var target_position: Vector3
# Current target rotation for snapping (in degrees)
var target_rotation_degrees: float = 0.0
# Current rotation (in degrees)
var current_rotation_degrees: float = 0.0
# Turning control variables
var is_turning = false
var turn_direction = 0
var can_move = true
var is_paused = false
var is_in_combat = false

# Raycasts
@onready var ray_forward: RayCast3D = $RayForward
@onready var ray_back: RayCast3D = $RayBack
@onready var ray_left: RayCast3D = $RayLeft
@onready var ray_right: RayCast3D = $RayRight
@onready var pause_popup = $PausePopup  # Adjust the path to your pause popup node

# Camera
@onready var camera: Camera3D = $Control/SubViewportContainer/SubViewport/Camera3D
# Timer for continuous turning
@onready var turn_timer: Timer = $TurnTimer
# audio
@onready var audioPlayer: AudioStreamPlayer3D = $Control/SubViewportContainer/SubViewport/AudioStreamPlayer3D

@onready var handContainer: PanelContainer = $Control/handContainer
@onready var textContainer: TextEdit = $Control/handContainer/TextEdit

# Combat
signal combat_started
signal combat_ended

# Card deck properties
var deck = {}
var hand = []
var card_scene = preload("res://entities/Card.tscn")  # Adjust the path to your card scene

# Deck keys
var deck_keys = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	target_position = global_transform.origin
	target_rotation_degrees = rotation_degrees.y
	current_rotation_degrees = rotation_degrees.y
	initialize_deck()
	shuffle_deck()
	fill_hand(3)
	print_hand()
	render_hand()  # Add this line to render the hand

func _process(delta):
	if is_paused:
		return
	camera.rotation_degrees.y = rotation_degrees.y
	camera.position = position
	
	if can_move and !is_in_combat:
		var direction = Vector3.ZERO

		# Get input for movement
		if Input.is_action_just_pressed("move_forward") and not ray_forward.is_colliding():
			direction -= camera.global_transform.basis.z
			audioPlayer.play()
		elif Input.is_action_just_pressed("move_backward") and not ray_back.is_colliding():
			direction += camera.global_transform.basis.z
		elif Input.is_action_just_pressed("move_left") and not ray_left.is_colliding():
			direction -= camera.global_transform.basis.x
		elif Input.is_action_just_pressed("move_right") and not ray_right.is_colliding():
			direction += camera.global_transform.basis.x

		# Snap to the next cell if a movement key was pressed
		if direction != Vector3.ZERO:
			direction = direction.normalized()
			target_position += direction.round()
			can_move = false
			$MovementCooldownTimer.start()

	# Check for turn input
	if Input.is_action_just_pressed("turn_left"):
		start_turning(-1)
	elif Input.is_action_just_pressed("turn_right"):
		start_turning(1)
	elif Input.is_action_just_released("turn_left") or Input.is_action_just_released("turn_right"):
		stop_turning()

	# Move towards the target position
	global_transform.origin = global_transform.origin.lerp(target_position, speed * delta)

	# Smoothly rotate the player if turning
	if is_turning and turn_timer.is_stopped():
		target_rotation_degrees += turn_direction * 90.0
		turn_timer.start()  # Restart the timer for continuous turning
	current_rotation_degrees = lerp(current_rotation_degrees, deg_to_rad(target_rotation_degrees), rotation_speed * delta)
	rotation_degrees.y = rad_to_deg(current_rotation_degrees)

func start_turning(direction: int):
	is_turning = true
	turn_direction = -direction
	target_rotation_degrees += turn_direction * 90.0  # Initial turn
	turn_timer.start()

func stop_turning():
	is_turning = false
	turn_timer.stop()

func _on_movement_cooldown_timer_timeout():
	can_move = true

func _input(event):
	if event.is_action_pressed("pause"):  # Adjust the action name as needed
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	if is_paused:
		pause_popup.show()
	else:
		pause_popup.hide()

func enter_combat():
	emit_signal("combat_started")
	is_in_combat = true
	# Additional actions for entering combat, e.g., switching to a combat UI

func exit_combat():
	emit_signal("combat_ended")
	is_in_combat = false
	# Additional actions for exiting combat, e.g., switching back to normal UI

# Connect this function to the enemy's collision signal
func _on_enemy_collision(enemy):
	enter_combat()

# Card deck methods
func readJSON(json_file_path):
	var file = FileAccess.open(json_file_path, FileAccess.READ)
	if not file:
		print("Failed to load JSON data from", json_file_path)
		return {}

	var content = file.get_as_text()
	var json = JSON.new()
	var finish = json.parse(content)
	file.close()

	if typeof(finish) != TYPE_DICTIONARY:
		print("Failed to parse JSON data")
		return {}

	return finish

func initialize_deck():
	var card_data = StaticData.cardData["cards"]
	for card in card_data:
		deck[card["name"]] = card
	deck_keys = deck.keys()
	print("Deck initialized:", deck_keys)

func shuffle_deck():
	var shuffled_keys = deck_keys.duplicate()
	shuffled_keys.shuffle()
	
	var shuffled_deck = {}
	for key in shuffled_keys:
		shuffled_deck[key] = deck[key]
	
	deck = shuffled_deck

func draw_cards(number_of_cards):
	var drawn_cards = []
	for i in range(number_of_cards):
		if deck_keys.size() > 0:
			var card_key = deck_keys[randi() % deck_keys.size()]
			var card = deck[card_key]
			drawn_cards.append(card)
			deck.erase(card_key)
			deck_keys.erase(card_key)
		else:
			print("No more cards in the deck.")
			break
	return drawn_cards

func fill_hand(num_cards: int):
	for i in range(num_cards):
		var drawn_cards = draw_cards(1)
		if drawn_cards.size() > 0:
			hand.append(drawn_cards[0])

func print_hand():
	var hand_text = "Hand:\n"
	for card in hand:
		hand_text += str(card) + "\n"
	textContainer.text = hand_text

func play_card(card_name: String):
	for card_idx in range(hand.size()):
		if hand[card_idx]["name"] == card_name:
			# Perform card effect based on type (Attack, Defense, etc.)
			if hand[card_idx]["type"] == "Attack":
				# Implement attack logic
				print("Performing attack with", card_name)
			elif hand[card_idx]["type"] == "Defense":
				# Implement defense logic
				print("Performing defense with", card_name)
			# Remove the played card from the hand
			hand.remove(card_idx)
			print("Remaining hand after playing", card_name)
			print_hand()
			break
			
func render_hand():
	# Clear the previous cards
	for child in handContainer.get_children():
		if child.is_in_group("card"):
			child.queue_free()

	# Determine the number of cards and the dimensions of the PanelContainer
	var num_cards = hand.size()
	var panel_width = handContainer.custom_minimum_size.x
	var panel_height = handContainer.custom_minimum_size.y
	var card_width = 50

	# Adjust the overlap and fan angle based on the number of cards
	var overlap = min(card_width * 0.8, panel_width / num_cards)
	var fan_angle = min(10, 150 / max(1, num_cards))  # Avoid division by zero

	# Calculate the starting x position to center the cards in the PanelContainer
	var start_x = (panel_width - (card_width - overlap) * num_cards) / 2

	for i in range(num_cards):
		var card_instance = card_scene.instantiate()
		if card_instance:
			card_instance.set_card_data(hand[i])

			# Calculate the fan angle and set the pivot offset
			var angle_rad = deg_to_rad(fan_angle * (i - (num_cards - 1) / 2))
			card_instance.rotation_degrees = rad_to_deg(angle_rad)

			# Calculate the card's position
			var card_pos = Vector2(start_x + i * (card_width - overlap), panel_height - card_instance.custom_minimum_size.y / 2)
			card_instance.position = card_pos

			# Calculate and apply an offset to align the rotation along the bottom edge of the card
			var offset_x = (card_width / 2) * (1 - cos(angle_rad))
			var offset_y = (card_width / 2) * sin(angle_rad)
			card_instance.position += Vector2(offset_x, offset_y)

			handContainer.add_child(card_instance)
			card_instance.add_to_group("card")
		else:
			print("Error loading card scene.")
