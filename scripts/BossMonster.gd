class_name BossMonster extends Character

func _ready():
	super._ready()
	Speed = 32
	Hitpoints = 100
	
	add_to_group("Monsters")

func _physics_process(delta):
	if(State=="Move"):
		if(MoveList.size() > 0):
			var point = MoveList[0]
			Body.velocity = Body.position.direction_to(point) * Speed
			var collision = Body.move_and_collide(Body.velocity * delta)
			if collision:
				if(collision.get_collider().get_parent().is_in_group("Heroes")):
					get_parent().emit_signal("update_combat", collision.get_collider().get_parent(), self)
				elif(collision.get_collider().get_parent().is_in_group("Objects")):
					collision.get_collider().get_parent().get_node("StaticBody2D/CollisionShape2D").disabled = true
					collision.get_collider().get_parent().get_node("StaticBody2D/Sprite2D").modulate = Color(131/255.0, 121/255.0, 110/255.0)
					Body.velocity = Body.velocity.slide(collision.get_normal())
			
			var d = Body.position.distance_to(point);
			if d < 10: # Movement is alot smoother with 10 here
				MoveList.pop_front()
		else:
			MoveList.clear()
			State = "Idle"
	elif(State=="Dead"):
		visible = false
	
func UpdateColor(color):
	get_node("CharacterBody2D/Sprite2D").modulate = color
	SpriteColor = color
