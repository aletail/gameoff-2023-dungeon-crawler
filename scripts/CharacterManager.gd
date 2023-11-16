class_name CharacterManager extends Node2D

var Map

var Heroes:Array = []
var HeroPosition:Array = []
var PartySize = 5
var PartyState = "Idle"
var PartyTargetTimer
var PartyTargetCount = 0
var PartyPosition = null

var Monsters:Array = []
var MonsterTargetTimer
var MonsterTargetCount = 0
var MonsterSpawnTimer
var MonsterWakeCount = 0

var CombatQueue = {}
var RemoveFromCombatQueue = []

signal update_combat(character, monster)

func _init(map):
	Map = map

func _ready():
	MonsterTargetTimer = Timer.new()
	add_child(MonsterTargetTimer)
	MonsterTargetTimer.autostart = true
	MonsterTargetTimer.wait_time = 0.05
	MonsterTargetTimer.start()
	MonsterTargetTimer.connect("timeout", self.UpdateMonsterPath)
	
	PartyTargetTimer = Timer.new()
	add_child(PartyTargetTimer)
	PartyTargetTimer.autostart = true
	PartyTargetTimer.wait_time = 0.05
	PartyTargetTimer.start()
	PartyTargetTimer.connect("timeout", self.UpdatePlayerPath)
	
	update_combat.connect(_on_update_combat)
	
func _on_update_combat(character, monster) -> void:
	if(character.State!="Dead" || monster.State!="Dead"):
		CombatQueue[str(monster.ID)] = [character, monster]
	
func _process(delta):
	# Update player and monster targets
	UpdateTargets()
	
	# Process the combat queue
	ProcessCombatQueue()
	
	# Look for any dead monsters
	for i in Monsters:
		if(i.State=="Dead"):
			print("Dead Monster Found" + str(Monsters.size()))
			for h in Heroes:
				if(h.Target==i):
					h.Target=null
			CombatQueue.erase(i.ID)
			Monsters.erase(i)
			i.queue_free()
	
	# Track Party
	var points = []
	for p in Heroes:
		points.push_back(p.getPosition())
	PartyPosition = _centroid(points)
	
	UpdatePartyState()
	
		
func UpdatePartyState():
	if(PartyState=="Combat"):
		#print("Combat")
		# The only way out is if there are no monsters left
		if(Monsters.size()==0):
			for h in Heroes.size():
				var start = Vector2i(Heroes[h].getPosition()) / Map.cell_size
				var end = Vector2i(HeroPosition[h]) / Map.cell_size
				var movelist = Map.FindPath(start, end)
				Heroes[h].Move(movelist)
			PartyState = "Formation"
	elif(PartyState=="Formation"):
		#print("Formation")
		var moving = false
		for h in Heroes:
			if(h.State == "Move"):
				moving = true
		if(!moving):
			PartyState = "Idle"
	else:
		#print(PartyState)
		if(Monsters.size()>0):
			PartyState = "Combat"
			for h in Heroes.size():
				HeroPosition[h] = Heroes[h].getPosition()
				Heroes[h].MoveList = []
			
func ProcessCombatQueue():
	for pairid in CombatQueue:
		if CombatQueue[pairid][0].Hitpoints<=0:
			CombatQueue[pairid][0].State = "Dead"
			#print("Character - Dead")
		elif CombatQueue[pairid][0].CombatCooldown=="Ready":
			# roll for hit and damage
			var dice = Dice.new()
			if(dice.Roll(1, 20)>10):
				var dmg = dice.Roll(3, 6)
				#print("Character - Hit for "+ str(dmg) + " damage")
				CombatQueue[pairid][1].Hitpoints = CombatQueue[pairid][1].Hitpoints - dmg
			else:
				#print("Character - miss")
				pass
			# set combat state to cooldown
			CombatQueue[pairid][0].setCombatCooldownState("Cooldown")
			
		if CombatQueue[pairid][1].Hitpoints<=0:
			CombatQueue[pairid][1].State = "Dead"
			#print("Monster - Dead")
		elif CombatQueue[pairid][1].CombatCooldown=="Ready":
			# roll for hit and damage
			var dice = Dice.new()
			if(dice.Roll(1, 20)>18):
				var dmg = dice.Roll(1, 6)
				print("Monster - Hit for "+ str(dmg) + " damage")
				#TODO: Character hitpoints
				#CombatQueue[pairid][0].Hitpoints = CombatQueue[pairid][1].Hitpoints - dmg
			else:
				print("Monster - miss")
			# set combat state to cooldown
			CombatQueue[pairid][1].setCombatCooldownState("Cooldown")
			
		if CombatQueue[pairid][0].Hitpoints<=0 || CombatQueue[pairid][1].Hitpoints<=0:	
			RemoveFromCombatQueue.push_back(str(CombatQueue[pairid][1].ID))
	
	# Clear combat queue
	for i in RemoveFromCombatQueue:
		CombatQueue.erase(i)
	RemoveFromCombatQueue.clear()
	
func SpawnParty(spawnposition):
	for n in PartySize:
		var partyscene = load("res://Scenes/Characters/Hero.tscn")
		var partymember = partyscene.instantiate();
		partymember.ID = n
		add_child(partymember)
		partymember.setPosition(spawnposition)
		spawnposition = spawnposition + Vector2(16, 0)
		Heroes.push_back(partymember)
		HeroPosition.push_back(partymember.getPosition())
		
	var previous_member = null
	for m in Heroes:
		if(previous_member != null):
			previous_member.Follower = m
		previous_member = m
	
func SpawnMonster(spawnposition):
	var monsterscene = load("res://Scenes/Characters/Monster.tscn")
	var monster = monsterscene.instantiate();
	monster.ID = Monsters.size()
	add_child(monster)
	monster.setPosition(spawnposition)
	monster.Target = PartyPosition
	Monsters.push_back(monster)
	
func SpawnBossMonster(spawnposition):
	var monsterscene = load("res://Scenes/Characters/BossMonster.tscn")
	var monster = monsterscene.instantiate();
	monster.Speed = 32
	monster.Hitpoints = 100
	monster.ID = Monsters.size()
	add_child(monster)
	monster.setPosition(spawnposition)
	monster.Target = PartyPosition
	Monsters.push_back(monster)
		
func UpdateMonsterPath():
	if(MonsterTargetCount < Monsters.size()):
		Monsters[MonsterTargetCount].State = "Move"
		var start = Vector2i(Monsters[MonsterTargetCount].getPosition()) / Map.cell_size
		var end = Vector2i(Monsters[MonsterTargetCount].Target) / Map.cell_size
		var monster_movelist = Map.FindPath(start, end)
		Monsters[MonsterTargetCount].Move(monster_movelist)
		MonsterTargetCount+=1
	else:
		MonsterTargetCount = 0
		
func UpdatePlayerPath():
	if(PartyTargetCount < Heroes.size()):
		if(Heroes[PartyTargetCount].Target!=null):
			var d = Heroes[PartyTargetCount].getPosition().distance_to(Heroes[PartyTargetCount].Target.getPosition())
			if(d < 100):
				Heroes[PartyTargetCount].State = "Move"
				var start = Vector2i(Heroes[PartyTargetCount].getPosition()) / Map.cell_size
				var end = Vector2i(Heroes[PartyTargetCount].Target.getPosition()) / Map.cell_size
				var player_movelist = Map.FindPath(start, end)
				Heroes[PartyTargetCount].Move(player_movelist)
			PartyTargetCount+=1
	else:
		PartyTargetCount = 0

func UpdateTargets():
	# Loop through party members, assign targets
	for p in Heroes:
		if(p.Target==null):
			var last_d = 10000000
			var tmp_target = null
			for m in Monsters:
				var d = p.getPosition().distance_to(m.getPosition())
				#if(d < 50):
				if(d < last_d):
					last_d = d
					tmp_target = m
			p.Target = tmp_target
			
	# Loop through monsters, assign targets - if not, set target to center of the party
	for m in Monsters:
		var last_d = 10000000
		var tmp_target = null
		var player_target = null
		for p in Heroes:
			var d = m.getPosition().distance_to(p.getPosition())
			if(d < 200):
				if(d < last_d):
					last_d = d
					tmp_target = p.getPosition()
					player_target = p
		if(tmp_target==null):
			tmp_target = PartyPosition
		
		if(tmp_target != m.Target):
			if(player_target):
				m.UpdateColor(player_target.SpriteColor)
			else:
				m.UpdateColor(Color(1,1,1))
			m.Target = tmp_target
			
func _centroid(points):
	var centroid = [0,0];

	for i in points.size():
		centroid[0] += points[i].x
		centroid[1] += points[i].y
		
	var totalPoints = points.size();
	centroid[0] = centroid[0] / totalPoints;
	centroid[1] = centroid[1] / totalPoints;

	return Vector2(centroid[0],centroid[1]);
