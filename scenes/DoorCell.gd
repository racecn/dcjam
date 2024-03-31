extends Cell
class_name DoorCell

var isOpen = false
@onready var door_mesh: MeshInstance3D = $DoorMesh


func _ready():
	connect("card_marker_enabled", on_enable_marker)
	connect("card_marker_disabled", on_disable_marker)

func open():
	isOpen = true
	# Add code to animate the door opening or change its appearance
	door_mesh.visible = false  # Example: Hide the door mesh when opened

func close():
	isOpen = false
	# Add code to animate the door closing or change its appearance
	door_mesh.visible = true  # Example: Show the door mesh when closed

func toggle():
	if isOpen:
		close()
	else:
		open()
