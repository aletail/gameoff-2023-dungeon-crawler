class_name Hero extends Character

func _ready():
	super._ready()
	
	add_to_group("Heroes")
	var rng = RandomNumberGenerator.new()
	SpriteColor = Color(rng.randf_range(0, 1), rng.randf_range(0, 1), rng.randf_range(0, 1))
	get_node("CharacterBody2D/Sprite2D").modulate = SpriteColor
	
	get_node("CharacterBody2D/Label").text = str(ID)
		
func _physics_process(delta):
	if(State=="Move"):
		if(MoveList.size() > 0):
			var point = MoveList[0]
			
			Body.velocity = Body.position.direction_to(point) * Speed
			var collision = Body.move_and_collide(Body.velocity * delta)
			
			# If a collision is detected, check what we collided with
			if collision:
				if(collision.get_collider().get_parent().is_in_group("Monsters")):
					get_parent().emit_signal("update_combat", self, collision.get_collider().get_parent())
			
			# Check distance to our point, if less then one - remove point from list and update any followers
			var d = Body.position.distance_to(point);
			if d < 1:
				# If we have a follower, send point to them and trigger a move state
				if(Follower && (get_parent().PartyState!="Combat" && get_parent().PartyState!="Formation")):
					# Checking for greater then one, will stop this before it reaches the character it is following
					if(MoveList.size() > 1):
						Follower.MoveList.push_back(MoveList.pop_front())
						Follower.setState("Move")
				else:
					MoveList.pop_front()
		else:
			MoveList.clear()
			State = "Idle"
	elif(State=="Idle"):
		pass
