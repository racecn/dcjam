extends Node3D

@export var textures = [
	preload("res://assets/textures/torch/SD_Anim_Frame_0.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_1.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_2.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_3.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_4.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_5.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_6.png"),
	preload("res://assets/textures/torch/SD_Anim_Frame_7.png")
]


func _ready():
	var animation_player = $AnimationPlayer
	var animation_name = "torch_flame"
	var sprite_3d = $Sprite3D
	var anim_length = 1.0 # Total length of the animation in seconds

	# Create a new animation
	var anim = Animation.new()
	anim.length = anim_length
	anim.loop = true  # Set to false if you do not want the animation to loop

	# Create a track for the texture property
	anim.add_track(Animation.TYPE_VALUE)
	var track_idx = anim.get_track_count() - 1
	anim.track_set_path(track_idx, str(sprite_3d.get_path()) + ":material_override/albedo_texture")

	# Insert the keyframes
	var frame_length = anim_length / textures.size() # Length of each frame in the animation
	for i in range(textures.size()):
		anim.track_insert_key(track_idx, i * frame_length, textures[i])

	# Add the animation to the AnimationPlayer and play it

	animation_player.play(animation_name)
