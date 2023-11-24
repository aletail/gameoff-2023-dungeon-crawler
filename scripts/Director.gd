extends Node2D

var map:Map
var hero_manager:HeroManager
var monster_manager:MonsterManager
var camera:Camera2D
var ui:Control

# Tracks the state of the company: Idle, Combat, Formation
var company_state:String = "Idle"

# Timer for updating character and monster paths
var update_paths_timer:Timer

# Horde settings, size, timer
var horde_size:int = 20
var horde_size_count:int = 0
var spawn_horde_count:int = 0
var spawn_horde_timer:Timer
var spawn_monster_timer:Timer
var spawn_horde_position:Vector2
var boss_spawn_flag = false
var boss_object:Monster
var spawn_boss_timer:Timer

# Track the current cave the company is in
var track_current_cave = 1
var cave_active = false

# Combat queue - stores reference to a hero and a monster engaged in combat
var combat_queue:Dictionary = {}
# Remove From Combat Queue - stores items from the combat queue that need to be removed
var remove_from_combat_queue:Array = []
# Updates the combat queue with character and monster pair
signal update_combat(character, monster)

# Ability Cooldown 
const TAUNT_COOLDOWN = 13
const DAMAGE_COOLDOWN = 13
const HEAL_COOLDOWN = 13

# Taunt Ability
var button_taunt
var taunt_cooldown_state:String = "Ready"
var taunt_timer:Timer

# Heal Ability
var button_heal
var heal_cooldown_state:String = "Ready"
var heal_timer:Timer

# Damage Ability
var button_damage
var damage_cooldown_state:String = "Ready"
var damage_timer:Timer

# Reset Ability Checks
var hero_tank_defeat_count = 0
var hero_damage_defeat_count = 0
var hero_healer_defeat_count = 0

# UI
var quit_to_main_menu_button_on_boss_defeat
var quit_to_main_menu_button_on_hero_defeat

func _ready():
	ui = get_node("CanvasLayer/Control")
	camera = get_node("Camera2D")
	
	# Generate a map
	map = Map.new(Vector2i(16,16), Vector2i(200,50))
	add_child(map)
	
	# Hero Manager - Spawn company of heroes
	hero_manager = HeroManager.new(map, ui)
	add_child(hero_manager)
	hero_manager.spawn_company(map.get_spawn_point())
	
	# Monster Manager
	monster_manager = MonsterManager.new(map)
	add_child(monster_manager)
	
	# Heros and Monsters will update their pathing every 0.05 seconds
	update_paths_timer = Timer.new()
	add_child(update_paths_timer)
	update_paths_timer.autostart = true
	update_paths_timer.wait_time = 0.05
	update_paths_timer.start()
	update_paths_timer.connect("timeout", self.update_paths)
	
	# When spawing a horde, the spawn will be delayed by this timer
	spawn_horde_timer = Timer.new()
	add_child(spawn_horde_timer)
	spawn_horde_timer.autostart = false
	spawn_horde_timer.wait_time = 5
	spawn_horde_timer.connect("timeout", self.spawn_horde)
	
	# When spawing a horde, a monster will be added every 0.5 seconds
	spawn_monster_timer = Timer.new()
	add_child(spawn_monster_timer)
	spawn_monster_timer.autostart = false
	spawn_monster_timer.wait_time = 0.5
	spawn_monster_timer.connect("timeout", self.spawn_horde_monster)
	
	# Spawns the boss after so many seconds
	spawn_boss_timer = Timer.new()
	add_child(spawn_boss_timer)
	spawn_boss_timer.autostart = false
	spawn_boss_timer.wait_time = 5
	spawn_boss_timer.connect("timeout", self.spawn_boss_monster)
	
	# Connect update combat signal
	update_combat.connect(_on_update_combat)
	
	# Taunt Ability
	button_taunt = get_node("CanvasLayer/Control/BoxContainer/HBoxContainer/TauntButtonContainer/TauntButton")
	button_taunt.pressed.connect(self.taunt_button_pressed)
	
	taunt_timer = Timer.new()
	add_child(taunt_timer)
	taunt_timer.autostart = false
	taunt_timer.wait_time = TAUNT_COOLDOWN
	taunt_timer.connect("timeout", self.reset_taunt_timer)
	
	# Heal Ability
	button_heal = get_node("CanvasLayer/Control/BoxContainer/HBoxContainer/HealButtonContainer/HealButton")
	button_heal.pressed.connect(self.heal_button_pressed)
	
	heal_timer = Timer.new()
	add_child(heal_timer)
	heal_timer.autostart = false
	heal_timer.wait_time = 20
	heal_timer.connect("timeout", self.reset_heal_timer)
	
	# Damage Ability
	button_damage = get_node("CanvasLayer/Control/BoxContainer/HBoxContainer/DamageButtonContainer/DamageButton")
	button_damage.pressed.connect(self.damage_button_pressed)
	
	damage_timer = Timer.new()
	add_child(damage_timer)
	damage_timer.autostart = false
	damage_timer.wait_time = 15
	damage_timer.connect("timeout", self.reset_damage_timer)
	
	# Quit to main menu button
	# On Boss Defeat
	quit_to_main_menu_button_on_boss_defeat = get_node("CanvasLayer/Control/GameOverPanel/QuitMainMenuButton")
	quit_to_main_menu_button_on_boss_defeat.pressed.connect(self.quit_to_main_menu)
	
	# On Hero Defeat
	quit_to_main_menu_button_on_hero_defeat = get_node("CanvasLayer/Control/GameOverPanel_Defeat/QuitMainMenuButton")
	quit_to_main_menu_button_on_hero_defeat.pressed.connect(self.quit_to_main_menu)
	
	ui.show_chat_bubble("Game Start", hero_manager.hero_list[0])
	
# Main loop
func _process(delta):
	# Check for end of game, disable abilities based on heroes who are down
	check_heroes()
	
	# Check boss, if spawned, ends game if boss is defeated
	check_boss()
	
	# Update camera based on situation
	update_camera(delta)
		
	# Map - update tile weights
	map.process_tile_weight_updates()
		
	# Update Hero and Monster targets
	hero_manager.update_hero_targets(monster_manager.monster_list)
	monster_manager.update_monster_targets(hero_manager.hero_list, hero_manager.company_position, hero_manager.tank_list)
		
	# Process the combat queue
	process_combat_queue()
	
	# Check for dead/down states for heroes and monsters
	monster_manager.check_for_dead_state()
	hero_manager.check_for_down_state()
	
	# Monitor company state
	update_company_state()
	
	# Monster Cleanup
	cleanup_monsters()
	
	# Check if enemies should be spawned
	spawn_enemy_check()
	
	# Update UI Timers
	ui.update_taunt_timer(taunt_timer.time_left, TAUNT_COOLDOWN)
	ui.update_damage_timer(damage_timer.time_left, DAMAGE_COOLDOWN)
	ui.update_heal_timer(heal_timer.time_left, HEAL_COOLDOWN)

func quit_to_main_menu():
	var loading_scene_path = "res://scenes/MainMenu.tscn"
	get_tree().change_scene_to_file(loading_scene_path)
	
# Spawns enemy/boss when entering a cave
func spawn_enemy_check():
	# If we enter a different cave then we are already in and a current cave is not active
	if hero_manager.company_cave_id != track_current_cave && !cave_active:
		if hero_manager.company_cave_id != null and hero_manager.company_cave_id != 0:
			track_current_cave = hero_manager.company_cave_id
			cave_active = true
			if track_current_cave == map.cave_object_list[map.cave_object_list.size()-1].id:
				# spawn the boss
				ui.show_chat_bubble("Boss Battle", hero_manager.hero_list[0])
				spawn_boss_timer.start()
			else:
				# start horde spawn
				ui.show_chat_bubble("Horde Battle", hero_manager.hero_list[0])
				var rng = RandomNumberGenerator.new()
				horde_size = rng.randi_range(20, 100)
				horde_size_count = horde_size
				spawn_horde_timer.wait_time = rng.randf_range(5.0, 10.0)
				spawn_horde_timer.start()
#				print("Horde Size: " + str(horde_size))
#				print("Wait time: " + str(spawn_horde_timer.wait_time))
#				print("----------")
#		elif hero_manager.company_cave_id==null:
#			track_current_cave = hero_manager.company_cave_id
#			hero_manager.get_hero_chat("Enter Cave")


# Update camera
func update_camera(delta):
	if(company_state=="Combat"):
		camera.zoom = camera.zoom.lerp(Vector2(2, 2), delta * 1.25)
		if(hero_manager.company_position):
			camera.position = camera.position.lerp(hero_manager.company_position, delta * 5)
	else:
		if track_current_cave == 0:
			camera.zoom = camera.zoom.lerp(Vector2(2.5, 2.5), delta * 1.25)
		else:
			camera.zoom = camera.zoom.lerp(Vector2(1, 1), delta * 1.25)
			
		camera.position = camera.position.lerp(hero_manager.hero_list[0].getPosition(), delta * 5)
	

# Check for boss defeat, update health bar
func check_boss():
	if(boss_spawn_flag):
		if(monster_manager.monster_list.size()==0):
			# GAME OVER!
			#get_tree().paused = true
			ui.game_over_panel.visible = true
		else:
			ui.update_health_bar_boss(boss_object.hitpoints, boss_object.max_hitpoints, Color(0.75, 0, 0))

# Check for heroes down, update abilities based on who is down
func check_heroes():
	# Check for hero defeat
	var hero_defeat_count = 0
	hero_tank_defeat_count = 0
	hero_damage_defeat_count = 0
	hero_healer_defeat_count = 0
	
	# Check all heroes for a down state
	if hero_manager.hero_list[0].state == "Down":
		hero_defeat_count += 1
		hero_tank_defeat_count+=1
	if hero_manager.hero_list[1].state == "Down":
		hero_defeat_count += 1
		hero_tank_defeat_count+=1
	if hero_manager.hero_list[2].state == "Down":
		hero_defeat_count += 1
		hero_damage_defeat_count+=1
	if hero_manager.hero_list[3].state == "Down":
		hero_defeat_count += 1
		hero_damage_defeat_count+=1
	if hero_manager.hero_list[4].state == "Down":
		hero_defeat_count += 1
		hero_healer_defeat_count+=1
			
	# If all five heroes are down its game over
	if hero_defeat_count==5:
		# GAME OVER!
		#get_tree().paused = true
		ui.game_over_panel_defeat.visible = true
	
	# Check for abilities that need disabled
	if hero_tank_defeat_count == 2:
		button_taunt.get_parent().visible = false
	else:
		button_taunt.get_parent().visible = true
	if hero_damage_defeat_count == 2:
		button_damage.get_parent().visible = false
	else:
		button_damage.get_parent().visible = true
	if hero_healer_defeat_count == 1:
		button_heal.get_parent().visible = false
	else:
		button_heal.get_parent().visible = true
	
# Handle Input here
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if(company_state=="Idle"):
				var start = Vector2(hero_manager.hero_list[0].getPosition()) / map.cell_size
				var end = Vector2(get_global_mouse_position()) / map.cell_size
				var path = map.find_path(start, end)
				hero_manager.hero_list[0].move(path)
				get_node("PathLine").update_line(path)
	
	if event is InputEventKey and event.is_released:
		if event.keycode == KEY_1:
			self.taunt_button_pressed()
		if event.keycode == KEY_2:
			self.damage_button_pressed()
		if event.keycode == KEY_3:
			self.heal_button_pressed()
			

# Spawn Boss Monster		
func spawn_boss_monster():
	spawn_horde_position = map.get_offscreen_spawn_point(hero_manager.company_position, track_current_cave)
	boss_spawn_flag = true
	boss_object = monster_manager.spawn_boss(spawn_horde_position, hero_manager.company_position)
	ui.boss_health_bar.visible = true
	spawn_boss_timer.stop()
	
# Spawns multiple monsters at once				
func spawn_horde():
	spawn_horde_position = map.get_offscreen_spawn_point(hero_manager.company_position, track_current_cave)
	spawn_horde_timer.stop()
	spawn_monster_timer.start()	
	ui.update_health_bar_horde(horde_size - monster_manager.dead_state_count, horde_size, Color(0.75, 0, 0))
	ui.horde_health_bar.visible = true

# Spawns monster for a horder, on a timer		
func spawn_horde_monster():
	if(spawn_horde_count < horde_size):
		spawn_horde_position = map.get_offscreen_spawn_point(hero_manager.company_position, track_current_cave)
		if spawn_horde_position:
			monster_manager.spawn_monster(spawn_horde_position, hero_manager.company_position)
			monster_manager.spawn_monster(spawn_horde_position, hero_manager.company_position)
		#else:
			#print("No spawn position found")
		spawn_horde_count+=2
	else:
		spawn_horde_count = 0
		spawn_monster_timer.stop()

# Update Hero and Monster paths, called on a timer
func update_paths():
	hero_manager.update_hero_paths(company_state)
	monster_manager.update_monster_paths()

# Signal function - adds the character and monster to the combat queue
func _on_update_combat(character, monster) -> void:
	if(character.state!="Down" || monster.state!="Dead"):
		combat_queue[str(monster.id)] = [character, monster]
		
# Process the combat queue
func process_combat_queue():
	for pairid in combat_queue:
		var hero = combat_queue[pairid][0]
		var monster = combat_queue[pairid][1]
		
		# Hero turn
		if hero.combat_cooldown=="Ready":
			var hitchance = 10
			if(hero.damage_buff):
				hitchance = 0
			# roll for hit and damage
			var dice = Dice.new()
			if(dice.roll(1, 20) > hitchance):
				hero.state = "Combat"
				var dmg = dice.roll(3, 6)
				if(hero.damage_buff):
					dmg = dice.roll(4, 6)
				#print("Character - Critical Hit for "+ str(dmg) + " damage")
				monster.hitpoints = monster.hitpoints - dmg
				hero.get_node("AttackSound").play()
				monster.get_node("CharacterBody2D/BloodParticles").set_emitting(true)
			#else:
				#pass
				#print("Character - miss")
			# set combat state to cooldown
			hero.set_combat_cooldown_state("Cooldown")
			
		# Monster turn
		if monster.combat_cooldown=="Ready":
			# Check monster target is set to the hero in the queue, if not then there is an active taunt debuff
			if(monster.target_object == hero):
				# roll for hit and damage
				var dice = Dice.new()
				if(monster.is_boss):
					var chance = 5
				else:
					var chance = 10
				if(dice.roll(1, 20) > 10):
					var dmg = 0
					if(monster.is_boss):
						dmg = dice.roll(1, 8)
					else:
						dmg = dice.roll(1, 4)
					#print("Monster - Hit for "+ str(dmg) + " damage")
					hero.hitpoints = hero.hitpoints - dmg
					monster.get_node("AttackSound").play()
					hero.get_node("CharacterBody2D/BloodParticles").set_emitting(true)
				#else:
					#print("Monster - miss")
				# set combat state to cooldown
				monster.set_combat_cooldown_state("Cooldown")
			#else:
				#pass
				#print("Taunt Debuff")
			
		# If either are dead, remove from queue
		if hero.hitpoints<=0 || monster.hitpoints<=0:
			remove_from_combat_queue.push_back(str(monster.id))
	
	# Clear combat queue
	for i in remove_from_combat_queue:
		combat_queue.erase(i)
	remove_from_combat_queue.clear()

# Monitors the state of the company, sets the company state accordingly
func update_company_state():
	if(company_state=="Combat"):
		ui.update_health_bar_horde(horde_size - monster_manager.dead_state_count, horde_size, Color(0.75, 0, 0))
		# The only way out of the combat state is if there are no monsters left in current spawn
		if(monster_manager.monster_list.size()==0):
			get_node("DefaultMusic").play()
			get_node("BattleMusic").stop()
			ui.horde_health_bar.visible=false
			map.reset_tile_weights()
			# Reset Ability Checks
			hero_tank_defeat_count = 0
			hero_damage_defeat_count = 0
			hero_healer_defeat_count = 0
			for h in hero_manager.hero_list.size():
				# Raise any downed heroes
				hero_manager.hero_list[h].hitpoints = hero_manager.hero_list[h].max_hitpoints
				if(hero_manager.hero_list[h].state=="Down"):
					hero_manager.hero_list[h].state = "Idle"
				var start = Vector2(hero_manager.hero_list[h].getPosition()) / map.cell_size
				var end = Vector2(hero_manager.hero_last_position[h]) / map.cell_size
				hero_manager.hero_list[h].move(map.find_path(start, end))
			company_state = "Formation"
			cave_active = false
	elif(company_state=="Formation"):
		# To exit the formation state, all heros should be idle
		var moving = false
		for h in hero_manager.hero_list:
			if(h.state == "Move"):
				moving = true
		if(!moving):
			ui.show_chat_bubble("After Battle", hero_manager.hero_list[0])
			company_state = "Idle"
	else:
		if(monster_manager.monster_list.size()>0):
			company_state = "Combat"
			get_node("DefaultMusic").stop()
			get_node("BattleMusic").play()
			ui.show_chat_bubble("Before Battle", hero_manager.hero_list[0])
			# When entering combat, store the hero position (to be used later after battle) and clear their move list
			for h in hero_manager.hero_list.size():
				#hero_manager.hero_list[h].speed = 32
				hero_manager.hero_last_position[h] = hero_manager.hero_list[h].getPosition()
				hero_manager.hero_list[h].move_list = []

# Remove dead monsters from lists, combat queue
func cleanup_monsters():
	for m in monster_manager.monster_list:
		if m.is_boss and m.state == "Dead":
			for h in hero_manager.hero_list:
				if(h.target==m):
					h.target=null
					h.target_object=null
			combat_queue.erase(m.id)
			monster_manager.monster_list.erase(m)
		elif m.state=="Remove":
			for h in hero_manager.hero_list:
				if(h.target==m):
					h.target=null
					h.target_object=null
			combat_queue.erase(m.id)
			monster_manager.monster_list.erase(m)
			m.queue_free()

# Taunt Ability button pressed
func taunt_button_pressed():
	# Check if cooldown is ready and that atleast 1 tank is still standing
	if taunt_cooldown_state == "Ready" and hero_tank_defeat_count != 2:
		button_taunt.disabled = true
		set_taunt_cooldown_state("Cooldown")
		monster_manager.add_taunt_debuff()
		
# Reset the taunt timer, enables the taunt button
func reset_taunt_timer():
	taunt_cooldown_state = "Ready"
	button_taunt.disabled = false
	taunt_timer.stop()

# Set taunt cooldown state, starts timer
func set_taunt_cooldown_state(state):
	if(state=="Cooldown"):
		taunt_cooldown_state = state
		taunt_timer.start()
		
# Heal Ability button pressed
func heal_button_pressed():
	# Check if cooldown is ready and that one healer is standing
	if heal_cooldown_state == "Ready" and hero_healer_defeat_count != 1:
		button_heal.disabled = true
		set_heal_cooldown_state("Cooldown")
		hero_manager.heal_company()

# Reset the heal timer, enables the heal button
func reset_heal_timer():
	heal_cooldown_state = "Ready"
	button_heal.disabled = false
	heal_timer.stop()
	
# Set heal cooldown state, starts timer
func set_heal_cooldown_state(state):
	if(state=="Cooldown"):
		heal_cooldown_state = state
		heal_timer.start()
		
# Damage Ability button pressed
func damage_button_pressed():
	if damage_cooldown_state == "Ready" and hero_damage_defeat_count != 2:
		button_damage.disabled = true
		set_damage_cooldown_state("Cooldown")
		hero_manager.add_damage_buff()

# Reset the damage timer, enables the damage button
func reset_damage_timer():
	damage_cooldown_state = "Ready"
	button_damage.disabled = false
	damage_timer.stop()
	
# Set damage cooldown state, starts timer
func set_damage_cooldown_state(state):
	if(state=="Cooldown"):
		damage_cooldown_state = state
		damage_timer.start()
