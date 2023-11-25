class_name HeroManager extends Node2D

# Store reference to the map
var map:Map
# Store reference to the UI
var ui:Control

# List of all the heros
var hero_list:Array = []
# Stores the hero position before entering a combat state
var hero_last_position:Array = []

# The size of the company of heroes
var company_size:int = 5
# Tracks the position of the company, takes the centroid of all heroes
var company_position:Vector2
var company_cave_id:int

# Class Lists - store references to our heros based on their class role
var tank_list:Array = []
var damage_list:Array = []
var healer_list:Array = []

#
var update_hero_path_count:int = 0

# Init
func _init(_map:Map, _ui:Control):
	map = _map
	ui = _ui
	
func _process(delta):
	# Track the position of the company
	var points = []
	for h in hero_list:
		points.push_back(h.getPosition())
	company_position = iMathHelper.get_centroid(points)
	
	# Track what cave the company is in
	var tile = map.get_tile(hero_list[0].getPosition())
	if(tile):
		company_cave_id = tile.cave_id
	else:
		company_cave_id = 0
		
	# Update Movement Path Line
	if(get_parent().company_state!="Combat" && get_parent().company_state!="Formation"):
		if(hero_list[0].move_list.size() > 1):
			get_parent().get_node("PathLine").update_line(hero_list[0].move_list)
		else:
			get_parent().get_node("PathLine").clear_path_line()
	else:
		get_parent().get_node("PathLine").clear_path_line()
		
	# Update UI
	ui.update_health_bar_0(hero_list[0].hitpoints, hero_list[0].max_hitpoints, hero_list[0].sprite_color)
	ui.update_health_bar_1(hero_list[1].hitpoints, hero_list[1].max_hitpoints, hero_list[1].sprite_color)
	ui.update_health_bar_2(hero_list[2].hitpoints, hero_list[2].max_hitpoints, hero_list[2].sprite_color)
	ui.update_health_bar_3(hero_list[3].hitpoints, hero_list[3].max_hitpoints, hero_list[3].sprite_color)
	ui.update_health_bar_4(hero_list[4].hitpoints, hero_list[4].max_hitpoints, hero_list[4].sprite_color)
	
# Spawn Company
func spawn_company(spawnposition:Vector2):
	var heroscene
	var zindex = 5
	for n in company_size:
		if n==0:
			heroscene = load("res://scenes/Heroes/Hero_Tank_1.tscn")
		elif(n==1):
			heroscene = load("res://scenes/Heroes/Hero_Tank_2.tscn")
		elif(n==2):
			heroscene = load("res://scenes/Heroes/Hero_Damage_1.tscn")
		elif(n==3):
			heroscene = load("res://scenes/Heroes/Hero_Damage_2.tscn")
		elif(n==4):
			heroscene = load("res://scenes/Heroes/Hero_Healer.tscn")
			
		var hero = heroscene.instantiate();
		hero.id = n
		add_child(hero)
		hero.setPosition(spawnposition)
		hero_list.push_back(hero)
		hero_last_position.push_back(hero.getPosition())
		hero.set_z_index(zindex)
		zindex-=1
		
		if n==0:
			hero.sprite_color = Color(74/255.0, 90/255.0, 1.0)
		elif(n==1):
			hero.sprite_color = Color(61/255.0, 252/255.0, 115/255.0)
		elif(n==2):
			hero.sprite_color = Color(252/255.0, 61/255.0, 61/255.0)
		elif(n==3):
			hero.sprite_color = Color(252/255.0, 211/255.0, 61/255.0)
		elif(n==4):
			hero.sprite_color = Color(183/255.0, 171/255.0, 171/255.0)
		
		# Set class roles
		if n==0 or n==1:
			hero.setRandomTankClass()
			tank_list.push_back(hero)
		elif n==2 or n==3:
			hero.setRandomDamageClass()
			damage_list.push_back(hero)
		elif n==4:
			hero.setRandomHealerClass()
			healer_list.push_back(hero)
			
		# Update UI
		if n==0:
			ui.update_health_bar_0(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			#ui.update_race_class_0(hero.race + "/" + hero.class_type)
		elif n==1:
			ui.update_health_bar_1(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			#ui.update_race_class_1(hero.race + "/" + hero.class_type)
		elif n==2:
			ui.update_health_bar_2(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			#ui.update_race_class_2(hero.race + "/" + hero.class_type)
		elif n==3:
			ui.update_health_bar_3(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			#ui.update_race_class_3(hero.race + "/" + hero.class_type)
		elif n==4:
			ui.update_health_bar_4(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			#ui.update_race_class_4(hero.race + "/" + hero.class_type)
	
	# Setup followers
	var previous_member = null
	for h in hero_list:
		if previous_member != null:
			previous_member.follower = h
		previous_member = h
		
# Loop through heroes, assign targets based on distance
func update_hero_targets(monster_list:Array):
	for h in hero_list:
		# TODO Check target as well?
		if h.target_object==null:
			var last_d = 10000000
			var tmp_target = null
			for m in monster_list:
				if m.state != "Dead":
					var d = h.getPosition().distance_to(m.getPosition())
					if d < last_d:
						last_d = d
						tmp_target = m
			h.target = tmp_target
			h.target_object = tmp_target

# Loops through heros on timer, updates path to target
func update_hero_paths(company_state:String):
	if company_state=="Combat" or company_state=="Formation":
		if update_hero_path_count < hero_list.size():
			var hero = hero_list[update_hero_path_count]
			if hero.target!=null:
				var d = hero.getPosition().distance_to(hero.target.getPosition())
				#if d < 100 and d > 5:
				if d < 100:
					var start = Vector2(hero.getPosition()) / map.cell_size
					start = map.check_if_valid(start)
					var end = Vector2(hero.target.getPosition()) / map.cell_size
					hero.move(map.find_path(start, end))
				else:
					var start = Vector2(hero.getPosition()) / map.cell_size
					start = map.check_if_valid(start)
					var end = Vector2(hero_last_position[hero.id]) / map.cell_size
					hero.move(map.find_path(start, end))
				update_hero_path_count+=1
		else:
			update_hero_path_count = 0		
	
# Check for down state, any hero whose hitpoints less then zero get marked to down state
func check_for_down_state():
	for h in hero_list:
		if(h.hitpoints <= 0 and h.state != "Down"):
			h.state = "Down"
	
# Heal company to max hitpoints				
func heal_company():
	for h in hero_list:
		h.get_node("CharacterBody2D/HealParticles").set_emitting(true)
		h.hitpoints = h.max_hitpoints
	
# Adds the damage buff to all heroes	
func add_damage_buff():
	for h in hero_list:
		h.start_damage_buff_timer()

# Returns random chatter based on even passed in		
func get_hero_chat(event:String):
	var rng = RandomNumberGenerator.new()
	randomize()
	var game_start_chats = [
		"I Hope you packed your sleeping bags",
		"Lets proceed with caution...",
	]
	var boss_battle_chats = [
		"Did you hear that? sounds large...",
		"I hear something big...",
		"The ground is shaking..."
	]
	var horde_battle_chats = [
		"Did you hear that?",
		"I heard something this way...",
		"Something smells rotten here..."
	]
	var before_battle_chats = [
		"Here they come!",
		"So it begins!",
		"Ready yourselves!"
	]
	var after_battle_chats = [
		"That was a good fight!",
		"Form up!",
		"Lets keep moving!"
	]
	var enter_cave = [
		"Let's see where this goes...",
		"Whats down here..."
	]	
	if event == "Game Start":
		hero_list[0].show_chat_bubble(game_start_chats[rng.randi_range(0, game_start_chats.size()-1)])
	elif event == "Boss Battle":
		hero_list[0].show_chat_bubble(boss_battle_chats[rng.randi_range(0, boss_battle_chats.size()-1)])
	elif event == "Horde Battle":
		hero_list[0].show_chat_bubble(horde_battle_chats[rng.randi_range(0, horde_battle_chats.size()-1)])
	elif event == "Before Battle":
		hero_list[0].show_chat_bubble(before_battle_chats[rng.randi_range(0, before_battle_chats.size()-1)])
	elif event == "After Battle":
		hero_list[0].show_chat_bubble(after_battle_chats[rng.randi_range(0, after_battle_chats.size()-1)])
	elif event == "Enter Cave":
		hero_list[0].show_chat_bubble(enter_cave[rng.randi_range(0, enter_cave.size()-1)])
	
