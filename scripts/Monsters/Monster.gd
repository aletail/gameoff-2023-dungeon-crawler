class_name Monster extends Character

# Debuff timer
var taunt_debuff:String
var taunt_debuff_timer:Timer
var taunt_target = null

# Dead timer
var dead_removal_timer:Timer

# Flag to specify if this monster is a boss monster
var is_boss:bool = false

func _ready():
	# Set attributes based on type of monster
	if(is_boss):
		speed = 64
		hitpoints = 1000
		max_hitpoints = hitpoints
		attack_speed = 1
	else:
		speed = 96
		hitpoints = 10
		max_hitpoints = hitpoints
		attack_speed = 1
		
	super._ready()
	
	add_to_group("Monsters")
	get_node("CharacterBody2D/TauntCircle").visible = false
	
	taunt_debuff_timer = Timer.new()
	add_child(taunt_debuff_timer)
	taunt_debuff_timer.autostart = false
	taunt_debuff_timer.wait_time = 10
	taunt_debuff_timer.connect("timeout", self.reset_taunt_debuff_timer)
	
	dead_removal_timer = Timer.new()
	add_child(dead_removal_timer)
	dead_removal_timer.autostart = true
	dead_removal_timer.wait_time = 2
	dead_removal_timer.connect("timeout", self.set_state_to_remove)

	get_node("CharacterBody2D/BloodParticles").set_emitting(false)
#
func set_state_to_remove():
	if !is_boss:
		set_state("Remove")
	dead_removal_timer.stop()
	
# Starts the taunt debuff timer
func start_taunt_debuff_timer():
	taunt_debuff = "Init"
	taunt_debuff_timer.start()
	get_node("CharacterBody2D/TauntCircle").visible = true

# Reset the taunt debuff flag
func reset_taunt_debuff_timer():
	taunt_debuff = "Not Active"
	taunt_debuff_timer.stop()
	get_node("CharacterBody2D/TauntCircle").visible = false
#
func _physics_process(delta):
	if(state=="Dead" || state=="Remove"):
		get_node("CharacterBody2D/CollisionShape2D").disabled = true
	elif(state=="Move"):
		if(move_list.size() > 0):
			var point = move_list[0]
			# While moving through this tile, increase the weight of the tile
			get_parent().map.add_tile_weight(point)
			
			character_body.velocity = character_body.position.direction_to(point) * speed
			var collision = character_body.move_and_collide(character_body.velocity * delta)
			if collision:
				if(collision.get_collider().get_parent().is_in_group("Heroes")):
					get_parent().get_parent().emit_signal("update_combat", collision.get_collider().get_parent(), self)
				if(collision.get_collider().get_parent().is_in_group("Objects")):
					character_body.velocity = character_body.velocity.slide(collision.get_normal())
					if(is_boss):
						# Break down any walls
						collision.get_collider().get_parent().make_ground()
						
			var d = character_body.position.distance_to(point);
			if d < 10: # Movement is alot smoother with 10 here
				get_parent().map.subtract_tile_weight(point)
				move_list.pop_front()
		else:
			move_list.clear()
			state = "Idle"
