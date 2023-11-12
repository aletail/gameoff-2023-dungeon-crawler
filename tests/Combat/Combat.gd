extends Node2D

var map
var character_manager

var monster_spwan_timer
var monster_spwan_timer_iterator
var monster_spawn_count = 0

func _ready():
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
	#monster_spwan_timer_iterator.one_shot = true
	monster_spwan_timer_iterator.wait_time = 0.2
	monster_spwan_timer_iterator.connect("timeout", self.SpawnMonsters)
	
#	for i in 100:
#		var rng = RandomNumberGenerator.new()
#		character_manager.SpawnMonster(map.ConvertToGlobal(Vector2(rng.randi_range(0, map.grid_size.x-1), rng.randi_range(0, map.grid_size.y-1))))
		
#	character_manager.SpawnMonster(map.ConvertToGlobal(Vector2(49, 49)))
#	character_manager.SpawnMonster(map.ConvertToGlobal(Vector2(15, 15)))
#	character_manager.SpawnMonster(map.ConvertToGlobal(Vector2(23, 45)))s
func StartSpawnTimer():
	monster_spwan_timer_iterator.start()
	#character_manager.setPartyState("Combat")
	
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
