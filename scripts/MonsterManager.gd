class_name MonsterManager extends Node2D

var Monsters:Array = []
var TargetTimer
var TargetCount = 0
var SpawnTimer
var WakeCount = 0
var Map
var Party

func _init(map, party):
	Map = map
	Party = party

func _ready():
	TargetTimer = Timer.new()
	add_child(TargetTimer)
	TargetTimer.autostart = true
	TargetTimer.wait_time = 0.1
	TargetTimer.start()
	TargetTimer.connect("timeout", self.UpdateTarget)
	
	SpawnTimer = Timer.new()
	add_child(SpawnTimer)
	SpawnTimer.autostart = true
	SpawnTimer.wait_time = 2
	SpawnTimer.start()
	SpawnTimer.connect("timeout", self.WakeMonster)
	
func SpawnMonster(spawnposition):
	var monster = Monster.new()
	monster.position = spawnposition
	add_child(monster)
	Monsters.push_back(monster)
	
func WakeMonster():
	if(WakeCount < Monsters.size()):
		Monsters[WakeCount].State = "Move"
		WakeCount+=1
		
func UpdateTarget():
	if(TargetCount < Monsters.size()):
		Monsters[TargetCount].State = "Move"
		var start = Vector2i(Monsters[TargetCount].position) / Map.cell_size
		var end = Vector2i(Party.getLeader().position) / Map.cell_size
		var monster_movelist = Map.FindPath(start, end)
		Monsters[TargetCount].Move(monster_movelist)
		TargetCount+=1
	else:
		TargetCount = 0
