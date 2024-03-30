extends Node

var card_data = {}
var deck: Array = []
var data_file_path = "res://assets/cards/cards.json"

func _ready():
	card_data = load_json_file(data_file_path)

func load_json_file(filepath: String) -> Dictionary:
	if FileAccess.file_exists(filepath):
		var data_file = FileAccess.open(filepath, FileAccess.READ)
		var json_text = data_file.get_as_text()
		data_file.close()

		var json_parser = JSON.new()
		var error = json_parser.parse(json_text)
		if error == OK:
			return json_parser.data
		else:
			print("Error parsing JSON: " + str(error))
	else:
		print("File does not exist: " + filepath)
	return {}
