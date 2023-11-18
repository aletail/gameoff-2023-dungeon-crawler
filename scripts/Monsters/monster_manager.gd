class_name MonsterManager extends Node2D

# Store reference of the map
var map:Map
# List of all the monsters
var monster_list:Array = []

var update_monster_paths_count:int = 0

# Init
func _init(_map:Map):
	map = _map
	
# Spawns a monster at the specified spawn position
func spawn_monster(spawnposition:Vector2, company_position:Vector2):
	var monsterscene = load("res://Scenes/Characters/Monster.tscn")
	var monster = monsterscene.instantiate();
	monster.id = monster_list.size()
	add_child(monster)
	monster.setPosition(spawnposition)
	monster.target = company_position
	monster_list.push_back(monster)
	
# Spawns a boss monster
func spawn_boss(spawnposition:Vector2, company_position:Vector2):
	var monsterscene = load("res://Scenes/Characters/BossMonster.tscn")
	var monster = monsterscene.instantiate();
	monster.id = monster_list.size()
	monster.is_boss = true
	add_child(monster)
	monster.setPosition(spawnposition)
	monster.target = company_position
	monster_list.push_back(monster)

# Loop through heroes, assign targets based on distance
func update_monster_targets(HeroList:Array, company_position:Vector2, tank_list:Array):
	for m in monster_list:
		# Check if the monster has a taunt debuff
		if m.taunt_debuff=="Active":
			# Do nothing until the debuff expires
			pass
		elif(m.taunt_debuff=="Init"):
			m.taunt_debuff = "Active"
			var d = Dice.new()
			if d.roll(1,2)==1:
				m.target = tank_list[0].getPosition()
				m.target_object = tank_list[0]
				m.update_color(tank_list[0].sprite_color)
			else:
				m.target = tank_list[1].getPosition()
				m.target_object = tank_list[1]
				m.update_color(tank_list[1].sprite_color)
			get_parent().remove_from_combat_queue.push_back(str(m.id))
		else:
			var last_d = 10000000
			var tmp_target = null
			var hero_target = null
			for h in HeroList:
				var d = m.getPosition().distance_to(h.getPosition())
				if(d < last_d):
					last_d = d
					tmp_target = h.getPosition()
					hero_target = h
			# If no suitable target is found, set the target to the company position
			if(tmp_target==null):
				tmp_target = company_position
			
			if(tmp_target != m.target):
				if(hero_target):
					m.update_color(hero_target.sprite_color)
				else:
					m.update_color(Color(1,1,1))
				m.target = tmp_target
				m.target_object = hero_target
	
# Loops through monsters on timer, updates path to target
func update_monster_paths():
	if(update_monster_paths_count < monster_list.size()):
		var monster = monster_list[update_monster_paths_count]
		var start = Vector2(monster.getPosition()) / map.cell_size
		var end = Vector2(monster.target) / map.cell_size
		monster.move(map.find_path(start, end))
		update_monster_paths_count+=1
	else:
		update_monster_paths_count = 0

# Starts the taunt debuff timer
func add_taunt_debuff():
	for m in monster_list:
		m.start_taunt_debuff_timer()
