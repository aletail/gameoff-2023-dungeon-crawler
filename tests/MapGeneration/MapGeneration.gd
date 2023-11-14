extends Node2D

var map
var camera_movement = Vector2(0,0)
var camera_speed = 1000
var character_manager

func _ready():
	map = Map.new(Vector2i(16,16), Vector2i(200,50))
	add_child(map)
	
	character_manager = CharacterManager.new(map)
	add_child(character_manager)

	character_manager.SpawnParty(map.ConvertToGlobal(map.get_spawn_point()))
	
func _process(delta):
	get_node("Camera2D").position += (camera_movement * delta)
	camera_movement.x = 0
	camera_movement.y = 0
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var start = Vector2i(character_manager.Heroes[0].getPosition()) / map.cell_size
			var end = Vector2i(get_global_mouse_position()) / map.cell_size
			character_manager.Heroes[0].Move(map.FindPath(start, end))
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_W:
			camera_movement.y = -camera_speed
		if event.keycode == KEY_A:
			camera_movement.x = -camera_speed
		if event.keycode == KEY_S:
			camera_movement.y = camera_speed
		if event.keycode == KEY_D:
			camera_movement.x = camera_speed
