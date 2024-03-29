extends Node

var cardData = {}

var data_file_path = "res://assets/cards/cards.json"

func _ready():
	cardData = load_json_file(data_file_path)

func load_json_file(filepath: String):
	if FileAccess.file_exists(filepath):
		var dataFile = FileAccess.open(filepath, FileAccess.READ)
		var parsedResult = JSON.parse_string(dataFile.get_as_text())
		
		if parsedResult is Dictionary:
			return parsedResult
		else:
			print("Error reading data")
	
	else:
		print("File does not exist")
