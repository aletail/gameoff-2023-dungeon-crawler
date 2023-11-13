class_name CharacterManager extends Node2D

var Map

var Heroes:Array = []
var HeroPosition 
var PartySize = 10
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
			CombatQueue.erase(i.ID)
			Monsters.erase(i)
			i.queue_free()
	
	# Track Party
	var points = []
	for p in Heroes:
		points.push_back(p.getPosition())
	PartyPosition = _centroid(points)
	
	if(Monsters.size()==0):
		pass
		setPartyState("Idle")
		
func setPartyState(state):
	# TODO: May not be working as intended
	if(PartyState=="Combat" && state=="Idle"):
		PartyState = state
		var start = Vector2i(Heroes[0].getPosition()) / Map.cell_size
		var end = Vector2i(HeroPosition) / Map.cell_size
		var movelist = Map.FindPath(start, end)
		Heroes[0].Move(movelist)
	elif(PartyState=="Idle" && state=="Combat"):
		PartyState = state
		# store initial positions
		HeroPosition = Heroes[0].getPosition()
	
			
func ProcessCombatQueue():
	for pairid in CombatQueue:
		if CombatQueue[pairid][0].Hitpoints<=0:
			CombatQueue[pairid][0].State = "Dead"
			print("Character - Dead")
		elif CombatQueue[pairid][0].CombatCooldown=="Ready":
			# roll for hit and damage
			var dice = Dice.new()
			if(dice.Roll(1, 20)>10):
				var dmg = dice.Roll(3, 6)
				print("Character - Hit for "+ str(dmg) + " damage")
				CombatQueue[pairid][1].Hitpoints = CombatQueue[pairid][1].Hitpoints - dmg
			else:
				print("Character - miss")
			# set combat state to cooldown
			CombatQueue[pairid][0].setCombatCooldownState("Cooldown")
			
		if CombatQueue[pairid][1].Hitpoints<=0:
			CombatQueue[pairid][1].State = "Dead"
			print("Monster - Dead")
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
	#if(PartyState=="Combat"):
		if(PartyTargetCount < Heroes.size()):
			if(Heroes[PartyTargetCount].Target!=null):
				Heroes[PartyTargetCount].State = "Move"
				var start = Vector2i(Heroes[PartyTargetCount].getPosition()) / Map.cell_size
				var end = Vector2i(Heroes[PartyTargetCount].Target.getPosition()) / Map.cell_size
				var player_movelist = Map.FindPath(start, end)
				Heroes[PartyTargetCount].Move(player_movelist)
				PartyTargetCount+=1
		else:
			PartyTargetCount = 0

func UpdateTargets():
	#if(PartyState=="Combat"):
		# Loop through party members, assign targets
		for p in Heroes:
			if(p.Target==null):
				var last_d = 10000000
				var tmp_target = null
				for m in Monsters:
					var d = p.getPosition().distance_to(m.getPosition())
					if(d < 200):
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
