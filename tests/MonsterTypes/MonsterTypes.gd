extends Node2D

var map
var character_manager
var camera

func _ready():
	camera = get_node("Camera2D")
	
	map = Map.new(Vector2i(16,16), Vector2i(200,50))
	add_child(map)
	
	character_manager = CharacterManager.new(map)
	add_child(character_manager)

	character_manager.SpawnParty(map.get_spawn_point())
	
func _process(delta):
	if(character_manager.PartyPosition):
		camera.position = camera.position.lerp(character_manager.PartyPosition, delta * 5)
		
	if(character_manager.PartyState=="Combat"):
		camera.zoom = camera.zoom.lerp(Vector2(1, 1), delta * 1.25)
	else:
		camera.zoom = camera.zoom.lerp(Vector2(1.75, 1.75), delta * 1.25)
			
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var start = Vector2i(character_manager.Heroes[0].getPosition()) / map.cell_size
			var end = Vector2i(get_global_mouse_position()) / map.cell_size
			character_manager.Heroes[0].Move(map.FindPath(start, end))
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			SpawnMonster()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_2:
			SpawnBossMonster()
			
func SpawnMonster():
	var p = map.get_offscreen_spawn_point(character_manager.PartyPosition)
	if p:
		character_manager.SpawnMonster(p)
	else:
		print("No spawn position found")
		
func SpawnBossMonster():
	var p = map.get_offscreen_spawn_point(character_manager.PartyPosition)
	if p:
		character_manager.SpawnBossMonster(p)
	else:
		print("No spawn position found")
