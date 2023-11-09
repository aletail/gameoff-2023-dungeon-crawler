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
	var rng = RandomNumberGenerator.new()
	var monsterspawn = Vector2i(rng.randi_range(0, map.grid_size.x-1), rng.randi_range(0, map.grid_size.y-1)) * map.cell_size 
	
	var start = Vector2i(monsterspawn) / map.cell_size
	var end = Vector2i(party.getLeader().position) / map.cell_size
	var monster_movelist = map.FindPath(start, end)
	
	for i in 50:
		monstermanager.SpawnMonster(monsterspawn)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var start = Vector2i(party.getLeader().position) / map.cell_size
			var end = Vector2i(get_global_mouse_position()) / map.cell_size
			party.getLeader().Move(map.FindPath(start, end))
