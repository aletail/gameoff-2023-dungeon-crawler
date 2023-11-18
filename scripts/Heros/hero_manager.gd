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
	
	# Update UI
	ui.update_health_bar_0(hero_list[0].hitpoints, hero_list[0].max_hitpoints, hero_list[0].sprite_color)
	ui.update_health_bar_1(hero_list[1].hitpoints, hero_list[1].max_hitpoints, hero_list[1].sprite_color)
	ui.update_health_bar_2(hero_list[2].hitpoints, hero_list[2].max_hitpoints, hero_list[2].sprite_color)
	ui.update_health_bar_3(hero_list[3].hitpoints, hero_list[3].max_hitpoints, hero_list[3].sprite_color)
	ui.update_health_bar_4(hero_list[4].hitpoints, hero_list[4].max_hitpoints, hero_list[4].sprite_color)
	
# Spawn Company
func spawn_company(spawnposition:Vector2):
	for n in company_size:
		var heroscene = load("res://Scenes/Characters/Hero.tscn")
		var hero = heroscene.instantiate();
		hero.id = n
		add_child(hero)
		hero.setPosition(spawnposition)
		hero_list.push_back(hero)
		hero_last_position.push_back(hero.getPosition())
		
		# Set class roles
		if(n==0 || n==1):
			hero.setRandomTankClass()
			tank_list.push_back(hero)
		elif(n==2 || n==3):
			hero.setRandomDamageClass()
			damage_list.push_back(hero)
		elif(n==4):
			hero.setRandomHealerClass()
			healer_list.push_back(hero)
			
		# Update UI
		if(n==0):
			ui.update_health_bar_0(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			ui.update_race_class_0(hero.race + "/" + hero.class_type)
		elif(n==1):
			ui.update_health_bar_1(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			ui.update_race_class_1(hero.race + "/" + hero.class_type)
		elif(n==2):
			ui.update_health_bar_2(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			ui.update_race_class_2(hero.race + "/" + hero.class_type)
		elif(n==3):
			ui.update_health_bar_3(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			ui.update_race_class_3(hero.race + "/" + hero.class_type)
		elif(n==4):
			ui.update_health_bar_4(hero.hitpoints, hero.max_hitpoints, hero.sprite_color)
			ui.update_race_class_4(hero.race + "/" + hero.class_type)
	
	# Setup followers
	var previous_member = null
	for h in hero_list:
		if(previous_member != null):
			previous_member.follower = h
		previous_member = h
		
# Loop through heroes, assign targets based on distance
func update_hero_targets(monster_list:Array):
	for h in hero_list:
		if(h.target==null):
			var last_d = 10000000
			var tmp_target = null
			for m in monster_list:
				var d = h.getPosition().distance_to(m.getPosition())
				if(d < last_d):
					last_d = d
					tmp_target = m
			h.target = tmp_target

# Loops through heros on timer, updates path to target
func update_hero_paths(company_state:String):
	if(company_state=="Combat" || company_state=="Formation"):
		if(update_hero_path_count < hero_list.size()):
			var hero = hero_list[update_hero_path_count]
			if(hero.target!=null):
				var d = hero.getPosition().distance_to(hero.target.getPosition())
				if(d < 200):
					var start = Vector2(hero.getPosition()) / map.cell_size
					var end = Vector2(hero.target.getPosition()) / map.cell_size
					hero.move(map.find_path(start, end))
				update_hero_path_count+=1
		else:
			update_hero_path_count = 0		
