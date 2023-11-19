class_name Hero extends Character

# Damage Buff timer
var damage_buff:String
var damage_buff_timer:Timer
var damage_target = null

func _ready():
	super._ready()
	
	# Set attributes
	speed = 64
		
	# Randomly select a race
	var dice = Dice.new()
	var raceroll = dice.roll(1, 6)
	if(raceroll <= 2):
		race = "Human"
	elif(raceroll <= 4):
		race = "Dwarf"
	elif(raceroll <= 6):
		race = "Elf"
	
	# Add this to the "Heroes" group, used for collisions, simple for debugging
	add_to_group("Heroes")
	
	# Assign a random color
	var rng = RandomNumberGenerator.new()
	sprite_color = Color(rng.randf_range(0, 1), rng.randf_range(0, 1), rng.randf_range(0, 1))
	get_node("CharacterBody2D/Sprite2D").modulate = sprite_color
	
	# Assign a number, simple for debugging
	get_node("CharacterBody2D/Label").text = str(id)
	
	damage_buff_timer = Timer.new()
	add_child(damage_buff_timer)
	damage_buff_timer.autostart = false
	damage_buff_timer.wait_time = 30
	damage_buff_timer.connect("timeout", self.reset_damage_buff_timer)

# Starts the damage buff timer
func start_damage_buff_timer():
	damage_buff = "Init"
	damage_buff_timer.start()

# Reset the damage buff flag
func reset_damage_buff_timer():
	damage_buff = "Not Active"
	
# 	
func _physics_process(delta):
	if(state=="Move"):
		if(move_list.size() > 0):
			var point = move_list[0]
			# While moving through this tile, increase the weight of the tile
			get_parent().map.add_tile_weight(point)
			
			# Move and detect collisions
			character_body.velocity = character_body.position.direction_to(point) * speed
			var collision = character_body.move_and_collide(character_body.velocity * delta)
			# If a collision is detected, check what we collided with
			if collision:
				if(collision.get_collider().get_parent().is_in_group("Monsters")):
					get_parent().get_parent().emit_signal("update_combat", self, collision.get_collider().get_parent())
			
			# Check distance to our point, if less then one - remove point from list and update any followers
			var d = character_body.position.distance_to(point);
			if d < 1:
				get_parent().map.subtract_tile_weight(point)
				# If we have a follower, send point to them and trigger a move state
				if(follower && (get_parent().get_parent().company_state!="Combat" && get_parent().get_parent().company_state!="Formation")):
					# Checking for greater then one, will stop this before it reaches the character it is following
					if(move_list.size() > 1):
						follower.move_list.push_back(move_list.pop_front())
						follower.set_state("Move")
					else:
						state = "Idle"
				else:
					move_list.pop_front()
		else:
			move_list.clear()
			state = "Idle"
	elif(state=="Idle"):
		pass

# Sets a random tank class
func setRandomTankClass():
	hitpoints = 30
	max_hitpoints = 30
	var dice = Dice.new()
	var classroll = dice.roll(1, 6)
	if(classroll <= 2):
		class_type = "Barbarian"
	elif(classroll <= 4):
		class_type = "Fighter"
	elif(classroll <= 6):
		class_type = "Paladin"

# Sets a random damage class
func setRandomDamageClass():
	hitpoints = 20
	max_hitpoints = 20
	var dice = Dice.new()
	var classroll = dice.roll(1, 10)
	if(classroll <= 2):
		class_type = "Wizard"
	elif(classroll <= 4):
		class_type = "Ranger"
	elif(classroll <= 6):
		class_type = "Rogue"
	elif(classroll <= 8):
		class_type = "Monk"
	elif(classroll <= 10):
		class_type = "Sorcerer"
		
# Sets a random healer class
func setRandomHealerClass():
	hitpoints = 10
	max_hitpoints = 10
	var dice = Dice.new()
	var classroll = dice.roll(1, 4)
	if(classroll <= 2):
		class_type = "Cleric"
	elif(classroll <= 4):
		class_type = "Druid"
