class_name Monster extends Character

var TauntDebuff
var TauntDebuffTimer

func _ready():
	super._ready()
	Speed = 96
	Hitpoints = 10
	
	add_to_group("Monsters")
	
	TauntDebuffTimer = Timer.new()
	add_child(TauntDebuffTimer)
	TauntDebuffTimer.autostart = false
	TauntDebuffTimer.wait_time = 30
	TauntDebuffTimer.connect("timeout", self.ResetTauntDebuffTimer)

func StartTauntDebuffTimer():
	TauntDebuff = true
	TauntDebuffTimer.start()
	
func ResetTauntDebuffTimer():
	TauntDebuff = false
	
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
