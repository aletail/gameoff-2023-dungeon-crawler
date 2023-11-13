extends Node2D

var map
var character_manager
var camera

var monster_spwan_timer
var monster_spwan_timer_iterator
var monster_spawn_count = 0

func _ready():
	camera = get_node("Camera2D")
	
	map = Map.new(Vector2i(16,16), Vector2i(50,50))
	add_child(map)
	
	character_manager = CharacterManager.new(map)
	add_child(character_manager)

	character_manager.SpawnParty(map.ConvertToGlobal(Vector2(20, 20)))
	
	monster_spwan_timer = Timer.new()
	add_child(monster_spwan_timer)
	monster_spwan_timer.autostart = false
	monster_spwan_timer.wait_time = 3
	monster_spwan_timer.connect("timeout", self.StartSpawnTimer)
	monster_spwan_timer.start()
	
	monster_spwan_timer_iterator = Timer.new()
	add_child(monster_spwan_timer_iterator)
	monster_spwan_timer_iterator.autostart = false
	monster_spwan_timer_iterator.wait_time = 0.2
	monster_spwan_timer_iterator.connect("timeout", self.SpawnMonsters)
	
func _process(delta):
	if(character_manager.PartyPosition):
		camera.position = camera.position.lerp(character_manager.PartyPosition, delta * 5)
		
	if(character_manager.PartyState=="Combat"):
		camera.zoom = camera.zoom.lerp(Vector2(1, 1), delta * 1.25)
	else:
		camera.zoom = camera.zoom.lerp(Vector2(2, 2), delta * 1.25)
	
func StartSpawnTimer():
	monster_spwan_timer_iterator.start()
	character_manager.setPartyState("Combat")
	
func SpawnMonsters():
	if(monster_spawn_count < 50):
		var sp = map.ConvertToGlobal(Vector2(map.grid_size.x-1, monster_spawn_count))
		character_manager.SpawnMonster(sp)
		monster_spawn_count+=1
		
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var start = Vector2i(character_manager.Heroes[0].getPosition()) / map.cell_size
			var end = Vector2i(get_global_mouse_position()) / map.cell_size
			character_manager.Heroes[0].Move(map.FindPath(start, end))
