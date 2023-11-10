extends Node2D

var map
var party
var monstermanager

func _ready():
	map = Map.new(Vector2i(16,16), Vector2i(50,50))
	add_child(map)
	
	party = PartyManager.new()
	add_child(party)
	
	monstermanager = MonsterManager.new(map, party)
	add_child(monstermanager)
	
	# Get random monster spawn position
	for i in 100:
		var rng = RandomNumberGenerator.new()
		var monsterspawn = Vector2i(rng.randi_range(0, map.grid_size.x-1), map.grid_size.y-1) * map.cell_size 
		monstermanager.SpawnMonster(monsterspawn)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			for i in monstermanager.Monsters.size():
				var start = Vector2i(monstermanager.Monsters[i].getPosition()) / map.cell_size
				var end = Vector2i(get_global_mouse_position()) / map.cell_size
				monstermanager.Monsters[i].Move(map.FindPath(start, end))
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var start = Vector2i(party.getLeader().getPosition()) / map.cell_size
			var end = Vector2i(get_global_mouse_position()) / map.cell_size
			party.getLeader().Move(map.FindPath(start, end))
