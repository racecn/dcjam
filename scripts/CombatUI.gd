extends Control

signal end_turn_pressed

@onready var end_turn_button: Button = $EndTurn
@onready var turn_indicator: Label = $TurnIndicator

func _ready() -> void:
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)
	hide_combat_ui()

func _on_end_turn_pressed() -> void:
	print_debug("End turn button pressed")
	emit_signal("end_turn_pressed")

func show_combat_ui() -> void:
	show()
	if end_turn_button:
		end_turn_button.show()
		end_turn_button.disabled = false

func hide_combat_ui() -> void:
	hide()
	if end_turn_button:
		end_turn_button.hide()
		end_turn_button.disabled = true

func set_turn_indicator(is_player_turn: bool) -> void:
	if turn_indicator:
		turn_indicator.text = "Your Turn" if is_player_turn else "Enemy Turn"
		turn_indicator.modulate = Color(0, 1, 0, 1) if is_player_turn else Color(1, 0, 0, 1)
