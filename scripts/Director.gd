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
var spawn_horde_count:int = 0
var spawn_horde_timer:Timer
var spawn_horde_position:Vector2

# Combat queue - stores reference to a hero and a monster engaged in combat
var combat_queue:Dictionary = {}
# Remove From Combat Queue - stores items from the combat queue that need to be removed
var remove_from_combat_queue:Array = []
# Updates the combat queue with character and monster pair
signal update_combat(character, monster)

# Abilities
var button_taunt
var taunt_cooldown_state:String = "Ready"
var taunt_timer:Timer

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
	
	# When spawing a horde, a monster will be added every 0.5 seconds
	spawn_horde_timer = Timer.new()
	add_child(spawn_horde_timer)
	spawn_horde_timer.autostart = false
	spawn_horde_timer.wait_time = 0.5
	spawn_horde_timer.connect("timeout", self.spawn_horde)
	
	# Connect update combat signal
	update_combat.connect(_on_update_combat)
	
	# Abilities
	button_taunt = get_node("CanvasLayer/Control/BoxContainer/HBoxContainer/TauntButton")
	button_taunt.pressed.connect(self.taunt_button_pressed)
	
	taunt_timer = Timer.new()
	add_child(taunt_timer)
	taunt_timer.autostart = false
	taunt_timer.wait_time = 5
	taunt_timer.connect("timeout", self.reset_taunt_timer)
	
# Main loop
func _process(delta):
	# Update camera position to follow the company
	if(hero_manager.company_position):
		camera.position = camera.position.lerp(hero_manager.company_position, delta * 5)
		
	if(company_state=="Combat"):
		camera.zoom = camera.zoom.lerp(Vector2(0.75, 0.75), delta * 1.25)
	else:
		camera.zoom = camera.zoom.lerp(Vector2(1.5, 1.5), delta * 1.25)
		
	# Update Hero and Monster targets
	hero_manager.update_hero_targets(monster_manager.monster_list)
	monster_manager.update_monster_targets(hero_manager.hero_list, hero_manager.company_position, hero_manager.tank_list)
	
	# Process the combat queue
	process_combat_queue()
	
	# Monitor company state
	update_company_state()
	
	# Monster Cleanup
	cleanup_monsters()
	
# Handle Input here
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var start = Vector2(hero_manager.hero_list[0].getPosition()) / map.cell_size
			var end = Vector2(get_global_mouse_position()) / map.cell_size
			hero_manager.hero_list[0].move(map.find_path(start, end))
	
	if event is InputEventKey and event.is_released:
		if event.keycode == KEY_SPACE:
			spawn_horde_position = map.get_offscreen_spawn_point(hero_manager.company_position)
			spawn_horde_timer.start()
			
# Spawns multiple monsters at once			
func spawn_horde():
	if(spawn_horde_count < horde_size):
		#var sp = map.get_offscreen_spawn_point(hero_manager.company_position)
		if spawn_horde_position:
			monster_manager.spawn_monster(spawn_horde_position, hero_manager.company_position)
			#monster_manager.SpawnBoss(sp, hero_manager.CompanyPosition)
		else:
			print("No spawn position found")
		spawn_horde_count+=1
	else:
		spawn_horde_count = 0
		spawn_horde_timer.stop()

# Update Hero and Monster paths, called on a timer
func update_paths():
	hero_manager.update_hero_paths(company_state)
	monster_manager.update_monster_paths()
	

# Signal function - adds the character and monster to the combat queue
func _on_update_combat(character, monster) -> void:
	if(character.state!="Dead" || monster.state!="Dead"):
		combat_queue[str(monster.id)] = [character, monster]
		
# Process the combat queue
#TODO Issue with taunt debuff, other heros will still target a monster which gives that monster an opportunity to 
# attack that hero, even if their target is a different hero
func process_combat_queue():
	for pairid in combat_queue:
		var hero = combat_queue[pairid][0]
		var monster = combat_queue[pairid][1]
		if hero.hitpoints<=0:
			hero.state = "Dead"
			#print("Character - Dead")
		elif hero.combat_cooldown=="Ready":
			# roll for hit and damage
			var dice = Dice.new()
			if(dice.roll(1, 20)>10):
				var dmg = dice.roll(3, 6)
				print("Character - Hit for "+ str(dmg) + " damage")
				monster.hitpoints = monster.hitpoints - dmg
			else:
				print("Character - miss")
				pass
			# set combat state to cooldown
			hero.set_combat_cooldown_state("Cooldown")
			
		if monster.hitpoints<=0:
			monster.state = "Dead"
			#print("Monster - Dead")
		elif monster.combat_cooldown=="Ready":
			if(monster.target_object == hero):
				# roll for hit and damage
				var dice = Dice.new()
				if(dice.roll(1, 20)>16):
					var dmg = dice.roll(1, 2)
					print("Monster - Hit for "+ str(dmg) + " damage")
					hero.hitpoints = hero.hitpoints - dmg
				else:
					print("Monster - miss")
				# set combat state to cooldown
				monster.set_combat_cooldown_state("Cooldown")
			else:
				print("Taunt Debuff")
			
		if hero.hitpoints<=0 || monster.hitpoints<=0:	
			remove_from_combat_queue.push_back(str(monster.id))
	
	# Clear combat queue
	for i in remove_from_combat_queue:
		combat_queue.erase(i)
	remove_from_combat_queue.clear()

# Monitors the state of the company, sets the company state accordingly
func update_company_state():
	if(company_state=="Combat"):
		# The only way out of the combat state is if there are no monsters left in current spawn
		if(monster_manager.monster_list.size()==0):
			for h in hero_manager.hero_list.size():
				var start = Vector2(hero_manager.hero_list[h].getPosition()) / map.cell_size
				var end = Vector2(hero_manager.hero_last_position[h]) / map.cell_size
				hero_manager.hero_list[h].move(map.find_path(start, end))
			company_state = "Formation"
	elif(company_state=="Formation"):
		# To exit the formation state, all heros should be idle
		var moving = false
		for h in hero_manager.hero_list:
			if(h.state == "Move"):
				moving = true
		if(!moving):
			company_state = "Idle"
	else:
		if(monster_manager.monster_list.size()>0):
			company_state = "Combat"
			# When entering combat, store the hero position (to be used later after battle) and clear their move list
			for h in hero_manager.hero_list.size():
				hero_manager.hero_last_position[h] = hero_manager.hero_list[h].getPosition()
				hero_manager.hero_list[h].move_list = []

# Remove dead monsters from lists, combat queue
func cleanup_monsters():
	for m in monster_manager.monster_list:
		if(m.state=="Dead"):
			#print("Dead Monster Found" + str(Monsters.size()))
			for h in hero_manager.hero_list:
				if(h.target==m):
					h.target=null
			combat_queue.erase(m.id)
			monster_manager.monster_list.erase(m)
			m.queue_free()

func taunt_button_pressed():
	button_taunt.disabled = true
	set_taunt_cooldown_state("Cooldown")
	monster_manager.add_taunt_debuff()

func reset_taunt_timer():
	taunt_cooldown_state = "Ready"
	button_taunt.disabled = false
	
func set_taunt_cooldown_state(state):
	if(state=="Cooldown"):
		taunt_cooldown_state = state
		taunt_timer.start()
