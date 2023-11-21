extends Control

func _ready():
	## Start Game Button
	var button_startgame = get_node("CenterContainer/ButtonContainer/NewGameButton")
	button_startgame.text = "Start Game"
	button_startgame.pressed.connect(self.start_game)

func start_game():
	# Packup properties that need shared between scenes
	var properties : Dictionary = {
	}
	var loading_scene_path = "res://scenes/Helpers/LoadingHelper.tscn"
	get_tree().change_scene_to_file(loading_scene_path)
