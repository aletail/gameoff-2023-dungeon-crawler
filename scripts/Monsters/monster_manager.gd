class_name MonsterManager extends Node2D

# Store reference of the map
var map:Map
# List of all the monsters
var monster_list:Array = []

var update_monster_paths_count:int = 0

var dead_state_count:int = 0

# Init
func _init(_map:Map):
	map = _map
	
# Spawns a monster at the specified spawn position
func spawn_monster(spawnposition:Vector2, company_position:Vector2):
	var monsterscene = load("res://Scenes/Monsters/Monster.tscn")
	var monster = monsterscene.instantiate();
	monster.id = monster_list.size()
	add_child(monster)
	monster.setPosition(spawnposition)
	monster.target = company_position
	monster.move(map.find_path(spawnposition, company_position))
	monster_list.push_back(monster)
	
# Spawns a boss monster
func spawn_boss(spawnposition:Vector2, company_position:Vector2):
	var monsterscene = load("res://Scenes/Monsters/BossMonster.tscn")
	var monster = monsterscene.instantiate();
	monster.id = monster_list.size()
	monster.is_boss = true
	add_child(monster)
	monster.setPosition(spawnposition)
	monster.target = company_position
	monster_list.push_back(monster)
	return monster

# Loop through heroes, assign targets based on distance
func update_monster_targets(HeroList:Array, company_position:Vector2, tank_list:Array):
	for m in monster_list:
		if m.state != "Dead":
			# Check if the monster has a taunt debuff
			if m.taunt_debuff=="Active":
				# Do nothing until the debuff expires
				pass
			# Initialize the taunt debuff
			elif(m.taunt_debuff=="Init"):
				if(m.target_object):
					if m.target_object.is_tank:
						m.get_node("CharacterBody2D/TauntCircle").modulate = m.target_object.sprite_color
						pass
					else:
						m.taunt_debuff = "Active"
						var active_tanks = []
						if tank_list[0].state!="Down":
							active_tanks.push_back(tank_list[0])
						if tank_list[1].state!="Down":
							active_tanks.push_back(tank_list[1])
						randomize()
						var rand_index = randi() % active_tanks.size()
						m.target = active_tanks[rand_index].getPosition()
						m.target_object = active_tanks[rand_index]
						get_parent().remove_from_combat_queue.push_back(str(m.id))
						m.get_node("CharacterBody2D/TauntCircle").modulate = m.target_object.sprite_color
			else:
				var last_d = 10000000
				var tmp_target = null
				var hero_target = null
				for h in HeroList:
					if h.state != "Down":
						var d = m.getPosition().distance_to(h.getPosition())
						if(d < last_d):
							last_d = d
							tmp_target = h.getPosition()
							hero_target = h
				# If no suitable target is found, set the target to the company position
				if(tmp_target==null):
					tmp_target = company_position
				elif(tmp_target != m.target):
					m.target = tmp_target
					m.target_object = hero_target
	
# Loops through monsters on timer, updates path to target
func update_monster_paths():
	if(update_monster_paths_count < monster_list.size()):
		var monster = monster_list[update_monster_paths_count]
		var start = Vector2(monster.getPosition()) / map.cell_size
		if monster.state != "Dead":
			if(!monster.is_boss):
				if map.get_tile_type(start.x, start.y)=="roof":
					start = map.get_offscreen_spawn_point(monster.getPosition(), get_parent().track_current_cave)
					monster.setPosition(start)
				
			var end = Vector2(monster.target) / map.cell_size
			start = map.check_if_valid(start)
			monster.move(map.find_path(start, end))
			
		update_monster_paths_count+=1
	else:
		update_monster_paths_count = 0

# Check for dead state, checks all monsters for a dead state, if so the remove timer is started
func check_for_dead_state():
	if monster_list.size() > 0:
		for m in monster_list:
			if(m.hitpoints <= 0 and m.state != "Remove" and m.state != "Dead"):
				m.state = "Dead"
				dead_state_count+=1
				m.dead_removal_timer.start()
	else:
		dead_state_count = 0
			
# Starts the taunt debuff timer
func add_taunt_debuff():
	for m in monster_list:
		m.start_taunt_debuff_timer()
