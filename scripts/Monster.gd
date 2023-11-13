class_name Monster extends Character

func _ready():
	super._ready()
	Speed = 96
	Hitpoints = 10
	
	add_to_group("Monsters")

func _physics_process(delta):
	if(State=="Move"):
		if(MoveList.size() > 0):
			var point = MoveList[0]
			#Body.look_at(point)
			Body.velocity = Body.position.direction_to(point) * Speed
			var collision = Body.move_and_collide(Body.velocity * delta)
			if collision:
				if(collision.get_collider().get_parent().is_in_group("Heroes")):
					get_parent().emit_signal("update_combat", collision.get_collider().get_parent(), self)
				else:
					Body.velocity = Body.velocity.slide(collision.get_normal())
			
			var d = Body.position.distance_to(point);
			if d < 1:
				Body.velocity = Vector2.ZERO
				MoveList.pop_front()
		else:
			MoveList.clear()
			State = "Idle"
	elif(State=="Dead"):
		visible = false
	
func UpdateColor(color):
	get_node("CharacterBody2D/Sprite2D").modulate = color
	SpriteColor = color
